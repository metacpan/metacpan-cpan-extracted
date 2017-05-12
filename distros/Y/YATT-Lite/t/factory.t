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
# MyApp.pm の有無
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
  my $THEME = "[empty MyApp]";
  #
  # When given app_ns class has no definition,
  # yatt should set its ISA correctly.
  #
  my $CLS = 'MyAppMissing';
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
  my $THEME = "[predefined MyApp]";
  #
  # * default_app を渡さなかった時は、 YL が default_app になる
  # * app_ns を渡さなかったときは、 MyApp が app_ns になる
  # * MyApp が default_app を継承済みなら、そのまま用いる。
  #
  my $foo_res = "My App's foo";
  {
    package MyApp;
    use parent qw(YATT::Lite); use YATT::Lite::Inc;
    use YATT::Lite::MFields;
    sub foo {$foo_res}
  }
  my $CLS = 'MyApp';
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
  my $THEME = "[composed MyApp]";
  # * default_app のオーバライド
  # * app_ns を渡したが、それが default_app(YL) を継承していない(=空クラスの)場合、
  #   app_ns に default_app への継承関係を追加する
  #
  my $CLS = myapp($i);
  my $default_app = 'MyApp';
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
    package MyAppBaz;
    use parent qw(YATT::Lite); use YATT::Lite::Inc;
    use YATT::Lite::MFields qw(cf_other_config);
    sub baz {$baz_res}
  }
  
  my $CLS = myapp($i);
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
	     => q|sub bar {"my bar result"}|);
  
  #----------------------------------------
  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '::MyAppBaz'
		      );
  ok $CLS->isa($YL), "$THEME $CLS isa $YL";
  
  my $yatt = $F->get_yatt('/');
  $root_sanity->($THEME, $CLS, $yatt, 2);
  
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
    package MyAppQux;
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
base: ::MyAppQux
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
  ok $ytmpl->isa('MyAppQux'), "$THEME ytmpl isa MyAppQux";

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
    package MyAppQuux;
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
		       , app_base => '::MyAppQuux'
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
  my $site = MY->new(app_root => $FindBin::Bin
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

done_testing();
