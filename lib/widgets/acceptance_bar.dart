import 'package:flutter/material.dart';
import '../models/driver_stats.dart';

class AcceptanceBarWidget extends StatelessWidget {
  final int acceptancePercentage;
  final bool showLabel;
  final bool animated;

  const AcceptanceBarWidget({
    Key? key,
    required this.acceptancePercentage,
    this.showLabel = true,
    this.animated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) _buildLabel(),
          const SizedBox(height: 8),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Taxa de Aceitação',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          '$acceptancePercentage%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getBarColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            // Barra de progresso
            animated
                ? _buildAnimatedProgress()
                : _buildStaticProgress(),
            
            // Espaço restante
            Expanded(
              flex: 100 - acceptancePercentage.clamp(0, 100),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedProgress() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: (acceptancePercentage.clamp(0, 100) / 100) * 
             (MediaQueryData.fromView(WidgetsBinding.instance.window).size.width - 40),
      height: 8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildStaticProgress() {
    return Expanded(
      flex: acceptancePercentage.clamp(0, 100),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Color _getBarColor() {
    if (acceptancePercentage < 40) return Colors.red;
    if (acceptancePercentage < 50) return Colors.orange;
    return Colors.green;
  }

  List<Color> _getGradientColors() {
    if (acceptancePercentage < 40) {
      return [Colors.red[300]!, Colors.red];
    }
    if (acceptancePercentage < 50) {
      return [Colors.orange[300]!, Colors.orange];
    }
    return [Colors.green[300]!, Colors.green];
  }

  AcceptanceBarColor get barColor {
    if (acceptancePercentage < 40) return AcceptanceBarColor.red;
    if (acceptancePercentage < 50) return AcceptanceBarColor.yellow;
    return AcceptanceBarColor.green;
  }
}

// Widget com informações detalhadas
class DetailedAcceptanceBar extends StatelessWidget {
  final int acceptancePercentage;
  final int totalRides;
  final int acceptedRides;
  final bool showTrend;

  const DetailedAcceptanceBar({
    Key? key,
    required this.acceptancePercentage,
    required this.totalRides,
    required this.acceptedRides,
    this.showTrend = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: _getStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Taxa de Aceitação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barra de progresso
          AcceptanceBarWidget(
            acceptancePercentage: acceptancePercentage,
            showLabel: false,
          ),
          
          const SizedBox(height: 12),
          
          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Aceitas',
                acceptedRides.toString(),
                Colors.green,
              ),
              _buildStatItem(
                'Recusadas',
                (totalRides - acceptedRides).toString(),
                Colors.red,
              ),
              _buildStatItem(
                'Total',
                totalRides.toString(),
                Colors.grey[600]!,
              ),
            ],
          ),
          
          if (showTrend) ...[
            const SizedBox(height: 8),
            _buildTrendInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String status;
    Color color;
    
    if (acceptancePercentage < 40) {
      status = 'BAIXA';
      color = Colors.red;
    } else if (acceptancePercentage < 50) {
      status = 'MÉDIA';
      color = Colors.orange;
    } else {
      status = 'ALTA';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendInfo() {
    // Simulação de tendência - em produção viria de dados reais
    final isImproving = acceptancePercentage >= 50;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isImproving 
            ? Colors.green.withOpacity(0.1) 
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImproving ? Icons.trending_up : Icons.trending_flat,
            color: isImproving ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isImproving 
                ? 'Tendência positiva' 
                : 'Manter acima de 50%',
            style: TextStyle(
              color: isImproving ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (acceptancePercentage < 40) return Colors.red;
    if (acceptancePercentage < 50) return Colors.orange;
    return Colors.green;
  }
}