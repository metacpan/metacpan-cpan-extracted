# NAME

yatt\_lite\_readme(ja) -- 初めにお読み下さい (日本語版)

# SYNOPSIS

ファイル `index.yatt` にて

```html
<yatt:envelope title="test">
  My first YATT App! &yatt:repeat(foo,3);
</yatt:envelope>
```

ファイル `.htyattrc.pl` にて

```perl
Entity repeat => sub {
  my ($this, $what, $count) = @_;
  $what x $count;
};
```

ファイル `envelope.ytmpl` にて

```html
<!yatt:args title="html?">
<!doctype html>
<html>
<head>
<title>&yatt:title;</title>
</head>
<body>
<h2>&yatt:title;</h2>
<yatt:body />
</body>
</html>
```

変換結果は…

```html
<!doctype html>
<html>
<head>
<title>test</title>
</head>
<body>
<h2>test</h2>
  My first YATT App! foofoofoo
</body>
</html>
```

# DESCRIPTION

[yatt](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual) (Yet Another Template Toolkit) は
Web開発を直接的に支援するテンプレートシステムです。
**YATT::Lite** は yatt の最新版です。
Pure Perl で実装されており、
[PSGI](https://metacpan.org/pod/PSGI) ベースの Web フレームワークの Reference Implementation
である **WebMVC0** が添付されています
(YATT::Lite 単体でテンプレートエンジンとして使うことも可能です)。

## Features

yatt の主な特徴を以下に挙げます。

- 他のテンプレートシステムと比べて、HTML/XML との親和性が高い。


    yatt で書かれたテンプレートは HTML/XML に
    [非常に構文が似ている](#synopsis) ので、
    導入が容易です
    (一般的なエディタの HTML/XML モードでもほぼ問題なく読み書き出来ます)。

    またテンプレート言語としての yatt の仕様自体は
    perl5 へ過度に依存しないよう設計されているので、
    仮に将来、組織の開発言語が perl5 以外の言語に切り替わったときも、
    (yatt をそこで実装し直せば^^;)
    Web デザイナーチームの再学習のコストを最小化できるだろう、
    という読みもあります。

- 「タグを単位とした、テンプレートの部品化」を支援


    HTML は冗長な記述言語なので、テンプレートエンジンにおいても
    [DRY (Don't Repeat Yourself)](http://en.wikipedia.org/wiki/Don&#x27;t_repeat_yourself)
    の原則は重要です。
    ただ、組み合わせやすい部品化の単位とは何か(エディタ上での見栄えも含めて)、
    そしてデザイナーにその部品化の枠組みをどんな概念として伝えるか、にも配慮が必要です。

    そこで yatt では、デザイナーにとって最も自然な記述単位であると思われる
    「タグ(=element)」を部品化の基礎単位とすることにしました。
    (つまり yatt は **「タグの集まり」に名前を付けて「新たなタグ」を作る** ためのツール、
    として設計されました)。なお、以後 yatt における部品のことを **yatt widget**,
    又は単に **widget** (ウィジェット)と呼びます。

    プログラマーの観点からは、
    テンプレートをクラスに、その中で定義された widget 群をクラス内の関数群へと
    1対1 で対応付けるようにしました。
    また、widget のタグに囲まれたブロック範囲をクロージャ引数として
    扱うようにしたことで、 **制御構文もタグ** として自然に表現出来るようにしました。
    それ以外にもタグからスクリプトへの **変換マクロ** を定義することも可能です。
    (将来的には perl 以外の言語への変換も計画しています)

    部品管理の観点からは、テンプレートファイルとディレクトリを統合的な
    名前空間として扱う仕組みを用意しました。これにより、
    プロジェクト規模に合わせて無理のない範囲で widget のライブラリー化を進めることが出来ます。

- 静的検査を重視、構文エラー検出のための `lint` ツールを用意
 

    プログラムを書き慣れない素人にとって、変数名や部品の名前をスペルミスしないよう、
    注意を払い続けることは、決して容易ではありません。

    そこで yatt では、部品、部品に渡す引数、変数参照について、
    可能な限り静的にスペルミスを検査します。
    (「静的に」とは、実行しなくても、スクリプトへの変換の段階で検査される、という意味です。)

- XSS への抜本対策としての、出力時エスケープと変数型宣言機能
 

    Web 用のアプリケーション開発では、
    ユーザが入力したデータを他のユーザのブラウザへと送る際に、
    セキュリティ上の問題が出ない形式へと確実に変換(エスケープ)する事が
    求められます。これを忘れると、 Cross Site Scripting (XSS)
    セキュリティーホールの問題が発生するからです。

    そこで yatt ではテンプレート内で用いる変数に、予め『(escape の)型』を
    宣言するようにしました。テンプレート中で変数を使用した箇所には、型に応じた
    escape 処理が自動的に生成されます。

- 複雑な処理をテンプレートの外に括り出すための、拡張(?) Entity reference 式


    複雑な処理をテンプレートに埋め込むときに
    `<?php?>` のような processing instruction 構文を用いると、
    途端にソースから HTML らしさが失われてしまいます。

    yatt では、そもそも HTML/XML の思想では埋め込み置換要素は
    Entity reference で書くものだったはずと考えます。
    そこで、その構文を `&yatt:f(x,y):g(z,w)...;` のように
    object のメソッド呼び出しチェーン風に拡張し、
    これをテンプレート外で定義される無名クラスのメソッド呼び出しへとマップする仕組みを
    用意しました。

- Web アプリ構築向けの、リクエストルーティング機能付き


    Web アプリにはユーザの要求した url を view へマップするための、
    リクエストルーティング機能が必要です。これは、アプリの内部構造の変更に
    振り回されない、
    [簡潔で安定した URI](http://www.kanzaki.com/docs/Style/URI)
    を提供するためです。ですが、一般的な Webフレームワークでは、URL ルーティングの変更には
    プログラミングの知識が必要でした。

    yatt の WebMVC0 では、テンプレートエンジン自身に
    [URL ルーティング](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual#subrouting)
    の機能を持たせました。

    例えば `index.yatt` に以下のように書くだけで、

    ```html
    <!yatt:page mod="/mod/:mod" >
    ```

    URL
    [/mod/YATT::Lite::doc::readme](https://yatt-yl-podview-rrdekxdjda-an.a.run.app/mod/YATT::Lite::docs::readme)
    へのリクエストを、

    - テンプレートディレクトリの
    - `index.yatt` ファイルの
    - `<yatt:mod>` サブページへの、
    - モジュール名 `YATT::Lite::doc::readme` を引数とした呼出へ

    マップすることが出来ます。(もちろん、拡張子 `.yatt` は隠せます。)

    また、ディレクトリとテンプレートファイルを抽象化して統一的に扱うことが出来ることと、
    他のテンプレートの widget を簡単に呼び出せることにより、
    外部仕様を変えずに、大幅に内部のファイル構成を変更することが可能です。

- 多国語化の支援

    メッセージ多国語化のための構文があり、専用の xgettext ユーティリティが付属しています。

    XXX: (残念ながら、最初に生成した .po ファイルには複数行メッセージの扱いにバグがあり、
    生成結果を修正する必要があります。
    また、 .pm からの xgettext は従来のツールを使う必要があります)

## Installation

yatt\_lite をインストールする方法は通常の CPAN モジュールと同様です。

```sh
cpanm YATT::Lite
```

あるいは、最新版の yatt\_lite を使いたい場合は、
[github 上のリポジトリ](https://github.com/hkoba/yatt_lite)を
**git clone するだけ** でそのまま使用できます。
(make や Build は不要です。依存するのは Plack くらいです)
例えばあなたの Web アプリの perl lib ディレクトリが `./lib` にあるとすれば

```sh
git clone git://github.com/hkoba/yatt_lite.git ./lib/YATT
```

だけで YATT::Lite を使い始めることが出来ます。もしその Web アプリが
既に git で管理されているなら、git submodule を使って、

```sh
git submodule add git://github.com/hkoba/yatt_lite.git ./lib/YATT
git submodule update --init
```

とすることも可能です。

### Quick start

この状態で、サンプル app.psgi をコピーすれば、 yatt の使える web app の出来上がりです。

```sh
cp lib/YATT/samples/app.psgi .
mkdir html
plackup
```

後は `html` ディレクトリの下に、拡張子 `.yatt` でファイルを作ってみましょう。
例えば好みのエディタで `html/index.yatt` という名前のファイルを作り、
以下のように入力してみて下さい。

```html
<!yatt:args "/:foo" bar>
<h2>Hello &yatt:foo; world!</h2>
&yatt:bar;
```

変更が済んだら、ブラウザで以下の URL をアクセスしてみて下さい。

     http://0:5000/
     http://0:5000/?bar=y
     http://0:5000/foo
     http://0:5000/foo?bar=z
     http://0:5000/index.yatt/foo?bar=baz

### Command Line util

XXX: To be written about: `./lib/YATT/scripts/yatt`

### Emacs Lisp

- [poly-yatt](https://github.com/hkoba/poly-yatt)

    [polymode](https://polymode.github.io/) をベースにした編集モードです。

- yatt-lint-any-mode

    ファイル保存時に静的検査を行う minor mode です。
    ファイルの種類に応じて `perl -wc` や `yatt lint` などを
    自動的に起動し、エラーが有ればその行にジャンプします。

### dotcloud

`vendor` ディレクトリに [dotcloud](http://www.dotcloud.com)
用のサンプルを用意してあります。コピーしてお使い下さい。

    cp -va YATT/vendor/dotcloud ~/myapp
    cd ~/myapp
    git init
    git submodule add git://github.com/hkoba/yatt_lite.git approot/lib/YATT
    plackup approot/app.psgi

## Benchmark results:


私のノート PC でのベンチマーク結果は
このようになりました。

(with Intel(R) Core(TM) i3-2367M CPU @ 1.40GHz)

Pure Perl 同士の比較結果です。

    % cd YATT/samples/benchmarks
    % ./yt-x-poor-env.pl
    Perl/5.14.3 x86_64-linux-thread-multi
    Text::Xslate/1.5009
    Template/2.24
    HTML::Template/2.91
    Text::MicroTemplate/0.18
    Text::MicroTemplate::Extended/0.12
    YATT::Lite/0.0_4
    1..4
    ok 1 - TT: Template-Toolkit
    ok 2 - MT: Text::MicroTemplate
    ok 3 - HT: HTML::Template
    ok 4 - YT: YATT::Lite
    Partially Cached Benchmarks with 'include' (datasize=100)
             Rate     TT Xslate     HT     YT     MT
    TT     72.4/s     --   -15%   -55%   -80%   -81%
    Xslate 85.3/s    18%     --   -47%   -76%   -78%
    HT      162/s   124%    90%     --   -55%   -57%
    YT      359/s   396%   321%   121%     --    -6%
    MT      381/s   426%   346%   135%     6%     --

なお、XS ベースのものと比べるとこのレベルです。

    % ./yt-x-rich-env.pl
    Perl/5.14.3 x86_64-linux-thread-multi
    Text::Xslate/1.5009
    Text::MicroTemplate/0.18
    Text::MicroTemplate::Extended/0.12
    Template/2.24
    Text::ClearSilver/0.10.5.4
    HTML::Template::Pro/0.9509
    YATT::Lite/0.0_4
    1..5
    ok 1 - TT: Template-Toolkit
    ok 2 - MT: Text::MicroTemplate
    ok 3 - TCS: Text::ClearSilver
    ok 4 - HTP: HTML::Template::Pro
    ok 5 - YT: YATT::Lite
    Benchmarks with 'include' (datasize=100)
              Rate     TT     YT     MT    TCS    HTP Xslate
    TT       116/s     --   -67%   -84%   -95%   -97%   -99%
    YT       352/s   203%     --   -53%   -86%   -91%   -98%
    MT       745/s   541%   112%     --   -70%   -82%   -96%
    TCS     2510/s  2060%   613%   237%     --   -38%   -86%
    HTP     4072/s  3404%  1057%   446%    62%     --   -77%
    Xslate 17935/s 15332%  4997%  2306%   615%   340%     --

# NOTICE

## yatt is \*NOT\* for wiki-like public content formatting.

yatt はテンプレートを perl プログラムへと変換し、サーバーで動かすものです。
ですので、絶対に、(潜在的に悪意を仮定すべき) 任意のユーザに
Web 経由でテンプレートをアップロード・入力させる
ような用途に用いてはいけません。

あくまで yatt のテンプレートは、サイトの運用に共同責任を負う、身内の立場の人間にのみ
書くことを許すようにしてください。

## Most APIs are not yet stable.

内部 API については、まだまだ納得していないので、変更したくなるかもしれません。

# Next Steps

## for Web Designers

yatt の構文の詳しい説明は [yatt\_manual](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_manual) を
参照してください。

## for Perl Mongers

yatt を呼び出す Webアプリを書く perl プログラマーの方は、
[Perl Monger のための yatt (YATT::Lite) ガイド](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Ayatt_guides_for_pm)
から始めてください。より詳しい YATT::Lite の内部構造については
[prog\_guide](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Aprog_guide) をご覧ください。

具体的な例を見たい場合は、 `samples/` ディレクトリ以下も参考にしてください。

また、テストスクリプト `t/*.t` とその入力ファイル `*.xhf` も参考になるかも
しれません。
