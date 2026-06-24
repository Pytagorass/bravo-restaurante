import 'package:bravo_restaurante/models/produto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdutoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Produto>> carregarProdutosAtivos() async {
    final response = await _supabase
        .from('produto')
        .select()
        .eq('ativo', true)
        .order('nome_produto', ascending: true);

    return response.map<Produto>((item) => Produto.fromMap(item)).toList();
  }
}
