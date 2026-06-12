import 'package:bravo_restaurante/pages/bebida/lancar_bebida_view.dart';
import 'package:bravo_restaurante/pages/conta/conta_hospede_view.dart';
import 'package:bravo_restaurante/pages/conta/fechar_conta_view.dart';
import 'package:bravo_restaurante/pages/pedido/registrar_pedido_view.dart';
import 'package:bravo_restaurante/widgets/app_colors.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Controla qual item da barra inferior esta selecionado.
  int _selectedIndex = 0;

  void _logout() {
    Navigator.of(context).pop();
  }

  // Abre a tela usada para registrar pedidos do restaurante.
  void _abrirRegistrarPedido() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarPedidoView()),
    );
  }

  // Abre a tela usada para lancar bebidas na conta do hospede.
  void _abrirLancarBebida() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LancarBebidaView()),
    );
  }

  // Abre a tela que mostra os consumos da conta do hospede.
  void _abrirContaHospede() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContaHospedeView()),
    );
  }

  // Abre a tela onde a conta selecionada pode ser fechada.
  void _abrirFecharConta() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FecharContaView()),
    );
  }

  // Fecha o menu lateral antes de navegar para outra tela.
  void _fecharDrawerEAbrir(VoidCallback abrirTela) {
    Navigator.pop(context);
    abrirTela();
  }

  @override
  Widget build(BuildContext context) {
    // Monta a pagina principal com app bar, drawer, conteudo e menu inferior.
    return Scaffold(
      appBar: AppBar(
        title: const Text('BRAVO Restaurante'),
        backgroundColor: AppColors.verdeEscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        // Permite puxar a tela para baixo e simular uma atualizacao da Home.
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ResumoCard(),
            const SizedBox(height: 16),
            _AcessosRapidosCard(
              abrirRegistrarPedido: _abrirRegistrarPedido,
              abrirLancarBebida: _abrirLancarBebida,
              abrirContaHospede: _abrirContaHospede,
              abrirFecharConta: _abrirFecharConta,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.verdeEscuro,
        unselectedItemColor: AppColors.cinzaEscuro.withOpacity(0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          // Atualiza o item selecionado e abre a tela ligada ao indice tocado.
          setState(() => _selectedIndex = index);

          if (index == 1) {
            _abrirRegistrarPedido();
          } else if (index == 2) {
            _abrirContaHospede();
          } else if (index == 3) {
            _abrirFecharConta();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Conta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Fechar',
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    // Menu lateral com atalhos para as principais funcoes do aplicativo.
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.verdeEscuro),
            accountName: Text('Usuário Teste'),
            accountEmail: Text('teste@bravo.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.verdeEscuro),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Registrar Pedido'),
            onTap: () {
              _fecharDrawerEAbrir(_abrirRegistrarPedido);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_bar),
            title: const Text('Lançar Bebida'),
            onTap: () {
              _fecharDrawerEAbrir(_abrirLancarBebida);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Conta do Hóspede'),
            onTap: () {
              _fecharDrawerEAbrir(_abrirContaHospede);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Fechar Conta'),
            onTap: () {
              Navigator.pop(context);
              _abrirFecharConta();
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Card informativo exibido no topo da Home.
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.verdeMedio,
              child: Icon(Icons.restaurant, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Controle de pedidos e consumo do barco-hotel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.verdeEscuro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcessosRapidosCard extends StatelessWidget {
  final VoidCallback abrirRegistrarPedido;
  final VoidCallback abrirLancarBebida;
  final VoidCallback abrirContaHospede;
  final VoidCallback abrirFecharConta;

  const _AcessosRapidosCard({
    required this.abrirRegistrarPedido,
    required this.abrirLancarBebida,
    required this.abrirContaHospede,
    required this.abrirFecharConta,
  });

  @override
  Widget build(BuildContext context) {
    // Card com botoes rapidos para acessar os fluxos principais.
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acessos rápidos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    label: 'Restaurante',
                    icon: Icons.receipt_long,
                    onTap: abrirRegistrarPedido,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickButton(
                    label: 'Bar',
                    icon: Icons.local_bar,
                    onTap: abrirLancarBebida,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickButton(
                    label: 'Conta do Hóspede',
                    icon: Icons.account_balance_wallet,
                    onTap: abrirContaHospede,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickButton(
                    label: 'Fechar Conta',
                    icon: Icons.attach_money,
                    onTap: abrirFecharConta,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Botao reutilizavel dos atalhos da Home.
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.verdeMedio),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.verdeEscuro,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.verdeMedio.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
