### C. SourceTree（GUI クライアント）セットアップ【詳細版・Windows】

**公式ダウンロード**
- 公式サイト: https://www.sourcetreeapp.com/
- Windowsユーザー: 「Download for Windows」をクリック

#### インストール手順（Windows）

1. ダウンロードした `SourceTreeSetup-xxx.exe` をダブルクリック実行  
2. ライセンス・プライバシーポリシーに同意（チェック）  
3. **Bitbucketアカウント設定**  
   - Atlassian（Bitbucket）アカウントが求められるが「スキップ」可能  
4. **Git のインストール選択**  
   - 既にインストール済みならチェックを外す  
   - 未インストールならチェックして続行  
5. ユーザー名・メールアドレス入力（Gitコミット記録用）  
6. **SSH・リモートリポジトリの初期設定**  
   - この画面は設定をスキップしても後から Preferences（設定）でいつでも設定可能  
   - 初めて SourceTree を使う場合は「スキップ」して、インストール後に落ち着いて設定することを推奨  
7. インストール完了・起動

---

#### GitHub 認証設定（OAuth + SSH キー）

**ステップ 1: ホスティングサービスの設定**

1. SourceTree メニュー → **ツール** → **オプション**  
2. **認証** タブをクリック  
3. 以下を設定:
   - **ホスティングサービス**: GitHub を選択  
   - **優先するプロトコル**: SSH を選択  
   - **認証**: OAuth を選択

**ステップ 2: OAuth トークンの再読み込み**

1. 「**OAuthトークンを再読み込み**」をクリック  
2. 「**Authorize atlassian**」をクリック（ブラウザで認可画面が開きます）  
3. GitHub の認可画面で「Authorize」を許可  
4. SourceTree に戻り、OAuth 認証が完了していることを確認

---

#### SSH キーの作成と登録

**ステップ 3: SSH キーを生成（SourceTree）**

1. SourceTree → **ツール** → **オプション** → **認証** タブ  
2. 「**SSH キーの作成/インポート**」をクリック  
3. 「**Generate**」をクリックして鍵を生成  
4. 生成された公開鍵（英数字列）を **クリップボードにコピー**（後で GitHub に貼る）

**ステップ 4: パスフレーズの設定と公開鍵保存**

1. **Key Passphrase** に任意のパスワードを入力（忘れないよう安全に保管）  
2. 「**Save public key**」をクリックして公開鍵を一時保存

**ステップ 5: ローカルに `.ssh` フォルダを用意**

Windows のユーザーフォルダに `.ssh` ディレクトリを作成します。

- GUI（エクスプローラー）で作成: `C:\Users\[ユーザー名]` を開き、新規フォルダを `.ssh` と命名  
- コマンドプロンプトで作成:
```cmd
mkdir C:\Users\[ユーザー名]\.ssh

## ステップ 6: 公開鍵を保存

`.ssh` フォルダ内に **id_rsa.pub** というファイルを作成し、  
先ほどクリップボードにコピーした公開鍵の内容を貼り付けて保存します。

---

## ステップ 7: 秘密鍵を保存（.ppk 形式）

1. SourceTree → **ツール** → **オプション** → **認証**
2. 「**Save private key**」をクリック
3. ファイル名 **id_rsa.ppk** として `.ssh` フォルダに保存

---

## ステップ 8: OpenSSH 形式にもエクスポート（コマンドライン用）

PowerShell / Git Bash などの CLI からも同じ鍵を使えるように、  
OpenSSH 形式の秘密鍵も作成します。

1. SourceTree → **ツール** → **オプション** → **認証**
2. **Conversions** タブを開く
3. 「**Export OpenSSH key**」を選択
4. ファイル名 **id_rsa**（拡張子なし）で `.ssh` フォルダに保存

これで以下の 2 種類が揃います：

- PuTTY 形式：`id_rsa.ppk`
- OpenSSH 形式：`id_rsa`

---

## GitHub に公開鍵を登録

1. ブラウザで GitHub にサインイン
2. 右上プロフィール → **Settings**
3. **SSH and GPG keys**
4. 「**New SSH key**」をクリック
5. Title：識別しやすい名前（例：SourceTree Windows PC）
6. Key：`id_rsa.pub` の内容を貼り付け
7. 「Add SSH key」をクリック

---

## SourceTree で SSH エージェントを起動

1. SourceTree → **ツール** → **オプション** → **認証**
2. 「**SSH エージェントを起動**」を有効にして「はい」
3. 保存した秘密鍵 **id_rsa.ppk** を選択して読み込み
4. 「SSH キーを読み込みますか？」→「はい」
5. SourceTree を再起動して設定を反映

---

## リモートリポジトリを追加（SourceTree）

### ステップ 1: GitHub から SSH アドレスをコピー

GitHub のリポジトリページ → **Code** → **SSH**  
例：
