import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Background message received: ${message.messageId}');
  print('📬 Title: ${message.notification?.title}');
  print('📬 Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
        
        // Get FCM token
        String? token = await _fcm.getToken();
        print('📱 FCM Token: $token');
        
        // Initialize local notifications
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
        
        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (details) {
            print('Notification tapped: ${details.payload}');
          },
        );

        // Create notification channel for Android
        const androidChannel = AndroidNotificationChannel(
          'high_importance_channel',
          'SnapBudget Notifications',
          description: 'Important notifications from SnapBudget',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        print('🎉 Notification service initialized successfully');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ Notification permission denied');
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print('⚠️ Notification permission not determined');
      } else {
        print('❓ Notification permission status: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Notification received: ${message.notification?.title}');
    
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'SnapBudget Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }

  // Budget warning notifications
  Future<void> showBudgetWarning(double percentage) async {
    String title;
    String body;
    
    if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body = 'You\'ve spent ${percentage.toStringAsFixed(0)}% of your budget';
    } else if (percentage >= 90) {
      title = '⚠️ Budget Alert!';
      body = '${percentage.toStringAsFixed(0)}% of budget used. Slow down!';
    } else {
      title = '💡 Budget Notice';
      body = '${percentage.toStringAsFixed(0)}% of budget used';
    }
    
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Budget Alerts',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    
    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // Payday reminder
  Future<void> showPaydayReminder(String amount, int daysUntil) async {
    String title;
    String body;
    
    if (daysUntil == 1) {
      title = '💰 Payday Tomorrow!';
      body = 'You\'ll receive $amount tomorrow';
    } else if (daysUntil == 0) {
      title = '🎉 It\'s Payday!';
      body = 'You\'re receiving $amount today';
    } else {
      title = '📅 Payday in $daysUntil days';
      body = 'You\'ll receive $amount';
    }
    
    await _localNotifications.show(
      1,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Payday Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Large expense alert
  Future<void> showLargeExpenseAlert(double amount) async {
    try {
      await _localNotifications.show(
        2,
        '💸 Large Expense Added',
        'You just spent ${_formatCurrency(amount)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Expense Alerts',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Large expense notification sent');
    } catch (e) {
      print('❌ Error showing large expense alert: $e');
    }
  }

  // Income added notification
  Future<void> showIncomeAdded(String amount) async {
    await _localNotifications.show(
      3,
      '✅ Income Source Added',
      'Expected income: $amount',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Income Alerts',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  // Goal notifications
  Future<void> showGoalReminder(List<Map<String, dynamic>> goals) async {
    if (goals.isEmpty) return;
    
    String title = '🎯 You have ${goals.length} active goal${goals.length > 1 ? 's' : ''}';
    String body = 'Check your progress and stay on track!';
    
    // If there are expense limits near completion, show specific alert
    for (var goal in goals) {
      if (goal['category'] == 'expense_limit') {
        double progress = (goal['currentAmount'] / goal['targetAmount']) * 100;
        if (progress >= 80) {
          title = '⚠️ Expense Goal Alert!';
          body = 'You\'ve used ${progress.toStringAsFixed(0)}% of your ${goal['name']} limit';
          break;
        }
      }
    }
    
    await _localNotifications.show(
      4,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Goal Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Expense goal near limit alert
  Future<void> showExpenseGoalAlert(String goalName, double currentAmount, double targetAmount) async {
    try {
      double progress = (currentAmount / targetAmount) * 100;
      String title;
      String body;
      
      if (progress >= 100) {
        title = '🚨 Goal Limit Exceeded!';
        body = 'You\'ve exceeded your $goalName limit by ${_formatCurrency(currentAmount - targetAmount)}';
      } else if (progress >= 90) {
        title = '⚠️ Almost at Limit!';
        body = 'You\'ve used ${progress.toStringAsFixed(0)}% of your $goalName limit';
      } else if (progress >= 80) {
        title = '💡 Getting Close';
        body = 'You\'ve used ${progress.toStringAsFixed(0)}% of your $goalName limit';
      } else {
        return; // Don't show notification if not close to limit
      }
      
      await _localNotifications.show(
        5,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Goal Alerts',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Expense goal alert sent: $title');
    } catch (e) {
      print('❌ Error showing expense goal alert: $e');
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Test notification method
  Future<void> showTestNotification() async {
    try {
      await _localNotifications.show(
        999,
        '🧪 Test Notification',
        'Notifications are working correctly!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Test Notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }
}