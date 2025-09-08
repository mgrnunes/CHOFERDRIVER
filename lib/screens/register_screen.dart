import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
// SUBSTITUIR Firebase Storage por Cloudinary
import 'services/cloudinary_service.dart';

class ImprovedDriverRegistration extends StatefulWidget {
  @override
  _ImprovedDriverRegistrationState createState() => _ImprovedDriverRegistrationState();
}

class _ImprovedDriverRegistrationState extends State<ImprovedDriverRegistration> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // CLOUDINARY SERVICE (substitui Firebase Storage)
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Controllers para dados pessoais
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _rgController = TextEditingController();
  final TextEditingController _nascimentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Controllers para endereço
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  
  // Controllers para CNH
  final TextEditingController _cnhController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _validadeController = TextEditingController();
  
  // Controllers para veículo
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _anoController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _renavamController = TextEditingController();
  
  // Controllers para senha
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  // Arquivos de documentos
  Map<String, File?> _documentos = {
    'profilePhoto': null,
    'cpfPhoto': null,
    'rgPhoto': null,
    'driverLicense': null,
    'criminalRecord': null,
    'residenceProof': null,
    'vehicleRegistration': null,
    'insurance': null,
    'inspection': null,
  };
  
  List<File> _vehiclePhotos = [];

  bool _isLoading = false;
  bool _termos = false;
  int _currentStep = 0;
  double _uploadProgress = 0.0;

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  // NOVA FUNÇÃO DE UPLOAD COM CLOUDINARY
  Future<String> _uploadDocument(File file, String documentType, String userId) async {
    try {
      String downloadURL = await _cloudinaryService.uploadDocument(
        file, 
        documentType, 
        userId
      );
      return downloadURL;
    } catch (e) {
      throw Exception('Erro no upload de $documentType: $e');
    }
  }

  // NOVA FUNÇÃO PARA UPLOAD COM PROGRESSO
  Future<String> _uploadDocumentWithProgress(File file, String documentType, String userId) async {
    try {
      String downloadURL = await _cloudinaryService.uploadDocumentWithProgress(
        file, 
        documentType, 
        userId,
        (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
      return downloadURL;
    } catch (e) {
      throw Exception('Erro no upload de $documentType: $e');
    }
  }

  // Função principal de cadastro - MODIFICADA PARA CLOUDINARY
  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termos) {
      _showMessage('Você deve aceitar os termos de uso', isError: true);
      return;
    }

    if (_senhaController.text != _confirmarSenhaController.text) {
      _showMessage('As senhas não coincidem', isError: true);
      return;
    }

    // Verificar documentos obrigatórios
    List<String> requiredDocs = ['profilePhoto', 'cpfPhoto', 'rgPhoto', 'driverLicense', 'vehicleRegistration'];
    for (String docType in requiredDocs) {
      if (_documentos[docType] == null) {
        _showMessage('Documento obrigatório: $docType', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Criar usuário no Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      String userId = userCredential.user!.uid;
      await userCredential.user!.updateDisplayName(_nomeController.text.trim());

      _showMessage('Iniciando upload dos documentos...', isError: false);

      // UPLOAD DOS DOCUMENTOS COM CLOUDINARY
      Map<String, String> documentURLs = {};
      int totalDocuments = _documentos.where((key, value) => value != null).length;
      int uploadedCount = 0;

      for (String docType in _documentos.keys) {
        if (_documentos[docType] != null) {
          try {
            setState(() {
              _uploadProgress = uploadedCount / totalDocuments;
            });
            
            String url = await _uploadDocument(_documentos[docType]!, docType, userId);
            documentURLs[docType] = url;
            uploadedCount++;
            
            _showMessage('✅ $docType enviado com sucesso', isError: false);
          } catch (e) {
            print('Erro no upload de $docType: $e');
            _showMessage('❌ Erro no upload de $docType', isError: true);
            // Continua com outros documentos
          }
        }
      }

      // UPLOAD DAS FOTOS DO VEÍCULO COM CLOUDINARY
      List<String> vehiclePhotoURLs = [];
      if (_vehiclePhotos.isNotEmpty) {
        _showMessage('Enviando fotos do veículo...', isError: false);
        try {
          vehiclePhotoURLs = await _cloudinaryService.uploadVehiclePhotos(_vehiclePhotos, userId);
          _showMessage('✅ Fotos do veículo enviadas', isError: false);
        } catch (e) {
          print('Erro no upload das fotos do veículo: $e');
          _showMessage('❌ Erro no upload das fotos do veículo', isError: true);
        }
      }

      // Salvar no Firestore
      _showMessage('Salvando dados...', isError: false);
      
      await _firestore.collection('drivers').doc(userId).set({
        // Dados pessoais
        'personalInfo': {
          'fullName': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'rg': _rgController.text.trim(),
          'birthDate': _nascimentoController.text.trim(),
          'phone': _telefoneController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'address': {
            'street': _ruaController.text.trim(),
            'number': _numeroController.text.trim(),
            'neighborhood': _bairroController.text.trim(),
            'city': _cidadeController.text.trim(),
            'state': _estadoController.text.trim(),
            'zipCode': _cepController.text.trim(),
          }
        },
        
        // Documentos (URLs do Cloudinary)
        'documents': documentURLs,
        
        // Dados do veículo
        'vehicle': {
          'brand': _marcaController.text.trim(),
          'model': _modeloController.text.trim(),
          'year': int.tryParse(_anoController.text.trim()) ?? DateTime.now().year,
          'color': _corController.text.trim(),
          'plate': _placaController.text.trim().toUpperCase(),
          'renavam': _renavamController.text.trim(),
          'documents': {
            'vehicleRegistration': documentURLs['vehicleRegistration'] ?? '',
            'insurance': documentURLs['insurance'] ?? '',
            'inspection': documentURLs['inspection'] ?? '',
            'vehiclePhotos': vehiclePhotoURLs,
          }
        },
        
        // CNH
        'driverLicense': {
          'number': _cnhController.text.trim(),
          'category': _categoriaController.text.trim(),
          'expiryDate': _validadeController.text.trim(),
        },
        
        // Status de aprovação
        'status': 'pending',
        'registrationStatus': 'pending',
        'approvalNotes': '',
        'submittedAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': '',
        
        // Dados operacionais
        'isActive': false,
        'isOnline': false,
        'rating': 0.0,
        'totalRides': 0,
        'totalEarnings': 0.0,
        
        // Metadados
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        
        // Localização
        'currentLocation': null,
        'geohash': '',
      });

      _showMessage('🎉 Cadastro realizado com sucesso!\nAguarde a aprovação dos seus documentos.', isError: false);
      
      // Fazer logout para que o usuário precise fazer login após aprovação
      await _auth.signOut();
      
      await Future.delayed(Duration(seconds: 3));
      Navigator.of(context).pushReplacementNamed('/login');

    } catch (e) {
      String errorMessage = 'Erro ao realizar cadastro';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'A senha é muito fraca';
            break;
          case 'email-already-in-use':
            errorMessage = 'Este e-mail já está em uso';
            break;
          case 'invalid-email':
            errorMessage = 'E-mail inválido';
            break;
          default:
            errorMessage = 'Erro de autenticação: ${e.message}';
        }
      } else {
        errorMessage = 'Erro: ${e.toString()}';
      }
      
      _showMessage(errorMessage, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // Função para selecionar imagem
  Future<void> _pickImage(String documentType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _documentos[documentType] = File(image.path);
      });
    }
  }

  // Função para selecionar múltiplas fotos do veículo
  Future<void> _pickVehiclePhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (images != null && images.isNotEmpty) {
      setState(() {
        _vehiclePhotos = images.take(5).map((image) => File(image.path)).toList();
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Motorista'),
        backgroundColor: Colors.orange,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.orange),
        ),
        child: Stack(
          children: [
            Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    if (details.stepIndex < 4)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text('Próximo'),
                      ),
                    if (details.stepIndex == 4)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerDriver,
                        child: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Finalizar Cadastro'),
                      ),
                    SizedBox(width: 8),
                    if (details.stepIndex > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text('Voltar'),
                      ),
                  ],
                );
              },
              steps: [
                _buildPersonalDataStep(),
                _buildAddressStep(),
                _buildDocumentsStep(),
                _buildVehicleStep(),
                _buildFinalStep(),
              ],
            ),
            
            // Indicador de progresso de upload
            if (_isLoading && _uploadProgress > 0)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enviando documentos...',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Step _buildPersonalDataStep() {
    return Step(
      title: Text('Dados Pessoais'),
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField('Nome Completo', _nomeController, required: true),
            _buildTextField('CPF', _cpfController, required: true),
            _buildTextField('RG', _rgController, required: true),
            _buildTextField('Data de Nascimento', _nascimentoController, required: true),
            _buildTextField('Telefone', _telefoneController, required: true),
            _buildTextField('E-mail', _emailController, required: true, isEmail: true),
            _buildTextField('CNH', _cnhController, required: true),
            _buildTextField('Categoria CNH', _categoriaController, required: true),
            _buildTextField('Validade CNH', _validadeController, required: true),
          ],
        ),
      ),
      isActive: _currentStep == 0,
    );
  }

  Step _buildAddressStep() {
    return Step(
      title: Text('Endereço'),
      content: Column(
        children: [
          _buildTextField('CEP', _cepController, required: true),
          _buildTextField('Rua', _ruaController, required: true),
          _buildTextField('Número', _numeroController, required: true),
          _buildTextField('Bairro', _bairroController, required: true),
          _buildTextField('Cidade', _cidadeController, required: true),
          _buildDropdownField('Estado', _estadoController, _estados, required: true),
        ],
      ),
      isActive: _currentStep == 1,
    );
  }

  Step _buildDocumentsStep() {
    return Step(
      title: Text('Documentos'),
      content: Column(
        children: [
          _buildDocumentUpload('Foto de Perfil', 'profilePhoto'),
          _buildDocumentUpload('Foto do CPF', 'cpfPhoto'),
          _buildDocumentUpload('Foto do RG', 'rgPhoto'),
          _buildDocumentUpload('Foto da CNH', 'driverLicense'),
          _buildDocumentUpload('Antecedentes Criminais', 'criminalRecord'),
          _buildDocumentUpload('Comprovante de Residência', 'residenceProof'),
        ],
      ),
      isActive: _currentStep == 2,
    );
  }

  Step _buildVehicleStep() {
    return Step(
      title: Text('Dados do Veículo'),
      content: Column(
        children: [
          _buildTextField('Marca', _marcaController, required: true),
          _buildTextField('Modelo', _modeloController, required: true),
          _buildTextField('Ano', _anoController, required: true, isNumeric: true),
          _buildTextField('Cor', _corController, required: true),
          _buildTextField('Placa', _placaController, required: true),
          _buildTextField('RENAVAM', _renavamController, required: true),
          _buildDocumentUpload('CRLV do Veículo', 'vehicleRegistration'),
          _buildDocumentUpload('Seguro do Veículo', 'insurance'),
          _buildDocumentUpload('Vistoria do Veículo', 'inspection'),
          _buildVehiclePhotosUpload(),
        ],
      ),
      isActive: _currentStep == 3,
    );
  }

  Step _buildFinalStep() {
    return Step(
      title: Text('Finalizar'),
      content: Column(
        children: [
          _buildTextField('Senha (mínimo 6 caracteres)', _senhaController, required: true, isPassword: true),
          _buildTextField('Confirmar Senha', _confirmarSenhaController, required: true, isPassword: true),
          SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _termos,
                onChanged: (value) => setState(() => _termos = value ?? false),
                activeColor: Colors.orange,
              ),
              Expanded(
                child: Text('Li e concordo com os termos de uso e política de privacidade'),
              ),
            ],
          ),
        ],
      ),
      isActive: _currentStep == 4,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    bool required = false,
    bool isEmail = false,
    bool isPassword = false,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail 
            ? TextInputType.emailAddress 
            : isNumeric 
                ? TextInputType.number 
                : TextInputType.text,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '$label é obrigatório';
          }
          if (isEmail && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'E-mail inválido';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '$label é obrigatório';
          }
          return null;
        },
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
          }
        },
      ),
    );
  }

  Widget _buildDocumentUpload(String label, String documentType) {
    bool hasFile = _documentos[documentType] != null;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(documentType),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: hasFile ? Colors.green : Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        hasFile ? 'Arquivo selecionado ✓' : 'Tocar para selecionar',
                        style: TextStyle(
                          color: hasFile ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasFile ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      hasFile ? Icons.check : Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotosUpload() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fotos do Veículo (até 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          GestureDetector(
            onTap: _pickVehiclePhotos,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: _vehiclePhotos.isNotEmpty ? Colors.green : Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _vehiclePhotos.isNotEmpty 
                            ? '${_vehiclePhotos.length} foto(s) selecionada(s) ✓' 
                            : 'Tocar para selecionar fotos',
                        style: TextStyle(
                          color: _vehiclePhotos.isNotEmpty ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _vehiclePhotos.isNotEmpty ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      _vehiclePhotos.isNotEmpty ? Icons.check : Icons.photo_library,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nomeController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _nascimentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _cnhController.dispose();
    _categoriaController.dispose();
    _validadeController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _corController.dispose();
    _placaController.dispose();
    _renavamController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}