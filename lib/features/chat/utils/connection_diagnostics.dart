import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionDiagnostics {
  static Future<Map<String, dynamic>> runDiagnostics(String serverUrl) async {
    final results = <String, dynamic>{};

    // 检查网络连接类型
    try {
      final connectivity = await Connectivity().checkConnectivity();
      results['networkType'] = connectivity.toString();
      results['hasNetwork'] = connectivity != ConnectivityResult.none;
    } catch (e) {
      results['networkTypeError'] = e.toString();
    }

    // 从URL中提取主机名和端口
    Uri? uri;
    try {
      uri = Uri.parse(serverUrl);
      results['host'] = uri.host;
      results['port'] = uri.port;
      results['scheme'] = uri.scheme;
    } catch (e) {
      results['uriParseError'] = e.toString();
      return results;
    }

    // 尝试DNS解析
    try {
      final addresses = await InternetAddress.lookup(uri.host);
      results['dnsResolved'] = addresses.isNotEmpty;
      results['ipAddresses'] = addresses.map((addr) => addr.address).toList();
    } catch (e) {
      results['dnsError'] = e.toString();
    }

    // 尝试建立TCP连接
    if (uri.hasPort && uri.port > 0) {
      try {
        final socket = await Socket.connect(uri.host, uri.port,
            timeout: Duration(seconds: 5));
        results['tcpConnected'] = true;
        socket.destroy();
      } catch (e) {
        results['tcpError'] = e.toString();
        results['tcpConnected'] = false;
      }
    }

    return results;
  }

  static String generateReport(Map<String, dynamic> diagnostics) {
    final buffer = StringBuffer();

    buffer.writeln('===== 连接诊断报告 =====');
    buffer.writeln('时间: ${DateTime.now()}');

    if (diagnostics.containsKey('networkType')) {
      buffer.writeln('网络类型: ${diagnostics['networkType']}');
    }

    if (diagnostics.containsKey('host')) {
      buffer.writeln('目标主机: ${diagnostics['host']}');
      buffer.writeln('端口: ${diagnostics['port']}');
      buffer.writeln('协议: ${diagnostics['scheme']}');
    }

    if (diagnostics.containsKey('dnsResolved')) {
      buffer.writeln('DNS解析: ${diagnostics['dnsResolved'] ? '成功' : '失败'}');
      if (diagnostics['dnsResolved']) {
        buffer.writeln('解析到IP: ${diagnostics['ipAddresses'].join(', ')}');
      }
    }

    if (diagnostics.containsKey('tcpConnected')) {
      buffer.writeln('TCP连接: ${diagnostics['tcpConnected'] ? '成功' : '失败'}');
      if (!diagnostics['tcpConnected'] && diagnostics.containsKey('tcpError')) {
        buffer.writeln('TCP错误: ${diagnostics['tcpError']}');
      }
    }

    if (diagnostics.containsKey('networkTypeError')) {
      buffer.writeln('获取网络类型错误: ${diagnostics['networkTypeError']}');
    }

    if (diagnostics.containsKey('uriParseError')) {
      buffer.writeln('URL解析错误: ${diagnostics['uriParseError']}');
    }

    if (diagnostics.containsKey('dnsError')) {
      buffer.writeln('DNS解析错误: ${diagnostics['dnsError']}');
    }

    buffer.writeln('========================');

    return buffer.toString();
  }
}
