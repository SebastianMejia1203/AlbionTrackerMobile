import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/guild_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/formatters.dart';

class GuildTab extends StatefulWidget {
  const GuildTab({super.key});

  @override
  State<GuildTab> createState() => _GuildTabState();
}

class _GuildTabState extends State<GuildTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestGuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuildProvider>();
    final conn = context.watch<ConnectionProvider>();
    final data = provider.data;

    if (data == null) {
      return const EmptyState(
        icon: Icons.shield_outlined,
        message: 'Sin datos de guild',
        submessage: 'Los datos aparecerán cuando estés en una guild',
      );
    }

    final guildName = conn.playerInfo.guild;
    final allianceName = conn.playerInfo.alliance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Guild info header
        _buildGuildHeader(guildName, allianceName, data),
        const SizedBox(height: 16),

        // Stats
        const SectionHeader(title: 'Energía Sifoneada', icon: Icons.bar_chart),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatCard(
              label: 'Total Energía',
              value: Formatters.number(data.totalSiphonedEnergyQuantity),
              icon: Icons.flash_on,
              valueColor: Colors.amber[300],
              width: (MediaQuery.of(context).size.width - 40) / 2,
            ),
            StatCard(
              label: 'Contribuidores',
              value: '${data.siphonedEnergyOverview.length}',
              icon: Icons.people,
              width: (MediaQuery.of(context).size.width - 40) / 2,
            ),
          ],
        ),

        // Siphoned Energy Overview
        if (data.siphonedEnergyOverview.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(title: 'Por Jugador', icon: Icons.person),
          ...data.siphonedEnergyOverview.map((item) => _buildOverviewCard(item)),
        ],

        // Siphoned Energy Log
        if (data.siphonedEnergyList.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(title: 'Historial', icon: Icons.history),
          ...data.siphonedEnergyList.take(50).map((item) => _buildSiphonedCard(item)),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGuildHeader(String guildName, String allianceName, GuildData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            child: const Icon(Icons.shield, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            guildName.isNotEmpty ? guildName : 'Guild',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (allianceName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '[$allianceName]',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (data.siphonedEnergyLastUpdate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Última Act: ${Formatters.dateTime(data.siphonedEnergyLastUpdate)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(SiphonedEnergyOverview item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.amber[300], size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.characterName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              Formatters.number(item.totalQuantity),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiphonedCard(SiphonedEnergyItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              item.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: item.isDeposit ? Colors.green[300] : Colors.red[300],
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.characterName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (item.guildName.isNotEmpty)
                    Text(
                      item.guildName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.number(item.quantity),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[300],
                  ),
                ),
                Text(
                  Formatters.dateTime(item.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
