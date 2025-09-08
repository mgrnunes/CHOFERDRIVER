import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Cria o usuário no Auth e insere dados na tabela `usuarios`
  static Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Falha ao criar usuário');

    // Ajustes de dados
    final data = Map<String, dynamic>.from(userData);
    if (data['nascimento'] is String &&
        (data['nascimento'] as String).contains('/')) {
      data['nascimento'] = _convertToIsoDate(data['nascimento']);
    }
    if (data['placa'] is String) {
      data['placa'] = (data['placa'] as String).toUpperCase().trim();
    }

    await client.from('usuarios').insert({
      'id': user.id,
      ...data,
    });
  }

  /// Converte "DD/MM/AAAA" para "AAAA-MM-DD"
  static String _convertToIsoDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return date;
      final d = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      final y = parts[2];
      return '$y-$m-$d';
    } catch (_) {
      return date;
    }
  }

  /// Retorna dados do usuário logado
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return await client
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  /// Login simples
  static Future<void> signIn(String email, String password) async {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Credenciais inválidas');
  }

  /// Atualiza status online/offline
  static Future<void> updateOnlineStatus(bool online) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');
    await client.from('usuarios').update({'online': online}).eq('id', user.id);
  }

  /// Atualiza notas, aceitação e cancelamento
  static Future<void> updateDriverStats({
    required double rating,
    required double acceptance,
    required double cancellation,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');
    await client.from('usuarios').update({
      'rating': rating,
      'acceptance': acceptance,
      'cancellation': cancellation,
    }).eq('id', user.id);
  }

  /// Busca eventos do Supabase para exibir no mapa
  static Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await client.from('events').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
