package XML::XSS::OverloadTest;

use strict;
use warnings;

no warnings qw/ uninitialized /;

use base qw/ My::Test::Class /;

use Test::More;

use XML::XSS;

sub overload_everybody :Tests {
    my $self = shift;

    my $xss = $self->{xss};

    $xss.'#document'.'pre' *= 'doc';
    $xss.'#comment'.'pre' *= 'comment';
    $xss.'#text'.'pre' *= 'text';
    $xss.'#pi'.'pre' *= 'pi';

    $self->{doc} = '<?foo attr="bar" ?><doc><!-- yadah -->yadah<foo/></doc>';

    $self->render_ok( 'docpi<?foo attr="bar" ?><doc>comment yadah textyadah<foo></foo></doc>' );


}

sub overload_basic :Tests {
    my $self = shift;

    my $xss = $self->{xss};

    isa_ok $xss.'foo' => 'XML::XSS::Element';

    my $foo = $xss.'foo';
    isa_ok $foo => 'XML::XSS::Element';

    isa_ok $xss.'foo'.'pre' => 'XML::XSS::StyleAttribute';
    isa_ok $foo.'pre' => 'XML::XSS::StyleAttribute';

    $xss.'foo'.'pre' *= 'X';

    $self->render_ok( '<doc>X</doc>' );

    $xss.'foo'.'pre' x= '<%= "Y" %>';

    $self->render_ok( '<doc>Y</doc>' );


    $foo->set_pre('X');
    $self->render_ok( '<doc>X</doc>' );

    $xss.'foo'.'pre' *= undef;

    $xss.'foo'.'content' *= '<%= \o/ %>';
    $self->render_ok( '<doc><%= \o/ %></doc>' );

    $xss.'foo'.'content' x= q{<%= '\o/' %>};
    $self->render_ok( '<doc>\o/</doc>' );

    $xss.'foo'.'style' %= {
        pre =>  'A',
        post => 'Z',
        content => undef,
    };

    $self->render_ok( '<doc>AZ</doc>' );

    my $node = $xss.'foo';
    $node %= {
        pre =>  'B',
        post => 'Y',
        content => undef,
    };

    $self->render_ok( '<doc>BY</doc>' );
}


sub render_ok {
    my ( $self, $expected, $comment ) = @_;

    is $self->{xss}->render( $self->{doc} ), $expected, $comment;
}

sub create_xss : Test(setup) {
    my $self = shift;
    $self->{xss} = XML::XSS->new;
    $self->{doc} = '<doc><foo/></doc>';
}

1;

