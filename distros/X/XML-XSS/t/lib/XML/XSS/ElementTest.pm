package XML::XSS::ElementTest;

use strict;
use warnings;

use base qw/ My::Test::Class /;

use Test::More;

use XML::XSS;

no warnings qw/ uninitialized /;

sub everything :Tests {
    my $self = shift;

    $self->{doc} = <<'END_DOC';
<doc>
    <foo><bar>yadah</bar><baz>blah</baz></foo>
</doc>
END_DOC

    my $foo = $self->{foo};

    $foo->set(
        process => 1,
        showtag => 1,
        rename => 'rename',
        map { $_ => "[$_]" } qw/ pre post intro extro prechildren postchildren prechild
        postchild /
    );

    $self->render_ok( q{<doc>
    [pre]<rename>[intro][prechildren][prechild]<bar>yadah</bar>[postchild][prechild]<baz>blah</baz>[postchild][postchildren][extro]</rename>[post]
</doc>} );

    $foo->set( 
        content => '[content]',
    );

    $self->render_ok( q{<doc>
    [pre]<rename>[intro][content][extro]</rename>[post]
</doc>} );

}

sub process :Tests {
    my $self  = shift;

    $self->{foo}->set( process => 0 );

    $self->render_ok( '<doc></doc>' );
}

sub pre_and_showtag :Tests {
    my $self = shift;

    $self->{foo}->set( pre => 'X' );

    $self->render_ok( '<doc>Xbar</doc>' );

    $self->{foo}->set( showtag => 1 );

    $self->render_ok( '<doc>X<foo>bar</foo></doc>' );
}

sub prepostchildren :Tests {
    my $self = shift;
    $self->{foo}->set(
        prechildren => 'A',
        postchildren => 'E',
        prechild => 'X',
        postchild => 'Y',
    );

    $self->{doc} = "<doc><foo><bar/><bar/></foo></doc>";
    $self->render_ok( '<doc><foo>AX<bar></bar>YX<bar></bar>YE</foo></doc>' );

    # no children? No nothing
    $self->{doc} = "<doc><foo></foo></doc>";
    $self->render_ok( '<doc><foo></foo></doc>' );
}

sub intro_extro :Tests {
    my $self = shift;
    $self->{foo}->set(
        intro => 'A',
        extro => 'E',
    );

    $self->render_ok( '<doc><foo>AbarE</foo></doc>' );
}

sub set_foo : Tests {
    my $self = shift;
    my $xss  = $self->{xss};
    $xss->set(
        'foo' => {
            pre  => 'PRE',
            post => 'POST',
            showtag => 1,
        } );

    is $xss->element('foo')->pre->value => 'PRE', 'element PRE';

    $self->render_ok("<doc>PRE<foo>bar</foo>POST</doc>");

}

sub show_tag :Tests {
    my $self = shift;

    my $elt = $self->{foo};

    is $elt->showtag->value => undef, 'default is undef';

    $elt->set_showtag(0);

    $self->render_ok( '<doc>bar</doc>' );
}

sub rename :Tests {
    my $self = shift;

    $self->{foo}->set( rename => 'baz' );

    $self->render_ok( '<doc><baz>bar</baz></doc>' );
}

sub in_render_modifs :Tests {
    my $self = shift;

    $self->{foo}->set( showtag => 1, 
        pre => sub { $_[0]->set_post( 
                $_[0]->post + 1
            ); ''; } );

    $self->{doc} = "<doc><foo></foo><foo></foo></doc>";

    $self->render_ok( "<doc><foo></foo>1<foo></foo>1</doc>" );

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

