import 'package:bravo_restaurante/models/produto.dart';

class ItemPedidoTemporario {
  final Produto produto;
  final int quantidade;
  final String observacao;

  ItemPedidoTemporario({
    required this.produto,
    required this.quantidade,
    required this.observacao,
  });

  double get subtotal {
    return produto.preco * quantidade;
  }

  // Monta o payload esperado pela tabela item_pedido.
  // O id_pedido só existe depois que o pedido é criado no banco.
  Map<String, dynamic> toMap({String? idPedido}) {
    final map = {
      'id_produto': produto.idProduto,
      'quantidade': quantidade,
      'valor_unitario': produto.preco,
      'subtotal': subtotal,
    };

    if (idPedido != null) {
      map['id_pedido'] = idPedido;
    }

    return map;
  }
}
