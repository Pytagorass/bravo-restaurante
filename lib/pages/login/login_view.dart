// import 'package:bravo_restaurante/pages/home/home_view.dart';
// import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class LoginView extends StatefulWidget {
//   const LoginView({super.key});

//   @override
//   State<LoginView> createState() => _LoginViewState();
// }

// class _LoginViewState extends State<LoginView> {
//   final emailController = TextEditingController();
//   final senhaController = TextEditingController();

//   bool isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // 🔹 LOGO
//                 Image.asset('assets/LogoBravo.ico', height: 120),

//                 const SizedBox(height: 40),

//                 // 🔹 CAMPO EMAIL
//                 TextField(
//                   controller: emailController,
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // 🔹 CAMPO SENHA
//                 TextField(
//                   controller: senhaController,
//                   obscureText: true,
//                   decoration: InputDecoration(
//                     labelText: 'Senha',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // 🔹 BOTÃO
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: isLoading
//                         ? null
//                         : () async {
//                             setState(() {
//                               isLoading = true;
//                             });

//                             final usuarioViewModel = context
//                                 .read<UsuarioViewModel>();

//                             final sucesso = await usuarioViewModel.login(
//                               email: emailController.text.trim(),
//                               senha: senhaController.text.trim(),
//                             );

//                             if (!context.mounted) return;

//                             setState(() {
//                               isLoading = false;
//                             });

//                             if (sucesso) {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const HomeView(),
//                                 ),
//                               );
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(
//                                     usuarioViewModel.mensagemErro ??
//                                         'Erro ao realizar login',
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF26522C),
//                     ),
//                     child: isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text('Entrar', style: TextStyle(fontSize: 16)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:bravo_restaurante/mvvm/usuario_viewmodel.dart';
import 'package:bravo_restaurante/pages/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const Color verdeEscuro = Color(0xFF26522C);
  static const Color verdeMedio = Color(0xFF628D38);
  static const Color cinzaEscuro = Color(0xFF30332E);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final usuarioVM = Provider.of<UsuarioViewModel>(context, listen: false);

    final sucesso = await usuarioVM.login(
      email: _emailController.text.trim().toLowerCase(),
      senha: _senhaController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (sucesso) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
    } else {
      _mostrarErro(usuarioVM.mensagemErro ?? 'E-mail ou senha incorretos.');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/LogoBravo.ico', height: 110),

              const SizedBox(height: 16),

              const Text(
                'BRAVO Restaurante',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: verdeEscuro,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Controle da lanchonete e restaurante do barco-hotel',
                textAlign: TextAlign.center,
                style: TextStyle(color: cinzaEscuro),
              ),

              const SizedBox(height: 32),

              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Digite seu e-mail';
                            }

                            if (!value.contains('@')) {
                              return 'E-mail inválido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Digite sua senha';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _login,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isLoading ? 'Entrando...' : 'Entrar',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: verdeEscuro,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'BRAVO • Barco-Hotel',
                style: TextStyle(
                  color: verdeMedio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
