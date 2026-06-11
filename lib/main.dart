import 'package:bravo_restaurante/mvvm/conta_consumo_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/lib/mvvm/bebida_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/pedido_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/produto_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/reserva_viewmodel.dart';
import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:bravo_restaurante/pages/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://vtnpypripbptoifscpps.supabase.co';

const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ0bnB5cHJpcGJwdG9pZnNjcHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NzYwNjgsImV4cCI6MjA5MjU1MjA2OH0.68xUZjWYg83EFfmgCK7_4lvKUTra-95RqVa1Cr2LqoA';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioViewModel()),
        ChangeNotifierProvider(create: (_) => ProdutoViewModel()),
        ChangeNotifierProvider(create: (_) => ReservaViewModel()),
        ChangeNotifierProvider(create: (_) => PedidoViewModel()),
        ChangeNotifierProvider(create: (_) => ContaConsumoViewModel()),
        ChangeNotifierProvider(create: (_) => BebidaViewModel()),
      ],
      child: const BravoApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class BravoApp extends StatelessWidget {
  const BravoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRAVO Restaurante',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: const Color(0xFF26522C),

        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF26522C)),
      ),

      home: const LoginView(),
    );
  }
}
