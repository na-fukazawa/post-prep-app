class XOAuthConfig {
  static const String clientId = 'eWlNTTRSdjcyWlZXY0lBQWRRQXc6MTpjaQ';
  static const String redirectUri = 'postprep://oauth/callback';
  static const String authorizeEndpoint = 'https://x.com/i/oauth2/authorize';
  static const String tokenEndpoint = 'https://api.x.com/2/oauth2/token';
  static const String apiBase = 'https://api.x.com/2';
  static const String mediaUploadEndpoint = 'https://upload.twitter.com/1.1/media/upload.json';

  static const List<String> scopes = <String>[
    'tweet.read',
    'tweet.write',
    'users.read',
    'offline.access',
  ];
}
