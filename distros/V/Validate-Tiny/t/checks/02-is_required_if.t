use strict;
use warnings;
use Test::More tests => 10;
use Validate::Tiny ':all';

my $rules = {
    fields => [qw/a b/],
};

my $r;

$rules->{checks} = [ a => is_required_if(1) ];
$r = validate( { a => '' }, $rules );
ok !$r->{success};
ok $r->{error}->{a};
$r = validate( { a => 'z' }, $rules );
ok $r->{success};

$rules->{checks} = [ a => is_required_if(0) ];
$r = validate( { a => '' }, $rules );
ok $r->{success};
$r = validate( { a => 'j' }, $rules );
ok $r->{success};

my $cond = sub {
    my $p = shift;
    return defined $p->{b} && $p->{b} eq 'z';
};

$rules->{checks} = [ a => is_required_if( $cond, 'foo' ) ];
$r = validate( { a => '' }, $rules );
ok $r->{success};
$r = validate( { a => '', b => 'z' }, $rules );
ok !$r->{success};
is $r->{error}->{a}, 'foo';
$r = validate( { a => 'k', b => 'z' }, $rules );
ok $r->{success};

{
    local $@;
    eval { is_required_id([]) };
    ok $@;
}
