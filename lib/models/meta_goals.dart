import 'package:hive/hive.dart';

part 'meta_goals.g.dart';

@HiveType(typeId: 4)
class MetaGoals extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final double dailyEarningsGoal;

  @HiveField(3)
  final double hourlyEarningsGoal;

  @HiveField(4)
  final double perKmEarningsGoal;

  @HiveField(5)
  final double weeklyEarningsGoal;

  @HiveField(6)
  final double monthlyEarningsGoal;

  @HiveField(7)
  final int dailyRidesGoal;

  @HiveField(8)
  final Duration dailyWorkTimeGoal;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final MetaPeriod activePeriod;

  MetaGoals({
    required this.id,
    required this.driverId,
    this.dailyEarningsGoal = 0.0,
    this.hourlyEarningsGoal = 0.0,
    this.perKmEarningsGoal = 0.0,
    this.weeklyEarningsGoal = 0.0,
    this.monthlyEarningsGoal = 0.0,
    this.dailyRidesGoal = 0,
    this.dailyWorkTimeGoal = const Duration(hours: 8),
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.activePeriod = MetaPeriod.daily,
  });

  // Método para criar cópia com alterações
  MetaGoals copyWith({
    String? id,
    String? driverId,
    double? dailyEarningsGoal,
    double? hourlyEarningsGoal,
    double? perKmEarningsGoal,
    double? weeklyEarningsGoal,
    double? monthlyEarningsGoal,
    int? dailyRidesGoal,
    Duration? dailyWorkTimeGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    MetaPeriod? activePeriod,
  }) {
    return MetaGoals(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      dailyEarningsGoal: dailyEarningsGoal ?? this.dailyEarningsGoal,
      hourlyEarningsGoal: hourlyEarningsGoal ?? this.hourlyEarningsGoal,
      perKmEarningsGoal: perKmEarningsGoal ?? this.perKmEarningsGoal,
      weeklyEarningsGoal: weeklyEarningsGoal ?? this.weeklyEarningsGoal,
      monthlyEarningsGoal: monthlyEarningsGoal ?? this.monthlyEarningsGoal,
      dailyRidesGoal: dailyRidesGoal ?? this.dailyRidesGoal,
      dailyWorkTimeGoal: dailyWorkTimeGoal ?? this.dailyWorkTimeGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      activePeriod: activePeriod ?? this.activePeriod,
    );
  }

  // Método para verificar se tem metas definidas
  bool get hasGoals {
    return dailyEarningsGoal > 0 ||
           hourlyEarningsGoal > 0 ||
           perKmEarningsGoal > 0 ||
           weeklyEarningsGoal > 0 ||
           monthlyEarningsGoal > 0 ||
           dailyRidesGoal > 0;
  }

  // Obter meta ativa baseada no período
  double get activeEarningsGoal {
    switch (activePeriod) {
      case MetaPeriod.daily:
        return dailyEarningsGoal;
      case MetaPeriod.weekly:
        return weeklyEarningsGoal;
      case MetaPeriod.monthly:
        return monthlyEarningsGoal;
    }
  }

  // Converter para JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'daily_earnings_goal': dailyEarningsGoal,
      'hourly_earnings_goal': hourlyEarningsGoal,
      'per_km_earnings_goal': perKmEarningsGoal,
      'weekly_earnings_goal': weeklyEarningsGoal,
      'monthly_earnings_goal': monthlyEarningsGoal,
      'daily_rides_goal': dailyRidesGoal,
      'daily_work_time_goal': dailyWorkTimeGoal.inMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'active_period': activePeriod.name,
    };
  }

  // Criar instância a partir do JSON
  factory MetaGoals.fromJson(Map<String, dynamic> json) {
    return MetaGoals(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      dailyEarningsGoal: (json['daily_earnings_goal'] ?? 0.0).toDouble(),
      hourlyEarningsGoal: (json['hourly_earnings_goal'] ?? 0.0).toDouble(),
      perKmEarningsGoal: (json['per_km_earnings_goal'] ?? 0.0).toDouble(),
      weeklyEarningsGoal: (json['weekly_earnings_goal'] ?? 0.0).toDouble(),
      monthlyEarningsGoal: (json['monthly_earnings_goal'] ?? 0.0).toDouble(),
      dailyRidesGoal: json['daily_rides_goal'] ?? 0,
      dailyWorkTimeGoal: Duration(minutes: json['daily_work_time_goal'] ?? 480),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
      activePeriod: MetaPeriod.values.firstWhere(
        (e) => e.name == json['active_period'],
        orElse: () => MetaPeriod.daily,
      ),
    );
  }

  @override
  String toString() {
    return 'MetaGoals(daily: R\${dailyEarningsGoal.toStringAsFixed(2)}, period: ${activePeriod.name})';
  }
}

// Classe para progresso das metas
@HiveType(typeId: 5)
class MetaProgress extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final double currentEarnings;

  @HiveField(4)
  final double currentKmEarnings;

  @HiveField(5)
  final int currentRides;

  @HiveField(6)
  final Duration currentWorkTime;

  @HiveField(7)
  final double totalKm;

  @HiveField(8)
  final MetaPeriod period;

  @HiveField(9)
  final bool goalAchieved;

  @HiveField(10)
  final DateTime? goalAchievedAt;

  MetaProgress({
    required this.id,
    required this.driverId,
    required this.date,
    this.currentEarnings = 0.0,
    this.currentKmEarnings = 0.0,
    this.currentRides = 0,
    this.currentWorkTime = Duration.zero,
    this.totalKm = 0.0,
    this.period = MetaPeriod.daily,
    this.goalAchieved = false,
    this.goalAchievedAt,
  });

  // Calcular progresso percentual baseado na meta
  double calculateProgressPercentage(MetaGoals goals) {
    double targetEarnings = goals.activeEarningsGoal;
    if (targetEarnings <= 0) return 0.0;
    
    return (currentEarnings / targetEarnings).clamp(0.0, 1.0);
  }

  // Calcular ganho por hora atual
  double get currentHourlyEarnings {
    if (currentWorkTime.inMinutes == 0) return 0.0;
    return currentEarnings / (currentWorkTime.inMinutes / 60.0);
  }

  // Calcular ganho por km atual
  double get currentPerKmEarnings {
    if (totalKm == 0) return 0.0;
    return currentEarnings / totalKm;
  }

  // Verificar se a meta foi atingida
  bool checkGoalAchieved(MetaGoals goals) {
    double targetEarnings = goals.activeEarningsGoal;
    return targetEarnings > 0 && currentEarnings >= targetEarnings;
  }

  // Calcular tempo restante para atingir meta (estimativa)
  Duration? estimateTimeToGoal(MetaGoals goals) {
    if (currentHourlyEarnings <= 0) return null;
    
    double targetEarnings = goals.activeEarningsGoal;
    double remainingEarnings = targetEarnings - currentEarnings;
    
    if (remainingEarnings <= 0) return Duration.zero;
    
    double hoursNeeded = remainingEarnings / currentHourlyEarnings;
    return Duration(minutes: (hoursNeeded * 60).round());
  }

  // Método para atualizar progresso
  MetaProgress updateProgress({
    double? additionalEarnings,
    int? additionalRides,
    Duration? additionalWorkTime,
    double? additionalKm,
  }) {
    return MetaProgress(
      id: id,
      driverId: driverId,
      date: date,
      currentEarnings: currentEarnings + (additionalEarnings ?? 0.0),
      currentKmEarnings: currentKmEarnings,
      currentRides: currentRides + (additionalRides ?? 0),
      currentWorkTime: currentWorkTime + (additionalWorkTime ?? Duration.zero),
      totalKm: totalKm + (additionalKm ?? 0.0),
      period: period,
      goalAchieved: goalAchieved,
      goalAchievedAt: goalAchievedAt,
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'date': date.toIso8601String(),
      'current_earnings': currentEarnings,
      'current_km_earnings': currentKmEarnings,
      'current_rides': currentRides,
      'current_work_time': currentWorkTime.inMinutes,
      'total_km': totalKm,
      'period': period.name,
      'goal_achieved': goalAchieved,
      'goal_achieved_at': goalAchievedAt?.toIso8601String(),
    };
  }

  // Criar instância a partir do JSON
  factory MetaProgress.fromJson(Map<String, dynamic> json) {
    return MetaProgress(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      currentEarnings: (json['current_earnings'] ?? 0.0).toDouble(),
      currentKmEarnings: (json['current_km_earnings'] ?? 0.0).toDouble(),
      currentRides: json['current_rides'] ?? 0,
      currentWorkTime: Duration(minutes: json['current_work_time'] ?? 0),
      totalKm: (json['total_km'] ?? 0.0).toDouble(),
      period: MetaPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => MetaPeriod.daily,
      ),
      goalAchieved: json['goal_achieved'] ?? false,
      goalAchievedAt: json['goal_achieved_at'] != null 
                      ? DateTime.parse(json['goal_achieved_at']) 
                      : null,
    );
  }

  @override
  String toString() {
    return 'MetaProgress(earnings: R\${currentEarnings.toStringAsFixed(2)}, rides: $currentRides)';
  }
}

// Classe para notificação de meta atingida
class MetaAchievementNotification {
  final MetaPeriod period;
  final double goalAmount;
  final double actualAmount;
  final DateTime achievedAt;
  final Duration timeTaken;
  final bool hasNextPeriodGoal;
  final MetaPeriod? nextPeriod;

  const MetaAchievementNotification({
    required this.period,
    required this.goalAmount,
    required this.actualAmount,
    required this.achievedAt,
    required this.timeTaken,
    this.hasNextPeriodGoal = false,
    this.nextPeriod,
  });

  // Mensagem de parabenização
  String get congratulationsMessage {
    String periodName = period == MetaPeriod.daily ? 'diária' :
                       period == MetaPeriod.weekly ? 'semanal' : 'mensal';
    
    return 'Parabéns! Você atingiu sua meta $periodName de R\${goalAmount.toStringAsFixed(2)}!';
  }

  // Mensagem sobre continuar
  String get continueMessage {
    if (!hasNextPeriodGoal) {
      return 'Quer continuar online para ganhar ainda mais?';
    }
    
    String nextPeriodName = nextPeriod == MetaPeriod.weekly ? 'semanal' : 'mensal';
    return 'Quer continuar online para sua meta $nextPeriodName?';
  }
}

// Enum para períodos de meta
@HiveType(typeId: 6)
enum MetaPeriod {
  @HiveField(0)
  daily,    // Diária
  
  @HiveField(1)
  weekly,   // Semanal
  
  @HiveField(2)
  monthly,  // Mensal
}