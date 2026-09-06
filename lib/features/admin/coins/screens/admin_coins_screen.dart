import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tradingpro/providers/app_providers.dart';
import 'package:tradingpro/core/theme/app_colors.dart';
import 'package:tradingpro/core/theme/app_text_styles.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/coin_model.dart';
import 'package:tradingpro/shared_widgets/app_widgets.dart';
import 'package:tradingpro/shared_widgets/market_data_widgets.dart';

class AdminCoinsScreen extends ConsumerStatefulWidget {
  const AdminCoinsScreen({super.key});

  @override
  ConsumerState<AdminCoinsScreen> createState() => _AdminCoinsScreenState();
}

class _AdminCoinsScreenState extends ConsumerState<AdminCoinsScreen> {
  void _showCoinDialog([CoinModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final symbolCtrl = TextEditingController(text: existing?.symbol ?? '');
    final binanceSymbolCtrl =
        TextEditingController(text: existing?.binanceSymbol ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null && existing.latestPrice > 0
            ? existing.latestPrice.toString()
            : '');
    final changeCtrl = TextEditingController(
        text: existing != null
            ? existing.priceChangePercent24h.toString()
            : '');
    final orderCtrl = TextEditingController(
        text: existing != null ? existing.displayOrder.toString() : '0');

    var marketMode =
        existing?.marketDataMode ?? MarketDataMode.live;
    var isFeatured = existing?.isFeatured ?? false;
    var isActive = existing?.isActive ?? true;

    Uint8List? selectedLogoBytes;
    String? selectedLogoExt;
    String? currentLogoUrl = existing?.logoUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setDialogState) {
          final isMobile = MediaQuery.of(sbCtx).size.width < 600;

          Future<void> pickLogo() async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 400,
                maxHeight: 400,
                imageQuality: 85,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                final ext = picked.name.split('.').last;
                if (sbCtx.mounted) {
                  setDialogState(() {
                    selectedLogoBytes = bytes;
                    selectedLogoExt = ext;
                  });
                }
              }
            } catch (e) {
              if (sbCtx.mounted) {
                ScaffoldMessenger.of(sbCtx).showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick logo: $e'),
                    backgroundColor: AppColors.negative,
                  ),
                );
              }
            }
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 24,
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: 24,
              child: Container(
                width: isMobile ? double.infinity : 480,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sbCtx).size.height * 0.90,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null
                              ? 'Add New Market Coin'
                              : 'Edit Coin Data',
                          style: AppTextStyles.h3.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: isUploading
                              ? null
                              : () => Navigator.of(dialogCtx).pop(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Scrollable Form Fields
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Logo Picker ──
                            Center(
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: isUploading ? null : pickLogo,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              AppColors.primary.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: selectedLogoBytes != null
                                            ? Image.memory(
                                                selectedLogoBytes!,
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.cover,
                                              )
                                            : (currentLogoUrl != null &&
                                                    currentLogoUrl.isNotEmpty)
                                                ? CachedNetworkImage(
                                                    imageUrl: currentLogoUrl,
                                                    width: 72,
                                                    height: 72,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                      Icons.token_rounded,
                                                      size: 32,
                                                      color: AppColors.primary,
                                                    ),
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(
                                                          Icons
                                                              .add_photo_alternate_rounded,
                                                          color:
                                                              AppColors.primary,
                                                          size: 26),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        'Logo',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: isUploading ? null : pickLogo,
                                    icon: const Icon(Icons.upload_file_rounded,
                                        size: 16),
                                    label: Text(
                                      selectedLogoBytes != null ||
                                              (currentLogoUrl != null &&
                                                  currentLogoUrl.isNotEmpty)
                                          ? 'Change Logo'
                                          : 'Upload Logo',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Symbol & Name ──
                            TextFormField(
                              controller: symbolCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Display Symbol (e.g. BTC/USDT)',
                                hintText: 'e.g. BTC/USDT',
                                prefixIcon: Icon(Icons.token_rounded),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Full Name (e.g. Bitcoin)',
                                hintText: 'e.g. Bitcoin',
                                prefixIcon: Icon(Icons.title_rounded),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Market Data Mode ──
                            const Text(
                              'Market Data Source',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            MarketDataModeSelector(
                              value: marketMode,
                              onChanged: (mode) =>
                                  setDialogState(() => marketMode = mode),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              marketMode == MarketDataMode.live
                                  ? 'Prices updated automatically from Binance. Enter the Binance symbol below.'
                                  : 'You control the price and percentage manually.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),

                            // ── Binance Symbol (shown for both modes but required for live) ──
                            TextFormField(
                              controller: binanceSymbolCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Binance Symbol (e.g. BTCUSDT)',
                                hintText: 'e.g. BTCUSDT',
                                prefixIcon:
                                    const Icon(Icons.link_rounded),
                                helperText: marketMode == MarketDataMode.live
                                    ? 'Required for live data. Lowercase is used internally.'
                                    : 'Optional — for reference only in manual mode.',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Price & Percent (always shown; read-only hint when live) ──
                            if (marketMode == MarketDataMode.manual) ...[
                              TextFormField(
                                controller: priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Price (\$ USD)',
                                  hintText: 'e.g. 64250.00',
                                  prefixIcon:
                                      Icon(Icons.attach_money_rounded),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: changeCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  labelText: '24h Change % (e.g. -1.24 or 3.08)',
                                  hintText: 'e.g. -1.24',
                                  prefixIcon: Icon(Icons.percent_rounded),
                                  helperText:
                                      'Use negative for decline, positive for gain.',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              // In live mode, show current price read-only if editing
                              if (existing != null && existing.hasPrice) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.divider, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: Color(0xFF16A34A),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Live Price: ${AppFormatters.cryptoPrice(existing.latestPrice)}',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '24h Change: ${AppFormatters.percentageChange(existing.priceChangePercent24h)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.financialColor(
                                                        existing.isPositive),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      MarketStatusBadge(
                                          status: existing.marketDataStatus),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (existing.lastMarketUpdate != null)
                                  Text(
                                    'Last update: ${AppFormatters.marketDataAge(existing.lastMarketUpdate)}',
                                    style: AppTextStyles.caption,
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ],

                            // ── Toggles ──
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Featured (Top 3 on Home)',
                                  style: TextStyle(fontSize: 13)),
                              subtitle: const Text(
                                  'Max 3 coins can be featured',
                                  style: TextStyle(fontSize: 11)),
                              value: isFeatured,
                              activeColor: AppColors.primary,
                              onChanged: (val) =>
                                  setDialogState(() => isFeatured = val),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Active for Trading',
                                  style: TextStyle(fontSize: 13)),
                              value: isActive,
                              activeColor: AppColors.primary,
                              onChanged: (val) =>
                                  setDialogState(() => isActive = val),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: orderCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Display Order (e.g. 0, 1, 2)',
                                prefixIcon: Icon(Icons.sort_rounded),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Actions ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUploading
                              ? null
                              : () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final symbol = symbolCtrl.text.trim();
                                  final name = nameCtrl.text.trim();
                                  final binanceSymbol = binanceSymbolCtrl.text
                                      .trim()
                                      .toUpperCase();
                                  final order =
                                      int.tryParse(orderCtrl.text.trim()) ?? 0;

                                  // Validation
                                  if (symbol.isEmpty || name.isEmpty) {
                                    ScaffoldMessenger.of(sbCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please enter both symbol and name.'),
                                        backgroundColor: AppColors.negative,
                                      ),
                                    );
                                    return;
                                  }

                                  if (marketMode == MarketDataMode.live &&
                                      binanceSymbol.isEmpty) {
                                    ScaffoldMessenger.of(sbCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Binance symbol is required for LIVE mode (e.g. BTCUSDT).'),
                                        backgroundColor: AppColors.negative,
                                      ),
                                    );
                                    return;
                                  }

                                  // Resolve price/pct for manual mode
                                  final price = marketMode == MarketDataMode.manual
                                      ? (double.tryParse(
                                              priceCtrl.text.trim()) ??
                                          0.0)
                                      : (existing?.latestPrice ?? 0.0);
                                  final pct = marketMode == MarketDataMode.manual
                                      ? (double.tryParse(
                                              changeCtrl.text.trim()) ??
                                          0.0)
                                      : (existing?.priceChangePercent24h ??
                                          0.0);

                                  setDialogState(() => isUploading = true);

                                  final repo =
                                      ref.read(coinRepositoryProvider);
                                  try {
                                    String? logoUrl = currentLogoUrl;
                                    if (selectedLogoBytes != null) {
                                      logoUrl = await repo.uploadCoinLogo(
                                        selectedLogoBytes!,
                                        selectedLogoExt ?? 'png',
                                      );
                                    }

                                    if (existing == null) {
                                      await repo.addCoin(
                                        CoinModel(
                                          coinId: '',
                                          name: name,
                                          symbol: symbol,
                                          logoUrl: logoUrl,
                                          latestPrice: price,
                                          priceChangePercent24h: pct,
                                          binanceSymbol: binanceSymbol,
                                          marketDataMode: marketMode,
                                          marketDataStatus: marketMode ==
                                                  MarketDataMode.live
                                              ? MarketDataStatus.offline
                                              : MarketDataStatus.disabled,
                                          isActive: isActive,
                                          isFeatured: isFeatured,
                                          displayOrder: order,
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        ),
                                      );
                                    } else {
                                      await repo.updateCoin(existing.coinId, {
                                        'name': name,
                                        'symbol': symbol,
                                        if (logoUrl != null) 'logoUrl': logoUrl,
                                        'latestPrice': price,
                                        'priceChangePercent24h': pct,
                                        'binanceSymbol': binanceSymbol,
                                        'marketDataMode': marketMode.name,
                                        // If switching to live, set offline so
                                        // the backend updates it on next tick.
                                        if (marketMode ==
                                                MarketDataMode.live &&
                                            existing.marketDataMode !=
                                                MarketDataMode.live)
                                          'marketDataStatus': 'offline',
                                        'isActive': isActive,
                                        'isFeatured': isFeatured,
                                        'displayOrder': order,
                                      });
                                    }

                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(existing == null
                                              ? 'Coin added successfully!'
                                              : 'Coin updated successfully!'),
                                          backgroundColor: AppColors.positive,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (sbCtx.mounted) {
                                      setDialogState(
                                          () => isUploading = false);
                                      ScaffoldMessenger.of(sbCtx).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: AppColors.negative,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(existing == null
                                  ? 'Add Coin'
                                  : 'Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinsAsync = ref.watch(allCoinsProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCoinDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Coin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Text('Coin & Market Management', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Manage symbols, Binance live prices, and featured Top 3 coins.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCoinDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Market Coin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coin & Market Management', style: AppTextStyles.h2),
                        const SizedBox(height: 2),
                        Text(
                          'Manage symbols, Binance live prices, and featured Top 3 coins.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCoinDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Coin'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            Expanded(
              child: coinsAsync.when(
                data: (coins) {
                  if (coins.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EmptyStateWidget(
                            title: 'No Coins Configured',
                            message:
                                'Add your first market coin to display live pricing.',
                            icon: Icons.monetization_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCoinDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Coin'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: coins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final coin = coins[i];
                      return _AdminCoinCard(
                        coin: coin,
                        onEdit: () => _showCoinDialog(coin),
                        onToggleActive: () async {
                          await ref
                              .read(coinRepositoryProvider)
                              .toggleCoinActive(coin.coinId, !coin.isActive);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => ErrorStateWidget(
                  message: 'Failed to load coins',
                  onRetry: () => ref.invalidate(allCoinsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Coin Card ──────────────────────────────────────────────────────────

class _AdminCoinCard extends StatelessWidget {
  final CoinModel coin;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _AdminCoinCard({
    required this.coin,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = coin.marketDataMode == MarketDataMode.live;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (coin.logoUrl != null && coin.logoUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: coin.logoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          coin.symbol.isNotEmpty
                              ? coin.symbol[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        coin.symbol.isNotEmpty
                            ? coin.symbol[0].toUpperCase()
                            : '?',
                        style:
                            AppTextStyles.h4.copyWith(color: AppColors.primary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Coin details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Symbol + name + badges row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      coin.symbol,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(coin.name, style: AppTextStyles.caption),
                    if (coin.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TOP 3',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (!coin.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.negativeLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'INACTIVE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.negative,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),

                // Price + change row
                Wrap(
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    Text(
                      coin.hasPrice
                          ? AppFormatters.cryptoPrice(coin.latestPrice)
                          : '--',
                      style: AppTextStyles.captionMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      coin.hasPrice
                          ? AppFormatters.percentageChange(
                              coin.priceChangePercent24h)
                          : '--',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.financialColor(coin.isPositive),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isLive && coin.binanceSymbol.isNotEmpty)
                      Text(
                        coin.binanceSymbol,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Status + last update
                MarketDataInfoRow(coin: coin),
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(
                  coin.isActive
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color:
                      coin.isActive ? AppColors.gray600 : AppColors.negative,
                ),
                onPressed: onToggleActive,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
