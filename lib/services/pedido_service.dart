import 'package:bravo_restaurante/models/item_pedido_temporario.dart';
import 'package:bravo_restaurante/models/pedido.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> gravarContaConsumo({
    required Reserva reserva,
    required List<ItemPedidoTemporario> itens,
    required double total,
    required String idUsuario,
    String? observacao,
  }) async {
    final contaExistente = await _supabase
        .from('conta_consumo')
        .select('id_conta')
        .eq('id_reserva', reserva.idReserva)
        .maybeSingle();

    final String idConta;

    if (contaExistente == null) {
      final novaConta = await _supabase
          .from('conta_consumo')
          .insert({
            'id_reserva': reserva.idReserva,
            'total_acumulado': 0,
            'status_conta': 'Aberta',
          })
          .select('id_conta')
          .single();

      idConta = novaConta['id_conta'] as String;
    } else {
      idConta = contaExistente['id_conta'] as String;
    }

    final novoPedido = Pedido(
      idPedido: '',
      idConta: idConta,
      idUsuario: idUsuario,
      statusPedido: 'Aberto',
      observacao: observacao,
      totalPedido: total,
    );

    final pedido = await _supabase
        .from('pedido')
        .insert(novoPedido.toInsertMap())
        .select('id_pedido')
        .single();

    final idPedido = pedido['id_pedido'] as String;
    final itensMap = itens
        .map((item) => item.toInsertMap(idPedido: idPedido))
        .toList();

    await _supabase.from('item_pedido').insert(itensMap);
  }
}
