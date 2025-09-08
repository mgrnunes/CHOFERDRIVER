import 'package:flutter/material.dart';

class CategoryModel {
  final DriverCategory category;
  final String name;
  final String displayName;
  final String description;
  final CategoryRequirements requirements;
  final CategoryBenefits benefits;
  final Color primaryColor;
  final Color backgroundColor;
  final String? icon;

  const CategoryModel({
    required this.category,
    required this.name,
    required this.displayName,
    required this.description,
    required this.requirements,
    required this.benefits,
    required this.primaryColor,
    required this.backgroundColor,
    this.icon,
  });

  // Factory para criar instâncias baseadas na categoria
  factory CategoryModel.fromCategory(DriverCategory category) {
    switch (category) {
      case DriverCategory.starter:
        return const CategoryModel(
          category: DriverCategory.starter,
          name: 'starter',
          displayName: 'Starter',
          description: 'Motorista iniciante, começando a construir histórico',
          requirements: CategoryRequirements(
            minRating: 4.70,
            maxRating: 4.79,
            minAcceptance: 50,
            maxCancellation: 20,
          ),
          benefits: CategoryBenefits(
            hasMetaMode: false,
            hasDestinationMode: false,
            rideBonus: 0.0,
            bonusDescription: '',
          ),
          primaryColor: Color(0xFF9E9E9E), // Cinza
          backgroundColor: Color(0xFFF5F5F5),
        );

      case DriverCategory.proDriver:
        return const CategoryModel(
          category: DriverCategory.proDriver,
          name: 'pro_driver',
          displayName: 'Pro Driver',
          description: 'Motorista regular, já demonstra consistência e qualidade',
          requirements: CategoryRequirements(
            minRating: 4.80,
            maxRating: 4.89,
            minAcceptance: 60,
            maxCancellation: 15,
          ),
          benefits: CategoryBenefits(
            hasMetaMode: false,
            hasDestinationMode: false,
            rideBonus: 0.0,
            bonusDescription: '',
          ),
          primaryColor: Color(0xFF2196F3), // Azul
          backgroundColor: Color(0xFFE3F2FD),
        );

      case DriverCategory.elite:
        return const CategoryModel(
          category: DriverCategory.elite,
          name: 'elite',
          displayName: 'Elite',
          description: 'Motorista de alto nível, quase no topo da plataforma',
          requirements: CategoryRequirements(
            minRating: 4.90,
            maxRating: 4.94,
            minAcceptance: 65,
            maxCancellation: 12,
          ),
          benefits: CategoryBenefits(
            hasMetaMode: true,
            hasDestinationMode: true,
            rideBonus: 0.0,
            bonusDescription: 'MODO META - DESTINO',
          ),
          primaryColor: Color(0xFF9C27B0), // Roxo
          backgroundColor: Color(0xFFF3E5F5),
        );

      case DriverCategory.master:
        return const CategoryModel(
          category: DriverCategory.master,
          name: 'master',
          displayName: 'Master',
          description: 'Motorista de excelência máxima',
          requirements: CategoryRequirements(
            minRating: 4.95,
            maxRating: 5.00,
            minAcceptance: 70,
            maxCancellation: 10,
          ),
          benefits: CategoryBenefits(
            hasMetaMode: true,
            hasDestinationMode: true,
            rideBonus: 1.00,
            bonusDescription: 'MODO META - DESTINO - +R\$1,00 POR CORRIDA',
          ),
          primaryColor: Color(0xFFFFD700), // Dourado
          backgroundColor: Color(0xFFFFF9C4),
          icon: '🏆',
        );
    }
  }

  // Método para verificar se o motorista atende aos requisitos
  bool meetsRequirements(double rating, int acceptance, int cancellation) {
    return rating >= requirements.minRating &&
           rating <= requirements.maxRating &&
           acceptance >= requirements.minAcceptance &&
           cancellation <= requirements.maxCancellation;
  }

  // Método para calcular progresso até a próxima categoria
  CategoryProgress calculateProgress(double currentRating, int currentAcceptance, int currentCancellation) {
    // Calcular o progresso baseado nos requisitos atuais
    double ratingProgress = ((currentRating - requirements.minRating) / 
                           (requirements.maxRating - requirements.minRating)).clamp(0.0, 1.0);
    
    double acceptanceProgress = (currentAcceptance / requirements.minAcceptance).clamp(0.0, 1.0);
    
    double cancellationProgress = currentCancellation <= requirements.maxCancellation 
                                 ? 1.0 
                                 : (requirements.maxCancellation / currentCancellation).clamp(0.0, 1.0);

    double overallProgress = (ratingProgress + acceptanceProgress + cancellationProgress) / 3;

    return CategoryProgress(
      ratingProgress: ratingProgress,
      acceptanceProgress: acceptanceProgress,
      cancellationProgress: cancellationProgress,
      overallProgress: overallProgress,
      isEligible: meetsRequirements(currentRating, currentAcceptance, currentCancellation),
    );
  }

  // Obter próxima categoria
  CategoryModel? get nextCategory {
    switch (category) {
      case DriverCategory.starter:
        return CategoryModel.fromCategory(DriverCategory.proDriver);
      case DriverCategory.proDriver:
        return CategoryModel.fromCategory(DriverCategory.elite);
      case DriverCategory.elite:
        return CategoryModel.fromCategory(DriverCategory.master);
      case DriverCategory.master:
        return null; // Já é a categoria máxima
    }
  }

  // Obter categoria anterior
  CategoryModel? get previousCategory {
    switch (category) {
      case DriverCategory.starter:
        return null; // Já é a categoria mínima
      case DriverCategory.proDriver:
        return CategoryModel.fromCategory(DriverCategory.starter);
      case DriverCategory.elite:
        return CategoryModel.fromCategory(DriverCategory.proDriver);
      case DriverCategory.master:
        return CategoryModel.fromCategory(DriverCategory.elite);
    }
  }

  @override
  String toString() {
    return 'CategoryModel(name: $displayName, rating: ${requirements.minRating}-${requirements.maxRating})';
  }
}

// Classe para os requisitos da categoria
class CategoryRequirements {
  final double minRating;
  final double maxRating;
  final int minAcceptance;
  final int maxCancellation;

  const CategoryRequirements({
    required this.minRating,
    required this.maxRating,
    required this.minAcceptance,
    required this.maxCancellation,
  });

  // Converter para texto legível
  String get ratingRange => '${minRating.toStringAsFixed(2)} a ${maxRating.toStringAsFixed(2)}';
  String get acceptanceText => 'mínimo ${minAcceptance}%';
  String get cancellationText => 'até ${maxCancellation}%';
}

// Classe para os benefícios da categoria
class CategoryBenefits {
  final bool hasMetaMode;
  final bool hasDestinationMode;
  final double rideBonus;
  final String bonusDescription;

  const CategoryBenefits({
    required this.hasMetaMode,
    required this.hasDestinationMode,
    required this.rideBonus,
    required this.bonusDescription,
  });

  List<String> get benefitsList {
    List<String> benefits = [];
    if (hasMetaMode) benefits.add('Modo Meta');
    if (hasDestinationMode) benefits.add('Modo Destino');
    if (rideBonus > 0) benefits.add('Bônus de R\$${rideBonus.toStringAsFixed(2)} por corrida');
    return benefits;
  }
}

// Classe para o progresso em direção à próxima categoria
class CategoryProgress {
  final double ratingProgress;
  final double acceptanceProgress;
  final double cancellationProgress;
  final double overallProgress;
  final bool isEligible;

  const CategoryProgress({
    required this.ratingProgress,
    required this.acceptanceProgress,
    required this.cancellationProgress,
    required this.overallProgress,
    required this.isEligible,
  });

  // Feedback sobre o que precisa melhorar
  List<String> get improvementSuggestions {
    List<String> suggestions = [];
    
    if (ratingProgress < 1.0) {
      suggestions.add('Melhore sua avaliação');
    }
    if (acceptanceProgress < 1.0) {
      suggestions.add('Aumente sua taxa de aceitação');
    }
    if (cancellationProgress < 1.0) {
      suggestions.add('Reduza sua taxa de cancelamento');
    }
    
    return suggestions;
  }
}

// Enum para as categorias (importado do driver_stats.dart)
enum DriverCategory {
  starter,
  proDriver,
  elite,
  master,
}