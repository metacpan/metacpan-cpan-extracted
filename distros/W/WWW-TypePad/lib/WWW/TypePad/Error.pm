package WWW::TypePad::Error;
use strict;

use Any::Moose;

sub throw {
    my( $class, @rest ) = @_;
    die $class->new( @rest );
}

package WWW::TypePad::Error::HTTP;
use Any::Moose;
use HTTP::Status;
extends 'WWW::TypePad::Error';

use overload q("") => sub { sprintf "%s (%d)", $_[0]->message, $_[0]->code }, fallback => 1;
has code => ( is => 'rw', isa => 'Int' );
has message => ( is => 'rw', isa => 'Str' );

around BUILDARGS => sub {
    my $orig = shift;
    my( $class, $code, $msg ) = @_;
    $msg ||= HTTP::Status::status_message( $code );
    $class->$orig( code => $code, message => $msg );
};

package WWW::TypePad::Error;

1;