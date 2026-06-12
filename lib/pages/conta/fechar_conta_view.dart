import 'package:bravo_restaurante/models/reserva.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/widgets/cores_app.dart';
import 'package:bravo_restaurante/widgets/consumo_card.dart';
import 'package:bravo_restaurante/widgets/formulario.dart';
import 'package:bravo_restaurante/widgets/alerta_informacoes_pagina.dart';
import 'package:bravo_restaurante/widgets/botao_acao_principal.dart';
import 'package:bravo_restaurante/widgets/reserva_dropdown.dart';
import 'package:bravo_restaurante/widgets/botao_acao_secundaria.dart';
import 'package:bravo_restaurante/widgets/total_card.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FecharContaView extends StatefulWidget {
  const FecharContaView({super.key});

  @override
  State<FecharContaView> createState() => _FecharContaViewState();
}

class _FecharContaViewState extends State<FecharContaView> {
  // Cliente usado para buscar e atualizar dados diretamente no Supabase.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Reserva escolhida no dropdown; a partir dela a conta sera carregada.
  Reserva? reservaSelecionada;

  // Estados de carregamento e erro exibidos na tela.
  bool carregandoConta = false;
  String? mensagemErro;

  // Listas preenchidas com os pedidos e bebidas encontrados para a conta.
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> bebidas = [];

  // Valor final acumulado da ContaConsumo selecionada.
  double totalConta = 0.0;

  @override
  void initState() {
    super.initState();

    // Carrega as reservas abertas depois que a tela foi criada.
    Future.microtask(() {
      // ignore: use_build_context_synchronously
      context.read<ReservaViewModel>().carregarReservasAbertas();
    });
  }

  Future<void> _carregarResumoConta(Reserva reserva) async {
    // Prepara a tela para buscar novamente os dados da conta.
    setState(() {
      carregandoConta = true;
      mensagemErro = null;
      pedidos = [];
      bebidas = [];
      totalConta = 0.0;
    });

    try {
      // Busca os pedidos vinculados a conta, ignorando pedidos cancelados.
      final pedidosResponse = await _supabase
          .from('pedido')
          .select('''
            total_pedido,
            status_pedido,
            created_at,
            item_pedido (
              quantidade,
              subtotal,
              produto:id_produto (
                nome_produto,
                preco
              )
            )
          ''')
          .eq('id_conta', reserva.idConta)
          .neq('status_pedido', 'Cancelado');

      // Busca as bebidas lancadas diretamente na mesma conta.
      final bebidasResponse = await _supabase
          .from('bebida_lancada')
          .select('''
            id_bebida_lancada,
            quantidade,
            subtotal,
            created_at,
            produto:id_produto (
              nome_produto,
              preco
            )
          ''')
          .eq('id_conta', reserva.idConta);

      // Busca o total acumulado ja calculado na tabela conta_consumo.
      final contaResponse = await _supabase
          .from('conta_consumo')
          .select('total_acumulado')
          .eq('id_conta', reserva.idConta)
          .maybeSingle();

      // Converte as respostas do Supabase para listas usadas nos cards.
      setState(() {
        pedidos = List<Map<String, dynamic>>.from(pedidosResponse);
        bebidas = List<Map<String, dynamic>>.from(bebidasResponse);
        totalConta =
            (contaResponse?['total_acumulado'] as num?)?.toDouble() ?? 0.0;
        carregandoConta = false;
      });
    } catch (e) {
      // Se a busca falhar, a tela mostra a mensagem e encerra o carregamento.
      setState(() {
        mensagemErro = 'Erro ao carregar conta: $e';
        carregandoConta = false;
      });
    }
  }

  Future<void> _fecharConta() async {
    // Impede o fechamento sem uma reserva selecionada.
    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva.');
      return;
    }

    // Pede confirmacao antes de alterar o status da conta no banco.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fechar conta'),
          content: Text(
            'Deseja realmente fechar a conta no valor de R\$ ${totalConta.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CoresAPP.verdeEscuro,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      // Marca a ContaConsumo como fechada e registra data/hora do fechamento.
      await _supabase
          .from('conta_consumo')
          .update({
            'status_conta': 'Fechada',
            'closed_at': DateTime.now().toIso8601String(),
          })
          .eq('id_conta', reservaSelecionada!.idConta);

      // Marca a reserva como fechada para retirar da lista de reservas abertas.
      await _supabase
          .from('reserva')
          .update({'status_reserva': 'Fechada'})
          .eq('id_reserva', reservaSelecionada!.idReserva);

      if (!mounted) return;

      _mostrarMensagem('Conta fechada com sucesso.');

      // Limpa os dados exibidos para evitar mostrar a conta fechada na tela.
      setState(() {
        reservaSelecionada = null;
        pedidos = [];
        bebidas = [];
        totalConta = 0.0;
      });

      // Atualiza o dropdown para remover reservas que acabaram de ser fechadas.
      context.read<ReservaViewModel>().carregarReservasAbertas();
    } catch (e) {
      _mostrarMensagem('Erro ao fechar conta: $e');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatarDataPedido(dynamic valor) {
    final data = valor is DateTime
        ? valor.toLocal()
        : DateTime.tryParse(valor?.toString() ?? '')?.toLocal();

    if (data == null) return 'Data nao informada';

    String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

    final dia = doisDigitos(data.day);
    final mes = doisDigitos(data.month);
    final hora = doisDigitos(data.hour);
    final minuto = doisDigitos(data.minute);

    return '$dia/$mes/${data.year} $hora:$minuto';
  }

  Future<void> _gerarRelatorioConta() async {
    // Gera um PDF com o resumo da conta selecionada.
    if (reservaSelecionada == null) {
      _mostrarMensagem('Selecione uma reserva para gerar o relatório.');
      return;
    }

    final pdf = pw.Document();
    final reserva = reservaSelecionada!;

    // Monta uma pagina de PDF com dados do hospede, pedidos, bebidas e total.
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'BRAVO Restaurante / Lanchonete',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Relatório da Conta do Hóspede'),
          pw.Divider(),

          pw.Text('Hóspede: ${reserva.nomeHospede}'),
          pw.Text('Quarto: ${reserva.numeroQuarto}'),
          pw.Text('Status da Conta: ${reserva.statusConta}'),

          pw.SizedBox(height: 16),

          pw.Text(
            'Restaurante',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          if (pedidos.isEmpty)
            pw.Text('Nenhum pedido registrado.')
          else
            // Para cada pedido, cria um bloco com seus itens e subtotal.
            ...pedidos.map((pedido) {
              final itens = pedido['item_pedido'] as List<dynamic>? ?? [];
              final totalPedido =
                  (pedido['total_pedido'] as num?)?.toDouble() ?? 0.0;
              final dataPedido = _formatarDataPedido(pedido['created_at']);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Pedido',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Data: $dataPedido'),
                  ...itens.map((item) {
                    final produto =
                        item['produto'] as Map<String, dynamic>? ?? {};
                    final subtotal =
                        (item['subtotal'] as num?)?.toDouble() ?? 0.0;

                    return pw.Text(
                      '${item['quantidade']}x ${produto['nome_produto']} - R\$ ${subtotal.toStringAsFixed(2)}',
                    );
                  }),
                  pw.Text(
                    'Total do pedido: R\$ ${totalPedido.toStringAsFixed(2)}',
                  ),
                ],
              );
            }),

          pw.SizedBox(height: 16),

          pw.Text('Bar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          if (bebidas.isEmpty)
            pw.Text('Nenhuma bebida lançada.')
          else
            // Para cada bebida, cria um bloco no mesmo visual dos pedidos.
            ...bebidas.map((bebida) {
              final produto = bebida['produto'] as Map<String, dynamic>? ?? {};
              final subtotal = (bebida['subtotal'] as num?)?.toDouble() ?? 0.0;
              final dataPedido = _formatarDataPedido(bebida['created_at']);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Pedido',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Data: $dataPedido'),
                  pw.Text(
                    '${bebida['quantidade']}x ${produto['nome_produto']} - R\$ ${subtotal.toStringAsFixed(2)}',
                  ),
                  pw.Text(
                    'Total do pedido: R\$ ${subtotal.toStringAsFixed(2)}',
                  ),
                ],
              );
            }),

          pw.Divider(),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL: R\$ ${totalConta.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Abre a tela nativa de impressao/compartilhamento do PDF gerado.
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    // Consumer atualiza a tela quando a lista de reservas mudar no ViewModel.
    return Consumer<ReservaViewModel>(
      builder: (context, reservaVM, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Fechar Conta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: CoresAPP.verdeEscuro,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AlertaInformacoesPagina(
                  message:
                      'Revise o consumo antes de fechar a conta da reserva.',
                ),

                const SizedBox(height: 18),

                const Formulario('Selecione a Reserva'),
                const SizedBox(height: 6),
                _buildDropdownReserva(reservaVM),

                const SizedBox(height: 18),

                // O card da reserva so aparece depois de uma escolha no dropdown.
                if (reservaSelecionada != null) _buildCardReserva(),

                // Enquanto busca pedidos e bebidas, exibe carregamento central.
                if (carregandoConta)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Caso a busca falhe, mostra o texto de erro na propria tela.
                if (mensagemErro != null)
                  Text(
                    mensagemErro!,
                    style: const TextStyle(color: Colors.red),
                  ),

                // O resumo e as acoes aparecem somente com a conta carregada.
                if (!carregandoConta && reservaSelecionada != null) ...[
                  const SizedBox(height: 18),
                  _buildResumoConta(),
                  const SizedBox(height: 18),
                  _buildBotaoFecharConta(),
                  const SizedBox(height: 10),
                  _buildBotaoComprovante(),
                  const SizedBox(height: 10),
                  _buildAvisoFinal(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownReserva(ReservaViewModel reservaVM) {
    // Monta o seletor de reservas abertas e carrega a conta ao selecionar.
    return ReservaDropdown(
      reservaVM: reservaVM,
      reservaSelecionada: reservaSelecionada,
      mostrarLoading: true,
      onChanged: (value) {
        setState(() {
          // Guarda a reserva escolhida antes de buscar o resumo da conta.
          reservaSelecionada = value;
        });

        if (value != null) {
          // Ao selecionar uma reserva, carrega pedidos, bebidas e total.
          _carregarResumoConta(value);
        }
      },
    );
  }

  Widget _buildCardReserva() {
    // Exibe os dados principais da reserva selecionada.
    final reserva = reservaSelecionada!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reserva', style: TextStyle(fontSize: 12)),
          Text(
            reserva.nomeHospede,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CoresAPP.verdeEscuro,
            ),
          ),
          Text('Quarto ${reserva.numeroQuarto}'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reserva.statusConta,
              style: const TextStyle(
                fontSize: 12,
                color: CoresAPP.verdeEscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoConta() {
    // Agrupa pedidos ao restaurante e bar, e total acumulado em um resumo visual.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo da Conta do Cliente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CoresAPP.cinzaEscuro,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),

        const Text(
          'Restaurante',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        if (pedidos.isEmpty)
          const Text('Nenhum pedido registrado.')
        else
          ...pedidos.map((pedido) => _buildPedidoCard(pedido)),

        const SizedBox(height: 14),

        const Text('Bar', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),

        if (bebidas.isEmpty)
          const Text('Nenhuma pedido ao bar realizado.')
        else
          ...bebidas.map((bebida) => _buildBebidaCard(bebida)),

        const SizedBox(height: 14),

        TotalCard(
          titulo: 'Total Acumulado na Conta do Cliente',
          valor: totalConta,
          backgroundColor: CoresAPP.verdeEscuro,
          valorFontSize: 26,
        ),
      ],
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido) {
    // Card individual com itens e total de um pedido da conta.
    final total = (pedido['total_pedido'] as num?)?.toDouble() ?? 0.0;
    final itens = pedido['item_pedido'] as List<dynamic>? ?? [];
    final dataPedido = _formatarDataPedido(pedido['created_at']);

    return ConsumoCard(
      data: dataPedido,
      itens: itens.map((item) {
        final produto = item['produto'] as Map<String, dynamic>? ?? {};
        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
        return '${item['quantidade']}x ${produto['nome_produto']} - R\$ ${subtotal.toStringAsFixed(2)}';
      }).toList(),
      total: total,
    );
  }

  Widget _buildBebidaCard(Map<String, dynamic> bebida) {
    // Card individual do bar no mesmo visual usado pelos pedidos do restaurante.
    final produto = bebida['produto'] as Map<String, dynamic>? ?? {};
    final subtotal = (bebida['subtotal'] as num?)?.toDouble() ?? 0.0;
    final dataPedido = _formatarDataPedido(bebida['created_at']);

    return ConsumoCard(
      data: dataPedido,
      itens: [
        '${bebida['quantidade']}x ${produto['nome_produto']} - R\$ ${subtotal.toStringAsFixed(2)}',
      ],
      total: subtotal,
    );
  }

  Widget _buildBotaoFecharConta() {
    // Botao principal que inicia o fluxo de confirmacao e fechamento da conta.
    return BotaoAcaoPrincipal(
      label: 'Fechar Conta',
      icon: Icons.attach_money,
      onPressed: _fecharConta,
    );
  }

  Widget _buildBotaoComprovante() {
    // Botao secundario que gera o comprovante em PDF da conta.
    return BotaoAcaoSecundaria(
      label: 'Gerar Comprovante',
      icon: Icons.description_outlined,
      onPressed: _gerarRelatorioConta,
    );
  }

  Widget _buildAvisoFinal() {
    // Aviso exibido para reforcar a consequencia do fechamento da conta.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: const Text(
        'Ao fechar a conta, nenhum novo pedido ou bebida poderá ser adicionado à Conta do Cliente.',
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}
