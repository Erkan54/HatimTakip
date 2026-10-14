import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String friendly(Object error) {
  debugPrint('Hatim Halkası işlem hatası: $error');
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Bad state: |Invalid argument\(s\): )'), '');
  }
  if (error is FirebaseException && error.code == 'resource-exhausted') {
    return 'Bugünkü ücretsiz kullanım sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin.';
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Bu işlem için yetkiniz yok veya oturum süresi doldu.';
  }
  return 'İşlem yapılamadı. İnternetinizi kontrol edip tekrar deneyin.';
}

void notice(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(friendly(error))));
}
