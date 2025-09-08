import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 1)
class EventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final EventType type;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final EventSeverity severity;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? expiresAt;

  @HiveField(8)
  final String? reportedBy;

  @HiveField(9)
  final int confirmations;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final Map<String, dynamic>? additionalData;

  EventModel({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.severity = EventSeverity.medium,
    required this.createdAt,
    this.expiresAt,
    this.reportedBy,
    this.confirmations = 1,
    this.isActive = true,
    this.additionalData,
  });

  // Getter para posição
  LatLng get position => LatLng(latitude, longitude);

  // Getter para verificar se o evento ainda é válido
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  // Getter para informações do tipo de evento
  EventTypeInfo get typeInfo => EventTypeInfo.fromType(type);

  // Método para criar cópia com alterações
  EventModel copyWith({
    String? id,
    EventType? type,
    double? latitude,
    double? longitude,
    String? description,
    EventSeverity? severity,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? reportedBy,
    int? confirmations,
    bool? isActive,
    Map<String, dynamic>? additionalData,
  }) {
    return EventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      reportedBy: reportedBy ?? this.reportedBy,
      confirmations: confirmations ?? this.confirmations,
      isActive: isActive ?? this.isActive,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Converter para JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'severity': severity.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'reported_by': reportedBy,
      'confirmations': confirmations,
      'is_active': isActive,
      'additional_data': additionalData,
    };
  }

  // Criar instância a partir do JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.other,
      ),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      severity: EventSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => EventSeverity.medium,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      reportedBy: json['reported_by'],
      confirmations: json['confirmations'] ?? 1,
      isActive: json['is_active'] ?? true,
      additionalData: json['additional_data'] != null 
                      ? Map<String, dynamic>.from(json['additional_data']) 
                      : null,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, type: ${type.name}, position: $position)';
  }
}

// Enum para tipos de eventos
@HiveType(typeId: 2)
enum EventType {
  @HiveField(0)
  pothole,          // Buraco na pista
  
  @HiveField(1)
  radar,            // Radar de velocidade
  
  @HiveField(2)
  flood,            // Alagamento
  
  @HiveField(3)
  policeSupport,    // Ponto de apoio policial
  
  @HiveField(4)
  accident,         // Acidente
  
  @HiveField(5)
  roadWork,         // Obras na via
  
  @HiveField(6)
  heavyTraffic,     // Trânsito pesado
  
  @HiveField(7)
  roadBlock,        // Bloqueio na via
  
  @HiveField(8)
  gasStation,       // Posto de combustível
  
  @HiveField(9)
  other,            // Outros eventos
}

// Enum para severidade dos eventos
@HiveType(typeId: 3)
enum EventSeverity {
  @HiveField(0)
  low,              // Baixa - informativo
  
  @HiveField(1)
  medium,           // Média - atenção
  
  @HiveField(2)
  high,             // Alta - cuidado
  
  @HiveField(3)
  critical,         // Crítica - evitar área
}

// Classe com informações sobre cada tipo de evento
class EventTypeInfo {
  final EventType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Duration defaultDuration;

  const EventTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.defaultDuration,
  });

  factory EventTypeInfo.fromType(EventType type) {
    switch (type) {
      case EventType.pothole:
        return const EventTypeInfo(
          type: EventType.pothole,
          name: 'Buraco',
          description: 'Buraco na pista',
          icon: Icons.warning,
          color: Colors.orange,
          defaultDuration: Duration(days: 30),
        );

      case EventType.radar:
        return const EventTypeInfo(
          type: EventType.radar,
          name: 'Radar',
          description: 'Radar de velocidade',
          icon: Icons.camera_alt,
          color: Colors.red,
          defaultDuration: Duration(days: 365), // Radar é permanente
        );

      case EventType.flood:
        return const EventTypeInfo(
          type: EventType.flood,
          name: 'Alagamento',
          description: 'Área alagada',
          icon: Icons.water,
          color: Colors.blue,
          defaultDuration: Duration(hours: 6),
        );

      case EventType.policeSupport:
        return const EventTypeInfo(
          type: EventType.policeSupport,
          name: 'Apoio Policial',
          description: 'Ponto de apoio policial',
          icon: Icons.local_police,
          color: Colors.green,
          defaultDuration: Duration(days: 365), // Permanente
        );

      case EventType.accident:
        return const EventTypeInfo(
          type: EventType.accident,
          name: 'Acidente',
          description: 'Acidente de trânsito',
          icon: Icons.car_crash,
          color: Colors.red,
          defaultDuration: Duration(hours: 2),
        );

      case EventType.roadWork:
        return const EventTypeInfo(
          type: EventType.roadWork,
          name: 'Obra',
          description: 'Obras na via',
          icon: Icons.construction,
          color: Colors.yellow,
          defaultDuration: Duration(days: 7),
        );

      case EventType.heavyTraffic:
        return const EventTypeInfo(
          type: EventType.heavyTraffic,
          name: 'Trânsito Intenso',
          description: 'Tráfego pesado',
          icon: Icons.traffic,
          color: Colors.red,
          defaultDuration: Duration(minutes: 30),
        );

      case EventType.roadBlock:
        return const EventTypeInfo(
          type: EventType.roadBlock,
          name: 'Bloqueio',
          description: 'Via bloqueada',
          icon: Icons.block,
          color: Colors.red,
          defaultDuration: Duration(hours: 4),
        );

      case EventType.gasStation:
        return const EventTypeInfo(
          type: EventType.gasStation,
          name: 'Posto',
          description: 'Posto de combustível',
          icon: Icons.local_gas_station,
          color: Colors.green,
          defaultDuration: Duration(days: 365), // Permanente
        );

      case EventType.other:
        return const EventTypeInfo(
          type: EventType.other,
          name: 'Outro',
          description: 'Outro evento',
          icon: Icons.info,
          color: Colors.grey,
          defaultDuration: Duration(hours: 1),
        );
    }
  }

  // Obter cor baseada na severidade
  Color getColorBySeverity(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.low:
        return color.withOpacity(0.6);
      case EventSeverity.medium:
        return color;
      case EventSeverity.high:
        return color.withRed(255);
      case EventSeverity.critical:
        return Colors.red;
    }
  }
}