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

++$i;
{
  my $THEME = "[vfscache with crossbase]";

  my $CLS = myapp($i);
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/html";
  my $ytmpl   = "$approot/ytmpl";

  my $BASE = do {
    my $mkxhf_base = sub {
      "base[\n".join("", map {"- $_\n"} @_)."]\n";
    };
    sub {$mkxhf_base->(@_, qw(.. @ytmpl))};
  };

  MY->mkfile("$ytmpl/common.ytmpl" => "COMMON"

	     , "$docroot/us2012/.htyattconfig.xhf"
	     => $BASE->(qw(@html/jp2011))

	     , "$docroot/us2014/.htyattconfig.xhf"
	     => $BASE->(qw(@html/us2012 @html/jp2015_en @html/jp2015))

	     , "$docroot/us2016/.htyattconfig.xhf"
	     => $BASE->(qw(@html/us2012 @html/jp2015_en @html/jp2015))

	     , "$docroot/jp2015_en/.htyattconfig.xhf"
	     => $BASE->(qw(../jp2011))

	     , "$docroot/jp2015/.htyattconfig.xhf"
	     => $BASE->(qw(../jp2011))

	     , "$docroot/jp2011/.htyattconfig.xhf"
	     => $BASE->()

	     , "$docroot/us2012/index.yatt" => <<'END'
OK <yatt:item/>
END

	     , "$docroot/jp2011/item.yatt" => <<'END'
- FROM jp2011
END

	     , "$docroot/us2014/index.yatt" => <<'END'
OK <yatt:item/>
END

	     , "$docroot/jp2015_en/item.yatt" => <<'END'
- FROM jp2015_en
END

             , map(("$docroot/$_/index.yatt" => "OK - $_/\n")
                   , qw(jp2015 us2016))
	    );


  my $F = Factory->new(app_ns => $CLS
		       , app_root => $approot
		       , doc_root => $docroot
		       , app_base => '@ytmpl'
		      );

  foreach my $dn (qw(jp2015/ us2016/)) {
    is $F->get_yatt("/$dn")->render('' => [])
      , "OK - $dn\n", "$THEME /$dn";
  }


  is $F->get_yatt('/us2012/')->render('' => [])
    , "OK - FROM jp2011\n\n", "$THEME /us2012/";

  is $F->get_yatt('/us2014/')->render('' => [])
    , "OK - FROM jp2015_en\n\n", "$THEME /us2014/";

}

done_testing();
