import 'package:bravo_restaurante/mvvm/conta_consumo_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/lib/mvvm/bebida_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/pedido_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:bravo_restaurante/pages/login/login_view.dart';
import 'package:bravo_restaurante/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Dados de conexao com o Supabase, que funciona como backend do app.
const supabaseUrl = 'https://vtnpypripbptoifscpps.supabase.co';

// Chave publica anonima usada pelo cliente Flutter para acessar o Supabase.
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ0bnB5cHJpcGJwdG9pZnNjcHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NzYwNjgsImV4cCI6MjA5MjU1MjA2OH0.68xUZjWYg83EFfmgCK7_4lvKUTra-95RqVa1Cr2LqoA';

Future<void> main() async {
  // Garante que o Flutter esteja pronto antes de inicializar servicos externos.
  WidgetsFlutterBinding.ensureInitialized();

  // Abre a conexao com o Supabase antes de montar a interface.
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Registra os ViewModels que serao usados pelas telas com Provider.
  runApp(
    MultiProvider(
      providers: [
        // Guarda dados do usuario logado e regras de autenticacao.
        ChangeNotifierProvider(create: (_) => UsuarioViewModel()),
        // Carrega produtos usados em pedidos e lancamentos de bebida.
        ChangeNotifierProvider(create: (_) => ProdutoViewModel()),
        // Carrega reservas abertas para selecionar quarto/hospede.
        ChangeNotifierProvider(create: (_) => ReservaViewModel()),
        // Controla criacao e envio dos pedidos do restaurante.
        ChangeNotifierProvider(create: (_) => PedidoViewModel()),
        // Consulta o resumo de consumo da conta do hospede.
        ChangeNotifierProvider(create: (_) => ContaConsumoViewModel()),
        // Registra bebidas diretamente na ContaConsumo.
        ChangeNotifierProvider(create: (_) => BebidaViewModel()),
      ],
      child: const BravoApp(),
    ),
  );
}

// Atalho global para o cliente Supabase ja inicializado no main().
final supabase = Supabase.instance.client;

// Widget raiz do aplicativo: define tema, titulo e tela inicial.
class BravoApp extends StatelessWidget {
  const BravoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRAVO Restaurante',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        // Cor principal usada nas barras, botoes e componentes do app.
        primaryColor: AppColors.verdeEscuro,

        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.verdeEscuro),
      ),

      // A primeira tela exibida quando o aplicativo abre.
      home: const LoginView(),
    );
  }
}
