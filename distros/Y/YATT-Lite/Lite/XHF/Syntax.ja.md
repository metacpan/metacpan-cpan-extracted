# NAME

YATT::Lite::XHF::Syntax(ja) - Extended Header Fields (XHF) フォーマットの構文定義

# SYNOPSIS

```perl
require YATT::Lite::XHF;

my $parser = YATT::Lite::XHF->new(string => <<'END');
# Taken from http://docs.ansible.com/YAMLSyntax.html#yaml-basics
name: Example Developer
job: Developer
skill: Elite
employed: 1
foods[
- Apple
- Orange
- Strawberry
- Mango
]
languages{
ruby: Elite
python: Elite
dotnet: Lame
}

name: hkoba
languages{
yatt: Elite?
}
END

# read() は(\n\n+ で区切られた)一パラグラフ分のレコードを返します,
# リストコンテキストでは, 戻り値はフラットなリストです。
# 通常、それは キー: 値 組のリストですが、それ以外のものを含めることも出来ます。
# スカラコンテキストで呼び出した場合は hash が返ります
while (my %hash = $parser->read) {
  print Dumper(\%hash), "\n";
}
```

# DESCRIPTION

Extended Header Fields (**XHF**) フォーマットとは
hkoba が独自に定義した俺々フォーマットで、
[電子メールのヘッダ](http://tools.ietf.org/html/rfc2822#section-2.2)
や [HTTP の ヘッダ](http://tools.ietf.org/html/rfc2616#section-4.2)
をベースに、 _入れ子データ構造_ のための拡張を加えたものです。
XHF 形式のファイルや文字列を load/parse するには [YATT::Lite::XHF](https://metacpan.org/pod/YATT%3A%3ALite%3A%3AXHF)
を使って下さい。

Note: 元々 XHF は unit test のテスト入力・出力ペアを簡単に書くために
設計されました。シリアライザ ([YATT::Lite::XHF::Dumper](https://metacpan.org/pod/YATT%3A%3ALite%3A%3AXHF%3A%3ADumper)) も用意してありますが、
決して完全な(perl の任意のデータ構造をシリアライズすることを目指した)ものでは
ありません。そのような用途には [YAML](https://metacpan.org/pod/YAML) 一族や, [Storable](https://metacpan.org/pod/Storable) などを用いて下さい。

## 最小限のエスケープルール


最も単純な用途では、 YAML と XHF はとても良く似て見えます。例えば、
`{foo => 1, bar => 2}` というデータを表現する時、YAML と
XHF は同じように書けます。

    foo: 1
    bar: 2

しかし、少し複雑なデータ構造になると、段々違いが見えてきます。
例えば `{x => [1, 2, "3, 4"], y => 5}` は、

**XHF** では以下のように書けます:

    {
    x[
    - 1
    - 2
    - 3, 4
    ]
    y: 5
    }

同じものを **YAML** ではこう書くでしょう：

    ---
    x:
      - 1
      - 2
      - '3, 4'
    y: 5

両者の違いは:

- XHF は **括弧** ` {} [] ` を用い、YAML は **字下げ** を使って構造を表す。
- XHF では `3, 4` はそのまま表記できるが、YAML では **エスケープして** `'3, 4'` と書かねばならない。

### 複数行文字列と、"書いたまま"モード


XHF の `キー：値` ペアの **値** 部分では、エスケープする必要がある文字は
改行文字 `\n` (と、値の前後の空白文字) だけです。
つまり、値部分には全く「構文」がありません。ですので、
値部分を書く時に覚えなければならないことは、実質的に無いも同然なのです。

- 値の中に改行を含めたい場合
 

    単純に、全ての改行 `"\n"` を改行+SPACE `"\n "` で置換して下さい。
    つまり `s/\n/\n /g` するだけです。

    例： `{ foo => "1\n2\n\n3", bar => 4 }` は以下のように書けます:

        foo: 1
         2
         
         3
        bar: 4

- 先頭・末尾にスペース/タブ/改行を残したい場合は？


    キーと値の区切りを、 `": "` の代わりに `":\n"` で書くだけです。
    後は他と同様、値の中の `"\n"` をエスケープするだけで構いません。

    例： `{ foo => "  x  ", bar => "\n\ny\n\n" }` は以下のように書けます:

        foo:
          x  
        bar:
         
         
         y
         
         

## キーと値を個別のアイテムとして書ける


XHF のキー部分には、書ける文字に強い制限が有ります(値部分と違って).
具体的には `[[:alnum:]]`, `"-"`, `"."`, `"/"` そして
幾つかの追加の文字(詳細は ["BNF"](#bnf) の _field-name_ の定義を参照) です。

しかしながら、 `キー: 値` と書く代わりに、`- キー`, `- 値` と２つのアイテムを
連続して書くことで、同じ意味を表すことが出来ます。この２つの書き方は、
どこでも入れ替えて使うことが出来ます。
ですので、もし面倒なら、キー部分を全部 `- キー` 表記で書いて、
(値と同じく)改行 `\n` だけエスケープする、でも構いません。

    # 例えば、以下のブロック：

    foo: 1
    bar: 2

    # 上記は、以下と同じ結果になります

    - foo
    - 1
    - bar
    - 2

例： `{ "foo bar" => "baz" }` は以下のように書けます：

    {
    - foo bar
    - baz
    }

別の例： `{ "\n  foo\nbar  \n" => "baz" }` は以下のように書けます。

    {
    -
    
       foo
     bar
    
    - baz
    }

入れ子になったデータ構造でも、同じ法則が適用できます。

    foo{
    x: 1
    y: 2
    }
    baz[
    - z
    ]

    # can be written instead as following:

    - foo
    {
    x: 1
    y: 2
    }
    - baz
    [
    - z
    ]

    # or even like following:

    - foo
    {
    - x
    - 1
    - y
    - 2
    }
    - baz
    [
    - z
    ]

`キー: 値` 記法は配列の中でも使えます：

    [
    foo: 1
    bar: 2
    ]

    # above is equal to following

    [
    - foo
    - 1
    - bar
    - 2
    ]

## リストを格納するコンテナの型は外側が決める


もう一つの重要な違いは、コンテナの型の選択方法です。
XHF では キー・値を区切る区切り文字は、"値部分の型" を決めるものです。
これは区切り文字が外側のコンテナの型を決める YAML とは大きく違います。

XHF では、以下のブロック：

    foo: 1
    bar: 2

は、`( foo => 1, bar => 2 )` つまり４つの要素からなるフラットなリスト、を表します。このリストをどんなコンテナに格納するのかは、呼び出し側が自由に決めて構いません。
例えば辞書に格納したいなら:

```perl
my %dict = $parser->read;
```

配列に格納したいなら:

```perl
my @array = $parser->read;
```

なお、もしスカラコンテキストで呼び出した場合は、辞書が作られます
(もし奇数個しか要素がないなら、エラーになります).

```perl
my $dict = $parser->read;
```

これに対して YAML では `:` は常に _map(dictionary)_ を意味します。
ですので、上記は `+{ foo => 1, bar => 2 }` を返すでしょう。

### 順序付き、キー・値ペアのリスト、重複有り


以上のように XHF のブロックの一番外側はフラットなリストを表しているので、
そこには (Perl の HASH データ構造から来る) 制限は適用されません。
従って、Perl の HASH では許されないような、キーの順序や、キーの重複を
表現することも、以下のように一応可能です：

    foo: 1
    foo: 2
    foo: 3
    bar: x
    bar: y

上記を以下のスクリプトで読むと

```perl
my @array = $parser->read;
```

`@array` には `(foo => 1, foo => 2, foo => 3, bar => 'x', bar => 'y')`
が格納されるでしょう。

この機能は、ある種のテストデータを表現するために、時に大いに役立ちます。
(例えば HTTP のクエリ引数や、
Email ヘッダの "Received" フィールド). 例えば上記の XHF が表すデータと
等価な http クエリパラメータを作る html form は、以下のように書けるでしょう：

```html
<input type="checkbox" name="foo" value="1">
<input type="checkbox" name="foo" value="2">
<input type="checkbox" name="foo" value="3">
<input type="checkbox" name="bar" value="x">
<input type="checkbox" name="bar" value="y">
```

Note: 現在のところ、入れ子要素は perl の普通の HASH と ARRAY に変換されます。
ですので、上記の順序・重複保護が有効に働くのは、一番外側のみです。

## パラグラフのストリーム (コメント読み飛ばし付き)


XHF の入力ストリームは連続空行 `"\n\n+"` で区切られます
(これは Email ヘッダや HTTP ヘッダと同様です)。
これは Perl の(懐かしの) パラグラフモードに基づく複数行レコードのフォーマットが
ベースになっています。Perl でパラグラフモードを扱うためのマニュアルは
[perl -00](https://metacpan.org/pod/perlrun#pod-0) や [Setting $RS to ""](https://metacpan.org/pod/perlvar#RS) を参照して下さい。

Note: XHF では "コメントのみを含む" ブロックは自動的に読み捨てられます。例えば：

    foo: 1
    bar: 2

    # どや！ ここにコメントだけのブロックがおんねん！


    baz: 3
    qux: 4

上記を以下のスクリプトで読むとします：

```perl
my @records;
push @records, $_ while $_ = $parser->read;
```

すると `@records` には２つの要素
`({foo => 1, bar => 2}, {baz => 3, qux => 4})` だけが入ります。

### メタ要素を入れたいときは?


ごく稀に、一つのストリームに、メタ情報的なものを含めたり、含めなかったり！
したくなる時が有ります。そんな時は、ストリームの先頭で、一回だけ
`read(skip_comment => 0)` のように、
"コメントのみブロック"の読み捨て機能をオフにして読み込む、というハックが使えます：

    # これがメタ情報. 下の test => 1 を有効にするには、次の行頭の "# " を削って下さい
    # test: 1


    # This is body1
    foo: 1
    bar: 2

    # This is body2
    foo: 3
    bar: 4

スクリプトはこんな感じです。

```perl
if (my @meta = $parser->read(skip_comment => 0)) {
  # process metainfo. You may get (test => 1).
}
while (my @content = $parser->read) {
  # process body1, body2, ...
}
```

# 複雑な例 (YAML との対比つき)


Here is a more dense example **in XHF**:

    name: hkoba
    # (1) You can write a comment line here, starting with '#'.
    job: Programming Language Designer (self-described;-)
    skill: Random
    employed: 0
    foods[
    - Sushi
    #(2) here too. You don't need space after '#'. This will be good for '#!'
    - Tonkatsu
    - Curry and Rice
    [
    - More nested elements
    ]
    ]
    favorites[
    # (3) here also.
    {
    title: Chaika - The Coffin Princess
    # (4) ditto.
    heroine: Chaika Trabant
    }
    {
    title: Witch Craft Works
    heroine: Ayaka Kagari
    # (5) You can use leading "-" for hash key/value too (so that include any chars)
    - Witch, Witch!
    - Tower and Workshop!
    }
    # (6) You can put NULL(undef) like below. (equal space sharp+keyword)
    = #null
    ]

Above will be loaded like following structure:

```perl
$VAR1 = {
        'foods' => [
                   'Sushi',
                   'Tonkatsu',
                   'Curry and Rice',
                   [
                     'More nested element'
                   ]
                 ],
        'job' => 'Programming Language Designer (self-described;-)',
        'name' => 'hkoba',
        'employed' => '0',
        'skill' => 'Random',
        'favorites' => [
                       {
                         'heroine' => 'Chaika Trabant',
                         'title' => 'Chaika - The Coffin Princess'
                       },
                       {
                         'title' => 'Witch Craft Works',
                         'heroine' => 'Ayaka Kagari',
                         'Witch, Witch!' => 'Tower and Workshop!'
                       },
                       undef
                     ]
      };
```

Above will be written **in YAML** like below (note: inline comments are omitted):

    ---
    employed: 0
    favorites:
      - heroine: Chaika Trabant
        title: 'Chaika - The Coffin Princess'
      - 'Witch, Witch!': Tower and Workshop!
        heroine: Ayaka Kagari
        title: Witch Craft Works
      - ~
    foods:
      - Sushi
      - Tonkatsu
      - Curry and Rice
      -
        - More nested element
    job: Programming Language Designer (self-described;-)
    name: hkoba
    skill: Random

This YAML example clearly shows how you need to escape strings quite randomly,
e.g. see above value of `$VAR1->{favorites}[0]{title}`.
Also the key of `$VAR1->{favorites}[1]{'Witch, Witch!'}` is nightmare.

I don't want to be bothered by this kind of escaping.
That's why I made XHF.

# FORMAT SPECIFICATION


XHF は(空行で区切られた)パラグラフ一個ずつの単位でパースされます。
個々のパラグラフは複数の `xhf-item` を含むことが出来ます。
全ての xhf-item は必ず行の先頭から始まり、最後は改行で終わります。
xhf-item は以下の２つのうち、どちらかの形式を取ります。

    <name> <type-sigil> <sep> <value>         (name-value pair)

    <type-sigil> <sep> <value>                (standalone value)

`type-sigil` は `value` の型を決めます。
`sep` は空白文字(スペース、タブ、改行) のいずれかです。
`sep`が改行の場合は [書いたままモード(verbatim text)](#verbatim-text)) を意味します。
ただし dict/array ブロックの場合は、`sep` は改行だけしか許されません。

`type-sigil` の全リストと、使える `sep` は以下の通りです。

- `"name:"` then `" "` or `"\n"`

    `":"` は文字列値を(名前付きで)格納します。名前の省略は出来ません。
    `sep` は全ての空白文字です。

- `"-"` then `" "` or `"\n"`

    `"-"` は文字列値を(名前抜きで)格納します。名前は書いてはいけません。

    (Note: Currently, `","` works same as `"-"`. This feature is arguable.)

- `"{"` then `"\n"`
- `"name{"` then `"\n"`

    `"{"` は辞書ブロック (` { %HASH } ` コンテナ)の始まりです。
    名前を付けることが出来ます。

    このブロックは `"}\n"` で閉じられねばなりません。
    また、要素の個数は偶数個でなければなりません。

- `"["` then `"\n"`
- `"name["` then `"\n"`

    `"["` は配列ブロック(` [ @ARRAY ] ` コンテナ)の始まりです。
    名前をつけることが出来ます。

    このブロックは `"]\n"` で閉じられねばなりません。

- `"="` then `" "` or `"\n"`
- `"name="` then `" "` or `"\n"`

    `"="` は特別な値を格納するために使います。
    名前を付けることが出来ます。

    現状では、`#undef` と、同じ意味の別表記である `#null` だけが定義されています。

- `"#"`

    `"#"` は埋め込みコメントを格納するために使います。
    名前を付けることは出来ません。

## XHF Syntax definition in extended BNF
 

Here is a syntax definition of XHF in extended BNF
(_roughly_ following [ABNF](https://tools.ietf.org/html/rfc5234).)

    xhf-block       = 1*xhf-item

    xhf-item        = field-pair / single-text
                     / dict-block / array-block / special-expr
                     / comment

    field-pair      = field-name  field-value

    field-name      = 1*NAME *field-subscript

    field-subscript = "[" *NAME "]"

    field-value     = ":" text-payload / dict-block / array-block / special-expr

    text-payload    = ( trimmed-text / verbatim-text ) NL

    trimmed-text    = SPTAB *( 1*NON-NL / NL SPTAB )

    verbatim-text   = NL    *( 1*NON-NL / NL SPTAB )

    single-text     = "-" text-payload

    dict-block      = "{" NL *xhf-item "}" NL

    array-block     = "[" NL *xhf-item "]" NL

    special-expr    = "=" SPTAB known-specials NL

    known-specials  = "#" ("null" / "undef")

    comment         = "#" *NON-NL NL

    NL              = [\n]
    NON-NL          = [^\n]
    SPTAB           = [\ \t]
    NAME            = [0-9A-Za-z_.-/~!]

## Some notes on current definition


- field-name, field-subscript

    **field-name** can contain `/`,  `.`, `~` and `!`.
    Former two are for file names (path separator and extension separator).
    Later two (and **field-subscript**) are incorporated just to help
    writing test input/output data for [YATT::Lite](https://metacpan.org/pod/YATT%3A%3ALite),
    so these can be arguable for general use.

- trimmed-text vs verbatim-text

    If **field-name** is separated by `": "`, its **field-value** will be trimmed
    their leading/trailing spaces/tabs.
    This is useful to handle hand-written configuration files.

    But for some software-testing purpose(e.g. templating engine!),
    this space-trimming makes it impossible to write exact input/output data.

    So, when **field-sep** is NL, field-value is not trimmed.

- LF vs CRLF

    Currently, I'm not so rigid to reject the use of CRLF.
    This ambiguity may harm use of XHF as a serialization format, however.

- `","` can be used in-place of `"-"`.

    This feature also may be arguable for general use.

- `":"` without `name` was valid, but is now deprecated.

    Previously valid

        : bar

    which represents `( "" => "bar" )`, is now invalid.
    Please use two `"- "` items like following:

        - 
        - bar

    XXX: Hmm, should I provide deprecation cycle? Are there someone
    already used XHF to serialize important data even before having this manual?
    If so, please contact me. I will add an option to allow this.

- line-continuation is valid.

    Although [line-continuation](#line-continuation) is obsoleted
    in [HTTP headers](http://tools.ietf.org/html/rfc7230#section-3.2.4),
    line-continuation will be kept valid in XHF spec. This is my preference.

# AUTHOR

"KOBAYASI, Hiroaki" <hkoba@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
