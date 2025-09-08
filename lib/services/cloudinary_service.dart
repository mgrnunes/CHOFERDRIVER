import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
// Substitua pelos dados do seu Cloudinary
static const String _cloudName = 'dgs7wn8gm';
static const String _uploadPreset = 'motorista_doc';

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Faz upload de uma imagem para uma pasta no Cloudinary e retorna a URL segura
  static Future<String?> uploadImage(File? file, String folder) async {
    if (file == null) return null;
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Erro ao enviar imagem: $e');
    }
  }
}
