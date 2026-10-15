import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileProvider extends GetConnect {
  final box = GetStorage();
  static const baseDomain = 'https://latest-dev.vbsxr.com';

  Future<String?> uploadImage(Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse('$baseDomain/fs/api/upload/file');
      final sanitizedFilename = filename.replaceAll(' ', '_');

      final extension = sanitizedFilename.split('.').last.toLowerCase();
      MediaType contentType;
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }
      final request = http.MultipartRequest('POST', uri);
      final token = box.read('token');
      if (token != null && token.toString().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      request.fields['FileName'] = sanitizedFilename;
      request.files.add(
        http.MultipartFile.fromBytes(
          'File',
          bytes,
          filename: sanitizedFilename,
          contentType: contentType,
        ),
      );
      request.headers.remove('content-length');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('UPLOAD ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) {
          final data =
              body['data'] ?? body['result'] ?? body['results'] ?? body;
          if (data is Map) {
            return (data['url'] ??
                    data['path'] ??
                    data['fileUrl'] ??
                    data['fileName'])
                ?.toString();
          } else if (data is String) {
            return data;
          }
        }
      }
    } catch (e) {
      print('Upload Exception: $e');
    }
    return null;
  }
}
