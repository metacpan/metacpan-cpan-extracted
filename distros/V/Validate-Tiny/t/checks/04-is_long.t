use strict;
use warnings;
use Test::More;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

# is_long_between
{
    $r->{checks} = [ a => is_long_between( 2, 3 ) ];
    ok validate( { a => '' }, $r )->{success};
    ok !validate( { a => 'a' }, $r )->{success};
    ok validate( { a => 'ab' },  $r )->{success};
    ok validate( { a => 'abc' }, $r )->{success};
    ok !validate( { a => 'abcd' }, $r )->{success};

    $r->{checks} = [ a => is_long_between( 2, 3, 'NO' ) ];
    is validate( { a => 'abcd' }, $r )->{error}->{a}, "NO";
}

# is_long_at_least
{
    $r->{checks} = [ a => is_long_at_least(2) ];
    ok validate({a => ''}, $r)->{success};
    ok !validate({a => 'a'}, $r)->{success};
    ok validate({a => 'ab'}, $r)->{success};

    $r->{checks} = [ a => is_long_at_least(2, 'NO') ];
    is validate( { a => 'a' }, $r )->{error}->{a}, "NO";
}

# is_long_at_most (irrelevant)
{
    $r->{checks} = [ a => is_long_at_most(2) ];
    ok validate({a => ''}, $r)->{success};
    ok !validate({a => 'abc'}, $r)->{success};
    ok validate({a => 'ab'}, $r)->{success};
    ok validate({a => 'a'}, $r)->{success};

    $r->{checks} = [ a => is_long_at_most(2, 'NO') ];
    is validate( { a => 'abcd' }, $r )->{error}->{a}, "NO";
}

done_testing;
