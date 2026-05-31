import Foundation
import Combine

class NodeWalletStore: ObservableObject {
    static let shared = NodeWalletStore()

    @Published var isOnboarded: Bool = false
    @Published var validatorId: String?
    @Published var classicalPk: String?
    @Published var displayName: String?
    @Published var balanceSpark: UInt64 = 0
    @Published var rewardsEarnedSpark: UInt64 = 0
    @Published var todayRewardsSpark: UInt64 = 0

    var balanceINDRA: Double { Double(balanceSpark) / 100_000_000.0 }
    var rewardsINDRA: Double { Double(rewardsEarnedSpark) / 100_000_000.0 }
    var todayINDRA:   Double { Double(todayRewardsSpark) / 100_000_000.0 }

    private init() {
        let onboarded = UserDefaults.standard.bool(forKey: "indra.node.onboarded")
        let id = UserDefaults.standard.string(forKey: "indra.node.validator_id")
        let pk = UserDefaults.standard.string(forKey: "indra.node.classical_pk")
        
        
        isOnboarded = onboarded
        validatorId = id
        classicalPk = pk
        displayName = UserDefaults.standard.string(forKey: "indra.node.display_name")
        
        if isOnboarded, let vid = validatorId, vid.count != 64 {
            reloadFromKeysJson()
        }
    }

    func reloadFromKeysJson() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let keysPath = appSupport.appendingPathComponent("INDRANode/keys.json")
        guard let data = try? Data(contentsOf: keysPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["validator_id"] as? String,
              let pub = json["public"] as? [String: Any],
              let pk = pub["hybrid_classical_pk"] as? String else { return }
        self.validatorId = id
        self.classicalPk = pk
        UserDefaults.standard.set(id, forKey: "indra.node.validator_id")
        UserDefaults.standard.set(pk, forKey: "indra.node.classical_pk")
    }

    func saveIdentity(validatorId: String, classicalPk: String, displayName: String? = nil) {
        if let name = displayName, !name.isEmpty {
            self.displayName = name
            UserDefaults.standard.set(name, forKey: "indra.node.display_name")
        }
        self.validatorId = validatorId
        self.classicalPk = classicalPk
        self.isOnboarded = true
        UserDefaults.standard.set(validatorId, forKey: "indra.node.validator_id")
        UserDefaults.standard.set(classicalPk, forKey: "indra.node.classical_pk")
        UserDefaults.standard.set(true, forKey: "indra.node.onboarded")
    }

    func reset() {
        validatorId = nil
        classicalPk = nil
        balanceSpark = 0
        rewardsEarnedSpark = 0
        isOnboarded = false
        UserDefaults.standard.removeObject(forKey: "indra.node.validator_id")
        UserDefaults.standard.removeObject(forKey: "indra.node.classical_pk")
        UserDefaults.standard.removeObject(forKey: "indra.node.display_name")
        UserDefaults.standard.removeObject(forKey: "indra.node.display_name")
        UserDefaults.standard.removeObject(forKey: "indra.node.onboarded")
    }
}
