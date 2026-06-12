import 'package:bravo_restaurante/models/item_pedido_temporario.dart';
import 'package:bravo_restaurante/models/produto.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/pedido_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:bravo_restaurante/widgets/cores_app.dart';
import 'package:bravo_restaurante/widgets/formulario.dart';
import 'package:bravo_restaurante/widgets/alerta_informacoes_pagina.dart';
import 'package:bravo_restaurante/widgets/botao_acao_principal.dart';
import 'package:bravo_restaurante/widgets/seletor_quantidade.dart';
import 'package:bravo_restaurante/widgets/reserva_dropdown.dart';
import 'package:bravo_restaurante/widgets/botao_acao_secundaria.dart';
import 'package:bravo_restaurante/widgets/total_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Lista local usada para montar o pedido antes de confirmar e gravar no banco.
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
  // Formulario principal usado para validar reserva/produto antes de adicionar item.
  final _formKey = GlobalKey<FormState>();

  // Controller da observacao digitada para o item/pedido.
  final _observacaoController = TextEditingController();

  // Selecoes atuais feitas nos dropdowns.
  Reserva? reservaSelecionada;
  Produto? produtoSelecionado;

  // Estado local da quantidade e do envio para o banco.
  int quantidade = 1;
  bool salvandoPedido = false;

  @override
  void initState() {
    super.initState();

    // Carrega os dados necessários para montar os dropdowns da tela.
    Future.microtask(() {
      // ignore: use_build_context_synchronously
      context.read<ProdutoViewModel>().carregarProdutos();
      // ignore: use_build_context_synchronously
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

  void _cancelarPedido() {
    if (salvandoPedido) return;

    setState(() {
      // Cancela a montagem local do pedido antes de gravar no banco.
      itensPedido.clear();
      reservaSelecionada = null;
      produtoSelecionado = null;
      quantidade = 1;
      _observacaoController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.reset();
    });
    _mostrarMensagem('Inserção de pedido cancelada.');
  }

  void _removerItemPedido(int index) {
    if (salvandoPedido) return;

    setState(() {
      itensPedido.removeAt(index);
    });

    _mostrarMensagem('Item removido do pedido.');
  }

  Future<void> _editarQuantidadeItem(int index) async {
    if (salvandoPedido) return;

    final item = itensPedido[index];
    var novaQuantidade = item.quantidade;

    final quantidadeEditada = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar quantidade'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: novaQuantidade > 1
                        ? () {
                            setDialogState(() {
                              novaQuantidade--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      novaQuantidade.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setDialogState(() {
                        novaQuantidade++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresAPP.verdeEscuro,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, novaQuantidade),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (quantidadeEditada == null || !mounted) return;

    setState(() {
      itensPedido[index] = ItemPedidoTemporario(
        produto: item.produto,
        quantidade: quantidadeEditada,
        observacao: item.observacao,
      );
    });

    _mostrarMensagem('Quantidade do item atualizada.');
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
      _mostrarMensagem(pedidoVM.mensagemErro ?? 'Erro ao confirmar o pedido.');
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

    _mostrarMensagem('Pedido confirmado e vinculado a Conta do cliente.');
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
    // Observa produtos e reservas para montar o formulario quando os dados chegam.
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
            backgroundColor: CoresAPP.verdeEscuro,
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
                        // Alerta de contexto no inicio do formulario.
                        const AlertaInformacoesPagina(
                          message:
                              'Registre o pedido e vincule a uma reserva aberta.',
                        ),

                        const SizedBox(height: 18),

                        const Formulario('Reserva / Quarto'),
                        const SizedBox(height: 6),
                        _buildDropdownReserva(reservaVM),

                        const SizedBox(height: 18),

                        const Formulario('Produto'),
                        const SizedBox(height: 6),
                        _buildDropdownProduto(produtoVM),

                        const SizedBox(height: 18),

                        const Formulario('Quantidade'),
                        const SizedBox(height: 6),
                        SeletorQuantide(
                          quantidade: quantidade,
                          habilitado: produtoSelecionado != null,
                          aoAumentar: _aumentarQuantidade,
                          aoDiminuir: _diminuirQuantidade,
                        ),

                        const SizedBox(height: 18),

                        const Formulario('Observação'),
                        const SizedBox(height: 6),
                        _buildObservacaoField(),

                        const SizedBox(height: 22),

                        _buildBotaoAdicionar(),
                        if (itensPedido.isNotEmpty) ...[
                          // A lista aparece apenas depois que ha itens temporarios.
                          const SizedBox(height: 24),

                          const Text(
                            'Itens do Pedido',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CoresAPP.cinzaEscuro,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Card(
                            // Lista local dos itens que ainda nao foram gravados no banco.
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

                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'R\$ ${item.subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: CoresAPP.verdeEscuro,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Editar quantidade',
                                        onPressed: salvandoPedido
                                            ? null
                                            : () =>
                                                  _editarQuantidadeItem(index),
                                        icon: const Icon(Icons.edit_outlined),
                                        color: CoresAPP.verdeEscuro,
                                      ),
                                      IconButton(
                                        tooltip: 'Cancelar item',
                                        onPressed: salvandoPedido
                                            ? null
                                            : () => _removerItemPedido(index),
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Use editar para alterar a quantidade ou cancelar para remover um item antes de confirmar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: CoresAPP.cinzaEscuro,
                            ),
                          ),

                          const SizedBox(height: 14),

                          TotalCard(
                            // Total calculado antes da confirmacao final do pedido.
                            titulo: 'Total do Pedido',
                            valor: totalPedido,
                          ),

                          const SizedBox(height: 14),

                          BotaoAcaoPrincipal(
                            // Confirmacao final grava ContaConsumo, pedido e item_pedido.
                            label: 'Confirmar e Vincular à Conta do Cliente',
                            icon: Icons.check,
                            onPressed: salvandoPedido ? null : _confirmarPedido,
                            borderRadius: 10,
                          ),

                          const SizedBox(height: 10),
                          _buildBotaoCancelar(),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildDropdownReserva(ReservaViewModel reservaVM) {
    // Mostra erro/lista vazia antes de renderizar o dropdown.
    return ReservaDropdown(
      reservaVM: reservaVM,
      reservaSelecionada: reservaSelecionada,
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
      initialValue: produtoSelecionado,
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

  Widget _buildObservacaoField() {
    // Campo opcional para observacoes que serao consolidadas no pedido.
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
    // O botao so habilita quando reserva e produto ja foram selecionados.
    final habilitado = reservaSelecionada != null && produtoSelecionado != null;

    return BotaoAcaoPrincipal(
      label: 'Adicionar Item',
      icon: Icons.add,
      onPressed: habilitado ? _adicionarItem : null,
      backgroundColor: CoresAPP.verdeMedio,
    );
  }

  Widget _buildBotaoCancelar() {
    // Cancela o pedido em montagem sem enviar nada para o banco.
    final habilitado = itensPedido.isNotEmpty && !salvandoPedido;

    return BotaoAcaoSecundaria(
      label: 'Cancelar Pedido',
      icon: Icons.close,
      onPressed: habilitado ? _cancelarPedido : null,
      foregroundColor: Colors.red.shade700,
      borderColor: Colors.red.shade300,
    );
  }
}
