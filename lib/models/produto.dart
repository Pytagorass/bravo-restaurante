// Representa um produto cadastrado no banco.
// Pode ser comida, bebida ou outra categoria usada pelos dropdowns.
class Produto {
  // Campos principais da tabela produto.
  final String idProduto;
  final String nomeProduto;
  final String categoria;
  final double preco;
  final bool ativo;

  Produto({
    required this.idProduto,
    required this.nomeProduto,
    required this.categoria,
    required this.preco,
    required this.ativo,
  });

  // Converte o Map retornado pelo Supabase em Produto.
  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      idProduto: map['id_produto'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      categoria: map['categoria'] ?? '',
      preco: (map['preco'] as num?)?.toDouble() ?? 0.0,
      ativo: map['ativo'] ?? false,
    );
  }

  // Converte Produto em Map usando os nomes das colunas do banco.
  Map<String, dynamic> toMap() {
    return {
      'id_produto': idProduto,
      'nome_produto': nomeProduto,
      'categoria': categoria,
      'preco': preco,
      'ativo': ativo,
    };
  }
}
