# GUI だけで GitHub リポジトリを更地化し、美しい履歴に再構築する手順  
（SourceTree / GitHub のみ使用）

本ドキュメントは、以下の目的を達成するための手順をまとめたものです。

- コミットログが汚れているため、履歴をきれいにしたい  
- Issue や PR も整理して、本番環境をできるだけ “更地” にしたい  
- コマンドを使わず GUI だけで実施したい  
- 新しい main を作り、必要なコミットだけ移植したい  

---

# 1. 新しい main-clean ブランチを作る（履歴ゼロ）

SourceTree で以下を行う：

### ▼ 手順

1. **main をチェックアウト**
2. 上部メニュー → **ブランチ作成**
3. ブランチ名：  
   ```
   main-clean
   ```
4. 「親コミットを引き継がない（orphan ブランチ）」を選択  
   ※ SourceTree では「空のブランチを作成」などの表現になる
5. 作成後、左側のファイル一覧で **すべてのファイルを削除**  
   （右クリック → 削除）

→ これで **履歴ゼロの main-clean** が完成。

---

# 2. 必要なファイルをコピーして初期コミットを作る

### ▼ 手順

1. エクスプローラーで **旧 main の作業フォルダを開く**
2. 必要なファイルだけを main-clean の作業フォルダへコピー  
3. SourceTree に戻り、変更が検出される  
4. 「すべてステージ」→「コミット」

コミットメッセージ例：

```
Initial clean commit: project baseline
```

→ **美しい最初の1コミットが完成**

---

# 3. 必要な修正だけ cherry-pick で移植（GUI）

### ▼ 手順

1. SourceTree 左側の **main-old（旧 main）** をチェックアウト  
2. ログビューで必要なコミットを右クリック  
3. **「このコミットを cherry-pick」** を選択  
4. 対象ブランチとして **main-clean** を選択

これで **必要な修正だけを綺麗な履歴に移植**できる。

---

# 4. コミットログを整形（GUI）

SourceTree の **インタラクティブリベース（rebase -i）** を GUI で実行する。

### ▼ 手順

1. main-clean をチェックアウト  
2. ログビューで整形したい範囲を選択  
3. 右クリック → **「インタラクティブリベース」**  
4. 以下を GUI 上で実施  
   - コミット名を編集  
   - squash（まとめる）  
   - fixup（不要コミットを潰す）

→ **美しい履歴が完成**

---

# 5. GitHub の main を差し替える（GUI）

### ▼ 手順

#### ① GitHub 上で main をリネーム
1. GitHub → Repository → Settings  
2. 「Branches」  
3. main を **main-old** にリネーム

#### ② main-clean を push
1. SourceTree → main-clean を push  
2. GitHub 上に main-clean が表示される

#### ③ GitHub のデフォルトブランチを変更
1. GitHub → Settings → Branches  
2. Default branch を **main-clean** に変更  
3. main-clean を **main** にリネーム

#### ④ ブランチ保護ルールを設定
- Require PR before merging  
- Require status checks  
- Require linear history  
- 必要なら Require signed commits  

---

# 6. Issue / PR の整理（GUI）

### ▼ Issue の整理
- 完了済み → Close  
- 不要 → Delete  
- 残すもの → 新しい main に合わせて再登録

### ▼ PR の整理
- 過去の PR はすべて Close  
- 新しい main に対して必要な PR を作り直す

### ▼ Projects / Milestones
- 必要なものだけ移行  
- 過去のものはアーカイブ

---

# 7. 注意点

- **main-old は削除しない**（履歴の保険として残す）  
- cherry-pick は必要な修正だけに限定する  
- main-clean を main に切り替える前に必ず動作確認する  

---

# 8. 最終構成

```
main-old：過去の履歴（保険）
main：新しい美しい履歴（本番用）
develop：main から作り直す
release：必要に応じて作成
```

---

# 9. まとめ

- GUI だけでリポジトリを更地化する最も安全な方法は  
  **新しい main-clean を作り、必要なコミットだけ移植する方式**  
- コミットログは完全に美しくなる  
- Issue / PR も整理して “新しいプロジェクト” として再スタートできる  
- 過去の履歴は main-old に残るため安全  

---

# GitHub ブランチ名変更手順（main → main-old、main-new → main）

この手順では、GitHub 上でブランチ名を変更し、
新しいきれいな履歴を持つ `main-new` を本番用の `main` として設定します。

---

## 1. ブランチ一覧を開く

1. GitHub のリポジトリ画面を開く  
2. 上部タブの **Code** をクリック  
3. ファイル一覧の上にある **「2 branches」**（数字は環境により異なる）をクリック  
4. ブランチ一覧が表示される

---

## 2. 旧 main を main-old にリネームする

1. ブランチ一覧の中から **main** を探す  
2. 右側にある **鉛筆アイコン（Rename）** をクリック  
3. 新しい名前を入力  
   ```
   main-old
   ```
4. **Rename branch** を押す

これで旧 main は `main-old` に変更されます。

---

## 3. 新しい main-new を main にリネームする

1. 同じブランチ一覧で **main-new** を探す  
2. 右側の **鉛筆アイコン（Rename）** をクリック  
3. 新しい名前を入力  
   ```
   main
   ```
4. **Rename branch** を押す

これで `main-new` が新しい `main` になります。

---

## 4. Default branch（デフォルトブランチ）を確認する

1. GitHub 上部の **Settings** をクリック  
2. 左メニューの **Branches** をクリック  
3. Default branch が **main** になっていることを確認  
   - もし main になっていなければ、  
     **Change default branch** から main を選択して変更する

---

## 5. 新しい main にブランチ保護ルールを設定する（必要に応じて）

1. Settings → Branches  
2. Branch protection rules の **Add rule** をクリック  
3. 以下の設定を推奨  
   - Require a pull request before merging  
   - Require status checks  
   - Require linear history  
   - Require signed commits（必要なら）

---

## 6. 完了後のブランチ構成

```
main-old   ← 旧履歴（バックアップ）
main       ← 新しいきれいな履歴（本番用）
develop    ← main から作り直す（必要に応じて）
```

---

## 7. 注意点

- リポジトリの設定（Secrets、Actions、Collaborators など）は消えません  
- main に紐づいていた保護ルールは main-old に移動します  
- 新しい main に対して保護ルールを付け直す必要があります  
- Issue / PR はそのまま残ります（必要に応じて整理）

---

以上で、新しい main を本番用として安全に切り替えることができます。