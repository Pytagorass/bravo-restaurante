class Reserva {
  final String idReserva;
  final String idHospede;
  final String idQuarto;
  final String idConta;

  final String nomeHospede;
  final String numeroQuarto;
  final String statusReserva;
  final String statusConta;

  Reserva({
    required this.idReserva,
    required this.idHospede,
    required this.idQuarto,
    required this.idConta,
    required this.nomeHospede,
    required this.numeroQuarto,
    required this.statusReserva,
    required this.statusConta,
  });

  factory Reserva.fromMap(Map<String, dynamic> map) {
    final hospede =
        map['hospede'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final quarto =
        map['quarto'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final conta =
        map['conta_consumo'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return Reserva(
      idReserva: map['id_reserva'] ?? '',
      idHospede: map['id_hospede'] ?? '',
      idQuarto: map['id_quarto'] ?? '',
      idConta: conta['id_conta'] ?? '',
      nomeHospede: hospede['nome_hospede'] ?? '',
      numeroQuarto: quarto['numero_quarto'] ?? '',
      statusReserva: map['status_reserva'] ?? '',
      statusConta: conta['status_conta'] ?? '',
    );
  }

  String get descricaoDropdown {
    return 'Quarto $numeroQuarto - $nomeHospede ($statusReserva)';
  }

  bool get possuiContaAberta {
    return idConta.isNotEmpty && statusConta == 'Aberta';
  }
}
