import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener el ID del usuario actual (si está logueado)
  String? get currentUserId => _auth.currentUser?.uid;

  // --- REGISTRO ---
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    required String telefono, // Lo usaremos como teléfono de consultorio
    required String rol,
    String? especialidad,
    String? cedula,
    String? whatsapp,
    String? direccion,
  }) async {
    try {
      // 1. Crea el usuario en Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Preparamos los datos base (comunes para pacientes y médicos)
      Map<String, dynamic> userData = {
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'telefono': telefono,
        'rol': rol,
        'uid': userCredential.user!.uid,
        'fecha_registro': DateTime.now(),
        // 👇 AQUÍ ESTÁ LA NUEVA MAGIA DEL NEGOCIO 👇
        // Si es médico entra APAGADO (false), si es paciente entra PRENDIDO (true)
        'activo': rol == 'medico' ? false : true,
      };

      // 3. Si es médico, blindamos su cuenta con la estructura correcta
      if (rol == 'medico') {
        userData['especialidad'] = especialidad;
        userData['cedula'] = cedula;
        // Se queda como 'basico' por defecto hasta que pague el VIP
        userData['tipo_perfil'] = 'basico';
        userData['servicios'] =
            []; // Array de etiquetas vacío para que no marque error

        // Construimos su primer consultorio automáticamente
        userData['consultorios'] = [
          {
            'nombre': 'Consultorio Principal',
            'direccion': direccion ?? '',
            'telefono': telefono, // Teléfono que puso en el registro
            'whatsapp': whatsapp ?? '',
            'horario': {
              'Lunes': {'abierto': true, 'de': '09:00 AM', 'a': '05:00 PM'},
              'Martes': {'abierto': true, 'de': '09:00 AM', 'a': '05:00 PM'},
              'Miércoles': {'abierto': true, 'de': '09:00 AM', 'a': '05:00 PM'},
              'Jueves': {'abierto': true, 'de': '09:00 AM', 'a': '05:00 PM'},
              'Viernes': {'abierto': true, 'de': '09:00 AM', 'a': '05:00 PM'},
              'Sábado': {'abierto': false, 'de': '09:00 AM', 'a': '02:00 PM'},
              'Domingo': {'abierto': false, 'de': '09:00 AM', 'a': '02:00 PM'},
            },
          },
        ];
      }

      // 4. Guarda todos los datos bien estructurados en Firestore
      await _db
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set(userData);

      return "success";
    } on FirebaseAuthException catch (e) {
      return _manejarErroresFirebase(e);
    } catch (e) {
      return e.toString();
    }
  }

  // --- LOGIN ---
  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return _manejarErroresFirebase(e);
    } catch (e) {
      return e.toString();
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // --- MANEJO DE ERRORES (Para que los mensajes sean claros en español) ---
  String _manejarErroresFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "El correo electrónico no está registrado.";
      case 'wrong-password':
        return "La contraseña es incorrecta.";
      case 'email-already-in-use':
        return "Este correo ya está siendo usado por otra cuenta.";
      case 'invalid-email':
        return "El formato del correo no es válido.";
      case 'weak-password':
        return "La contraseña es muy débil (usa al menos 6 caracteres).";
      default:
        return e.message ?? "Ocurrió un error inesperado.";
    }
  }

  // --- RECUPERAR CONTRASEÑA ---
  Future<String?> recuperarPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "success";
    } on FirebaseAuthException catch (e) {
      return _manejarErroresFirebase(e);
    } catch (e) {
      return e.toString();
    }
  }
}
