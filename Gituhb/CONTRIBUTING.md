# Contributing - 貢献ガイド

このプロジェクトへの貢献をお考えいただきありがとうございます。以下は社内チーム向けの開発ガイドです。

## 基本フロー

1. **Issue を確認 / 作成**
   ```bash
   # 割り当てられた Issue を確認、または新しい Issue を作成
   ```

2. **リポジトリをクローン**
   ```bash
   git clone git@github.com:ORG/REPO.git
   cd REPO
   ```

3. **develop を最新化してブランチを作成**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/ISSUE-123-short-desc
   ```

4. **コードを編集し、小さい単位でコミット**
   ```bash
   git add .
   git commit -m "feat(scope): short description (#123)"
   ```

5. **ローカルで lint / test を実行**
   ```bash
   npm run lint
   npm test
   ```

6. **push して PR を作成**
   ```bash
   git push -u origin feature/ISSUE-123-short-desc
   ```
   - GitHub 上で PR を作成（PULL_REQUEST_TEMPLATE を埋める）

7. **レビュー対応**
   - コメント指摘があれば修正 → commit → push

8. **マージ（レビュワーまたは管理者）**
   - CI 成功 & 承認を得たら merge

## ブランチ命名規則

| タイプ | 命名例 | 用途 |
|------|------|------|
| Feature | feature/ISSUE-123-add-login | 新機能 |
| Bug fix | fix/ISSUE-123-fix-npe | バグ修正 |
| Chore | chore/ISSUE-123-update-deps | メンテナンス |
| Docs | docs/update-readme | ドキュメント |
| Quick fix | quickfix/typo-fix | Issue 作成不要な小修正 |

## コミットメッセージ規約（Conventional Commits）

```
<type>(<scope>): <subject>
```

- **type**: feat, fix, docs, style, refactor, perf, test, chore
- **scope**: 影響を受けるモジュール/機能（省略可）
- **subject**: 短い説明（命令形）、72 文字以下

例:
- `feat(auth): add JWT login flow (#123)`
- `fix(api): correct status code on timeout error`
- `docs(readme): update installation instructions`

## PR の作り方

- **Base**: develop（通常）、main（release/hotfix の場合のみ）
- **Compare**: feature/... ブランチ
- **PR 本文**: PULL_REQUEST_TEMPLATE に沿って記載
- **頭に付記**: `Closes #ISSUE` で Issue を自動クローズ

## Excel（構成管理）の変更手順

```bash
# 編集前にロック
git lfs lock configs/excel/setting.xlsx

# 編集後、CSV に変換
python scripts/xlsx_to_csv.py configs/excel/setting.xlsx --out-dir configs/csv

# EXCEL_CHANGELOG.csv を更新
# コミット
git add configs/excel/setting.xlsx configs/csv/ configs/EXCEL_CHANGELOG.csv
git commit -m "chore(config): update setting.xlsx (Closes #123)"

# アンロック
git lfs unlock configs/excel/setting.xlsx
```

## レビュー基準

レビュワーが確認するポイント:

- ✓ CI（Jenkins）が成功しているか
- ✓ 変更の意図が明確か
- ✓ テストケースが追加されているか
- ✓ セキュリティ懸念がないか（トークン / パスワード流出等）
- ✓ Excel 変更時に CSV / EXCEL_CHANGELOG が更新されているか
- ✓ ドキュメント更新が必要でないか

## ローカルのセットアップ

### Node.js（例）
```bash
npm ci                  # 依存関係をインストール
npm run lint            # Lint チェック
npm test                # テスト実行
npm run build           # ビルド
```

## 重要な注意事項

- **main / develop への直接 push は禁止** → PR で変更する
- **main / develop から直接ブランチを切らない** → develop が source になることを原則とする
- **リリース権限者** がタグ付けと本番デプロイを実施する
- **Excel 編集時は必ず `git lfs lock` を実行** する

質問や不明な点があれば、チーム内で相談してください。

ありがとうございます！