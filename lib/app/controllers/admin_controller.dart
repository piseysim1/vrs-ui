import 'package:get/get.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/rate_model.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';

const _seedLookups = <OptionItem>[
  OptionItem(id: 4, name: 'Available', typeId: kStatusTypeId),
  OptionItem(id: 5, name: 'Unavailable', typeId: kStatusTypeId),
  OptionItem(id: 6, name: 'Rented', typeId: kStatusTypeId),
  OptionItem(id: 3, name: 'Red', typeId: kColorTypeId),
  OptionItem(id: 7, name: 'Black', typeId: kColorTypeId),
  OptionItem(id: 8, name: 'White', typeId: kColorTypeId),
  OptionItem(id: 9, name: 'Silver', typeId: kColorTypeId),
  OptionItem(id: 10, name: 'Blue', typeId: kColorTypeId),
];

const kRateTypeId = 2;
const kStatusTypeId = 3;
const kColorTypeId = 4;

const kDayRateType = 1;
const kHourRateType = 2;

enum StatusKind { available, onRent, reserved, maintenance, other }

StatusKind statusKindOf(String raw) {
  final s = raw.toLowerCase().trim();
  if (s.contains('unavail') ||
      s.contains('មិនអាច') ||
      s.contains('maint') ||
      s.contains('service') ||
      s.contains('repair')) {
    return StatusKind.maintenance;
  }
  if (s.contains('avail') || s.contains('អាចជួល')) return StatusKind.available;
  if (s.contains('rent') || s.contains('កំពុងជួល')) return StatusKind.onRent;
  if (s.contains('reserv')) return StatusKind.reserved;
  return StatusKind.other;
}

class BrandChip {
  final int id;
  final String name;
  final int count;
  BrandChip(this.id, this.name, this.count);
}

class AdminController extends GetxController {
  final api = AdminProvider();
  static const pageSize = 6;

  final menuIndex = 5.obs;
  final isLoading = false.obs;

  final vehicles = <VehicleModel>[].obs;
  final rates = <RateModel>[].obs;
  final brands = <OptionItem>[].obs;
  final models = <OptionItem>[].obs;
  final locations = <OptionItem>[].obs;
  final colors = <OptionItem>[].obs;
  final statuses = <OptionItem>[].obs;

  final search = ''.obs;
  final rowFilter = ''.obs;
  final brandFilter = (-1).obs;
  final page = 0.obs;
  final selected = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const [
        'results',
        'Results',
        'items',
        'Items',
        'lookUpItems',
        'data',
      ]) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  List<OptionItem> _opts(Response r) => r.statusCode == 200
      ? _list(r.body).map((e) => OptionItem.fromJson(e)).toList()
      : <OptionItem>[];
  List<OptionItem> _lookups = [];

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final res = await Future.wait([
        api.getVehicles(), // 0
        api.getBrands(), // 1
        api.getModels(), // 2
        api.getLocations(), // 3
        api.getRates(), // 4
      ]);

      if (res[4].statusCode == 200) {
        rates.value = _list(
          res[4].body,
        ).map((e) => RateModel.fromJson(e)).toList();
      }

      if (res[0].statusCode == 200) {
        vehicles.value = _list(
          res[0].body,
        ).map((e) => VehicleModel.fromJson(e)).toList();
      } else {
        Get.snackbar('Error', 'Vehicles: HTTP ${res[0].statusCode}');
      }

      brands.value = _opts(res[1]);
      models.value = _opts(res[2]);
      locations.value = _opts(res[3]);
      await _loadLookups();
      _fillFallbacks();
      selected.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLookups() async {
    if (_lookups.isEmpty) _lookups = await api.fetchLookupItems();

    List<OptionItem> ofType(int t) {
      final l = _lookups.where((e) => e.typeId == t).toList();
      final use = l.isNotEmpty
          ? l
          : _seedLookups.where((e) => e.typeId == t).toList();
      return use..sort((a, b) => a.id.compareTo(b.id));
    }

    colors.value = ofType(kColorTypeId);
    statuses.value = ofType(kStatusTypeId);
  }

  Future<void> _reloadRates() async {
    final r = await api.getRates();
    if (r.statusCode == 200) {
      rates.value = _list(r.body).map((e) => RateModel.fromJson(e)).toList();
    }
  }

  void _fillFallbacks() {
    List<OptionItem> distinct(
      Iterable<MapEntry<int?, String>> src, {
      Map<int, int?>? parents,
    }) {
      final seen = <int>{};
      final out = <OptionItem>[];
      for (final e in src) {
        final id = e.key;
        if (id == null || id == 0 || e.value.isEmpty || !seen.add(id)) continue;
        out.add(OptionItem(id: id, name: e.value, parentId: parents?[id]));
      }
      return out;
    }

    if (brands.isEmpty) {
      brands.value = distinct(
        vehicles.map((v) => MapEntry(v.brandId, v.brandName)),
      );
    }
    if (locations.isEmpty) {
      locations.value = distinct(
        vehicles.map((v) => MapEntry(v.locationId, v.locationName)),
      );
    }
    if (colors.isEmpty) {
      colors.value = distinct(
        vehicles.map((v) => MapEntry(v.colorId, v.colorName)),
      );
    }
    if (statuses.isEmpty) {
      statuses.value = distinct(
        vehicles.map((v) => MapEntry(v.statusId, v.statusName)),
      );
    }
    if (models.isEmpty) {
      final parents = <int, int?>{};
      for (final v in vehicles) {
        if (v.modelId != null) parents[v.modelId!] = v.brandId;
      }
      models.value = distinct(
        vehicles.map((v) => MapEntry(v.modelId, v.modelName)),
        parents: parents,
      );
    }
  }

  RateModel? findRate(int? modelId, int typeId) {
    if (modelId == null) return null;
    for (final r in rates) {
      if (r.modelId == modelId && r.rateTypeId == typeId) return r;
    }
    return null;
  }

  // ---------- filter + pagination ----------
  List<VehicleModel> get filtered {
    final q = search.value.trim().toLowerCase();
    final f = rowFilter.value.trim().toLowerCase();
    final b = brandFilter.value;

    return vehicles.where((v) {
      if (b != -1 && v.brandId != b) return false;
      bool hit(String t) =>
          t.isEmpty ||
          [
            v.displayName,
            v.licensePlate,
            v.locationName,
            v.statusName,
            v.colorName,
          ].any((s) => s.toLowerCase().contains(t));
      return hit(q) && hit(f);
    }).toList();
  }

  List<BrandChip> get brandChips {
    final names = <int, String>{};
    final counts = <int, int>{};
    for (final v in vehicles) {
      final id = v.brandId;
      if (id == null) continue;
      names[id] = v.brandName;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return names.entries
        .map((e) => BrandChip(e.key, e.value, counts[e.key]!))
        .toList();
  }

  int get pageCount =>
      (filtered.length / pageSize).ceil().clamp(1, 9999).toInt();

  List<VehicleModel> get pageItems {
    final list = filtered;
    final start = (page.value * pageSize).clamp(0, list.length).toInt();
    final end = (start + pageSize).clamp(0, list.length).toInt();
    return list.sublist(start, end);
  }

  void setSearch(String v) {
    search.value = v;
    page.value = 0;
  }

  void setRowFilter(String v) {
    rowFilter.value = v;
    page.value = 0;
  }

  void setBrand(int id) {
    brandFilter.value = id;
    page.value = 0;
  }

  // ---------- selection ----------
  void toggleSelect(int? id) {
    if (id == null) return;
    selected.contains(id) ? selected.remove(id) : selected.add(id);
  }

  void togglePage(List<VehicleModel> items) {
    final ids = items.map((v) => v.id).whereType<int>().toList();
    final all = ids.every(selected.contains);
    all ? selected.removeAll(ids) : selected.addAll(ids);
  }

  // ---------- CRUD ----------
  bool _ok(int? c) => c == 200 || c == 201 || c == 204;

  /// Finds the model by name, or creates it. Returns its id.
  Future<int?> resolveModelId(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return null;

    OptionItem? find() => models.firstWhereOrNull(
      (m) => m.name.toLowerCase() == name.toLowerCase(),
    );

    final existing = find();
    if (existing != null) return existing.id;

    final res = await api.createModel({
      'code': _modelCode(name),
      'name': name,
      'note': '',
    });
    print('CREATE MODEL ${res.statusCode}: ${res.body}');
    if (!_ok(res.statusCode)) {
      Get.snackbar('Model failed', 'HTTP ${res.statusCode}: ${res.bodyString}');
      return null;
    }

    final r = await api.getModels(); // POST may not return the id
    if (r.statusCode == 200) models.value = _opts(r);
    return find()?.id;
  }

  String _modelCode(String name) {
    var base = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (base.isEmpty) base = 'MODEL';
    if (base.length > 10) base = base.substring(0, 10);
    var code = base;
    var n = 1;
    while (models.any((m) => m.code == code)) {
      code = '$base${n++}';
    }
    return code;
  }

  Future<bool> saveVehicle({
    int? id,
    required String modelName,
    required Map<String, dynamic> body,
    double? dayPrice,
    double? hourPrice,
  }) async {
    try {
      final modelId = await resolveModelId(modelName);
      if (modelId == null) return false;

      if (dayPrice != null) await _upsertRate(modelId, kDayRateType, dayPrice);
      if (hourPrice != null)
        await _upsertRate(modelId, kHourRateType, hourPrice);

      final payload = {...body, 'modelId': modelId};
      final res = id == null
          ? await api.createVehicle(payload)
          : await api.updateVehicle(id, {...payload, 'id': id});
      print('SAVE VEHICLE ${res.statusCode}: ${res.body}');

      if (!_ok(res.statusCode)) {
        Get.snackbar('Error', 'HTTP ${res.statusCode}: ${res.bodyString}');
        return false;
      }
      Get.snackbar(
        'Success',
        id == null ? 'Vehicle created' : 'Vehicle updated',
      );
      await loadAll();
      return true;
    } catch (e) {
      Get.snackbar('Error', '$e');
      return false;
    }
  }

  /// Creates or updates the rate for (model, type) and returns its id.
  Future<int?> _upsertRate(int modelId, int typeId, double price) async {
    final existing = findRate(modelId, typeId);

    if (existing != null) {
      if (existing.price == price) return existing.id;

      final res = await api.updateRate(existing.id!, {
        'id': existing.id,
        'code': existing.code,
        'modelId': modelId,
        'rateTypeId': typeId,
        'price': price,
      });
      print('UPDATE RATE ${res.statusCode}: ${res.body}');
      if (!_ok(res.statusCode)) {
        Get.snackbar(
          'Rate failed',
          'HTTP ${res.statusCode}: ${res.bodyString}',
        );
        return existing.id;
      }
      await _reloadRates();
      return existing.id;
    }

    final res = await api.createRate({
      'code': 'R$modelId-$typeId',
      'modelId': modelId,
      'rateTypeId': typeId,
      'price': price,
    });
    print('CREATE RATE ${res.statusCode}: ${res.body}');
    if (!_ok(res.statusCode)) {
      Get.snackbar('Rate failed', 'HTTP ${res.statusCode}: ${res.bodyString}');
      return null;
    }
    await _reloadRates(); // POST may not return the id, so look it up
    return findRate(modelId, typeId)?.id;
  }

  Future<bool> removeVehicle(int id) async {
    final res = await api.deleteVehicle(id);
    final ok = _ok(res.statusCode);
    Get.snackbar(
      ok ? 'Deleted' : 'Delete failed',
      ok ? 'Vehicle removed' : 'HTTP ${res.statusCode}: ${res.bodyString}',
    );
    await loadAll();
    return ok;
  }

  Future<void> removeSelected() async {
    final ids = selected.toList();
    var done = 0;
    for (final id in ids) {
      final r = await api.deleteVehicle(id);
      if (_ok(r.statusCode)) done++;
    }
    Get.snackbar('Deleted', '$done of ${ids.length} vehicles removed');
    await loadAll();
  }
}
