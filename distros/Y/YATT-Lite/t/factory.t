#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw(tempdir);
use autodie qw(mkdir chdir);

use YATT::Lite::Util::File qw(mkfile);
use YATT::Lite::Util qw(appname catch);

sub myapp {join _ => MyTest => appname($0), @_}
use YATT::Lite;
use YATT::Lite::Factory;
sub Factory () {'YATT::Lite::Factory'}

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

{
  isa_ok(YATT::Lite->EntNS, 'YATT::Lite::Entities');
}

my $has_yaml = do {
  eval {require YAML::Tiny};
};

my $YL = 'YATT::Lite';
my $i = 0;

#----------------------------------------
# 試したいバリエーション(実験計画法の出番か?)
#
# app_base 指定の有無
#   @ytmpl か CLASS::Name か
#
# MyYATT.pm の有無
#
# .htyattconfig.xhf の有無
#   base: の有無.. @dir か +CLASS::Name か
#   2つめ以降の base(=mixin) の有無
#
# .htyattrc.pl の有無
#   use parent の有無... <= これは mixin 専用にすべきでは?
#
#----------------------------------------

#
# * そもそも root yatt が正常に動いているか。
#
my $root_sanity = sub {
  my ($THEME, $CLS, $yatt, $num) = @_;
  ok $yatt->isa($YL), "$THEME(sanity) inst isa $YL";

  is ref($yatt), my $rootns = $CLS . "::INST$num"
    , "$THEME(sanity) inst ref";
  is $rootns->EntNS, my $rooten = $rootns."::EntNS"
    , "$THEME(sanity) root entns";
  ok $rooten->isa($YL->EntNS)
    , "$THEME(sanity) $rooten isa YATT::Lite::EntNS";

};

++$i;
{
  my $THEME = "[empty MyYATT]";
  #
  # When given app_ns class has no definition,
  # yatt should set its ISA correctly.
  #
  my $CLS = 'MyYATTMissing';
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/index.yatt", q|FOO|);

  #----------------------------------------
  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot);
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";

  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 1);

  ok($yatt->find_part('index'), "$THEME inst index is visible");

  is $yatt->render('index'), 'FOO', "$THEME inst->render(index)";
}


++$i;
{
  my $THEME = "[predefined MyYATT]";
  #
  # * default_app を渡さなかった時は、 YL が default_app になる
  # * app_ns を渡さなかったときは、 MyYATT が app_ns になる
  # * MyYATT が default_app を継承済みなら、そのまま用いる。
  #
  my $foo_res = "My App's foo";
  {
    package MyYATT;
    use parent qw(YATT::Lite); use YATT::Lite::Inc;
    use YATT::Lite::MFields;
    sub foo {$foo_res}
  }
  my $CLS = 'MyYATT';
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/foo.yatt", q|FOO|);

  #----------------------------------------
  my $F = Factory->new(app_root => $approot
		       , doc_root => $docroot);
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";

  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 1);

  is $yatt->foo, $foo_res, "$THEME inst->foo";

  ok($yatt->find_part('foo'), "$THEME inst part foo is visible");
}

++$i;
{
  my $THEME = "[composed MyYATT]";
  # * default_app のオーバライド
  # * app_ns を渡したが、それが default_app(YL) を継承していない(=空クラスの)場合、
  #   app_ns に default_app への継承関係を追加する
  #
  my $CLS = myapp($i);
  my $default_app = 'MyYATT';
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/foo.yatt", q|FOO|);

  #----------------------------------------
  my $F = Factory->new(app_ns => $CLS
		       , default_app => $default_app
		       , doc_root => $docroot
		      );
  ok $CLS->isa($default_app), "$THEME $CLS isa $default_app";

  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 1);
}

++$i;
{
  my $THEME = "[read_config xhf, yml]";
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/.htyattconfig.xhf" => <<'END'
base: @ytmpl
other_config: in docroot
END

	     , "$docroot/yamltest/.htyattconfig.yml" => <<'END'
---
base: '@ytmpl'
other_config: 'read from yml'
END
	     );

  # In xhf, order must be preserved.
  is_deeply [Factory->read_file("$docroot/.htyattconfig.xhf")]
    , [base => '@ytmpl', other_config => 'in docroot']
      , "Factory->read_file .htyattconfig.xhf";

 SKIP: {
    skip "YAML::Tiny is not installed", 1 unless $has_yaml;
    # In yaml, order is not preserved.
    is_deeply +{Factory->read_file("$docroot/yamltest/.htyattconfig.yml")}
      , +{base => '@ytmpl', other_config => 'read from yml'}
	, "Factory->read_file .htyattconfig.yml";
  }
}

++$i;
{
  my $THEME = "[config+rc]";
  # * root に config と rc があり、 config から ytmpl への継承が指定されているケース
  # * サブディレクトリ(config 無し)がデフォルト値を継承するケース

  my $baz_res = 'My App baz';
  {
    package MyYATTBaz;
    use parent qw(YATT::Lite); use YATT::Lite::Inc;
    use YATT::Lite::MFields qw(cf_other_config cf_other_config_list);
    sub baz {$baz_res}
  }
  
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/.htyattconfig.xhf" => <<'END'
base: @ytmpl
other_config: in docroot
other_config_list[
foo: 1
bar: 2
baz: 3
]
END

	     , "$docroot/yamltest/.htyattconfig.yml" => <<'END'
---
base: '@ytmpl'
other_config: 'read from yml'
END


	     , "$docroot/.htyattrc.pl" => <<'END'
use strict;
use warnings qw(FATAL all NONFATAL misc);
sub root_method {
  (my MY $self) = @_;
  $self->{cf_other_config}
}
END

	     , "$docroot/foo/bar.yatt"
	     => q|BAR rrrr|
	     
	     , "$approot/ytmpl/bar.ytmpl"
	     => q|BAR|
	     , "$approot/ytmpl/.htyattrc.pl"
	     => q|sub bar {"my bar result"}|

	     , "$approot/ytmpl/.htyattconfig.xhf" => <<'END'
other_config_list[
A: 1
B: 2
C: 3
]
END
);

  #----------------------------------------
  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '::MyYATTBaz'
		      );
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";
  
  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 2);

  is_deeply([$yatt->cget_all('other_config_list')]
      , [A => 1, B => 2, C => 3, foo => 1, bar => 2, baz => 3]);
  
  is $yatt->bar, "my bar result", "$THEME root inherits ytmpl bar";
  ok($yatt->find_part('bar'), "$THEME inst part bar is visible");

 SKIP: {
    skip "YAML::Tiny is not installed", 1 unless $has_yaml;
    is $F->get_yatt('/yamltest/')->cget('other_config')
     , 'read from yml', "yaml support .htyattconfig.yml";
  }
}

++$i;
{
  my $THEME = '[app_base=@ytmpl]';
  # * root に config と rc があり、 config から ytmpl への継承が指定されているケース
  # * サブディレクトリ(config 無し)がデフォルト値を継承するケース

  my $qux_res = 'My App qux';
  {
    package MyYATTQux;
    use parent qw(YATT::Lite); use YATT::Lite::Inc;
    use YATT::Lite::MFields qw/cf_other_config2/;
    sub qux {$qux_res}
  }
  
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  
  MY->mkfile("$docroot/index.yatt"
	     => q|my index|

	     , "$docroot/.htyattconfig.xhf" => <<'END'
other_config2: in docroot
END

	     , "$approot/ytmpl/.htyattconfig.xhf" => <<'END'
base: ::MyYATTQux
other_config2: in @ytmpl
END
	     , "$approot/ytmpl/.htyattrc.pl" => <<'END'
use strict;
use warnings qw(FATAL all NONFATAL misc);
sub root_method {
  (my MY $self) = @_;
  $self->{cf_other_config2}
}
END
);
  
  #----------------------------------------
  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '@ytmpl'
		      );
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";

  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 2);

  my $ytmpl = $F->load_yatt("$approot/ytmpl");
  ok $yatt->isa(ref $ytmpl), "$THEME docroot isa ytmpl";
  ok $ytmpl->isa('MyYATTQux'), "$THEME ytmpl isa MyYATTQux";

  foreach my $key (qw(index)) {
    ok($yatt->find_part($key), "$THEME inst part $key is visible");
  }
}

++$i;
{
  my $THEME = "[mixin]";
  # * base を複数(=mixin) を指定したケース

  my $quux_res = 'My App quux';
  {
    package MyYATTQuux;
    use parent qw(YATT::Lite);use YATT::Lite::Inc;
    use YATT::Lite::MFields;
    sub quux {$quux_res}
  }
  
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  
  MY->mkfile("$docroot/.htyattconfig.xhf", <<'END');
base[
- @t_foo
- @t_bar
- @t_baz
]
END

  MY->mkfile("$docroot/index.yatt"
	     , q|main index|
	     , "$approot/t_foo/foo.ytmpl"
	     , q|FOO|
	     , "$approot/t_foo/.htyattrc.pl"
	     , q|sub foo_func {"my foo result"}|
	     , "$approot/t_bar/bar.ytmpl"
	     , q|BAR|
	     , "$approot/t_baz/baz.ytmpl"
	     , q|BAZ|);


  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '::MyYATTQuux'
		      );
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";
  
  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 4);

  is $yatt->foo_func, "my foo result", "$THEME root inherits t_foo";

  foreach my $key (qw(foo bar baz)) {
    ok($yatt->find_part($key), "$THEME inst part $key is visible");
  }
}

++$i;
{
  my $THEME = "[cyclic inheritance error detection]";
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/.htyattconfig.xhf" => <<'END'
base[
- foo
]
END
	     , "$docroot/foo/.htyattconfig.xhf" => <<'END'
base[
- ../bar
]
END
	     , "$docroot/bar/.htyattconfig.xhf" => <<'END'
base[
- ../foo
]
END
	     );

  #----------------------------------------

  like catch {
    Factory->new(app_ns => $CLS
		 , app_root => $approot
		 , doc_root => $docroot);
  }, qr/^Template config error! base has cycle!/
    , "$THEME";

}

++$i;
{
  my $THEME = "[No false alert of cyclic inheritance error detection - simple]";
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  my $ytmpl   = "$approot/ytmpl";

  MY->mkfile("$docroot/.htyattconfig.xhf" => <<'END'
base[
- @ytmpl
]
END
	     , "$ytmpl/common.ytmpl" => "shared"
	     );

  #----------------------------------------

  is catch {
    Factory->new(app_ns => $CLS
		 , app_root => $approot
		 , doc_root => $docroot
		 , app_base => '@ytmpl'
	       );
  }, '', "$THEME";
}

++$i;
{
  my $THEME = "[No false alert of cyclic inheritance error detection - multi]";
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  my $ytmpl   = "$approot/ytmpl";

  MY->mkfile("$docroot/.htyattconfig.xhf" => <<'END'
base[
- @ytmpl
- foo
]
END
	     , "$docroot/foo/.htyattconfig.xhf" => <<'END'
base[
- @ytmpl
]
END
	     , "$ytmpl/common.ytmpl" => "shared"
	     );

  #----------------------------------------

  is catch {
    Factory->new(app_ns => $CLS
		 , app_root => $approot
		 , doc_root => $docroot
		 , app_base => '@ytmpl'
	       );
  }, '', "$THEME";
}


++$i;
{
  my $THEME = "[vfscache]";
  # vfscache ありの時に、subdir -> topdir の順でアクセスしたらエラーになった件。
  # test だけでも足しておこう...

  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  my $ytmpl   = "$approot/ytmpl";

  # '..' causes error.
  MY->mkfile("$docroot/subapp/.htyattconfig.xhf" => <<'END'
base[
- ..
- @ytmpl
]
END
	     , "$docroot/subapp/foo.yatt" => <<'END'
foo<yatt:common/>
END

	     , "$docroot/.htyattconfig.xhf" => <<'END'
base[
- @ytmpl
]
END
	     , "$docroot/bar.yatt" => <<'END'
bar<yatt:common/>
END
	     , "$ytmpl/common.ytmpl" => "shared"
	    );


  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '@ytmpl'
		      );

  my $subapp = $F->get_yatt('/subapp/');
  is $subapp->render(foo => []), "fooshared\n", "$THEME subapp/foo";
  is $subapp->app_name, "subapp", "app_name of /subapp/";

  my $top = $F->get_yatt('/');
  is $top->render(bar => []), "barshared\n", "$THEME bar";
  # No such widget <yatt:common> at file /tmp/pFTOXbIAaa/app6/docs/bar.yatt line 1,

  # あと、Subroutine filename redefined になるケースがあるが、同じ現象か別か不明。
}

++$i;
{
  my $THEME = "[app.psgi loading]";
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/html";

  MY->mkfile("$approot/html/index.yatt", q|dummy|);

  MY->mkfile(my $fn = "$approot/app.psgi", <<'END');
use FindBin;
use YATT::Lite::WebMVC0::SiteApp -as_base;

return do {
  my $site = MY->new(app_ns => 'MyYATT_load_factory'
                     , app_root => $FindBin::Bin
		     , doc_root => "$FindBin::Bin/html");

  if (MY->want_object) {
    $site
  } else {
    $site->to_app;
  }
};

END

  ok(Factory->load_factory_script($fn)
     , "Factory->load_factory_script(app.psgi)");
}

++$i;
{
  my $THEME = "[<!yatt:base file='../other/lib.yatt'>]";
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/foo/index.yatt" => <<'END'
<!yatt:base file="../base/base.yatt">
<h2>foo index</h2>
<yatt:bazzzzzz/>
&yatt:render(qux);
END

	     , "$docroot/bar/index.yatt" => <<'END'
<!yatt:base file="../base/base.yatt">
<h2>bar index</h2>
<yatt:bazzzzzz/>
&yatt:render(qux);
END

	     , "$docroot/base/base.yatt" => <<'END'
<h2>base &yatt:this;</h2>
<!yatt:widget bazzzzzz>
<h3>&yatt:this;</h3>
<!yatt:widget qux>
Qux!
END
	     );

  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		      );

  my $base_ns = "MyTest_factory_13::INST3::EntNS::base";

  is $F->get_yatt('/foo/')->render('')
    , qq{<h2>foo index</h2>\n<h3>$base_ns</h3>\nQux!\n\n}
    , "$THEME /foo/ index";

  is $F->get_yatt('/bar/')->render('')
    , qq{<h2>bar index</h2>\n<h3>$base_ns</h3>\nQux!\n\n}
    , "$THEME /bar/ index";

  is $F->get_yatt('/base/')->render('base')
    , qq{<h2>base $base_ns</h2>\n}
    , "$THEME /base/base";
}

++$i;
{
  my $THEME = "[complicated <!yatt:base >]";
  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";

  MY->mkfile("$docroot/base1.yatt" => <<'END'
<!yatt:widget foo xa xb>
<h2>foo: &yatt:xa;</h2>
&yatt:xb;
END

	     , "$docroot/base2/bar.yatt" => <<'END'
<!yatt:args xa xb>
<h2>bar: &yatt:xa;</h2>
&yatt:xb;
END

	     , "$docroot/base3/index.yatt" => <<'END'
<!yatt:widget baz xa xb>
<h2>base3: &yatt:xa;</h2>
&yatt:xb;
END
	     
	     , "$docroot/usefoo.yatt" => <<'END'
<!yatt:base file="base1.yatt">
<yatt:foo xa="bar" xb="baz"/>
END
	     
	     , "$docroot/usebar.yatt" => <<'END'
<!yatt:base dir="base2">
<yatt:bar xa="qux" xb="quux"/>
END

	     , "$docroot/usebaz.yatt" => <<'END'
<!yatt:base file="base3/index.yatt">
<yatt:baz xa="111" xb="222"/>
END

	     , "$docroot/base3/other.yatt" => <<'END'
<yatt:index:baz xa="333" xb="444"/>
END
	     );

  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		      );

  my $base_ns = "MyTest_factory_13::INST3::EntNS::base";

  is $F->get_yatt('/')->render('usefoo')
    , qq{<h2>foo: bar</h2>\nbaz\n\n}
    , "$THEME /foo";

  is $F->get_yatt('/')->render('usebar')
    , qq{<h2>bar: qux</h2>\nquux\n\n}
    , "$THEME /bar";

  is $F->get_yatt('/')->render('usebaz')
    , qq{<h2>base3: 111</h2>\n222\n\n}
    , "$THEME /baz";

  is $F->get_yatt('/base3')->render('other')
    , qq{<h2>base3: 333</h2>\n444\n\n}
    , "$THEME /base3/other";
}

++$i;
{
  use utf8;
  my $THEME = "render_as_bytes";
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/public";

  MY->mkfile(["$docroot/index.yatt" => ':utf8'] => <<'END');
<!yatt:args x y>
漢字&yatt:x;ひらがな&yatt:y;<br>
END

  {
    my $F = Factory->new(app_ns => myapp($i),
                         app_root => $approot,
                         doc_root => $docroot,
                         render_as_bytes => 1,
                         debug_cgen => $ENV{DEBUG});

    my $res = $F->render('', ['かんじ','平仮名']);
    is Encode::is_utf8($res), '', "[$THEME on] is_utf8 is off";
    is $res, "\xe6\xbc\xa2\xe5\xad\x97\xe3\x81\x8b\xe3\x82\x93\xe3\x81\x98\xe3\x81\xb2\xe3\x82\x89\xe3\x81\x8c\xe3\x81\xaa\xe5\xb9\xb3\xe4\xbb\xae\xe5\x90\x8d\x3c\x62\x72\x3e\x0a", "[$THEME on] result matches exactly";
  }

  {
    my $F = Factory->new(app_ns => myapp(++$i),
                         app_root => $approot,
                         doc_root => $docroot,
                         debug_cgen => $ENV{DEBUG});

    my $res = $F->render('', ['かんじ','平仮名']);
    is Encode::is_utf8($res), 1, "[$THEME off] is_utf8 is on";
    is $res, "漢字かんじひらがな平仮名<br>\n", "[$THEME off] result matches exactly";
  }
}

#----------------------------------------
# misc
#----------------------------------------
{
  use YATT::Lite::Util qw/terse_dump/;
  my $test = sub {
    my ($input, $expect, $title) = @_;
    is Factory->_extract_app_name(@$input), $expect
      , ($title // ""). terse_dump($input, $expect);
  };

  my $T = "app_name: ";
  $test->(["/foo/bar/baz/", "/foo/bar/"], "baz", $T);
  $test->(["/foo/bar/", "/foo/bar/"], "", $T);
  $test->(["/foo/bar/", "/unk/"], undef, $T);
}

#----------------------------------------
# parameter delegation
#----------------------------------------

{
  my %except = map {$_ => 1}
    qw(
        vfs
        dir
        app_ns
        app_name
        factory

        tmpl_cache
        entns2vfs_item

        error_handler
        lcmsg_sink

        base
        import
        rc_script
        info
        in_sig_die
    );

  my %lite = map {
    ($$_[0] =~ /^cf_(\w+)/) ? ($1 => 1) : ()
  } YATT::Lite::MFields->get_meta("YATT::Lite")->fields;

  delete $lite{$_} for YATT::Lite::Factory->_cf_delegates;

  is_deeply \%lite, \%except, "parameter delegation[Factory -> Lite]";
}

{
  my %except = map {$_ => 1}
    (# These are internal use only, so we don't need to delegate.
     qw(
         facade
         cache
         entns2vfs_item
         entns
         mark)
     ,
     # Belows are future candidates for delegation.
     qw(
         no_auto_create
         error_handler
         parse_while_loading
     )
   );

  my %core = map {
    ($$_[0] =~ /^cf_(\w+)/) ? ($1 => 1) : ()
  } YATT::Lite::MFields->get_meta("YATT::Lite::Core")->fields;

  delete $core{$_} for YATT::Lite->_cf_delegates;

  is_deeply \%core, \%except, "parameter delegation[Lite -> Core]";
}

done_testing();
