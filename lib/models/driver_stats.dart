import 'package:hive/hive.dart';

part 'driver_stats.g.dart';

@HiveType(typeId: 0)
class DriverStats extends HiveObject {
  @HiveField(0)
  final String driverId;

  @HiveField(1)
  final double rating;

  @HiveField(2)
  final int acceptancePercentage;

  @HiveField(3)
  final int cancellationPercentage;

  @HiveField(4)
  final int totalRides;

  @HiveField(5)
  final int acceptedRides;

  @HiveField(6)
  final int cancelledRides;

  @HiveField(7)
  final DateTime lastUpdated;

  @HiveField(8)
  final double totalEarnings;

  @HiveField(9)
  final double currentMonthEarnings;

  @HiveField(10)
  final int currentStreak;

  DriverStats({
    required this.driverId,
    required this.rating,
    required this.acceptancePercentage,
    required this.cancellationPercentage,
    required this.totalRides,
    required this.acceptedRides,
    required this.cancelledRides,
    required this.lastUpdated,
    this.totalEarnings = 0.0,
    this.currentMonthEarnings = 0.0,
    this.currentStreak = 0,
  });

  // Getters para determinar categoria baseado nas regras
  DriverCategory get category {
    if (rating >= 4.95 && acceptancePercentage >= 70 && cancellationPercentage <= 10) {
      return DriverCategory.master;
    } else if (rating >= 4.90 && acceptancePercentage >= 65 && cancellationPercentage <= 12) {
      return DriverCategory.elite;
    } else if (rating >= 4.80 && acceptancePercentage >= 60 && cancellationPercentage <= 15) {
      return DriverCategory.proDriver;
    } else {
      return DriverCategory.starter;
    }
  }

  // Getter para cor da barra de aceitação
  AcceptanceBarColor get acceptanceBarColor {
    if (acceptancePercentage < 40) return AcceptanceBarColor.red;
    if (acceptancePercentage < 50) return AcceptanceBarColor.yellow;
    return AcceptanceBarColor.green;
  }

  // Getter para cor da barra de cancelamento
  CancellationBarColor get cancellationBarColor {
    if (cancellationPercentage <= 5) return CancellationBarColor.green;
    if (cancellationPercentage <= 10) return CancellationBarColor.yellow;
    return CancellationBarColor.red;
  }

  // Verificar se pode acessar modo meta
  bool get canAccessMetaMode {
    return category == DriverCategory.elite || category == DriverCategory.master;
  }

  // Verificar se recebe bônus por corrida (apenas Master)
  bool get receivesRideBonus {
    return category == DriverCategory.master;
  }

  double get rideBonus {
    return receivesRideBonus ? 1.00 : 0.0;
  }

  // Método para atualizar estatísticas
  DriverStats copyWith({
    String? driverId,
    double? rating,
    int? acceptancePercentage,
    int? cancellationPercentage,
    int? totalRides,
    int? acceptedRides,
    int? cancelledRides,
    DateTime? lastUpdated,
    double? totalEarnings,
    double? currentMonthEarnings,
    int? currentStreak,
  }) {
    return DriverStats(
      driverId: driverId ?? this.driverId,
      rating: rating ?? this.rating,
      acceptancePercentage: acceptancePercentage ?? this.acceptancePercentage,
      cancellationPercentage: cancellationPercentage ?? this.cancellationPercentage,
      totalRides: totalRides ?? this.totalRides,
      acceptedRides: acceptedRides ?? this.acceptedRides,
      cancelledRides: cancelledRides ?? this.cancelledRides,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentMonthEarnings: currentMonthEarnings ?? this.currentMonthEarnings,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  // Método para calcular nova aceitação após aceitar/recusar corrida
  static int calculateNewAcceptance(int currentAcceptance, int totalRides, bool accepted) {
    if (totalRides == 0) return accepted ? 100 : 0;
    
    int acceptedRides = (currentAcceptance * totalRides / 100).round();
    if (accepted) acceptedRides++;
    
    return ((acceptedRides / (totalRides + 1)) * 100).round();
  }

  // Método para calcular novo cancelamento após cancelar corrida
  static int calculateNewCancellation(int currentCancellation, int totalRides, bool cancelled) {
    if (totalRides == 0) return cancelled ? 100 : 0;
    
    int cancelledRides = (currentCancellation * totalRides / 100).round();
    if (cancelled) cancelledRides++;
    
    return ((cancelledRides / (totalRides + 1)) * 100).round();
  }

  // Converter para JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'rating': rating,
      'acceptance_percentage': acceptancePercentage,
      'cancellation_percentage': cancellationPercentage,
      'total_rides': totalRides,
      'accepted_rides': acceptedRides,
      'cancelled_rides': cancelledRides,
      'last_updated': lastUpdated.toIso8601String(),
      'total_earnings': totalEarnings,
      'current_month_earnings': currentMonthEarnings,
      'current_streak': currentStreak,
    };
  }

  // Criar instância a partir do JSON
  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      driverId: json['driver_id'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      acceptancePercentage: json['acceptance_percentage'] ?? 0,
      cancellationPercentage: json['cancellation_percentage'] ?? 0,
      totalRides: json['total_rides'] ?? 0,
      acceptedRides: json['accepted_rides'] ?? 0,
      cancelledRides: json['cancelled_rides'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      currentMonthEarnings: (json['current_month_earnings'] ?? 0.0).toDouble(),
      currentStreak: json['current_streak'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'DriverStats(rating: $rating, acceptance: $acceptancePercentage%, cancellation: $cancellationPercentage%, category: ${category.name})';
  }
}

// Enums auxiliares
enum DriverCategory {
  starter,
  proDriver,
  elite,
  master,
}

enum AcceptanceBarColor {
  red,    // < 40%
  yellow, // 40-49%
  green,  // >= 50%
}

enum CancellationBarColor {
  green,  // 0-5%
  yellow, // 6-10%
  red,    // > 10%
}