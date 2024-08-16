#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::More;
use Test::Differences;
use File::Temp qw(tempdir);

use Plack::Test;
use HTTP::Request::Common;

use YATT::Lite::Breakpoint;

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util::File qw(mkfile);

use YATT::Lite::WebMVC0::SiteApp ();

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

my $i = 1;
{
  my $CLS = 'MyYATTUnknownParams';
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile("$docroot/index.yatt", <<'END');
<!yatt:args x y z>
x=&yatt:x;
y=&yatt:y;
z=&yatt:z;
stash=&yatt:CON:stash();
&yatt:body;
END

  local $ENV{PLACK_ENV} = 'deployment';

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => $CLS
    , app_root => $approot
    , doc_root => $docroot
    , body_argument_type => 'html'
    # , stash_unknown_params_to => 'yatt.unknown_params'
  );

  test_psgi $site->to_app, sub {
    my ($cb) = @_;
    # Sanity check.
    my $res = $cb->(GET "/?x=A;y=B;z=C");
    eq_or_diff($res->content, <<'END');
x=A
y=B
z=C
stash={
  'yatt.unknown_params' => {}
}


END

    # Unknown params are stashed.
    # body is known but always stashed for security.
    $res = $cb->(GET "/?a=X;b=Y;x=Z;body=ZZZ");
    eq_or_diff($res->content, <<'END');
x=Z
y=
z=
stash={
  'yatt.unknown_params' => {
    'a' => [
      'X'
    ],
    'b' => [
      'Y'
    ],
    'body' => [
      'ZZZ'
    ]
  }
}


END

    # Also known but code params are stashed.
    $res = $cb->(GET "/?body=foo");
    eq_or_diff($res->content, <<'END');
x=
y=
z=
stash={
  'yatt.unknown_params' => {
    'body' => [
      'foo'
    ]
  }
}


END

  };
}

++$i;
{
  my $CLS = 'MyYATTInDevelopment';
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile("$docroot/index.yatt", <<'END');
<!yatt:args x y z>
x=&yatt:x;
y=&yatt:y;
z=&yatt:z;
stash=&yatt:CON:stash();
<yatt:body/>
END

  local $ENV{PLACK_ENV} = 'development';

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => $CLS
    , app_root => $approot
    , doc_root => $docroot
  );

  test_psgi $site->to_app, sub {
    my ($cb) = @_;
    # Sanity check.
    my $res = $cb->(GET "/?x=A;y=B;z=C");
    eq_or_diff($res->content, <<'END');
x=A
y=B
z=C
stash={}


END

    # Unknown args are raised as error
    $res = $cb->(GET "/?a=A;y=B;z=C");
    is $res->code, 500;
    like $res->content, qr/Unknown args: a/;
  }
}

done_testing();
