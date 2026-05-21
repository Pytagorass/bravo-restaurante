import 'package:bravo_restaurante/models/reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservaViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? mensagemErro;

  List<Reserva> reservas = [];

  Future<void> carregarReservasAbertas() async {
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('reserva')
          .select('''
            id_reserva,
            id_hospede,
            id_quarto,
            status_reserva,
            hospede:id_hospede (
              nome_hospede
            ),
            quarto:id_quarto (
              numero_quarto
            )
          ''')
          .eq('status_reserva', 'Aberta')
          .order('created_at', ascending: false);

      reservas = response
          .map<Reserva>((item) => Reserva.fromMap(item))
          .toList();

      debugPrint('Reservas abertas carregadas: ${reservas.length}');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar reservas: $e');
      mensagemErro = 'Erro ao carregar reservas: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void limpar() {
    reservas = [];
    mensagemErro = null;
    notifyListeners();
  }
}
