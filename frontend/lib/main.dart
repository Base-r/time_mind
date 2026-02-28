import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:time_mind/features/home/presentation/home.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Info',
      home: Scaffold(
        appBar: AppBar(title: Text('Информация об устройстве')),
        body: FutureBuilder<Map<String, String>>(
          future: getDeviceInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final data = snapshot.data ?? {};
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (data['browser'] != null)
                    Text(
                      'Браузер: ${data['browser']} ${data['browserVersion'] ?? ''}',
                      style: TextStyle(fontSize: 22),
                    ),
                  if (data['os'] != null)
                    Text(
                      'Устройство: ${data['os']} ${data['osVersion'] ?? ''}',
                      style: TextStyle(fontSize: 20),
                    ),
                  if (data['deviceModel'] != null)
                    Text(
                      'Модель: ${data['deviceModel']}',
                      style: TextStyle(fontSize: 18),
                    ),
                ],
              ),
            );
          },
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   onTap: (value) => PageRouteBuilder(
        //     pageBuilder: {},
        //     transitionsBuilder: TransitionBuilder(context: ),
        //   ),

        //   items: [
        //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Главная"),
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.settings),
        //       label: "Настройки",
        //     ),
        //   ],
        // ),
      ),
    );
  }
}

// ... (предыдущие импорты и код класса MyApp остаются без изменений)

Future<Map<String, String>> getDeviceInfo() async {
  final result = <String, String>{};

  if (kIsWeb) {
    final browserInfo = _getBrowserInfo();
    result['browser'] = browserInfo['name']!;
    result['browserVersion'] = browserInfo['version']!;

    final osInfo = _getWebOSInfo();
    result['os'] = osInfo['name']!;
    result['osVersion'] = osInfo['version']!;
    result['deviceModel'] = _getPrettyDeviceModel(_getWebDeviceModel());
  } else {
    result['os'] = _getDeviceOS();
    result['osVersion'] = await _getNativeOSDetails();
    result['deviceModel'] = await _getPrettyNativeDeviceModel();
    result['browser'] = 'Native App';
  }
  return result;
}

String _getPrettyDeviceModel(String rawModel) {
  // Словарь известных моделей
  final knownModels = {
    'sm-a705': 'Samsung Galaxy A70',
    'sm-g950': 'Samsung Galaxy S8',
    'sm-g955': 'Samsung Galaxy S8+',
    'sm-g960': 'Samsung Galaxy S9',
    'sm-g965': 'Samsung Galaxy S9+',
    'sm-g970': 'Samsung Galaxy S10e',
    'sm-g973': 'Samsung Galaxy S10',
    'sm-g975': 'Samsung Galaxy S10+',
    'iphone12,1': 'iPhone 11',
    'iphone12,3': 'iPhone 11 Pro',
    'iphone12,5': 'iPhone 11 Pro Max',
    'iphone13,1': 'iPhone 12 mini',
    'iphone13,2': 'iPhone 12',
    'iphone13,3': 'iPhone 12 Pro',
    'iphone13,4': 'iPhone 12 Pro Max',
  };

  // Приводим к нижнему регистру для сравнения
  final lowerModel = rawModel.toLowerCase();

  // Ищем в словаре известных моделей
  for (final entry in knownModels.entries) {
    if (lowerModel.contains(entry.key)) {
      return entry.value;
    }
  }

  // Если модель не найдена в словаре, возвращаем оригинальное значение
  return rawModel;
}

Future<String> _getPrettyNativeDeviceModel() async {
  final rawModel = await _getNativeDeviceModel();
  return _getPrettyDeviceModel(rawModel);
}

String _getWebDeviceModel() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();

  // Для iOS устройств
  if (userAgent.contains('iphone')) {
    final match = RegExp(r'iphone(\d+,\d+)').firstMatch(userAgent);
    return match?.group(1) ?? 'iPhone';
  }
  if (userAgent.contains('ipad')) {
    final match = RegExp(r'ipad(\d+,\d+)').firstMatch(userAgent);
    return match?.group(1) ?? 'iPad';
  }
  if (userAgent.contains('ipod')) return 'iPod Touch';

  // Для Android устройств
  final androidModelMatch = RegExp(
    r'android.*;\s([^;)]+)\)',
  ).firstMatch(userAgent);
  if (androidModelMatch != null) {
    return androidModelMatch.group(1)?.replaceAll('_', ' ') ?? 'Android Device';
  }

  return 'Unknown Device';
}

Future<String> _getNativeDeviceModel() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Для Android возвращаем модель без производителя (он часто дублируется)
      return androidInfo.model;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine ?? 'iOS Device';
    }
    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.computerName ?? 'Windows Device';
    }
    if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return macInfo.computerName ?? 'Mac Device';
    }
    if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.name ?? 'Linux Device';
    }
  } catch (e) {
    return 'Unknown Device';
  }

  return 'Unknown Device';
}

// ... (остальные функции остаются без изменений)

// Веб-версия: Получение модели устройства из User-Agent

// Нативная версия: Получение модели устройства

Map<String, String> _getBrowserInfo() {
  final userAgent = html.window.navigator.userAgent;
  final browser = _detectBrowser(userAgent);
  final version = _getBrowserVersion(userAgent, browser);
  return {'name': browser, 'version': version};
}

Map<String, String> _getWebOSInfo() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return _detectOS(userAgent);
}

String _getDeviceOS() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  return 'Unknown OS';
}

Future<String> _getNativeOSDetails() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.release ?? 'Unknown';
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.systemVersion ?? 'Unknown';
    }
    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.buildNumber.toString();
    }
    if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return macInfo.osRelease ?? 'Unknown';
    }
    if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.version ?? 'Unknown';
    }
    return 'Unknown OS';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

String _detectBrowser(String userAgent) {
  userAgent = userAgent.toLowerCase();

  // Проверяем браузеры в порядке специфичности
  if (userAgent.contains('yabrowser')) return 'Yandex Browser';
  if (userAgent.contains('edg')) return 'Edge';
  if (userAgent.contains('opr')) return 'Opera';
  if (userAgent.contains('firefox')) return 'Firefox';
  if (userAgent.contains('chrome') && !userAgent.contains('chromium')) {
    return 'Chrome';
  }
  if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
    return 'Safari';
  }
  if (userAgent.contains('vivaldi')) return 'Vivaldi';
  if (userAgent.contains('samsungbrowser')) return 'Samsung Browser';

  return 'Unknown Browser';
}

String _getBrowserVersion(String userAgent, String browser) {
  try {
    final regexMap = {
      'Yandex Browser': r'YaBrowser\/([\d.]+)',
      'Chrome': r'Chrome\/([\d.]+)',
      'Firefox': r'Firefox\/([\d.]+)',
      'Safari': r'Version\/([\d.]+)',
      'Edge': r'Edg\/([\d.]+)',
      'Opera': r'OPR\/([\d.]+)',
      'Vivaldi': r'Vivaldi\/([\d.]+)',
      'Samsung Browser': r'SamsungBrowser\/([\d.]+)',
    };

    final regex = RegExp(regexMap[browser] ?? '');
    final match = regex.firstMatch(userAgent);
    return match?.group(1) ?? 'Unknown version';
  } catch (e) {
    return 'Unknown version';
  }
}

Map<String, String> _detectOS(String userAgent) {
  if (userAgent.contains('windows')) {
    return {
      'name': 'Windows',
      'version': userAgent.contains('windows nt 10')
          ? '10'
          : userAgent.contains('windows nt 11')
          ? '11'
          : 'Unknown',
    };
  } else if (userAgent.contains('mac os')) {
    try {
      return {
        'name': 'macOS',
        'version': userAgent
            .split('mac os x ')[1]
            .split(')')[0]
            .replaceAll('_', '.'),
      };
    } catch (e) {
      return {'name': 'macOS', 'version': 'Unknown'};
    }
  } else if (userAgent.contains('linux')) {
    return {'name': 'Linux', 'version': 'Unknown'};
  } else if (userAgent.contains('android')) {
    try {
      return {
        'name': 'Android',
        'version': userAgent.split('android ')[1].split(';')[0],
      };
    } catch (e) {
      return {'name': 'Android', 'version': 'Unknown'};
    }
  } else if (userAgent.contains('iphone') || userAgent.contains('ipad')) {
    try {
      return {
        'name': 'iOS',
        'version': userAgent
            .split('os ')[1]
            .split(' like')[0]
            .replaceAll('_', '.'),
      };
    } catch (e) {
      return {'name': 'iOS', 'version': 'Unknown'};
    }
  }
  return {'name': 'Unknown', 'version': 'Unknown'};
}
