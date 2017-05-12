#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;
use Test::More;

use Tie::Google;
use Cwd qw(cwd);
use File::Spec::Functions qw(catfile updir);

my ($g, $KEY, $warn);
$KEY = -d "t" ? catfile(cwd, ".googlekey")
              : catfile(cwd, updir, ".googlekey");

if (-z $KEY) {
    plan skip_all => "No key provided";
    exit;
} else {
    plan tests => 6;
}

tie $g, 'Tie::Google', $KEY, "perl";
ok(defined $g, "tie \$g, 'Tie::Google', '$KEY', 'perl'");
is(ref tied($g), "Tie::Google", "tied(\$g)->isa('Tie::Google')");

eval {
    local $SIG{__WARN__} = sub { chomp($warn = $_[0]) };
    $g = "perl";
};
ok($warn =~ /attempt to modify/, "STORE warns correctly: '$warn'");

is  (tied($g)->is_scalar, 1, "tied(\$g)->is_scalar == 1");
isnt(tied($g)->is_array,  1, "tied(\$g)->is_array  == undef");
isnt(tied($g)->is_hash,   1, "tied(\$g)->is_array  == undef");
