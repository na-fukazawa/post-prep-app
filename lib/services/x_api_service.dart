import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'x_auth_service.dart';
import 'x_oauth_config.dart';

class XApiException implements Exception {
  final String message;
  const XApiException(this.message);

  @override
  String toString() => message;
}

class XUser {
  final String id;
  final String username;
  final String name;
  final String? profileImageUrl;

  const XUser({
    required this.id,
    required this.username,
    required this.name,
    this.profileImageUrl,
  });
}

class XApiService {
  XApiService(this._authService);

  final XAuthService _authService;

  Future<XUser> lookupUserByUsername(String username) async {
    final token = await _requireToken();
    final sanitized = username.replaceAll('@', '').trim();
    if (sanitized.isEmpty) {
      throw const XApiException('ユーザー名が空です。');
    }
    final uri = Uri.parse('${XOAuthConfig.apiBase}/users/by/username/$sanitized').replace(
      queryParameters: <String, String>{
        'user.fields': 'profile_image_url,name',
      },
    );
    final json = await _getJson(uri, token);
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const XApiException('ユーザーが見つかりませんでした。');
    }
    return XUser(
      id: data['id'] as String,
      username: data['username'] as String? ?? sanitized,
      name: data['name'] as String? ?? sanitized,
      profileImageUrl: data['profile_image_url'] as String?,
    );
  }

  Future<XUser> getCurrentUser({String? accessToken}) async {
    final token = accessToken ?? await _requireToken();
    final uri = Uri.parse('${XOAuthConfig.apiBase}/users/me').replace(
      queryParameters: <String, String>{
        'user.fields': 'profile_image_url,name,username',
      },
    );
    final json = await _getJson(uri, token);
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const XApiException('ユーザー情報を取得できませんでした。');
    }
    return XUser(
      id: data['id'] as String,
      username: data['username'] as String? ?? '',
      name: data['name'] as String? ?? '',
      profileImageUrl: data['profile_image_url'] as String?,
    );
  }

  Future<String> createPost({
    required String text,
    required List<String> imageUrls,
    required List<String> taggedUserIds,
  }) async {
    final token = await _requireToken();
    final mediaIds = await _uploadImages(imageUrls, token);
    final payload = <String, dynamic>{
      if (text.trim().isNotEmpty) 'text': text.trim(),
      if (mediaIds.isNotEmpty)
        'media': <String, dynamic>{
          'media_ids': mediaIds,
          if (taggedUserIds.isNotEmpty) 'tagged_user_ids': taggedUserIds.take(10).toList(),
        },
    };
    if (payload.isEmpty) {
      throw const XApiException('投稿内容が空です。');
    }
    final uri = Uri.parse('${XOAuthConfig.apiBase}/tweets');
    final json = await _postJson(uri, token, payload);
    final data = json['data'] as Map<String, dynamic>?;
    final id = data?['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const XApiException('投稿結果が取得できませんでした。');
    }
    return id;
  }

  Future<String> _requireToken() async {
    final token = await _authService.getValidAccessToken();
    if (token == null) {
      throw const XApiException('Xの認証が必要です。');
    }
    return token;
  }

  Future<List<String>> _uploadImages(List<String> imageUrls, String token) async {
    if (imageUrls.isEmpty) return <String>[];
    final uploads = <String>[];
    for (final url in imageUrls.take(4)) {
      final bytes = await _loadImageBytes(url);
      if (bytes == null) continue;
      final mediaId = await _uploadImage(bytes, token);
      if (mediaId.isNotEmpty) {
        uploads.add(mediaId);
      }
    }
    return uploads;
  }

  Future<String> _uploadImage(Uint8List bytes, String token) async {
    final body = _encodeForm(<String, String>{
      'media_data': base64Encode(bytes),
      'media_category': 'tweet_image',
    });
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(XOAuthConfig.mediaUploadEndpoint));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');
      request.add(utf8.encode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw XApiException('画像アップロードに失敗しました: ${response.statusCode}');
      }
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final id = decoded['media_id_string'] as String?;
      if (id == null || id.isEmpty) {
        throw const XApiException('画像アップロード結果が不正です。');
      }
      return id;
    } on SocketException {
      throw const XApiException('ネットワークに接続できません。');
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _loadImageBytes(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (_isRemote(trimmed)) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(trimmed));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) return null;
        return await consolidateHttpClientResponseBytes(response);
      } finally {
        client.close(force: true);
      }
    }
    final file = File(trimmed);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  bool _isRemote(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String token) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw XApiException('X API 取得に失敗しました: ${response.statusCode}');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } on SocketException {
      throw const XApiException('ネットワークに接続できません。');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _postJson(Uri uri, String token, Map<String, dynamic> payload) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw XApiException('X API 投稿に失敗しました: ${response.statusCode}');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } on SocketException {
      throw const XApiException('ネットワークに接続できません。');
    } finally {
      client.close(force: true);
    }
  }

  String _encodeForm(Map<String, String> params) {
    return params.entries
        .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
  }
}
