# Git / GitHub 環境立ち上げ手順書（完成版・最終）

最終更新: 2026-03-01  
対象: Git/GitHub 初心者～中級者、チーム開発メンバー全員  
ブランチモデル: Git-flow（main / develop / feature / release / hotfix）  
ツール: SourceTree（Git クライアント）/ VS Code（エディタ）/ Jenkins（CI/CD）

---

## 序論

この手順書は、チーム開発を始める際に必要な「Git / GitHub の環境立ち上げ」から「日常の開発ワークフロー」「役割別の具体的操作」「Excel などの構成管理資料の安全な運用」までを、初心者でも迷わないようにまとめたものです。

**3つの重要なポイント**
1. **Issue 起点（ハイブリッド運用）**: 機能・バグは Issue を作ってからブランチを切る。ただし小さな修正（quickfix）は例外を認める。
2. **Git-flow ブランチ戦略**: main（本番安定）/ develop（統合）/ feature/release/hotfix（作業用）を使い分ける。
3. **CI/CD と品質**: Jenkins で PR ごとに自動テスト・lint を実行し、Branch Protection で安全性を担保する。

手順通りに進めれば、チームで安心して開発を始められます。

---

## 目次

1. 要約（推奨方針・全体像）
2. 事前にチームで決めること（決定事項リスト）
3. GitHub アカウント・セキュリティ設定（2FA / SSH / PAT）
4. ローカル環境セットアップ（Git / SourceTree / VS Code / Git LFS）
5. リポジトリ作成と初期ファイル（管理者向け詳細手順）
6. ブランチ戦略の詳細（Git-flow ルール）
7. 開発者の日常ワークフロー（SourceTree + VS Code での実際の操作）
8. PR 作成とレビュー（レビュワー��け具体手順）
9. リリース手順（リリース担当向け）
10. Git/GitHub 管理者の作業（Branch Protection / Jenkins 連携 / LFS 管理）
11. Excel（構成管理帳票）の安全な運用（Git LFS + CSV + 変更ログ）
12. 自動化と検証（GitHub Action / Jenkinsfile / スクリプト）
13. トラブルシューティング（よくある問題と対処）
14. チェックリスト（導入時・日常・リリース時）
15. 付録：テンプレートと実装例

---

## 1. 要約（推奨方針・全体像）

### ブランチ戦略
- **main**: 本番環境に常にデプロイ可能な安定ブランチ。タグでバージョン管理。
- **develop**: 次のリリース向け統合ブランチ。feature がここにマージされる。
- **feature/ISSUE-123-desc**: 個別の機能実装。develop から派生し、PR で develop にマージ。
- **release/x.y.z**: リリース準備用。develop から派生し、最終調整後 main と develop にマージ。
- **hotfix/x.y.z**: 本番バグ修正。main から派生し、修正後 main と develop にマージ。

### PR・レビュー運用
- すべての変更は PR ベース（main / develop への直接 push は禁止）。
- Jenkins で PR ごとに自動ビルド・テスト・lint を実行。
- Approval は 1〜2 人（チーム方針で決定）。
- CODEOWNERS でディレクトリごとの自動レビュワー割当。

### Issue 運用（ハイブリッド方式）
- 機能・バグ・タスク: Issue 作成 → ブランチ作成 → PR（本文に Closes #ISSUE）→ マージ → Issue 自動クローズ
- quickfix（小さな修正）: Issue 作成は省略可。PR に "quickfix: 理由" を記載。

### Excel（構成管理）
- Git LFS で .xlsx を管理（バイナリを差分管理できないため）。
- 編集時は `git lfs lock` でロック → 編集 → CSV に変換して差分化 → EXCEL_CHANGELOG.csv 更新 → commit → unlock。

---

## 2. 事前にチームで決めること（決定事項リスト）

以下を チーム内で合意して記録しておくことが重要です。

| 項目 | 推奨値 | 備考 |
|------|------|------|
| default ブランチ | main | develop への push は禁止 |
| 統合ブランチ | develop | main にマージされる直前 |
| ブランチ命名規則 | feature/ISSUE-123-short-desc | feature / fix / chore / docs など type を含める |
| コミット規約 | Conventional Commits | type(scope): subject の形式 |
| PR レビュー人数 | 1〜2 | 重大変更は多めに |
| マージ方式（feature→develop） | Squash and merge | 履歴を整理した状態で統合 |
| マージ方式（release→main） | Merge commit | リリース履歴を明確に |
| CI 必須チェック | lint, test, build | Jenkins ジョブ名を決める |
| リリース権限者 | Maintainer 指定 | 本番デプロイを実行する者 |
| Excel ロック運用 | 必須 | 編集時は git lfs lock を実行 |
| 構成ファイル保存場所 | /configs/excel/ | /configs/csv/ に自動生成 CSV も配置 |

---

## 3. GitHub アカウント・セキュリティ設定

### A. アカウント作成
1. https://github.com/ で Sign up
2. ユーザー名（小文字推奨）、メール、パスワードを設定
3. メール確認（Verify email address）

### B. 2段階認証（2FA）を有効化【推奨】
セキュリティを高めるため **必須** の推奨です。

**手順**
1. GitHub → 右上プロフィール → Settings
2. 左メニュー "Security" → "Two-factor authentication"
3. "Enable two-factor authentication" をクリック
4. TOTP アプリ（例: Google Authenticator / Microsoft Authenticator）をインストール → QR コードをスキャン
5. バックアップコード 1-off を安全に保存（メモ帳は避け、Password Manager などを使用）

### C. SSH 鍵生成と登録

**ローカルで鍵を生成（macOS / Linux / WSL / Git Bash）**

```bash
# ed25519 鍵を生成（推奨・最新セキュアな方式）
ssh-keygen -t ed25519 -C "you@example.com"

# パスフレーズ入力（空でも OK だが、セキュリティのため入力推奨）
# ~/.ssh/id_ed25519 に秘密鍵、~/.ssh/id_ed25519.pub に公開鍵が生成される

# 公開鍵をクリップボードにコピー
cat ~/.ssh/id_ed25519.pub | pbcopy  # macOS
# または
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard  # Linux
```

**GitHub に公開鍵を登録**
1. GitHub → Settings → SSH and GPG keys
2. "New SSH key" をクリック
3. Title: 例 "MacBook Pro (yamada)" （どのマシンかわかるように）
4. Key: 公開鍵の内容を貼る
5. "Add SSH key"

**接続確認**
```bash
ssh -T git@github.com
# Expected output: Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

### D. Personal Access Token（PAT）作成【CI/CD 用】

Jenkins などの CI/CD から GitHub にアクセスするために必要です。

**手順**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token"
3. Note: 例 "Jenkins CI for REPO"
4. Expiration: 90 days 推奨（定期更新を習慣化）
5. Select scopes:
   - `repo` （Full control of private repositories）
   - `admin:repo_hook` （Full control of repository hooks）
   - `read:user` （Read user data）
6. "Generate token" → **トークンをコピーして安全に保存** （このページを閉じると二度と表示されません）

### E. GPG 署名（任意・高セキュリティチーム向け）

チームでコミット署名を必須にする場合は、GPG 鍵を設定します。

```bash
# GPG 鍵を生成（初回）
gpg --full-generate-key
# Key type: RSA and RSA / Keysize: 4096 を推奨

# 生成された鍵 ID を確認
gpg --list-secret-keys --keyid-format long

# Git に設定
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgSign true
```

詳細は GitHub Docs の「Signing commits」を参照。

---

## 4. ローカル環境セットアップ（Git / SourceTree / VS Code / Git LFS）

### A. Git インストール

**macOS**
```bash
brew install git
git --version  # 確認
```

**Ubuntu / Debian**
```bash
sudo apt update
sudo apt install git
git --version
```

**Windows**
- https://git-scm.com/download/win からインストーラをダウンロード
- インストーラを実行（Recommended Settings で OK）

### B. Git 初期設定

```bash
# ユーザー情報
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# エディタ（VS Code を使う場合）
git config --global core.editor "code --wait"

# Pull 時の設定（rebase vs merge）
git config --global pull.rebase false  # merge を推奨（チーム方針で変可）

# Credential helper（パスワード保存）
git config --global credential.helper manager-core  # Windows / macOS 推奨
```

確認:
```bash
git config --global --list
```

### C. SourceTree（GUI クライアント）セットアップ

**インストール**
- https://www.sourcetreeapp.com/ からダウンロード

**初期設定**

1. 起動時に Git のパスを指定
   - Embedded Git （推奨）または System Git
   - "Use Embedded Git" を選択

2. SSH 認証を設定
   - Preferences → Authentication → SSH Key（Path to OpenSSH key file）
   - Windows + PuTTY の場合: SSH Client を PuTTY (Plink) に設定し、Pageant で秘密鍵を登録

3. リポジトリをクローン
   - File → Clone / New
   - "Source URL": git@github.com:ORG/REPO.git
   - "Destination Path": クローン先
   - Clone

### D. VS Code（エディタ）セットアップ

**インストール**
- https://code.visualstudio.com/

**推奨拡張のインストール**
1. Extensions パネル（Ctrl+Shift+X / Cmd+Shift+X）で以下を検索＆インストール
   - **GitLens — Git supercharged**: Git 履歴・詳細表示
   - **ESLint**: JavaScript/TypeScript の lint
   - **Prettier - Code formatter**: コード整形
   - **EditorConfig for VS Code**: エディタ設定統一
   - **YAML**: GitHub Actions ワークフロー編集時に便利

**推奨設定 (settings.json)**
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },
  "git.ignoreLimitWarning": true
}
```

### E. Git LFS（Large File Storage）導入【Excel 管理必須】

**インストール**
```bash
# macOS
brew install git-lfs

# Ubuntu / Debian
sudo apt install git-lfs

# Windows
# git-lfs インストーラをダウンロード: https://git-lfs.com/
```

**初期化（各開発者が実行）**
```bash
git lfs install
```

**リポジトリで .xlsx を LFS で管理する設定（管理者が実行）**
```bash
cd REPO
git lfs track "configs/excel/*.xlsx"
git add .gitattributes
git commit -m "chore: track xlsx files with git-lfs"
git push origin develop
```

`.gitattributes` の内容:
```
configs/excel/*.xlsx filter=lfs diff=lfs merge=lfs -text
```

---

## 5. リポジトリ作成と初期ファイル配置（管理者向け詳細手順）

### A. Organization（組織）作成【チーム管理の場合】

1. GitHub → 右上プロフィール → "Your organizations"
2. "New organization"
3. Organization name, email, 支払いプランを設定
4. Create organization

### B. Team 作成

1. Organization → Teams → "New team"
2. Team name: 例 "Engineering", "Frontend", "Backend"
3. 各 Team にメンバーを追加（Invite to team）
4. Repository access: Admin / Write / Read を設定

### C. リポジトリ作成

1. Organization → Repositories → "New"
2. Repository name: 例 "project-name"
3. Description: 簡潔にプロジェクト説明
4. Choose visibility: **Private**（社内）or **Public**（OSS）
5. Initialize repository:
   - Add a README file: チェック（初期説明を後で書く）
   - Add .gitignore: 言語に合わせて選択（例: Node, Python）
   - Choose a license: MIT など
6. "Create repository"

### D. Default branch を main に設定

1. リポジトリ → Settings → General
2. "Default branch" が `main` か確認。違えば変更（develop での PR 必須化のため）

### E. 初期ファイル配置（ローカルで追加してプッシュ）

**リポジトリをクローン**
```bash
git clone git@github.com:ORG/REPO.git
cd REPO
```

**develop ブランチを作成**
```bash
git checkout -b develop
git push -u origin develop
```

**テンプレートファイルを配置**
```bash
# ディレクトリ作成
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p scripts
mkdir -p configs/excel
mkdir -p configs/csv
mkdir -p hooks

# 後述の各テンプレート（.github/PULL_REQUEST_TEMPLATE.md 等）をここに配置
# (第 15 節を参照）

# コミット
git add .
git commit -m "chore: add github templates, scripts, and initial structure"
git push origin develop
```

---

## 6. ブランチ戦略の詳細（Git-flow ルール）

### ブランチの役割と命名

| ブランチ | 派生元 | マージ先 | 用途 |
|---------|------|---------|------|
| main | - | - | 本番環境、常に安定。タグでバージョン管理 |
| develop | - | - | 統合ブランチ。feature からの PR 受け入れ |
| feature/ISSUE-123-desc | develop | develop | 新機能実装。PR で develop にマージ |
| fix/ISSUE-123-desc | develop | develop | バグ修正。feature と同じ手順 |
| release/x.y.z | develop | main, develop | リリース準備。最終調整後 main/develop にマージ |
| hotfix/x.y.z | main | main, develop | 本番バグ修正。緊急対応ブランチ |

### マージポリシー（��要）

| マージ元 → マージ先 | マージ方式 | 理由 |
|-----------------|---------|------|
| feature / fix → develop | Squash and merge | 履歴を整理し develop の履歴を簡潔に |
| release → main | Merge commit | リリースのマイルストーンを明確に |
| hotfix → main | Merge commit | 緊急対応をログに残す |
| main → develop | Merge commit | 本番変更を統合ブランチに反映 |

### タグ付与（リリース時）

```bash
git checkout main
git pull origin main
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
```

---

## 7. 開発者の日常ワークフロー（SourceTree + VS Code での実際の操作）

### ステップ 1: Issue 確認・作成

**やること**
- GitHub → Issues で担当の Issue を確認
- Issue の「Acceptance Criteria」（受入条件）を読んで理解→不要
- 不明な点があればコメント欄で質問

### ステップ 2: ブランチ作成

**GUI (SourceTree)**
- SourceTree を起動し、対象リポジトリを開く
- 上部メニューの 「Fetch」 をクリックし、リモートの最新状態を取得
- 左パネルの 「Remotes → origin → develop」 を右クリック
- ※ローカルに develop がない場合はここに表示される
- 「ブランチをチェックアウト」 または
「新しいローカルブランチを作成」 をクリック
- これでローカル develop が作成され、develop に切り替わる
- 上部の 「Branch」 ボタン → 「New Branch」 をクリック
- Branch name に以下の形式で入力
    feature/ISSUE-123-short-desc
- 「Create Branch」をクリック
- 自動で新しい feature ブランチにチェックアウトされる

**またはコマンド**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/ISSUE-123-short-desc
```

### ステップ 3: VS Code で作業

1. VS Code でプロジェクトフォルダを開く
2. 機能を実装
3. 小さい単位で commit（SourceTree で行う）

### ステップ 4: コミット（SourceTree）

**GUI**
1. SourceTree で対象ファイルを右クリック → "Stage File"（または左下の "Stage all"）
2. 下部の "Commit message" に Conventional Commits 形式で記載
   - 例: `feat(auth): add login flow (#123)`
3. "Commit" をクリック

**コマンド**
```bash
git add .
git commit -m "feat(auth): add login flow (#123)"
```

### ステップ 5: Excel（構成帳票）を変更する場合

**LFS ロック**
```bash
git lfs lock configs/excel/setting.xlsx
```

**編集**
- Excel を開いて編集

**CSV 差分化**
```bash
# Python スクリプトで xlsx を CSV に変換（自動生成）
python scripts/xlsx_to_csv.py configs/excel/setting.xlsx --out-dir configs/csv

# EXCEL_CHANGELOG.csv を更新
# 形式: file,version,date,author,issue,summary,commit
# 例: configs/excel/setting.xlsx,v1.0.1,2026-03-02,yamada,#123,"Update timeout","abc1234"
```

**コミット**
```bash
git add configs/excel/setting.xlsx configs/csv/setting__Sheet1.csv configs/EXCEL_CHANGELOG.csv
git commit -m "chore(config): update setting.xlsx (Closes #123)"
```

**アンロック**
```bash
git lfs unlock configs/excel/setting.xlsx
```

### ステップ 6: Push & PR 作成

**Push（SourceTree）**
1. "Push" ボタン
2. "Set upstream" にチェック→不要
3. "Push" をクリック → feature ブランチがリモートに作成される

**PR 作成（GitHub Web）**
1. リポジトリページを開く
2. "Compare & pull request" ボタンが自動で表示される（push 直後）
3. Base: `develop`、Compare: `feature/ISSUE-123-...` を確認
4. PR タイトル: 例 `feat(auth): Add login flow (#123)`
5. PR 本文: PULL_REQUEST_TEMPLATE.md に沿って以下を記載
   - 概要（何をしたか）
   - 関連チケット: `Closes #123`（Issue を自動クローズする記法）
   - 変更内容（箇条書き）
   - チェックリスト（実施内容に ✓ を入れる）
6. Reviewers / Labels / Projects を設定
7. "Create pull request"

### ステップ 7: レビュー・修正

**レビューコメント対応**
1. PR ページを見てレビューコメントを確認
2. ローカルで修正
3. commit → push （PR は自動更新される）
4. GitHub コメントに "Re-requesting review" をしてレビュワーに通知

### ステップ 8: マージ（レビュワーまたは管理者が実施）

**CI（Jenkins）が成功 & レビュー承認を得たら**
1. GitHub → PR ページ
2. Merge ボタン → マージ方式を選択
   - feature → develop の場合: "Squash and merge"
3. "Confirm squash and merge"
4. PR は自動で closed、Issue は自動で closed（Closes # のため）

### ステップ 9: ローカルクリーンアップ

**PR マージ後**
```bash
git checkout develop
git pull origin develop

# ローカルブランチ削除
git branch -d feature/ISSUE-123-short-desc

# リモートブランチ削除
git push origin --delete feature/ISSUE-123-short-desc
```

---

## 8. PR 作成とレビュー（レビュワー向け具体手順）

### レビューの流れ

**1) PR をクリックして開く**
- GitHub → Pull requests → 対象 PR を開く
- PR 本文を読む（目的・説明を理解）

**2) CI（Jenkins）ステータスを確認**
- PR 下部の Checks セクション
- Jenkins のビルド結果が✓（success）か確認
- ❌ の場合はマージできない（作成者に修正を依頼）

**3) コード diff を確認**
- "Files changed" タブをクリック
- 各ファイルの diff を確認
- 必要に応じてコメント追加（右端の + をクリック）


**6) 承認またはコメント**
- 問題なければ "Approve"（右上の Review button）
- 修正が必要なら "Request changes" で指摘内容を記載

**7) マージ権限者がマージ**
- Approve が必要数集まり CI が成功したら、マージ権限者がマージボタンをクリック


こうすると、内側の ```sh が壊れずに全文を 1 つの md ブロックとして保持できます。

---

# ✅ **今度こそ、完全に「全文がひとつの .md コードブロック」に収まった正しい形式**

以下は **フェンス 4 本（````）で囲んだ完全版**です。  
これなら絶対に壊れません。

---

````md
# 8. PR 作成とレビュー手順（レビュワー + 開発者）

---

## 🔍 レビューの流れ（レビュワー）

### **1) PR をクリックして開く**
- GitHub → Pull requests → 対象 PR を開く
- PR 本文（概要・目的・変更内容）を確認する

---

### **2) CI（Jenkins）ステータスを確認**
- PR 下部の **Checks** セクションを確認
- Jenkins が **✓ success** になっているか確認
- ❌ の場合はマージ不可  
  → 作成者に修正依頼（コメント or Request changes）

---

### **3) コード diff を確認**
- 上部タブ **「Files changed」** をクリック
- 変更されたファイルの diff を確認

#### ▼ コメントの付け方（詳細）
1. コメントしたい行にカーソルを合わせる  
2. 行番号の右側に **「＋」** が表示される  
3. 「＋」をクリックするとコメント入力欄が開く  
4. コメントを入力  
5. 以下のいずれかを選択  
   - **Add single comment**（単発コメント）  
   - **Start a review**（複数コメントをまとめてレビュー）

#### ▼ ファイル全体へのコメント
- diff 上部の **「Add a general comment」** から追加可能

---

### **4) レビューの提出**
右上の **「Review changes」** をクリックし、以下から選択：

- **Approve**  
  → 問題なし。マージ可能
- **Comment**  
  → コメントのみ。承認でも却下でもない
- **Request changes**  
  → 修正が必要。マージ不可（ブランチ保護ルールがある場合）

---

## 🛠 修正が必要な場合（開発者側の操作）

レビュワーが **Request changes** またはコメントで修正を依頼した場合、  
PR 作成者（開発者）は以下の手順で対応する。

---

### **① ローカルで feature ブランチをチェックアウト**
```sh
git checkout feature/ISSUE-123-short-desc
```
（SourceTree なら左パネルのブランチをダブルクリック）

---

### **② 指摘内容を修正**
- コード修正  
- コメント対応  
- テスト修正  
- Lint 修正など

---

### **③ 修正内容をコミット**
```sh
git add .
git commit -m "fix: レビュー指摘対応"
```

---

### **④ リモートへ push**
```sh
git push
```

push すると PR に自動で反映される。

---

### **⑤ CI（Jenkins）が再実行される**
- 修正後のコードで Jenkins が自動再実行
- success になるまで待つ
- ❌ の場合は再度修正

---

### **⑥ レビュワーが再レビュー**
- 修正内容を確認
- 問題なければ **Approve**

---

## 🚀 7) マージ権限者がマージ

### ▼ マージ条件
- 必要な Approve が揃っている  
- CI が success  
- コンフリクトなし  

### ▼ feature → develop の場合（推奨）
**Squash and merge**  
→ PR 全体を 1 コミットにまとめて develop に取り込む

---
---

## 9. リリース手順（リリース担当向け）
SourceTree を使ったリリース作業の手順です。  
release ブランチの作成、CHANGELOG 更新、バージョン更新までを含みます。



# 9. リリース手順（リリース担当向け・タグ運用版）

本手順は CHANGELOG を使用せず、**Git タグを公式なリリース情報**として扱う運用です。

---

## 1) Release ブランチ作成

### ▼ SourceTree 操作
1. 左パネルで **develop** をダブルクリック（チェックアウト）
2. 上部メニュー **Fetch**
3. 上部メニュー **Pull**（origin/develop を最新化）
4. 上部メニュー **Branch** をクリック  
   Branch name に以下を入力  
   ```
   release/1.2.0
   ```
5. 「Create Branch」
6. 自動で release/1.2.0 に切り替わる

---

## 2) リリース用の不要フォルダ削除（必要な場合）

### ▼ 手動で削除するフォルダ一覧（例）
- `/docs/dev-only`
- `/local-config`
- `/tmp`

### ▼ SourceTree 操作
1. 左パネルでフォルダを右クリック → **削除**
2. 「ファイルステータス」で削除が表示される
3. コミットメッセージ  
   ```
   chore(release): remove dev-only folders
   ```
4. Commit → Push

---

## 3) （任意）不要行削除パッチの適用

特定行だけ削除したい場合は、事前に作成したパッチを適用する。

### ▼ パッチ適用（CLI）
```
git apply 0001-remove-debug-lines.patch
```

### ▼ その後
SourceTree の「ファイルステータス」に差分が出るので Commit → Push。

---

## 4) 動作確認（ステージング / QA）

release ブランチをデプロイして動作確認を行う。

---

## 5) main へマージ（リリース確定）

### ▼ SourceTree 操作
1. 左パネルで **main** をダブルクリック（チェックアウト）
2. 上部メニュー **Merge**
3. マージ元に **release/1.2.0** を選択
4. 「OK」  
5. 問題なければ Commit → Push

---

## 6) タグ付け（リリースの公式記録）

### ▼ SourceTree 操作
1. main にいる状態で、上部メニュー **Tag**
2. Tag name に以下を入力  
   ```
   v1.2.0
   ```
3. Message（任意）  
   ```
   Release 1.2.0
   ```
4. 「Create Tag」
5. Push（タグにチェックを入れる）

---

## 7) develop へ反映（release の変更を戻す）

release ブランチで削除したフォルダや修正を develop に戻す。

### ▼ SourceTree 操作
1. develop をチェックアウト
2. 上部メニュー **Merge**
3. マージ元に **main** を選択
4. 「OK」  
5. Commit → Push

---

## 8) release ブランチの削除（任意）

GitHub または SourceTree で release ブランチを削除する。

---

# ✔ リリースの最終成果物

- main にリリース内容が反映されている  
- タグ `v1.2.0` が付いている  
- develop にも反映済み  
- 不要フォルダは release だけから除外されている  

これでリリース完了。

---

---

## 🔧 リリース前の準備

---

## 1) Release ブランチ作成（SourceTree）

### ① develop を最新化
1. 左パネルの **Branches → develop** をダブルクリック（チェックアウト）
2. 上部メニューの **Fetch** をクリック
3. 上部メニューの **Pull** をクリック  
   → 「origin / develop」を選択して最新化

---

### ② release ブランチを作成
1. 上部メニューの **Branch** ボタンをクリック
2. Branch name に以下を入力  
   ```
   release/1.2.0
   ```
3. 「Create Branch」をクリック  
4. 自動で release/1.2.0 にチェックアウトされる

---

### ③ リモートへ push
1. 上部メニューの **Push** をクリック
2. 「release/1.2.0」にチェックを入れる
3. 「Track remote branch（リモート追跡）」にチェック
4. 「Push」をクリック



# リリース時の不要フォルダ・不要行削除運用ガイド

本ドキュメントでは、以下の要件を満たすための運用方法をまとめる。

- develop には必要なフォルダがある  
- しかし release ブランチには含めたくない  
- さらに、特定のファイルの特定行だけ削除したい場合もある  
- パッチ方式で効率化したい  

---

# 1. 基本方針

最も安全で現実的な方法は以下の 2 つ：

## ✔ 方法 A：release ブランチ作成後に不要フォルダを削除する  
（SourceTree で右クリック → 削除 → コミット）

## ✔ 方法 B：不要フォルダ削除や特定行削除を「パッチ化」して自動適用する  
（毎回同じ削除を自動化できる）

どちらも develop には影響せず、release ブランチだけに反映される。

---

# 2. 方法 A：release ブランチ作成後に削除するフォルダ一覧（固定化）

release ブランチを作成したら、以下のフォルダを削除する：

- `/docs/dev-only`
- `/local-config`
- `/tmp`

## ▼ SourceTree 操作
1. release ブランチにチェックアウト  
2. 左パネルでフォルダを右クリック  
3. 「削除」を選択  
4. 「ファイルステータス」で削除が表示される  
5. コミットメッセージ例：  
   ```
   chore(release): remove dev-only folders
   ```
6. Commit → Push

---

# 3. 方法 B：パッチ方式で自動化する

## ▼ 1. 一度だけ「削除コミット」を作る
release ブランチで不要フォルダを削除し、コミットする。

例：
```
chore(release): remove dev-only folders
```

## ▼ 2. そのコミットをパッチ化する
```
git format-patch -1 <コミットID>
```

これで以下のようなパッチファイルが生成される：

```
0001-remove-dev-folders.patch
```

## ▼ 3. 次回以降の release 作成時にパッチを適用
release ブランチを作成したら、以下を実行：

```
git apply 0001-remove-dev-folders.patch
```

これで毎回同じフォルダが自動で削除される。

---

# 4. 特定行だけ削除するパッチも可能

Git パッチは「行単位の差分」を記録するため、以下のような細かい変更も可能：

- 1 行だけ削除  
- 1 行だけ追加  
- 1 文字だけ変更  
- 特定のシンボル（例：`DEBUG_MODE = true`）を変更  
- 特定の if 文だけ削除  
- 特定の import だけ削除  
- コメント行だけ削除  
- 複数ファイルにまたがる複雑な変更  

すべてパッチで実現できる。

---

# 5. 特定行削除パッチの例

例：`src/config.js` の 3 行だけ削除したい場合。

```
diff --git a/src/config.js b/src/config.js
--- a/src/config.js
+++ b/src/config.js
@@ -10,7 +10,3 @@
   enableFeatureX: true,
 }

-// ↓ この3行だけ削除したい
-console.log("debug mode");
-debugger;
```

このパッチを apply すると、該当行だけが削除される。

---

# 6. 特定行削除パッチの作り方

## ▼ 1. release ブランチで行を削除してコミット
例：
```
chore(release): remove debug lines
```

## ▼ 2. パッチ化
```
git format-patch -1 <コミットID>
```

生成例：
```
0001-remove-debug-lines.patch
```

## ▼ 3. 次回以降の release 作成時に適用
```
git apply 0001-remove-debug-lines.patch
```

---

# 7. まとめ

| 要件 | 最適な方法 |
|------|-------------|
| develop には必要、release には不要なフォルダ | release ブランチで削除（手動 or パッチ） |
| 特定行だけ削除したい | パッチ方式 |
| 毎回同じ削除を自動化したい | パッチ方式 |
| チーム全体で安全に運用したい | 削除フォルダ一覧を手順書に固定化 |

---

# 8. 推奨運用（Daisuke さんの環境向け）

1. release ブランチ作成  
2. パッチ適用（不要フォルダ削除 + 不要行削除）  
3. CHANGELOG 更新  
4. バージョン更新  
5. コミット & Push  

これが最も安全で、再現性が高く、チーム全体で迷わない運用。

---



---

## 2) CHANGELOG・EXCEL_CHANGELOG を更新

---

### ① CHANGELOG.md を編集
1. SourceTree 左パネルのファイル一覧から **CHANGELOG.md** をダブルクリック
2. エディタで以下のように追記  
   ```
   ## [1.2.0] - 2026-03-02
   ### Added
   - User login feature (Closes #123)
   - Password reset flow

   ### Fixed
   - Timeout issue on API endpoint
   ```

---

### ② EXCEL_CHANGELOG.csv を編集
1. SourceTree 左パネルから **configs/EXCEL_CHANGELOG.csv** をダブルクリック
2. Excel またはエディタで変更内容を追記

---

### ③ 変更をコミット
1. SourceTree の「ファイルステータス」画面で  
   - CHANGELOG.md  
   - EXCEL_CHANGELOG.csv  
   - package.json（後述）  
   をステージング
2. コミットメッセージを入力  
   ```
   chore(release): prepare 1.2.0
   ```
3. 「Commit」をクリック

---

## 3) バージョン番号を package.json 等に反映

---

### ① package.json を編集
1. SourceTree 左パネルから **package.json** をダブルクリック
2. version を `1.2.0` に更新  
   例：  
   ```
   "version": "1.2.0"
   ```

---

### ② コミット & push
1. 「ファイルステータス」で package.json をステージング
2. コミットメッセージ  
   ```
   chore(release): bump version to 1.2.0
   ```
3. 「Commit」→「Push」

---

## ✔ これで release ブランチの準備完了
- release/1.2.0 が GitHub に作成される  
- CHANGELOG / EXCEL_CHANGELOG / version が反映済み  
- この後は QA / ステージング環境での確認へ進む

---







### リリース前の準備

**1) Release ブランチ作成**
```bash
git checkout develop
git pull origin develop
git checkout -b release/1.2.0
git push -u origin release/1.2.0
```

**2) CHANGELOG・EXCEL_CHANGELOG を更新**
```bash
# CHANGELOG.md に変更内容を記載
vi CHANGELOG.md

# 例:
# ## [1.2.0] - 2026-03-02
# ### Added
# - User login feature (Closes #123)
# - Password reset flow
# ### Fixed
# - Timeout issue on API endpoint

# EXCEL_CHANGELOG.csv も同様に更新
vi configs/EXCEL_CHANGELOG.csv
```

**3) バージョン番号を package.json 等に反映**
```bash
# package.json の version を 1.2.0 に更新など
vi package.json

git add CHANGELOG.md EXCEL_CHANGELOG.csv package.json
git commit -m "chore(release): prepare 1.2.0"
git push origin release/1.2.0
```

### PR: release → main

**4) PR を作成**
- GitHub → "Compare & pull request"
- Base: `main`、Compare: `release/1.2.0`
- PR タイトル: `Release v1.2.0`
- 本文に変更内容・リリースノートを記載
- Create pull request

**5) Jenkins ステージングデプロイを実行**
- PR ページの Jenkins チェック（Stage Deploy ジョブがあれば）を実行
- ステージング環境で最終確認

**6) レビュー・承認取得**
- Maintainer にレビュー依頼
- 承認を得たら Merge (Merge commit）

### タグ付け & 本番デプロイ

**7) タグを付与**
```bash
git checkout main
git pull origin main
git tag -a v1.2.0 -m "Release v1.2.0 - User login & bug fixes"
git push origin v1.2.0
```

**8) Jenkins 本番デプロイジョブを実行**
- Jenkins → 該当リポジトリのジョブ
- "Build with Parameters" で `TAG=v1.2.0` を指定
- ビルド・本番デプロイ実行

**9) 本番確認**
- 本番環境で機能・パフォーマンスを確認
- 問題あれば緊急 hotfix

### develop への同期（必須）

**10) main 変更を develop に反映**
```bash
git checkout develop
git pull origin develop
git merge --no-ff main
git push origin develop
```

**11) release ブランチ削除**
```bash
git push origin --delete release/1.2.0
```

---

## 10. Git/GitHub 管理者の具体作業

### A. Organization & Team 管理

**Team の作成と権限付与**
1. Organization → Teams → New team
2. Team に対象メンバーを追加
3. 各リポジトリに Team の access を付与（Admin / Maintain / Write / Read）

### B. Branch Protection 設定（最重要）

**main ブランチの保護**
1. リポジトリ → Settings → Branches
2. "Add rule"
3. Branch name pattern: `main`
4. 以下のチェックボックスをON:
   - ✓ Require a pull request before merging
     - Required approving reviews: 1〜2
     - Require review from code owners: ON
     - Dismiss stale pull request approvals when new commits are pushed: ON（任意）
   - ✓ Require status checks to pass before merging
     - Require branches to be up to date before merging: ON
     - 必須チェック: Jenkins ジョブ名（例: "build", "test"）を追加
   - ✓ Require signed commits（任意）
   - ✓ Include administrators（重要）
   - ✓ Prevent force pushes
5. Save changes

**develop ブランチも同様に保護**
- Pattern: `develop`
- ほぼ同じ設定（リリース直前なため同等のセキュリティ）

### C. Webhooks（GitHub ↔ Jenkins 連携）

**GitHub webhook 設定**
1. リポジトリ → Settings → Webhooks
2. "Add webhook"
3. Payload URL: `https://<JENKINS_HOST>/github-webhook/`
4. Content type: application/json
5. Secret: Jenkins 側に指定した secret 文字列（省略可）
6. Which events?
   - ✓ Push events
   - ✓ Pull request events
7. Active: ON
8. Add webhook

### D. Jenkins Multibranch Pipeline 設定

**Jenkins 側での詳細手順**
1. Jenkins → New Item
2. Item name: 例 "project-name-multibranch"
3. "Multibranch Pipeline" を選択
4. OK
5. Branch Sources セクション
   - Add source → GitHub
   - Credentials: 先ほど登録した GitHub PAT
   - Repository owner: ORG
   - Repository: REPO
   - Behaviors: "Filter by name" で develop / release / main / hotfix を include（feature は除外可）
6. Build Configuration
   - Mode: by Jenkinsfile
   - Script path: Jenkinsfile
7. Scan Multibranch Pipeline Triggers
   - ✓ Periodically（毎時など）
   - ✓ When a GitHub push event is received
8. Save

**Jenkins ステータスが GitHub PR に表示される**
- PR ページの Checks セクションに Jenkins ビルド結果が自動表示される

### E. Git LFS ストレージ管理

**GitHub での LFS ストレージ確認**
1. リポジトリ → Settings → Code & automation → GitHub Actions
2. "Large File Storage" → ストレージ使用量確認
3. 必要に応じて LFS データ容量を購入

### F. CODEOWNERS ファイル設定

**自動レビュワー割当**
1. リポジトリルートに `.github/CODEOWNERS` を配置
```
# 例
/docs/ @org/docs-team
/src/frontend/ @org/frontend-team
/src/backend/ @org/backend-team
/.github/ @maintainers
/configs/excel/ @config-team
```

2. PR を作成すると、変更ファイルのパスに応じて自動でレビュワーが assigned される

### G. 定期保守タスク

**月 1 回程度**
- LFS ストレージ使用量確認
- Team / リポジトリアクセス権の見直し
- Branch Protection ルールが機能しているか確認
- 古い hotfix / release ブランチの削除

---

## 11. Excel（構成管理帳票）の安全な運用

### 運用方針（Git LFS + ロック + CSV + 変更ログ）

Excel は バイナリファイルのため、従来の Git diff は意味をなしません。以下のハイブリッド方式を推奨します。

**フォルダ構成**
```
/configs/
  /excel/          ← .xlsx ファイル（Git LFS で管理）
  /csv/            ← 自動生成された CSV（テキスト、diff 可能）
  EXCEL_CHANGELOG.csv  ← 変更ログ（テキスト管理）
```

### 編集フロー（詳細）

**Step 1: Issue 作成**
- Excel を変更する理由・内容を Issue に記載
- Issue ID を以下のステップで参照

**Step 2: ブランチ作成 & LFS ロック**
```bash
git checkout -b feature/ISSUE-123-update-excel develop

# .xlsx をロック（編集競合防止）
git lfs lock configs/excel/setting.xlsx
# 成功: Locked configs/excel/setting.xlsx
```

**Step 3: Excel 編集**
- Excel を開いて編集
- 編集内容: 項目追加、値更新など

**Step 4: CSV に自動変換**
```bash
python scripts/xlsx_to_csv.py configs/excel/setting.xlsx --out-dir configs/csv

# 結果: configs/csv/setting__Sheet1.csv が生成される
# （シート名ごとに CSV が作成される）
```

**Step 5: EXCEL_CHANGELOG.csv を更新**
```bash
# テキストエディタで編集
# 形式: file,version,date,author,issue,summary,commit

# 追記行:
# configs/excel/setting.xlsx,v1.0.2,2026-03-02,yamada,#123,"Update timeout value","9f8e7d6"
```

**Step 6: コミット**
```bash
git add configs/excel/setting.xlsx configs/csv/setting__Sheet1.csv configs/EXCEL_CHANGELOG.csv
git commit -m "chore(config): update setting.xlsx - increase timeout (#123)"
git push -u origin feature/ISSUE-123-update-excel
```

**Step 7: ロック解除**
```bash
git lfs unlock configs/excel/setting.xlsx
```

### レビュワーの確認手順

**CSV で diff を確認**
1. PR の Files changed タブで `configs/csv/setting__Sheet1.csv` を確認
2. GitHub の diff で変更内容を確認（CSV はテキストなので diff が見えます）

**必要に応じて .xlsx も確認**
```bash
# PR をローカルで checkout して .xlsx を確認
git fetch origin pull/<PR_NUMBER>/head:<BRANCH_NAME>
git checkout <BRANCH_NAME>

# Excel を開くまたは Spreadsheet Compare で比較
```

### LFS ロック管理

**ロック一覧確認**
```bash
git lfs locks
# Locked by yamada at 2026-03-02 10:00:00 +0000
#  configs/excel/setting.xlsx
```

**ロック解除（ロック保有者のみ）**
```bash
git lfs unlock configs/excel/setting.xlsx

# 強制的に解除（管理者のみ）
git lfs unlock --force configs/excel/setting.xlsx
```

### 競合対応

**複数人が同じ Excel を編集した場合（ロック忘れ時）**
1. チーム内で協議：どのバージョンを採用するか
2. ロック者に連絡して競合を解決
3. 変更内容をマージ（手動）

推奨: ロック運用を徹底することで競合を未然に防ぐ

---

## 12. 自動化と検証（GitHub Action / Jenkinsfile / スクリプト）

### A. Jenkinsfile（基本サンプル）

```groovy
pipeline {
  agent { label 'linux' }
  environment {
    NODE_VERSION = '18'
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Install Dependencies') {
      steps {
        sh 'node --version || true'
        sh 'npm ci'
      }
    }
    stage('Lint') {
      steps {
        sh 'npm run lint'
      }
    }
    stage('Test') {
      steps {
        sh 'npm test'
      }
      post {
        always {
          junit 'test-results/**/*.xml'
        }
      }
    }
    stage('Build') {
      when { 
        branch 'main'
        branch 'develop'
      }
      steps {
        sh 'npm run build'
      }
    }
    stage('Deploy to Staging') {
      when { branch 'develop' }
      steps {
        sh 'npm run deploy:staging'
      }
    }
    stage('Deploy to Production') {
      when { 
        tag pattern: /^v[0-9]+\.[0-9]+\.[0-9]+$/, comparator: "REGEXP"
      }
      steps {
        sh 'npm run deploy:production'
      }
    }
  }
  post {
    success {
      echo 'Build succeeded'
    }
    failure {
      echo 'Build failed - notify team'
    }
  }
}
```

### B. GitHub Action（Excel チェック）

```yaml
name: Excel Check

on:
  pull_request:
    paths:
      - 'configs/excel/**'
      - 'configs/EXCEL_CHANGELOG.csv'

jobs:
  excel-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: python -m pip install openpyxl pandas

      - name: Find changed xlsx files
        id: changed
        run: |
          CHANGED=$(git diff --name-only ${{ github.event.pull_request.base.sha }}...${{ github.sha }} | grep '\.xlsx$' || true)
          echo "changed=$CHANGED" >> $GITHUB_OUTPUT

      - name: Check EXCEL_CHANGELOG updated
        run: |
          CHANGED=$(echo "${{ steps.changed.outputs.changed }}")
          if [ -n "$CHANGED" ]; then
            echo "Excel files changed: $CHANGED"
            git diff --name-only ${{ github.event.pull_request.base.sha }}...${{ github.sha }} | grep 'EXCEL_CHANGELOG.csv' || (echo "ERROR: EXCEL_CHANGELOG.csv must be updated" && exit 1)
          fi
```

### C. スクリプト（xlsx → csv 変換）

Python スクリプト `scripts/xlsx_to_csv.py`:
```python
#!/usr/bin/env python3
import sys, openpyxl, csv
from pathlib import Path

def xlsx_to_csv(xlsx_path, out_dir):
    wb = openpyxl.load_workbook(xlsx_path, data_only=True)
    for sheet in wb.worksheets:
        csv_name = f"{xlsx_path.stem}__{sheet.title}.csv"
        csv_path = out_dir / csv_name
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for row in sheet.rows:
                writer.writerow([cell.value or "" for cell in row])

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+")
    parser.add_argument("--out-dir", default="configs/csv")
    args = parser.parse_args()
    
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    for f in args.files:
        print(f"Converting {f}")
        xlsx_to_csv(Path(f), out_dir)
```

---

## 13. トラブルシューティング（よくある問題と対処）

### 問題 1: SSH 認証エラー

**エラーメッセージ**
```
Permission denied (publickey).
```

**原因と対処**
1. 公開鍵が GitHub に登録されているか確認
   ```bash
   ssh -T git@github.com
   # Expected: Hi <username>! You've successfully authenticated
   ```
2. SSH エージェントに秘密鍵がロードされているか確認
   ```bash
   ssh-add -l
   ssh-add ~/.ssh/id_ed25519  # 鍵を追加
   ```
3. SourceTree の設定確認（Windows + PuTTY の場合）
   - Preferences → SSH → SSH Client が正しく設定されているか

### 問題 2: Push が拒否される

**エラー**
```
[remote rejected] main -> main (protected branch hook declined)
```

**原因と対処**
- main / develop は Branch Protection により直接 push 禁止
- **必ず PR ベースでマージする** （main / develop への直接 push は禁止）
```bash
# 代わりに feature → develop で PR を作る
git checkout feature/ISSUE-123-...
git push -u origin feature/ISSUE-123-...
# GitHub で PR を作成してマージ
```

### 問題 3: コンフリクト発生

**develop を pull したらコンフリクト**
```bash
git checkout develop
git pull origin develop
# CONFLICT (content merge): Merge conflict in src/app.js
```

**対処**
```bash
# コンフリクト箇所を VS Code で編集（<<<< ==== >>>> で囲まれた部分）
# 解決後
git add src/app.js
git commit -m "fix: resolve conflict"
git push origin develop
```

### 問題 4: Excel ロック競合

**ロック情報**
```bash
git lfs locks
# Locked by other_user at 2026-03-02 10:00
#  configs/excel/setting.xlsx
```

**対処**
- 他ユーザーに連絡して対応を依頼
- やむを得ず強制解除する場合（管理者のみ）
  ```bash
  git lfs unlock --force configs/excel/setting.xlsx
  ```

### 問題 5: 誤って main に直接コミットした

**状況**
```bash
git log --oneline main | head
# abc1234 Wrong commit directly to main
# def5678 Release v1.0.0
```

**対処**
```bash
# main を1つ前に戻す（チーム合意のもと）
git checkout main
git reset --hard HEAD~1
git push --force-with-lease origin main

# 誤ったコミットを別ブランチに移す
git checkout -b fix/wrong-commit abc1234
git push -u origin fix/wrong-commit
# 別途 PR を作成して develop に取り込む
```

---

## 14. チェックリスト（導入時・日常・リリース時）

### 導入時チェック（管理者向け）

- [ ] Organization / Team を作成
- [ ] リポジトリを作成（main を default ブランチに）
- [ ] develop ブランチを作成
- [ ] .github テンプレ群を配置（PULL_REQUEST_TEMPLATE, ISSUE_TEMPLATE, CODEOWNERS, CONTRIBUTING）
- [ ] Branch Protection を main / develop に設定
- [ ] Jenkins PAT を GitHub から取得して Jenkins に登録
- [ ] Jenkins Multibranch Pipeline を作成してリポジトリを指定
- [ ] GitHub webhook を追加（Jenkins endpoint）
- [ ] Git LFS を初期化して .gitattributes を設定
- [ ] /configs/excel, /configs/csv ディレクトリを作成
- [ ] commit-template.txt をリポジトリに配置
- [ ] チーム全員に SSH 公開鍵・GitHub アカウント登録を依頼
- [ ] SourceTree / VS Code / Git LFS をチーム全員がインストール

### 開発者の日常チェック（PR 作成前）

- [ ] Issue が割り当てられているか
- [ ] ブランチ名が規約（feature/ISSUE-123-desc）に従っているか
- [ ] ローカルで lint を実行して エラーが無いか
- [ ] ローカルで test を実行して失敗が無いか
- [ ] commit メッセージが Conventional Commits に従っているか
- [ ] PR テンプレートをすべて埋めたか
- [ ] PR 本文の先頭に `Closes #ISSUE` を記載したか（Issue 自動クローズ）
- [ ] Excel を変更した場合：Git LFS ロック → CSV 生成 → EXCEL_CHANGELOG 更新したか

### レ��ュワーのチェック

- [ ] Jenkins ビルド（PR check）が成功しているか
- [ ] コード diff が論理的に正しいか
- [ ] テストケースが追加されているか
- [ ] セキュリティ上問題がないか（パスワード / トークン流出等）
- [ ] Excel 変更時：CSV を確認してスキーマが壊れていないか
- [ ] コメント対応の品質が十分か

### リリース時チェック（リリース担当向け）

- [ ] release ブランチから CHANGELOG / EXCEL_CHANGELOG を最新化
- [ ] バージョン番号を package.json などに反映
- [ ] Jenkins ステージングデプロイが成功
- [ ] ステージング環境で機能・パフォーマンス確認
- [ ] PR が Approve & CI 成功で main にマージ可能か
- [ ] main へマージ後、タグ（v1.2.0 等）を付与
- [ ] Jenkins 本番デプロイジョブを実行
- [ ] 本番環境で機能動作確認
- [ ] develop に main をマージ（同期）
- [ ] リリース報告をチーム・ステークホルダーに実施

---

## 15. 付録：テンプレートと実装例

ここでは、実際に利用するテンプレートファイル群を貼ります。下記のファイルを該当ディレクトリにコピーして使用してください。

（以下の各テンプレートは別ファイルブロック【ファイル区切り】で提供します）

# 8. PR 作成とレビュー（レビュワー向け・完全詳細版）

## 8.1 レビュー全体フロー（概要）

PR レビューは以下の流れで進みます。

1. **PR 初期確認**（PR 作成直後）
2. **CI チェック確認**（Jenkins ビルド結果）
3. **コード差分確認**（Files changed タブ）
4. **Excel 差分確認**（バイナリファイル）
5. **ローカル検証**（必要に応じて）
6. **コメント・指摘**（Issue ごと）
7. **修正待ち**（開発者の対応を監視）
8. **修正内容の再確認**（diff を再度見る）
9. **最終承認**（Approve）
10. **マージ**（管理者が実行）

本節ではステップ 7「修正待ち」と ステップ 8「修正内容の再確認」を、特に詳しく掘り下げます。

---

## 8.2 PR を開く・初期情報を確認する

### PR ページへのアクセス

```
GitHub → Pull requests → 対象 PR をクリック
```

### 確認すべき初期情報

#### 項目 1: PR メタ情報
- **PR 番号**: #123
- **ステータス**: Open / Closed / Draft
- **ブランチ**: feature/ISSUE-123-... → develop

#### 項目 2: PR 作成者・タイトル・本文

```markdown
# タイトル例
feat(auth): Add JWT login flow

# 本文の必須要素
Closes #123

## 概要
ユーザーログイン機能を実装しました。

## 変更内容
- JWT トークン生成ロジック
- ログイン API エンドポイント
- セッション管理

## チェックリスト
- [x] ローカルで lint を実行した（エラーなし）
- [x] ローカルでユニットテストを実行した（成功）
- [ ] Excel を変更した場合は CSV と EXCEL_CHANGELOG.csv を更新した
```

**確認ポイント**
- [ ] PR 本文は PULL_REQUEST_TEMPLATE に沿っているか
- [ ] 本文先頭に `Closes #ISSUE` があるか
- [ ] 概要・変更内容が論理的か・明確か

---

## 8.3 CI（Jenkins）ビルド結果を確認する

### チェック結果の見方

PR ページの下部に **Checks** セクションがあります。

```
OK All checks have passed
  └ jenkins/REPO/PR-123 — Build passed
  └ build — Passed
  └ test — Passed
```

### CI が失敗している場合（NG）

**表示例**
```
NG Some checks were not successful
  └ jenkins/REPO/PR-123 — Build failed
  └ lint — Failed
```

**レビュワーがすべきこと**
1. Jenkins リンクをクリック → ビルドログを確認
2. どのステージ（lint / test / build）で失敗したか特定
3. **PR コメントで開発者に指摘**: 例
   ```
   Jenkins の lint ステージが失敗しています。
   ビルドログ: [link]
   修正をお願いします。
   ```
4. 修正を待つ（開発者が commit → push）
5. **修正後、CI が再度実行される**（自動）

### CI が通っている場合（OK）

次のステップに進みます。

---

## 8.4 コード差分（Code Diff）を確認する

### Files Changed タブを開く

```
PR ページ → Files changed タブ
```

表示内容:
- 追加行（緑 +）
- 削除行（赤 -）
- 変更行（黄色）

### 確認すべき項目

#### A. ビジネスロジックの正確性
- 要件と実装が一致しているか
- アルゴリズムは効率的か
- 境界値やエラーハンドリングが漏れていないか

**例**
```diff
+ if (user.password.length < 8) {
+   throw new Error('Password must be at least 8 characters');
+ }
```

レビュコメント例: 「パスワード長の最小値は確認したか? セキュリティポリシーに合致しているか?」

#### B. テストケースの充実
- ユニットテストが追加されているか
- エッジケース（null, 空文字列, 大きな値等）をテストしているか

**例**
```diff
+ describe('Login', () => {
+   it('should login with valid credentials', () => {
+     // ...
+   });
+   
+   it('should reject invalid password', () => {
+     // ...
+   });
+ });
```

#### C. コード品質
- 関数が長くないか（20 行以上は分割を検討）
- 変数名が明確か
- コメント・ドキュメント文字列があるか

#### D. セキュリティ
- API キーやパスワードが誤ってコミットされていないか
- SQL インジェクション対策があるか
- 認証・認可チェックがあるか

### コメント・指摘の方法

**diff 行にコメントを追加**
1. 指摘したい行の右端にマウスをホバー → **+（プラス）ボタン**が出現
2. クリック → コメント欄が開く
3. コメントを記載（Markdown 対応）
4. "Add a single comment" をクリック

**例**
```
このパスワード検証ロジック、大文字・小文字の混在チェックはありますか?
セキュリティポリシーの要件を確認してください。
```

### レビュワーのコメント段階での役割

- 指摘を明確に記載（曖昧さを避ける）
- 修正を強要せず、質問形式で促す（例：「これはなぜこの方法?」）
- 小さい指摘（typo, lint）と大きい指摘（ロジックエラー）を分ける

---

## 8.5 Excel（バイナリ）の差分を確認する

### Excel 変更がある場合

PR に `configs/excel/...xlsx` と `configs/csv/...csv` が含まれているか確認。

#### CSV で diff を確認

```
PR ページ → Files changed → configs/csv/setting__Sheet1.csv をクリック
```

**CSV の表示例**
```diff
- Item,Value,Status
+ Item,Value,Status,UpdatedDate
  name,setting1,active
- timeout,30,enabled
+ timeout,60,enabled,2026-03-02
```

**確認ポイント**
- [ ] 新しい列の追加・削除が仕様に合致しているか
- [ ] 数値の変更が理にかなっているか（例: timeout 30 → 60）
- [ ] フォーマット・スキーマが壊れていないか

#### .xlsx ファイルを直接確認（必要な場合）

PR をローカルで checkout して .xlsx を開く:
```bash
git fetch origin pull/<PR_NUMBER>/head:<BRANCH_NAME>
git checkout <BRANCH_NAME>
# Excel を開く
open configs/excel/setting.xlsx
# または Spreadsheet Compare で比較
```

#### EXCEL_CHANGELOG.csv の確認

```
PR ページ → Files changed → configs/EXCEL_CHANGELOG.csv をクリック
```

**確認ポイント**
- [ ] 変更内容・理由が記載されているか
- [ ] Issue ID が正しく紐付けられているか

---

## 8.6 ローカル検証（必要に応じて実施）

### 検証が必要なケース

- UI / フロントエンド の変更（実際に動作確認が必要）
- API 仕様の変更（実際にリクエスト・レスポンスを確認）
- セキュリティに関わる変更
- PR の説明だけでは理解が難しい場合

### ローカル検証の手順

#### Step 1: PR をローカルで checkout

```bash
git fetch origin pull/<PR_NUMBER>/head:<BRANCH_NAME>
git checkout <BRANCH_NAME>
```

**例**
```bash
git fetch origin pull/42/head:feature/ISSUE-123-login
git checkout feature/ISSUE-123-login
```

#### Step 2: 依存関係をインストール

```bash
npm ci  # または npm install, pip install 等（言語に応じて）
```

#### Step 3: ローカルで実行・テスト

```bash
# Lint 実行
npm run lint

# テスト実行
npm run test

# ビルド
npm run build

# ローカルサーバー起動（UI の場合）
npm run dev
# http://localhost:3000 で動作確認
```

#### Step 4: 動作確認・検証

**チェックリスト**
- [ ] エラーが出ていないか
- [ ] UI の表示は想定通りか
- [ ] API の返り値は正しいか
- [ ] パフォーマンスに問題がないか（大量データで遅くないか）
- [ ] 前のバージョンとの互換性は保たれているか

---

## 8.7 修正指摘を記載する（Request Changes）

### Request Changes の使い方

修正が必要な場合、以下の手順で **Request changes** を送信します。

#### Step 1: Review ボタンをクリック

PR ページ右上の **"Review changes"** ボタン **"Request changes"** を選択

#### Step 2: サマリーコメントを記載

```markdown
## 修正が必要な点

1. **lint エラー**: src/app.js の 45 行目でセミコロン漏れ
2. **テストケース不足**: パスワード検証のエッジケース（10 文字以上の要件）がテストされていません
3. **EXCEL_CHANGELOG.csv が更新されていません**: Excel を変更した場合は必須です
4. **セキュリティ**: パスワードはハッシュ化されていますか? 平文保存は避けてください。

修正をお願いします。修正後、再度レビュー依頼してください。
```

#### Step 3: "Request changes" を送信

これで開発者に通知が届きます。

---

## 8.8 修正作業の詳細手順（開発者向け説明）

レビュワーが Request changes を送った後、**開発者は以下の手順で修正します**。

### Step 1: レビュコメントをすべて確認

```
PR ページ → Conversation タブ
→ レビュワーの "Request changes" コメントをすべて読む
```

各指摘に対して、修正が必要な項目を整理します。

**整理例（自分のメモ）**
```
[ ] 修正 1: src/app.js 45 行目のセミコロン漏れ
[ ] 修正 2: password.test.js に 10 文字以上のテストケース追加
[ ] 修正 3: configs/EXCEL_CHANGELOG.csv を更新
[ ] 修正 4: パスワードハッシュ化ロジック確認
```

### Step 2: ローカルで修正作業を実施

```bash
# 現在のブランチを確認（feature/ISSUE-123-... であることを確認）
git branch

# ファイルを編集（VS Code等で）
vi src/app.js
vi src/password.test.js
vi configs/EXCEL_CHANGELOG.csv
```

#### 具体例：修正作業

**修正前**（レビュコメントで指摘された状態）
```javascript
// src/app.js 45 行目
if (user.password.length < 8) throw new Error('Too short')  // セミコロン漏れ
```

**修正後**
```javascript
// src/app.js 45 行目
if (user.password.length < 8) throw new Error('Too short');  // セミコロン追加
```

**テストケース追加例**
```javascript
// src/password.test.js
describe('Password validation', () => {
  it('should reject password shorter than 8 characters', () => {
    expect(() => validatePassword('short')).toThrow();
  });

  // レビュで指摘された新しいテスト
  it('should accept password with 10 or more characters', () => {
    expect(() => validatePassword('ValidPass123')).not.toThrow();
  });

  it('should accept mixed case and numbers', () => {
    expect(() => validatePassword('MyPass123')).not.toThrow();
  });
});
```

**EXCEL_CHANGELOG.csv 更新例**
```csv
# 修正前（記載なし）

# 修正後
configs/excel/setting.xlsx,v1.0.1,2026-03-02,yamada,#123,"Update timeout 30->60","abc1234"
```

### Step 3: ローカルでテスト・lint 実行

修正後、**必ずローカルで検証**します。

```bash
# Lint チェック
npm run lint
# Expected: OK no errors

# テスト実行
npm test
# Expected: All tests passed (XX passed)

# ビルド
npm run build
# Expected: Build successful
```

**チェックリスト**
- [ ] lint エラーが全て消えたか
- [ ] テストが全て pass するか
- [ ] 新しいテストケースが追加されているか

### Step 4: Excel を変更した場合、CSV を生成

```bash
# CSV 生成
python scripts/xlsx_to_csv.py configs/excel/setting.xlsx --out-dir configs/csv

# 生成確認
ls -la configs/csv/
# setting__Sheet1.csv が作成されていることを確認
```

### Step 5: コミット（修正用コミット）

修正内容を新しいコミットとして追加します。

```bash
# 変更をステージ
git add src/app.js src/password.test.js configs/EXCEL_CHANGELOG.csv configs/csv/

# コミットメッセージ（修正用）
git commit -m "fix: address review comments - add password validation tests, fix syntax (#123)"

# または、より詳細に
git commit -m "fix(auth): add password validation tests and update EXCEL_CHANGELOG (#123)

- Add test case for 10+ character passwords
- Add mixed case/number validation tests
- Update configs/EXCEL_CHANGELOG.csv with latest changes
- Fix semicolon on line 45"
```

**コミットメッセージのポイント**
- 修正内容を明確に（例："Address review comments" は曖昧なので避ける）
- 元の Issue 番号を含める（自動クローズのため）
- 複数の修正がある場合は bullet point で記載

### Step 6: Push

```bash
git push origin feature/ISSUE-123-...
```

**重要**: feature ブランチには **追加コミット** がされます（squash はしない）。
- PR は自動で更新される（新しいコミットが追加される）
- レビュワーは新しい commit の diff のみを確認すればよい

### Step 7: Reviewers に再レビュー依頼（PR コメント）

Push した後、GitHub の PR ページで **コメント欄** に返信を追加します。

```markdown
修正完了しました。

実施内容:
- [x] src/app.js の 45 行目にセミコロン追加
- [x] password.test.js に 10+ 文字のテストケース追加
- [x] configs/EXCEL_CHANGELOG.csv を更新
- [x] ローカルで lint / test 全て pass

再度のレビュアルをお願いします。
```

その後、PR ページ右側の **"Reviewers"** に マウスを当てて、もう一度レビュワーをクリック（またはアイコンの矢印ボタン）で **"Re-request review"** を送信します。

---

## 8.9 修正後のレビュワーの再確認手順

開発者が修正・push した後、**レビュワーが再度確認**します。

### Step 1: PR の更新を確認

PR ページをリロード。新しいコミットが追加されているはずです。

```
Commits: 2 commits
└ feat(auth): Add JWT login flow
└ fix(auth): address review comments - add password validation tests, fix syntax  ← NEW
```

### Step 2: 新しいコミットの diff のみを確認

PR ページ → **Files changed** タブ → コミットフィルタから **最新のコミット（修正コミット）のみ** を表示

```
Showing 1 commit
Select commit: [All commits -] → [fix(auth): address review comments -]
```

これで修正内容の diff のみが表示されます。

**確認内容**
- [ ] レビュコメントで指摘した点が全て修正されたか
- [ ] 新しいエラー・問題が導入されていないか
- [ ] テストケースが追加されているか

### Step 3: CI（Jenkins）を確認

修正後、Jenkins が自動で再ビルドされます。

```
Checks セクション
OK jenkins/REPO/PR-123 — Build passed
OK build — Passed
OK test — Passed
```

**失敗していれば**
- Jenkins ログを確認 → 再度修正を依頼

### Step 4: その他の修正が必要か判断

#### パターン A: すべて OK → Approve に進む

修正内容に問題がなければ、**Approve** を送ります。

#### パターン B: 追加指摘がある → Request changes を送る

例: 「テストケースは追加されたが、エ���ジケース（負の数値）のテストが漏れている」

この場合、再度 **Request changes** を送ります（修正後のサイクルが繰り返される）。

---

## 8.10 最終承認（Approve）

修正が完全に終わり、問題がなくなった段階で **Approve** を送ります。

### Approve の方法

PR ページ右上 → **"Review changes"** → **"Approve"** を選択

**サマリーコメント例**
```markdown
修正ありがとうございました。すべての指摘が適切に対応されています。

確認事項:
OK lint 修正済み
OK テストケース（10+ 文字）追加済み
OK パスワードハッシュ化ロジック確認済み
OK EXCEL_CHANGELOG.csv 更新済み
OK Jenkins ビルド成功

マージして問題ありません。
```

### Approve 後

必要数の Approve が集まり CI が成功したら、**マージ権限者**（管理者）がマージボタンをクリックします。

---

## 8.11 修正サイクルのベストプラクティス

### レビュワーの心構え

1. **指摘は明確に**: 「直せ」ではなく「ここが問題な理由は...」と説明
2. **修正の難易度を意識**: 小さい指摘（typo）なら Request changes ではなく Comment で OK
3. **段階的に**: 一度に大量の指摘を送らず、5-6 個の主要指摘に絞る
4. **修正後の確認は徹底**: 修正コミットの diff のみを確認（前のコミットは見直さない）

### 開発者の心構え

1. **指摘をすべて記録**: メモを取り、修正漏れを防ぐ
2. **各修正を separate commit で**: 1 commit = 1 修正内容が分かりやすい
3. **ローカルテストを徹底**: push 前に lint / test が全て pass することを確認
4. **修正後は PR コメントで報告**: 「○○を修正しました」と明示
5. **不明な指摘は質問**: 「この修正の意図は?」と聞いても OK

### 修正が複数回必要な場合

通常、1-2 回の修正サイクルで完了します。3 回以上続く場合は以下を検討:

- レビュワーと開発者が直接会話（ビデオ通話で詳細説明）
- Issue や Wiki にドキュメント化して共有
- PR の要件定義が不足していなかったか見直す

---

## 8.12 Excel 変更時の修正フロー（特別対応）

Excel ファイルを変更した場合、修正フローに **追加の確認項目** があります。

### レビュワーの確認（修正前）

1. **CSV の diff 確認**
   ```
   PR → Files changed → configs/csv/... → diff を確認
   ```

2. **EXCEL_CHANGELOG.csv の確認**
   ```
   変更内容・Issue 号が記載されているか確認
   ```

3. **指摘例**
   ```
   新しい "UpdatedDate" 列が追加されていますが、既存のデータの UpdatedDate はどう埋めるのですか?
   また、この列の形式（日付フォーマット）を確認してください。
   ```

### 開発者の修正（修正後）

```bash
# Excel を再編集して、新しい列に値を記入
open configs/excel/setting.xlsx  # 編集

# CSV を再生成
python scripts/xlsx_to_csv.py configs/excel/setting.xlsx --out-dir configs/csv

# EXCEL_CHANGELOG.csv にも詳細を記載
vi configs/EXCEL_CHANGELOG.csv
# 例: configs/excel/setting.xlsx,v1.0.2,2026-03-02,yamada,#123,"Add UpdatedDate column","abc1234"

# コミット
git add configs/excel/setting.xlsx configs/csv/ configs/EXCEL_CHANGELOG.csv
git commit -m "fix: add UpdatedDate to all rows and update EXCEL_CHANGELOG (#123)"

git push origin feature/...
```

### レビュワーの再確認

1. CSV の新しい diff を確認
   ```
   + UpdatedDate
   + 2026-03-01
   + 2026-03-01
   ```

2. EXCEL_CHANGELOG.csv で変更内容を確認

3. 必要なら .xlsx をダウンロードして Excel で直接確認

---

## 8.13 修正フロー完全シーケンス図

```
レビュワー側
├─ 1. PR を確認
├─ 2. CI を確認
├─ 3. diff を確認
└─ 4. Request changes に指摘を記載
        ↓（開発者が通知受け取り）

開発者側
├─ 5. 指摘を読む
├─ 6. ローカルで修正
├─ 7. lint/test 実行
├─ 8. コミット
├─ 9. push
└─ 10. 再レビュー依頼
        ↓（PR 自動更新、レビュワーが通知）

レビュワー側
├─ 11. 修正コミットの diff確認
├─ 12. CI 再チェック
└─ 13. 追加指摘 or Approve
        ↓

[修正が必要 → ループ or 完了]
        ↓

管理者側
├─ 14. マージ
└─ 15. 完了
```

---

## 8.14 PR レビュー時の禁止事項と推奨事項

### レビュワーの禁止事項

- **曖昧な指摘**: 「これおかしいです」ではなく、具体的に
- **一度に大量指摘**: 開発者が対応できなくなる（5-6 個が上限）
- **細かすぎる指摘**: 自動 lint で対応できる内容は CI に任せる
- **感情的コメント**: 「ここはなぜこんなコードを書いた」ではなく「この実装方法の意図は?」
- **非同期で解決できない問題の放置**: 困ったら同期で相談

### レビュワーの推奨事項

- **具体的な指摘**: 「45 行目の if 条件で、user.password が null の場合のチェックがないです。追加してください」
- **理由を説明**: 「SQL インジェクションの可能性があるため、パラメータ化クエリを使用してください」
- **修正例を示す**: コードスニペットで修正方法を提案
- **段階的確認**: 最初のコメントで「主要な問題」、修正後に「細かい点」を指摘
- **良い実装も褒める**: 「テストケースがよく書けてますね」

### 開発者の禁止事項

- **レビュコメントの無視**: 指摘に対応しないで push
- **修正内容を PR に書かない**: 何を修正したかコメントに記載すること
- **テスト不実施で push**: 必ずローカルで lint/test 通過を確認
- **修正コミットを squash**: PR 上で修正の痕跡を残す（追跡可能に）

### 開発者の推奨事項

- **指摘を丁寧に対応**: 不明な点は質問する
- **修正ごとに separate commit**: 「修正 1」「修正 2」で分ける
- **修正完了後に PR コメント**: 「○○を修正しました」と通知
- **修正内容を簡潔に記載**: EXCEL_CHANGELOG や CHANGELOG も忘れずに
- **ローカルテストを徹底**: 本番問題を未然に防ぐ

---

## 8.15 PR レビュー完全チェックリスト（テンプレート）

レビュワーが PR を確認する際に使用してください。

```markdown
## PR レビュー確認チェックリスト

### 初期確認
- [ ] PR タイトルが明確か
- [ ] PR 本文が PULL_REQUEST_TEMPLATE に沿っているか
- [ ] 関連 Issue（Closes #）が記載されているか

### CI / ビルド確認
- [ ] Jenkins ビルドが OK Pass しているか
- [ ] すべてのステージ（lint, test, build）が成功しているか

### コード差分確認
- [ ] ビジネスロジックが正確か
- [ ] テストケースが追加されているか
- [ ] セキュリティ上問題がないか
- [ ] コード品質は良好か（関数の長さ、命名、コメント）
- [ ] API 仕様に変更がある場合、ドキュメント更新がされている��

### Excel / バイナリ確認（変更があれば）
- [ ] CSV の diff が確認できるか
- [ ] EXCEL_CHANGELOG.csv が更新されているか
- [ ] スキーマに破損がないか

### ローカル検証（必要な場合）
- [ ] UI の表示は正しいか
- [ ] API のレスポンスは期待値か
- [ ] パフォーマンスに問題がないか

### 修正・再確認
- [ ] 修正コミットの diff を確認した
- [ ] 修正後の CI が Pass しているか
- [ ] レビュコメントがすべて対応されているか

### 最終承認
- [ ] すべてのチェックが完了した
- [ ] Approve コメントを送信
```

---

以上が、PR レビュー・修正フローの完全詳細版です。

このプロセスを通じて：
1. **開発品質が向上** → 多くの問題がマージ前に検出される
2. **チーム全体の学習** → レビューコメントからコーディング知識が共有される
3. **本番の安定性** → 十分な検証を通った変更のみが本番に入る

ことが期待できます。