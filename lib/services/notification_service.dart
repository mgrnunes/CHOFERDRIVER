import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler para mensagens em background
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
  
  // Processar notificação de corrida em background
  if (message.data['type'] == 'nova_corrida') {
    await NotificationService.instance.showCorridaNotification(
      title: 'Nova Corrida Disponível!',
      body: message.data['origem'] ?? 'Nova solicitação de corrida',
      payload: json.encode(message.data),
    );
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    try {
      // Inicializar Firebase
      await Firebase.initializeApp();
      
      // Configurar handler para mensagens em background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Solicitar permissões
      await _requestPermissions();
      
      // Configurar notificações locais
      await _initializeLocalNotifications();
      
      // Configurar FCM
      await _configureFCM();
      
      // Obter token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
    } catch (e) {
      debugPrint('Erro ao inicializar notificações: $e');
    }
  }

  /// Solicita permissões de notificação
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint('Permissão de notificação: ${settings.authorizationStatus}');
  }

  /// Inicializa notificações locais
  Future<void> _initializeLocalNotifications() async {
    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Criar canal de notificação para Android
    await _createNotificationChannels();
  }

  /// Cria canais de notificação (Android)
  Future<void> _createNotificationChannels() async {
    // Canal para corridas
    const AndroidNotificationChannel corridaChannel = AndroidNotificationChannel(
      'corridas',
      'Corridas',
      description: 'Notificações de novas corridas disponíveis',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('corrida_sound'),
    );

    // Canal para sistema
    const AndroidNotificationChannel sistemaChannel = AndroidNotificationChannel(
      'sistema',
      'Sistema',
      description: 'Notificações do sistema',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(corridaChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(sistemaChannel);
  }

  /// Configura FCM
  Future<void> _configureFCM() async {
    // Configurar foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configurar quando app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Verificar se app foi aberto via notificação
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Manipula mensagens em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.messageId}');
    
    String title = message.notification?.title ?? 'Nova Notificação';
    String body = message.notification?.body ?? '';
    
    // Mostrar notificação local
    if (message.data['type'] == 'nova_corrida') {
      await showCorridaNotification(
        title: title,
        body: body,
        payload: json.encode(message.data),
      );
    } else {
      await showGeneralNotification(
        title: title,
        body: body,
        payload: json.encode(message.data),
      );
    }
  }

  /// Manipula quando app é aberto via notificação
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App aberto via notificação: ${message.messageId}');
    
    // Navegar para tela específica baseado no tipo
    if (message.data['type'] == 'nova_corrida') {
      // Navegar para tela de corrida
      // NavigatorService.navigateTo('/corrida', arguments: message.data);
    }
  }

  /// Callback quando notificação local é tocada
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Notificação tocada: ${notificationResponse.id}');
    
    if (notificationResponse.payload != null) {
      try {
        final data = json.decode(notificationResponse.payload!);
        
        // Processar baseado no tipo
        if (data['type'] == 'nova_corrida') {
          // Navegar para tela de aceitar corrida
          // NavigatorService.navigateTo('/aceitar_corrida', arguments: data);
        }
      } catch (e) {
        debugPrint('Erro ao processar payload: $e');
      }
    }
  }

  /// Mostra notificação de nova corrida
  Future<void> showCorridaNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'corridas',
      'Corridas',
      channelDescription: 'Notificações de novas corridas',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Nova Corrida',
      icon: '@mipmap/ic_launcher',
      color: Colors.orange,
      sound: RawResourceAndroidNotificationSound('corrida_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'aceitar',
          'Aceitar',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
          contextual: true,
        ),
        AndroidNotificationAction(
          'rejeitar',
          'Rejeitar',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
          contextual: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'corrida_sound.wav',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Mostra notificação geral do sistema
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sistema',
      'Sistema',
      channelDescription: 'Notificações do sistema',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancela notificação específica
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Subscreve a um tópico FCM
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscrito ao tópico: $topic');
  }

  /// Desinscreve de um tópico FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Desinscrito do tópico: $topic');
  }

  /// Atualiza token FCM no servidor
  Future<void> updateTokenOnServer(String userId) async {
    if (_fcmToken != null) {
      try {
        // Aqui você enviaria o token para seu servidor
        // await ApiService.updateFCMToken(userId, _fcmToken!);
        debugPrint('Token FCM atualizado no servidor');
      } catch (e) {
        debugPrint('Erro ao atualizar token: $e');
      }
    }
  }
}