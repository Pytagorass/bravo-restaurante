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
          .eq('email_usuario', email)
          .eq('senha', senha)
          .eq('ativo', true)
          .maybeSingle();

      if (response == null) {
        mensagemErro = 'E-mail ou senha inválidos.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      usuarioLogado = Usuario.fromMap(response);
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
