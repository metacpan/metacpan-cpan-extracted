#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# $CON->redirect / raise_redirect / &yatt:redirect() advertise built-in
# open redirect protection for plain string urls. The old check was a
# single regex for "//host" and "scheme://host", so browser-normalized
# forms like "\\evil", "/\evil", "///evil", "http:\\evil" and urls with
# leading whitespace slipped through into Location:.
#

use Test::More;
use File::Temp qw/tempdir/;
use File::Path qw(make_path);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::Util::File qw/mkfile_may_wait/;

my $TEMPDIR = tempdir(CLEANUP => 1);
my $app_root = "$TEMPDIR/app";
my $html_dir = "$app_root/html";
make_path($html_dir);

MY->mkfile_may_wait("$html_dir/index.yatt", <<'END');
top page
END

# F8: the template entity entry point, documented idiom.
MY->mkfile_may_wait("$html_dir/nx.yatt", <<'END');
<!yatt:args nx>
&yatt:redirect(:nx);
END

my $site = YATT::Lite::WebMVC0::SiteApp
  ->new(app_ns => 'TestRedirectGuard'
        , app_root => $app_root
        , doc_root => $html_dir
        , debug_cgen => $ENV{DEBUG});

# F4: the action/method entry point, documented idiom.
$site->mount_action('/redir', sub {
  my ($this, $con) = @_;
  $con->raise_redirect($con->param('nx'));
});

$site->mount_action('/redir_ext', sub {
  my ($this, $con) = @_;
  $con->raise_redirect(\ $con->param('nx'));
});

$site->mount_action('/host', sub {
  my ($this, $con) = @_;
  print $con $con->mkhost;
});

my $test = Plack::Test->create($site->to_app);

# Find out what this test client looks like as a host.
my $HOST = do {
  my $res = $test->request(GET "/host");
  is $res->code, 200, "probe /host";
  $res->content;
};
ok defined $HOST && length $HOST, "mkhost is '$HOST'";

my $enc = sub {
  my ($s) = @_;
  $s =~ s{([^A-Za-z0-9_.~-])}{sprintf("%%%02X", ord $1)}ge;
  $s;
};

my $redirect_via = sub {
  my ($entry, $nx) = @_;
  if ($entry eq 'action') {
    $test->request(GET "/redir?nx=" . $enc->($nx));
  } elsif ($entry eq 'entity') {
    $test->request(GET "/nx?nx=" . $enc->($nx));
  } else {
    die "unknown entry $entry";
  }
};

#========================================
subtest "same-origin targets are still redirected (302)", sub {
  my @ok = (
    "/qux",
    "/qux?x=1&y=2",
    "/qux#frag",
    "./",
    "../up/",
    "index?x=1",
    "?x=1",
    "/foo//bar",            # '//' not at the start is just a path
    "/foo\\bar",            # backslash not at the start is just a path
    "http://$HOST/bar/",    # same host, absolute
    "//$HOST/bar/",         # same host, scheme-relative
  );
  foreach my $entry (qw(action entity)) {
    foreach my $nx (@ok) {
      my $res = $redirect_via->($entry, $nx);
      is $res->code, 302, "[$entry] '$nx' is 302";
      is $res->header('Location'), $nx, "[$entry] Location is '$nx'";
    }
  }
};

#========================================
subtest "foreign-host and browser-normalized forms are rejected (400)", sub {
  my @ng = (
    # already rejected before this fix
    "//evil.example/",
    "http://evil.example/",
    "https://evil.example",
    "http://evil.example:8080/x",
    # bypasses of the old regex
    "\\\\evil.example",
    "/\\evil.example",
    "\\/evil.example",
    "///evil.example",
    "////evil.example/x",
    "/\\/evil.example",
    "http:\\\\evil.example",
    "http:///evil.example",
    "https:/\\evil.example",
    " //evil.example",          # leading space
    "\t//evil.example",         # leading tab
    "\n//evil.example",
    "http://$HOST\@evil.example/",   # userinfo trick
    "http://$HOST\\\@evil.example/", # backslash ends host for browsers
    "http://evil.example\\\@$HOST/",
    "http://$HOST.evil.example/",
    "javascript:alert(1)",
    "data:text/html,hi",
    "HTTP://EVIL.EXAMPLE/",
    # header injection
    "/qux\r\nSet-Cookie: x=1",
    "/qux\nX: y",
    "/qux\x00",
  );
  foreach my $entry (qw(action entity)) {
    foreach my $nx (@ng) {
      my $res = $redirect_via->($entry, $nx);
      (my $shown = $nx) =~ s/([^\x21-\x7e])/sprintf("\\x%02x", ord $1)/ge;
      is $res->code, 400, "[$entry] '$shown' is 400";
      ok !defined $res->header('Location')
        , "[$entry] '$shown' has no Location header";
    }
  }
};

#========================================
subtest "SCALAR REF opts out of the check (intentional external redirect)", sub {
  foreach my $nx ("http://evil.example/", "//evil.example/", "\\\\evil.example") {
    my $res = $test->request(GET "/redir_ext?nx=" . $enc->($nx));
    is $res->code, 302, "\\'$nx' is 302";
    is $res->header('Location'), $nx, "Location is '$nx'";
  }
};

#========================================
subtest "empty / undefined url", sub {
  my $res = $test->request(GET "/redir?nx=");
  is $res->code, 400, "empty url is 400";
  ok !defined $res->header('Location'), "no Location header";
};

done_testing();
