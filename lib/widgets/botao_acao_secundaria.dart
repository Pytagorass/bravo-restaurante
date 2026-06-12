import 'package:bravo_restaurante/widgets/cores_app.dart';
import 'package:flutter/material.dart';

// Botao secundario padrao para acoes auxiliares, cancelamento ou comprovante.
class BotaoAcaoSecundaria extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color borderColor;
  final double height;
  final double borderRadius;

  const BotaoAcaoSecundaria({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor = CoresAPP.verdeEscuro,
    this.borderColor = CoresAPP.verdeEscuro,
    this.height = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
