import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BebidaViewModel extends ChangeNotifier {
  // Cliente Supabase usado para inserir e consultar bebidas lancadas.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estados observados pela tela de lancamento de bebida.
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
      // Calcula o subtotal no app antes de gravar o lancamento no banco.
      final subtotal = valorUnitario * quantidade;

      // Insere a bebida diretamente na ContaConsumo selecionada.
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
      // Busca bebidas de uma conta com os dados do produto relacionado.
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

      // Retorna mapas porque esta consulta e usada como resumo dinamico.
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      mensagemErro = 'Erro ao buscar bebidas da conta: $e';
      notifyListeners();
      return [];
    }
  }
}
