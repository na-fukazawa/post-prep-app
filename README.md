# post-prep-app

このリポジトリは、イベント告知を貼り付けて投稿用キャプションを生成する簡易な Flutter アプリの雛形です（個人利用向け）。

主な機能
- 生のイベント情報を貼り付け
- テンプレートベースでキャプション生成
- コピー、共有（シェア）、下書き保存（ローカル）

依存パッケージ
- share_plus
- shared_preferences

ローカルでの実行手順
1. Flutter がインストールされていることを確認します（flutter doctor）。
2. プロジェクトディレクトリで依存関係を取得します。

```bash
cd /Users/naokif/post-prep-app/post-prep-app
flutter pub get
```

3. 実機またはエミュレータを接続して実行します。

```bash
flutter run
```

注意
- このアプリは自動投稿や外部 API を使いません。ローカル保存のみです。
