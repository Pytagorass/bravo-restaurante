import 'package:supabase_flutter/supabase_flutter.dart';

class BebidaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> lancarBebidaNaConta({
    required String idConta,
    required String idProduto,
    required String idUsuario,
    required int quantidade,
    required double valorUnitario,
    String? observacao,
  }) async {
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
  }

  Future<List<Map<String, dynamic>>> buscarBebidasPorConta(
    String idConta,
  ) async {
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
  }
}
