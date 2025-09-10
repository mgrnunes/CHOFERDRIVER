import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({Key? key}) : super(key: key);

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // Controllers
  final TextEditingController _enderecoController = TextEditingController();
  final MapController _mapController = MapController();

  // Estado do motorista
  bool isOnline = false;
  bool _isLoadingLocation = true;

  // Localização
  Position? _currentPosition;
  LatLng _initialPosition = const LatLng(-23.5505, -46.6333); // São Paulo padrão

  // Markers e polylines
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  // Dados do motorista
  double nota = 4.85;
  double aceitacao = 65.0;
  double cancelamento = 8.0;
  String motoristaId = 'motorista_123';

  // Meta do motorista
  bool metaAtiva = false;
  double metaDiaria = 150.0;
  double ganhoAtual = 75.0;

  // Streams
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Corrida>? _corridaSubscription;

  // Corrida atual
  Corrida? _corridaDisponivel;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSavedConfiguration();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _corridaSubscription?.cancel();
    LocationService.instance.dispose();
    WebSocketService.instance.dispose();
    super.dispose();
  }

  /// Inicializa serviços
  Future<void> _initializeServices() async {
    try {
      await NotificationService.instance.initialize();
      await PersistenceService.instance.initialize();
      await _initializeLocation();
      await _connectWebSocket();
      _setupStreams();
    } catch (e) {
      debugPrint('Erro ao inicializar: $e');
      _showErrorDialog('Erro ao inicializar aplicativo: $e');
    }
  }

  void _loadSavedConfiguration() {
    final config = PersistenceService.instance.obterConfiguracao(motoristaId);
    if (config != null) {
      setState(() {
        isOnline = config.isOnline;
        metaAtiva = config.metaAtiva;
        metaDiaria = config.metaDiaria;
        ganhoAtual = config.ganhoAtual;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool hasPermission = await LocationService.checkPermissions();
      if (!hasPermission) {
        _showPermissionDialog();
        return;
      }

      bool started = await LocationService.instance.startLocationTracking();
      if (started) {
        _currentPosition = LocationService.instance.currentPosition;
        if (_currentPosition != null) {
          _initialPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
          _addCurrentLocationMarker();
        }
      }

      setState(() => _isLoadingLocation = false);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Erro ao inicializar localização: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      bool connected = await WebSocketService.instance.connect(motoristaId);
      if (connected) debugPrint('WebSocket conectado');
    } catch (e) {
      debugPrint('Erro ao conectar WebSocket: $e');
    }
  }

  void _setupStreams() {
    _locationSubscription = LocationService.instance.locationStream.listen((position) {
      setState(() => _currentPosition = position);
      _mapController.move(LatLng(position.latitude, position.longitude), _mapController.camera.zoom);
      _addCurrentLocationMarker();
      if (isOnline) {
        WebSocketService.instance.updateLocation(position.latitude, position.longitude);
      }
    });

    _corridaSubscription = WebSocketService.instance.corridaStream.listen((corrida) {
      _mostrarNovaCorridaDialog(corrida);
    });
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition == null) return;
    setState(() {
      _markers.removeWhere((m) => m.key == const ValueKey('current_location'));
      _markers.add(
        Marker(
          key: const ValueKey('current_location'),
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          builder: (ctx) => const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    });
  }

  void _toggleOnlineStatus() {
    setState(() => isOnline = !isOnline);
    if (_currentPosition != null) {
      WebSocketService.instance.updateMotoristaStatus(
        isOnline,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
      );
    }
    _saveConfiguration();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isOnline ? 'Você está ONLINE' : 'Você está OFFLINE'),
      backgroundColor: isOnline ? Colors.green : Colors.grey[700],
    ));
  }

  void _saveConfiguration() {
    final config = ConfiguracaoMotorista(
      motoristaId: motoristaId,
      isOnline: isOnline,
      metaDiaria: metaDiaria,
      metaAtiva: metaAtiva,
      ganhoAtual: ganhoAtual,
      ultimaAtualizacao: DateTime.now(),
    );
    PersistenceService.instance.salvarConfiguracao(config);
  }

  // ----- Diálogos e métodos de corrida iguais -----

  void _mostrarNovaCorridaDialog(Corrida corrida) {
    _addCorridaMarkers(corrida);
    NotificationService.instance.showCorridaNotification(
      title: 'Nova Corrida Disponível!',
      body: '${corrida.origem} → ${corrida.destino} - R\$ ${corrida.valor.toStringAsFixed(2)}',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.orange),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Nova Corrida!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
              child: Text('R\$ ${corrida.valor.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCorridaInfo('Passageiro', corrida.passageiroNome),
            _buildCorridaInfo('Origem', corrida.origem),
            _buildCorridaInfo('Destino', corrida.destino),
            _buildCorridaInfo('Distância', '${corrida.distancia.toStringAsFixed(1)} km'),
            _buildCorridaInfo('Tempo est.', '${corrida.tempoEstimado} min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              WebSocketService.instance.rejeitarCorrida(corrida.id, 'Motorista rejeitou');
              Navigator.pop(context);
              _removeCorridaMarkers();
            },
            child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              WebSocketService.instance.aceitarCorrida(corrida.id);
              Navigator.pop(context);
              _aceitarCorrida(corrida);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridaInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _addCorridaMarkers(Corrida corrida) {
    setState(() {
      _markers.add(
        Marker(
          key: ValueKey('origem_corrida'),
          point: LatLng(corrida.origemLat, corrida.origemLon),
          width: 40,
          height: 40,
          builder: (ctx) => const Icon(Icons.location_on, color: Colors.green),
        ),
      );
      _markers.add(
        Marker(
          key: ValueKey('destino_corrida'),
          point: LatLng(corrida.destinoLat, corrida.destinoLon),
          width: 40,
          height: 40,
          builder: (ctx) => const Icon(Icons.location_on, color: Colors.red),
        ),
      );
    });
  }

  void _removeCorridaMarkers() {
    setState(() {
      _markers.removeWhere((m) => m.key == const ValueKey('origem_corrida') || m.key == const ValueKey('destino_corrida'));
    });
  }

  void _aceitarCorrida(Corrida corrida) {
    final historico = HistoricoCorrida(
      corridaId: corrida.id,
      passageiroNome: corrida.passageiroNome,
      origem: corrida.origem,
      destino: corrida.destino,
      valor: corrida.valor,
      distancia: corrida.distancia,
      inicioEm: DateTime.now(),
      status: 'aceita',
    );
    PersistenceService.instance.salvarCorrida(historico);
    if (metaAtiva) {
      setState(() {
        ganhoAtual += corrida.valor;
        if (ganhoAtual >= metaDiaria) _mostrarMetaAlcancadaDialog();
      });
      _saveConfiguration();
    }
  }

  void _mostrarMetaAlcancadaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Meta Alcançada!', style: TextStyle(color: Colors.white)),
        content: Text('Você atingiu R\$ ${metaDiaria.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _toggleOnlineStatus(); }, child: const Text('Ficar Offline', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Continuar Online')),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Permissões Necessárias', style: TextStyle(color: Colors.white)),
        content: const Text('Conceda permissões de localização.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () async { Navigator.pop(context); await LocationService.checkPermissions(); _initializeLocation(); }, child: const Text('Tentar Novamente')),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Erro', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  String get categoria {
    if (nota >= 4.95) return 'Master 🏆';
    if (nota >= 4.90) return 'Elite';
    if (nota >= 4.80) return 'Pro Driver';
    return 'Starter';
  }

  Color get corAceitacao {
    if (aceitacao >= 50) return Colors.green;
    if (aceitacao >= 40) return Colors.orange;
    return Colors.red;
  }

  Color get corCancelamento {
    if (cancelamento <= 5) return Colors.green;
    if (cancelamento <= 10) return Colors.orange;
    return Colors.red;
  }

  bool get podeUsarMeta => categoria == 'Elite' || categoria == 'Master 🏆';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMap(),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: TextField(
              controller: _enderecoController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Para onde você quer ir?',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onSubmitted: _buscarEndereco,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _mostrarEventos,
                icon: const Icon(Icons.warning, size: 18),
                label: const Text('Eventos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            _isLoadingLocation
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(center: _initialPosition, zoom: 15.0),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.chofer_motorista_clean',
                      ),
                      MarkerLayer(markers: _markers),
                      PolylineLayer(polylines: _polylines),
                    ],
                  ),
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton.small(
                onPressed: _downloadMapaOffline,
                backgroundColor: Colors.white,
                child: const Icon(Icons.download, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton.small(
                onPressed: _centralizarMapa,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOnlineButton(),
            const SizedBox(height: 20),
            _buildPerformanceIndicators(),
            const SizedBox(height: 15),
            _buildStatusRow(),
            if (metaAtiva) ...[
              const SizedBox(height: 15),
              _buildMetaProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _toggleOnlineStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOnline ? Colors.green : Colors.grey[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOnline ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(isOnline ? 'ONLINE - Recebendo corridas' : 'OFFLINE - Toque para ficar online',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aceitação: ${aceitacao.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: aceitacao / 100,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(corAceitacao),
              minHeight: 8,
            ),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cancelamento: ${cancelamento.toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: cancelamento / 100,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(corCancelamento),
              minHeight: 8,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
          child: Text(categoria, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 16),
              const SizedBox(width: 4),
              Text(nota.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (podeUsarMeta)
          ElevatedButton(
            onPressed: _configurarMeta,
            style: ElevatedButton.styleFrom(
              backgroundColor: metaAtiva ? Colors.green : Colors.grey[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(metaAtiva ? 'Meta ON' : 'Meta',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildMetaProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text('Meta Diária: R\$ ${metaDiaria.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ganhoAtual / metaDiaria,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 6,
          ),
          const SizedBox(height: 5),
          Text('R\$ ${ganhoAtual.toStringAsFixed(2)} / R\$ ${metaDiaria.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  void _buscarEndereco(String endereco) async {
    if (endereco.isEmpty) return;
    try {
      final position = await LocationService.getCoordinatesFromAddress(endereco);
      if (position != null) {
        _mapController.move(LatLng(position.latitude, position.longitude), _mapController.camera.zoom);
        PersistenceService.instance.adicionarEnderecoRecente(endereco, position.latitude, position.longitude);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar endereço: $e')));
    }
  }

  void _downloadMapaOffline() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Funcionalidade de mapa offline será implementada'),
      backgroundColor: Colors.orange,
    ));
  }

  void _centralizarMapa() {
    if (_currentPosition != null) {
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), _mapController.camera.zoom);
    }
  }

  void _mostrarEventos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Eventos no Trajeto',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _eventoItem(Icons.warning, 'Buraco na Av. Principal', Colors.red),
            _eventoItem(Icons.speed, 'Radar na Rua das Flores', Colors.orange),
            _eventoItem(Icons.water, 'Alagamento na Rua do Centro', Colors.blue),
            _eventoItem(Icons.local_police, 'Ponto Policial - Praça Central', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _eventoItem(IconData icon, String descricao, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: cor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(descricao, style: const TextStyle(color: Colors.white))),
      ]),
    );
  }

  void _configurarMeta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Configurar Meta', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Meta Diária (R\$)',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: metaDiaria.toStringAsFixed(0)),
              onChanged: (value) {
                if (value.isNotEmpty) metaDiaria = double.tryParse(value) ?? metaDiaria;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Bônus ${categoria == 'Master 🏆' ? '+R\$ 1,00 por corrida' : 'Destino disponível'}',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                metaAtiva = !metaAtiva;
              });
              _saveConfiguration();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(metaAtiva ? 'Desativar' : 'Ativar', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
