import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bravo_restaurante/models/produto.dart';

class ProdutoViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? mensagemErro;

  List<Produto> produtos = [];

  Future<void> carregarProdutos() async {
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('produto')
          .select()
          .eq('ativo', true)
          .order('nome_produto', ascending: true);

      produtos = response
          .map<Produto>((item) => Produto.fromMap(item))
          .toList();

      debugPrint('Produtos ativos carregados: ${produtos.length}');

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
      mensagemErro = 'Erro ao carregar produtos: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  List<Produto> filtrarPorCategoria(String categoria) {
    return produtos.where((produto) => produto.categoria == categoria).toList();
  }

  void limparErro() {
    mensagemErro = null;
    notifyListeners();
  }
}
