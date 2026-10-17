import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/customer_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/customer_model.dart';
import 'package:vrs_ui/app/ui/admin/admin_customer_page/admin_customer_dialog.dart';


class AdminCustomerPage extends StatelessWidget {
  const AdminCustomerPage({super.key});

  static const _primary = Color(0xFF003399);
  static const _border = Color(0xFFE2E8F0);
  static const _muted = Color(0xFF64748B);
  static const _ink = Color(0xFF0F172A);

  void _openForm(BuildContext context, [CustomerModel? customer]) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerController c,
    CustomerModel u,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          '${u.fullName.isEmpty ? u.username : u.fullName} (@${u.username}) '
          'will be removed. Their existing bookings may stop showing '
          'customer details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes == true && u.id != null) await c.removeCustomer(u.id!);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<CustomerController>()
        ? Get.find<CustomerController>()
        : Get.put(CustomerController());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customers Management',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 20),
          _toolbar(context, c),
          const SizedBox(height: 20),
          _table(context, c),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context, CustomerController c) => Row(
    children: [
      Expanded(
        child: TextField(
          onChanged: c.setSearch,
          decoration: InputDecoration(
            hintText: 'Search customers by name, username, email, or phone...',
            hintStyle: const TextStyle(color: _muted),
            prefixIcon: const Icon(Icons.search, color: _muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      ElevatedButton.icon(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Customer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );

  Widget _table(BuildContext context, CustomerController c) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Obx(() {
      final items = c.pageItems;

      if (c.isLoading.value && c.customers.isEmpty) {
        return const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 720;
          return Column(
            children: [
              _headerRow(wide),
              const Divider(height: 1, color: _border),
              if (items.isEmpty)
                _empty(context, c)
              else
                for (final b in items) ...[
                  _row(context, c, b, wide),
                  const Divider(height: 1, color: _border),
                ],
              _pager(c, items.length),
            ],
          );
        },
      );
    }),
  );

  Widget _headCell(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: Color(0xFF475569),
    ),
  );

  Widget _headerRow(bool wide) => Container(
    color: const Color(0xFFF8FAFC),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Expanded(flex: 4, child: _headCell('CUSTOMER')),
        if (wide) Expanded(flex: 3, child: _headCell('EMAIL')),
        Expanded(flex: 2, child: _headCell('PHONE')),
        SizedBox(
          width: 150,
          child: Align(
            alignment: Alignment.centerRight,
            child: _headCell('ACTIONS'),
          ),
        ),
      ],
    ),
  );

  Widget _row(
    BuildContext context,
    CustomerController c,
    CustomerModel u,
    bool wide,
  ) {
    final img = resolveImageUrl(u.profile);
    final name = u.fullName.isEmpty ? u.username : u.fullName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: img != null ? NetworkImage(img) : null,
                  child: img == null
                      ? Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      Text(
                        '@${u.username}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (wide)
            Expanded(
              flex: 3,
              child: Text(
                u.email.isEmpty ? '-' : u.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              u.phone.isEmpty ? '-' : u.phone,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openForm(context, u),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, c, u),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, CustomerController c) {
    final searching = c.search.value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 36, color: _muted),
            const SizedBox(height: 12),
            Text(
              searching ? 'No customers match "${c.search.value}"' : 'No customers yet',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              searching
                  ? 'Try a different name or code.'
                  : 'Add a customer to get started.',
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pager(CustomerController c, int shown) {
    final total = c.filtered.length;
    final start = shown == 0 ? 0 : c.page.value * CustomerController.pageSize + 1;
    final end = shown == 0 ? 0 : start + shown - 1;
    final hasPrev = c.page.value > 0;
    final hasNext = c.page.value < c.pageCount - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            total == 0
                ? 'No customers'
                : 'Showing $start to $end of $total customers',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          Row(
            children: [
              TextButton(
                onPressed: hasPrev ? c.prevPage : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${c.page.value + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: hasNext ? c.nextPage : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}