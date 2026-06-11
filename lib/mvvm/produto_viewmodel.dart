import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bravo_restaurante/models/produto.dart';

class ProdutoViewModel extends ChangeNotifier {
  // Cliente Supabase usado para buscar produtos cadastrados no banco.
  final SupabaseClient _supabase = Supabase.instance.client;

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
      final response = await _supabase
          .from('produto')
          .select()
          .eq('ativo', true)
          .order('nome_produto', ascending: true);

      // Converte cada registro do banco para o model Produto usado no app.
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
    // Reaproveita a lista carregada para separar Restaurante, Bebida etc.
    return produtos.where((produto) => produto.categoria == categoria).toList();
  }

  void limparErro() {
    // Remove erro antigo sem recarregar a lista de produtos.
    mensagemErro = null;
    notifyListeners();
  }
}
