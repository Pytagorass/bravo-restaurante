class ContaConsumo {
  final String idConta;
  final String idReserva;
  final double totalAcumulado;
  final String statusConta;
  final List<PedidoConta> pedidos;
  final List<BebidaConta> bebidas;

  ContaConsumo({
    required this.idConta,
    required this.idReserva,
    required this.totalAcumulado,
    required this.statusConta,
    required this.pedidos,
    required this.bebidas,
  });

  factory ContaConsumo.fromMap(
    Map<String, dynamic> map, {
    List<PedidoConta> pedidos = const [],
    List<BebidaConta> bebidas = const [],
  }) {
    // A conta vem da tabela conta_consumo; pedidos e bebidas são carregados
    // separadamente pelo ViewModel para simplificar as consultas.
    return ContaConsumo(
      idConta: map['id_conta'] ?? '',
      idReserva: map['id_reserva'] ?? '',
      totalAcumulado: (map['total_acumulado'] as num?)?.toDouble() ?? 0.0,
      statusConta: map['status_conta'] ?? '',
      pedidos: pedidos,
      bebidas: bebidas,
    );
  }
}

class PedidoConta {
  final String idPedido;
  final String statusPedido;
  final String observacao;
  final double totalPedido;
  final List<ItemPedidoConta> itens;

  PedidoConta({
    required this.idPedido,
    required this.statusPedido,
    required this.observacao,
    required this.totalPedido,
    required this.itens,
  });

  factory PedidoConta.fromMap(Map<String, dynamic> map) {
    // item_pedido chega como lista aninhada na consulta do PostgREST.
    final itensMap = map['item_pedido'] as List<dynamic>? ?? [];

    return PedidoConta(
      idPedido: map['id_pedido'] ?? '',
      statusPedido: map['status_pedido'] ?? '',
      observacao: map['observacao'] ?? '',
      totalPedido: (map['total_pedido'] as num?)?.toDouble() ?? 0.0,
      itens: itensMap
          .map((item) => ItemPedidoConta.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ItemPedidoConta {
  final String nomeProduto;
  final int quantidade;
  final double valorUnitario;
  final double subtotal;

  ItemPedidoConta({
    required this.nomeProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
  });

  factory ItemPedidoConta.fromMap(Map<String, dynamic> map) {
    // O nome do produto vem do relacionamento produto:id_produto.
    final produto = map['produto'] as Map<String, dynamic>? ?? {};

    return ItemPedidoConta(
      nomeProduto: produto['nome_produto'] ?? 'Produto',
      quantidade: map['quantidade'] ?? 0,
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BebidaConta {
  final String nomeProduto;
  final int quantidade;
  final double valorUnitario;
  final double subtotal;
  final String observacao;

  BebidaConta({
    required this.nomeProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
    required this.observacao,
  });

  factory BebidaConta.fromMap(Map<String, dynamic> map) {
    // Bebidas são lançamentos diretos na conta, mas também referenciam produto.
    final produto = map['produto'] as Map<String, dynamic>? ?? {};

    return BebidaConta(
      nomeProduto: produto['nome_produto'] ?? 'Bebida',
      quantidade: map['quantidade'] ?? 0,
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      observacao: map['observacao'] ?? '',
    );
  }
}
