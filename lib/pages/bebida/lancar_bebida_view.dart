import 'package:bravo_restaurante/models/produto.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/lib/mvvm/bebida_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:bravo_restaurante/widgets/info_alert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LancarBebidaView extends StatefulWidget {
  const LancarBebidaView({super.key});

  @override
  State<LancarBebidaView> createState() => _LancarBebidaViewState();
}

class _LancarBebidaViewState extends State<LancarBebidaView> {
  static const Color verdeEscuro = Color(0xFF26522C);
  static const Color verdeMedio = Color(0xFF628D38);
  static const Color cinzaEscuro = Color(0xFF30332E);

  // Chave usada para validar todos os campos do formulario.
  final _formKey = GlobalKey<FormState>();

  // Guarda a reserva e a bebida selecionadas pelo usuario.
  Reserva? reservaSelecionada;
  Produto? bebidaSelecionada;

  // Quantidade de bebidas que sera lancada na conta.
  int quantidade = 1;

  // Calcula o valor total com base na bebida escolhida e na quantidade.
  double get total {
    if (bebidaSelecionada == null) return 0;
    return bebidaSelecionada!.preco * quantidade;
  }

  @override
  void initState() {
    super.initState();

    // Carrega reservas abertas e produtos assim que a tela termina de abrir.
    Future.microtask(() {
      context.read<ReservaViewModel>().carregarReservasAbertas();
      context.read<ProdutoViewModel>().carregarProdutos();
    });
  }

  void _aumentarQuantidade() {
    // Atualiza a tela somando uma unidade.
    setState(() {
      quantidade++;
    });
  }

  void _diminuirQuantidade() {
    if (quantidade <= 1) return;

    // Atualiza a tela removendo uma unidade sem deixar passar de 1.
    setState(() {
      quantidade--;
    });
  }

  Future<void> _lancarBebida() async {
    // Valida formulario, usuario logado e dados escolhidos antes de salvar.
    if (!_formKey.currentState!.validate()) return;

    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva/quarto.');
      return;
    }

    if (bebidaSelecionada == null) {
      _mostrarMensagem('Selecione uma bebida.');
      return;
    }

    final usuarioLogado = context.read<UsuarioViewModel>().usuarioLogado;

    if (usuarioLogado == null) {
      _mostrarMensagem('Usuário não encontrado. Faça login novamente.');
      return;
    }

    // Envia o lancamento para o ViewModel, que grava no backend.
    final sucesso = await context.read<BebidaViewModel>().lancarBebidaNaConta(
      idConta: reservaSelecionada!.idConta,
      idProduto: bebidaSelecionada!.idProduto,
      idUsuario: usuarioLogado.idUsuario,
      quantidade: quantidade,
      valorUnitario: bebidaSelecionada!.preco,
      observacao: 'Lançamento realizado pelo app mobile',
    );

    // Evita atualizar a interface se o usuario saiu da tela durante o envio.
    if (!mounted) return;

    if (sucesso) {
      _mostrarMensagem(
        'Bebida lançada na conta: ${quantidade}x ${bebidaSelecionada!.nomeProduto}',
      );

      // Apos salvar, limpa a bebida e volta a quantidade para o padrao.
      setState(() {
        bebidaSelecionada = null;
        quantidade = 1;
      });
    } else {
      // Mostra a mensagem de erro retornada pelo ViewModel, se existir.
      final erro = context.read<BebidaViewModel>().mensagemErro;
      _mostrarMensagem(erro ?? 'Erro ao lançar bebida.');
    }
  }

  void _cancelarLancamento() {
    setState(() {
      // Cancela o lancamento em montagem antes de gravar no banco.
      reservaSelecionada = null;
      bebidaSelecionada = null;
      quantidade = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.reset();
    });
    _mostrarMensagem('Lançamento de bebida cancelado.');
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observa reservas e produtos para reconstruir a tela quando os dados mudam.
    return Consumer2<ReservaViewModel, ProdutoViewModel>(
      builder: (context, reservaVM, produtoVM, child) {
        final carregando = reservaVM.isLoading || produtoVM.isLoading;

        // Filtra apenas produtos cadastrados como bebida.
        final bebidas = produtoVM.produtos
            .where((produto) => produto.categoria == 'Bebida')
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Lançar Bebida na Conta',
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
                        const InfoAlert(
                          message:
                              'Lançamento rápido de bebida direto na Conta do Cliente.',
                        ),

                        const SizedBox(height: 18),

                        _label('Reserva / Quarto'),
                        const SizedBox(height: 6),
                        _buildDropdownReserva(reservaVM),

                        const SizedBox(height: 18),

                        _label('Bebida'),
                        const SizedBox(height: 6),
                        _buildDropdownBebida(bebidas),

                        const SizedBox(height: 18),

                        _label('Quantidade'),
                        const SizedBox(height: 6),
                        _buildQuantidadeSelector(),

                        const SizedBox(height: 18),

                        _label('Valor Unitário'),
                        const SizedBox(height: 6),
                        _buildValorUnitario(),

                        const SizedBox(height: 18),

                        _buildTotalCard(),

                        const SizedBox(height: 14),

                        _buildBotaoLancar(),
                        const SizedBox(height: 10),
                        _buildBotaoCancelar(),
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
    // Lista as reservas abertas para escolher em qual conta a bebida entrara.
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
      initialValue: reservaSelecionada,
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
          // Trocar de reserva reinicia a bebida e a quantidade escolhidas.
          reservaSelecionada = value;
          bebidaSelecionada = null;
          quantidade = 1;
        });
      },
      validator: (value) {
        // O formulario nao continua sem uma reserva valida.
        if (value == null) {
          return 'Selecione uma reserva';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownBebida(List<Produto> bebidas) {
    // A bebida so pode ser escolhida depois que uma reserva for selecionada.
    final bebidaLiberada = reservaSelecionada != null;

    if (bebidas.isEmpty) {
      return const Text(
        'Nenhuma bebida ativa encontrada.',
        style: TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<Produto>(
      initialValue: bebidaSelecionada,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: !bebidaLiberada,
        fillColor: !bebidaLiberada ? Colors.grey.shade100 : Colors.white,
      ),
      hint: Text(
        bebidaLiberada
            ? 'Selecione a bebida'
            : 'Selecione primeiro a reserva/quarto',
      ),
      items: bebidaLiberada
          ? bebidas.map((bebida) {
              return DropdownMenuItem<Produto>(
                value: bebida,
                child: Text(
                  '${bebida.nomeProduto} - R\$ ${bebida.preco.toStringAsFixed(2)}',
                ),
              );
            }).toList()
          : [],
      onChanged: bebidaLiberada
          ? (value) {
              setState(() {
                // Ao trocar a bebida, a quantidade volta para 1.
                bebidaSelecionada = value;
                quantidade = 1;
              });
            }
          : null,
      validator: (value) {
        // Primeiro exige a reserva, depois exige a bebida.
        if (reservaSelecionada == null) {
          return 'Selecione primeiro a reserva/quarto';
        }

        if (value == null) {
          return 'Selecione uma bebida';
        }

        return null;
      },
    );
  }

  Widget _buildQuantidadeSelector() {
    // Controle visual para aumentar ou diminuir a quantidade da bebida.
    final habilitado = bebidaSelecionada != null;

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

  Widget _buildValorUnitario() {
    // Campo somente leitura com o preco da bebida escolhida.
    final valor = bebidaSelecionada?.preco ?? 0.0;

    return TextFormField(
      enabled: false,
      initialValue: 'R\$ ${valor.toStringAsFixed(2)}',
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildTotalCard() {
    // Exibe o total calculado antes de confirmar o lancamento.
    return Container(
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
            'Total a lançar na Conta do Cliente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Text(
            'R\$ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoLancar() {
    // Habilita o botao apenas quando reserva e bebida foram selecionadas.
    final habilitado = reservaSelecionada != null && bebidaSelecionada != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _lancarBebida : null,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Lançar na Conta do Cliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeEscuro,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBotaoCancelar() {
    // Cancela o lancamento do bar sem enviar nada para o banco.

    // Habilita o botao apenas quando reserva e bebida foram selecionadas.
    final habilitado = reservaSelecionada != null && bebidaSelecionada != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: habilitado ? _cancelarLancamento : null,
        icon: const Icon(Icons.close),
        label: const Text('Cancelar Lançamento'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
