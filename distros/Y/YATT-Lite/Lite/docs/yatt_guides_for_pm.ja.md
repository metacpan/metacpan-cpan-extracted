# NAME

yatt\_guides\_for\_pm(ja) - Perl Monger のための yatt (YATT::Lite) ガイド

# INTRODUCTION

この文書では Perl Monger を対象に、yatt (YATT::Lite) で
Web アプリを作る方法を解説します。
特に、最初のシンプルなバージョンを自分で動かしたあとで、
**テンプレート書きをデザイナーさんにアウトソース**したり、
システムとして顧客に納品して以後の
**ビジネスレベルの改良・拡張・カスタマイズは顧客が自分で進める** 、
という業態を想定して説明を進めます。

解説は複数のツアーに別れており、
Hello world から初めて、テンプレートの部品化(widget 化)、
外部モジュールの呼び出し…と段階的に進みます。

# TOUR1: Hello world!


## Install YATT::Lite from github

説明を簡単にするため、一連のツアーは、github 上のインストーラを
直接使う方法を用います。

まずターミナルを開いて、開発用のディレクトリを作り、そこに cd して下さい。

```console
$ mkdir -p ~/public_apps/app1 && cd ~/public_apps/app1   # or wherever.
```

次に、以下のようにインストーラを実行して下さい。

```console
$ curl https://raw.githubusercontent.com/hkoba/yatt_lite/dev/scripts/skels/min/install.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1274  100  1274    0     0   4425      0 --:--:-- --:--:-- --:--:--  4439
Using remote git https://github.com/hkoba/yatt_lite.git
# git init
Initialized empty Git repository in /home/hkoba/public_apps/app1/.git/
# mkdir -p lib
# git submodule add https://github.com/hkoba/yatt_lite.git lib/YATT
Cloning into 'lib/YATT'...
remote: Counting objects: 5775, done.
remote: Compressing objects: 100% (1488/1488), done.
remote: Total 5775 (delta 4029), reused 5775 (delta 4029)
Receiving objects: 100% (5775/5775), 1.32 MiB | 332.00 KiB/s, done.
Resolving deltas: 100% (4029/4029), done.
Checking connectivity... done.
# cpanm --installdeps .
--> Working on .
Configuring YATT-Lite-v0.0.9 ... OK
<== Installed dependencies for .. Finishing.
# cp -va lib/YATT/scripts/skels/min/approot/app.psgi lib/YATT/scripts/skels/min/approot/html .
`lib/YATT/scripts/skels/min/approot/app.psgi' -> `./app.psgi'
`lib/YATT/scripts/skels/min/approot/html' -> `./html'
`lib/YATT/scripts/skels/min/approot/html/index.yatt' -> `./html/index.yatt'
$
```

インストールが終わると、以下のようなディレクトリが出来上がるはずです。

```console
$ tree -L 2
.
├── app.psgi
├── html
│   └── index.yatt
└── lib
    └── YATT

3 directories, 2 files
$
```

各ファイル・ディレクトリの説明です。

- `app.psgi`

    `app.psgi` は YATT::Lite (の WebMVC0::SiteApp) を用いた PSGI アプリです。
    これを `plackup` で起動すれば、テンプレートとして
    `*.yatt` を使える Web サーバーが動きます。
    この場合の app.psgi の中身は、以下のようになっているはずです。
    (勿論これはあくまでサンプルで、自分で書いても構いません。)

    ```perl
    # -*- perl -*-
    sub MY () {__PACKAGE__}; # omissible
    use FindBin;
    use lib "$FindBin::Bin/lib";
    use YATT::Lite::WebMVC0::SiteApp -as_base;
    use YATT::Lite qw/Entity *CON/;
    {
      my $app_root = $FindBin::Bin;
      my $site = MY->new(app_root => $app_root
                     , doc_root => "$app_root/html");
      Entity param => sub { my ($this, $name) = @_; $CON->param($name) };
      return $site if MY->want_object;
      $site->to_app;
    }
    ```

- `html/`

    `html/` がこの Web アプリの document root になります。
    ファイル名を省略してアクセスした場合は
    `index.yatt` がインデックスファイルとして表示されます。

- `lib/`

    `lib/` はこのアプリのためのモジュールを置く場所です。
    `lib/YATT` 以下には `git submodule` として [YATT::Lite](https://metacpan.org/pod/YATT%3A%3ALite)
    の git リポジトリが登録されます。(symlink で共有することも可能です)

## Write your first "Hello world"!


好みのエディタで、 `html/index.yatt` を以下のように編集してみて下さい。

```html
<!yatt:args foo="text?world" bar="text" baz>
<h2>Hello &yatt:foo;!</h2>
&yatt:bar;, &yatt:baz;
```

その上で、 `plackup` でアプリを起動してから以下の URL をアクセス
してみて下さい。

- [http://0:5000/](http://0:5000/)
- [http://0:5000/?foo=aa&bar=bb](http://0:5000/?foo=aa&bar=bb)
- [http://0:5000/index?foo=cc&bar=dd](http://0:5000/index?foo=cc&bar=dd)
- [http://0:5000/index.yatt?foo=ee&bar=ff&baz=gg](http://0:5000/index.yatt?foo=ee&bar=ff&baz=gg)

無事 "Hello world!", "Hello aa!", "Hello cc!"... などと表示されたでしょうか？
(もしかすると 0: を localhost: に書き換えないと繋がらないかもしれません)

上記の index.yatt テンプレートの、各部の意味は以下の通りです。

- (1行目) `<!yatt:args foo="text?world" bar="text" baz>`

    `<!yatt:...` で始まり `>` で終わる行は、
    そのテンプレートで定義される部品( **widget** ) の名前や引数を宣言する、
    [yatt 宣言](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual#YATT-Declaration) です。
    主な yatt宣言には他に `<!yatt:page>`, `<!yatt:widget>`,
    `<!yatt:action>` があります。

    この宣言の場合、 index.yatt テンプレート(の中の、デフォルト widget)に、
    `foo` 、`bar`、 `baz` ３つの引数があることを意味しています。

    - `foo="text?world"`

        [引数の宣言](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual#Argument-Declaration)は
        `引数名 = "型名 フラグ文字 デフォルト値"` の形式で書かれます。
        型名は省略すると `text` 型になり、出力時に自動的に escape されます。

        この例では引数 **foo** が **text** 型で、フラグ文字が **?**、
        デフォルト値が **world** となっています。
        デフォルトモードフラグが `?` なので、 `foo` の値が空文字列 `""` か `undef`
        の時にデフォルト値 `world` が使われます。

- (2,3行目) `&yatt:foo;`, `&yatt:bar;`

    `&yatt:` で始まり `;` で終わる部分は、(html の entity 参照記法に習って)
    外から来た値を埋め込む(置換する)、[Entity 参照](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual#Entity-reference) を表しています。

    この例では引数 foo, bar を html 中に埋め込んでいます。
    なお、entity 記法は引数以外に計算処理の式を埋め込むためにも使います。

## Emacs integration (strongly recommended)

yatt の設計テーマは **"use strict" のあるテンプレートエンジン** です。
つまり、変数名や widget 名の綴り間違いが、
web からアクセスするよりも前に、
検知出来ることが最大の売りです。

この yatt のメリットを享受するためには、
エディタに静的検査コマンド(yatt lint)を連動させる必要が有ります。

XXX: readme からここへ転記

# TOUR2: How to write yatt widgets and compose them.


今度は複数の widget を組み合わせる方法を解説します。
[先ほど](#tour1-index-yatt)の `html/index.yatt` を次のように myhello.yatt へと rename して下さい。

```console
$ mv -v html/index.yatt html/myhello.yatt
```

次に、エディタで改めて `html/index.yatt` を新規作成し、
次のように書いて下さい。

```html
<!yatt:args>
<yatt:layout>
   <yatt:myhello/>
   <yatt:myhello foo="xxx" bar='yyy' />
</yatt:layout>

<!yatt:widget layout>
<!doctype html>
<style>h2 {border: solid blue; border-width: 5px 0;}</style>
<body>
   <yatt:body/>
</body>
```

保存したら [http://0:5000/](http://0:5000/) をアクセスしてみて下さい。今度は h2 タグが
css で着色されて表示されたのではないでしょうか？

この例では、新たに 2つの widget が出てきました。rename して出来た
`html/myhello.yatt` が表す `yatt:myhello` と、
`html/index.yatt` の後半で定義された、`yatt:layout`です。

前半の

```html
<yatt:layout>
   <yatt:myhello/>
   <yatt:myhello foo="xxx" bar='yyy' />
</yatt:layout>
```

は `yatt:layout` widget の呼び出しです。この layout タグで囲まれた部分は
[body 引数](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual#body)と呼ばれる
closure として扱われます。ここでは更に
`yatt:myhello` の呼び出しを二回書いています。ここで layout に渡した closure は

```html
...
 <body>
    <yatt:body/>
 </body>
```

の `<yatt:body/>` の所で呼び出されます。

## XXX: genperl

## XXX: delegate

```html
<!yatt:args mh=[delegate:myhello]>
<yatt:layout>
   <yatt:mh/>
</yatt:layout>
```
