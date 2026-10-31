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

use YATT::Lite::Util::File qw(mkfile_may_wait);

BEGIN {
  use_ok('YATT::Lite::Util', qw(split_path lookup_path
                                trim_common_suffix_from
                                trim_ext
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

  MY->mkfile_may_wait("html/index.yatt", 'top');
  MY->mkfile_may_wait("html/auth.yatt", 'auth');
  MY->mkfile_may_wait("html/code.ydo", 'code');
  MY->mkfile_may_wait("html/img/bg.png", 'background');
  MY->mkfile_may_wait("html/d1/f1.yatt", 'in_d1');

  MY->mkfile_may_wait("ytmpl/foo.yatt", "foo in tmpl");
  MY->mkfile_may_wait("ytmpl/d1/f2.yatt", "f2 in tmpl");
  MY->mkfile_may_wait("ytmpl/d2/bar.yatt", "bar in tmpl");

  my $test = sub {
    my ($part, $loc, $want, $longtitle) = @_;
    is_deeply [split_path("$appdir/$part$loc", $appdir, 1)], $want
      , "split_path: $loc";
  };

  # GH-251: 6th element is $request_file (file name part as it
  # appeared in the request; ext-less when request omitted the ext).
  $test->(html => "/index.yatt"
	  , [$docroot, "/", "index.yatt", "", '', 'index.yatt']);

  $test->(html => "/unknown.png"
	  , [$docroot, "/", "", "/unknown.png", 1, '']);

  $test->(html => "/auth.yatt"
	  , [$docroot, "/", "auth.yatt", "", '', 'auth.yatt']);
  $test->(html => "/auth"
	  , [$docroot, "/", "auth.yatt", "", '', 'auth']);

  $test->(html => "/auth.yatt/foo"
	  , [$docroot, "/", "auth.yatt", "/foo", '', 'auth.yatt']);
  $test->(html => "/auth/foo"
	  , [$docroot, "/", "auth.yatt", "/foo", '', 'auth']);

  $test->(html => "/auth.yatt/foo/bar"
	  , [$docroot, "/", "auth.yatt", "/foo/bar", '', 'auth.yatt']);
  $test->(html => "/auth/foo/bar"
	  , [$docroot, "/", "auth.yatt", "/foo/bar", '', 'auth']);

  $test->(ytmpl => "/foo.yatt"
	  , [$ytmpl, "/", "foo.yatt", "", '', 'foo.yatt']);
  $test->(ytmpl => "/foo"
	  , [$ytmpl, "/", "foo.yatt", "", '', 'foo']);

  $test->(html => "/d1/f1.yatt"
	  , [$docroot, "/d1/", "f1.yatt", "", '', 'f1.yatt']);
  $test->(html => "/d1/f1"
	  , [$docroot, "/d1/", "f1.yatt", "", '', 'f1']);

  $test->(ytmpl => "/d1/f2.yatt"
	  , [$ytmpl, "/d1/", "f2.yatt", "", '', 'f2.yatt']);
  $test->(ytmpl => "/d1/f2"
	  , [$ytmpl, "/d1/", "f2.yatt", "", '', 'f2']);

  $test->(html => "/code.ydo"
	  , [$docroot, '/', 'code.ydo', '', '', 'code.ydo']);

  $test->(html => "/img/bg.png"
	  , [$docroot, "/img/", "bg.png", "", '', 'bg.png']);

  $test->(html => "/img/missing.png"
	  , [$docroot, "/img/", "missing.png", "", '', 'missing.png']);
}

$i++;
{
  mkdir(my $realdir = "$BASE/t$i.docs");
  chdir($realdir);

  my $html = "$realdir/html";
  MY->mkfile_may_wait("$html/test.yatt", 'test1');
  MY->mkfile_may_wait("$html/real/index.yatt", 'index in realsub');
  MY->mkfile_may_wait("$html/real/test.yatt", 'test in realsub');
  MY->mkfile_may_wait("$html/real/code.ydo", 'code in realsub');
  MY->mkfile_may_wait("$html/rootcode.ydo", 'rootcode');

  MY->mkfile_may_wait("$html/js/jquery/jquery.min.js", 'yes this is dummy;-)');

  my $tmpl = "$realdir/runyatt.ytmpl";
  MY->mkfile_may_wait("$tmpl/index.yatt", 'virtual index');
  MY->mkfile_may_wait("$tmpl/virt/index.yatt", 'virtual index in virt');
  MY->mkfile_may_wait("$tmpl/virt/test.yatt", 'test in virt');
  MY->mkfile_may_wait("$tmpl/virt/code.ydo", 'code in virt');
  MY->mkfile_may_wait("$tmpl/virtcode.ydo", 'virtcode');

  MY->mkfile_may_wait("$tmpl/filevsdir.yatt", "file vs dir, this is the file");
  MY->mkfile_may_wait("$tmpl/filevsdir/index.yatt", "file vs dir, this is dir index");
  MY->mkfile_may_wait("$tmpl/filevsdir/real.yatt", "file vs dir, real in dir");


  my @tmpls = map {"$realdir/$_"} qw(html runyatt.ytmpl);
  my $test = sub {
    my ($loc, $want, @rest) = @_;
    is_deeply [lookup_path($loc, \@tmpls, @rest)]
      , $want, "lookup_path: $loc";
  };

  # GH-251: 5th is $is_index (now always present), 6th is $request_file.
  $test->("/index.yatt"
	  , [$tmpl, '/', 'index.yatt', '', 0, 'index.yatt']);
  $test->("/index"
	  , [$tmpl, '/', 'index.yatt', '', 0, 'index']);
  $test->("/", [$tmpl, '/', 'index.yatt', '', 1, '']);

  $test->("/index.yatt/foo/bar"
	  , [$tmpl, '/', 'index.yatt', '/foo/bar', 0, 'index.yatt']);
  $test->("/index/foo/bar"
	  , [$tmpl, '/', 'index.yatt', '/foo/bar', 0, 'index']);

  $test->("/test.yatt"
	  , [$html, '/', 'test.yatt', '', 0, 'test.yatt']);
  $test->("/test"
	  , [$html, '/', 'test.yatt', '', 0, 'test']);

  $test->("/test.yatt/foo/bar"
	  , [$html, '/', 'test.yatt', '/foo/bar', 0, 'test.yatt']);
  $test->("/test/foo/bar"
	  , [$html, '/', 'test.yatt', '/foo/bar', 0, 'test']);

  # GH-251: request_file must be a dot-boundary prefix of the
  # resolved file name, so a mismatching requested ext is NOT
  # reproduced (though the request itself is still served).
  $test->("/test.html"
	  , [$html, '/', 'test.yatt', '', 0, 'test']);
  $test->("/test.html/foo/bar"
	  , [$html, '/', 'test.yatt', '/foo/bar', 0, 'test']);

  $test->("/real/index.yatt"
	  , [$html, '/real/', 'index.yatt', '', 0, 'index.yatt']);
  $test->("/real/index"
	  , [$html, '/real/', 'index.yatt', '', 0, 'index']);
  $test->("/real/", [$html, '/real/', 'index.yatt', '', 1, '']);

  $test->("/real/index.yatt/foo/bar"
	  , [$html, '/real/', 'index.yatt', '/foo/bar', 0, 'index.yatt']);
  $test->("/real/index/foo/bar"
	  , [$html, '/real/', 'index.yatt', '/foo/bar', 0, 'index']);

  $test->("/real/test.yatt"
	  , [$html, '/real/', 'test.yatt', '', 0, 'test.yatt']);
  $test->("/real/test"
	  , [$html, '/real/', 'test.yatt', '', 0, 'test']);

  $test->("/real/code.ydo"
	  , [$html, '/real/', 'code.ydo', '', 0, 'code.ydo']);
  $test->("/rootcode.ydo"
	  , [$html, '/', 'rootcode.ydo', '', 0, 'rootcode.ydo']);
  $test->("/virt/code.ydo"
	  , [$tmpl, '/virt/', 'code.ydo', '', 0, 'code.ydo']);
  $test->("/virtcode.ydo"
	  , [$tmpl, '/', 'virtcode.ydo', '', 0, 'virtcode.ydo']);

  $test->("/js/jquery/jquery.min.js"
	  , [$html, '/js/jquery/', 'jquery.min.js', '', 0, 'jquery.min.js']);
  $test->("/js/jquery/jquery.min.js/foo/bar"
	  , [$html, '/js/jquery/', 'jquery.min.js', '/foo/bar'
	     , 0, 'jquery.min.js']);

  $test->("/virt/index.yatt"
	  , [$tmpl, '/virt/', 'index.yatt', '', 0, 'index.yatt']);
  $test->("/virt/index"
	  , [$tmpl, '/virt/', 'index.yatt', '', 0, 'index']);
  $test->("/virt/", [$tmpl, '/virt/', 'index.yatt', '', 1, '']);
  $test->("/virt/index.yatt/foo/bar"
	  , [$tmpl, '/virt/', 'index.yatt', '/foo/bar', 0, 'index.yatt']);
  $test->("/virt/index/foo/bar"
	  , [$tmpl, '/virt/', 'index.yatt', '/foo/bar', 0, 'index']);

  $test->("/virt/test.yatt"
	  , [$tmpl, '/virt/', 'test.yatt', '', 0, 'test.yatt']);
  $test->("/virt/test"
	  , [$tmpl, '/virt/', 'test.yatt', '', 0, 'test']);

  $test->("/virt/test.yatt/foo/bar"
	  , [$tmpl, '/virt/', 'test.yatt', '/foo/bar', 0, 'test.yatt']);
  $test->("/virt/test/foo/bar"
	  , [$tmpl, '/virt/', 'test.yatt', '/foo/bar', 0, 'test']);

  $test->('/filevsdir',  [$tmpl, '/', 'filevsdir.yatt', '', 0, 'filevsdir']);
  $test->('/filevsdir/', [$tmpl, '/filevsdir/', 'index.yatt', '', 1, '']);
  $test->('/filevsdir/real/foo'
	  , [$tmpl, '/filevsdir/', 'real.yatt', '/foo', 0, 'real']);
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
  # GH-251: trim_ext trims one trailing ".$ext" only for KNOWN extensions.
  my $test = sub {
    my ($fn, $extlist, $expect) = @_;
    is trim_ext($fn, $extlist), $expect
      , "trim_ext(".YATT::Lite::Util::terse_dump($fn, $extlist).") => "
      . ($expect // 'undef');
  };

  $test->("test.yatt", undef, "test");            # default ext is 'yatt'
  $test->("test.yatt", 'yatt', "test");
  $test->("test.yatt", ['yatt', 'ydo'], "test");
  $test->("code.ydo", ['yatt', 'ydo'], "code");

  # Apache mod_mime style: only the known extension is trimmed.
  $test->("foo.tar.yatt", 'yatt', "foo.tar");
  $test->("foo.bar", 'yatt', "foo.bar");          # unknown ext, as-is
  $test->("foo.yatt.gz", 'yatt', "foo.yatt.gz");  # not at the tail, as-is

  # Leading dot in ext spec is allowed.
  $test->("test.yatt", '.yatt', "test");

  $test->("noext", 'yatt', "noext");
  $test->(undef, 'yatt', undef);
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
