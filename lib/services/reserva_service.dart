import 'package:bravo_restaurante/models/reserva.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Reserva>> carregarReservasAbertas() async {
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

    return response
        .map<Reserva>((item) => Reserva.fromMap(item))
        .where((reserva) => reserva.possuiContaAberta)
        .toList();
  }

}
