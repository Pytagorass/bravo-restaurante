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
    isLoading = true;
    mensagemErro = null;
    notifyListeners();

    try {
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
      debugPrint(
        'Login: usuario encontrado. ativo=${usuario.ativo}, senhaConfere=${usuario.senha == senha}',
      );

      if (usuario.senha != senha) {
        mensagemErro = 'E-mail ou senha invalidos.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      if (!usuario.ativo) {
        mensagemErro = 'Usuario inativo.';
        isLoading = false;
        notifyListeners();
        return false;
      }

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
    usuarioLogado = null;
    mensagemErro = null;
    notifyListeners();
  }
}
