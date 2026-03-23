import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/trade_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_image_widget.dart';
import '../../utils/formatters.dart';

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestTrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.trades.isEmpty) {
      return const EmptyState(
        icon: Icons.swap_horiz,
        message: 'Sin datos de comercio',
        submessage: 'Los datos aparecerán cuando compres o vendas items',
      );
    }

    return Column(
      children: [
        _buildStatsHeader(provider.stats, isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: provider.trades.length,
            itemBuilder: (context, index) {
              return _buildTradeCard(provider.trades[index], isDark);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  STATS HEADER
  // ═══════════════════════════════════════════
  Widget _buildStatsHeader(TradeStatsData stats, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.12))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Ventas', Formatters.silver(stats.soldTotal), Colors.green[isDark ? 300 : 700], isDark),
              _miniStat('Compras', Formatters.silver(stats.boughtTotal), Colors.red[isDark ? 300 : 700], isDark),
              _miniStat('Impuestos', Formatters.silver(stats.taxesTotal), Colors.orange[isDark ? 300 : 700], isDark),
            ],
          ),
          const SizedBox(height: 8),
          // Profit row: today / week / total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _profitChip('Hoy', stats.salesToday, isDark),
              _profitChip('Semana', stats.salesThisWeek, isDark),
              _profitChip('Total', stats.salesTotal, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profitChip(String label, int profit, bool isDark) {
    final isPositive = profit >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: color),
              const SizedBox(width: 3),
              Text(
                '${isPositive ? '+' : '-'}${Formatters.silver(profit.abs())}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              ),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color? color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  TRADE CARD
  // ═══════════════════════════════════════════
  Widget _buildTradeCard(TradeData trade, bool isDark) {
    final isBuy = trade.isPurchase;
    final isSale = trade.isSale;
    final accentColor = isBuy ? Colors.red : Colors.green;
    final badgeLabel = isBuy ? 'COMPRA' : (isSale ? 'VENTA' : trade.type.toUpperCase());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showTradeDetail(context, trade, isDark),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Item image
              ItemImageWidget(uniqueName: trade.item?.uniqueName ?? '', size: 44),
              const SizedBox(width: 10),

              // Trade info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor[isDark ? 300 : 700]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            trade.item?.localizedName ?? trade.item?.uniqueName ?? trade.description,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price row
                    Row(
                      children: [
                        Text(
                          'x${trade.quantity}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '@ ${Formatters.silver(trade.unitPrice)}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        ),
                        const Spacer(),
                        // Total price
                        Text(
                          Formatters.silver(trade.totalPrice),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor[isDark ? 300 : 700],
                          ),
                        ),
                      ],
                    ),
                    // Tax + revenue row
                    if (trade.totalTaxes > 0 || trade.distanceFee > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            if (trade.taxAmount > 0) ...[
                              Icon(Icons.percent, size: 10, color: Colors.orange[isDark ? 300 : 700]),
                              const SizedBox(width: 2),
                              Text(
                                'Imp: ${Formatters.silver(trade.taxAmount)}',
                                style: TextStyle(fontSize: 10, color: Colors.orange[isDark ? 300 : 700]),
                              ),
                            ],
                            if (trade.taxSetupAmount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Ajuste: ${Formatters.silver(trade.taxSetupAmount)}',
                                style: TextStyle(fontSize: 10, color: Colors.amber[isDark ? 300 : 700]),
                              ),
                            ],
                            const Spacer(),
                            if (isSale && trade.totalRevenue > 0)
                              Text(
                                'Neto: ${Formatters.silver(trade.totalRevenue)}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green[isDark ? 200 : 800]),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Date + location column
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.dateTime(trade.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    if (trade.locationName.isNotEmpty && trade.locationName != 'Unknown')
                      Text(
                        _shortLocation(trade.locationName),
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TRADE DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════
  void _showTradeDetail(BuildContext context, TradeData trade, bool isDark) {
    final isBuy = trade.isPurchase;
    final accentColor = isBuy ? Colors.red : Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Item header
              Row(
                children: [
                  ItemImageWidget(uniqueName: trade.item?.uniqueName ?? '', size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.item?.localizedName ?? trade.item?.uniqueName ?? trade.description,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trade.typeLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor[isDark ? 300 : 700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Detail rows
              _detailRow('Cantidad', 'x${trade.quantity}', isDark),
              _detailRow('Precio Unitario', Formatters.silver(trade.unitPrice), isDark),
              _detailRow('Precio Total (sin imp.)', Formatters.silver(trade.totalPrice), isDark, bold: true),

              if (trade.taxRate > 0)
                _detailRow(
                  'Tasa de Mercado (${trade.taxRate.toStringAsFixed(1)}%)',
                  Formatters.silver(trade.taxAmount),
                  isDark,
                  color: Colors.orange,
                ),

              if (trade.taxSetupRate > 0)
                _detailRow(
                  'Cuota de Ajuste (${trade.taxSetupRate.toStringAsFixed(1)}%)',
                  Formatters.silver(trade.taxSetupAmount),
                  isDark,
                  color: Colors.amber,
                ),

              if (trade.distanceFee > 0)
                _detailRow(
                  'Tarifa de Distancia',
                  Formatters.silver(trade.distanceFee),
                  isDark,
                  color: Colors.blue,
                ),

              if (trade.totalTaxes > 0)
                _detailRow('Total Impuestos', Formatters.silver(trade.totalTaxes), isDark, color: Colors.orange, bold: true),

              if (trade.isSale && trade.totalRevenue > 0) ...[
                const Divider(height: 16),
                _detailRow(
                  'Ingresos Netos',
                  Formatters.silver(trade.totalRevenue),
                  isDark,
                  bold: true,
                  color: Colors.green,
                  fontSize: 15,
                ),
              ],

              const SizedBox(height: 12),

              // Origin + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        trade.locationName.isNotEmpty && trade.locationName != 'Unknown'
                            ? trade.locationName
                            : 'Desconocido',
                        style: TextStyle(fontSize: 12, color: Colors.grey[isDark ? 400 : 600]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.dateTime(trade.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[isDark ? 400 : 600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, bool isDark, {Color? color, bool bold = false, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortLocation(String location) {
    // Trim long location names
    if (location.length > 14) return '${location.substring(0, 12)}..';
    return location;
  }
}
