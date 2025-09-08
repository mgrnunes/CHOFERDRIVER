import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onAddressSelected;
  final String? hintText;
  final bool enabled;

  const SearchBarWidget({
    Key? key,
    required this.onAddressSelected,
    this.hintText = 'Buscar endereço...',
    this.enabled = true,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  // Sugestões rápidas baseadas no Rio de Janeiro
  final List<String> _quickSuggestions = [
    'Copacabana, Rio de Janeiro',
    'Ipanema, Rio de Janeiro', 
    'Centro, Rio de Janeiro',
    'Barra da Tijuca, Rio de Janeiro',
    'Tijuca, Rio de Janeiro',
    'Botafogo, Rio de Janeiro',
    'Flamengo, Rio de Janeiro',
    'Leblon, Rio de Janeiro',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (value.length < 2) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    // Filtrar sugestões baseadas no texto
    final filtered = _quickSuggestions
        .where((address) => 
            address.toLowerCase().contains(value.toLowerCase()))
        .take(4)
        .toList();

    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _onSuggestionTapped(String suggestion) {
    _controller.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    
    widget.onAddressSelected(suggestion);
    _focusNode.unfocus();
    HapticFeedback.selectionClick();
  }

  void _onSubmitted(String value) {
    if (value.trim().isEmpty) return;
    
    setState(() {
      _showSuggestions = false;
    });
    
    widget.onAddressSelected(value.trim());
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de busca principal (mantendo estrutura original)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            onChanged: _onTextChanged,
            onSubmitted: _onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),

        // Lista de sugestões (nova funcionalidade)
        if (_showSuggestions) _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.location_on,
              color: Colors.grey[600],
              size: 20,
            ),
            title: Text(
              suggestion,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _onSuggestionTapped(suggestion),
          );
        },
      ),
    );
  }
}

// Versão simplificada que mantém exatamente sua estrutura original
// Use esta se quiser manter 100% compatível com o código existente
class SimpleSearchBar extends StatelessWidget {
  final Function(String) onAddressSelected;
  
  const SimpleSearchBar({
    Key? key, 
    required this.onAddressSelected
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar endereço...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8)
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            onAddressSelected(value);
          }
        },
      ),
    );
  }
}