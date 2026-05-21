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
      final conta = await _supabase
          .from('conta_consumo')
          .insert({
            'id_reserva': reserva.idReserva,
            'valor_total': total,
            'status_conta': 'Aberta',
          })
          .select('id_conta_consumo')
          .single();

      final idContaConsumo = conta['id_conta_consumo'] as String;

      final itensMap = itens
          .map((item) => item.toMap(idContaConsumo: idContaConsumo))
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
