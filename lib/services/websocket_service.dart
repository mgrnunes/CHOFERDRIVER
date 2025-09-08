import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// Modelo para uma corrida
class Corrida {
  final String id;
  final String passageiroNome;
  final String origem;
  final String destino;
  final double origemLat;
  final double origemLon;
  final double destinoLat;
  final double destinoLon;
  final double valor;
  final double distancia;
  final int tempoEstimado;
  final String? observacoes;
  final DateTime criadaEm;

  Corrida({
    required this.id,
    required this.passageiroNome,
    required this.origem,
    required this.destino,
    required this.origemLat,
    required this.origemLon,
    required this.destinoLat,
    required this.destinoLon,
    required this.valor,
    required this.distancia,
    required this.tempoEstimado,
    this.observacoes,
    required this.criadaEm,
  });

  factory Corrida.fromJson(Map<String, dynamic> json) {
    return Corrida(
      id: json['id'],
      passageiroNome: json['passageiro_nome'],
      origem: json['origem'],
      destino: json['destino'],
      origemLat: json['origem_lat'].toDouble(),
      origemLon: json['origem_lon'].toDouble(),
      destinoLat: json['destino_lat'].toDouble(),
      destinoLon: json['destino_lon'].toDouble(),
      valor: json['valor'].toDouble(),
      distancia: json['distancia'].toDouble(),
      tempoEstimado: json['tempo_estimado'],
      observacoes: json['observacoes'],
      criadaEm: DateTime.parse(json['criada_em']),
    );
  }
}

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  WebSocketService._();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _motoristaId;

  // Streams para diferentes eventos
  final _corridaController = StreamController<Corrida>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Getters para os streams
  Stream<Corrida> get corridaStream => _corridaController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;

  /// Conecta ao WebSocket do servidor
  Future<bool> connect(String motoristaId) async {
    try {
      _motoristaId = motoristaId;
      
      // URL do seu servidor WebSocket
      // Substitua pela URL real do seu backend
      final wsUrl = Uri.parse('wss://seu-servidor.com/ws/motorista/$motoristaId');
      
      _channel = WebSocketChannel.connect(wsUrl);
      
      // Escutar mensagens
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Enviar mensagem de autenticação
      await _authenticate();
      
      _isConnected = true;
      _statusController.add('connected');
      
      debugPrint('WebSocket conectado para motorista: $motoristaId');
      return true;
      
    } catch (e) {
      debugPrint('Erro ao conectar WebSocket: $e');
      _errorController.add('Erro de conexão: $e');
      return false;
    }
  }

  /// Autentica o motorista no WebSocket
  Future<void> _authenticate() async {
    final authMessage = {
      'type': 'auth',
      'motorista_id': _motoristaId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel?.sink.add(json.encode(authMessage));
  }

  /// Manipula mensagens recebidas
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message.toString());
      final messageType = data['type'];

      switch (messageType) {
        case 'nova_corrida':
          final corrida = Corrida.fromJson(data['corrida']);
          _corridaController.add(corrida);
          debugPrint('Nova corrida recebida: ${corrida.id}');
          break;
          
        case 'corrida_cancelada':
          _statusController.add('corrida_cancelada:${data['corrida_id']}');
          break;
          
        case 'ping':
          _sendPong();
          break;
          
        case 'status':
          _statusController.add(data['message']);
          break;
          
        default:
          debugPrint('Tipo de mensagem desconhecido: $messageType');
      }
    } catch (e) {
      debugPrint('Erro ao processar mensagem: $e');
      _errorController.add('Erro ao processar mensagem: $e');
    }
  }

  /// Responde ao ping do servidor
  void _sendPong() {
    final pongMessage = {
      'type': 'pong',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _channel?.sink.add(json.encode(pongMessage));
  }

  /// Manipula erros de conexão
  void _handleError(error) {
    debugPrint('Erro no WebSocket: $error');
    _errorController.add('Erro de WebSocket: $error');
    _isConnected = false;
  }

  /// Manipula desconexão
  void _handleDisconnection() {
    debugPrint('WebSocket desconectado');
    _isConnected = false;
    _statusController.add('disconnected');
    
    // Tentar reconectar após 5 segundos
    Timer(const Duration(seconds: 5), () {
      if (_motoristaId != null && !_isConnected) {
        reconnect();
      }
    });
  }

  /// Atualiza status do motorista (online/offline)
  void updateMotoristaStatus(bool isOnline, {double? lat, double? lon}) {
    if (!_isConnected || _channel == null) return;

    final statusMessage = {
      'type': 'update_status',
      'motorista_id': _motoristaId,
      'is_online': isOnline,
      'latitude': lat,
      'longitude': lon,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(statusMessage));
    debugPrint('Status atualizado: ${isOnline ? 'ONLINE' : 'OFFLINE'}');
  }

  /// Aceita uma corrida
  void aceitarCorrida(String corridaId) {
    if (!_isConnected || _channel == null) return;

    final aceitarMessage = {
      'type': 'aceitar_corrida',
      'motorista_id': _motoristaId,
      'corrida_id': corridaId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(aceitarMessage));
    debugPrint('Corrida aceita: $corridaId');
  }

  /// Rejeita uma corrida
  void rejeitarCorrida(String corridaId, String motivo) {
    if (!_isConnected || _channel == null) return;

    final rejeitarMessage = {
      'type': 'rejeitar_corrida',
      'motorista_id': _motoristaId,
      'corrida_id': corridaId,
      'motivo': motivo,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(rejeitarMessage));
    debugPrint('Corrida rejeitada: $corridaId');
  }

  /// Atualiza localização em tempo real
  void updateLocation(double latitude, double longitude) {
    if (!_isConnected || _channel == null) return;

    final locationMessage = {
      'type': 'location_update',
      'motorista_id': _motoristaId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(locationMessage));
  }

  /// Tenta reconectar
  Future<void> reconnect() async {
    if (_motoristaId != null) {
      debugPrint('Tentando reconectar WebSocket...');
      await connect(_motoristaId!);
    }
  }

  /// Desconecta do WebSocket
  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
    _motoristaId = null;
    _statusController.add('disconnected');
    debugPrint('WebSocket desconectado manualmente');
  }

  /// Limpa recursos
  void dispose() {
    disconnect();
    _corridaController.close();
    _statusController.close();
    _errorController.close();
  }
}