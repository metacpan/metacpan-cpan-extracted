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
use YATT::Lite::Util::File qw(mkfile_may_wait);

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
  MY->mkfile_may_wait("$docroot/index.yatt", <<'END');
<!yatt:args x y z>
x=&yatt:x;
y=&yatt:y;
z=&yatt:z;
stash=&yatt:CON:stash();
&yatt:body;
END

  local $ENV{PLACK_ENV} = 'deployment';
  # This test prints the stash (a HASH) via &yatt:CON:stash(); escape()
  # dumps references only when HTDEBUG_DUMP is on (or in development).
  local $ENV{HTDEBUG_DUMP} = 1;

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
  &#39;yatt.unknown_params&#39; =&gt; {}
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
  &#39;yatt.unknown_params&#39; =&gt; {
    &#39;a&#39; =&gt; [
      &#39;X&#39;
    ],
    &#39;b&#39; =&gt; [
      &#39;Y&#39;
    ],
    &#39;body&#39; =&gt; [
      &#39;ZZZ&#39;
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
  &#39;yatt.unknown_params&#39; =&gt; {
    &#39;body&#39; =&gt; [
      &#39;foo&#39;
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
  MY->mkfile_may_wait("$docroot/index.yatt", <<'END');
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
