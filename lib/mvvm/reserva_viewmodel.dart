import 'package:bravo_restaurante/models/reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservaViewModel extends ChangeNotifier {
  // Cliente Supabase usado para consultar reservas, hospedes, quartos e contas.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estados observados pelos dropdowns de reserva nas telas.
  bool isLoading = false;
  String? mensagemErro;

  // Reservas abertas que podem receber pedido, bebida ou fechamento de conta.
  List<Reserva> reservas = [];

  Future<void> carregarReservasAbertas() async {
    // Sinaliza carregamento antes de buscar dados no Supabase.
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      // Busca reservas abertas junto com dados relacionados de hospede, quarto e conta.
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
            ),
            conta_consumo (
              id_conta,
              status_conta
            )
          ''')
          .eq('status_reserva', 'Aberta')
          .order('created_at', ascending: false);

      // Mantem na lista apenas reservas que ainda possuem conta aberta.
      reservas = response
          .map<Reserva>((item) => Reserva.fromMap(item))
          .where((reserva) => reserva.possuiContaAberta)
          .toList();

      isLoading = false;
      notifyListeners();
      debugPrint(response.toString());
    } catch (e) {
      mensagemErro = 'Erro ao carregar reservas: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void limpar() {
    // Limpa a selecao/lista local quando a tela precisa reiniciar o estado.
    reservas = [];
    mensagemErro = null;
    notifyListeners();
  }
}
