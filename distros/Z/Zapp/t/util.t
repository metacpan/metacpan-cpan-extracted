
=head1 DESCRIPTION

This tests the utilitize in the Zapp::Util class.

=cut

use Test::More;
use Zapp::Util qw( ansi_colorize );
use Mojo::DOM;
use Term::ANSIColor;

subtest 'ansi_colorize' => sub {

    subtest '16-color' => sub {
        my $text = color( 'bold blue' ) . 'Hello, ' . color( 'bright_red on_black' ) . 'World' . color( 'reset' );
        my $html = ansi_colorize( $text );
        my $dom = Mojo::DOM->new( $html );
        is $dom->children->size, 2, '2 spans in output';
        like $dom->children->[0]->attr( 'style' ), qr{color: navy}, 'first span color is correct';
        like $dom->children->[0]->attr( 'style' ), qr{font-weight: bold}, 'first span is bold';
        like $dom->children->[1]->attr( 'style' ), qr{color: red}, 'second span color is correct';
        like $dom->children->[1]->attr( 'style' ), qr{font-weight: bold}, 'second span is bold (continuing from first)';
        like $dom->children->[1]->attr( 'style' ), qr{background: black}, 'second span bg is black';
    };

    subtest '256-color' => sub {
        my $text = color( 'ansi128' ) . 'Hello, ' . color( 'underline on_ansi201' ) . 'World' . color( 'reset' );
        my $html = ansi_colorize( $text );
        my $dom = Mojo::DOM->new( $html );
        is $dom->children->size, 2, '2 spans in output';
        like $dom->children->[0]->attr( 'style' ), qr{\Qcolor: rgb(108,0,144)}, 'first span color is correct';
        like $dom->children->[1]->attr( 'style' ), qr{\Qcolor: rgb(108,0,144)}, 'second span color is correct (continuing from first)';
        like $dom->children->[1]->attr( 'style' ), qr{text-decoration: underline}, 'second span is underline';
        like $dom->children->[1]->attr( 'style' ), qr{\Qbackground: rgb(180,0,180)}, 'second span bg is correct';
    };

    subtest 'RGB color' => sub {
        my $text = "\e[38;2;255;0;0mHello, \e[48;2;0;0;128mWorld";
        my $html = ansi_colorize( $text );
        my $dom = Mojo::DOM->new( $html );
        is $dom->children->size, 2, '2 spans in output';
        like $dom->children->[0]->attr( 'style' ), qr{\Qcolor: rgb(255,0,0)}, 'first span color is correct';
        like $dom->children->[1]->attr( 'style' ), qr{\Qcolor: rgb(255,0,0)}, 'second span color is correct (continuing from first)';
        like $dom->children->[1]->attr( 'style' ), qr{\Qbackground: rgb(0,0,128)}, 'second span bg is correct';
    };
};

done_testing;
