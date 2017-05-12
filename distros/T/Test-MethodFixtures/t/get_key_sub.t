use strict;
use warnings;

use Test::More;
use Test::MethodFixtures;

note "no args conversion";
ok my $sub = Test::MethodFixtures::_get_key_sub(), "got basic key sub";

my @args = ( 1 .. 5 );

ok my $key = $sub->( { foo => 'bar' }, @args );
is_deeply $key, [ { foo => 'bar' }, @args ], "no transformation";

note "args conversion";
ok $sub
    = Test::MethodFixtures::_get_key_sub(
    sub { ( $_[0], $_[2], $_[1] + 10, undef ) } ),
    "got key sub with transform";

ok $key = $sub->( { foo => 'bar' }, @args );
is_deeply $key, [ { foo => 'bar' }, 1, 3, 12, undef, 5 ], "with transformation";

is_deeply \@args, [ 1 .. 5 ], '@args unchanged';

done_testing;

__END__
sub _get_key_sub {
    my $value = shift;

    return sub {
        my ( $config, @args ) = @_;
        if ($value) {
            my @replace = $value->(@args);
            splice( @args, 0, scalar(@replace), @replace );
        }
        return [ $config, @args ];
    };
}
