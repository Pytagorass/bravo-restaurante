import 'package:bravo_restaurante/widgets/app_colors.dart';
import 'package:flutter/material.dart';

// Controle reutilizavel para aumentar ou diminuir quantidades em formularios.
class QuantitySelector extends StatelessWidget {
  final int quantidade;
  final bool habilitado;
  final VoidCallback aoAumentar;
  final VoidCallback aoDiminuir;
  final int quantidadeMinima;

  const QuantitySelector({
    super.key,
    required this.quantidade,
    required this.habilitado,
    required this.aoAumentar,
    required this.aoDiminuir,
    this.quantidadeMinima = 1,
  });

  @override
  Widget build(BuildContext context) {
    final podeDiminuir = habilitado && quantidade > quantidadeMinima;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: habilitado ? Colors.white : Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: podeDiminuir ? aoDiminuir : null,
            icon: const Icon(Icons.remove),
            color: AppColors.verdeEscuro,
          ),
          Expanded(
            child: Center(
              child: Text(
                quantidade.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: habilitado ? AppColors.cinzaEscuro : Colors.grey,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: habilitado ? aoAumentar : null,
            icon: const Icon(Icons.add),
            color: AppColors.verdeEscuro,
          ),
        ],
      ),
    );
  }
}
