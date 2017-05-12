#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
This is an example of what needs to be done to override
the base HASH instance type with an ARRAY ref instead.

=cut

{
    package Point;
    use strict;
    use warnings;

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') };
    our %HAS; BEGIN {
        %HAS = (
            x => sub { 0 },
            y => sub { 0 },
        );
    };

    sub REPR { return [] }
    sub CREATE {
        my ($class, $proto) = @_;
        my %slots = $class->SLOTS;
        my $self  = $class->REPR;
        @$self    = map $proto->{$_} || $slots{$_}->(), sort keys %slots;
        return $self;
    }

}

{
    my $p = Point->new( x => 10 );
    isa_ok($p, 'Point');
    isa_ok($p, 'UNIVERSAL::Object');

    is_deeply(
        [ @$p ],
        [ 10, 0 ],
        '... the expected instance has the expected value'
    );
}

