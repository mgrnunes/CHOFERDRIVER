// utils/validators.dart
class Validators {
  static bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cpf.length != 11) return false;
    if (cpf == cpf[0] * 11) return false; // Números repetidos
    
    // Validação do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;
    
    if (digit1 != int.parse(cpf[9])) return false;
    
    // Validação do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;
    
    return digit2 == int.parse(cpf[10]);
  }
  
  static bool isValidCNH(String cnh) {
    cnh = cnh.replaceAll(RegExp(r'[^0-9]'), '');
    return cnh.length == 11;
  }
  
  static bool isValidPlate(String plate) {
    // Formato antigo: ABC-1234 ou novo: ABC1D23
    plate = plate.replaceAll('-', '').toUpperCase();
    
    // Placa antiga
    if (RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(plate)) return true;
    // Placa Mercosul
    if (RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$').hasMatch(plate)) return true;
    
    return false;
  }
  
  static bool isValidRENAVAM(String renavam) {
    renavam = renavam.replaceAll(RegExp(r'[^0-9]'), '');
    return renavam.length >= 9 && renavam.length <= 11;
  }
  
  static bool isValidPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length >= 10 && phone.length <= 11;
  }
  
  static bool isValidCEP(String cep) {
    cep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    return cep.length == 8;
  }
  
  static bool isAdult(String birthDate) {
    try {
      DateTime birth = DateTime.parse(birthDate.split('/').reversed.join('-'));
      DateTime now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || 
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age >= 18;
    } catch (e) {
      return false;
    }
  }
}

// services/file_service.dart
import 'dart:io';

class FileService {
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  
  static bool isValidFile(File file) {
    // Verificar tamanho
    if (file.lengthSync() > maxFileSize) {
      throw Exception('Arquivo muito grande. Máximo 5MB permitido.');
    }
    
    // Verificar extensão
    String extension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Formato não permitido. Use: ${allowedExtensions.join(", ")}');
    }
    
    return true;
  }
  
  static Future<bool> isValidImage(File file) async {
    try {
      // Verificação básica se é uma imagem válida
      var bytes = await file.readAsBytes();
      
      // Verificar assinatura JPEG
      if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return true;
      }
      
      // Verificar assinatura PNG
      if (bytes.length >= 8 && 
          bytes[0] == 0x89 && bytes[1] == 0x50 && 
          bytes[2] == 0x4E && bytes[3] == 0x47) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}