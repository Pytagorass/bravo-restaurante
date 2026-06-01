import 'package:bravo_restaurante/models/conta_consumo.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/conta_consumo_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContaHospedeView extends StatefulWidget {
  const ContaHospedeView({super.key});

  @override
  State<ContaHospedeView> createState() => _ContaHospedeViewState();
}

class _ContaHospedeViewState extends State<ContaHospedeView> {
  static const Color verdeEscuro = Color(0xFF26522C);
  static const Color cinzaEscuro = Color(0xFF30332E);

  Reserva? reservaSelecionada;

  @override
  void initState() {
    super.initState();

    // A tela sempre começa listando as reservas abertas disponíveis.
    Future.microtask(() {
      // ignore: use_build_context_synchronously
      context.read<ReservaViewModel>().carregarReservasAbertas();
    });
  }

  Future<void> _selecionarReserva(Reserva? reserva) async {
    // Ao trocar a reserva, a conta exibida precisa acompanhar a seleção.
    setState(() {
      reservaSelecionada = reserva;
    });

    if (reserva == null) {
      context.read<ContaConsumoViewModel>().limpar();
      return;
    }

    await context.read<ContaConsumoViewModel>().carregarContaDaReserva(reserva);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReservaViewModel, ContaConsumoViewModel>(
      builder: (context, reservaVM, contaVM, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Conta do Hospede',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: verdeEscuro,
            foregroundColor: Colors.white,
          ),
          body: reservaVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    // Pull-to-refresh recarrega a conta da reserva atual.
                    if (reservaSelecionada != null) {
                      await contaVM.carregarContaDaReserva(reservaSelecionada!);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildReservaDropdown(reservaVM),
                      const SizedBox(height: 16),
                      if (contaVM.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (contaVM.mensagemErro != null)
                        _MensagemCard(mensagem: contaVM.mensagemErro!)
                      else if (contaVM.conta != null)
                        _ContaDetalhes(conta: contaVM.conta!)
                      else
                        const _MensagemCard(
                          mensagem: 'Selecione uma reserva para ver a conta.',
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildReservaDropdown(ReservaViewModel reservaVM) {
    // Antes do dropdown, a tela trata erro ou ausência de reservas abertas.
    if (reservaVM.mensagemErro != null) {
      return _MensagemCard(mensagem: reservaVM.mensagemErro!);
    }

    if (reservaVM.reservas.isEmpty) {
      return const _MensagemCard(
        mensagem: 'Nenhuma reserva aberta encontrada.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reserva / Quarto',
          style: TextStyle(fontWeight: FontWeight.w600, color: cinzaEscuro),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Reserva>(
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
            _selecionarReserva(value);
          },
        ),
      ],
    );
  }
}

class _ContaDetalhes extends StatelessWidget {
  final ContaConsumo conta;

  const _ContaDetalhes({required this.conta});

  static const Color verdeMedio = Color(0xFF628D38);

  @override
  Widget build(BuildContext context) {
    // Mostra o resumo financeiro e as duas origens de consumo: pedidos e bebidas.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text(
                'Conta ${conta.statusConta}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${conta.totalAcumulado.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pedidos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (conta.pedidos.isEmpty)
          const _MensagemCard(mensagem: 'Nenhum pedido registrado.')
        else
          ...conta.pedidos.map((pedido) => _PedidoCard(pedido: pedido)),
        const SizedBox(height: 18),
        const Text(
          'Bebidas Lancadas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (conta.bebidas.isEmpty)
          const _MensagemCard(mensagem: 'Nenhuma bebida lancada.')
        else
          ...conta.bebidas.map((bebida) => _BebidaCard(bebida: bebida)),
      ],
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoConta pedido;

  const _PedidoCard({required this.pedido});

  static const Color verdeEscuro = Color(0xFF26522C);

  @override
  Widget build(BuildContext context) {
    // ExpansionTile mantém a lista compacta e abre os itens sob demanda.
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          'Pedido ${pedido.statusPedido}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('R\$ ${pedido.totalPedido.toStringAsFixed(2)}'),
        children: [
          if (pedido.observacao.isNotEmpty)
            ListTile(dense: true, title: Text(pedido.observacao)),
          ...pedido.itens.map((item) {
            return ListTile(
              dense: true,
              title: Text('${item.quantidade}x ${item.nomeProduto}'),
              subtitle: Text(
                'R\$ ${item.valorUnitario.toStringAsFixed(2)} cada',
              ),
              trailing: Text(
                'R\$ ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: verdeEscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BebidaCard extends StatelessWidget {
  final BebidaConta bebida;

  const _BebidaCard({required this.bebida});

  static const Color verdeEscuro = Color(0xFF26522C);

  @override
  Widget build(BuildContext context) {
    // Bebidas lançadas direto na conta não têm itens filhos, então usam ListTile.
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.local_bar, color: verdeEscuro),
        title: Text('${bebida.quantidade}x ${bebida.nomeProduto}'),
        subtitle: Text(
          bebida.observacao.isEmpty
              ? 'R\$ ${bebida.valorUnitario.toStringAsFixed(2)} cada'
              : bebida.observacao,
        ),
        trailing: Text(
          'R\$ ${bebida.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: verdeEscuro,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MensagemCard extends StatelessWidget {
  final String mensagem;

  const _MensagemCard({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(mensagem),
    );
  }
}
