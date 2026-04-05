import SwiftUI
import CoreBluetooth
import Combine

// MARK: - BLE UUIDs
// Replace these with the actual UUIDs from your keychain firmware
enum KeychainBLE {
    static let serviceUUID         = CBUUID(string: "12345678-1234-1234-1234-1234567890AB")
    static let buttonCountsCharUUID = CBUUID(string: "12345678-1234-1234-1234-1234567890AC") // keychain → app (notify)
    static let habitDataCharUUID   = CBUUID(string: "12345678-1234-1234-1234-1234567890AD") // app → keychain (write)
}

// MARK: - Keychain Device Model
struct KeychainDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var name: String { peripheral.name ?? "Unknown Device" }
    var rssi: Int
}

// MARK: - Button Press Model
struct ButtonState: Identifiable {
    let id: Int          // 1–9
    var pressCount: Int = 0
    var lastUpdated: Date? = nil
}

// MARK: - Bluetooth Manager
class KeychainBluetoothManager: NSObject, ObservableObject {

    //Lets other files contact to this one
    static let shared = KeychainBluetoothManager()

    // Published state
    @Published var scanState: ScanState = .idle
    @Published var connectionState: ConnectionState = .disconnected
    @Published var discoveredDevices: [KeychainDevice] = []
    @Published var connectedDevice: KeychainDevice? = nil
    @Published var buttonStates: [ButtonState] = (1...9).map { ButtonState(id: $0) }
    @Published var lastAlert: String? = nil

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var buttonCountsChar: CBCharacteristic?
    private var habitDataChar: CBCharacteristic?

    enum ScanState { case idle, scanning, done }
    enum ConnectionState { case disconnected, connecting, connected, error(String) }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Scanning
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices = []
        scanState = .scanning
        centralManager.scanForPeripherals(withServices: [KeychainBLE.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        // Auto-stop after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScan()
        }
    }

    func stopScan() {
        centralManager.stopScan()
        scanState = .done
    }

    // MARK: - Connect / Disconnect
    func connect(to device: KeychainDevice) {
        peripheral = device.peripheral
        peripheral?.delegate = self
        connectionState = .connecting
        centralManager.connect(device.peripheral, options: nil)
    }

    func disconnect() {
        guard let p = peripheral else { return }
        centralManager.cancelPeripheralConnection(p)
    }

    // MARK: - Send Habit Data to Keychain
    func sendHabitData(_ payload: HabitPayload) {
        guard let char = habitDataChar,
              let p = peripheral,
              let data = try? JSONEncoder().encode(payload) else { return }
        p.writeValue(data, for: char, type: .withResponse)
    }

    // MARK: - Parse incoming button counts
    private func parseButtonCounts(_ data: Data) {
        // Expected: 9 bytes, one per button (0–255 press count each)
        guard data.count >= 9 else { return }
        for i in 0..<9 {
            let count = Int(data[i])
            if buttonStates[i].pressCount != count {
                buttonStates[i].pressCount = count
                buttonStates[i].lastUpdated = Date()
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension KeychainBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            connectionState = .error("Bluetooth unavailable: \(central.state.description)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let device = KeychainDevice(id: peripheral.identifier, peripheral: peripheral, rssi: RSSI.intValue)
        if !discoveredDevices.contains(where: { $0.id == device.id }) {
            discoveredDevices.append(device)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        connectedDevice = discoveredDevices.first(where: { $0.id == peripheral.identifier })
        peripheral.discoverServices([KeychainBLE.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .error(error?.localizedDescription ?? "Failed to connect")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        connectedDevice = nil
        buttonCountsChar = nil
        habitDataChar = nil
    }
}

// MARK: - CBPeripheralDelegate
extension KeychainBluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == KeychainBLE.serviceUUID {
            peripheral.discoverCharacteristics([KeychainBLE.buttonCountsCharUUID, KeychainBLE.habitDataCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars {
            if char.uuid == KeychainBLE.buttonCountsCharUUID {
                buttonCountsChar = char
                peripheral.setNotifyValue(true, for: char) // subscribe to live updates
            }
            if char.uuid == KeychainBLE.habitDataCharUUID {
                habitDataChar = char
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == KeychainBLE.buttonCountsCharUUID,
              let data = characteristic.value else { return }
        parseButtonCounts(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            lastAlert = "Write failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - CBManagerState description helper
extension CBManagerState {
    var description: String {
        switch self {
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Habit Payload (sent to keychain)
struct HabitPayload: Codable {
    var habitNames: [String]   // up to 9, one per button
    var alerts: [String]       // optional alert messages
}


// ============================================================
// MARK: - Device Setup View
// ============================================================
struct DeviceSetupView: View {
    @StateObject private var ble = KeychainBluetoothManager.shared
    @State private var showButtonDashboard = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── Status banner ──
                        ConnectionBanner(state: ble.connectionState, device: ble.connectedDevice)

                        // ── Scan controls ──
                        if case .connected = ble.connectionState {
                            // Already connected — show dashboard link
                            NavigationLink(destination: ButtonDashboardView(ble: ble)) {
                                Label("View Button Dashboard", systemImage: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
                            }
                            .padding(.horizontal)

                            Button(role: .destructive) { ble.disconnect() } label: {
                                Label("Disconnect", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray5)))
                            }
                            .padding(.horizontal)

                        } else {
                            ScanButton(scanState: ble.scanState) {
                                ble.scanState == .scanning ? ble.stopScan() : ble.startScan()
                            }
                        }

                        // ── Device list ──
                        if !ble.discoveredDevices.isEmpty {
                            DeviceListSection(devices: ble.discoveredDevices, connectionState: ble.connectionState) { device in
                                ble.connect(to: device)
                            }
                        } else if ble.scanState == .done {
                            Text("No keychain devices found.\nMake sure it's powered on and nearby.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 15))
                                .padding()
                        }

                        if ble.scanState == .scanning {
                            ProgressView("Searching for devices…")
                                .padding()
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Device Setup")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Sub-views

struct ConnectionBanner: View {
    let state: KeychainBluetoothManager.ConnectionState
    let device: KeychainDevice?

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(bannerColor)
                .frame(width: 12, height: 12)
                .shadow(color: bannerColor.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.system(size: 15, weight: .semibold))
                if let name = device?.name {
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if case .error(let msg) = state {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
    }

    var bannerColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .orange
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    var bannerTitle: String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting…"
        case .error: return "Error"
        case .disconnected: return "Not Connected"
        }
    }
}

struct ScanButton: View {
    let scanState: KeychainBluetoothManager.ScanState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if scanState == .scanning {
                    ProgressView().tint(.white).padding(.trailing, 4)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                Text(scanState == .scanning ? "Stop Scanning" : "Scan for Keychain")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(scanState == .scanning ? Color.orange : Color.blue)
            )
        }
        .padding(.horizontal)
        .buttonStyle(.plain)
    }
}

struct DeviceListSection: View {
    let devices: [KeychainDevice]
    let connectionState: KeychainBluetoothManager.ConnectionState
    let onConnect: (KeychainDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEARBY DEVICES")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(devices) { device in
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.system(size: 15, weight: .medium))
                            Text("Signal: \(device.rssi) dBm")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if case .connecting = connectionState {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button("Connect") { onConnect(device) }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))

                    if device.id != devices.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }
}

// ============================================================
// MARK: - Button Dashboard View
// ============================================================
struct ButtonDashboardView: View {
    @ObservedObject var ble: KeychainBluetoothManager
    @State private var habitNames: [String] = Array(repeating: "", count: 9)
    @State private var showSendAlert = false

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // 3×3 button grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ble.buttonStates) { btn in
                        ButtonCard(
                            button: btn,
                            habitName: habitNames[btn.id - 1]
                        )
                    }
                }
                .padding(.horizontal)

                // Send habit data back to keychain
                VStack(alignment: .leading, spacing: 12) {
                    Text("ASSIGN HABITS TO BUTTONS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)

                    ForEach(0..<9, id: \.self) { i in
                        HStack {
                            Text("Button \(i + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 72, alignment: .leading)
                            TextField("Habit name…", text: $habitNames[i])
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Button {
                        let payload = HabitPayload(
                            habitNames: habitNames,
                            alerts: habitNames.map { $0.isEmpty ? "" : "Keep it up with \($0)!" }
                        )
                        ble.sendHabitData(payload)
                        showSendAlert = true
                    } label: {
                        Label("Send to Keychain", systemImage: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Button Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sent!", isPresented: $showSendAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Habit data sent to your keychain.")
        }
    }
}

struct ButtonCard: View {
    let button: ButtonState
    let habitName: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(button.pressCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(button.pressCount > 0 ? Color.blue : Color(.systemGray3))

            Text(habitName.isEmpty ? "Button \(button.id)" : habitName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let date = button.lastUpdated {
                Text(date, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    DeviceSetupView()
}
