// Models for Firebase-based real-time party sharing
// Independent from SAT connection — guests only need Firebase

class FbPartyMeta {
  final String hostName;
  final int createdAt;
  final int lastPushAt;
  final int maxMembers;
  final int pushIntervalSeconds;

  const FbPartyMeta({
    required this.hostName,
    required this.createdAt,
    required this.lastPushAt,
    required this.maxMembers,
    required this.pushIntervalSeconds,
  });

  Map<String, dynamic> toMap() => {
        'hostName': hostName,
        'createdAt': createdAt,
        'lastPushAt': lastPushAt,
        'maxMembers': maxMembers,
        'pushIntervalSeconds': pushIntervalSeconds,
      };

  factory FbPartyMeta.fromMap(Map<dynamic, dynamic> map) => FbPartyMeta(
        hostName: map['hostName'] as String? ?? '',
        createdAt: map['createdAt'] as int? ?? 0,
        lastPushAt: map['lastPushAt'] as int? ?? 0,
        maxMembers: map['maxMembers'] as int? ?? 5,
        pushIntervalSeconds: map['pushIntervalSeconds'] as int? ?? 10,
      );

  /// Party is considered stale if host hasn't pushed in 30 minutes
  bool get isStale {
    final diff = DateTime.now().millisecondsSinceEpoch - lastPushAt;
    return diff > 30 * 60 * 1000;
  }
}

class FbPartyMember {
  final String name;
  final double damage;
  final double dps;
  final double fame;
  final double silver;
  final String weapon; // uniqueName del arma principal (para imagen)
  final int lastUpdated;

  const FbPartyMember({
    required this.name,
    required this.damage,
    required this.dps,
    required this.fame,
    required this.silver,
    this.weapon = '',
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'damage': damage,
        'dps': dps,
        'fame': fame,
        'silver': silver,
        'weapon': weapon,
        'lastUpdated': lastUpdated,
      };

  factory FbPartyMember.fromMap(String name, Map<dynamic, dynamic> map) =>
      FbPartyMember(
        name: name,
        damage: (map['damage'] as num?)?.toDouble() ?? 0.0,
        dps: (map['dps'] as num?)?.toDouble() ?? 0.0,
        fame: (map['fame'] as num?)?.toDouble() ?? 0.0,
        silver: (map['silver'] as num?)?.toDouble() ?? 0.0,
        weapon: map['weapon'] as String? ?? '',
        lastUpdated: map['lastUpdated'] as int? ?? 0,
      );

  FbPartyMember copyWith({double? damage, double? dps, double? fame, double? silver, String? weapon}) =>
      FbPartyMember(
        name: name,
        damage: damage ?? this.damage,
        dps: dps ?? this.dps,
        fame: fame ?? this.fame,
        silver: silver ?? this.silver,
        weapon: weapon ?? this.weapon,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
}

class FbPartySnapshot {
  final FbPartyMeta meta;
  final List<FbPartyMember> members;

  const FbPartySnapshot({required this.meta, required this.members});

  int get memberCount => members.length;

  List<FbPartyMember> get sortedByDamage =>
      List.of(members)..sort((a, b) => b.damage.compareTo(a.damage));

  double get totalDamage => members.fold(0, (s, m) => s + m.damage);
  double get totalFame => members.fold(0, (s, m) => s + m.fame);
  double get totalSilver => members.fold(0, (s, m) => s + m.silver);
}

enum FbPartyRole { none, host, guest }
