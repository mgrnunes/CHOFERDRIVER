import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_page.dart';
import 'screens/cadastro_screen.dart';
import 'screens/cadastro_sucesso_page.dart';
import 'screens/confirmacao_page.dart';
import 'screens/inicio_screen.dart';

// Services
import 'services/persistence_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'services/websocket_service.dart';

// Models (após gerar os adaptadores com build_runner)
// import 'models/hive_models.dart';

Future<void> main() async {
  // Garantir que o Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação da tela (apenas retrato)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Inicializar Firebase (para notificações)
    await Firebase.initializeApp();
    
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://hymoiciibpjqznepaukz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5bW9pY2lpYnBqcXpuZXBhdWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyNjgxNzcsImV4cCI6MjA3MTg0NDE3N30.H63791V6AAVsbDUqZWnC-6pdeErgf2lsLo7s2gxhqU8',
    );
    
    // Inicializar Hive para persistência local
    await Hive.initFlutter();
    
    // Registrar adaptadores do Hive (descomente após gerar com build_runner)
    // Hive.registerAdapter(ConfiguracaoMotoristaAdapter());
    // Hive.registerAdapter(HistoricoCorridaAdapter());
    // Hive.registerAdapter(LocalizacaoSalvaAdapter());
    
    // Inicializar serviços principais
    await _initializeServices();
    
    debugPrint('✅ Todos os serviços inicializados com sucesso');
  } catch (e) {
    debugPrint('❌ Erro na inicialização: $e');
  }

  runApp(const MyApp());
}

/// Inicializa todos os serviços necessários
Future<void> _initializeServices() async {
  try {
    // Inicializar serviço de persistência
    await PersistenceService.instance.initialize();
    
    // Inicializar serviço de notificações
    await NotificationService.instance.initialize();
    
    // Verificar permissões de localização
    await LocationService.checkPermissions();
    
    debugPrint('🔧 Serviços básicos inicializados');
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar alguns serviços: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chofer Motorista',
      debugShowCheckedModeBanner: false,
      
      // Tema personalizado para o app
      theme: _buildTheme(),
      
      // Rota inicial
      initialRoute: '/splash',
      
      // Rotas do aplicativo
      routes: _buildRoutes(),
      
      // Handler para rotas não encontradas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text(
                'Página não encontrada',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            backgroundColor: Colors.black,
          ),
        );
      },
    );
  }

  /// Constrói o tema do aplicativo
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.orange,
      primaryColor: Colors.orange,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: Colors.grey[850],
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: Colors.orange,
        secondary: Colors.orangeAccent,
        surface: Colors.grey[800]!,
        background: Colors.black,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        error: Colors.red,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      
      // Button themes
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: Colors.grey[850],
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.orange;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.grey),
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.orange;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.orange.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }

  /// Constrói as rotas do aplicativo
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/splash': (context) => const SplashScreen(),
      '/login': (context) => const LoginScreen(),
      '/dashboard': (context) => const DashboardPage(),
      '/cadastro': (context) => const CadastroScreen(),
      '/cadastro_sucesso': (context) => const CadastroSucessoPage(),
      '/confirmacao': (context) => const ConfirmacaoPage(),
      '/inicio': (context) => const InicioScreen(),
    };
  }
}

/// Widget de erro para capturar erros não tratados
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const AppErrorWidget({Key? key, required this.errorDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ops! Algo deu errado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Por favor, reinicie o aplicativo',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Reiniciar o app ou voltar para tela inicial
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/splash',
                    (route) => false,
                  );
                },
                child: const Text('Reiniciar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}