import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _apiKey = '76dcaca5eb234d1f1c49fa8129fe2c82';

  /// Uploads raw image bytes to imgbb and returns the public URL.
  /// Works on both mobile and web because it never touches dart:io File.
  static Future<String?> uploadBytes(Uint8List bytes) async {
    try {
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['data'] as Map<String, dynamic>)['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
