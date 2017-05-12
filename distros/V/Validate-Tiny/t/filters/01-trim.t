
use strict;
use warnings;

use Validate::Tiny ':all';
use Test::More;

my $rules = {
    fields  => ['a'],
    filters => [ a => filter('trim') ]
};

my $res = validate({a => undef}, $rules);
is $res->{a}, undef;

for my $e (" ", "\n", "\r") {
    for ("${e}a${e}", "${e}a", "a${e}", "${e}${e}a${e}${e}") {
        my $res = validate({ a => $_ }, $rules);
        is $res->{data}->{a}, 'a', "OK for [$_]";
    }
}

done_testing;

