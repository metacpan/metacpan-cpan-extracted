use 5.008001;
use strict;
use warnings;

package MyFailures;

use custom::failures qw/io::file/;

use Class::Tiny {
    did_build => 0,
    when      => sub { time },
};

sub message {
    my ( $self, $msg ) = @_;
    my $when = sprintf( "(%s)", $self->when );
    return $self->SUPER::message( length($msg) ? "$when $msg" : $when );
}

sub throw {
    my ( $self, $msg ) = @_;
    $self->SUPER::throw( { msg => $msg, payload => "Hello Payload" } );
}

sub BUILD {
    my ($self) = @_;
    $self->did_build(1);
}

package main;

use custom::failures 'Other::Failure' => [qw/io::file/];

1;
