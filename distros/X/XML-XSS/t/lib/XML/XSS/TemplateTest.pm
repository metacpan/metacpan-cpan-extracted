package XML::XSS::TemplateTest;

use strict;
use warnings;

no warnings qw/ uninitialized /;

use base qw/ My::Test::Class /;

use Test::More;

use XML::XSS;

sub line_count :Tests {
    my $self = shift;

    my( undef, $filename, $line ) = sub { caller }->();
    my $f = xsst q{ <% die "urgh" %> };  $line++;
    eval { $f->() };

    like $@ => qr/$filename line $line/;

    # now with squelching of spaces
    ( undef, $filename, $line ) = sub { caller }->();
    $f = xsst "\n" x 100 . '<-% die "urgh" %>';  $line++;
    $line += 100;

    eval { $f->() };
    
    like $@ => qr/$filename line $line/;

    pass;
}

sub sigil_findvalue :Tests {
    my $self = shift;

    $self->{doc} = '<doc><foo>yadah<bar baz="yay">meh</bar></foo></doc>';

    $self->{xss}->set( 'doc' => { content => 
            xsst q{<%@ foo/bar/@baz %>}
        } );

    $self->render_ok( 'yay' );

    # what about two values?
    $self->{doc} = '<doc><foo>yadah<bar baz="yay">meh</bar><bar baz="w00t"/></foo></doc>';

    $self->render_ok( 'yayw00t' );

}

sub sigil_render :Tests {
    my $self = shift;

    $self->{doc} = '<doc><foo/><bar/><baz/><bar/></doc>';

    $self->{xss}->set( 'doc', {
        content => xsst q{<%~ bar %>},
    }
    );

    $self->render_ok( '<bar></bar><bar></bar>' );

    # doesn't match anything
    $self->{xss}->set( 'doc', {
        content => xsst q{<%~ jabberwocky %>},
    }
    );

    $self->render_ok( '' );


    # bad xpath
    {
    local *STDERR;
    my $error;
    open STDERR, '>', \$error;
    $self->{xss}->set( 'doc', {
        content => xsst q{<%~ foo[name>] %>},
    }
    );
   
    $self->render_ok( '' );

    like $error => qr/XPath error : Invalid expression/;

}


}

sub xsst_basic :Tests {
    my $code = xsst q{Foo!};
    is ref $code => 'XML::XSS::Template', 'produces a sub ref';

    is $code->() => 'Foo!', 'and returns the right stuff';

}


sub simple_string :Tests {
    my $self = shift;

    $self->{foo}->set( 'content' => xsst q{Hello world} ); 

    $self->render_ok( 'Hello world' );
}

sub sigil_equal :Tests {
    my $self = shift;

    my $f = xsst q{X<%= 'Y' %>X};

    is $f->() => 'XYX';
}

sub space_squish :Tests {
    my $self = shift;

    is xsst( q{X <% %> X} )->() => 'X  X';
    is xsst( q{X <% %-> X} )->() => 'X X';
    is xsst( q{X <-% %> X} )->() => 'X X';
    is xsst( q{X <-% %-> X} )->() => 'XX';

    my $s = "\n\t" x 10;
    is xsst( qq{X${s}<-% %->${s}X} )->() => 'XX';
}



sub simple_evaluation :Tests {
    my $self = shift;

    my $f = xsst q{X<% $args->{x} = 'bar' %>X};

    my %args;
    is $f->(undef, undef,\%args ) => 'XX';
    is $args{x} => 'bar';
}



sub render_ok {
    my ( $self, $expected, $comment ) = @_;

    is $self->{xss}->render( $self->{doc} ), $expected, $comment;
}

sub create_xss : Test(setup) {
    my $self = shift;
    $self->{xss} = XML::XSS->new;
    $self->{foo} = $self->{xss}->element('foo');
    $self->{xss}->set( 'doc' => { showtag => 0 } );
    $self->{doc} = '<doc><foo>bar</foo></doc>';
}

1;

