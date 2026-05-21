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

  Map<String, dynamic> toMap({String? idContaConsumo}) {
    final map = {
      'id_produto': produto.idProduto,
      'quantidade': quantidade,
      'valor_unitario': produto.preco,
      'subtotal': subtotal,
      'observacao': observacao,
    };

    if (idContaConsumo != null) {
      map['id_conta_consumo'] = idContaConsumo;
    }

    return map;
  }
}
