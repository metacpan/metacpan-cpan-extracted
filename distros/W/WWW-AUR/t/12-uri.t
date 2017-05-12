#!perl

use warnings;
use strict;
use Test::More;
use WWW::AUR::URI qw(:all);

my $pkgs = "https://aur.archlinux.org/cgit/aur.git";
is pkgfile_uri('f'), "$pkgs/snapshot/f.tar.gz";
is pkgfile_uri('fo'), "$pkgs/snapshot/fo.tar.gz";
is pkgfile_uri('foo'), "$pkgs/snapshot/foo.tar.gz";

is pkgbuild_uri('bar'), "$pkgs/plain/PKGBUILD?h=bar";
is pkgbuild_uri('ba'), "$pkgs/plain/PKGBUILD?h=ba";
is pkgbuild_uri('b'), "$pkgs/plain/PKGBUILD?h=b";

my $rpc = "https://aur.archlinux.org/rpc";
my $arg = "arg%5B%5D";
is rpc_uri('multiinfo', qw/foo bar/), "$rpc?type=multiinfo&$arg=foo&$arg=bar";
is rpc_uri('info', qw/foo bar/),  "$rpc?type=info&arg=foo";
is rpc_uri('info', 'foo'), rpc_uri('info', qw/foo bar/);

is rpc_uri('search', 'foo'), "$rpc?type=search&arg=foo";
is rpc_uri('search', 'foo'), "$rpc?type=search&arg=foo";
is rpc_uri('msearch', 'juster'), "$rpc?type=msearch&arg=juster";

$WWW::AUR::URI::Scheme = 'http';
s/^https/http/ for $rpc, $pkgs;

is rpc_uri('search', 'foo'), "$rpc?type=search&arg=foo";
is pkgfile_uri('foo'), "$pkgs/snapshot/foo.tar.gz";
is pkgbuild_uri('bar'), "$pkgs/plain/PKGBUILD?h=bar";

done_testing;
