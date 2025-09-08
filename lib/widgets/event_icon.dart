import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventIconWidget extends StatelessWidget {
  final EventModel event;
  final double size;
  final VoidCallback? onTap;
  final bool showPulse;

  const EventIconWidget({
    Key? key,
    required this.event,
    this.size = 32,
    this.onTap,
    this.showPulse = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!event.isValid) {
      return Container(); // Não mostra eventos expirados
    }

    return GestureDetector(
      onTap: onTap,
      child: showPulse && _shouldPulse()
          ? _buildPulsingIcon()
          : _buildStaticIcon(),
    );
  }

  Widget _buildStaticIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: event.typeInfo.getColorBySeverity(event.severity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: event.typeInfo.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        event.typeInfo.icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.8, end: 1.2),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: _buildStaticIcon(),
        );
      },
      onEnd: () {
        // Reinicia a animação se o widget ainda estiver montado
        if (mounted) {
          // Trigger rebuild para reiniciar animação
        }
      },
    );
  }

  bool _shouldPulse() {
    // Eventos críticos ou recentes devem piscar
    return event.severity == EventSeverity.critical ||
           event.severity == EventSeverity.high ||
           DateTime.now().difference(event.createdAt).inMinutes < 30;
  }

  bool get mounted => true; // Placeholder - em widget real seria gerenciado pelo framework
}

// Widget para mostrar eventos em lista
class EventListItem extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool showDistance;
  final double? distanceKm;

  const EventListItem({
    Key? key,
    required this.event,
    this.onTap,
    this.showDistance = false,
    this.distanceKm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: EventIconWidget(
        event: event,
        size: 40,
        showPulse: false,
      ),
      title: Text(
        event.typeInfo.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.description),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildSeverityChip(),
              if (showDistance && distanceKm != null) ...[
                const SizedBox(width: 8),
                _buildDistanceChip(),
              ],
              const SizedBox(width: 8),
              _buildTimeChip(),
            ],
          ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSeverityChip() {
    String severityText;
    Color severityColor;

    switch (event.severity) {
      case EventSeverity.low:
        severityText = 'Baixa';
        severityColor = Colors.green;
        break;
      case EventSeverity.medium:
        severityText = 'Média';
        severityColor = Colors.orange;
        break;
      case EventSeverity.high:
        severityText = 'Alta';
        severityColor = Colors.red;
        break;
      case EventSeverity.critical:
        severityText = 'Crítica';
        severityColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Text(
        severityText,
        style: TextStyle(
          color: severityColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDistanceChip() {
    if (distanceKm == null) return Container();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${distanceKm!.toStringAsFixed(1)} km',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeChip() {
    final timeAgo = DateTime.now().difference(event.createdAt);
    String timeText;

    if (timeAgo.inMinutes < 1) {
      timeText = 'Agora';
    } else if (timeAgo.inHours < 1) {
      timeText = '${timeAgo.inMinutes}min';
    } else if (timeAgo.inDays < 1) {
      timeText = '${timeAgo.inHours}h';
    } else {
      timeText = '${timeAgo.inDays}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Widget para botão de placa de trânsito (eventos)
class TrafficSignButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int eventCount;

  const TrafficSignButton({
    Key? key,
    required this.onPressed,
    this.eventCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(25),
              child: const Icon(
                Icons.traffic,
                color: Colors.orange,
                size: 28,
              ),
            ),
          ),
        ),
        
        // Badge com contador de eventos
        if (eventCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                eventCount > 99 ? '99+' : eventCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Widget para seletor de tipo de evento (para reportar novos eventos)
class EventTypeSelector extends StatelessWidget {
  final EventType? selectedType;
  final Function(EventType) onTypeSelected;

  const EventTypeSelector({
    Key? key,
    this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de evento:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventType.values.map((type) {
              final typeInfo = EventTypeInfo.fromType(type);
              final isSelected = selectedType == type;
              
              return GestureDetector(
                onTap: () => onTypeSelected(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? typeInfo.color.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? typeInfo.color
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        typeInfo.icon,
                        color: isSelected
                            ? typeInfo.color
                            : Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeInfo.name,
                        style: TextStyle(
                          color: isSelected
                              ? typeInfo.color
                              : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}