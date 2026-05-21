import 'package:bravo_restaurante/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = false;
  String? mensagemErro;

  Usuario? usuarioLogado;

  bool get estaLogado => usuarioLogado != null;

  Future<bool> login({required String email, required String senha}) async {
    // Estado observado pela interface para indicar carregamento e limpar erros antigos.
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
      // Busca o usuário pelo e-mail sem diferenciar maiúsculas/minúsculas.
      // A senha e o status ativo são validados depois para mensagens mais claras.
      final response = await _supabase
          .from('usuario')
          .select()
          .ilike('email_usuario', email)
          .maybeSingle();

      if (response == null) {
        debugPrint('Login: nenhum usuario retornado para o e-mail informado.');
        mensagemErro = 'E-mail ou senha invalidos.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final usuario = Usuario.fromMap(response);
      // Log de diagnóstico sem expor a senha digitada no console.
      debugPrint(
        'Login: usuario encontrado. ativo=${usuario.ativo}, senhaConfere=${usuario.senha == senha}',
      );

      // Mantém a mesma mensagem para e-mail inexistente e senha incorreta.
      if (usuario.senha != senha) {
        mensagemErro = 'E-mail ou senha invalidos.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Usuários inativos existem no banco, mas não podem acessar o app.
      if (!usuario.ativo) {
        mensagemErro = 'Usuario inativo.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Guarda o usuário autenticado para outras telas usarem id/tipo/nome.
      usuarioLogado = usuario;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      mensagemErro = 'Erro ao realizar login: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    // Remove o usuário da sessão local mantida pelo Provider.
    usuarioLogado = null;
    mensagemErro = null;
    notifyListeners();
  }
}
