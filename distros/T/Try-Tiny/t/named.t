use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "Sub::Util or Sub::Name required"
        unless eval { require Sub::Util; defined &Sub::Util::set_subname; }
            || eval { require Sub::Name; Sub::Name->VERSION(0.08) };
    plan tests => 3;
}

use Try::Tiny;

my $name;
try {
    $name = (caller(0))[3];
};
is $name, "main::try {...} ", "try name"; # note extra space

try {
    die "Boom";
} catch {
    $name = (caller(0))[3];
};
is $name, "main::catch {...} ", "catch name"; # note extra space

try {
    die "Boom";
} catch {
    # noop
} finally {
    $name = (caller(0))[3];
};
is $name, "main::finally {...} ", "finally name"; # note extra space
