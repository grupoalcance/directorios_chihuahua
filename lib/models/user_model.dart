class UserModel {
  final String? id;
  final String nombre;
  final String email;
  final String telefono;
  final String rol; // 'medico' o 'paciente'

  UserModel({
    this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  // Esto es para convertir los datos de Firebase a código Flutter
  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'email': email, 'telefono': telefono, 'rol': rol};
  }
}
