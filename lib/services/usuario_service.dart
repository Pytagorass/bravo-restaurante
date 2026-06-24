import 'package:bravo_restaurante/models/usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Usuario?> buscarPorEmail(String email) async {
    final response = await _supabase
        .from('usuario')
        .select()
        .ilike('email_usuario', email)
        .maybeSingle();

    if (response == null) return null;

    return Usuario.fromMap(response);
  }
}
