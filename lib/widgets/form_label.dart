import 'package:bravo_restaurante/widgets/app_colors.dart';
import 'package:flutter/material.dart';

// Rotulo padrao usado antes dos campos de formulario do aplicativo.
class FormLabel extends StatelessWidget {
  final String texto;

  const FormLabel(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.cinzaEscuro,
      ),
    );
  }
}
