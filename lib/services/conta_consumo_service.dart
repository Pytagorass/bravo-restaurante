import 'package:bravo_restaurante/models/conta_consumo.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/models/resumo_fechamento_conta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContaConsumoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ContaConsumo?> carregarContaDaReserva(Reserva reserva) async {
    final contaMap = await _supabase
        .from('conta_consumo')
        .select()
        .eq('id_reserva', reserva.idReserva)
        .maybeSingle();

    if (contaMap == null) return null;

    final idConta = contaMap['id_conta'] as String;

    final pedidosResponse = await _supabase
        .from('pedido')
        .select('''
          id_pedido,
          status_pedido,
          observacao,
          total_pedido,
          created_at,
          item_pedido (
            quantidade,
            valor_unitario,
            subtotal,
            produto:id_produto (
              nome_produto
            )
          )
        ''')
        .eq('id_conta', idConta)
        .order('created_at', ascending: false);

    final bebidasResponse = await _supabase
        .from('bebida_lancada')
        .select('''
          quantidade,
          valor_unitario,
          subtotal,
          observacao,
          created_at,
          produto:id_produto (
            nome_produto
          )
        ''')
        .eq('id_conta', idConta)
        .order('created_at', ascending: false);

    final pedidos = pedidosResponse
        .map<PedidoConta>((item) => PedidoConta.fromMap(item))
        .toList();

    final bebidas = bebidasResponse
        .map<BebidaConta>((item) => BebidaConta.fromMap(item))
        .toList();

    return ContaConsumo.fromMap(contaMap, pedidos: pedidos, bebidas: bebidas);
  }

  Future<ResumoFechamentoConta> carregarResumoFechamento(
    Reserva reserva,
  ) async {
    final pedidosResponse = await _supabase
        .from('pedido')
        .select('''
          total_pedido,
          status_pedido,
          created_at,
          item_pedido (
            quantidade,
            subtotal,
            produto:id_produto (
              nome_produto,
              preco
            )
          )
        ''')
        .eq('id_conta', reserva.idConta)
        .neq('status_pedido', 'Cancelado');

    final bebidasResponse = await _supabase
        .from('bebida_lancada')
        .select('''
          id_bebida_lancada,
          quantidade,
          subtotal,
          created_at,
          produto:id_produto (
            nome_produto,
            preco
          )
        ''')
        .eq('id_conta', reserva.idConta);

    final contaResponse = await _supabase
        .from('conta_consumo')
        .select('total_acumulado')
        .eq('id_conta', reserva.idConta)
        .maybeSingle();

    return ResumoFechamentoConta(
      pedidos: pedidosResponse
          .map<PedidoResumoConta>((item) => PedidoResumoConta.fromMap(item))
          .toList(),
      bebidas: bebidasResponse
          .map<BebidaResumoConta>((item) => BebidaResumoConta.fromMap(item))
          .toList(),
      totalConta:
          (contaResponse?['total_acumulado'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> fecharContaDaReserva({
    required String idConta,
    required String idReserva,
  }) async {
    await _supabase
        .from('conta_consumo')
        .update({
          'status_conta': 'Fechada',
          'closed_at': DateTime.now().toIso8601String(),
        })
        .eq('id_conta', idConta);

    await _supabase
        .from('reserva')
        .update({'status_reserva': 'Fechada'})
        .eq('id_reserva', idReserva);
  }
}
