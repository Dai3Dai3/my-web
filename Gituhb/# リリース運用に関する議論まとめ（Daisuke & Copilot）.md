# リリース運用に関する議論まとめ（Daisuke & Copilot）

本ドキュメントは、以下のテーマについての議論をまとめたものです：

- release ブランチだけ特定フォルダを除外したい  
- develop と main は同じ状態に保ちたい  
- ただし develop と main には内部資料フォルダを残したい  
- release のみ内部資料を含めたくない  
- パッチ方式でフォルダ削除や行削除を自動化できるか  
- コンフリクト発生時の正しい解決方法  
- タグ中心のリリース手順を作りたい  

---

# 1. 要件整理

## ✔ develop には内部資料フォルダを残したい  
（構成管理上必要）

## ✔ main にも内部資料フォルダを残したい  
（本番にも残して問題ない）

## ✔ release ブランチだけ内部資料フォルダを含めたくない  
（本番ビルドに不要なため）

---

# 2. 望ましい最終状態

```
develop：内部資料あり
main：内部資料あり
release：内部資料なし
```

この状態を維持しながらリリース作業を行う。

---

# 3. release ブランチだけ内部資料を削除する方法

## ▼ 方法 A：手動で削除（SourceTree）
1. release ブランチ作成  
2. 内部資料フォルダを右クリック → 削除  
3. Commit → Push  

## ▼ 方法 B：パッチ方式で自動化
1. release ブランチで内部資料フォルダを削除してコミット  
2. そのコミットをパッチ化  
   ```
   git format-patch -1 <コミットID>
   ```
3. 次回以降の release 作成時に適用  
   ```
   git apply 0001-remove-dev-folder.patch
   ```

---

# 4. 特定行だけ削除するパッチも可能

Git パッチは行単位の差分を記録するため、以下も可能：

- 1 行だけ削除  
- 1 行だけ追加  
- 1 文字だけ変更  
- 特定のシンボル変更（例：DEBUG_MODE = true → false）  
- 特定の import 削除  
- コメント行削除  
- 複数ファイルにまたがる変更  

## ▼ 特定行削除パッチの例

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

---

# 5. release → main マージ時のコンフリクト

## ▼ 原因  
release では内部資料フォルダを削除しているため、  
main にマージすると「削除 or 残す」でコンフリクトが発生する。

## ▼ 解決方針  
**main では内部資料を残す（Use ours）**

## ▼ SourceTree 操作  
1. main をチェックアウト  
2. Merge → release  
3. コンフリクト発生  
4. 内部資料フォルダを右クリック  
5. **Use ours（main 側）** を選択  
6. Mark as resolved  
7. Commit → Push  

---

# 6. main → develop マージ時のコンフリクト

## ▼ 原因  
main では内部資料が残っているが、release の削除が影響して差分が出る。

## ▼ 解決方針  
**develop でも内部資料を残す（Use ours）**

## ▼ SourceTree 操作  
1. develop をチェックアウト  
2. Merge → main  
3. コンフリクト発生  
4. 内部資料フォルダを右クリック  
5. **Use ours（develop 側）** を選択  
6. Mark as resolved  
7. Commit → Push  

---

# 7. タグ中心のリリース手順（CHANGELOG 不要版）

## 1) Release ブランチ作成
- develop を最新化  
- Branch → `release/1.2.0` 作成  

## 2) release だけ内部資料削除
- 手動 or パッチ適用  
- Commit → Push  

## 3) 動作確認（ステージング / QA）

## 4) main へマージ（内部資料は残す）
- コンフリクト → **Use ours（main）**  

## 5) タグ付け
- Tag → `v1.2.0`  
- Push（タグを含む）  

## 6) develop へ反映
- main → develop  
- コンフリクト → **Use ours（develop）**  

## 7) release ブランチ削除（任意）

---# 8. 最終的な構成

```
develop：内部資料あり（構成管理用）
main：内部資料あり（本番にも残す）
release：内部資料なし（本番ビルド用）
```

この運用により：

- main と develop は常に一致  
- release だけ内部資料を除外  
- パッチ方式で自動化も可能  
- コンフリクトは完全にパターン化  
- 手順書としてチーム全体で共有可能  

---

# release → main のコンフリクト発生理由と解決方法（Daisuke プロジェクト用）

本ドキュメントは、以下の内容をまとめたものです：

- なぜ release → main のマージでコンフリクトが発生するのか  
- なぜ develop → main ではコンフリクトが発生しないのか  
- GitHub 上でのコンフリクト解決方法  
- Accept current change / Accept incoming change の正しい使い分け  
- 内部資料フォルダを release だけから除外する運用に最適化した判断基準  

---

# 1. 前提（Daisuke プロジェクトの構成）

```
develop：内部資料あり
main：内部資料あり
release：内部資料なし（内部資料フォルダを削除）
```

- develop と main には内部資料を残す  
- release だけ内部資料を削除する（本番ビルドに不要なため）  

---

# 2. なぜ release → main のマージでコンフリクトが発生するのか

Git はマージ時に **3-way merge** を行う。

比較するのは以下の3つ：

1. Base（共通の祖先＝develop）
2. Current（GitHub UI 上の “current”＝release）
3. Incoming（GitHub UI 上の “incoming”＝main）

## ▼ 状態の比較

```
Base（develop）：内部資料あり
main（incoming）：内部資料あり
release（current）：内部資料なし（削除）
```

Git の判断：

- Base → main：変更なし（内部資料あり）
- Base → release：変更あり（内部資料削除）

→ **同じフォルダに対して異なる変更が入っているため、コンフリクト発生**

### ✔ 行数を少し変えただけでもコンフリクトが出る理由

release で行を変更すると：

- Base → main：変更なし  
- Base → release：変更あり  

この差分が競合すると、**同じ行を変更していなくてもコンフリクトになる**。

---

# 3. なぜ develop → main のマージではコンフリクトが出ないのか

```
Base（過去の main）：内部資料あり
develop：内部資料あり
main：内部資料あり
```

3つとも同じ状態なので：

- Base → develop：変更なし  
- Base → main：変更なし  

→ **競合がないためコンフリクトは発生しない**

---

# 4. GitHub 上でのコンフリクト解決方法

PR 画面で以下の表示が出る：

- **This branch has conflicts that must be resolved**
- 「Resolve conflicts」ボタンが表示される

### ▼ 操作手順

1. PR を開く  
2. 「Resolve conflicts」をクリック  
3. コンフリクトしているファイルが一覧表示される  
4. 各ファイルを開き、以下のようなブロックを確認する：

```
<<<<<<< current
（current：release の内容）
=======
（incoming：main の内容）
>>>>>>> incoming
```

5. 残したい側の内容だけを残し、  
   `<<<<<<<`, `=======`, `>>>>>>>` を削除する  
6. 「Mark as resolved」  
7. 「Commit merge」  
8. PR をマージする  

---

# 5. Accept current change / Accept incoming change の使い分け

GitHub のコンフリクト画面では：

| ボタン | 実際に採用される内容 |
|--------|------------------------|
| **Accept current change** | **release（current）** の内容を採用 |
| **Accept incoming change** | **main（incoming）** の内容を採用 |

---

# 6. Daisuke プロジェクトにおける正しい判断基準

## ✔ release → main のマージ  
### 内部資料フォルダは main に残したい  
→ **Accept incoming change（main を残す）**

### コード修正は release の変更を反映したい  
→ **Accept current change（release を採用）**

### つまり：
- 内部資料：**incoming（main）**  
- コード修正：**current（release）**  

必要に応じて手動で両方を統合する。

---

# 7. 具体例（内部資料フォルダのコンフリクト）

```
<<<<<<< current
docs/internal/report.xlsx
=======
（main 側は残っている）
>>>>>>> incoming
```

### ▼ 正しい操作  
👉 **Accept incoming change（main を残す）**

---

# 8. 具体例（release のコード修正を main に反映したい場合）

```
<<<<<<< current
const mode = "production";   // release 側
=======
const mode = "dev";          // main 側
>>>>>>> incoming
```

### ▼ 正しい操作  
👉 **Accept current change（release の修正を採用）**

---

# 9. まとめ

- release → main のコンフリクトは **必ず発生する（正常）**  
- 理由は release だけ内部資料を削除しているため  
- develop → main は状態が同じなのでコンフリクトしない  
- GitHub の判断基準は以下の通り：

| マージ方向 | 内部資料 | コード修正 |
|------------|-----------|-------------|
| **release → main** | Accept incoming（main） | Accept current（release） |
| **main → develop** | Accept incoming（develop） | Accept current（main） |

---

# 10. この運用で得られる最終状態

```
develop：内部資料あり
main：内部資料あり
release：内部資料なし
```

- main と develop は常に一致  
- release だけ内部資料を除外  
- コンフリクトは毎回出るが、解決方法は完全にパターン化できる  

---

- release → main の PR をマージ
- main ブランチのコミット画面へ移動
- 「Create tag」または「Releases」→「Draft a new release」
- タグ名を入力（例：v1.2.0）
- 「Publish release」


# GitHub でタグをつける方法（Release から作成）  
および SourceTree でのタグ確認方法

本ドキュメントでは以下を説明します：

- GitHub 上でタグをつける正しい手順（Release 画面から作成）  
- タグがローカル（SourceTree）に見えないときの対処  
- SourceTree で GitHub のタグを確認する方法  
- よくある原因と解決策  

---

# 1. GitHub 上でタグをつける（Release 画面から作成）

GitHub の「Releases」画面からタグを作成するのが最も安全で確実です。

## ▼ 手順

1. GitHub のリポジトリを開く  
2. 上部メニューの **「Releases」** をクリック  
3. **「Draft a new release」** をクリック  
4. 「Tag version」の欄で以下のどちらかを選択  
   - **新しいタグを作成（例：v1.2.0）**  
   - 既存タグを選択  
5. 「Target」は **main** を選択（重要）  
6. Release Notes を必要に応じて記述  
7. **「Publish release」** をクリック

これで GitHub 上に正式なタグが作成されます。

---

# 2. GitHub で作ったタグが SourceTree に見えない場合の対処

GitHub でタグを作っても、ローカル（SourceTree）には自動で反映されません。  
以下の手順でローカルにタグを取り込みます。

---

# 3. SourceTree で GitHub のタグを確認する方法

## ▼ 手順

### ① SourceTree を開く  
main ブランチをチェックアウトしておくとわかりやすい。

### ② 上部メニューの **「フェッチ（Fetch）」** をクリック  
※「プル（Pull）」ではタグが降ってこないことがあるため、必ず Fetch を使用。

### ③ Fetch の設定で「タグを取得」が有効か確認  
バージョンによってはチェックボックスがあるため、ON にする。

### ④ 左側のサイドバーの **「Tags（タグ）」** をクリック  
ここに GitHub で作成したタグが一覧表示される。

---

# 4. タグが見えないときのチェックポイント（重要）

以下のどれかが原因でタグが見えないことが多いです。

---

## ✔ 原因①：GitHub で「Release」は作ったが「タグ」を作っていない

GitHub は **タグなしで Release を作れてしまう** ため注意。

### ▼ 確認方法  
GitHub → **Tags** タブ  
→ ここにタグがなければ、SourceTree にも出ない。

---

## ✔ 原因②：タグを main ではなく release に付けてしまった

あなたの運用では：

- タグは **main** にだけつける  
- release にタグをつけても main には反映されない

GitHub の Release 作成画面で **Target が main になっているか確認**。

---

## ✔ 原因③：ローカルがタグ情報をまだ取得していない

SourceTree の Fetch がうまく動いていない場合は、  
ターミナルで以下を実行すると確実です。

```
git fetch --tags
```

---

# 5. タグ運用の正しいルール（Daisuke プロジェクト用）

| ブランチ | タグをつける？ | 理由 |
|---------|----------------|------|
| **main** | つける | 本番の基準点になるため |
| **develop** | つけない | 開発途中の履歴のため |
| **release** | つけない | 一時的なビルド用ブランチのため |

---

# 6. まとめ

- GitHub の Release 画面からタグを作成するのが最も安全  
- タグは **main** にだけつける  
- SourceTree では **Fetch → Tags** で確認  
- 見えない場合は  
  - GitHub の Tags タブに存在するか  
  - Target が main か  
  - `git fetch --tags` を実行  
  を確認する

---