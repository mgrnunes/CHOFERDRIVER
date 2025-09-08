import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  String? _currentAddress;

  // Stream para ouvir mudanças de localização
  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  /// Verifica e solicita permissões de localização
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Redirecionar para configurações
      await openAppSettings();
      return false;
    }

    // Verificar se o GPS está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    return true;
  }

  /// Inicia o monitoramento da localização em tempo real
  Future<bool> startLocationTracking() async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) return false;

      // Configurações de precisão
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Atualizar a cada 5 metros
        timeLimit: Duration(seconds: 10),
      );

      // Iniciar stream de localização
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _locationController.add(position);
          _updateAddress(position);
        },
        onError: (error) {
          debugPrint('Erro de localização: $error');
        },
      );

      // Obter posição inicial
      _currentPosition = await Geolocator.getCurrentPosition();
      _locationController.add(_currentPosition!);
      await _updateAddress(_currentPosition!);

      return true;
    } catch (e) {
      debugPrint('Erro ao iniciar localização: $e');
      return false;
    }
  }

  /// Para o monitoramento da localização
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Atualiza o endereço baseado na posição
  Future<void> _updateAddress(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}';
      }
    } catch (e) {
      debugPrint('Erro ao obter endereço: $e');
    }
  }

  /// Calcula distância entre dois pontos
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Geocoding: converte endereço em coordenadas
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erro no geocoding: $e');
      return null;
    }
  }

  /// Reverse Geocoding: converte coordenadas em endereço
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
      return null;
    } catch (e) {
      debugPrint('Erro no reverse geocoding: $e');
      return null;
    }
  }

  /// Dispose dos recursos
  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}