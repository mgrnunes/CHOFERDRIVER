import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({Key? key}) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmaSenhaController = TextEditingController();
  final nomeController = TextEditingController();
  final nascimentoController = TextEditingController();
  final telefoneController = TextEditingController();
  final cepController = TextEditingController();
  final cidadeController = TextEditingController();
  final bairroController = TextEditingController();
  final ruaController = TextEditingController();
  final fabricanteController = TextEditingController();
  final modeloController = TextEditingController();
  final placaController = TextEditingController();
  final anoController = TextEditingController();

  File? rgImage;
  File? cnhImage;
  File? selfieImage;
  File? crlvImage;

  bool loading = false;
  bool aceitaTermos = false;

  Future<void> _pickImage(Function(File) setImage) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setImage(File(picked.path));
      setState(() {});
    }
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!aceitaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar os termos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Upload das imagens
      final rgUrl =
          await CloudinaryService.uploadImage(rgImage, 'documentos/rg');
      final cnhUrl =
          await CloudinaryService.uploadImage(cnhImage, 'documentos/cnh');
      final selfieUrl =
          await CloudinaryService.uploadImage(selfieImage, 'documentos/selfie');
      final crlvUrl =
          await CloudinaryService.uploadImage(crlvImage, 'documentos/crlv');

      // Inserção no Supabase
      await SupabaseService.signUp(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
        userData: {
          'nome': nomeController.text.trim(),
          'nascimento': nascimentoController.text.trim(),
          'telefone': telefoneController.text.trim(),
          'cep': cepController.text.trim(),
          'cidade': cidadeController.text.trim(),
          'bairro': bairroController.text.trim(),
          'rua': ruaController.text.trim(),
          'email': emailController.text.trim(),
          'fabricante': fabricanteController.text.trim(),
          'modelo': modeloController.text.trim(),
          'placa': placaController.text.trim(),
          'ano': int.tryParse(anoController.text.trim()),
          'rg_url': rgUrl,
          'cnh_url': cnhUrl,
          'selfie_cnh_url': selfieUrl,
          'crlv_url': crlvUrl,
        },
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/cadastro_sucesso');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey), // Placeholder cinza escuro
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  Widget _tf(TextEditingController c, String h,
      {bool obsc = false, String? Function(String?)? v}) {
    return TextFormField(
      controller: c,
      obscureText: obsc,
      style: const TextStyle(color: Colors.black),
      decoration: _dec(h),
      validator: v,
    );
  }

  Widget _docBtn(String label, File? file, void Function(File) setImage) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => _pickImage(setImage),
          child: Text(file == null ? 'Enviar $label' : 'Trocar $label'),
        ),
        const SizedBox(width: 8),
        if (file != null) const Icon(Icons.check, color: Colors.green),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Cadastro Motorista'), backgroundColor: Colors.black),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo do app no topo
                Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  child: Image.asset(
                    'assets/images/logo.png', // Substitua pelo nome da sua logo
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback caso a imagem não seja encontrada
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_taxi,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                
                _tf(nomeController, 'Nome completo', v: (v) => v!.isEmpty ? 'Informe o nome' : null),
                const SizedBox(height: 12),
                _tf(nascimentoController, 'Nascimento (DD/MM/AAAA)', v: (v) => v!.isEmpty ? 'Informe a data' : null),
                const SizedBox(height: 12),
                _tf(telefoneController, 'Telefone', v: (v) => v!.isEmpty ? 'Informe o telefone' : null),
                const SizedBox(height: 12),
                _tf(cepController, 'CEP', v: (v) => v!.isEmpty ? 'Informe o CEP' : null),
                const SizedBox(height: 12),
                _tf(cidadeController, 'Cidade', v: (v) => v!.isEmpty ? 'Informe a cidade' : null),
                const SizedBox(height: 12),
                _tf(bairroController, 'Bairro', v: (v) => v!.isEmpty ? 'Informe o bairro' : null),
                const SizedBox(height: 12),
                _tf(ruaController, 'Rua', v: (v) => v!.isEmpty ? 'Informe a rua' : null),
                const SizedBox(height: 12),

                _docBtn('RG', rgImage, (f) => setState(() => rgImage = f)),
                _docBtn('CNH', cnhImage, (f) => setState(() => cnhImage = f)),
                _docBtn('Selfie com CNH', selfieImage, (f) => setState(() => selfieImage = f)),
                _docBtn('CRLV', crlvImage, (f) => setState(() => crlvImage = f)),
                const SizedBox(height: 12),

                _tf(emailController, 'E-mail', v: (v) => v!.isEmpty ? 'Informe o e-mail' : null),
                const SizedBox(height: 12),
                _tf(fabricanteController, 'Fabricante', v: (v) => v!.isEmpty ? 'Informe o fabricante' : null),
                const SizedBox(height: 12),
                _tf(modeloController, 'Modelo', v: (v) => v!.isEmpty ? 'Informe o modelo' : null),
                const SizedBox(height: 12),
                _tf(placaController, 'Placa', v: (v) => v!.isEmpty ? 'Informe a placa' : null),
                const SizedBox(height: 12),
                _tf(anoController, 'Ano', v: (v) => v!.isEmpty ? 'Informe o ano' : null),
                const SizedBox(height: 12),

                _tf(senhaController, 'Senha', obsc: true, v: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null),
                const SizedBox(height: 12),
                _tf(confirmaSenhaController, 'Confirmar senha', obsc: true, v: (v) {
                  if (v!.isEmpty) return 'Confirme a senha';
                  if (v != senhaController.text) return 'Senhas não coincidem';
                  return null;
                }),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(value: aceitaTermos, onChanged: (v) => setState(() => aceitaTermos = v ?? false)),
                    const Expanded(child: Text('Li e concordo com os termos', style: TextStyle(color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Botão laranja
                      foregroundColor: Colors.white, // Texto branco
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}