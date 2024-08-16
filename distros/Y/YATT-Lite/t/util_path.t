#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use autodie qw(mkdir chdir);
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Test::More;

use YATT::Lite::Util::File qw(mkfile);

BEGIN {
  use_ok('YATT::Lite::Util', qw(split_path lookup_path
                                trim_common_suffix_from
                             ));
}

my $BASE = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

my $i = 1;
{
  my $appdir = "$BASE/t$i";
  make_path(my $docroot = "$appdir/html"
	   , my $ytmpl = "$appdir/ytmpl");
  chdir($appdir);

  MY->mkfile("html/index.yatt", 'top');
  MY->mkfile("html/auth.yatt", 'auth');
  MY->mkfile("html/code.ydo", 'code');
  MY->mkfile("html/img/bg.png", 'background');
  MY->mkfile("html/d1/f1.yatt", 'in_d1');

  MY->mkfile("ytmpl/foo.yatt", "foo in tmpl");
  MY->mkfile("ytmpl/d1/f2.yatt", "f2 in tmpl");
  MY->mkfile("ytmpl/d2/bar.yatt", "bar in tmpl");

  my $test = sub {
    my ($part, $loc, $want, $longtitle) = @_;
    is_deeply [split_path("$appdir/$part$loc", $appdir, 1)], $want
      , "split_path: $loc";
  };

  my $res;
  $test->(html => "/index.yatt"
	  , $res = [$docroot, "/", "index.yatt", "", '']);

  $test->(html => "/unknown.png"
	  , $res = [$docroot, "/", "", "/unknown.png", 1]);

  $test->(html => "/auth.yatt"
	  , $res = [$docroot, "/", "auth.yatt", "", '']);
  $test->(html => "/auth", $res);

  $test->(html => "/auth.yatt/foo"
	  , $res = [$docroot, "/", "auth.yatt", "/foo", '']);
  $test->(html => "/auth/foo", $res);

  $test->(html => "/auth.yatt/foo/bar"
	  , $res = [$docroot, "/", "auth.yatt", "/foo/bar", '']);
  $test->(html => "/auth/foo/bar", $res);

  $test->(ytmpl => "/foo.yatt"
	  , $res = [$ytmpl, "/", "foo.yatt", "", '']);
  $test->(ytmpl => "/foo", $res);

  $test->(html => "/d1/f1.yatt"
	  , $res = [$docroot, "/d1/", "f1.yatt", "", '']);
  $test->(html => "/d1/f1", $res);

  $test->(ytmpl => "/d1/f2.yatt"
	  , $res = [$ytmpl, "/d1/", "f2.yatt", "", '']);
  $test->(ytmpl => "/d1/f2", $res);

  $test->(html => "/code.ydo"
	  , $res = [$docroot, '/', 'code.ydo', '', '']);

  $test->(html => "/img/bg.png"
	  , [$docroot, "/img/", "bg.png", "", '']);

  $test->(html => "/img/missing.png"
	  , [$docroot, "/img/", "missing.png", "", '']);
}

$i++;
{
  mkdir(my $realdir = "$BASE/t$i.docs");
  chdir($realdir);

  my $html = "$realdir/html";
  MY->mkfile("$html/test.yatt", 'test1');
  MY->mkfile("$html/real/index.yatt", 'index in realsub');
  MY->mkfile("$html/real/test.yatt", 'test in realsub');
  MY->mkfile("$html/real/code.ydo", 'code in realsub');
  MY->mkfile("$html/rootcode.ydo", 'rootcode');

  MY->mkfile("$html/js/jquery/jquery.min.js", 'yes this is dummy;-)');

  my $tmpl = "$realdir/runyatt.ytmpl";
  MY->mkfile("$tmpl/index.yatt", 'virtual index');
  MY->mkfile("$tmpl/virt/index.yatt", 'virtual index in virt');
  MY->mkfile("$tmpl/virt/test.yatt", 'test in virt');
  MY->mkfile("$tmpl/virt/code.ydo", 'code in virt');
  MY->mkfile("$tmpl/virtcode.ydo", 'virtcode');

  MY->mkfile("$tmpl/filevsdir.yatt", "file vs dir, this is the file");
  MY->mkfile("$tmpl/filevsdir/index.yatt", "file vs dir, this is dir index");
  MY->mkfile("$tmpl/filevsdir/real.yatt", "file vs dir, real in dir");


  my @tmpls = map {"$realdir/$_"} qw(html runyatt.ytmpl);
  my $test = sub {
    my ($loc, $want, @rest) = @_;
    is_deeply [lookup_path($loc, \@tmpls, @rest)]
      , $want, "lookup_path: $loc";
  };

  my $res;
  $test->("/index.yatt"
	  , $res = [$tmpl, '/', 'index.yatt', '']);
  $test->("/index", $res);
  $test->("/", [$tmpl, '/', 'index.yatt', '', 1]);

  $test->("/index.yatt/foo/bar"
	  , $res = [$tmpl, '/', 'index.yatt', '/foo/bar']);
  $test->("/index/foo/bar", $res);

  $test->("/test.yatt"
	  , $res = [$html, '/', 'test.yatt', '']);
  $test->("/test", $res);

  $test->("/test.yatt/foo/bar"
	  , $res = [$html, '/', 'test.yatt', '/foo/bar']);
  $test->("/test/foo/bar", $res);

  $test->("/real/index.yatt"
	  , $res = [$html, '/real/', 'index.yatt', '']);
  $test->("/real/index", $res);
  $test->("/real/", [$html, '/real/', 'index.yatt', '', 1]);

  $test->("/real/index.yatt/foo/bar"
	  , $res = [$html, '/real/', 'index.yatt', '/foo/bar']);
  $test->("/real/index/foo/bar", $res);

  $test->("/real/test.yatt"
	  , $res = [$html, '/real/', 'test.yatt', '']);
  $test->("/real/test", $res);

  $test->("/real/code.ydo"
	  , $res = [$html, '/real/', 'code.ydo', '']);
  $test->("/rootcode.ydo"
	  , $res = [$html, '/', 'rootcode.ydo', '']);
  $test->("/virt/code.ydo"
	  , $res = [$tmpl, '/virt/', 'code.ydo', '']);
  $test->("/virtcode.ydo"
	  , $res = [$tmpl, '/', 'virtcode.ydo', '']);

  $test->("/js/jquery/jquery.min.js"
	  , $res = [$html, '/js/jquery/', 'jquery.min.js', '']);
  $test->("/js/jquery/jquery.min.js/foo/bar"
	  , $res = [$html, '/js/jquery/', 'jquery.min.js', '/foo/bar']);

  $test->("/virt/index.yatt"
	  , $res = [$tmpl, '/virt/', 'index.yatt', '']);
  $test->("/virt/index", $res);
  $test->("/virt/", [$tmpl, '/virt/', 'index.yatt', '', 1]);
  $test->("/virt/index.yatt/foo/bar"
	  , $res = [$tmpl, '/virt/', 'index.yatt', '/foo/bar']);
  $test->("/virt/index/foo/bar", $res);

  $test->("/virt/test.yatt"
	  , $res = [$tmpl, '/virt/', 'test.yatt', '']);
  $test->("/virt/test", $res);

  $test->("/virt/test.yatt/foo/bar"
	  , $res = [$tmpl, '/virt/', 'test.yatt', '/foo/bar']);
  $test->("/virt/test/foo/bar", $res);

  $test->('/filevsdir',  [$tmpl, '/', 'filevsdir.yatt', '']);
  $test->('/filevsdir/', [$tmpl, '/filevsdir/', 'index.yatt', '', 1]);
  $test->('/filevsdir/real/foo', [$tmpl, '/filevsdir/', 'real.yatt', '/foo']);
 TODO: {
    local our $TODO = "Util::lookup_path file vs dir subpath priority";
    # Which is better?
    $test->('/filevsdir/virt/bar'
	    , [$tmpl, '/', 'filevsdir.yatt', '/virt/bar']);
    $test->('/filevsdir/virt/bar'
	    , [$tmpl, '/filevsdir/', 'index.yatt', '/virt/bar']);
  }
}

{
  my $test = sub {
    my ($script_name, $script_filename, $expect) = @_;
    is(trim_common_suffix_from($script_name, $script_filename)
       , $expect
       , "trim_common_suffix_from($script_name, $script_filename) => $expect");
  };

  $test->('/foo/cgi-bin/dispatch.cgi'
          , '/var/www/foo/html/cgi-bin/dispatch.cgi'
          => '/foo');

  $test->('/cgi-bin/dispatch.cgi'
          , '/var/www/cgi-bin/dispatch.cgi'
          => '');

  $test->('/experimental/foobar/1/-/cgi-bin/runplack.cgi'
          , '/var/www/experimental/apps/foobar/1/cgi-bin/runplack.cgi'
          => '/experimental/foobar/1/-');

}

{
  # Shamelessly stolen from Dancer2/t/file_utils.t
  my $paths = [
    [ undef          => 'undef' ],
    [ '/foo/./bar/'  => '/foo/bar/' ],
    [ '/foo/../bar' => '/bar' ],
    [ '/foo/bar/..'  => '/foo/' ],
    [ '/a/b/c/d/A/B/C' => '/a/b/c/d/A/B/C' ],
    [ '/a/b/c/d/../A/B/C' => '/a/b/c/A/B/C' ],
    [ '/a/b/c/d/../../A/B/C' => '/a/b/A/B/C' ],
    [ '/a/b/c/d/../../../A/B/C' => '/a/A/B/C' ],
    [ '/a/b/c/d/../../../../A/B/C' => '/A/B/C' ],
  ];

  for my $case ( @$paths ) {
    is YATT::Lite::Util::normalize_path( $case->[0] ), $case->[1]
      , YATT::Lite::Util::terse_dump($case);
  }
}

done_testing();
