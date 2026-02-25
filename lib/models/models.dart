// ==================== Dashboard Models ====================

class DashboardData {
  final double famePerHour;
  final double silverPerHour;
  final double reSpecPointsPerHour;
  final double mightPerHour;
  final double favorPerHour;
  final double silverCostForReSpecHour;

  final double totalGainedFameInSession;
  final double totalGainedSilverInSession;
  final double totalGainedReSpecPointsInSession;
  final double totalGainedMightInSession;
  final double totalGainedFavorInSession;
  final double totalGainedSilverCostForReSpecInSession;

  final double fameInPercent;
  final double silverInPercent;
  final double reSpecPointsInPercent;
  final double mightInPercent;
  final double favorInPercent;

  final int killsToday;
  final int killsThisWeek;
  final int killsThisMonth;
  final int deathsToday;
  final int deathsThisWeek;
  final int deathsThisMonth;
  final int soloKillsToday;
  final int soloKillsThisWeek;
  final int soloKillsThisMonth;

  final double averageItemPowerWhenKilling;
  final double averageItemPowerOfTheKilledEnemies;
  final double averageItemPowerWhenDying;

  final int repairCostsToday;
  final int repairCostsLast7Days;
  final int repairCostsLast30Days;

  final LootedChestsData lootedChests;
  final List<FactionPointStat> factionPointStats;

  DashboardData({
    this.famePerHour = 0,
    this.silverPerHour = 0,
    this.reSpecPointsPerHour = 0,
    this.mightPerHour = 0,
    this.favorPerHour = 0,
    this.silverCostForReSpecHour = 0,
    this.totalGainedFameInSession = 0,
    this.totalGainedSilverInSession = 0,
    this.totalGainedReSpecPointsInSession = 0,
    this.totalGainedMightInSession = 0,
    this.totalGainedFavorInSession = 0,
    this.totalGainedSilverCostForReSpecInSession = 0,
    this.fameInPercent = 0,
    this.silverInPercent = 0,
    this.reSpecPointsInPercent = 0,
    this.mightInPercent = 0,
    this.favorInPercent = 0,
    this.killsToday = 0,
    this.killsThisWeek = 0,
    this.killsThisMonth = 0,
    this.deathsToday = 0,
    this.deathsThisWeek = 0,
    this.deathsThisMonth = 0,
    this.soloKillsToday = 0,
    this.soloKillsThisWeek = 0,
    this.soloKillsThisMonth = 0,
    this.averageItemPowerWhenKilling = 0,
    this.averageItemPowerOfTheKilledEnemies = 0,
    this.averageItemPowerWhenDying = 0,
    this.repairCostsToday = 0,
    this.repairCostsLast7Days = 0,
    this.repairCostsLast30Days = 0,
    LootedChestsData? lootedChests,
    List<FactionPointStat>? factionPointStats,
  })  : lootedChests = lootedChests ?? LootedChestsData(),
        factionPointStats = factionPointStats ?? [];

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      famePerHour: (json['famePerHour'] ?? 0).toDouble(),
      silverPerHour: (json['silverPerHour'] ?? 0).toDouble(),
      reSpecPointsPerHour: (json['reSpecPointsPerHour'] ?? 0).toDouble(),
      mightPerHour: (json['mightPerHour'] ?? 0).toDouble(),
      favorPerHour: (json['favorPerHour'] ?? 0).toDouble(),
      silverCostForReSpecHour: (json['silverCostForReSpecHour'] ?? 0).toDouble(),
      totalGainedFameInSession: (json['totalGainedFameInSession'] ?? 0).toDouble(),
      totalGainedSilverInSession: (json['totalGainedSilverInSession'] ?? 0).toDouble(),
      totalGainedReSpecPointsInSession: (json['totalGainedReSpecPointsInSession'] ?? 0).toDouble(),
      totalGainedMightInSession: (json['totalGainedMightInSession'] ?? 0).toDouble(),
      totalGainedFavorInSession: (json['totalGainedFavorInSession'] ?? 0).toDouble(),
      totalGainedSilverCostForReSpecInSession: (json['totalGainedSilverCostForReSpecInSession'] ?? 0).toDouble(),
      fameInPercent: (json['fameInPercent'] ?? 0).toDouble(),
      silverInPercent: (json['silverInPercent'] ?? 0).toDouble(),
      reSpecPointsInPercent: (json['reSpecPointsInPercent'] ?? 0).toDouble(),
      mightInPercent: (json['mightInPercent'] ?? 0).toDouble(),
      favorInPercent: (json['favorInPercent'] ?? 0).toDouble(),
      killsToday: json['killsToday'] ?? 0,
      killsThisWeek: json['killsThisWeek'] ?? 0,
      killsThisMonth: json['killsThisMonth'] ?? 0,
      deathsToday: json['deathsToday'] ?? 0,
      deathsThisWeek: json['deathsThisWeek'] ?? 0,
      deathsThisMonth: json['deathsThisMonth'] ?? 0,
      soloKillsToday: json['soloKillsToday'] ?? 0,
      soloKillsThisWeek: json['soloKillsThisWeek'] ?? 0,
      soloKillsThisMonth: json['soloKillsThisMonth'] ?? 0,
      averageItemPowerWhenKilling: (json['averageItemPowerWhenKilling'] ?? 0).toDouble(),
      averageItemPowerOfTheKilledEnemies: (json['averageItemPowerOfTheKilledEnemies'] ?? 0).toDouble(),
      averageItemPowerWhenDying: (json['averageItemPowerWhenDying'] ?? 0).toDouble(),
      repairCostsToday: json['repairCostsToday'] ?? 0,
      repairCostsLast7Days: json['repairCostsLast7Days'] ?? 0,
      repairCostsLast30Days: json['repairCostsLast30Days'] ?? 0,
      lootedChests: json['lootedChests'] != null ? LootedChestsData.fromJson(json['lootedChests']) : null,
      factionPointStats: (json['factionPointStats'] as List?)?.map((e) => FactionPointStat.fromJson(e)).toList(),
    );
  }
}

class LootedChestsData {
  final int openedCommon;
  final int openedUncommon;
  final int openedRare;
  final int openedLegendary;

  LootedChestsData({
    this.openedCommon = 0,
    this.openedUncommon = 0,
    this.openedRare = 0,
    this.openedLegendary = 0,
  });

  factory LootedChestsData.fromJson(Map<String, dynamic> json) {
    return LootedChestsData(
      openedCommon: json['openedCommon'] ?? 0,
      openedUncommon: json['openedUncommon'] ?? 0,
      openedRare: json['openedRare'] ?? 0,
      openedLegendary: json['openedLegendary'] ?? 0,
    );
  }

  int get total => openedCommon + openedUncommon + openedRare + openedLegendary;
}

class FactionPointStat {
  final String cityFaction;
  final double value;
  final double valuePerHour;

  FactionPointStat({this.cityFaction = '', this.value = 0, this.valuePerHour = 0});

  factory FactionPointStat.fromJson(Map<String, dynamic> json) {
    return FactionPointStat(
      cityFaction: json['cityFaction'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      valuePerHour: (json['valuePerHour'] ?? 0).toDouble(),
    );
  }
}

// ==================== Damage Meter Models ====================

class DamageMeterData {
  final List<DamageMeterFragment> fragments;
  final String sortType;
  final bool isDamageMeterResetByMapChangeActive;
  final bool isDamageMeterResetBeforeCombatActive;

  DamageMeterData({
    List<DamageMeterFragment>? fragments,
    this.sortType = 'Damage',
    this.isDamageMeterResetByMapChangeActive = false,
    this.isDamageMeterResetBeforeCombatActive = false,
  }) : fragments = fragments ?? [];

  factory DamageMeterData.fromJson(Map<String, dynamic> json) {
    return DamageMeterData(
      fragments: (json['fragments'] as List?)?.map((e) => DamageMeterFragment.fromJson(e)).toList(),
      sortType: json['sortType'] ?? 'Damage',
      isDamageMeterResetByMapChangeActive: json['isDamageMeterResetByMapChangeActive'] ?? false,
      isDamageMeterResetBeforeCombatActive: json['isDamageMeterResetBeforeCombatActive'] ?? false,
    );
  }
}

class DamageMeterFragment {
  final String causerGuid;
  final String name;
  final int damage;
  final String damageShortString;
  final double dps;
  final String dpsString;
  final double damageInPercent;
  final double damagePercentage;
  final int heal;
  final String healShortString;
  final double hps;
  final String hpsString;
  final double healInPercent;
  final double healPercentage;
  final double overhealed;
  final double overhealedPercentageOfTotalHealing;
  final int takenDamage;
  final String takenDamageShortString;
  final double takenDamageInPercent;
  final double takenDamagePercentage;
  final String combatTime;
  final ItemData? causerMainHand;
  final List<UsedSpellData> spells;

  DamageMeterFragment({
    this.causerGuid = '',
    this.name = '',
    this.damage = 0,
    this.damageShortString = '',
    this.dps = 0,
    this.dpsString = '',
    this.damageInPercent = 0,
    this.damagePercentage = 0,
    this.heal = 0,
    this.healShortString = '',
    this.hps = 0,
    this.hpsString = '',
    this.healInPercent = 0,
    this.healPercentage = 0,
    this.overhealed = 0,
    this.overhealedPercentageOfTotalHealing = 0,
    this.takenDamage = 0,
    this.takenDamageShortString = '',
    this.takenDamageInPercent = 0,
    this.takenDamagePercentage = 0,
    this.combatTime = '',
    this.causerMainHand,
    List<UsedSpellData>? spells,
  }) : spells = spells ?? [];

  factory DamageMeterFragment.fromJson(Map<String, dynamic> json) {
    return DamageMeterFragment(
      causerGuid: json['causerGuid'] ?? '',
      name: json['name'] ?? '',
      damage: json['damage'] ?? 0,
      damageShortString: json['damageShortString'] ?? '',
      dps: (json['dps'] ?? 0).toDouble(),
      dpsString: json['dpsString'] ?? '',
      damageInPercent: (json['damageInPercent'] ?? 0).toDouble(),
      damagePercentage: (json['damagePercentage'] ?? 0).toDouble(),
      heal: json['heal'] ?? 0,
      healShortString: json['healShortString'] ?? '',
      hps: (json['hps'] ?? 0).toDouble(),
      hpsString: json['hpsString'] ?? '',
      healInPercent: (json['healInPercent'] ?? 0).toDouble(),
      healPercentage: (json['healPercentage'] ?? 0).toDouble(),
      overhealed: (json['overhealed'] ?? 0).toDouble(),
      overhealedPercentageOfTotalHealing: (json['overhealedPercentageOfTotalHealing'] ?? 0).toDouble(),
      takenDamage: json['takenDamage'] ?? 0,
      takenDamageShortString: json['takenDamageShortString'] ?? '',
      takenDamageInPercent: (json['takenDamageInPercent'] ?? 0).toDouble(),
      takenDamagePercentage: (json['takenDamagePercentage'] ?? 0).toDouble(),
      combatTime: json['combatTime'] ?? '',
      causerMainHand: json['causerMainHand'] != null ? ItemData.fromJson(json['causerMainHand']) : null,
      spells: (json['spells'] as List?)?.map((e) => UsedSpellData.fromJson(e)).toList(),
    );
  }
}

class UsedSpellData {
  final int spellIndex;
  final String uniqueName;
  final String itemName;
  final int damageHealValue;
  final String damageHealShortString;
  final String category;

  UsedSpellData({
    this.spellIndex = 0,
    this.uniqueName = '',
    this.itemName = '',
    this.damageHealValue = 0,
    this.damageHealShortString = '',
    this.category = '',
  });

  factory UsedSpellData.fromJson(Map<String, dynamic> json) {
    return UsedSpellData(
      spellIndex: json['spellIndex'] ?? 0,
      uniqueName: json['uniqueName'] ?? '',
      itemName: json['itemName'] ?? '',
      damageHealValue: json['damageHealValue'] ?? 0,
      damageHealShortString: json['damageHealShortString'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

// ==================== Dungeon Models ====================

class DungeonListData {
  final List<DungeonFragment> dungeons;
  final DungeonStats stats;

  DungeonListData({List<DungeonFragment>? dungeons, DungeonStats? stats})
      : dungeons = dungeons ?? [],
        stats = stats ?? DungeonStats();

  factory DungeonListData.fromJson(Map<String, dynamic> json) {
    return DungeonListData(
      dungeons: (json['dungeons'] as List?)?.map((e) => DungeonFragment.fromJson(e)).toList(),
      stats: json['stats'] != null ? DungeonStats.fromJson(json['stats']) : null,
    );
  }
}

class DungeonFragment {
  final String dungeonHash;
  final String mode;
  final String mapType;
  final String status;
  final String tier;
  final int level;
  final String faction;
  final String cityFaction;
  final String enterDungeonFirstTime;
  final double fame;
  final double silver;
  final double reSpec;
  final double might;
  final double favor;
  final double factionCoins;
  final double factionFlags;
  final double famePerHour;
  final double silverPerHour;
  final double reSpecPerHour;
  final int totalRunTimeInSeconds;
  final int numberOfFloors;
  final double totalValue;
  final String mainMapIndex;
  final String mainMapName;
  final String killedBy;
  final String diedName;
  final String killStatus;
  final List<DungeonLoot> loot;
  final List<DungeonEvent> events;
  final DungeonLoot? mostValuableLoot;

  DungeonFragment({
    this.dungeonHash = '',
    this.mode = '',
    this.mapType = '',
    this.status = '',
    this.tier = '',
    this.level = -1,
    this.faction = '',
    this.cityFaction = '',
    this.enterDungeonFirstTime = '',
    this.fame = 0,
    this.silver = 0,
    this.reSpec = 0,
    this.might = 0,
    this.favor = 0,
    this.factionCoins = 0,
    this.factionFlags = 0,
    this.famePerHour = 0,
    this.silverPerHour = 0,
    this.reSpecPerHour = 0,
    this.totalRunTimeInSeconds = 0,
    this.numberOfFloors = 1,
    this.totalValue = 0,
    this.mainMapIndex = '',
    this.mainMapName = '',
    this.killedBy = '',
    this.diedName = '',
    this.killStatus = '',
    List<DungeonLoot>? loot,
    List<DungeonEvent>? events,
    this.mostValuableLoot,
  })  : loot = loot ?? [],
        events = events ?? [];

  factory DungeonFragment.fromJson(Map<String, dynamic> json) {
    return DungeonFragment(
      dungeonHash: json['dungeonHash'] ?? '',
      mode: json['mode'] ?? '',
      mapType: json['mapType'] ?? '',
      status: json['status'] ?? '',
      tier: json['tier'] ?? '',
      level: json['level'] ?? -1,
      faction: json['faction'] ?? '',
      cityFaction: json['cityFaction'] ?? '',
      enterDungeonFirstTime: json['enterDungeonFirstTime'] ?? '',
      fame: (json['fame'] ?? 0).toDouble(),
      silver: (json['silver'] ?? 0).toDouble(),
      reSpec: (json['reSpec'] ?? 0).toDouble(),
      might: (json['might'] ?? 0).toDouble(),
      favor: (json['favor'] ?? 0).toDouble(),
      factionCoins: (json['factionCoins'] ?? 0).toDouble(),
      factionFlags: (json['factionFlags'] ?? 0).toDouble(),
      famePerHour: (json['famePerHour'] ?? 0).toDouble(),
      silverPerHour: (json['silverPerHour'] ?? 0).toDouble(),
      reSpecPerHour: (json['reSpecPerHour'] ?? 0).toDouble(),
      totalRunTimeInSeconds: json['totalRunTimeInSeconds'] ?? 0,
      numberOfFloors: json['numberOfFloors'] ?? 1,
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      mainMapIndex: json['mainMapIndex'] ?? '',
      mainMapName: json['mainMapName'] ?? '',
      killedBy: json['killedBy'] ?? '',
      diedName: json['diedName'] ?? '',
      killStatus: json['killStatus'] ?? '',
      loot: (json['loot'] as List?)?.map((e) => DungeonLoot.fromJson(e)).toList(),
      events: (json['events'] as List?)?.map((e) => DungeonEvent.fromJson(e)).toList(),
      mostValuableLoot: json['mostValuableLoot'] != null ? DungeonLoot.fromJson(json['mostValuableLoot']) : null,
    );
  }

  String get formattedRunTime {
    final hours = totalRunTimeInSeconds ~/ 3600;
    final minutes = (totalRunTimeInSeconds % 3600) ~/ 60;
    final seconds = totalRunTimeInSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  /// Returns the level string like ".0", ".1", ".2", ".3", ".4"
  String get levelString {
    if (level < 0) return '';
    if (level > 4) return '.?';
    return '.$level';
  }

  /// Display name combining tier + level, e.g. "T4.2"
  String get tierDisplay {
    final t = tier.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.isEmpty) return tier;
    if (level >= 0) return 'T$t.$level';
    return 'T$t';
  }

  /// Returns the butterfly asset name for the enchantment level
  String? get butterflyAsset {
    switch (level) {
      case 0: return 'assets/icons/butterfly_common.png';
      case 1: return 'assets/icons/butterfly_uncommon.png';
      case 2: return 'assets/icons/butterfly_rare.png';
      case 3: return 'assets/icons/butterfly_epic.png';
      case 4: return 'assets/icons/butterfly_legendary.png';
      default: return null;
    }
  }

  /// Returns the faction banner asset path
  String? get factionBannerAsset {
    switch (faction.toLowerCase()) {
      case 'keeper': return 'assets/icons/faction_keeper_banner.png';
      case 'heretic': return 'assets/icons/faction_heretic_banner.png';
      case 'morgana': return 'assets/icons/faction_morgana_banner.png';
      case 'undead': return 'assets/icons/faction_undead_banner.png';
      case 'avalon': return 'assets/icons/faction_avalon_banner.png';
      case 'corrupted': return 'assets/icons/corrupted_banner.png';
      case 'hellgate': return 'assets/icons/hellgate_banner.png';
      case 'mists': return 'assets/icons/mists_banner.png';
      case 'mistsdungeon': return 'assets/icons/mists_dungeon_banner.png';
      case 'abyssaldepths': return 'assets/icons/abyssal_depths_banner.png';
      default: return null;
    }
  }

  /// Returns dungeon type icon asset
  String get dungeonTypeAsset {
    switch (mapType.toLowerCase()) {
      case 'corrupteddungeon': return 'assets/icons/corrupted_banner.png';
      case 'hellgate': return 'assets/icons/hellgate_banner.png';
      case 'expedition': return 'assets/icons/dungeon.png';
      case 'mists': return 'assets/icons/mists_banner.png';
      case 'mistsdungeon': return 'assets/icons/mists_dungeon.png';
      case 'abyssaldepths': return 'assets/icons/abyssal_depths.png';
      default: return 'assets/icons/dungeon.png';
    }
  }
}

class DungeonLoot {
  final String uniqueName;
  final String itemName;
  final int quantity;
  final double estimatedMarketValue;
  final String lootedByName;
  final String lootedFromName;
  final bool isTrash;

  DungeonLoot({
    this.uniqueName = '',
    this.itemName = '',
    this.quantity = 0,
    this.estimatedMarketValue = 0,
    this.lootedByName = '',
    this.lootedFromName = '',
    this.isTrash = false,
  });

  factory DungeonLoot.fromJson(Map<String, dynamic> json) {
    return DungeonLoot(
      uniqueName: json['uniqueName'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      estimatedMarketValue: (json['estimatedMarketValue'] ?? 0).toDouble(),
      lootedByName: json['lootedByName'] ?? '',
      lootedFromName: json['lootedFromName'] ?? '',
      isTrash: json['isTrash'] ?? false,
    );
  }

  String get imageUrl => 'https://render.albiononline.com/v1/item/$uniqueName.png';
}

class DungeonEvent {
  final int id;
  final String type;
  final String uniqueName;
  final String status;
  final bool isBossChest;
  final String rarity;
  final String shrineType;
  final String shrineBuff;

  DungeonEvent({
    this.id = 0,
    this.type = '',
    this.uniqueName = '',
    this.status = '',
    this.isBossChest = false,
    this.rarity = '',
    this.shrineType = '',
    this.shrineBuff = '',
  });

  factory DungeonEvent.fromJson(Map<String, dynamic> json) {
    return DungeonEvent(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      uniqueName: json['uniqueName'] ?? json['name'] ?? '',
      status: json['status'] ?? (json['isOpen'] == true ? 'Open' : 'Close'),
      isBossChest: json['isBossChest'] ?? false,
      rarity: json['rarity'] ?? '',
      shrineType: json['shrineType'] ?? '',
      shrineBuff: json['shrineBuff'] ?? '',
    );
  }

  bool get isOpen => status == 'Open';

  bool get isChest => type == 'Chest' || type == 'BookChest';
  bool get isShrine => type == 'CombatShrine' || type == 'SilverShrine' || type == 'FameShrine' || type == 'HellDungeonShrine';

  /// Returns the chest asset path based on rarity and open/close state
  String? get chestAsset {
    if (!isChest) return null;
    final prefix = isOpen ? 'chest_open' : 'chest_close';
    switch (rarity.toLowerCase()) {
      case 'common': return 'assets/icons/${prefix}_standard.png';
      case 'uncommon': return 'assets/icons/${prefix}_uncommon.png';
      case 'rare': return 'assets/icons/${prefix}_rare.png';
      case 'legendary': return 'assets/icons/${prefix}_legendary.png';
      default: return 'assets/icons/${prefix}_standard.png';
    }
  }

  /// Returns the shrine asset path
  String? get shrineAsset {
    if (!isShrine) return null;
    switch (shrineBuff.toLowerCase()) {
      case 'fame': return 'assets/icons/shrine_fame.png';
      case 'silver': return 'assets/icons/shrine_silver.png';
      case 'combat': return 'assets/icons/shrine_combat_buff.png';
      default: return 'assets/icons/shrine_combat_buff.png';
    }
  }

  /// Returns a human-readable label
  String get displayName {
    if (isChest) {
      final boss = isBossChest ? 'Cofre de Jefe' : 'Cofre';
      final r = _rarityLabel;
      return r.isNotEmpty ? '$boss ($r)' : boss;
    }
    if (isShrine) {
      switch (shrineBuff.toLowerCase()) {
        case 'fame': return 'Santuario de Fama';
        case 'silver': return 'Santuario de Plata';
        case 'combat': return 'Santuario de Combate';
        default: return 'Santuario';
      }
    }
    return uniqueName;
  }

  String get _rarityLabel {
    switch (rarity.toLowerCase()) {
      case 'common': return 'Común';
      case 'uncommon': return 'Poco Común';
      case 'rare': return 'Raro';
      case 'legendary': return 'Legendario';
      default: return '';
    }
  }
}

class DungeonStats {
  final DungeonStatCategory solo;
  final DungeonStatCategory standard;
  final DungeonStatCategory avalonian;
  final DungeonStatCategory corrupted;
  final DungeonStatCategory hellGate;
  final DungeonStatCategory expedition;
  final DungeonStatCategory mists;
  final DungeonStatCategory mistsDungeon;
  final DungeonStatCategory abyssalDepths;
  final DungeonStatCategory total;

  DungeonStats({
    DungeonStatCategory? solo,
    DungeonStatCategory? standard,
    DungeonStatCategory? avalonian,
    DungeonStatCategory? corrupted,
    DungeonStatCategory? hellGate,
    DungeonStatCategory? expedition,
    DungeonStatCategory? mists,
    DungeonStatCategory? mistsDungeon,
    DungeonStatCategory? abyssalDepths,
    DungeonStatCategory? total,
  })  : solo = solo ?? DungeonStatCategory(),
        standard = standard ?? DungeonStatCategory(),
        avalonian = avalonian ?? DungeonStatCategory(),
        corrupted = corrupted ?? DungeonStatCategory(),
        hellGate = hellGate ?? DungeonStatCategory(),
        expedition = expedition ?? DungeonStatCategory(),
        mists = mists ?? DungeonStatCategory(),
        mistsDungeon = mistsDungeon ?? DungeonStatCategory(),
        abyssalDepths = abyssalDepths ?? DungeonStatCategory(),
        total = total ?? DungeonStatCategory();

  factory DungeonStats.fromJson(Map<String, dynamic> json) {
    return DungeonStats(
      solo: json['solo'] != null ? DungeonStatCategory.fromJson(json['solo']) : null,
      standard: json['standard'] != null ? DungeonStatCategory.fromJson(json['standard']) : null,
      avalonian: json['avalonian'] != null ? DungeonStatCategory.fromJson(json['avalonian']) : null,
      corrupted: json['corrupted'] != null ? DungeonStatCategory.fromJson(json['corrupted']) : null,
      hellGate: json['hellGate'] != null ? DungeonStatCategory.fromJson(json['hellGate']) : null,
      expedition: json['expedition'] != null ? DungeonStatCategory.fromJson(json['expedition']) : null,
      mists: json['mists'] != null ? DungeonStatCategory.fromJson(json['mists']) : null,
      mistsDungeon: json['mistsDungeon'] != null ? DungeonStatCategory.fromJson(json['mistsDungeon']) : null,
      abyssalDepths: json['abyssalDepths'] != null ? DungeonStatCategory.fromJson(json['abyssalDepths']) : null,
      total: json['total'] != null ? DungeonStatCategory.fromJson(json['total']) : null,
    );
  }
}

class DungeonStatCategory {
  final int enteredDungeon;
  final double fame;
  final double reSpec;
  final double silver;
  final double famePerHour;
  final double reSpecPerHour;
  final double silverPerHour;
  final double totalValue;
  final int bestTime;
  final double bestFame;
  final double bestReSpec;
  final double bestSilver;
  final double bestFamePerHour;
  final double bestReSpecPerHour;
  final double bestSilverPerHour;

  DungeonStatCategory({
    this.enteredDungeon = 0,
    this.fame = 0,
    this.reSpec = 0,
    this.silver = 0,
    this.famePerHour = 0,
    this.reSpecPerHour = 0,
    this.silverPerHour = 0,
    this.totalValue = 0,
    this.bestTime = 0,
    this.bestFame = 0,
    this.bestReSpec = 0,
    this.bestSilver = 0,
    this.bestFamePerHour = 0,
    this.bestReSpecPerHour = 0,
    this.bestSilverPerHour = 0,
  });

  factory DungeonStatCategory.fromJson(Map<String, dynamic> json) {
    return DungeonStatCategory(
      enteredDungeon: json['enteredDungeon'] ?? 0,
      fame: (json['fame'] ?? 0).toDouble(),
      reSpec: (json['reSpec'] ?? 0).toDouble(),
      silver: (json['silver'] ?? 0).toDouble(),
      famePerHour: (json['famePerHour'] ?? 0).toDouble(),
      reSpecPerHour: (json['reSpecPerHour'] ?? 0).toDouble(),
      silverPerHour: (json['silverPerHour'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      bestTime: json['bestTime'] ?? 0,
      bestFame: (json['bestFame'] ?? 0).toDouble(),
      bestReSpec: (json['bestReSpec'] ?? 0).toDouble(),
      bestSilver: (json['bestSilver'] ?? 0).toDouble(),
      bestFamePerHour: (json['bestFamePerHour'] ?? 0).toDouble(),
      bestReSpecPerHour: (json['bestReSpecPerHour'] ?? 0).toDouble(),
      bestSilverPerHour: (json['bestSilverPerHour'] ?? 0).toDouble(),
    );
  }
}

// ==================== Trade Models ====================

class TradeListData {
  final List<TradeData> trades;
  final TradeStatsData stats;

  TradeListData({List<TradeData>? trades, TradeStatsData? stats})
      : trades = trades ?? [],
        stats = stats ?? TradeStatsData();

  factory TradeListData.fromJson(Map<String, dynamic> json) {
    return TradeListData(
      trades: (json['trades'] as List?)?.map((e) => TradeData.fromJson(e)).toList(),
      stats: json['stats'] != null ? TradeStatsData.fromJson(json['stats']) : null,
    );
  }
}

class TradeData {
  final int id;
  final String timestamp;
  final String clusterIndex;
  final String type;
  final String locationName;
  final ItemData? item;
  final int quantity;
  final double totalPrice;
  final double unitPrice;
  final double taxRate;
  final double taxSetupRate;
  final double taxAmount;
  final double taxSetupAmount;
  final double totalRevenue;
  final double distanceFee;
  final String description;

  TradeData({
    this.id = 0,
    this.timestamp = '',
    this.clusterIndex = '',
    this.type = '',
    this.locationName = '',
    this.item,
    this.quantity = 0,
    this.totalPrice = 0,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.taxSetupRate = 0,
    this.taxAmount = 0,
    this.taxSetupAmount = 0,
    this.totalRevenue = 0,
    this.distanceFee = 0,
    this.description = '',
  });

  factory TradeData.fromJson(Map<String, dynamic> json) {
    return TradeData(
      id: json['id'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      clusterIndex: json['clusterIndex'] ?? '',
      type: json['type'] ?? '',
      locationName: json['locationName'] ?? '',
      item: json['item'] != null ? ItemData.fromJson(json['item']) : null,
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxSetupRate: (json['taxSetupRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      taxSetupAmount: (json['taxSetupAmount'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      distanceFee: (json['distanceFee'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  bool get isSale => type == 'InstantSell' || type == 'Mail';
  bool get isPurchase => type == 'InstantBuy';

  /// Total taxes (market fee + setup fee if any)
  double get totalTaxes => taxAmount + taxSetupAmount;

  /// Trade type label in Spanish
  String get typeLabel {
    switch (type) {
      case 'InstantSell': return 'Venta Instantánea';
      case 'InstantBuy': return 'Compra Instantánea';
      case 'Mail': return 'Venta (Orden)';
      case 'ManualSell': return 'Venta Manual';
      case 'ManualBuy': return 'Compra Manual';
      case 'Crafting': return 'Crafteo';
      default: return type;
    }
  }
}

class TradeStatsData {
  final int soldToday, boughtToday, salesToday, taxesToday;
  final int soldThisWeek, boughtThisWeek, salesThisWeek, taxesThisWeek;
  final int soldLastWeek, boughtLastWeek, salesLastWeek, taxesLastWeek;
  final int soldMonth, boughtMonth, salesMonth, taxesMonth;
  final int soldYear, boughtYear, salesYear, taxesYear;
  final int soldTotal, boughtTotal, salesTotal, taxesTotal;

  TradeStatsData({
    this.soldToday = 0, this.boughtToday = 0, this.salesToday = 0, this.taxesToday = 0,
    this.soldThisWeek = 0, this.boughtThisWeek = 0, this.salesThisWeek = 0, this.taxesThisWeek = 0,
    this.soldLastWeek = 0, this.boughtLastWeek = 0, this.salesLastWeek = 0, this.taxesLastWeek = 0,
    this.soldMonth = 0, this.boughtMonth = 0, this.salesMonth = 0, this.taxesMonth = 0,
    this.soldYear = 0, this.boughtYear = 0, this.salesYear = 0, this.taxesYear = 0,
    this.soldTotal = 0, this.boughtTotal = 0, this.salesTotal = 0, this.taxesTotal = 0,
  });

  factory TradeStatsData.fromJson(Map<String, dynamic> json) {
    return TradeStatsData(
      soldToday: json['soldToday'] ?? 0, boughtToday: json['boughtToday'] ?? 0,
      salesToday: json['salesToday'] ?? 0, taxesToday: json['taxesToday'] ?? 0,
      soldThisWeek: json['soldThisWeek'] ?? 0, boughtThisWeek: json['boughtThisWeek'] ?? 0,
      salesThisWeek: json['salesThisWeek'] ?? 0, taxesThisWeek: json['taxesThisWeek'] ?? 0,
      soldLastWeek: json['soldLastWeek'] ?? 0, boughtLastWeek: json['boughtLastWeek'] ?? 0,
      salesLastWeek: json['salesLastWeek'] ?? 0, taxesLastWeek: json['taxesLastWeek'] ?? 0,
      soldMonth: json['soldMonth'] ?? 0, boughtMonth: json['boughtMonth'] ?? 0,
      salesMonth: json['salesMonth'] ?? 0, taxesMonth: json['taxesMonth'] ?? 0,
      soldYear: json['soldYear'] ?? 0, boughtYear: json['boughtYear'] ?? 0,
      salesYear: json['salesYear'] ?? 0, taxesYear: json['taxesYear'] ?? 0,
      soldTotal: json['soldTotal'] ?? 0, boughtTotal: json['boughtTotal'] ?? 0,
      salesTotal: json['salesTotal'] ?? 0, taxesTotal: json['taxesTotal'] ?? 0,
    );
  }
}

// ==================== Gathering Models ====================

class GatheringListData {
  final List<GatheredData> gatheredItems;
  final GatheringStatsData stats;

  GatheringListData({List<GatheredData>? gatheredItems, GatheringStatsData? stats})
      : gatheredItems = gatheredItems ?? [],
        stats = stats ?? GatheringStatsData();

  factory GatheringListData.fromJson(Map<String, dynamic> json) {
    return GatheringListData(
      gatheredItems: (json['gatheredItems'] as List?)?.map((e) => GatheredData.fromJson(e)).toList(),
      stats: json['stats'] != null ? GatheringStatsData.fromJson(json['stats']) : null,
    );
  }
}

class GatheredData {
  final String guid;
  final String uniqueName;
  final String itemName;
  final int gainedStandardAmount;
  final int gainedBonusAmount;
  final int gainedPremiumBonusAmount;
  final int gainedTotalAmount;
  final int gainedFame;
  final int miningProcesses;
  final double estimatedMarketValue;
  final int totalMarketValue;
  final String clusterIndex;
  final String mapType;
  final String mapDisplayName;
  final String clusterMode;
  final String timestampUtc;
  final bool hasBeenFished;

  GatheredData({
    this.guid = '',
    this.uniqueName = '',
    this.itemName = '',
    this.gainedStandardAmount = 0,
    this.gainedBonusAmount = 0,
    this.gainedPremiumBonusAmount = 0,
    this.gainedTotalAmount = 0,
    this.gainedFame = 0,
    this.miningProcesses = 0,
    this.estimatedMarketValue = 0,
    this.totalMarketValue = 0,
    this.clusterIndex = '',
    this.mapType = '',
    this.mapDisplayName = '',
    this.clusterMode = '',
    this.timestampUtc = '',
    this.hasBeenFished = false,
  });

  factory GatheredData.fromJson(Map<String, dynamic> json) {
    return GatheredData(
      guid: json['guid'] ?? '',
      uniqueName: json['uniqueName'] ?? '',
      itemName: json['itemName'] ?? '',
      gainedStandardAmount: json['gainedStandardAmount'] ?? 0,
      gainedBonusAmount: json['gainedBonusAmount'] ?? 0,
      gainedPremiumBonusAmount: json['gainedPremiumBonusAmount'] ?? 0,
      gainedTotalAmount: json['gainedTotalAmount'] ?? 0,
      gainedFame: json['gainedFame'] ?? 0,
      miningProcesses: json['miningProcesses'] ?? 0,
      estimatedMarketValue: (json['estimatedMarketValue'] ?? 0).toDouble(),
      totalMarketValue: json['totalMarketValue'] ?? 0,
      clusterIndex: json['clusterIndex'] ?? '',
      mapType: json['mapType'] ?? '',
      mapDisplayName: json['mapDisplayName'] ?? '',
      clusterMode: json['clusterMode'] ?? '',
      timestampUtc: json['timestampUtc'] ?? '',
      hasBeenFished: json['hasBeenFished'] ?? false,
    );
  }

  String get imageUrl => 'https://render.albiononline.com/v1/item/$uniqueName.png';
}

class GatheringStatsData {
  final int totalMiningProcesses;
  final int totalResources;
  final int totalGainedSilver;
  final int gainedSilverByWood, gainedSilverByHide, gainedSilverByOre;
  final int gainedSilverByRock, gainedSilverByFiber, gainedSilverByFish;
  final int woodCount, hideCount, oreCount, rockCount, fiberCount, fishCount;

  GatheringStatsData({
    this.totalMiningProcesses = 0,
    this.totalResources = 0,
    this.totalGainedSilver = 0,
    this.gainedSilverByWood = 0, this.gainedSilverByHide = 0, this.gainedSilverByOre = 0,
    this.gainedSilverByRock = 0, this.gainedSilverByFiber = 0, this.gainedSilverByFish = 0,
    this.woodCount = 0, this.hideCount = 0, this.oreCount = 0,
    this.rockCount = 0, this.fiberCount = 0, this.fishCount = 0,
  });

  factory GatheringStatsData.fromJson(Map<String, dynamic> json) {
    return GatheringStatsData(
      totalMiningProcesses: json['totalMiningProcesses'] ?? 0,
      totalResources: json['totalResources'] ?? 0,
      totalGainedSilver: json['totalGainedSilver'] ?? 0,
      gainedSilverByWood: json['gainedSilverByWood'] ?? 0,
      gainedSilverByHide: json['gainedSilverByHide'] ?? 0,
      gainedSilverByOre: json['gainedSilverByOre'] ?? 0,
      gainedSilverByRock: json['gainedSilverByRock'] ?? 0,
      gainedSilverByFiber: json['gainedSilverByFiber'] ?? 0,
      gainedSilverByFish: json['gainedSilverByFish'] ?? 0,
      woodCount: json['woodCount'] ?? 0, hideCount: json['hideCount'] ?? 0,
      oreCount: json['oreCount'] ?? 0, rockCount: json['rockCount'] ?? 0,
      fiberCount: json['fiberCount'] ?? 0, fishCount: json['fishCount'] ?? 0,
    );
  }
}

// ==================== Party Models ====================

class PartyData {
  final List<PartyPlayerData> players;
  final double averagePartyIp;
  final double averagePartyBasicIp;
  final double minimalItemPower;
  final double maximumItemPower;

  PartyData({
    List<PartyPlayerData>? players,
    this.averagePartyIp = 0,
    this.averagePartyBasicIp = 0,
    this.minimalItemPower = 0,
    this.maximumItemPower = 0,
  }) : players = players ?? [];

  factory PartyData.fromJson(Map<String, dynamic> json) {
    return PartyData(
      players: (json['players'] as List?)?.map((e) => PartyPlayerData.fromJson(e)).toList(),
      averagePartyIp: (json['averagePartyIp'] ?? 0).toDouble(),
      averagePartyBasicIp: (json['averagePartyBasicIp'] ?? 0).toDouble(),
      minimalItemPower: (json['minimalItemPower'] ?? 0).toDouble(),
      maximumItemPower: (json['maximumItemPower'] ?? 0).toDouble(),
    );
  }
}

class PartyPlayerData {
  final String guid;
  final String username;
  final bool isLocalPlayer;
  final bool isPlayerInspected;
  final double averageItemPower;
  final double averageBasicItemPower;
  final String itemPowerCondition;
  final String basicItemPowerCondition;
  final bool isDeathAlertActive;
  final EquipmentData equipment;

  PartyPlayerData({
    this.guid = '',
    this.username = '',
    this.isLocalPlayer = false,
    this.isPlayerInspected = false,
    this.averageItemPower = 0,
    this.averageBasicItemPower = 0,
    this.itemPowerCondition = '',
    this.basicItemPowerCondition = '',
    this.isDeathAlertActive = false,
    EquipmentData? equipment,
  }) : equipment = equipment ?? EquipmentData();

  factory PartyPlayerData.fromJson(Map<String, dynamic> json) {
    return PartyPlayerData(
      guid: json['guid'] ?? '',
      username: json['username'] ?? '',
      isLocalPlayer: json['isLocalPlayer'] ?? false,
      isPlayerInspected: json['isPlayerInspected'] ?? false,
      averageItemPower: (json['averageItemPower'] ?? 0).toDouble(),
      averageBasicItemPower: (json['averageBasicItemPower'] ?? 0).toDouble(),
      itemPowerCondition: json['itemPowerCondition'] ?? '',
      basicItemPowerCondition: json['basicItemPowerCondition'] ?? '',
      isDeathAlertActive: json['isDeathAlertActive'] ?? false,
      equipment: json['equipment'] != null ? EquipmentData.fromJson(json['equipment']) : null,
    );
  }
}

class EquipmentData {
  final ItemData? mainHand;
  final ItemData? offHand;
  final ItemData? head;
  final ItemData? chest;
  final ItemData? shoes;
  final ItemData? bag;
  final ItemData? cape;
  final ItemData? mount;
  final ItemData? potion;
  final ItemData? buffFood;

  EquipmentData({
    this.mainHand, this.offHand, this.head, this.chest, this.shoes,
    this.bag, this.cape, this.mount, this.potion, this.buffFood,
  });

  factory EquipmentData.fromJson(Map<String, dynamic> json) {
    return EquipmentData(
      mainHand: json['mainHand'] != null ? ItemData.fromJson(json['mainHand']) : null,
      offHand: json['offHand'] != null ? ItemData.fromJson(json['offHand']) : null,
      head: json['head'] != null ? ItemData.fromJson(json['head']) : null,
      chest: json['chest'] != null ? ItemData.fromJson(json['chest']) : null,
      shoes: json['shoes'] != null ? ItemData.fromJson(json['shoes']) : null,
      bag: json['bag'] != null ? ItemData.fromJson(json['bag']) : null,
      cape: json['cape'] != null ? ItemData.fromJson(json['cape']) : null,
      mount: json['mount'] != null ? ItemData.fromJson(json['mount']) : null,
      potion: json['potion'] != null ? ItemData.fromJson(json['potion']) : null,
      buffFood: json['buffFood'] != null ? ItemData.fromJson(json['buffFood']) : null,
    );
  }

  List<ItemData?> get allSlots => [mainHand, offHand, head, chest, shoes, bag, cape, mount, potion, buffFood];
  List<String> get slotNames => ['Weapon', 'Off-hand', 'Head', 'Chest', 'Shoes', 'Bag', 'Cape', 'Mount', 'Potion', 'Food'];
}

// ==================== Guild Models ====================

class GuildData {
  final List<SiphonedEnergyItem> siphonedEnergyList;
  final List<SiphonedEnergyOverview> siphonedEnergyOverview;
  final int totalSiphonedEnergyQuantity;
  final String siphonedEnergyLastUpdate;

  GuildData({
    List<SiphonedEnergyItem>? siphonedEnergyList,
    List<SiphonedEnergyOverview>? siphonedEnergyOverview,
    this.totalSiphonedEnergyQuantity = 0,
    this.siphonedEnergyLastUpdate = '',
  })  : siphonedEnergyList = siphonedEnergyList ?? [],
        siphonedEnergyOverview = siphonedEnergyOverview ?? [];

  factory GuildData.fromJson(Map<String, dynamic> json) {
    return GuildData(
      siphonedEnergyList: (json['siphonedEnergyList'] as List?)?.map((e) => SiphonedEnergyItem.fromJson(e)).toList(),
      siphonedEnergyOverview: (json['siphonedEnergyOverview'] as List?)?.map((e) => SiphonedEnergyOverview.fromJson(e)).toList(),
      totalSiphonedEnergyQuantity: json['totalSiphonedEnergyQuantity'] ?? 0,
      siphonedEnergyLastUpdate: json['siphonedEnergyLastUpdate'] ?? '',
    );
  }
}

class SiphonedEnergyItem {
  final String guildName;
  final String characterName;
  final int quantity;
  final String timestamp;
  final bool isDeposit;

  SiphonedEnergyItem({
    this.guildName = '',
    this.characterName = '',
    this.quantity = 0,
    this.timestamp = '',
    this.isDeposit = false,
  });

  factory SiphonedEnergyItem.fromJson(Map<String, dynamic> json) {
    return SiphonedEnergyItem(
      guildName: json['guildName'] ?? '',
      characterName: json['characterName'] ?? '',
      quantity: json['quantity'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      isDeposit: json['isDeposit'] ?? false,
    );
  }
}

class SiphonedEnergyOverview {
  final String characterName;
  final int totalQuantity;

  SiphonedEnergyOverview({this.characterName = '', this.totalQuantity = 0});

  factory SiphonedEnergyOverview.fromJson(Map<String, dynamic> json) {
    return SiphonedEnergyOverview(
      characterName: json['characterName'] ?? '',
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }
}

// ==================== Logging Models ====================

class LoggingNotification {
  final String type;
  final String dateTime;
  final String fragmentType;
  final LoggingFragment fragment;

  LoggingNotification({
    this.type = '',
    this.dateTime = '',
    this.fragmentType = '',
    LoggingFragment? fragment,
  }) : fragment = fragment ?? LoggingFragment();

  factory LoggingNotification.fromJson(Map<String, dynamic> json) {
    return LoggingNotification(
      type: json['type'] ?? '',
      dateTime: json['dateTime'] ?? '',
      fragmentType: json['fragmentType'] ?? '',
      fragment: json['fragment'] != null ? LoggingFragment.fromJson(json['fragment']) : null,
    );
  }
}

class LoggingFragment {
  final String description;
  final String lootedByName;
  final String lootedFromName;
  final String localizedName;
  final int quantity;
  final double estimatedMarketValue;
  final double totalPlayerFame;
  final double gainedFame;
  final double totalPlayerSilver;
  final double gainedSilver;
  final String died;
  final String killedBy;

  LoggingFragment({
    this.description = '',
    this.lootedByName = '',
    this.lootedFromName = '',
    this.localizedName = '',
    this.quantity = 0,
    this.estimatedMarketValue = 0,
    this.totalPlayerFame = 0,
    this.gainedFame = 0,
    this.totalPlayerSilver = 0,
    this.gainedSilver = 0,
    this.died = '',
    this.killedBy = '',
  });

  factory LoggingFragment.fromJson(Map<String, dynamic> json) {
    return LoggingFragment(
      description: json['description'] ?? '',
      lootedByName: json['lootedByName'] ?? '',
      lootedFromName: json['lootedFromName'] ?? '',
      localizedName: json['localizedName'] ?? '',
      quantity: json['quantity'] ?? 0,
      estimatedMarketValue: (json['estimatedMarketValue'] ?? 0).toDouble(),
      totalPlayerFame: (json['totalPlayerFame'] ?? 0).toDouble(),
      gainedFame: (json['gainedFame'] ?? 0).toDouble(),
      totalPlayerSilver: (json['totalPlayerSilver'] ?? 0).toDouble(),
      gainedSilver: (json['gainedSilver'] ?? 0).toDouble(),
      died: json['died'] ?? '',
      killedBy: json['killedBy'] ?? '',
    );
  }
}

// ==================== Common Models ====================

class ItemData {
  final int index;
  final String uniqueName;
  final String localizedName;
  final String imageUrl;
  final int tier;
  final int enchantmentLevel;
  final String shopCategory;
  final String shopSubCategory;

  ItemData({
    this.index = 0,
    this.uniqueName = '',
    this.localizedName = '',
    this.imageUrl = '',
    this.tier = 0,
    this.enchantmentLevel = 0,
    this.shopCategory = '',
    this.shopSubCategory = '',
  });

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      index: json['index'] ?? 0,
      uniqueName: json['uniqueName'] ?? '',
      localizedName: json['localizedName'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://render.albiononline.com/v1/item/${json['uniqueName'] ?? ''}.png',
      tier: json['tier'] ?? 0,
      enchantmentLevel: json['enchantmentLevel'] ?? 0,
      shopCategory: json['shopCategory'] ?? '',
      shopSubCategory: json['shopSubCategory'] ?? '',
    );
  }

  String get tierString => enchantmentLevel > 0 ? 'T$tier.$enchantmentLevel' : 'T$tier';
}

class ServerStatus {
  final bool isTrackingActive;
  final String serverVersion;
  final String playerName;
  final int connectedClients;
  final String currentCluster;

  ServerStatus({
    this.isTrackingActive = false,
    this.serverVersion = '',
    this.playerName = '',
    this.connectedClients = 0,
    this.currentCluster = '',
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      isTrackingActive: json['isTrackingActive'] ?? false,
      serverVersion: json['serverVersion'] ?? '',
      playerName: json['playerName'] ?? '',
      connectedClients: json['connectedClients'] ?? 0,
      currentCluster: json['currentCluster'] ?? '',
    );
  }
}

class ClusterChanged {
  final String index;
  final String mainClusterIndex;
  final String uniqueName;
  final String uniqueClusterName;
  final String mapType;
  final String mapTypeString;
  final String tier;
  final String clusterMode;
  final String worldJsonType;
  final String avalonTunnelType;
  final String mistsRarity;
  final String instanceName;
  final String mapDisplayName;
  final String clusterHistoryString1;
  final String clusterHistoryString2;
  final String clusterHistoryString3;

  ClusterChanged({
    this.index = '',
    this.mainClusterIndex = '',
    this.uniqueName = '',
    this.uniqueClusterName = '',
    this.mapType = '',
    this.mapTypeString = '',
    this.tier = '',
    this.clusterMode = '',
    this.worldJsonType = '',
    this.avalonTunnelType = '',
    this.mistsRarity = '',
    this.instanceName = '',
    this.mapDisplayName = '',
    this.clusterHistoryString1 = '',
    this.clusterHistoryString2 = '',
    this.clusterHistoryString3 = '',
  });

  factory ClusterChanged.fromJson(Map<String, dynamic> json) {
    return ClusterChanged(
      index: json['index'] ?? '',
      mainClusterIndex: json['mainClusterIndex'] ?? '',
      uniqueName: json['uniqueName'] ?? '',
      uniqueClusterName: json['uniqueClusterName'] ?? '',
      mapType: json['mapType'] ?? '',
      mapTypeString: json['mapTypeString'] ?? '',
      tier: json['tier'] ?? '',
      clusterMode: json['clusterMode'] ?? '',
      worldJsonType: json['worldJsonType'] ?? '',
      avalonTunnelType: json['avalonTunnelType'] ?? '',
      mistsRarity: json['mistsRarity'] ?? '',
      instanceName: json['instanceName'] ?? '',
      mapDisplayName: json['mapDisplayName'] ?? '',
      clusterHistoryString1: json['clusterHistoryString1'] ?? '',
      clusterHistoryString2: json['clusterHistoryString2'] ?? '',
      clusterHistoryString3: json['clusterHistoryString3'] ?? '',
    );
  }
}

// ==================== Logging Settings ====================

class LoggingSettingsData {
  final bool isTrackingSilver;
  final bool isTrackingFame;
  final bool isTrackingMobLoot;

  const LoggingSettingsData({
    this.isTrackingSilver = false,
    this.isTrackingFame = false,
    this.isTrackingMobLoot = false,
  });

  factory LoggingSettingsData.fromJson(Map<String, dynamic> json) {
    return LoggingSettingsData(
      isTrackingSilver: json['isTrackingSilver'] as bool? ?? false,
      isTrackingFame: json['isTrackingFame'] as bool? ?? false,
      isTrackingMobLoot: json['isTrackingMobLoot'] as bool? ?? false,
    );
  }
}
class PlayerInfo {
  final String username;
  final String guild;
  final String alliance;
  final String currentMap;
  final String currentMapType;
  final String mapDisplayName;
  final String clusterMode;
  final String tier;
  final String mapTypeString;
  final String instanceName;

  PlayerInfo({
    this.username = '',
    this.guild = '',
    this.alliance = '',
    this.currentMap = '',
    this.currentMapType = '',
    this.mapDisplayName = '',
    this.clusterMode = '',
    this.tier = '',
    this.mapTypeString = '',
    this.instanceName = '',
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      username: json['username'] ?? '',
      guild: json['guild'] ?? '',
      alliance: json['alliance'] ?? '',
      currentMap: json['currentMap'] ?? '',
      currentMapType: json['currentMapType'] ?? '',
      mapDisplayName: json['mapDisplayName'] ?? '',
      clusterMode: json['clusterMode'] ?? '',
      tier: json['tier'] ?? '',
      mapTypeString: json['mapTypeString'] ?? '',
      instanceName: json['instanceName'] ?? '',
    );
  }
}

// ==================== Damage Meter Snapshot Models ====================

class DamageMeterSnapshot {
  final String id;
  final String timestamp;
  final List<DamageMeterFragment> fragments;

  DamageMeterSnapshot({
    this.id = '',
    this.timestamp = '',
    List<DamageMeterFragment>? fragments,
  }) : fragments = fragments ?? [];

  factory DamageMeterSnapshot.fromJson(Map<String, dynamic> json) {
    return DamageMeterSnapshot(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      fragments: (json['fragments'] as List?)
              ?.map((e) => DamageMeterFragment.fromJson(e))
              .toList(),
    );
  }
}

// ==================== Map History Models ====================

class MapHistoryData {
  final List<MapHistoryEntry> entries;

  MapHistoryData({List<MapHistoryEntry>? entries}) : entries = entries ?? [];

  factory MapHistoryData.fromJson(Map<String, dynamic> json) {
    return MapHistoryData(
      entries: (json['entries'] as List?)
              ?.map((e) => MapHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class MapHistoryEntry {
  final String index;
  final String mainClusterIndex;
  final String uniqueName;
  final String uniqueClusterName;
  final String mapDisplayName;
  final String mapType;
  final String mapTypeString;
  final String clusterMode;
  final String tier;
  final String worldJsonType;
  final String avalonTunnelType;
  final String mistsRarity;
  final String enteredAt;
  final String instanceName;
  final String clusterHistoryString1;
  final String clusterHistoryString2;
  final String clusterHistoryString3;

  MapHistoryEntry({
    this.index = '',
    this.mainClusterIndex = '',
    this.uniqueName = '',
    this.uniqueClusterName = '',
    this.mapDisplayName = '',
    this.mapType = '',
    this.mapTypeString = '',
    this.clusterMode = '',
    this.tier = '',
    this.worldJsonType = '',
    this.avalonTunnelType = '',
    this.mistsRarity = '',
    this.enteredAt = '',
    this.instanceName = '',
    this.clusterHistoryString1 = '',
    this.clusterHistoryString2 = '',
    this.clusterHistoryString3 = '',
  });

  factory MapHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MapHistoryEntry(
      index: json['index'] ?? '',
      mainClusterIndex: json['mainClusterIndex'] ?? '',
      uniqueName: json['uniqueName'] ?? '',
      uniqueClusterName: json['uniqueClusterName'] ?? '',
      mapDisplayName: json['mapDisplayName'] ?? '',
      mapType: json['mapType'] ?? '',
      mapTypeString: json['mapTypeString'] ?? '',
      clusterMode: json['clusterMode'] ?? '',
      tier: json['tier'] ?? '',
      worldJsonType: json['worldJsonType'] ?? '',
      avalonTunnelType: json['avalonTunnelType'] ?? '',
      mistsRarity: json['mistsRarity'] ?? '',
      enteredAt: json['enteredAt'] ?? '',
      instanceName: json['instanceName'] ?? '',
      clusterHistoryString1: json['clusterHistoryString1'] ?? '',
      clusterHistoryString2: json['clusterHistoryString2'] ?? '',
      clusterHistoryString3: json['clusterHistoryString3'] ?? '',
    );
  }
}
