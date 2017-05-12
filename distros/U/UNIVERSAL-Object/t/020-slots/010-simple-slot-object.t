#!perl

use strict;
use warnings;

use Test::More qw[no_plan];

BEGIN {
    use_ok('UNIVERSAL::Object');
}

=pod

NOTE:
This test is meant to illustrate the possible
types of things that can be stuffed into the
slots in %HAS. Using the CODE de-reference
overload allows us to substitute a blessed
object that behaves like a simple CODE ref.

=cut

{
    package My::Slot;
    use strict;
    use warnings;

    use overload '&{}' => 'to_code';

    sub new {
        my ($class, %args) = @_;
        bless { %args } => $class;
    }

    sub to_code {
        my ($self) = @_;
        sub { $self->{default}->( @_ ) };
    }
}

{
    package Foo;
    use strict;
    use warnings;

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
    our %HAS; BEGIN {
        %HAS = (
            bar => My::Slot->new( default => sub { 'Foo::bar' } )
        )
    };

    sub bar { $_[0]->{bar} }
}


{
    my $foo = eval { Foo->new };
    isa_ok($foo, 'Foo');

    is($foo->bar, 'Foo::bar', '... got the expected value');
}


1;

