import 'package:bravo_restaurante/models/produto.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
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

  final _formKey = GlobalKey<FormState>();

  Reserva? reservaSelecionada;
  Produto? bebidaSelecionada;

  int quantidade = 1;

  double get total {
    if (bebidaSelecionada == null) return 0;
    return bebidaSelecionada!.preco * quantidade;
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ReservaViewModel>().carregarReservasAbertas();
      context.read<ProdutoViewModel>().carregarProdutos();
    });
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

  void _lancarBebida() {
    if (!_formKey.currentState!.validate()) return;

    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva/quarto.');
      return;
    }

    if (bebidaSelecionada == null) {
      _mostrarMensagem('Selecione uma bebida.');
      return;
    }

    _mostrarMensagem(
      'Bebida lançada: ${quantidade}x ${bebidaSelecionada!.nomeProduto} - R\$ ${total.toStringAsFixed(2)}',
    );

    setState(() {
      bebidaSelecionada = null;
      quantidade = 1;
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReservaViewModel, ProdutoViewModel>(
      builder: (context, reservaVM, produtoVM, child) {
        final carregando = reservaVM.isLoading || produtoVM.isLoading;

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
                        _alertaInfo(),

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
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _alertaInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lançamento rápido de bebida direto na ContaConsumo.',
              style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String texto) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w600, color: cinzaEscuro),
    );
  }

  Widget _buildDropdownReserva(ReservaViewModel reservaVM) {
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
          bebidaSelecionada = null;
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

  Widget _buildDropdownBebida(List<Produto> bebidas) {
    final bebidaLiberada = reservaSelecionada != null;

    if (bebidas.isEmpty) {
      return const Text(
        'Nenhuma bebida ativa encontrada.',
        style: TextStyle(color: Colors.red),
      );
    }

    return DropdownButtonFormField<Produto>(
      value: bebidaSelecionada,
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
                bebidaSelecionada = value;
                quantidade = 1;
              });
            }
          : null,
      validator: (value) {
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
            'Total a lançar na ContaConsumo',
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
    final habilitado = reservaSelecionada != null && bebidaSelecionada != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _lancarBebida : null,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Lançar na ContaConsumo',
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
}
