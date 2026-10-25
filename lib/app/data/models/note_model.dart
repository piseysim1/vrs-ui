import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
Future<bool> saveModelNote(String modelName, String note) async {
  final ctrl = Get.find<AdminController>();
  final key = modelName.trim().toLowerCase();

  final OptionItem? model = ctrl.models.firstWhereOrNull(
    (m) => m.name.toLowerCase() == key,
  );
  if (model == null) {
    Get.snackbar('Model note', 'Model "$modelName" was not found');
    return false;
  }

  final String text = note.trim();
  final String current = ('${model.note ?? ''}').trim();
  if (current == text) return true; // nothing to change

  final res = await ctrl.api.put(
    '/vrms/api/model/id',
    {'id': model.id, 'code': model.code, 'name': model.name, 'note': text},
    query: {'id': '${model.id}'},
  );
  print('UPDATE MODEL NOTE ${res.statusCode}: ${res.body}');

  final bool ok =
      res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
  if (!ok) {
    Get.snackbar('Note not saved', 'HTTP ${res.statusCode}: ${res.bodyString}');
    return false;
  }

  await ctrl.loadAll();
  return true;
}