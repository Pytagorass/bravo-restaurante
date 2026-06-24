import 'package:bravo_restaurante/models/produto.dart';
import 'package:bravo_restaurante/services/produto_service.dart';
import 'package:flutter/material.dart';

class ProdutoViewModel extends ChangeNotifier {
  // Service responsavel por buscar produtos cadastrados no banco.
  final ProdutoService _produtoService = ProdutoService();

  // Estados consumidos pelas telas enquanto os produtos sao carregados.
  bool isLoading = false;
  String? mensagemErro;

  // Lista local dos produtos ativos retornados pelo Supabase.
  List<Produto> produtos = [];

  Future<void> carregarProdutos() async {
    // Inicia carregamento e avisa os widgets que dependem deste ViewModel.
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      // Consulta apenas produtos ativos e ordena pelo nome exibido nos dropdowns.
      produtos = await _produtoService.carregarProdutosAtivos();

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
    // Reaproveita a lista carregada para separar Restaurante, Bebida etc.
    return produtos.where((produto) => produto.categoria == categoria).toList();
  }

  void limparErro() {
    // Remove erro antigo sem recarregar a lista de produtos.
    mensagemErro = null;
    notifyListeners();
  }
}
