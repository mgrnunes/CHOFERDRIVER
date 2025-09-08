import 'package:flutter/material.dart';
import '../models/driver_stats.dart';
import '../models/category_model.dart';

class CategoryCardWidget extends StatelessWidget {
  final DriverStats driverStats;
  final VoidCallback? onMetaPress;
  final VoidCallback? onTap;

  const CategoryCardWidget({
    Key? key,
    required this.driverStats,
    this.onMetaPress,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryInfo = CategoryModel.fromCategory(driverStats.category);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryInfo.primaryColor.withOpacity(0.8),
            categoryInfo.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: categoryInfo.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(categoryInfo),
                const SizedBox(height: 16),
                _buildStats(categoryInfo),
                const SizedBox(height: 16),
                _buildBenefits(categoryInfo),
                if (driverStats.canAccessMetaMode) ...[
                  const SizedBox(height: 12),
                  _buildMetaButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryModel categoryInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  categoryInfo.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (categoryInfo.icon != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    categoryInfo.icon!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              categoryInfo.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '⭐ ${driverStats.rating.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(CategoryModel categoryInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Nota',
                  categoryInfo.requirements.ratingRange,
                  Icons.star,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Aceitação',
                  '${categoryInfo.requirements.minAcceptance}%+',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            'Cancelamento',
            'até ${categoryInfo.requirements.maxCancellation}%',
            Icons.cancel,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      alignment: fullWidth ? Alignment.center : null,
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(CategoryModel categoryInfo) {
    if (categoryInfo.benefits.bonusDescription.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryInfo.benefits.bonusDescription,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onMetaPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.target, size: 18),
        label: const Text(
          'MODO META',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Widget simplificado para espaços menores
class CompactCategoryCard extends StatelessWidget {
  final DriverStats driverStats;
  final VoidCallback? onTap;

  const CompactCategoryCard({
    Key? key,
    required this.driverStats,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryInfo = CategoryModel.fromCategory(driverStats.category);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryInfo.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: categoryInfo.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                // Ícone da categoria
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryInfo.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.person,
                    color: categoryInfo.primaryColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            categoryInfo.displayName,
                            style: TextStyle(
                              color: categoryInfo.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (categoryInfo.icon != null) ...[
                            const SizedBox(width: 4),
                            Text(categoryInfo.icon!, style: const TextStyle(fontSize: 16)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⭐ ${driverStats.rating.toStringAsFixed(2)} • ${driverStats.acceptancePercentage}% aceitação',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Seta
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget de progresso para próxima categoria
class CategoryProgressWidget extends StatelessWidget {
  final DriverStats currentStats;
  final bool showNextCategory;

  const CategoryProgressWidget({
    Key? key,
    required this.currentStats,
    this.showNextCategory = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentCategory = CategoryModel.fromCategory(currentStats.category);
    final nextCategory = currentCategory.nextCategory;
    
    if (!showNextCategory || nextCategory == null) {
      return Container();
    }

    final progress = currentCategory.calculateProgress(
      currentStats.rating,
      currentStats.acceptancePercentage,
      currentStats.cancellationPercentage,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: nextCategory.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Próxima categoria: ${nextCategory.displayName}',
                style: TextStyle(
                  color: nextCategory.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barra de progresso geral
          LinearProgressIndicator(
            value: progress.overallProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(nextCategory.primaryColor),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Progresso: ${(progress.overallProgress * 100).toInt()}%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          
          if (progress.improvementSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...progress.improvementSuggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_right,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}