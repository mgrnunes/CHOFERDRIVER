import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meta_goals.dart';
import '../models/driver_stats.dart';

class MetaModeModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final MetaGoals? currentGoals;
  final Function(MetaGoals) onSaveGoals;
  final DriverCategory category;

  const MetaModeModal({
    Key? key,
    required this.visible,
    required this.onClose,
    this.currentGoals,
    required this.onSaveGoals,
    required this.category,
  }) : super(key: key);

  @override
  State<MetaModeModal> createState() => _MetaModeModalState();
}

class _MetaModeModalState extends State<MetaModeModal> {
  final _formKey = GlobalKey<FormState>();
  final _dailyEarningsController = TextEditingController();
  final _hourlyEarningsController = TextEditingController();
  final _kmEarningsController = TextEditingController();
  final _weeklyEarningsController = TextEditingController();
  final _monthlyEarningsController = TextEditingController();
  
  MetaPeriod _selectedPeriod = MetaPeriod.daily;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  void _loadCurrentGoals() {
    if (widget.currentGoals != null) {
      _dailyEarningsController.text = widget.currentGoals!.dailyEarningsGoal > 0
          ? widget.currentGoals!.dailyEarningsGoal.toStringAsFixed(2)
          : '';
      _hourlyEarningsController.text = widget.currentGoals!.hourlyEarningsGoal > 0
          ? widget.currentGoals!.hourlyEarningsGoal.toStringAsFixed(2)
          : '';
      _kmEarningsController.text = widget.currentGoals!.perKmEarningsGoal > 0
          ? widget.currentGoals!.perKmEarningsGoal.toStringAsFixed(2)
          : '';
      _weeklyEarningsController.text = widget.currentGoals!.weeklyEarningsGoal > 0
          ? widget.currentGoals!.weeklyEarningsGoal.toStringAsFixed(2)
          : '';
      _monthlyEarningsController.text = widget.currentGoals!.monthlyEarningsGoal > 0
          ? widget.currentGoals!.monthlyEarningsGoal.toStringAsFixed(2)
          : '';
      _selectedPeriod = widget.currentGoals!.activePeriod;
    }
  }

  @override
  void dispose() {
    _dailyEarningsController.dispose();
    _hourlyEarningsController.dispose();
    _kmEarningsController.dispose();
    _weeklyEarningsController.dispose();
    _monthlyEarningsController.dispose();
    super.dispose();
  }

  void _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final goals = MetaGoals(
        id: widget.currentGoals?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: 'current_driver', // Em produção viria do estado da aplicação
        dailyEarningsGoal: double.tryParse(_dailyEarningsController.text) ?? 0.0,
        hourlyEarningsGoal: double.tryParse(_hourlyEarningsController.text) ?? 0.0,
        perKmEarningsGoal: double.tryParse(_kmEarningsController.text) ?? 0.0,
        weeklyEarningsGoal: double.tryParse(_weeklyEarningsController.text) ?? 0.0,
        monthlyEarningsGoal: double.tryParse(_monthlyEarningsController.text) ?? 0.0,
        createdAt: widget.currentGoals?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        activePeriod: _selectedPeriod,
      );

      widget.onSaveGoals(goals);
      
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metas salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar metas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return Container();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildCategoryInfo(),
                        const SizedBox(height: 20),
                        _buildPeriodSelector(),
                        const SizedBox(height: 20),
                        _buildGoalFields(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.target,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'MODO META',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    String categoryName = widget.category == DriverCategory.master ? 'Master 🏆' : 'Elite';
    String bonus = widget.category == DriverCategory.master ? '+R\$1,00 por corrida' : '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Categoria: $categoryName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          if (bonus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bonus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Configure suas metas de ganhos baseadas em tempo, quilometragem e valor desejado.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período da Meta:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: MetaPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            String label;
            
            switch (period) {
              case MetaPeriod.daily:
                label = 'Diária';
                break;
              case MetaPeriod.weekly:
                label = 'Semanal';
                break;
              case MetaPeriod.monthly:
                label = 'Mensal';
                break;
            }
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalFields() {
    return Column(
      children: [
        _buildGoalField(
          controller: _dailyEarningsController,
          label: 'Meta Diária (R\$)',
          hint: 'Ex: 200.00',
          icon: Icons.today,
        ),
        const SizedBox(height: 16),
        _buildGoalField(
          controller: _hourlyEarningsController,
          label: 'Meta por Hora (R\$)',
          hint: 'Ex: 25.00',
          icon: Icons.schedule,
        ),
        const SizedBox(height: 16),
        _buildGoalField(
          controller: _kmEarningsController,
          label: 'Meta por KM (R\$)',
          hint: 'Ex: 2.50',
          icon: Icons.speed,
        ),
        if (_selectedPeriod == MetaPeriod.weekly) ...[
          const SizedBox(height: 16),
          _buildGoalField(
            controller: _weeklyEarningsController,
            label: 'Meta Semanal (R\$)',
            hint: 'Ex: 1400.00',
            icon: Icons.calendar_view_week,
          ),
        ],
        if (_selectedPeriod == MetaPeriod.monthly) ...[
          const SizedBox(height: 16),
          _buildGoalField(
            controller: _monthlyEarningsController,
            label: 'Meta Mensal (R\$)',
            hint: 'Ex: 6000.00',
            icon: Icons.calendar_month,
          ),
        ],
      ],
    );
  }

  Widget _buildGoalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
      ),
      validator: (value) {
        if (value?.isNotEmpty == true) {
          final number = double.tryParse(value!);
          if (number == null || number <= 0) {
            return 'Digite um valor válido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveGoals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Salvar Metas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar popup quando meta é atingida
class MetaAchievedDialog extends StatelessWidget {
  final MetaAchievementNotification notification;
  final VoidCallback onContinue;
  final VoidCallback onStop;

  const MetaAchievedDialog({
    Key? key,
    required this.notification,
    required this.onContinue,
    required this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de sucesso
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            const Text(
              'META ALCANÇADA!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Mensagem de parabéns
            Text(
              notification.congratulationsMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Informações da meta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Meta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        'R\${notification.goalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Alcançado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        'R\${notification.actualAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Pergunta sobre continuar
            Text(
              notification.continueMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Parar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}