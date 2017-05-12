#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;
use Test::More;

use Tie::Google;
use File::Spec::Functions qw(catfile updir);
use Cwd qw(cwd);

my (%g, $KEY, $warn);
$KEY = -d "t" ? catfile(cwd, ".googlekey")
              : catfile(cwd, updir, ".googlekey");

if (-z $KEY) {
    plan skip_all => "No key provided";
    exit;
} else {
    plan tests => 8;
}

tie %g, 'Tie::Google', $KEY, "perl";
ok(keys %g, "tie %g, 'Tie::Google', '$KEY', 'perl'");
is(ref tied(%g), "Tie::Google", "tied(%g)->isa('Tie::Google')");

eval {
    local $SIG{__WARN__} = sub { chomp($warn = $_[0]) };
    $g{"perl"} = "WOAH!";
};
ok($warn =~ /attempt to modify/, "STORE warns correctly: '$warn'");

while (my ($k, $v) = each %g) {
    ok(defined $k, "each %g ($k)");
    ok(defined $v, "each %g ($v)");
}

isnt(tied(%g)->is_scalar, 1, "tied(\%g)->is_scalar == undef");
isnt(tied(%g)->is_array,  1, "tied(\%g)->is_array  == undef");
is  (tied(%g)->is_hash,   1, "tied(\%g)->is_hash   == 1");
