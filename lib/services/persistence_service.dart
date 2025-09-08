import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

// Modelos para persistência
@HiveType(typeId: 0)
class ConfiguracaoMotorista extends HiveObject {
  @HiveField(0)
  String motoristaId;

  @HiveField(1)
  bool isOnline;

  @HiveField(2)
  double metaDiaria;

  @HiveField(3)
  bool metaAtiva;

  @HiveField(4)
  double ganhoAtual;

  @HiveField(5)
  DateTime ultimaAtualizacao;

  @HiveField(6)
  Map<String, dynamic> configuracoes;

  ConfiguracaoMotorista({
    required this.motoristaId,
    this.isOnline = false,
    this.metaDiaria = 0.0,
    this.metaAtiva = false,
    this.ganhoAtual = 0.0,
    required this.ultimaAtualizacao,
    this.configuracoes = const {},
  });
}

@HiveType(typeId: 1)
class HistoricoCorrida extends HiveObject {
  @HiveField(0)
  String corridaId;

  @HiveField(1)
  String passageiroNome;

  @HiveField(2)
  String origem;

  @HiveField(3)
  String destino;

  @HiveField(4)
  double valor;

  @HiveField(5)
  double distancia;

  @HiveField(6)
  DateTime inicioEm;

  @HiveField(7)
  DateTime? fimEm;

  @HiveField(8)
  String status; // 'aceita', 'em_andamento', 'finalizada', 'cancelada'

  @HiveField(9)
  int? notaPassageiro;

  @HiveField(10)
  String? comentarioPassageiro;

  HistoricoCorrida({
    required this.corridaId,
    required this.passageiroNome,
    required this.origem,
    required this.destino,
    required this.valor,
    required this.distancia,
    required this.inicioEm,
    this.fimEm,
    required this.status,
    this.notaPassageiro,
    this.comentarioPassageiro,
  });
}

@HiveType(typeId: 2)
class LocalizacaoSalva extends HiveObject {
  @HiveField(0)
  String nome;

  @HiveField(1)
  String endereco;

  @HiveField(2)
  double latitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  DateTime salvoEm;

  @HiveField(5)
  String tipo; // 'favorito', 'recente', 'casa', 'trabalho'

  LocalizacaoSalva({
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.salvoEm,
    required this.tipo,
  });
}

class PersistenceService {
  static PersistenceService? _instance;
  static PersistenceService get instance => _instance ??= PersistenceService._();
  PersistenceService._();

  Box<ConfiguracaoMotorista>? _configBox;
  Box<HistoricoCorrida>? _corridasBox;
  Box<LocalizacaoSalva>? _localizacoesBox;
  Box? _cacheBox;

  /// Inicializa o Hive e registra adaptadores
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Registrar adaptadores (você precisa gerar estes com build_runner)
      // Hive.registerAdapter(ConfiguracaoMotoristaAdapter());
      // Hive.registerAdapter(HistoricoCorridaAdapter());
      // Hive.registerAdapter(LocalizacaoSalvaAdapter());

      // Abrir boxes
      _configBox = await Hive.openBox<ConfiguracaoMotorista>('configuracoes');
      _corridasBox = await Hive.openBox<HistoricoCorrida>('corridas');
      _localizacoesBox = await Hive.openBox<LocalizacaoSalva>('localizacoes');
      _cacheBox = await Hive.openBox('cache');

      debugPrint('Hive inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar Hive: $e');
    }
  }

  // === CONFIGURAÇÕES DO MOTORISTA ===

  /// Salva configuração do motorista
  Future<void> salvarConfiguracao(ConfiguracaoMotorista config) async {
    await _configBox?.put(config.motoristaId, config);
    debugPrint('Configuração salva para motorista: ${config.motoristaId}');
  }

  /// Obtém configuração do motorista
  ConfiguracaoMotorista? obterConfiguracao(String motoristaId) {
    return _configBox?.get(motoristaId);
  }

  /// Atualiza status online/offline
  Future<void> atualizarStatusOnline(String motoristaId, bool isOnline) async {
    var config = obterConfiguracao(motoristaId);
    if (config != null) {
      config.isOnline = isOnline;
      config.ultimaAtualizacao = DateTime.now();
      await salvarConfiguracao(config);
    }
  }

  /// Atualiza meta diária
  Future<void> atualizarMeta(String motoristaId, double metaDiaria, bool ativa) async {
    var config = obterConfiguracao(motoristaId);
    if (config != null) {
      config.metaDiaria = metaDiaria;
      config.metaAtiva = ativa;
      config.ultimaAtualizacao = DateTime.now();
      await salvarConfiguracao(config);
    }
  }

  /// Atualiza ganho atual
  Future<void> atualizarGanho(String motoristaId, double novoGanho) async {
    var config = obterConfiguracao(motoristaId);
    if (config != null) {
      config.ganhoAtual = novoGanho;
      config.ultimaAtualizacao = DateTime.now();
      await salvarConfiguracao(config);
    }
  }

  // === HISTÓRICO DE CORRIDAS ===

  /// Salva corrida no histórico
  Future<void> salvarCorrida(HistoricoCorrida corrida) async {
    await _corridasBox?.put(corrida.corridaId, corrida);
    debugPrint('Corrida salva: ${corrida.corridaId}');
  }

  /// Obtém histórico de corridas
  List<HistoricoCorrida> obterHistoricoCorridas({
    int? limite,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    var corridas = _corridasBox?.values.toList() ?? [];
    
    // Filtrar por data se especificado
    if (dataInicio != null || dataFim != null) {
      corridas = corridas.where((corrida) {
        if (dataInicio != null && corrida.inicioEm.isBefore(dataInicio)) {
          return false;
        }
        if (dataFim != null && corrida.inicioEm.isAfter(dataFim)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Ordenar por data (mais recentes primeiro)
    corridas.sort((a, b) => b.inicioEm.compareTo(a.inicioEm));

    // Limitar quantidade se especificado
    if (limite != null && corridas.length > limite) {
      corridas = corridas.take(limite).toList();
    }

    return corridas;
  }

  /// Calcula estatísticas do motorista
  Map<String, dynamic> calcularEstatisticas(String motoristaId) {
    final corridas = obterHistoricoCorridas();
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
    final inicioMes = DateTime(hoje.year, hoje.month, 1);

    // Corridas de hoje
    final corridasHoje = corridas.where((c) => 
      c.inicioEm.isAfter(inicioDia) && c.status == 'finalizada'
    ).toList();

    // Corridas da semana
    final corridasSemana = corridas.where((c) => 
      c.inicioEm.isAfter(inicioSemana) && c.status == 'finalizada'
    ).toList();

    // Corridas do mês
    final corridasMes = corridas.where((c) => 
      c.inicioEm.isAfter(inicioMes) && c.status == 'finalizada'
    ).toList();

    return {
      'hoje': {
        'quantidade': corridasHoje.length,
        'valor_total': corridasHoje.fold(0.0, (sum, c) => sum + c.valor),
        'distancia_total': corridasHoje.fold(0.0, (sum, c) => sum + c.distancia),
      },
      'semana': {
        'quantidade': corridasSemana.length,
        'valor_total': corridasSemana.fold(0.0, (sum, c) => sum + c.valor),
        'distancia_total': corridasSemana.fold(0.0, (sum, c) => sum + c.distancia),
      },
      'mes': {
        'quantidade': corridasMes.length,
        'valor_total': corridasMes.fold(0.0, (sum, c) => sum + c.valor),
        'distancia_total': corridasMes.fold(0.0, (sum, c) => sum + c.distancia),
      },
      'total': {
        'quantidade': corridas.length,
        'valor_total': corridas.fold(0.0, (sum, c) => sum + c.valor),
        'distancia_total': corridas.fold(0.0, (sum, c) => sum + c.distancia),
      },
    };
  }

  // === LOCALIZAÇÕES SALVAS ===

  /// Salva localização
  Future<void> salvarLocalizacao(LocalizacaoSalva localizacao) async {
    final key = '${localizacao.tipo}_${localizacao.nome}';
    await _localizacoesBox?.put(key, localizacao);
    debugPrint('Localização salva: ${localizacao.nome}');
  }

  /// Obtém localizações por tipo
  List<LocalizacaoSalva> obterLocalizacoes({String? tipo}) {
    var localizacoes = _localizacoesBox?.values.toList() ?? [];
    
    if (tipo != null) {
      localizacoes = localizacoes.where((loc) => loc.tipo == tipo).toList();
    }

    localizacoes.sort((a, b) => b.salvoEm.compareTo(a.salvoEm));
    return localizacoes;
  }

  /// Adiciona endereço recente
  Future<void> adicionarEnderecoRecente(
    String endereco, 
    double latitude, 
    double longitude
  ) async {
    final recente = LocalizacaoSalva(
      nome: endereco.split(',')[0], // Primeira parte do endereço
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
      salvoEm: DateTime.now(),
      tipo: 'recente',
    );

    await salvarLocalizacao(recente);

    // Manter apenas os 10 mais recentes
    final recentes = obterLocalizacoes(tipo: 'recente');
    if (recentes.length > 10) {
      for (int i = 10; i < recentes.length; i++) {
        await _localizacoesBox?.delete('recente_${recentes[i].nome}');
      }
    }
  }

  // === CACHE GERAL ===

  /// Salva dados no cache
  Future<void> salvarCache(String key, dynamic value, {Duration? duracao}) async {
    final dataExpiracao = duracao != null 
      ? DateTime.now().add(duracao) 
      : null;

    await _cacheBox?.put(key, {
      'data': value,
      'expiracao': dataExpiracao?.toIso8601String(),
    });
  }

  /// Obtém dados do cache
  dynamic obterCache(String key) {
    final cached = _cacheBox?.get(key);
    if (cached == null) return null;

    // Verificar expiração
    if (cached['expiracao'] != null) {
      final expiracao = DateTime.parse(cached['expiracao']);
      if (DateTime.now().isAfter(expiracao)) {
        _cacheBox?.delete(key);
        return null;
      }
    }

    return cached['data'];
  }

  /// Limpa cache expirado
  Future<void> limparCacheExpirado() async {
    final keys = _cacheBox?.keys.toList() ?? [];
    final agora = DateTime.now();

    for (final key in keys) {
      final cached = _cacheBox?.get(key);
      if (cached != null && cached['expiracao'] != null) {
        final expiracao = DateTime.parse(cached['expiracao']);
        if (agora.isAfter(expiracao)) {
          await _cacheBox?.delete(key);
        }
      }
    }
  }

  // === MÉTODOS UTILITÁRIOS ===

  /// Limpa todos os dados
  Future<void> limparTodosDados() async {
    await _configBox?.clear();
    await _corridasBox?.clear();
    await _localizacoesBox?.clear();
    await _cacheBox?.clear();
    debugPrint('Todos os dados foram limpos');
  }

  /// Exporta dados para backup
  Map<String, dynamic> exportarDados(String motoristaId) {
    final config = obterConfiguracao(motoristaId);
    final corridas = obterHistoricoCorridas();
    final localizacoes = obterLocalizacoes();

    return {
      'versao': '1.0.0',
      'data_backup': DateTime.now().toIso8601String(),
      'motorista_id': motoristaId,
      'configuracao': config != null ? {
        'meta_diaria': config.metaDiaria,
        'meta_ativa': config.metaAtiva,
        'ganho_atual': config.ganhoAtual,
        'configuracoes': config.configuracoes,
      } : null,
      'historico_corridas': corridas.map((c) => {
        'corrida_id': c.corridaId,
        'passageiro_nome': c.passageiroNome,
        'origem': c.origem,
        'destino': c.destino,
        'valor': c.valor,
        'distancia': c.distancia,
        'inicio_em': c.inicioEm.toIso8601String(),
        'fim_em': c.fimEm?.toIso8601String(),
        'status': c.status,
        'nota_passageiro': c.notaPassageiro,
        'comentario_passageiro': c.comentarioPassageiro,
      }).toList(),
      'localizacoes_salvas': localizacoes.map((l) => {
        'nome': l.nome,
        'endereco': l.endereco,
        'latitude': l.latitude,
        'longitude': l.longitude,
        'salvo_em': l.salvoEm.toIso8601String(),
        'tipo': l.tipo,
      }).toList(),
    };
  }

  /// Fecha todos os boxes
  Future<void> fecharBoxes() async {
    await _configBox?.close();
    await _corridasBox?.close();
    await _localizacoesBox?.close();
    await _cacheBox?.close();
  }

  /// Dispose dos recursos
  void dispose() {
    fecharBoxes();
  }
}