package XML::XSS::CommentTest;

use strict;
use warnings;

no warnings qw/ uninitialized /;

use base qw/ My::Test::Class /;

use Test::More;

use XML::XSS;

sub basic : Tests {
    my $self = shift;

    $self->{xss}->set_comment(
        process => 1,
        showtag => 1,
        pre     => 'PRE',
        post    => 'POST',
    );

    $self->render_ok('<doc>PRE<!-- foo -->POST</doc>');

}

sub render_ok {
    my ( $self, $expected, $comment ) = @_;

    is $self->{xss}->render( $self->{doc} ), $expected, $comment;
}

sub create_xss : Test(setup) {
    my $self = shift;
    $self->{xss} = XML::XSS->new;
    $self->{doc} = '<doc><!-- foo --></doc>';
}

1;

