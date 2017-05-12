package XML::XSS::DocumentTest;

use strict;
use warnings;

no warnings qw/ uninitialized /;

use base qw/ My::Test::Class /;

use Test::More;

use XML::XSS;

sub pod_synopsis :Tests {
    
    my $xss = XML::XSS->new;

    my $doc_style = $xss->document;

    $doc_style->set_pre( "=pod\n" );
    $doc_style->set_post( "=cut\n" );

    is $xss->render( '<doc>yadah yadah</doc>' ) =>
        "=pod\n<doc>yadah yadah</doc>=cut\n";

}


sub render_ok {
    my ( $self, $expected, $comment ) = @_;

    is $self->{xss}->render( $self->{doc} ), $expected, $comment;
}

sub create_xss : Test(setup) {
    my $self = shift;
    $self->{xss} = XML::XSS->new;
    $self->{doc} = '<doc><foo>bar</foo></doc>';
    $self->{foo} = $self->{xss}->element('foo');
}

1;

