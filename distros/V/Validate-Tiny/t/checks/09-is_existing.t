use strict;
use warnings;

use Test::More;
use Validate::Tiny ':all';

my $rules = {
    fields => [qw/a b/],
    checks => [
        a => is_existing(),
        b => is_existing('NO')
    ]
};

my $r;

$r = validate({}, $rules);
ok !$r->{success};
is_deeply $r->{error}, { a => 'Must be defined', b => 'NO' };

$r = validate( {a => 'z', b => ''}, $rules );
ok $r->{success};

$r = validate( {a => '', b => ''}, $rules );
ok $r->{success};

done_testing;
