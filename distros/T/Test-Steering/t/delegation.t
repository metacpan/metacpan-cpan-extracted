use strict;
use warnings;
use Test::More;

BEGIN {

    package Fake::Wheel;

    our @call_log = ();
    our $AUTOLOAD;

    sub new { bless {}, shift }
    sub option_names { return }

    sub AUTOLOAD {
        my $self = shift;

        my $name = $AUTOLOAD;
        $name =~ s/.*://;    # strip fully-qualified portion

        push @call_log, [ $name, @_ ];
        return $name x 2;
    }

    # Pretend we were loaded.
    $INC{'Fake::Wheel'} = $0;
}

package main;

use Test::Steering wheel => 'Fake::Wheel';

plan tests => @Test::Steering::EXPORT * 1 + 1;

for my $method ( @Test::Steering::EXPORT ) {
    my $sig = uc $method;
    my $got = eval "$method('$sig')";
    is $got, $method x 2, "called $method OK";
}

my @want_log = map { [ $_, uc $_ ] } @Test::Steering::EXPORT;
is_deeply \@Fake::Wheel::call_log, \@want_log, "Calls match";
