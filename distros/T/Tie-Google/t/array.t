#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;
use Test::More;

use Tie::Google;
use File::Spec::Functions qw(catfile updir);
use Cwd qw(cwd);

my (@g, $KEY, $warn);
$KEY = -d "t" ? catfile(cwd, ".googlekey")
              : catfile(cwd, updir, ".googlekey");

if (-z $KEY) {
    plan skip_all => "No key provided";
    exit;
} else {
    plan tests => 7;
}

tie @g, 'Tie::Google', $KEY, "perl";
ok(@g, "tie \@g, 'Tie::Google', '$KEY', 'perl'");
is(ref tied(@g), "Tie::Google", "tied(\@g)->isa('Tie::Google')");

eval {
    local $SIG{__WARN__} = sub { chomp($warn = $_[0]) };
    push @g, "perl";
};
ok($warn =~ /add results to/, "STORE warns correctly: '$warn'");

ok(exists $g[0], "EXISTS");


isnt(tied(@g)->is_scalar, 1, "tied(\@g)->is_scalar == undef");
is  (tied(@g)->is_array,  1, "tied(\@g)->is_array  == 1");
isnt(tied(@g)->is_hash,   1, "tied(\@g)->is_hash   == undef");
