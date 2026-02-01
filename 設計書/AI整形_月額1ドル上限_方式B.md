# AI整形 月額1ドル上限 方式B（usageトークン積算）

## 目的
- AI APIは使用する
- 月1ドルを超えない（超過は必ず防ぐ）
- できるだけAPI通信を発生させない
- 予算超過時は「メッセージ表示 + テンプレート整形を返す」

## 前提
- モデル: gpt-5-mini
- 月次区切り: UTC月初
- OpenAI側の上限設定は $1.00
- サーバー側でさらに厳密にガードする

## 単価（gpt-5-mini）
- 入力: $0.25 / 1M tokens
- キャッシュ入力: $0.025 / 1M tokens
- 出力: $2.00 / 1M tokens

## コスト計算式
```
billable_input = input_tokens - cached_tokens
cost = billable_input/1e6 * 0.25
     + cached_tokens/1e6 * 0.025
     + output_tokens/1e6 * 2.00
```

## 予算ガード
- BUDGET_USD = 1.00
- BUDGET_GUARD = 0.95（バッファ。0.95で停止）
- UTCの YYYY-MM を月キーにする

## 保存先（推奨）
- サーバー側 SQLite 1ファイル
- テーブル例:
  - usage_monthly(month TEXT PRIMARY KEY, cost_usd REAL, updated_at)
  - format_cache(key TEXT PRIMARY KEY, formatted TEXT, created_at)

## 処理フロー
1. リクエスト到着
2. キャッシュキーを生成
   - key = hash(raw + title + template + model + prompt_version)
3. キャッシュ存在 → 即返却（API呼ばない）
4. 月額コストが BUDGET_GUARD 以上 →
   - 予算超過メッセージ + テンプレ整形を返す（API呼ばない）
5. OpenAI APIへ送信
6. usageからコスト計算し月額に加算
7. AI整形結果を返す（キャッシュ保存）

## API通信削減の工夫
- キャッシュ（同一入力なら再実行しない）
- UI側で「入力が変わらない限り再実行しない」
- max_output_tokensの制限
- 不要な前文/署名/引用を削除して入力トークン削減
- prompt caching（1024トークン以上で効果）

## 予算超過時の返却仕様
- サーバーは「budget_exceeded」ステータスを返す
- アプリは
  - 「今月のAI予算に達したため、テンプレート整形で表示します」
  - テンプレ整形結果を表示

## 注意
- OpenAI側の $1 上限は最後の安全装置
- サーバー側で厳密ガードすることで超過リスクを極小化
