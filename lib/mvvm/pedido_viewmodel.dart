import 'package:bravo_restaurante/models/item_pedido_temporario.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/services/pedido_service.dart';
import 'package:flutter/material.dart';

class PedidoViewModel extends ChangeNotifier {
  // Service responsavel por gravar conta, pedido e itens do pedido.
  final PedidoService _pedidoService = PedidoService();

  // Estados observados pela tela enquanto o pedido esta sendo salvo.
  bool isLoading = false;
  String? mensagemErro;

  Future<bool> gravarContaConsumo({
    required Reserva reserva,
    required List<ItemPedidoTemporario> itens,
    required double total,
    required String idUsuario,
    String? observacao,
  }) async {
    // Nao faz sentido abrir/gravar pedido sem pelo menos um item.
    if (itens.isEmpty) {
      mensagemErro = 'Adicione pelo menos um item ao pedido.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      await _pedidoService.gravarContaConsumo(
        reserva: reserva,
        itens: itens,
        total: total,
        idUsuario: idUsuario,
        observacao: observacao,
      );

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
