use strict;
use warnings;
use Test::More tests => 9;
use Validate::Tiny ':all';

my $rules = {
    fields => [qw/a b c/],
    checks => [
        a => is_required(),
        b => is_required('NO'),
    ]
};

my $r;

$r = validate( {}, $rules );
ok !$r->{success};
is_deeply $r->{error}, { a => 'Required', b => 'NO' };

$r = validate( {a => 'z', b => '', c => 'y' }, $rules );
ok !$r->{success};
is_deeply $r->{error}, { b => 'NO' };

$r = validate( {a => '', b => 'z' }, $rules );
ok !$r->{success};
is_deeply $r->{error}, { a => 'Required' };

$r = validate( {a => 'x', b => 'z' }, $rules );
ok $r->{success};
is_deeply $r->{data}, { a => 'x', b => 'z' };
is_deeply $r->{error}, {};
