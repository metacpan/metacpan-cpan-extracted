# NAME

yatt\_manual(ja) -- yatt 構文マニュアル (日本語版)

# SYNOPSIS

```html
<!yatt:args>
<yatt:layout title="My hello world">
  <yatt:myhello who="world!"/>
</yatt:layout>

<!yatt:widget myhello who>
<h2>Hello &yatt:who;!</h2>

<!yatt:widget layout title>
<!doctype html>
<title>&yatt:title;</title>
<body>
  <yatt:body/>
</body>
```

# Overview

yatt のテンプレートは、通常の HTML に、
**名前空間 yatt:** で始まる yattの構文要素を加えたものです。
(名前空間は yatt の設定で変更可能ですが、
この文書では簡単のため yatt: で説明を統一します)
yatt の構文は XML に似ていますが、XML よりも再帰性を改善した、
よりテンプレート向きの独自構文 
[LRXML](https://metacpan.org/pod/YATT%3A%3ALite%3A%3ALRXML%3A%3ASyntax) (Loose but Recursive XML)
を採用しています。以下は LRXML の主な構文要素とその役割の概要です。

- `<yatt:` ... `/>`
- `<yatt:` ... `>` ～ `</yatt:...>`

    [部品(widget) の呼び出し](#widget-invocation)

- `<:yatt:` ... `/>`～
- `<:yatt:` ... `>` ～ `</:yatt:...>`

    [部品(widget) への引数(タグ形式)](#attribute-element).
    (引数の中に更にタグを含めたい時に使うと、HTML らしいテンプレートが書けます)

- `&yatt:` ... `;`

    [Entity 参照](#entity-reference) (埋め込み要素：変数や関数呼び出し)

- `<!yatt:` ... `>`

    [yatt 宣言](#yatt-declaration) (部品定義の始まり)

- `<!--#yatt` ... `-->`

    [コメント](#comment-block). この部分は yatt の解析対象外。

    **XXX:** 将来的に、閉じを `#-->` に変更する案があります。

- `&yatt[[;` ... `&yatt]];`
- `&yatt#num[[;` ... `SINGULAR` ... `&yatt||;` ... `PLURAL` ... `&yatt]];`

    多国語化メッセージ. **yatt xgettext** で抽出。

- `<?yatt` ... `?>`, `<?perl` ... `?>`

    [ターゲット言語の記述を直接埋め込みたい時](#processing-instruction)

# Files

yatt を用いた Web Application の典型的なディレクトリ構成の例を挙げます。

```tree
.
├── app.psgi
├── cpanfile
├── lib
├── public
│   ├── .htyattconfig.yml
│   ├── hello.yatt
│   ├── index.yatt
│   ├── login.ydo
│   └── other.html
├── static
│   └── css
│       └── main.css
└── ytmpl
    ├── .htyattrc.pl
    ├── envelope.ytmpl
    └── error.ytmpl
```

一般的な `.html`, `.css` や、perl の [PSGI](https://metacpan.org/pod/PSGI) ベースの Web Application
の標準的なファイルである `.psgi`, `cpanfile` 以外に、
yatt に固有なファイルとして `.yatt`, `.ytmpl`, `.ydo`, `.htyattconfig.yml`, `.htyattrc.pl`
が各所に置かれています。以下それぞれの役割を概説します。

- `*.yatt`

    Web Application として外部に公開したい (public な) yatt ベースの動的ページは、
    拡張子 `.yatt` を付けて、Web Application の公開ディレクトリに直接配置します。
    上記の例では `public/` ディレクトリに置いています。
    (php が `.php` ファイルを公開ディレクトリに配置するのと同様です)
    サブディレクトリも普通に扱えます。公開ディレクトリの名前は設定で変更可能です。

- `*.ytmpl`

    反対に、ユーザに見せる予定の無い(**private** な)テンプレートには拡張子
    `.ytmpl` をつけてください。公開ディレクトリに置くことも可能ですが表示は拒否されます。通常は上記の `ytmpl/` のようにテンプレート専用のディレクトリを作成して
    そこに配置します。

- `*.ydo`

    POST されるデータに対する処理など、 html 生成よりもデータの操作が
    主であるものは、テンプレートの中に書こうとすると却って読みにくくなります。
    そこでそのような処理は直接 perl で記述出来るよう、別の仕組みが用意されています。
    (この文書では扱いません)

- `.htyattconfig.yml`, `.htyattconfig.xhf`

    ディレクトリ毎の [YATT::Lite](https://metacpan.org/pod/YATT%3A%3ALite) をロードする時に渡される設定パラメータを記述します。
    書式は YAML か [XHF](https://metacpan.org/pod/YATT%3A%3ALite%3A%3AXHF%3A%3ASyntax) 形式です。

- `.htyattrc.pl`

    ディレクトリ毎の Entity 関数を定義したい時や、
    ディレクトリ毎の各種ハンドラをオーバロードしたい時に使います。

**XXX:** 残念ながら、現時点では、`.htyattconfig.yml` と
`.htyattrc.pl` の更新を反映させるには、 **プロセスの再起動** が必要です。

# Widget Invocation

widget を呼び出すには、 `<yatt:... >` で始まるタグを書きます。
タグは `/>` で閉じる empty element 形式か、閉じタグ `</yatt:... >` を
使う形式、どちらでも書けます。引数は ` x="..." ` のようにタグの属性として渡すか、
[引数を表す別のタグ](#attribute-element) として渡すことが出来ます。

```html
<!--foo の呼び出し. 閉じタグ無し. 引数は属性 x として渡す例-->
<yatt:foo x="hello!" y="world!"/>

<!--開きタグ＋閉じタグの例。囲まれた部分は body 引数として渡されます-->
<yatt:foo x="hello!" y="world!">
  my contents!
</yatt:foo>

<!--中に属性タグ形式で引数 x を書く例-->
<yatt:foo>
  <:yatt:x>hello!</:yatt:x>
  <:yatt:y>world!</:yatt:y>
  my contents!
</yatt:foo>

<!--属性タグの、閉じタグ無し形式の例-->
<yatt:foo>
  my contents!
<:yatt:x/>
  hello!
<:yatt:y/>
  world!
</yatt:foo>
```

## widget search order

widget は

- 同一ファイル内
- → 同一ディレクトリ内
- → 他に指定されたテンプレートディレクトリ

の順で検索され、最初に見つかったものが使われます。**検索はコンパイル時に** 行われ、
見つからない場合はコンパイルエラーとなります。

## widget **path**

別のファイルやディレクトリ内で定義された widget を呼び出す事も可能です。
この場合、パス名を `:` でつなげて書きます。(拡張子 `.yatt` は省いて下さい)

例えばファイル `foo/bar.yatt` の中に

```html
<!yatt:widget baz>
....
```

が有った場合、これを `index.yatt` から呼び出すには

```
<yatt:foo:bar:baz/>
```

と書きます。

XXX: 同じ名前のファイルとディレクトリが有った場合

## XXX: positional arguments

`name=` を省略して引数を書く話

## XXX: path thru arguments

引数の右辺に bareword を渡したときの挙動

## Implicit arguments

### XXX: this, CON

### body argument


全ての widget は閉じタグを使う形式で呼び出すことが出来ます。

```html
<yatt:foo>
  bar
</yatt:foo>
```

この時、閉じタグまでの間に書いた記述は、暗黙の引数 `body` として widget に渡されます。
body は (明示的に宣言しない限り) `code` 型とされます。

これを呼び出すには, entity 呼び出し形式か、widget 呼び出し形式、
どちらでも使用できます。

```html
&yatt:body();

<yatt:body/>
```

これは最も頻繁に現れる、ブロック形式の部品を定義するときに役立ちます。

```html
<yatt:env title="mypage">
  ...ここに延々と本体を...
</yatt:env>


<!yatt:widget env title>
<h2>&yatt:title;</h2>
<div class="content">
  <yatt:body/>
</div>
```

## attribute element

閉じタグを使う `<yatt:...> ... </yatt:...>`形式で
widget 呼び出しを書いたときは、そのタグで囲まれた
body の箇所に、他の引数を特別なタグ (属性タグ) として書くことができます。
(タグ型引数)
これを用いると、html 属性 の中にタグ的な記述を持ち込む必要を減らすことが
出来ます。

属性タグは、先頭が `<:yatt...` で始まるタグです。
(lisp の `:keyword` 引数のイメージです)

属性タグの書き方は二通りあり、 `/>` で終わる空要素を使う形式と、
`</:yatt...` 閉じタグを持つ形式です。

```html
<yatt:env>
  ...body として渡される部分...
  <:yatt:title/>
  タイトル
</yatt:env>


<yatt:env>
  <:yatt:title> タイトル </:yatt:title>
  ...body として渡される部分...
</yatt:env>
```

# BUILTIN Macro

yatt のタグは widget の呼び出しだけではなく、
他にも制御構文を表すタグにすることも出来ます。
これは yatt のマクロ機能によって実現されています。
[YATT::Lite](https://metacpan.org/pod/YATT%3A%3ALite) には以下のマクロが組込み定義されています。

## `yatt:my`


局所変数を宣言・初期化したい時に使います。属性として `var="初期値"` を複数
書くことが出来ます。初期値を省略することも可能です。
変数に型を指定するには `var:type="初期値"` のように `:` に続けて
型名を書きます。型を指定しない場合は ["text"](#text) 型になります。

```html
<yatt:my x=3 y=8 z />

<yatt:my
   foo="bar"
   val:value="&yatt:x; * &yatt:y;"
/>
```

閉じタグを用いた場合、自動的に html 型の変数宣言となり、body に相当する部分が
値として用いられます。

```html
<yatt:my foo>
  <h2>foobar</h2>
</yatt:my>
```

## `yatt:if`, `:yatt:else`
 

条件分岐を記述したい時に使います。

```html
<yatt:if "not &yatt:x;">
 ...not x の時...
<:yatt:else if="&yatt:x; < 10"/>
 ... x が 10 より小さい時 ...
<:yatt:else/>
 ...その他...
</yatt:if>
```

## `yatt:foreach`


ループを書く時に使います。 `list="..."` にリストを作る式を渡すと、
そのリストに対してループします。 `my=var` でループ変数を宣言出来ます。
宣言を省略した場合は `&yatt:_;` が使われます。

```html
<yatt:foreach my=row list="&yatt:some_db_query();">
  ...DB から取り出した一行毎に...
</yatt:foreach>
```

my で変数を宣言する時に型を指定するには、(変則的ですが)
`my:型名=` のように、 `my` と `=` の間に `:型名` で型を指定します。

```html
<yatt:foreach my:list=row list="&yatt:some_db_query();">
   &yatt:row[0]; &yatt:row[1];
</yatt:foreach>
```

## `yatt:return`


エラー処理などで Early return を書きたい時に使います。 `if="..."` か
`unless="..."` の条件式を渡すことで、指定条件成立時に early return する
ことが出来ます。(if, unless は無くても構いません)

```html
<yatt:return if="&yatt:some_error;">
  <h2>エラーが見つかりました！</h2>
  &yatt:some_error;
</yatt:return>

<yatt:my data:value="&yatt:get_some_data();"/>
<yatt:return unless="&yatt:data;">
  <h2>データが取得できませんでした！</h2>
</yatt:return>
```

注意点： `yatt:return` は単なる実行の打ち切りなので、それ以前に
出力された内容が有った場合、それも出力されます。

# Entity Path Expression
 

yatt ではテンプレートへの値の埋め込み(置換)を (HTML/XMLの) entity reference
記法を拡張した Entity Path 式で表現します。 HTML/XML の entity reference は `&amp;`, `&quot;` のように `&` .. `;` で表現されましたが、
yatt の Entity Path 式 は `&yatt` で始まり `;` で終わります。
(勿論、この接頭辞 yatt も設定で変更可能です)

以下はEntity Path式の例です。

```html
&yatt:foo;                       <!-- 変数 foo の参照 -->

&yatt:func(arg1,arg2);           <!-- 関数 funcの呼び出し -->

&yatt:dict{name};                <!-- 辞書(ハッシュ表) dict の要素参照 -->

&yatt:list[:x];                  <!-- 配列 list の要素参照 -->
```

重要な注意点ですが、一部の例外を除き、 Entity Path式の中には **スペースをそのまま含めることは出来ません**。

```html
&yatt:func( space separated text );  <!-- エラー！ -->
```

これは意図的に加えた制限です。あまり複雑な構文を用意しても、
既存の HTML/XML エディタとの相性が悪化するだけだから、という理由です。

## path element


Entity Path式の例を再掲します。

```html
&yatt:foo;                       <!-- 変数 foo の参照 -->

&yatt:func(arg1,arg2);           <!-- 関数 funcの呼び出し -->

&yatt:dict{name};                <!-- 辞書(ハッシュ表) dict の要素参照 -->

&yatt:list[:x];                  <!-- 配列 list の要素参照 -->
```

Entity Path式の構文は開始記号 `&yatt` で始まり、
一個以上の ["path element"](#path-element) の列の後、最後に終了記号 `;` で閉じられます。
式の意味はこの path element によって決まります。
先の例から path element のみを抜き出すと、以下のようになります。

```html
:foo                       <!-- 変数 foo の参照 -->

:func(arg1,arg2)           <!-- 関数 funcの呼び出し -->

:dict{name}                <!-- 辞書(ハッシュ表) dict の要素参照 -->

:list[:x]                  <!-- 配列 list の要素参照 -->
```

path element のうち、`(..)`, `[..]`, `{..}` のように括弧を用いるものは
以下の特徴が有ります。

- 括弧内の要素は `,` で区切ります

    通常の言語の関数呼び出しと違い、 `,` は optional な terminator として解釈されます

    ```html
    &yatt:func();                  <!-- func()       引数なし -->
    &yatt:func(1);                 <!-- func(1)      引数1つ -->
    &yatt:func(1,);                <!-- func(1)      引数2つ -->
    &yatt:func(1,2);               <!-- func(1,2)    引数2つ -->
    &yatt:func(1,2,);              <!-- func(1,2)    引数2つ -->
    &yatt:func(1,2,,);             <!-- func(1,2,'') 引数3つ -->
    &yatt:func(1,2,());            <!-- func(1,2,'') 引数3つ -->
    ```

- 括弧内の要素は `:..` で始まる ["path element"](#path-element) と、それ以外の ["literal element"](#literal-element) に分類されます。

    以下の例では、 [:val()](#entity_val) の引数は ["path element"](#path-element) です。

    ```html
    &yatt:val(:foo);
    &yatt:val(:bar[3]);
    &yatt:val(:baz{foo});
    ```

    以下の例では、 [:val()](#entity_val) の引数は ["literal element"](#literal-element) です。

    ```html
    &yatt:val(other);
    &yatt:val({k,v,k2,v2});
    &yatt:val([1,2,3]);
    ```

- 入れ子にする時は`&yatt` と `;` を書きません。

    括弧の要素には path element (か、後述の literal element)
    を入れ子で書くことが出来ます。

    ```html
    &yatt:func(&yatt:dict{name};,&yatt:list[:x];);  <!-- エラー！ -->

    &yatt:func(:dict{name},:list[:x]);              <!-- 正常 -->
    ```

- path element の後には、別の path element を続けて書くことが出来ます。

    ```html
    &yatt:object:method1():method2():method3();

    &yatt:list[:x][:y]:method();

    &yatt:dict{name}:method()[:ix];
    ```

### `:var`  -- 変数参照


変数 `var` の値を埋め込みます。例えば変数 `bar` の値が `"BAR"` だとして、

```html
foo &yatt:bar; baz
```

は

```
foo BAR baz
```

に置換されます。

### `:func(arg...)`  -- 関数呼び出し


そのディレクトリの .htyattrc.pl で定義された Entity `"func"` を呼び出します。
引数は `,` で区切って複数個書くことができます。

例えば、もし引数の合計を計算する関数 `sum()` が entity として宣言してあれば、

```html
3+4+5 = &yatt:sum(3,4,5);
```

は

```
3+4+5 = 12
```

に置換されます。

### `:dict{key}` -- 辞書から取り出し


HASH(辞書)変数 `dict` の要素 `key` を参照します。

例えば変数 `car` に辞書 `{model => "Pulse", maker => "Renault"}`
が入っている場合、

```html
My car is &yatt:car{model};.
```

は

```
My car is Pulse.
```

に置換されます。

### `:list[ix]` -- 配列から取り出し


配列変数 `list` の要素 `ix` を参照します。

## literal element

引数をそのまま返す標準 entity 関数 [:val()](#entity_val) を用いて
[最初の Entity の例](#entpath)を書き直してみましょう。

```html
&yatt:val(:var1);
&yatt:val(:func(arg1,arg2));
&yatt:val(:dict{name});
&yatt:val(:list[:x]);
```

この括弧の中には、上記のような path element の他に、
[配列](#array-lireal)、  [辞書(ハッシュ表)](#hash-literal)、
[文字列](#other-text)をそのまま埋め込むことも出来ます。
これを Entity Path式の ["literal element"](#literal-element) と呼びます。

```html
&yatt:val([1,2,3]);

&yatt:val({name,hkoba,age,XXX});

&yatt:val(rawstring);
```

文字列にスペースを含めたい場合は、文字列全体を `(...)` で囲みます。

```html
&yatt:val((space separated string)));
```

更に文字列 literal の先頭に `=` を入れた場合、
Entity Path式の該当箇所に(制限付きながら)ホスト言語(Perl)の計算式を埋め込むことも可能です。

```html
&yatt:val(=3*8);

&yatt:val((= $x * $y));
```

### `{key,value...}` -- 辞書作り


辞書(HASH表)をそのまま書きたい場合に使います。

```html
&yatt:val({foo,x,bar,y}{foo});  <!-- x を返します -->

&yatt:query(table,{user,hkoba,status,online});

&yatt:dbic:resultset(Artist):search({name,{like,John%}});
```

### `[val,val,...]` -- 配列作り


配列をそのまま書きたい時に使います。

```html
&yatt:val([a,b,c][0]);   <!-- a を返します -->

&yatt:query(table,[user,hkoba,status,online]);
```

### `(spaced text)` -- 空白入り文字列


文字列に空白や `,` などを含めたい時には、全体を `(...)` で囲んで下さい。

```html
&yatt:query((select x, y from t));
```

空文字列(長さゼロの文字列)を明示的に使いたい時も使えます。

```html
&yatt:obj:someMethod(());   <!-- 空文字列を引数として obj.someMethod を呼ぶ -->
```

### `=expr`, `(=expr)` -- 計算式


文字列の先頭が `=` で始まる場合、(perl の)式として扱われます。
部分式に計算式を書きたい時に使います。

```html
&yatt:if(=$x<$y,yes,no);
&yatt:if((= $x < $y),yes,no);
```

### `..other-text..` -- 文字列


以上いずれにも属さない文字列は、単なるテキスト値として扱われます。

**現時点では** ここに perl の `$var` 形式の変数埋め込みを書くことが許されています。

## Examples

例:

```html
&yatt:dict{foo}{:y};
&yatt:list[:y];
&yatt:x[0][:y][1];
&yatt:if(=$$list[0]or$$list[1],yes,no);
&yatt:if(=$$list[0]*$$list[1]==24,yes,no);
&yatt:if((=($$list[0]+$$list[1])==11),yes,no);
&yatt:HTML(:dump([3]));
&yatt:HTML([=3][0]);
&yatt:HTML(=@$var);
```

## BUILTIN Entity

**XXX:** dump, render, HTML, default, join, url\_encode, datetime, mkhash, breakpoint
site\_prefix, site\_config, dir\_config

### `:val()`

第一引数をそのまま返します。第二引数以降は無視します。

```html
&yatt:val(3);      <!-- 3 を返します -->

&yatt:val(a,b,c);  <!-- a を返します -->

&yatt:val();       <!-- undef(null) を返します -->
```

# YATT Declaration

yatt のテンプレートは宣言文と本文の並びです。 yatt宣言 は `<!yatt:...`
で始まり `>` で終わります。以下は宣言の例です。

```html
<!yatt:args
    x y="text" z='code'
    -- コメント --
    body=[
       title="text"
       name="text"
    ]
>

<!yatt:page "/doc/:item">

<!yatt:page other="/foo/:item">

<!yatt:widget another x y>
```

宣言の中に書けるものは、以下のものが有ります。

- `name`, `ns:name...` (ターゲット言語で許された識別子と `:`)

    引数や、widget 自体の名前は、(引用符抜きで) そのまま書くことが出来ます。

- `name=...`

    `...`には `".."`, `'..'`, `[..]` いずれかの引用記法か、
    スペースと閉じタグ `>` を含まない文字列を書くことができます。

- `"text in double quote"`, `'text in single quote'`, `[ ... nested ... ]`

    引数の型やデフォルト値、ルーティングを書くときの記法です。

- `-- ... --`

    宣言の中には [-- ... -- で囲んで](#inline-comment) コメントを書くことが出来ます。

## `<!yatt:args ARGS...>`
  

yatt では、拡張子が `*.yatt` 又は `*.ytmpl` となったファイルは自動的に
widget として扱われ、ファイル名から widget の名前が与えられます。例えば
`index.yatt` は同じディレクトリの別ファイルから `<yatt:index/>`
として呼び出すことが可能です。

そのようにして作った widget は(ファイルの中の) **default widget** と呼ばれます。
この default widget に引数を渡せるようにするための宣言が、 `<!yatt:args>` です。

```html
<!yatt:args x y>
...(以下、このテンプレートでは引数x と y が使用可能に)...
```

引数には ["Argument Declaration"](#argument-declaration) を用いて型やデフォルト値を指定することが出来ます。

また、[URL Pattern](#subrouting) を用いて,
path\_info の残りを引数に用いるよう指定することも出来ます。

```html
<!yatt:args "/:doc" x y>
... (引数 doc, x, y が使用可能に)...
```

## `<!yatt:widget NAME ARGS...>`
 

yatt では一つのテンプレートの中に複数の widget を定義することが出来ます。

```html
<!yatt:widget foo x y>
 ...(foo の定義)...

<!yatt:widget bar x y>
 ...(bar の定義)...
```

このようにして定義した widget は (次の ["page"](#page) とは異なって)
内部的なものであり、外部からのリクエストで勝手に呼び出されることは有りません。

## `<!yatt:page NAME ARGS...>`
 

public な widget を定義します。一つのテンプレートファイルで
複数の page を記述したい時に使います。
ファイル内の page を呼び出すには ["Request Sigil Mapping"](#request-sigil-mapping) か
[URL Pattern](#subrouting) を使って下さい。

```html
<h2>以下をご記入ください</h2>
<form>
 ...
 <input type="submit" name="~confirm" value="確認">
</form>

<!yatt:page confirm>
<h2>入力内容をご確認ください</h2>
...
```

## `<!yatt:action NAME>`
 

テンプレートの中に POST 動作も記述したい時に使います。
action 部分に書けるプログラムの詳細は
[XXX: (未完) prog\_action](https://metacpan.org/pod/YATT%3A%3ALite%3A%3Adocs%3A%3Aprog_action) を参照してください

```html
<!yatt:page confirm>
<h2>入力内容をご確認ください</h2>
<form>
 ...
 <input type="submit" name="!register" value="登録">
</form>

<!yatt:action register>
...(ここからperl のプログラム)...
```

# Request Sigil Mapping

## `~PAGE=title`, `~~=PAGE`

page を呼び出すには POST/GET の parameter に `~ページ名=...` か
 `~~=ページ名` を含めて下さい。(**...** 部分は任意の文字列で構いません。)
(複数同時に送信した場合はエラーになります)

例えば

```html
<input type="submit" name="~back" value="戻る">
<input type="submit" name="~confirm" value="確認画面へ進む">
```

あるいは

```html
<input type="hidden" name="~~" value="confirm">
<input type="submit" value="確認画面へ進む">
```

(submit ボタンが一つしか無いときは、後者の方が安全です)

## `!ACTION=title`, `!!=ACTION`

action を呼び出すには POST/GET の parameter に `!ページ名=...` か
 `!!=ページ名` を含めて下さい。(**...** 部分は任意の文字列で構いません。)
(複数同時に送信した場合はエラーになります)

例えば

```html
<input type="submit" name="~back" value="戻る">
<input type="submit" name="!register" value="登録する">
```

あるいは

```html
<input type="hidden" name="!!" value="register">
<input type="submit" value="登録する">
```

(これも、submit ボタンが一つしか無いときは、後者の方が安全です)

# Inline URL Router


yatt の args 又は page には、URL パターンを書く事が出来ます。

パターンは yatt 宣言の中の先頭(引数よりも前)に
文字列形式 (`'/...'` か `"/..."`) で書きます。

パターンの前に `識別子=` を加えて `name="/..パターン.."` の形式で書いた場合、
`name` が widget の名前として用いられます。
`name=` を省略することも可能です。この場合、URLパターンから
widget 名が自動生成されます。

(パターンは必ず `"/"` で始まる必要が有ります。(将来の拡張のため))

## `<!yatt:args "ROUTE" ARGS...>`


```html
<!yatt:args "/:user">
  ... &yatt:user; ...
```

(`!yatt:args` は (既に名前が決まっているので) `name=` は不要です。)

## `<!yatt:page "ROUTE" ARGS...>`

```html
<!yatt:page "/admin/:action" x y z>
  ...
```

## `<!yatt:page NAME="ROUTE" ARGS...>`

```html
<!yatt:page blog="/blog/:article_id">
  ... &yatt:article_id; ...

<!yatt:page blog_comments="/blog/:article_id/:comment_id">
  ... &yatt:article_id; ... &yatt:comment_id; ...
```

## Routing patterns

実際のルーティングでは、最初に page のパターンが上から順に試され、
最後に args のパターンが試されます。

### `:VAR`


`[^/]+` にマッチしたものが、引数 `:VAR` に渡されます。

```html
<!yatt:page '/authors/:id'>
<!yatt:page '/authors/:id/edit'>
<!yatt:page '/articles/:article_id/comments/:id'>
```

### `{VAR}`


```html
<!yatt:page "/{controller}/{action}/{id}">
<!yatt:page '/blog/{year}/{month}'>
```

### `{VAR:REGEXP}`


```html
<!yatt:page '/blog/{year:[0-9]+}/{month:[0-9]{2}}'>
```

### `{VAR:NAMED_PATTERN}`


```html
<!yatt:page '/blog/{year:digits}-{month:digits}'>
```

**XXX:** named\_pattern の拡張方法を書かねば... 現状では変数の型名とは無関係です。

### `(PATTERN)`


`(PAT)` は、後ろに正規表現の `?` を付けて `(PAT)?` として解釈されます。
つまり, (..) にマッチする内容が無いケースも許すパターンを書きたいときに使います。

```html
<!yatt:args "/:article(/:comment(/:action))">
```

# Argument Declaration

```html
<!yatt:args
    x y z  -- 3つの引数 x y z を宣言。--
    title="text?Hello world!"
           -- text型の引数 title を宣言, デフォルト値は Hello world  --
    yesno="bool/0"
           -- bool型の引数 yesno を宣言, デフォルト値は 0 --
>
```

yatt の widget には引数を宣言することが出来ます。引数宣言は
正式には `引数名 = "型名 フラグ文字 デフォルト値"` の形式で書かれます。
この内、型名は省略可能で、省略時は [text](#text) 型(出力時に全て escape される)に
なります。

引数にデフォルト値を指定するには、型名と区別するため、
[デフォルト・フラグ文字](#default-flag) を書いてからデフォルト値を続けて書きます。

以下は正しい引数宣言の例です。

```html
x
y=text
z="text"

victor="text?bar"
dave  ="?baz"
ginger= "?"
```

# TYPE

引数には(escapeの)型があります。型を指定しなかった場合は ["text"](#text) 型として扱われます。

## `text`


出力時に escape されます。通常はこちらを用います。

```html
<yatt:foo x="my x" y="my y"/>

<!yatt:widget foo x  y="text">
&yatt:x;
&yatt:y;
```

## `html`


引数として渡される値が、既に外側で何らかの方法で
安全な html へと escape 済みであると分かっている場合に指定します。
(なお body 引数の解説は [こちら](#body) を参照してください)

```html
<yatt:bq>
  <h2>foo</h2>
  bar
</yatt:bq>

 <!yatt:widget bq body=html>
 <blockquote>
    &yatt:body;
 </blockquote>
```

## `value`


引数に書いたものがターゲット言語(perl) の計算式として扱われます。
数値など計算結果を渡したい時に使います。

例

```html
<yatt:expr_and_result expr="3 * 4" val="3 * 4"/>

<!yatt:widget expr_and_result expr=text val=value>
&yatt:expr; = &yatt:val;
```

この結果は以下のように表示されます。

    3 * 4 = 12

## `bool`


フラグ用の型です。`=1` を省略出来る以外は、["value"](#value) 型と同じです。

```html
<yatt:foo use_header/>

<!yatt:widget foo use_header="bool/0">
<yatt:if "&yatt:use_header;">
  ...
</yatt:if>
```

## `list`


引数としてターゲット言語のリスト形式のデータを渡したいときに使います。

```html
<yatt:mymenu list="1..5"/>
<yatt:mymenu list="&yatt:some_db_query();"/>

<!yatt:widget mymenu items=list>
<ul>
<yatt:foreach my=item list=items>
  <li>&yatt:item;</li>
</yatt:foreach>
</ul>
```

## `code`


条件式や widget を渡したいときに使います。遅延評価されます。
widget の場合、更に引数の型指定が可能です。
([暗黙の body 引数](#body-argument)はこの型になります。)

```html
<!yatt:widget myquote  author=[code name=text url=text]>

<yatt:foreach my=rec list="&yatt:some_db_query();">
 ...
  <yatt:author name="&yatt:rec{name};" url="&yatt:rec{url};" />
 ...
</yatt:foreach>
```

## XXX: `attr`


## XXX: `delegate`


XXX: `[delegate -exclude_var]`

# DEFAULT FLAG

## `|` - `undef`, `""`, `0`


値が `undef`, `""`, `0` の時はデフォルト値に置き換えられます。
(覚え方：perl の `||` に相当)

```html
<!yatt:args  x="| 1">
```

## `?` - `undef`, `""`


値が `undef`, `""` の時はデフォルト値に置き換えられます。
(覚え方：キーボードの `/` に shift を加えると `?`)

```html
<!yatt:args  x="?foo" y="html?bar">
```

## `/` - `undef`


値が `undef` の時はデフォルト値に置き換えられます。
(覚え方：perl の `//` に相当)

```html
<!yatt:args  x="bool/0">
```

## `!` - mandatory


必ず指定しなければならない引数であることを宣言します。
この指定がある場合、引数を忘れるとコンパイルエラー扱いになります。

```html
<!yatt:args  title="!" x="value!">
```

# Comment block

**XXX:** 将来的に、閉じを `#-->` に変更する案があります。

`<!--#yatt ... -->` で囲まれた範囲は yatt の解析対象から外され、
また出力にも出されません。これに対し、
`#yatt` を含まない普通の `<!--...-->` は、その通りに出力されます。

もし yatt のテンプレートにうまく動かずエラーになる箇所がある時に、
そこをコメントアウトする(字面上は残しつつ、機能はさせない、
単なるコメントにする)には、必ず `#yatt` のついた、 yatt のコメントを使って下さい。

## Inline comment

[!yatt宣言](#yatt-declaration) や
[widget 呼び出しタグ](#widget-invocation),
[タグ型引数](#attribute-element) の中にも、制限付きながら
`-- ... --` でコメントを書き入れることが出来ます(タグ内コメント)。

制限としては、「使える文字が制限される(ex. 中にタグは書けない)」、
「タグの終わり, コメントの終わり」と誤解される書き方は出来ない、があります。

タグ内コメントの例を挙げます。

```html
<yatt:foo id="myfoo" -- id="mybar" と書こうと思ったけどやめた -- >
  ...
<:yatt:title  -- ここにもコメントを書けます -- />
  <h2>あれやこれや</h2>
</yatt:foo>


<!yatt:widget foo
   id -- id には dom id を入れて下さい, とかなんとか --
   title -- title には○○を入れて下さい... --
>
...
```

# Processing instruction

- `<?perl= ... ?>`

    処理結果を escape して出力します。

- `<?perl=== ... ?>`

    escape せずに、生のままで結果を出力します。

- `<?perl ... ?>`

    単純に処理だけ行います。
