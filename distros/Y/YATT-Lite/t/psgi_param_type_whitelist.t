#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# Only arguments whose type is in YATT::Lite::VarTypes::%SAFE_TYPES
# (text, list, scalar, bool) may be bound from request parameters.
# Everything else (html, attr, code, expr, delegate, and the body
# argument) is treated like an unknown parameter: stashed when
# stash_unknown_params_to is set, silently dropped otherwise.
#
# Before this, only body/code/expr were blocked, so a public page
# declaring `header=html` reflected ?header=<script>... unescaped.
#

use Test::More;
use Test::Differences;
use File::Temp qw(tempdir);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::WebMVC0::SiteApp ();
use YATT::Lite::VarTypes;

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END {
  chdir('/');
}

my $PAGE = <<'END';
<!yatt:args title header=html cls=attr flag=bool items=list n=scalar>
title=&yatt:title;
header=&yatt:header;
cls=&yatt:cls;
flag=&yatt:flag;
items=&yatt:items[0];,&yatt:items[1];
n=&yatt:n;
stash=&yatt:CON:stash();
END

my $XSS = "<script>alert(document.cookie)</script>";

#========================================
subtest "SAFE_TYPES is exactly text/list/scalar/bool", sub {
  no warnings 'once';
  is_deeply [sort keys %YATT::Lite::VarTypes::SAFE_TYPES]
    , [sort qw(text list scalar bool)];

  # Every other declared type is unsafe as a request parameter.
  foreach my $type (qw(text list scalar bool)) {
    my $var = YATT::Lite::VarTypes->can("t_$type")->()->new([$type], $type, 0);
    ok !$var->is_unsafe_param, "$type is a safe param type";
  }
  foreach my $type (qw(html attr code expr delegate)) {
    my $var = YATT::Lite::VarTypes->can("t_$type")->()->new([$type], $type, 0);
    ok $var->is_unsafe_param, "$type is an unsafe param type";
  }
  my $body = YATT::Lite::VarTypes::t_text->new(['text'], 'body', 0);
  $body->mark_body_argument;
  ok $body->is_unsafe_param, "body argument is unsafe even as text";
};

#========================================
my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile_may_wait("$docroot/index.yatt", $PAGE);
  YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "MyYATTParamWhitelist$i"
    , app_root => $approot
    , doc_root => $docroot
    , %opts
  );
};

#========================================
subtest "deployment: html/attr params are stashed, never bound", sub {
  local $ENV{PLACK_ENV} = 'deployment';
  # &yatt:CON:stash() prints a HASH; escape() dumps it only with HTDEBUG_DUMP.
  local $ENV{HTDEBUG_DUMP} = 1;
  my $site = $make_site->();

  test_psgi $site->to_app, sub {
    my ($cb) = @_;

    # Safe types are bound (and text is escaped on output).
    my $res = $cb->(GET "/?title=".enc("<b>T</b>")."&flag=1&items=a&n=42");
    is $res->code, 200, "safe params: 200";
    eq_or_diff($res->content, <<'END', "safe params are bound");
title=&lt;b&gt;T&lt;/b&gt;
header=
cls=
flag=1
items=a,
n=42
stash={
  &#39;yatt.unknown_params&#39; =&gt; {}
}

END

    # html is NOT bound: nothing reflected, value lands in the stash.
    $res = $cb->(GET "/?header=".enc($XSS)."&cls=".enc('" onload="x'));
    is $res->code, 200, "html/attr params: 200";
    unlike $res->content, qr/<script>/, "html param is not reflected";
    unlike $res->content, qr/" onload="/, "attr param is not reflected";
    # (&yatt:CON:stash() prints the dump through escape(), hence &lt; &quot;)
    eq_or_diff($res->content, <<'END', "html/attr params go to the stash");
title=
header=
cls=
flag=
items=,
n=
stash={
  &#39;yatt.unknown_params&#39; =&gt; {
    &#39;cls&#39; =&gt; [
      &#39;&quot; onload=&quot;x&#39;
    ],
    &#39;header&#39; =&gt; [
      &#39;&lt;script&gt;alert(document.cookie)&lt;/script&gt;&#39;
    ]
  }
}

END
  };
};

#========================================
subtest "development (no stash): html param is dropped, not an error", sub {
  local $ENV{PLACK_ENV} = 'development';
  my $site = $make_site->();

  test_psgi $site->to_app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET "/?title=T&header=".enc($XSS));
    is $res->code, 200, "known-but-unsafe param is not an error";
    unlike $res->content, qr/<script>/, "html param is not reflected";
    like $res->content, qr/^title=T$/m, "text param is still bound";
    like $res->content, qr/^header=$/m, "html param stays empty";

    # Sanity: a truly unknown param is still an error in development.
    $res = $cb->(GET "/?nosuch=1");
    is $res->code, 500, "unknown param is an error without stash";
    like $res->content, qr/Unknown args: nosuch/;
  };
};

#========================================
subtest "html args still work when passed from a calling widget", sub {
  local $ENV{PLACK_ENV} = 'deployment';
  ++$i;
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile_may_wait("$docroot/index.yatt", <<'END');
<!yatt:args title>
<yatt:layout title>
  <:yatt:header><em>safe markup</em></:yatt:header>
</yatt:layout>

<!yatt:widget layout title header=html>
title=&yatt:title;
header=&yatt:header;
END

  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "MyYATTParamWhitelist$i"
    , app_root => $approot
    , doc_root => $docroot
  );

  test_psgi $site->to_app, sub {
    my ($cb) = @_;
    my $res = $cb->(GET "/?title=T&header=".enc($XSS));
    is $res->code, 200;
    like $res->content, qr{^header=<em>safe markup</em>$}m
      , "html from the calling widget is printed raw";
    unlike $res->content, qr/<script>/, "request param never reaches the widget";
  };
};

sub enc {
  my ($s) = @_;
  $s =~ s{([^A-Za-z0-9_.~-])}{sprintf("%%%02X", ord $1)}ge;
  $s;
}

done_testing();
