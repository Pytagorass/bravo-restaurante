import 'package:bravo_restaurante/widgets/cores_app.dart';
import 'package:flutter/material.dart';

// Rotulo padrao usado antes dos campos de formulario do aplicativo.
class Formulario extends StatelessWidget {
  final String texto;

  const Formulario(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: CoresAPP.cinzaEscuro,
      ),
    );
  }
}
