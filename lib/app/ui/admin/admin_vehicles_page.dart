import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/ui/admin/vehicle_form_dialog.dart';

class AdminVehiclesPage extends GetView<AdminController> {
  const AdminVehiclesPage({super.key});

  static const _primary = Color(0xFF003399);

  static const _flex = [30, 20, 20, 16, 20, 16, 26];
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 1000;
    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Vehicles Management',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),

          _stats(),
          const SizedBox(height: 20),
          _searchRow(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_filterBar(), const Divider(height: 1), _table()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow() => Row(
    children: [
      Expanded(
        child: TextField(
          onChanged: controller.setSearch,
          decoration: InputDecoration(
            hintText: 'Search vehicles by make, model, or plate...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: const Color(0xFFEEF0F4),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      if (AuthService.can('vehicle.create')) ...[
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => Get.dialog(const VehicleFormDialog()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Vehicle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ],
  );

  // ---------------- stats ----------------
  Widget _stats() => Obx(() {
    final list = controller.vehicles;
    int count(StatusKind k) =>
        list.where((v) => statusKindOf(v.statusName) == k).length;

    final cards = [
      _statCard(
        Icons.directions_car_outlined,
        Colors.blueGrey,
        'Total Fleet',
        '${list.length}',
        'all vehicles',
        null,
      ),
      _statCard(
        Icons.check_circle_outline,
        Colors.green,
        'Available',
        '${count(StatusKind.available)}',
        'ready to rent',
        Colors.green,
      ),
      _statCard(
        Icons.key_outlined,
        Colors.amber.shade800,
        'Rented',
        '${count(StatusKind.onRent)}',
        'currently booked',
        Colors.amber.shade800,
      ),
      _statCard(
        Icons.build_circle_outlined,
        Colors.red,
        'Unavailable',
        '${count(StatusKind.maintenance)}',
        'out of service',
        Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 500 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  });

  Widget _statCard(
    IconData icon,
    Color color,
    String label,
    String value,
    String sub,
    Color? valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- filter bar ----------------
  Widget _filterBar() => Padding(
    padding: const EdgeInsets.all(14),
    child: Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Obx(() {
          final sel = controller.brandFilter.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'All (${controller.vehicles.length})',
                sel == -1,
                () => controller.setBrand(-1),
              ),
              for (final b in controller.brandChips)
                _chip(
                  '${b.name} (${b.count})',
                  sel == b.id,
                  () => controller.setBrand(b.id),
                ),
            ],
          );
        }),
        SizedBox(
          width: 220,
          child: TextField(
            onChanged: controller.setRowFilter,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Filter table rows...',
              prefixIcon: const Icon(Icons.filter_list, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chip(String text, bool selected, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF111827) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    ),
  );

  Widget _table() => Obx(() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = controller.pageItems;
    final total = controller.filtered.length;
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: Text('No vehicles found')),
      );
    }

    final pageNo = controller.page.value;
    final count = controller.pageCount;
    final from = pageNo * AdminController.pageSize + 1;
    final to = from + items.length - 1;
    final sel = controller.selected.toSet();
    final allChecked =
        items.isNotEmpty && items.every((v) => sel.contains(v.id));
    final canDelete = AuthService.can('vehicle.delete');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sel.isNotEmpty && canDelete) _bulkBar(sel.length),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth < 1000 ? 1000.0 : c.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: w,
                child: Column(
                  children: [
                    _headerRow(allChecked, items),
                    for (final v in items) _row(v, sel.contains(v.id)),
                  ],
                ),
              ),
            );
          },
        ),
        _footer(from, to, total, pageNo, count),
      ],
    );
  });

  Widget _bulkBar(int n) => Container(
    width: double.infinity,
    color: const Color(0xFFEAF0FF),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Text(
          '$n selected',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _confirm(
            'Delete $n vehicles?',
            'This cannot be undone.',
            controller.removeSelected,
          ),
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          label: const Text(
            'Delete selected',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  Widget _c(int i, Widget child) => Expanded(flex: _flex[i], child: child);

  Widget _h(int i, String t, {bool right = false}) => Expanded(
    flex: _flex[i],
    child: Text(
      t,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Colors.grey.shade600,
      ),
    ),
  );

  Widget _headerRow(bool all, List<VehicleModel> items) => Container(
    color: const Color(0xFFF7F8FA),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: all,
            onChanged: (_) => controller.togglePage(items),
          ),
        ),
        _h(0, 'VEHICLE'),
        _h(1, 'BRAND & MODEL'),
        _h(2, 'PLATE NUMBER'),
        _h(3, 'RATE'),
        _h(4, 'LOCATION HUB'),
        _h(5, 'STATUS'),
        _h(6, 'ACTIONS', right: true),
      ],
    ),
  );

  Widget _row(VehicleModel v, bool checked) {
    final url = resolveImageUrl(v.imageUrl);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: checked,
              onChanged: (_) => controller.toggleSelect(v.id),
            ),
          ),
          _c(
            0,
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 36,
                    child: url == null
                        ? _thumb()
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumb(),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _c(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.brandName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  v.modelName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _c(
            2,
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.licensePlate,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _c(3, _ratePills(v)),
          _c(
            4,
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    v.locationName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          _c(
            5,
            Align(
              alignment: Alignment.centerLeft,
              child: _statusPill(v.statusName),
            ),
          ),
          _c(
            6,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (AuthService.can('vehicle.edit'))
                  TextButton.icon(
                    onPressed: () => Get.dialog(VehicleFormDialog(vehicle: v)),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                if (AuthService.can('vehicle.delete'))
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () => _confirm(
                      'Delete vehicle?',
                      '${v.displayName} (${v.licensePlate}) will be removed.',
                      () => controller.removeVehicle(v.id!),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (s) {
                    if (s == 'view') Get.toNamed('/vehicle/${v.id}');
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'view', child: Text('View details')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
    color: Colors.grey.shade100,
    child: const Icon(Icons.directions_car, size: 18, color: Colors.grey),
  );

  Widget _statusPill(String name) {
    final Color fg;
    final Color bg;
    switch (statusKindOf(name)) {
      case StatusKind.available:
        fg = const Color(0xFF1E9E5A);
        bg = const Color(0xFFE6F7EE);
        break;
      case StatusKind.onRent:
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFF4E0);
        break;
      case StatusKind.reserved:
        fg = const Color(0xFF7C3AED);
        bg = const Color(0xFFF1EAFE);
        break;
      case StatusKind.maintenance:
        fg = const Color(0xFFDC3545);
        bg = const Color(0xFFFDECEE);
        break;
      case StatusKind.other:
        fg = Colors.grey.shade700;
        bg = Colors.grey.shade200;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- pagination ----------------
  Widget _footer(int from, int to, int total, int pageNo, int count) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          Text(
            'Showing $from to $to of $total vehicles',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: pageNo > 0 ? () => controller.page.value-- : null,
                child: const Text('Previous'),
              ),
              for (final p in _pages(pageNo, count))
                p == -1
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('…'),
                      )
                    : _pageBtn(p, p == pageNo),
              TextButton(
                onPressed: pageNo < count - 1
                    ? () => controller.page.value++
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(int p, bool active) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => controller.page.value = p,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${p + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    ),
  );

  /// page numbers (0-based), -1 = ellipsis
  List<int> _pages(int cur, int count) {
    if (count <= 6) return List.generate(count, (i) => i);
    final set = <int>{0, count - 1, cur - 1, cur, cur + 1}
      ..removeWhere((p) => p < 0 || p >= count);
    final sorted = set.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }

  void _confirm(String title, String msg, Future<void> Function() onYes) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              onYes();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

Widget _ratePills(VehicleModel v) {
  final day = v.dayPrice;
  final hour = v.hourPrice;
  final hasDay = day != null && day > 0;
  final hasHour = hour != null && hour > 0;

  if (!hasDay && !hasHour) {
    return Text('—', style: TextStyle(color: Colors.grey.shade500));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (hasDay)
        _ratePill(
          '\$${day.toStringAsFixed(2)}',
          '/day',
          const Color(0xFF2563EB),
          const Color(0xFFE8F0FE),
        ),
      if (hasDay && hasHour) const SizedBox(height: 4),
      if (hasHour)
        _ratePill(
          '\$${hour.toStringAsFixed(2)}',
          '/hr',
          const Color(0xFF7C3AED),
          const Color(0xFFF1EAFE),
        ),
    ],
  );
}

Widget _ratePill(String price, String unit, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 6, color: fg),
      const SizedBox(width: 5),
      Text(
        price,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
      const SizedBox(width: 3),
      Text(
        unit.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    ],
  ),
);
