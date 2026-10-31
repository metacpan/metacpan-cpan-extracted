#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# <yatt:my var>...</yatt:my> などで出力を捕捉している間の $CON。
#
#  - 捕捉中の widget/body 呼び出しの出力は、変数に入る (GH-293)
#  - 捕捉中の $CON は元の CON に delegate する proxy なので、
#    $CON のメソッドが呼べる (GH-295)
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use File::Temp qw/tempdir/;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $tempdir = tempdir(CLEANUP => 1);
END {chdir "/"}
my $testno = 0;

my $make_app = sub {
  my (%files) = @_;
  my $app_root = "$tempdir/t" . ++$testno;
  my $docroot = "$app_root/docs";
  YATT::Lite::Util::File->mkfile_may_wait(
    map {("$docroot/$_" => $files{$_})} keys %files
  );
  YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "TestCaptureCon$testno",
    app_root => $app_root,
    doc_root => $docroot,
  );
};

{
  my $site = $make_app->(
    'body.yatt' => <<'END',
<yatt:foo>[body]</yatt:foo>

<!yatt:widget foo body=[code]>
<yatt:my tmp>(&yatt:body();)</yatt:my>
{&yatt:tmp;}
END
    'conmethod.yatt' => <<'END',
<yatt:my tmp>(<yatt:foo/>)</yatt:my>
{&yatt:tmp;}

<!yatt:widget foo>
&yatt:CON:file();
END
    'textarg.yatt' => <<'END',
<yatt:foo><:yatt:t><yatt:bar/></:yatt:t></yatt:foo>

<!yatt:widget foo t=text>
[&yatt:t;]

<!yatt:widget bar>
&yatt:CON:file();
END
    'pi.yatt' => <<'END',
<yatt:my v:text><?perl print $CON $CON->isa('YATT::Lite::Connection') ? "isa" : "not"; ?></yatt:my>{&yatt:v;}
END
    'pi_expr.yatt' => <<'END',
<yatt:my v:text><?perl= 1+1 ?></yatt:my>{&yatt:v;}
END
    'nested.yatt' => <<'END',
<yatt:my a>(<yatt:foo><:yatt:t><yatt:bar/></:yatt:t></yatt:foo>)</yatt:my>{&yatt:a;}

<!yatt:widget foo t=text>
[&yatt:t;]

<!yatt:widget bar>
&yatt:CON:file();
END
    'after.yatt' => <<'END',
<yatt:my tmp>(<yatt:foo/>)</yatt:my>{&yatt:tmp;}
<yatt:foo/>

<!yatt:widget foo>
&yatt:CON:file();
END
  );

  is(eval {$site->render("body")} // "ERROR: $@", "{([body])}\n\n"
     , "body output is captured into my var");

  like(eval {$site->render("conmethod")} // "ERROR: $@"
       , qr{^\{\(\S*conmethod\.yatt}
       , "\$CON methods are available while capturing");

  like(eval {$site->render("textarg")} // "ERROR: $@"
       , qr{^\[\S*textarg\.yatt}
       , "\$CON methods are available in element for text arg");

  is(eval {$site->render("pi")} // "ERROR: $@", "{isa}\n"
     , "captured \$CON isa YATT::Lite::Connection in <?perl ?>");

  is(eval {$site->render("pi_expr")} // "ERROR: $@", "{2}\n"
     , "<?perl= ?> is captured as a value");

  like(eval {$site->render("nested")} // "ERROR: $@"
       , qr{^\{\(\[\S*nested\.yatt\s*\]\s*\)\}}
       , "\$CON methods are available in nested capture");

  my $after = eval {$site->render("after")} // "ERROR: $@";
  is(scalar(() = $after =~ /after\.yatt/g), 2
     , "original \$CON still works after capture")
    or diag $after;
}

done_testing();
