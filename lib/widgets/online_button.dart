import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnlineButtonWidget extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;
  final bool enabled;

  const OnlineButtonWidget({
    Key? key,
    required this.isOnline,
    required this.onToggle,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<OnlineButtonWidget> createState() => _OnlineButtonWidgetState();
}

class _OnlineButtonWidgetState extends State<OnlineButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    _colorAnimation = ColorTween(
      begin: widget.isOnline ? Colors.green : Colors.grey,
      end: widget.isOnline ? Colors.green[700] : Colors.grey[700],
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(OnlineButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _updateColorAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPressed() {
    if (!widget.enabled) return;

    // Animação de press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Vibração para feedback
    HapticFeedback.mediumImpact();

    // Executar callback
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (widget.isOnline ? Colors.green : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onPressed,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isOnline
                    ? [Colors.green, Colors.green[700]!]
                    : [Colors.grey[400]!, Colors.grey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Indicador LED animado
                _buildLEDIndicator(),
                
                const SizedBox(width: 12),
                
                // Texto do status
                Text(
                  widget.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Ícone de power
                Icon(
                  widget.isOnline ? Icons.power_settings_new : Icons.power_off,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLEDIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isOnline ? Colors.white : Colors.grey[300],
        boxShadow: widget.isOnline
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: widget.isOnline
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

// Widget alternativo mais simples
class SimpleOnlineButton extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;
  final bool enabled;

  const SimpleOnlineButton({
    Key? key,
    required this.isOnline,
    required this.onToggle,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: enabled ? onToggle : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOnline ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnline ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}