import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  Completer<GoogleMapController> _mapController = Completer();
  
  // Estado do motorista
  bool isOnline = false;
  bool _isLoadingLocation = true;
  
  // Localização
  Position? _currentPosition;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-23.5505, -46.6333), // São Paulo como padrão
    zoom: 15,
  );
  
  // Markers e polylines
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Dados do motorista (normalmente viriam do servidor/database)
  double nota = 4.85;
  double aceitacao = 65.0;
  double cancelamento = 8.0;
  String motoristaId = 'motorista_123'; // Seria obtido do login
  
  // Meta do motorista
  bool metaAtiva = false;
  double metaDiaria = 150.0;
  double ganhoAtual = 75.0;
  
  // Streams e subscriptions
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

  /// Inicializa todos os serviços necessários
  Future<void> _initializeServices() async {
    try {
      // Inicializar serviços
      await NotificationService.instance.initialize();
      await PersistenceService.instance.initialize();
      
      // Inicializar localização
      await _initializeLocation();
      
      // Conectar WebSocket
      await _connectWebSocket();
      
      // Configurar streams
      _setupStreams();
      
    } catch (e) {
      debugPrint('Erro ao inicializar serviços: $e');
      _showErrorDialog('Erro ao inicializar aplicativo: $e');
    }
  }

  /// Carrega configuração salva
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

  /// Inicializa localização e GPS
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
          _updateCameraPosition(_currentPosition!);
          _addCurrentLocationMarker();
        }
      }

      setState(() => _isLoadingLocation = false);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Erro ao inicializar localização: $e');
    }
  }

  /// Conecta ao WebSocket
  Future<void> _connectWebSocket() async {
    try {
      bool connected = await WebSocketService.instance.connect(motoristaId);
      if (connected) {
        debugPrint('WebSocket conectado com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao conectar WebSocket: $e');
    }
  }

  /// Configura os streams de localização e corridas
  void _setupStreams() {
    // Stream de localização
    _locationSubscription = LocationService.instance.locationStream.listen(
      (position) {
        setState(() => _currentPosition = position);
        _updateCameraPosition(position);
        _addCurrentLocationMarker();
        
        // Enviar localização via WebSocket se online
        if (isOnline) {
          WebSocketService.instance.updateLocation(
            position.latitude, 
            position.longitude,
          );
        }
      },
    );

    // Stream de corridas
    _corridaSubscription = WebSocketService.instance.corridaStream.listen(
      (corrida) {
        _mostrarNovaCorridaDialog(corrida);
      },
    );
  }

  /// Atualiza posição da câmera no mapa
  void _updateCameraPosition(Position position) async {
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  /// Adiciona marker da localização atual
  void _addCurrentLocationMarker() {
    if (_currentPosition == null) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Sua localização',
            snippet: LocationService.instance.currentAddress ?? 'Carregando...',
          ),
        ),
      );
    });
  }

  /// Toggle status online/offline
  void _toggleOnlineStatus() {
    setState(() => isOnline = !isOnline);
    
    // Atualizar no WebSocket
    if (_currentPosition != null) {
      WebSocketService.instance.updateMotoristaStatus(
        isOnline,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
      );
    }
    
    // Salvar configuração
    _saveConfiguration();
    
    // Mostrar notificação
    String message = isOnline ? 'Você está ONLINE e pode receber corridas' : 'Você está OFFLINE';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isOnline ? Colors.green : Colors.grey[700],
      ),
    );
  }

  /// Salva configuração atual
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

  /// Mostra diálogo de nova corrida
  void _mostrarNovaCorridaDialog(Corrida corrida) {
    // Adicionar marker da corrida
    _addCorridaMarkers(corrida);
    
    // Mostrar notificação
    NotificationService.instance.showCorridaNotification(
      title: 'Nova Corrida Disponível!',
      body: '${corrida.origem} → ${corrida.destino} - R\$ ${corrida.valor.toStringAsFixed(2)}',
    );

    // Mostrar diálogo
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
              child: Text(
                'Nova Corrida!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'R\$ ${corrida.valor.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCorridaInfo('Passageiro', corrida.passageiroNome),
            _buildCorridaInfo('Origem', corrida.origem),
            _buildCorridaInfo('Destino', corrida.destino),
            _buildCorridaInfo('Distância', '${corrida.distancia.toStringAsFixed(1)} km'),
            _buildCorridaInfo('Tempo est.', '${corrida.tempoEstimado} min'),
            if (corrida.observacoes != null)
              _buildCorridaInfo('Observações', corrida.observacoes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              WebSocketService.instance.rejeitarCorrida(
                corrida.id, 
                'Motorista rejeitou',
              );
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
    
    // Auto-rejeitar após 30 segundos
    Timer(const Duration(seconds: 30), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        _removeCorridaMarkers();
        WebSocketService.instance.rejeitarCorrida(
          corrida.id, 
          'Timeout - não respondeu',
        );
      }
    });
  }

  Widget _buildCorridaInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Adiciona markers da corrida no mapa
  void _addCorridaMarkers(Corrida corrida) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('origem_corrida'),
          position: LatLng(corrida.origemLat, corrida.origemLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Origem', snippet: corrida.origem),
        ),
      );
      
      _markers.add(
        Marker(
          markerId: const MarkerId('destino_corrida'),
          position: LatLng(corrida.destinoLat, corrida.destinoLon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destino', snippet: corrida.destino),
        ),
      );
    });
  }

  /// Remove markers da corrida
  void _removeCorridaMarkers() {
    setState(() {
      _markers.removeWhere((marker) => 
        marker.markerId.value == 'origem_corrida' ||
        marker.markerId.value == 'destino_corrida'
      );
    });
  }

  /// Aceita a corrida
  void _aceitarCorrida(Corrida corrida) {
    // Salvar corrida no histórico
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
    
    // Atualizar ganho se meta ativa
    if (metaAtiva) {
      setState(() {
        ganhoAtual += corrida.valor;
        if (ganhoAtual >= metaDiaria) {
          _mostrarMetaAlcancadaDialog();
        }
      });
      _saveConfiguration();
    }
    
    // Navegar para tela de corrida em andamento
    // Navigator.pushNamed(context, '/corrida_andamento', arguments: corrida);
  }

  /// Mostra diálogo de meta alcançada
  void _mostrarMetaAlcancadaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.gold),
            SizedBox(width: 10),
            Text('Meta Alcançada!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Parabéns! Você atingiu sua meta diária de R\$ ${metaDiaria.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Deseja continuar online para metas futuras?',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleOnlineStatus(); // Fica offline
            },
            child: const Text('Ficar Offline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Continuar Online', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo de permissões
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Permissões Necessárias', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Para funcionar corretamente, o app precisa acessar sua localização. '
          'Por favor, conceda as permissões nas configurações.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocationService.checkPermissions();
              _initializeLocation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Tentar Novamente', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Erro', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Getters para categorias e cores
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

  bool get podeUsarMeta {
    return categoria == 'Elite' || categoria == 'Master 🏆';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header com busca e eventos
            _buildHeader(),
            
            // Mapa principal
            _buildMap(),
            
            // Painel de controles
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
          // Barra de pesquisa
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _enderecoController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Para onde você quer ir?',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onSubmitted: _buscarEndereco,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Botão de eventos
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Google Maps
            _isLoadingLocation
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.orange),
                        const SizedBox(height: 20),
                        Text(
                          'Obtendo sua localização...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: _markers,
                    polylines: _polylines,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                  ),
            
            // Botão de download offline
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton.small(
                onPressed: _downloadMapaOffline,
                backgroundColor: Colors.white,
                child: const Icon(Icons.download, color: Colors.black),
              ),
            ),
            
            // Botão de centralizar
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
            // Botão Online/Offline
            _buildOnlineButton(),
            
            const SizedBox(height: 20),
            
            // Indicadores de desempenho
            _buildPerformanceIndicators(),
            
            const SizedBox(height: 15),
            
            // Categoria, nota e meta
            _buildStatusRow(),
            
            // Barra de meta (se ativa)
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? 'ONLINE - Recebendo corridas' : 'OFFLINE - Toque para ficar online',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Row(
      children: [
        // Barra de aceitação
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aceitação: ${aceitacao.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: aceitacao / 100,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(corAceitacao),
                minHeight: 8,
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Barra de cancelamento
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancelamento: ${cancelamento.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: cancelamento / 100,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(corCancelamento),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Categoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            categoria,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Nota
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.yellow, size: 16),
              const SizedBox(width: 4),
              Text(
                nota.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Botão Meta
        if (podeUsarMeta)
          ElevatedButton(
            onPressed: _configurarMeta,
            style: ElevatedButton.styleFrom(
              backgroundColor: metaAtiva ? Colors.green : Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              metaAtiva ? 'Meta ON' : 'Meta',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Meta Diária: R\$ ${metaDiaria.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ganhoAtual / metaDiaria,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 6,
          ),
          const SizedBox(height: 5),
          Text(
            'R\$ ${ganhoAtual.toStringAsFixed(2)} / R\$ ${metaDiaria.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  void _buscarEndereco(String endereco) async {
    if (endereco.isEmpty) return;
    
    try {
      final position = await LocationService.getCoordinatesFromAddress(endereco);
      if (position != null) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
        
        // Adicionar aos endereços recentes
        PersistenceService.instance.adicionarEnderecoRecente(
          endereco, 
          position.latitude, 
          position.longitude,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar endereço: $e')),
      );
    }
  }

  void _downloadMapaOffline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de mapa offline será implementada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _centralizarMapa() async {
    if (_currentPosition != null) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _mostrarEventos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eventos no Trajeto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _eventoItem(Icons.warning, 'Buraco na Av. Principal', Colors.red),
            _eventoItem(Icons.speed, 'Radar na Rua das Flores', Colors.orange),
            _eventoItem(Icons.water, 'Alagamento na Rua do Centro', Colors.blue),
            _eventoItem(Icons.local_police, 'Ponto de Apoio Policial - Praça Central', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _eventoItem(IconData icon, String descricao, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              descricao,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _configurarMeta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Configurar Meta',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Meta Diária (R\$)',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: metaDiaria.toStringAsFixed(0)),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  metaDiaria = double.tryParse(value) ?? metaDiaria;
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Bônus ${categoria == 'Master 🏆' ? '+R\$ 1,00 por corrida' : 'Destino disponível'}',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                metaAtiva = !metaAtiva;
              });
              _saveConfiguration();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              metaAtiva ? 'Desativar' : 'Ativar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }