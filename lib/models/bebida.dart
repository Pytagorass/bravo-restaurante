class Bebida {
  final String idBebidaLancada;
  final String idConta;
  final String idProduto;
  final String idUsuario;
  final int quantidade;
  final double valorUnitario;
  final double subtotal;
  final String? observacao;

  Bebida({
    required this.idBebidaLancada,
    required this.idConta,
    required this.idProduto,
    required this.idUsuario,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
    this.observacao,
  });

  factory Bebida.fromMap(Map<String, dynamic> map) {
    return Bebida(
      idBebidaLancada: map['id_bebida_lancada'] ?? '',
      idConta: map['id_conta'] ?? '',
      idProduto: map['id_produto'] ?? '',
      idUsuario: map['id_usuario'] ?? '',
      quantidade: map['quantidade'] ?? 0,
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      observacao: map['observacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_bebida_lancada': idBebidaLancada,
      'id_conta': idConta,
      'id_produto': idProduto,
      'id_usuario': idUsuario,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'subtotal': subtotal,
      'observacao': observacao,
    };
  }
}
