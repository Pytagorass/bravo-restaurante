import 'package:bravo_restaurante/models/item_pedido_temporario.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidoViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? mensagemErro;

  Future<bool> gravarContaConsumo({
    required Reserva reserva,
    required List<ItemPedidoTemporario> itens,
    required double total,
    required String idUsuario,
    String? observacao,
  }) async {
    if (itens.isEmpty) {
      mensagemErro = 'Adicione pelo menos um item ao pedido.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      // A conta de consumo e unica por reserva. Reaproveitamos a existente
      // para manter todos os pedidos e bebidas no mesmo fechamento.
      final contaExistente = await _supabase
          .from('conta_consumo')
          .select('id_conta')
          .eq('id_reserva', reserva.idReserva)
          .maybeSingle();

      final String idConta;

      if (contaExistente == null) {
        // O total comeca em zero porque os triggers do banco recalculam
        // total_pedido e total_acumulado apos inserir os itens.
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

      // Cada confirmacao gera um pedido vinculado a conta da reserva.
      final pedido = await _supabase
          .from('pedido')
          .insert({
            'id_conta': idConta,
            'id_usuario': idUsuario,
            'status_pedido': 'Aberto',
            'observacao': observacao,
            'total_pedido': total,
          })
          .select('id_pedido')
          .single();

      final idPedido = pedido['id_pedido'] as String;

      // item_pedido recebe id_pedido, nao id_conta. A relacao com a conta
      // passa por pedido -> conta_consumo, conforme a modelagem do banco.
      final itensMap = itens
          .map((item) => item.toMap(idPedido: idPedido))
          .toList();

      await _supabase.from('item_pedido').insert(itensMap);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      mensagemErro = 'Erro ao gravar conta de consumo: $e';
      debugPrint(mensagemErro);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
