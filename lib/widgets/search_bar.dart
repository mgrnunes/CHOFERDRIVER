import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final Function(String) onAddressSelected;

  const SearchBar({super.key, required this.onAddressSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar endereço...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
