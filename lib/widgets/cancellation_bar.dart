import 'package:flutter/material.dart';
import '../models/driver_stats.dart';

class CancellationBarWidget extends StatelessWidget {
  final int cancellationPercentage;
  final bool showLabel;
  final bool animated;

  const CancellationBarWidget({
    Key? key,
    required this.cancellationPercentage,
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
          'Taxa de Cancelamento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          '$cancellationPercentage%',
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
              flex: 100 - cancellationPercentage.clamp(0, 100),
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
      width: (cancellationPercentage.clamp(0, 100) / 100) * 
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
      flex: cancellationPercentage.clamp(0, 100),
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

  // Cores baseadas nas regras do guia:
  // 0% até 5%: verde
  // até 10%: amarelo  
  // acima disso: vermelho
  Color _getBarColor() {
    if (cancellationPercentage <= 5) return Colors.green;
    if (cancellationPercentage <= 10) return Colors.orange;
    return Colors.red;
  }

  List<Color> _getGradientColors() {
    if (cancellationPercentage <= 5) {
      return [Colors.green[300]!, Colors.green];
    }
    if (cancellationPercentage <= 10) {
      return [Colors.orange[300]!, Colors.orange];
    }
    return [Colors.red[300]!, Colors.red];
  }

  CancellationBarColor get barColor {
    if (cancellationPercentage <= 5) return CancellationBarColor.green;
    if (cancellationPercentage <= 10) return CancellationBarColor.yellow;
    return CancellationBarColor.red;
  }
}

// Widget com informações detalhadas
class DetailedCancellationBar extends StatelessWidget {
  final int cancellationPercentage;
  final int totalRides;
  final int cancelledRides;
  final bool showWarning;

  const DetailedCancellationBar({
    Key? key,
    required this.cancellationPercentage,
    required this.totalRides,
    required this.cancelledRides,
    this.showWarning = true,
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
                Icons.cancel,
                color: _getStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Taxa de Cancelamento',
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
          CancellationBarWidget(
            cancellationPercentage: cancellationPercentage,
            showLabel: false,
          ),
          
          const SizedBox(height: 12),
          
          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Canceladas',
                cancelledRides.toString(),
                Colors.red,
              ),
              _buildStatItem(
                'Completadas',
                (totalRides - cancelledRides).toString(),
                Colors.green,
              ),
              _buildStatItem(
                'Total',
                totalRides.toString(),
                Colors.grey[600]!,
              ),
            ],
          ),
          
          if (showWarning && cancellationPercentage > 10) ...[
            const SizedBox(height: 12),
            _buildWarningMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String status;
    Color color;
    
    if (cancellationPercentage <= 5) {
      status = 'EXCELENTE';
      color = Colors.green;
    } else if (cancellationPercentage <= 10) {
      status = 'ATENÇÃO';
      color = Colors.orange;
    } else {
      status = 'ALTA';
      color = Colors.red;
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

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Taxa de cancelamento alta pode afetar sua categoria e recebimento de corridas.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (cancellationPercentage <= 5) return Colors.green;
    if (cancellationPercentage <= 10) return Colors.orange;
    return Colors.red;
  }
}