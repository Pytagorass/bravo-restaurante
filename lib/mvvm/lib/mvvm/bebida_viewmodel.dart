import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BebidaViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? mensagemErro;

  Future<bool> lancarBebidaNaConta({
    required String idConta,
    required String idProduto,
    required String idUsuario,
    required int quantidade,
    required double valorUnitario,
    String? observacao,
  }) async {
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      final subtotal = valorUnitario * quantidade;

      await _supabase.from('bebida_lancada').insert({
        'id_conta': idConta,
        'id_produto': idProduto,
        'id_usuario': idUsuario,
        'quantidade': quantidade,
        'valor_unitario': valorUnitario,
        'subtotal': subtotal,
        'observacao': observacao,
      });

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      mensagemErro = 'Erro ao lançar bebida: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> buscarBebidasPorConta(
    String idConta,
  ) async {
    try {
      final response = await _supabase
          .from('bebida_lancada')
          .select('''
            id_bebida_lancada,
            quantidade,
            valor_unitario,
            subtotal,
            observacao,
            created_at,
            produto:id_produto (
              nome_produto,
              categoria
            )
          ''')
          .eq('id_conta', idConta)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      mensagemErro = 'Erro ao buscar bebidas da conta: $e';
      notifyListeners();
      return [];
    }
  }
}
