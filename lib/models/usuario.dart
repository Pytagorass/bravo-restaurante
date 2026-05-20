class Usuario {
  final String idUsuario;
  final String nomeUsuario;
  final String emailUsuario;
  final String senha;
  final String tipoUsuario;
  final bool ativo;

  Usuario({
    required this.idUsuario,
    required this.nomeUsuario,
    required this.emailUsuario,
    required this.senha,
    required this.tipoUsuario,
    required this.ativo,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['id_usuario'] ?? '',
      nomeUsuario: map['nome_usuario'] ?? '',
      emailUsuario: map['email_usuario'] ?? '',
      senha: map['senha'] ?? '',
      tipoUsuario: map['tipo_usuario'] ?? '',
      ativo: map['ativo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nome_usuario': nomeUsuario,
      'email_usuario': emailUsuario,
      'senha': senha,
      'tipo_usuario': tipoUsuario,
      'ativo': ativo,
    };
  }
}
