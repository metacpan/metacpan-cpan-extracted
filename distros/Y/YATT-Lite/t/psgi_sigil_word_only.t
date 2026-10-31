#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# Double sigils (~~=PAGE, !!=ACTION) take the page/action name from the
# parameter *value*. Before the fix, that value was joined onto the
# template directory as-is, so "~~=../../somewhere" could reach a
# directory outside doc_root and load it as a YATT app (executing its
# .htyattrc.pl). Now the name must be a plain \w+ word.
#

use Test::More;
use File::Temp qw/tempdir/;
use File::Path qw(make_path);
use Cwd ();

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

#
# Layout:
#   $TEMPDIR/app/html/index.yatt   -- doc_root
#   $TEMPDIR/evil/.htyattrc.pl     -- outside app_root. Must never be loaded.
#   $TEMPDIR/evil/index.yatt
#
my $app_root = "$TEMPDIR/app";
my $html_dir = "$app_root/html";
my $evil_dir = "$TEMPDIR/evil";
my $marker   = "$TEMPDIR/evil-rc-was-executed";

make_path($html_dir, $evil_dir);

MY->mkfile_may_wait("$html_dir/index.yatt", <<'END');
<!yatt:args>
top page

<!yatt:page foo>
subpage foo

<!yatt:action bar>
my ($this, $CON) = @_;
print $CON "action bar";
END

MY->mkfile_may_wait("$evil_dir/.htyattrc.pl", <<END);
use strict;
open my \$fh, '>', '$marker' or die \$!;
print \$fh "executed\\n";
close \$fh;
1;
END

MY->mkfile_may_wait("$evil_dir/index.yatt", <<'END');
evil index
END

my $site = YATT::Lite::WebMVC0::SiteApp
  ->new(app_ns => 'TestSigilWordOnly'
        , app_root => $app_root
        , doc_root => $html_dir
        , debug_cgen => $ENV{DEBUG});

my $test = Plack::Test->create($site->to_app);

# Relative path from doc_root ($TEMPDIR/app/html) to $TEMPDIR/evil.
my $traversal = "../../evil";

#========================================
subtest "sanity: normal sigils still work", sub {
  my $res = $test->request(GET "/");
  is $res->code, 200, "GET / is 200";
  like $res->content, qr/top page/, "GET / renders top page";

  $res = $test->request(GET "/?~~=foo");
  is $res->code, 200, "~~=foo is 200";
  like $res->content, qr/subpage foo/, "~~=foo renders subpage foo";

  $res = $test->request(GET "/?~foo=1");
  is $res->code, 200, "~foo=1 is 200";
  like $res->content, qr/subpage foo/, "~foo=1 renders subpage foo";

  $res = $test->request(GET "/?!!=bar");
  is $res->code, 200, "!!=bar is 200";
  is $res->content, "action bar", "!!=bar invokes action bar";

  $res = $test->request(POST "/", [ '!!' => 'bar' ]);
  is $res->code, 200, "POST !!=bar is 200";
  is $res->content, "action bar", "POST !!=bar invokes action bar";

  # Bare sigil (<input type="submit" name="~">) means the default page.
  $res = $test->request(GET "/?~=any");
  is $res->code, 200, "~=any (bare sigil) is 200";
  like $res->content, qr/top page/, "~=any renders the default page";

  $res = $test->request(POST "/", [ '~' => 'Back' ]);
  is $res->code, 200, "POST ~=Back (bare sigil) is 200";
  like $res->content, qr/top page/, "POST ~=Back renders the default page";

  # Empty double sigil also means the default page/action.
  $res = $test->request(GET "/?~~=");
  is $res->code, 200, "~~= (empty) is 200";
  like $res->content, qr/top page/, "~~= renders the default page";
};

#========================================
subtest "~~=VALUE with path traversal is rejected as 400", sub {
  my $res = $test->request(GET "/?~~=$traversal");
  is $res->code, 400, "GET ~~=$traversal is 400";
  like $res->content, qr/Invalid subpage/, "with 'Invalid subpage' diag";
  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed";

  $res = $test->request(POST "/", [ '~~' => $traversal ]);
  is $res->code, 400, "POST ~~=$traversal is 400";
  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed (POST)";

  # URL-encoded form of the same thing.
  $res = $test->request(GET "/?~~=..%2F..%2Fevil");
  is $res->code, 400, "GET ~~=..%2F..%2Fevil is 400";
  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed (encoded)";
};

#========================================
subtest "!!=VALUE with path traversal is rejected as 400", sub {
  my $res = $test->request(GET "/?!!=$traversal");
  is $res->code, 400, "GET !!=$traversal is 400";
  like $res->content, qr/Invalid action/, "with 'Invalid action' diag";
  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed";

  $res = $test->request(POST "/", [ '!!' => $traversal ]);
  is $res->code, 400, "POST !!=$traversal is 400";
  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed (POST)";
};

#========================================
subtest "other non-word names are rejected too", sub {
  foreach my $name ("foo/bar", "foo.bar", "foo bar", ".", "..", "/evil") {
    my $res = $test->request(GET "/?~~=$name");
    is $res->code, 400, "~~=$name is 400";
    $res = $test->request(GET "/?!!=$name");
    is $res->code, 400, "!!=$name is 400";
  }
};

#========================================
subtest "VFS::Dir::load itself rejects '/' and '..' (last line of defense)", sub {
  my $vfs = $site->get_yatt('/')->get_trans;
  my $root = $vfs->root;

  foreach my $name ("../../evil", "..", "foo/bar", "/evil") {
    my $got = eval { $root->lookup($vfs, $name) };
    like $@, qr/^Invalid part name \(contains '\/' or '\.\.'\)/
      , "lookup('$name') croaks";
    ok !defined $got, "lookup('$name') returns nothing";
  }

  ok !-e $marker, ".htyattrc.pl outside app_root was NOT executed";

  # Plain word names still resolve.
  ok $root->lookup($vfs, "index"), "lookup('index') still works";
};

#========================================
subtest "nothing outside app_root was loaded", sub {
  ok !-e $marker, "marker file still does not exist";
  # load_yatt caches by the path as given ("$html_dir/../../evil"),
  # so compare by realpath.
  my $evil_real = Cwd::realpath($evil_dir);
  my @loaded = grep {
    (Cwd::realpath($_) // '') eq $evil_real
  } keys %{$site->{_path2yatt}};
  is_deeply \@loaded, [], "evil dir is not registered in the factory's path2yatt";
};

done_testing();
