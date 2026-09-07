import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const _fileName = 'lichviet_data.json';
const _mimeType = 'application/json';
const _driveScope = 'https://www.googleapis.com/auth/drive.appdata';

class DriveService {
  static final _googleSignIn = GoogleSignIn(scopes: [_driveScope]);

  static Future<GoogleSignInAccount> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Đăng nhập bị huỷ.');
    return account;
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  static Future<GoogleSignInAccount?> get currentUser async =>
      _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

  static Future<drive.DriveApi> _api(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    return drive.DriveApi(_AuthClient(headers));
  }

  /// Upload (create or update) the data file in appDataFolder.
  static Future<void> upload(GoogleSignInAccount account, Map<String, dynamic> data) async {
    final api = await _api(account);
    final content = jsonEncode(data);
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: _mimeType);

    final existing = await _findFile(api);
    if (existing != null) {
      await api.files.update(drive.File(), existing, uploadMedia: media);
    } else {
      final meta = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(meta, uploadMedia: media);
    }
  }

  /// Download the data file from appDataFolder. Returns null if not found.
  static Future<Map<String, dynamic>?> download(GoogleSignInAccount account) async {
    final api = await _api(account);
    final fileId = await _findFile(api);
    if (fileId == null) return null;

    final media = await api.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    return jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
  }

  static Future<String?> _findFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$_fileName'",
      $fields: 'files(id)',
    );
    return list.files?.firstOrNull?.id;
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _inner = http.Client();
  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
