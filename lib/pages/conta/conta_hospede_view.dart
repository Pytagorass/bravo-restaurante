import 'package:bravo_restaurante/models/conta_consumo.dart';
import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/conta_consumo_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/widgets/info_alert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

String _formatarDataConta(DateTime? data) {
  if (data == null) return 'Data nao informada';

  final dataLocal = data.toLocal();
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

  final dia = doisDigitos(dataLocal.day);
  final mes = doisDigitos(dataLocal.month);
  final hora = doisDigitos(dataLocal.hour);
  final minuto = doisDigitos(dataLocal.minute);

  return '$dia/$mes/${dataLocal.year} $hora:$minuto';
}

class ContaHospedeView extends StatefulWidget {
  const ContaHospedeView({super.key});

  @override
  State<ContaHospedeView> createState() => _ContaHospedeViewState();
}

class _ContaHospedeViewState extends State<ContaHospedeView> {
  static const Color verdeEscuro = Color(0xFF26522C);
  static const Color cinzaEscuro = Color(0xFF30332E);

  // Reserva usada para buscar e exibir a conta de consumo.
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
    // Observa reservas e conta para atualizar a tela conforme as buscas terminam.
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
                      // Aviso inicial explicando o objetivo desta consulta.
                      const InfoAlert(
                        message:
                            'Consulte pedidos, bebidas e total acumulado de uma reserva aberta.',
                      ),

                      const SizedBox(height: 16),

                      _buildReservaDropdown(reservaVM),
                      const SizedBox(height: 16),
                      // Abaixo do dropdown, a tela alterna entre loading, erro e detalhes.
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
            // Trocar a reserva dispara nova busca da ContaConsumo.
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
          'Restaurante',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (conta.pedidos.isEmpty)
          const _MensagemCard(mensagem: 'Nenhum pedido registrado.')
        else
          ...conta.pedidos.map((pedido) => _PedidoCard(pedido: pedido)),
        const SizedBox(height: 18),
        const Text(
          'Bar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (conta.bebidas.isEmpty)
          const _MensagemCard(mensagem: 'Nenhum pedido ao bar realizado.')
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
    // Card no mesmo padrao visual da tela Fechar Conta.
    final dataPedido = _formatarDataConta(pedido.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pedido', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Data: $dataPedido'),
            if (pedido.observacao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Observacao: ${pedido.observacao}'),
            ],
            const SizedBox(height: 4),
            ...pedido.itens.map((item) {
              return Text(
                '${item.quantidade}x ${item.nomeProduto} - R\$ ${item.subtotal.toStringAsFixed(2)}',
              );
            }),
            const SizedBox(height: 6),
            Text(
              'Total: R\$ ${pedido.totalPedido.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: verdeEscuro,
              ),
            ),
          ],
        ),
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
    // Card do bar no mesmo padrao visual dos pedidos do restaurante.
    final dataPedido = _formatarDataConta(bebida.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pedido', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Data: $dataPedido'),
            const SizedBox(height: 4),
            Text(
              '${bebida.quantidade}x ${bebida.nomeProduto} - R\$ ${bebida.subtotal.toStringAsFixed(2)}',
            ),
            if (bebida.observacao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Observacao: ${bebida.observacao}'),
            ],
            const SizedBox(height: 6),
            Text(
              'Total: R\$ ${bebida.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: verdeEscuro,
              ),
            ),
          ],
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
    // Mensagem neutra usada para estado vazio, erro ou ausencia de registros.
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
