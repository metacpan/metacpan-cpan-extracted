# -*- cperl -*-
use strict;
use warnings FATAL => qw(all);

use Tk;
use ExtUtils::testlib;
use Tk::ObjEditorDialog;
use Tk::ROText;
use Data::Dumper;

use Test::More tests => 4;

my $trace = shift || 0;

package Toto;

sub new {
    my $type    = shift;
    my $tkstuff = shift;
    my $scalar  = 'dummy scalar ref value';
    my $self    = {
        'key1'  => 'value1',
        'array' => [ qw/a b sdf/, { 'v1' => '1', 'v2' => 2 }, 'dfg' ],
        'key2'  => {
            'sub key1' => 'sv1',
            'sub key2' => 'sv2'
        },
        'piped|key'      => { a => 1, b => 2 },
        'scalar_ref_ref' => \\$scalar,
        'empty string'   => '',
        'pseudo hash'      => [ { a => 1, b => 2 }, 'a value', 'bvalue' ],
        'non_empty string' => ' ',
        'long'             => 'very long line' . '.' x 80,
        'is undef'         => undef,
        'some text'        => "some \n dummy\n Text\n",
    };
    bless $self, $type;
}

package main;

ok( 1, "compiled" );

my $toto;
my $mw = eval { MainWindow->new };

SKIP: {
    skip "Cannot open Tk", 3 unless defined $mw;

    my $dummy = new Toto();

    ok( $dummy, "created dummy object" );

    $mw->Label( -text => "Here's the data that will be edited" )->pack;

    my $text = $mw->Scrolled('ROText');
    $text->pack;
    $text->insert( 'end', Dumper($dummy) );

    $mw->Label( -text => "use right button to get editor menu" )->pack;
    my $fm = $mw->Frame;
    $fm->pack;
    $fm->Label( -text => 'Monitoring hash->{key1} value:' )->pack(qw/-side left/);
    my $mon =
        $fm->Label( -textvariable => \$dummy->{key1} )->pack(qw/-side left/);

    ok( 1, "Created some data monitors" );

    my $direct = sub {
        print "Creating obj editor (direct edition)\n" if $trace;
        my $box = $mw->ObjEditorDialog( '-caller' => $dummy, -direct => 1 );

        $box->Show;
        $text->delete( '1.0', 'end' );
        $text->insert( 'end', Dumper($dummy) );
    };

    my $cloned = sub {
        print "Creating obj editor (not direct edition)\n" if $trace;
        my $box = $mw->ObjEditorDialog( '-caller' => $dummy );
        my $new = $box->Show;
        $text->delete( '1.0', 'end' );
        $text->insert( 'end', Dumper($new) );
    };

    my $bf = $mw->Frame->pack;

    ### TBD edit direct and indirect ????

    $bf->Button( -text => 'direct edit', -command => $direct )->pack( -side => 'right' );
    $bf->Button( -text => 'edit',        -command => $cloned )->pack( -side => 'right' );
    $bf->Button( -text => 'quit', -command => sub { $mw->destroy; } )->pack( -side => 'left' );

    if ($trace) {
        MainLoop;    # Tk's
    }
    else {
        $mw->idletasks;
        $mw->after(1000);    # sleep 300ms
    }

    ok( 1, "mainloop done" );

}
