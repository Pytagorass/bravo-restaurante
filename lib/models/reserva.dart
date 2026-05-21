class Reserva {
  final String idReserva;
  final String idHospede;
  final String idQuarto;
  final String nomeHospede;
  final String numeroQuarto;
  final String statusReserva;

  Reserva({
    required this.idReserva,
    required this.idHospede,
    required this.idQuarto,
    required this.nomeHospede,
    required this.numeroQuarto,
    required this.statusReserva,
  });

  factory Reserva.fromMap(Map<String, dynamic> map) {
    final hospede = map['hospede'] as Map<String, dynamic>? ?? {};
    final quarto = map['quarto'] as Map<String, dynamic>? ?? {};

    return Reserva(
      idReserva: map['id_reserva'] ?? '',
      idHospede: map['id_hospede'] ?? '',
      idQuarto: map['id_quarto'] ?? '',
      nomeHospede: hospede['nome_hospede'] ?? '',
      numeroQuarto: quarto['numero_quarto'] ?? '',
      statusReserva: map['status_reserva'] ?? '',
    );
  }

  String get descricaoDropdown {
    return 'Quarto $numeroQuarto - $nomeHospede ($statusReserva)';
  }
}
