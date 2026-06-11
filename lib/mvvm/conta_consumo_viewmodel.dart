import 'package:bravo_restaurante/models/conta_consumo.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContaConsumoViewModel extends ChangeNotifier {
  // Cliente Supabase usado para consultar conta, pedidos e bebidas da reserva.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estados observados pela tela de conta do hospede.
  bool isLoading = false;
  String? mensagemErro;
  ContaConsumo? conta;

  Future<void> carregarContaDaReserva(Reserva reserva) async {
    // Limpa dados antigos antes de carregar a conta da nova reserva selecionada.
    isLoading = true;
    mensagemErro = null;
    conta = null;
    notifyListeners();

    try {
      // A tela parte da reserva selecionada e localiza a conta unica dela.
      final contaMap = await _supabase
          .from('conta_consumo')
          .select()
          .eq('id_reserva', reserva.idReserva)
          .maybeSingle();

      if (contaMap == null) {
        mensagemErro = 'Nenhuma conta de consumo encontrada para esta reserva.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final idConta = contaMap['id_conta'] as String;

      // Busca pedidos com os itens e produtos ja relacionados pelo PostgREST.
      final pedidosResponse = await _supabase
          .from('pedido')
          .select('''
            id_pedido,
            status_pedido,
            observacao,
            total_pedido,
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

      // Bebidas sao lancamentos diretos na conta, separados dos pedidos.
      final bebidasResponse = await _supabase
          .from('bebida_lancada')
          .select('''
            quantidade,
            valor_unitario,
            subtotal,
            observacao,
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

      // Junta os dados da conta, pedidos e bebidas em um unico model para a tela.
      conta = ContaConsumo.fromMap(
        contaMap,
        pedidos: pedidos,
        bebidas: bebidas,
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      mensagemErro = 'Erro ao carregar conta de consumo: $e';
      debugPrint(mensagemErro);
      isLoading = false;
      notifyListeners();
    }
  }

  void limpar() {
    // Remove a conta atual quando nenhuma reserva esta selecionada.
    conta = null;
    mensagemErro = null;
    notifyListeners();
  }
}
