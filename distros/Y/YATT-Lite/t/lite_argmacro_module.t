#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# Perl モジュールで定義した ArgMacro (YATT::Lite::ArgMacro) のテスト。
#
#  - 1 pm = 1 macro。use YATT::Lite::ArgMacro out => [...], in => [...]
#  - Site 設定 argmacro => {name => 'Module'} で登録し、%name; で使う
#  - Args/Vars/Result の field 名 typo は pm のコンパイル時に検出される
#  - refer => [...] はマクロが参照するだけの widget 引数(トリガーにならない)
#  - out を明示するとマクロは bypass される(同じ instance の in はエラー)
#  - on_expand の第 6 引数は呼び出しの $node。in 引数から式を作るには
#    $cgen->try_pass_through / as_cast_node_to / as_expr_node
#    (旧 YATT の try_pass_through / faked_gentype / faked_genexpr)、
#    行番号付きエラーは $cgen->generror_at
#  - Module->expand_element($cgen, $node) で、通常のマクロ (foreach 等) の
#    要素の属性に展開できる (旧 YATT の create_from)
#  - on_expand の結果に引数 node を返すと、出力名に付け替えて渡す
#    (pass through の検査は受け手が行う)
#  - argmacro => [[ns => {name => 'Module'}], {...}] で名前空間付き登録。
#    %ns:name; は登録表のみ、%name; はページ内 → base → primary ns の登録
#  - %yatt:NAME; / %yatt:NAME(VALUE); は part の option yatt_NAME を設定する
#    (yatt_NAME が Part の field に無ければ argmacro の探索に落ちる)
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use File::Temp qw/tempdir/;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite;
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}
my $testno = 0;

my $libdir = "$tempdir/lib";
unshift @INC, $libdir;

YATT::Lite::Util::File->mkfile_may_wait(
  "$libdir/TestArgMacro/Pair.pm" => <<'END',
package TestArgMacro::Pair;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(x y)],
  in  => [qw(pair)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  my ($x, $y) = split /\s*,\s*/, $cgen->node_value($args->{pair});
  $result->{x} = $x;
  $result->{y} = $y;
  $result;
}
1;
END

  "$libdir/TestArgMacro/Enum.pm" => <<'END',
package TestArgMacro::Enum;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(list=list)],
  in  => ['first=value/0', 'last=value!'];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  my $firstExpr = $args->{first} ? $cgen->node_value($args->{first})
    : $vars->{first}->default;
  my $lastExpr = $cgen->node_value($args->{last});
  $result->{list} = sprintf(q{%s .. %s}, $firstExpr, $lastExpr);
  $result;
}
1;
END

  "$libdir/TestArgMacro/Typo.pm" => <<'END',
package TestArgMacro::Typo;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(x)],
  in  => [qw(pair)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  $result->{xx} = $cgen->node_value($args->{pair});
  $result;
}
1;
END

  (map {
    my ($pkg, $out, $in, $value) = @$_;
    ("$libdir/TestArgMacro/$pkg.pm" => <<END);
package TestArgMacro::$pkg;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw($out)],
  in  => [qw($in)];

sub on_expand {
  (my MY \$class, my CGen \$cgen, my Args \$args, my Vars \$vars) = \@_;
  my Result \$result = {};
  \$result->{$out} = q{$value};
  \$result;
}
1;
END
  } ([SrcA => src => tag => 'modA'], [SrcB => src => tag => 'modB'],
     [OtherC => other => otag => 'modC'])),

  "$libdir/TestArgMacro/Greet.pm" => <<'END',
package TestArgMacro::Greet;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(greeting)],
  in  => [qw(who)],
  refer => [qw(lang)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  my $lang = $args->{lang} ? $cgen->node_value($args->{lang})
    : $vars->{lang} ? 'declared' : 'undeclared';
  $result->{greeting} = "$lang/".$cgen->node_value($args->{who});
  $result;
}
1;
END

  "$libdir/TestArgMacro/Strict.pm" => <<'END',
package TestArgMacro::Strict;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(greeting)],
  in  => [qw(who)],
  refer => [qw(lang)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  die "widget must declare lang\n" unless $vars->{lang};
  my Result $result = {};
  $result->{greeting} = $cgen->node_value($args->{who});
  $result;
}
1;
END

  "$libdir/TestArgMacro/Join.pm" => <<'END',
package TestArgMacro::Join;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(val=value)],
  in  => [qw(a b n)];

# 旧 YATT 風に、in 引数から式を組み立てる
sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars
   , my ArgMacro $argmacro, my $node) = @_;
  my Result $result = {};
  my @expr;
  push @expr, $cgen->try_pass_through($args->{a})
    // $cgen->as_cast_node_to(text => $args->{a})
    if $args->{a};
  push @expr, $cgen->try_pass_through($args->{b}, q{'dflt'})
    // $cgen->as_cast_node_to(text => $args->{b})
    if $args->{b};
  push @expr, $cgen->as_expr_node($args->{n}, 0)
    if $args->{n};
  $result->{val} = sprintf q{join("-", %s)}, join(", ", @expr);
  $result;
}
1;
END

  "$libdir/TestArgMacro/NeedVar.pm" => <<'END',
package TestArgMacro::NeedVar;
use strict;
use warnings;
use YATT::Lite::Constants; # NODE_LNO
use YATT::Lite::ArgMacro
  out => [qw(val=value)],
  in  => [qw(src)];

# src は変数でなければならない
sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars
   , my ArgMacro $argmacro, my $node) = @_;
  my Result $result = {};
  $result->{val} = $cgen->try_pass_through($args->{src})
    // die $cgen->generror_at($node->[NODE_LNO], q{src must be a variable});
  $result;
}
1;
END

  "$libdir/TestArgMacro/Range.pm" => <<'END',
package TestArgMacro::Range;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(list=list)],
  in  => [qw(from to)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars
   , my ArgMacro $argmacro, my $node) = @_;
  my Result $result = {};
  my ($from, $to) = map {
    $args->{$_} ? ($cgen->try_pass_through($args->{$_})
                   // $cgen->as_expr_node($args->{$_}, 0))
      : 0
  } qw(from to);
  $result->{list} = "$from .. $to";
  $result;
}
1;
END

  "$libdir/TestArgMacro/SrcList.pm" => <<'END',
package TestArgMacro::SrcList;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(list=list)],
  in  => [qw(src)];

# src の node をそのまま list に (受け手の pass through 規則に任せる)
sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  $result->{list} = $args->{src};
  $result;
}
1;
END

  "$libdir/TestArgMacro/SrcVal.pm" => <<'END',
package TestArgMacro::SrcVal;
use strict;
use warnings;
use YATT::Lite::ArgMacro
  out => [qw(val=value)],
  in  => [qw(src)];

sub on_expand {
  (my MY $class, my CGen $cgen, my Args $args, my Vars $vars) = @_;
  my Result $result = {};
  $result->{val} = $args->{src};
  $result;
}
1;
END

  "$libdir/TestArgMacro/NotAMacro.pm" => <<'END',
package TestArgMacro::NotAMacro;
sub on_expand {}
1;
END
);

my $make_app = sub {
  my ($argmacro, @rest) = @_;
  my @opts = ref $rest[0] eq 'ARRAY' ? @{shift @rest} : ();
  my %files = @rest;
  my $app_root = "$tempdir/t" . ++$testno;
  my $docroot = "$app_root/docs";
  YATT::Lite::Util::File->mkfile_may_wait(
    map {("$docroot/$_" => $files{$_})} keys %files
  );
  YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "TestArgMacroModule$testno",
    app_root => $app_root,
    doc_root => $docroot,
    argmacro => $argmacro,
    @opts,
  );
};

# code 生成時のエラーは SiteApp->render だと \"DONE" になるため (GH-290)、
# 直接 find_product でコンパイルしてエラーを返す。
my $compile_err = sub {
  my ($site, $page) = @_;
  my $yatt = $site->get_yatt('/');
  local $YATT::Lite::YATT = $yatt;
  local $yatt->{error_handler} = sub {die $_[1]->message};
  local $@;
  eval {
    my $trans = $yatt->open_trans;
    $trans->find_product(perl => $trans->find_file($page));
  };
  $@;
};

describe "argmacro defined in perl module", sub {
  my $site = $make_app->(
    {pair => 'TestArgMacro::Pair', enum => 'TestArgMacro::Enum'},
    'pair.yatt' => <<'END',
<yatt:foo pair="3, 8"/>

<!yatt:widget foo %pair;>
x=&yatt:x; y=&yatt:y;
END
    'enum.yatt' => <<'END',
<yatt:bar header=2 label=1/>

<!yatt:widget bar
  %enum(header=last);
  %enum(label=last);
>
<yatt:foreach my=row list=label_list><yatt:foreach my=col list=header_list
>[&yatt:row;&yatt:col;]</yatt:foreach></yatt:foreach>
END
    'override.yatt' => <<'END',
<yatt:foo pair="3, 8"/>

<!yatt:argmacro pair=[x y] pair>
my ($x, $y) = split /\s*,\s*/, $cgen->node_value($args->{pair});
$result->{x} = "local$x";
$result->{y} = "local$y";

<!yatt:widget foo %pair;>
x=&yatt:x; y=&yatt:y;
END
  );

  it "should expand macro from module", sub {
    expect($site->render("pair"))->to_match(qr/x=3 y=8/);
  };

  it "should expand renamed macro from module", sub {
    expect($site->render("enum"))
      ->to_match(qr/\[00\]\[01\]\[02\]\[10\]\[11\]\[12\]/);
  };

  it "should prefer argmacro declared in template", sub {
    expect($site->render("override"))->to_match(qr/x=local3 y=local8/);
  };
};

describe "errors", sub {
  my $site = $make_app->(
    {notamacro => 'TestArgMacro::NotAMacro'},
    'unknown.yatt' => <<'END',
<!yatt:widget foo %nosuch;>
END
    'notamacro.yatt' => <<'END',
<!yatt:widget foo %notamacro;>
END
  );

  it "should report unknown argmacro", sub {
    expect(do {local $@; eval {$site->render("unknown")}; $@})
      ->to_match(qr/Unknown argmacro 'nosuch'/);
  };

  it "should reject module which is not a YATT::Lite::ArgMacro", sub {
    expect(do {local $@; eval {$site->render("notamacro")}; $@})
      ->to_match(qr/is not a YATT::Lite::ArgMacro/);
  };

  it "should compile the module alone with perl -c", sub {
    my @inc = map {"-I$_"} grep {not ref $_} @INC;
    my $out = qx{$^X @inc -c $libdir/TestArgMacro/Join.pm 2>&1};
    expect($out)->to_match(qr/syntax OK/);
  };

  it "should detect typo of field name at compile time of the module", sub {
    expect(do {local $@; eval {require TestArgMacro::Typo}; $@})
      ->to_match(qr/No such class field "xx" in variable \$result of type TestArgMacro::Typo::Result/);
  };
};

describe "refer", sub {
  my $site = $make_app->(
    {greet => 'TestArgMacro::Greet', strict => 'TestArgMacro::Strict'},
    'strict.yatt' => <<'END',
<yatt:w who="bob"/>

<!yatt:widget w %strict;>
g=&yatt:greeting;
END
    'given.yatt' => <<'END',
<yatt:w who="bob" lang="ja"/>

<!yatt:widget w lang %greet;>
g=&yatt:greeting; lang=&yatt:lang;
END
    'omitted.yatt' => <<'END',
<yatt:w who="bob"/>

<!yatt:widget w lang="?en" %greet;>
g=&yatt:greeting; lang=&yatt:lang;
END
    'undeclared.yatt' => <<'END',
<yatt:w who="bob"/>

<!yatt:widget w %greet;>
g=&yatt:greeting;
END
    'referonly.yatt' => <<'END',
<yatt:w lang="ja"/>

<!yatt:widget w lang %greet;>
g=&yatt:greeting; lang=&yatt:lang;
END
  );

  # XXX: SiteApp->render は一度成功した後のエラーを \"DONE" で返すため (GH-290)、
  # エラーになるページを先に render する。
  it "should let on_expand reject undeclared refer arg", sub {
    expect(do {local $@; eval {$site->render("strict")}; $@})
      ->to_match(qr/widget must declare lang/);
  };

  it "should pass refer arg to both macro and widget", sub {
    expect($site->render("given"))->to_match(qr{g=ja/bob lang=ja});
  };

  it "should give widget var of refer arg when omitted", sub {
    expect($site->render("omitted"))->to_match(qr{g=declared/bob lang=en});
  };

  it "should not require widget to declare refer arg", sub {
    expect($site->render("undeclared"))->to_match(qr{g=undeclared/bob});
  };

  it "should not trigger macro by refer arg", sub {
    expect($site->render("referonly"))->to_match(qr{g= lang=ja});
  };
};

describe "bypass by explicit output", sub {
  my $site = $make_app->(
    {greet => 'TestArgMacro::Greet', pair => 'TestArgMacro::Pair'},
    'in_out.yatt' => <<'END',
<yatt:w greeting="hi" who="bob"/>

<!yatt:widget w %greet;>
g=&yatt:greeting;
END
    'out_in.yatt' => <<'END',
<yatt:w who="bob" greeting="hi"/>

<!yatt:widget w %greet;>
g=&yatt:greeting;
END
    'renamed_err.yatt' => <<'END',
<yatt:w p="1, 2" p_x=5/>

<!yatt:widget w %pair(p=pair);>
x=&yatt:p_x; y=&yatt:p_y;
END
    'tmpl_err.yatt' => <<'END',
<yatt:w pair="1, 2" x=5/>

<!yatt:argmacro pair2=[x y] pair>
my ($x, $y) = split /\s*,\s*/, $cgen->node_value($args->{pair});
$result->{x} = $x;
$result->{y} = $y;

<!yatt:widget w %pair2;>
x=&yatt:x; y=&yatt:y;
END
    'out.yatt' => <<'END',
<yatt:w greeting="hi" lang="ja"/>

<!yatt:widget w lang %greet;>
g=&yatt:greeting; lang=&yatt:lang;
END
    'renamed.yatt' => <<'END',
<yatt:w p_x=5 p_y=6/>

<!yatt:widget w %pair(p=pair);>
x=&yatt:p_x; y=&yatt:p_y;
END
  );

  my $err = sub {$compile_err->($site, @_)};

  it "should reject input with explicit output", sub {
    expect($err->("in_out"))
      ->to_match(qr/argmacro %greet; is bypassed by explicit output 'greeting'; input 'who' can't be given/);
  };

  it "should reject input with explicit output regardless of order", sub {
    expect($err->("out_in"))
      ->to_match(qr/argmacro %greet; is bypassed by explicit output 'greeting'; input 'who' can't be given/);
  };

  it "should reject input with explicit renamed output", sub {
    expect($err->("renamed_err"))
      ->to_match(qr/argmacro %pair\(p=pair\); is bypassed by explicit output 'p_x'; input 'p' can't be given/);
  };

  it "should reject input with explicit output (template argmacro)", sub {
    expect($err->("tmpl_err"))
      ->to_match(qr/argmacro %pair2; is bypassed by explicit output 'x'; input 'pair' can't be given/);
  };

  it "should pass explicit output", sub {
    expect($site->render("out"))->to_match(qr/g=hi lang=ja/);
  };

  it "should pass explicit renamed output", sub {
    expect($site->render("renamed"))->to_match(qr/x=5 y=6/);
  };
};

describe "building expressions from input args", sub {
  my $site = $make_app->(
    {join => 'TestArgMacro::Join', needvar => 'TestArgMacro::NeedVar'},
    'pass.yatt' => <<'END',
<yatt:foreach my=x list="1..2"><yatt:w a=x b="lit"/></yatt:foreach>

<!yatt:widget w %join;>
[&yatt:val;]
END
    'entity.yatt' => <<'END',
<yatt:foreach my=x list="1..1"><yatt:w a="v&yatt:x;"/></yatt:foreach>

<!yatt:widget w %join;>
[&yatt:val;]
END
    'dflt.yatt' => <<'END',
<yatt:w a="p" b/>

<!yatt:widget w %join;>
[&yatt:val;]
END
    'namevar.yatt' => <<'END',
<yatt:foreach my=b list="'bb'"><yatt:w a="p" b/></yatt:foreach>

<!yatt:widget w %join;>
[&yatt:val;]
END
    'expr.yatt' => <<'END',
<yatt:foreach my=x list="1..1"><yatt:w a="p" n="&yatt:x; * 10"/></yatt:foreach>

<!yatt:widget w %join;>
[&yatt:val;]
END
    'tmpl.yatt' => <<'END',
<yatt:foreach my=x list="1..2"><yatt:w a=x/></yatt:foreach>

<!yatt:argmacro tjoin=[val=value] a>
$result->{val} = $cgen->try_pass_through($args->{a})
  // $cgen->as_cast_node_to(text => $args->{a});

<!yatt:widget w %tjoin;>
[&yatt:val;]
END
    'nosuch.yatt' => <<'END',
<!yatt:args>


<yatt:w
  a=nosuch/>

<!yatt:widget w %join;>
END
    'badtype.yatt' => <<'END',
<!yatt:args>
<yatt:w a="x"/>

<!yatt:argmacro tbad=[val=value] a>
$result->{val} = $cgen->as_cast_node_to(code => $args->{a});

<!yatt:widget w %tbad;>
END
    'needvar.yatt' => <<'END',
<!yatt:args>

<yatt:w
  src="1"/>

<!yatt:widget w %needvar;>
END
    'tmpl_needvar.yatt' => <<'END',
<!yatt:args>

<yatt:w src="1"/>

<!yatt:argmacro tneed=[val=value] src>
$result->{val} = $cgen->try_pass_through($args->{src})
  // die $cgen->generror_at($node->[NODE_LNO], q{src must be a variable});

<!yatt:widget w %tneed;>
END
  );

  my $err = sub {$compile_err->($site, @_)};

  it "should report unknown variable with the line of the arg", sub {
    expect($err->("nosuch"))
      ->to_match(qr{No such variable 'nosuch' at file \S+/nosuch.yatt line 5\b});
  };

  it "should reject unsupported type", sub {
    expect($err->("badtype"))
      ->to_match(qr{No such argtype: code at file \S+/badtype.yatt line 2\b});
  };

  it "should report error raised by on_expand with the line of the call", sub {
    expect($err->("needvar"))
      ->to_match(qr{src must be a variable at file \S+/needvar.yatt line 3\b});
  };

  it "should give \$node to argmacro declared in template", sub {
    expect($err->("tmpl_needvar"))
      ->to_match(qr{src must be a variable at file \S+/tmpl_needvar.yatt line 3\b});
  };

  it "should pass through bare variable and cast quoted text", sub {
    expect($site->render("pass"))->to_match(qr/\[1-lit\]\s*\[2-lit\]/);
  };

  it "should cast text with entity (not pass through)", sub {
    expect($site->render("entity"))->to_match(qr/\[v1\]/);
  };

  it "should use default for name only arg without variable", sub {
    expect($site->render("dflt"))->to_match(qr/\[p-dflt\]/);
  };

  it "should pass through name only arg with variable", sub {
    expect($site->render("namevar"))->to_match(qr/\[p-bb\]/);
  };

  it "should generate raw expression", sub {
    expect($site->render("expr"))->to_match(qr/\[p-10\]/);
  };

  it "should be usable in argmacro declared in template", sub {
    expect($site->render("tmpl"))->to_match(qr/\[1\]\s*\[2\]/);
  };
};

describe "expand_element in element macros", sub {
  my $site = $make_app->(
    {},
    '.htyattrc.pl' => <<'END',
use YATT::Lite::Macro;
require TestArgMacro::Range;

# 組み込みの foreach に、from= to= を足す
Macro foreach => sub {
  my ($self, $node, @rest) = @_;
  $node = TestArgMacro::Range->expand_element($self, $node);
  $self->YATT::Lite::CGen::Perl::macro_foreach($node, @rest);
};

# rename した出力を、展開結果から直接使う
Macro show => sub {
  my ($self, $node) = @_;
  my (undef, $result)
    = TestArgMacro::Range->expand_element($self, $node, rename => 'n=from');
  \ sprintf(q{print $CON join(",", %s);}, $result->{list});
};
END
    'range.yatt' => <<'END',
<yatt:foreach my=i from=1 to=3>[&yatt:i;]</yatt:foreach>
END
    'passthru.yatt' => <<'END',
<yatt:foreach my=x list="2..2"><yatt:foreach my=i from=x to=3>[&yatt:i;]</yatt:foreach></yatt:foreach>
END
    'plain.yatt' => <<'END',
<yatt:foreach my=i list="5..6">[&yatt:i;]</yatt:foreach>
END
    'renamed.yatt' => <<'END',
<yatt:show n=2 n_to=4/>
END
    'bypass.yatt' => <<'END',
<!yatt:args>

<yatt:foreach my=i
  list="1..2" from=1 to=2>[&yatt:i;]</yatt:foreach>
END
  );

  it "should report bypass error with the line of the element", sub {
    expect($compile_err->($site, "bypass"))
      ->to_match(qr{argmacro %TestArgMacro::Range; is bypassed by explicit output 'list'; input 'from' can't be given at file \S+/bypass.yatt line 3\b});
  };

  it "should expand argmacro in element macro", sub {
    expect($site->render("range"))->to_match(qr/\[1\]\[2\]\[3\]/);
  };

  it "should pass through variables in the scope of the element", sub {
    expect($site->render("passthru"))->to_match(qr/\[2\]\[3\]/);
  };

  it "should keep the element as is without triggers", sub {
    expect($site->render("plain"))->to_match(qr/\[5\]\[6\]/);
  };

  it "should return the result with renaming in list context", sub {
    expect($site->render("renamed"))->to_match(qr/2,3,4/);
  };
};

describe "on_expand returning arg node", sub {
  my $site = $make_app->(
    {srcval => 'TestArgMacro::SrcVal'},
    '.htyattrc.pl' => <<'END',
use YATT::Lite::Macro;
require TestArgMacro::SrcList;

Macro foreach => sub {
  my ($self, $node, @rest) = @_;
  $node = TestArgMacro::SrcList->expand_element($self, $node);
  $self->YATT::Lite::CGen::Perl::macro_foreach($node, @rest);
};
END
    'notlist.yatt' => <<'END',
<!yatt:args>
<yatt:foreach my=x list="1..1">
<yatt:foreach my=i src=x>[&yatt:i;]</yatt:foreach>
</yatt:foreach>
END
    'list.yatt' => <<'END',
<yatt:w items="7,8"/>

<!yatt:widget w items=list>
<yatt:foreach my=i src=items>[&yatt:i;]</yatt:foreach>
END
    'text.yatt' => <<'END',
<yatt:foreach my=i src="3..4">[&yatt:i;]</yatt:foreach>
END
    'widget.yatt' => <<'END',
<yatt:foreach my=x list="1..2"><yatt:w src=x/></yatt:foreach>

<!yatt:widget w %srcval;>
[&yatt:val;]
END
    'nameonly.yatt' => <<'END',
<yatt:foreach my=src list="5..5"><yatt:w src/></yatt:foreach>

<!yatt:widget w %srcval;>
[&yatt:val;]
END
  );

  it "should let the receiver check the passed variable", sub {
    expect($compile_err->($site, "notlist"))
      ->to_match(qr{x should be list type});
  };

  it "should pass through list variable to foreach", sub {
    expect($site->render("list"))->to_match(qr/\[7\]\[8\]/);
  };

  it "should pass text node to foreach as expression", sub {
    expect($site->render("text"))->to_match(qr/\[3\]\[4\]/);
  };

  it "should pass through variable to widget arg", sub {
    expect($site->render("widget"))->to_match(qr/\[1\]\s*\[2\]/);
  };

  it "should pass through name only arg as renamed", sub {
    expect($site->render("nameonly"))->to_match(qr/\[5\]/);
  };
};

describe "declaration errors", sub {
  my $declare = sub {
    my @spec = @_;
    local $@;
    eval {YATT::Lite::ArgMacro->declare_into("TestArgMacro::Decl$testno", @spec)};
    $testno++;
    $@;
  };

  it "should require out", sub {
    expect($declare->(in => [qw(a)]))->to_match(qr/requires 'out'/);
  };

  it "should reject duplicate names", sub {
    expect($declare->(out => [qw(a)], in => [qw(a)]))
      ->to_match(qr/Duplicate arg name in ArgMacro: a/);
  };

  it "should reject duplicate names between in and refer", sub {
    expect($declare->(out => [qw(a)], in => [qw(b)], refer => [qw(b)]))
      ->to_match(qr/Duplicate arg name in ArgMacro: b/);
  };

  it "should reject type spec in refer", sub {
    expect($declare->(out => [qw(a)], refer => [qw(b=value)]))
      ->to_match(qr/refer accepts only arg names: b=value/);
  };

  it "should reject unsupported types", sub {
    expect($declare->(out => [qw(a)], in => [qw(b=code)]))
      ->to_match(qr/not supported/);
  };
};

describe "part option by %yatt:NAME;", sub {
  my $widget = sub {
    my ($decl) = @_;
    <<END;
[<yatt:w/>]
<!yatt:widget w $decl>
abc
END
  };
  my $site = $make_app->(
    # 名前空間無しの登録は primary ns (yatt) に入る
    {pair => 'TestArgMacro::Pair', no_last_newline => 'TestArgMacro::SrcA'},
    'plain.yatt' => $widget->(''),
    'flag.yatt' => $widget->('%yatt:no_last_newline;'),
    'on.yatt' => $widget->('%yatt:no_last_newline(1);'),
    'off.yatt' => $widget->('%yatt:no_last_newline(0);'),
    'page.yatt' => <<'END',
<!yatt:args %yatt:no_last_newline;>
abc
END
    'multi.yatt' => $widget->('%yatt:no_last_newline(1,2);'),
    'var.yatt' => $widget->('%yatt:no_last_newline(:x);'),
    'pair.yatt' => <<'END',
<yatt:w pair="3, 8"/>
<!yatt:widget w %yatt:pair;>
x=&yatt:x; y=&yatt:y;
END
    'nosuch.yatt' => $widget->('%yatt:nosuch;'),
  );

  it "should keep last newline without option", sub {
    expect($site->render("plain"))->to_be("[abc\n]\n");
  };

  it "should drop last newline of widget", sub {
    expect($site->render("flag"))->to_be("[abc]\n");
  };

  it "should accept explicit value", sub {
    expect($site->render("on"))->to_be("[abc]\n");
    expect($site->render("off"))->to_be("[abc\n]\n");
  };

  it "should drop last newline of page", sub {
    expect($site->render("page"))->to_be("abc");
  };

  it "should reject multiple values", sub {
    expect($compile_err->($site, "multi"))
      ->to_match(qr/Too many values for part option 'no_last_newline'.* line 2/);
  };

  it "should reject non-text value", sub {
    expect($compile_err->($site, "var"))
      ->to_match(qr/Invalid value for part option 'no_last_newline'.* line 2/);
  };

  it "should fall back to argmacro in primary ns", sub {
    expect($site->render("pair"))->to_match(qr/x=3 y=8/);
  };

  it "should report unknown argmacro as before", sub {
    expect($compile_err->($site, "nosuch"))
      ->to_match(qr/Unknown argmacro 'yatt:nosuch'/);
  };
};

{
  my @ns = (namespace => [qw(myteam myorg yatt perl)]);

  # XXX: SiteApp->render は一度成功した後のエラーを \"DONE" で返すため、
  # エラーになるページを先に render する。
  my $render_err = sub {
    my ($site, $page) = @_;
    local $@;
    my $out = eval {$site->render($page)};
    $@ || $out;
  };

  my $use = sub {
    my ($ref) = @_;
    (my $fn = "$ref.yatt") =~ s/:/_/g;
    ($fn => <<END);
<yatt:w tag=1/>

<!yatt:widget w %$ref;>
src=&yatt:src;
END
  };

  my $local_foo = <<'END';
<!yatt:argmacro foo=[src] tag>
$result->{src} = q{local};
END

  describe "namespace: argmacro registered with namespace", sub {
    my $site = $make_app->(
      [[myorg => {foo => 'TestArgMacro::SrcA'}]], [@ns],
      $use->('myorg:foo'),
      $use->('foo'),
      'override.yatt' => <<END,
<yatt:w tag=1/><yatt:w2 tag=1/>
$local_foo
<!yatt:widget w %foo;>
w=&yatt:src;
<!yatt:widget w2 %myorg:foo;>
w2=&yatt:src;
END
    );

    it "should not be referenced without namespace", sub {
      expect($render_err->($site, "foo"))
        ->to_match(qr/Unknown argmacro 'foo'/);
    };

    it "should be referenced with the namespace", sub {
      expect($render_err->($site, "myorg_foo"))->to_match(qr/src=modA/);
    };

    it "should prefer page-local argmacro only for %foo;", sub {
      expect($render_err->($site, "override"))
        ->to_match(qr/w=local\s*w2=modA/);
    };
  };

  describe "namespace: argmacro registered without namespace", sub {
    my $site = $make_app->(
      {foo => 'TestArgMacro::SrcA'}, [@ns],
      $use->('foo'),
      $use->('myteam:foo'),
      $use->('myorg:foo'),
      $use->('yatt:foo'),
    );

    it "should not be referenced with other namespace (myorg)", sub {
      expect($render_err->($site, "myorg_foo"))
        ->to_match(qr/Unknown argmacro 'myorg:foo'/);
    };

    it "should not be referenced with other namespace (yatt)", sub {
      expect($render_err->($site, "yatt_foo"))
        ->to_match(qr/Unknown argmacro 'yatt:foo'/);
    };

    it "should be referenced without namespace", sub {
      expect($render_err->($site, "foo"))->to_match(qr/src=modA/);
    };

    it "should be referenced with primary namespace", sub {
      expect($render_err->($site, "myteam_foo"))->to_match(qr/src=modA/);
    };
  };

  describe "namespace: argmacro registered with primary namespace", sub {
    my $site = $make_app->(
      [[myteam => {foo => 'TestArgMacro::SrcA'}]], [@ns],
      $use->('foo'),
    );

    it "should be referenced without namespace too", sub {
      expect($render_err->($site, "foo"))->to_match(qr/src=modA/);
    };
  };

  describe "namespace: same name in different namespaces", sub {
    my $site = $make_app->(
      [[myorg => {foo => 'TestArgMacro::SrcA'}],
       {foo => 'TestArgMacro::OtherC'}], [@ns],
      'both.yatt' => <<'END',
<yatt:w tag=1 otag=1/>

<!yatt:widget w %myorg:foo; %foo;>
src=&yatt:src; other=&yatt:other;
END
    );

    it "should be usable together in one widget", sub {
      expect($render_err->($site, "both"))
        ->to_match(qr/src=modA other=modC/);
    };
  };

  describe "namespace: registration errors", sub {
    my $reg_err = sub {
      my ($argmacro) = @_;
      local $@;
      eval {
        my $site = $make_app->($argmacro, [@ns], $use->('foo'));
        $site->render("foo");
      };
      $@;
    };

    it "should reject duplicate registration in primary namespace", sub {
      expect($reg_err->([{foo => 'TestArgMacro::SrcA'},
                         [myteam => {foo => 'TestArgMacro::SrcB'}]]))
        ->to_match(qr/Duplicate argmacro registration 'myteam:foo'/);
    };

    it "should reject duplicate registration in the same namespace", sub {
      expect($reg_err->([[myorg => {foo => 'TestArgMacro::SrcA'}],
                         [myorg => {foo => 'TestArgMacro::SrcB'}]]))
        ->to_match(qr/Duplicate argmacro registration 'myorg:foo'/);
    };

    it "should reject unknown namespace", sub {
      expect($reg_err->([[nosuch => {foo => 'TestArgMacro::SrcA'}]]))
        ->to_match(qr/Unknown namespace 'nosuch' in argmacro registration/);
    };

    it "should reject malformed spec", sub {
      expect($reg_err->([[myorg => 'TestArgMacro::SrcA']]))
        ->to_match(qr/Invalid argmacro registration/);
    };

    it "should reject invalid macro name", sub {
      expect($reg_err->({'foo-bar' => 'TestArgMacro::SrcA'}))
        ->to_match(qr/Invalid argmacro name 'foo-bar'/);
    };
  };

  describe "namespace: reference errors", sub {
    my $site = $make_app->(
      {}, [@ns],
      $use->('bogus:foo'),
      'multi.yatt' => <<'END',
<!yatt:widget w %myorg:foo:bar;>
END
      'localonly.yatt' => <<END,
<yatt:w tag=1/>
$local_foo
<!yatt:widget w %myorg:foo;>
END
    );

    it "should reject unknown namespace", sub {
      expect($render_err->($site, "bogus_foo"))
        ->to_match(qr/Unknown namespace 'bogus' in argmacro reference/);
    };

    it "should reject extra path", sub {
      expect($render_err->($site, "multi"))
        ->to_match(qr/Invalid argmacro reference/);
    };

    it "should hint page-local argmacro", sub {
      expect($render_err->($site, "localonly"))
        ->to_match(qr/Unknown argmacro 'myorg:foo' \(page-local argmacro 'foo' can only be referenced as %foo;\)/);
    };
  };
}

done_testing();
