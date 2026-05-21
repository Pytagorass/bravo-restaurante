import 'package:bravo_restaurante/models/item_pedido_temporario.dart';
import 'package:bravo_restaurante/models/produto.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/pedido_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<ItemPedidoTemporario> itensPedido = [];

// Soma os subtotais dos itens ainda não gravados no banco.
double get totalPedido {
  double total = 0;

  for (final item in itensPedido) {
    total += item.subtotal;
  }

  return total;
}

class RegistrarPedidoView extends StatefulWidget {
  const RegistrarPedidoView({super.key});

  @override
  State<RegistrarPedidoView> createState() => _RegistrarPedidoViewState();
}

class _RegistrarPedidoViewState extends State<RegistrarPedidoView> {
  static const Color verdeEscuro = Color(0xFF26522C);
  static const Color verdeMedio = Color(0xFF628D38);
  static const Color cinzaEscuro = Color(0xFF30332E);

  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();

  Reserva? reservaSelecionada;
  Produto? produtoSelecionado;

  int quantidade = 1;
  bool salvandoPedido = false;

  @override
  void initState() {
    super.initState();

    // Carrega os dados necessários para montar os dropdowns da tela.
    Future.microtask(() {
      context.read<ProdutoViewModel>().carregarProdutos();
      context.read<ReservaViewModel>().carregarReservasAbertas();
    });
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  void _aumentarQuantidade() {
    setState(() {
      quantidade++;
    });
  }

  void _diminuirQuantidade() {
    if (quantidade <= 1) return;

    setState(() {
      quantidade--;
    });
  }

  void _adicionarItem() {
    // Valida reserva, produto e quantidade antes de adicionar à lista local.
    if (!_formKey.currentState!.validate()) return;

    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva/quarto.');
      return;
    }

    if (produtoSelecionado == null) {
      _mostrarMensagem('Selecione um produto.');
      return;
    }

    final item = ItemPedidoTemporario(
      produto: produtoSelecionado!,
      quantidade: quantidade,
      observacao: _observacaoController.text.trim(),
    );

    setState(() {
      // O item fica temporariamente na tela até o usuário confirmar o pedido.
      itensPedido.add(item);

      produtoSelecionado = null;
      quantidade = 1;
      _observacaoController.clear();
    });

    _mostrarMensagem('Item adicionado ao pedido.');
  }

  Future<void> _confirmarPedido() async {
    // A confirmação grava a conta/pedido/itens no Supabase.
    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva/quarto.');
      return;
    }

    if (itensPedido.isEmpty) {
      _mostrarMensagem('Adicione pelo menos um item ao pedido.');
      return;
    }

    setState(() {
      salvandoPedido = true;
    });

    final usuarioLogado = context.read<UsuarioViewModel>().usuarioLogado;

    // pedido.id_usuario é obrigatório na modelagem do banco.
    if (usuarioLogado == null) {
      setState(() {
        salvandoPedido = false;
      });
      _mostrarMensagem('Usuario logado nao encontrado.');
      return;
    }

    final pedidoVM = context.read<PedidoViewModel>();
    // Envia uma cópia da lista para evitar alterações durante a gravação.
    final sucesso = await pedidoVM.gravarContaConsumo(
      reserva: reservaSelecionada!,
      itens: List<ItemPedidoTemporario>.from(itensPedido),
      total: totalPedido,
      idUsuario: usuarioLogado.idUsuario,
      observacao: _observacaoPedido(),
    );

    if (!mounted) return;

    setState(() {
      salvandoPedido = false;
    });

    if (!sucesso) {
      _mostrarMensagem(
        pedidoVM.mensagemErro ?? 'Erro ao confirmar o pedido.',
      );
      return;
    }

    setState(() {
      // Depois de gravar com sucesso, limpa o formulário para um novo pedido.
      itensPedido.clear();
      reservaSelecionada = null;
      produtoSelecionado = null;
      quantidade = 1;
      _observacaoController.clear();
    });

    _mostrarMensagem('Pedido confirmado e vinculado a ContaConsumo.');
  }

  String? _observacaoPedido() {
    // A tabela pedido tem observação, mas item_pedido não. Por isso as
    // observações dos itens são consolidadas no campo observacao do pedido.
    final observacoes = itensPedido
        .where((item) => item.observacao.trim().isNotEmpty)
        .map((item) => '${item.produto.nomeProduto}: ${item.observacao.trim()}')
        .join('\n');

    return observacoes.isEmpty ? null : observacoes;
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProdutoViewModel, ReservaViewModel>(
      builder: (context, produtoVM, reservaVM, child) {
        final carregando = produtoVM.isLoading || reservaVM.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Registrar Pedido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: verdeEscuro,
            foregroundColor: Colors.white,
          ),
          body: carregando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Reserva / Quarto'),
                        const SizedBox(height: 6),
                        _buildDropdownReserva(reservaVM),

                        const SizedBox(height: 18),

                        _label('Produto'),
                        const SizedBox(height: 6),
                        _buildDropdownProduto(produtoVM),

                        const SizedBox(height: 18),

                        _label('Quantidade'),
                        const SizedBox(height: 6),
                        _buildQuantidadeSelector(),

                        const SizedBox(height: 18),

                        _label('Observação'),
                        const SizedBox(height: 6),
                        _buildObservacaoField(),

                        const SizedBox(height: 22),

                        _buildBotaoAdicionar(),
                        if (itensPedido.isNotEmpty) ...[
                          const SizedBox(height: 24),

                          const Text(
                            'Itens do Pedido',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: cinzaEscuro,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: itensPedido.length,
                              itemBuilder: (context, index) {
                                final item = itensPedido[index];

                                return ListTile(
                                  title: Text(
                                    '${item.quantidade}x ${item.produto.nomeProduto}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  subtitle: Text(
                                    'R\$ ${item.produto.preco.toStringAsFixed(2)} cada',
                                  ),

                                  trailing: Text(
                                    'R\$ ${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: verdeEscuro,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: verdeMedio,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total do Pedido',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                Text(
                                  'R\$ ${totalPedido.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: salvandoPedido
                                  ? null
                                  : _confirmarPedido,
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Confirmar e Vincular à ContaConsumo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: verdeEscuro,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _label(String texto) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w600, color: cinzaEscuro),
    );
  }

  Widget _buildDropdownReserva(ReservaViewModel reservaVM) {
    // Mostra erro/lista vazia antes de renderizar o dropdown.
    if (reservaVM.mensagemErro != null) {
      return Text(
        reservaVM.mensagemErro!,
        style: const TextStyle(color: Colors.red),
      );
    }

    if (reservaVM.reservas.isEmpty) {
      return const Text(
        'Nenhuma reserva aberta encontrada.',
        style: TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<Reserva>(
      value: reservaSelecionada,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      hint: const Text('Selecione a reserva'),
      items: reservaVM.reservas.map((reserva) {
        return DropdownMenuItem<Reserva>(
          value: reserva,
          child: Text(reserva.descricaoDropdown),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          reservaSelecionada = value;
          produtoSelecionado = null;
          quantidade = 1;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecione uma reserva';
        }

        return null;
      },
    );
  }

  Widget _buildDropdownProduto(ProdutoViewModel produtoVM) {
    // Produto só é liberado depois da reserva, pois o pedido precisa de conta.
    final produtoLiberado = reservaSelecionada != null;

    if (produtoVM.mensagemErro != null) {
      return Text(
        produtoVM.mensagemErro!,
        style: const TextStyle(color: Colors.red),
      );
    }

    if (produtoVM.produtos.isEmpty) {
      return const Text(
        'Nenhum produto ativo encontrado.',
        style: TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<Produto>(
      value: produtoSelecionado,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: !produtoLiberado,
        fillColor: !produtoLiberado ? Colors.grey.shade100 : Colors.white,
      ),
      hint: Text(
        produtoLiberado
            ? 'Selecione o produto'
            : 'Selecione primeiro a reserva/quarto',
      ),
      items: produtoLiberado
          ? produtoVM.produtos.map((produto) {
              return DropdownMenuItem<Produto>(
                value: produto,
                child: Text(
                  '${produto.nomeProduto} - R\$ ${produto.preco.toStringAsFixed(2)}',
                ),
              );
            }).toList()
          : [],
      onChanged: produtoLiberado
          ? (value) {
              setState(() {
                produtoSelecionado = value;
                quantidade = 1;
              });
            }
          : null,
      validator: (value) {
        if (reservaSelecionada == null) {
          return 'Selecione primeiro a reserva/quarto';
        }

        if (value == null) {
          return 'Selecione um produto';
        }

        return null;
      },
    );
  }

  Widget _buildQuantidadeSelector() {
    // A quantidade só pode ser alterada após escolher um produto.
    final habilitado = produtoSelecionado != null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: habilitado ? Colors.white : Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: habilitado && quantidade > 1
                ? _diminuirQuantidade
                : null,
            icon: const Icon(Icons.remove),
            color: verdeEscuro,
          ),
          Expanded(
            child: Center(
              child: Text(
                quantidade.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: habilitado ? cinzaEscuro : Colors.grey,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: habilitado ? _aumentarQuantidade : null,
            icon: const Icon(Icons.add),
            color: verdeEscuro,
          ),
        ],
      ),
    );
  }

  Widget _buildObservacaoField() {
    return TextFormField(
      controller: _observacaoController,
      minLines: 4,
      maxLines: 5,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Ex: Sem cebola, ponto da carne...',
      ),
    );
  }

  Widget _buildBotaoAdicionar() {
    // O botão só habilita quando reserva e produto já foram selecionados.
    final habilitado = reservaSelecionada != null && produtoSelecionado != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _adicionarItem : null,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Adicionar Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeMedio,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
