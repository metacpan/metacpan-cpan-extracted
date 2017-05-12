# -*- cperl -*-
use strict;
use warnings FATAL => qw(all);

use Tk;
use ExtUtils::testlib;
use Tk::ObjEditor;
use Tk::ROText;
use Data::Dumper;

use Test::More tests => 5;

my $trace = shift || 0;

package myHash;
use Tie::Hash;
use vars qw/@ISA/;

@ISA = qw/Tie::StdHash/;

sub TIEHASH {
    my $class = shift;
    my %args  = @_;
    return bless { %args, dummy => 'foo' }, $class;
}

sub STORE {
    my ( $self, $idx, $value ) = @_;
    $self->{$idx} = $value;
    return $value;
}

package MyScalar;
use Tie::Scalar;
use vars qw/@ISA/;

@ISA = qw/Tie::StdHash/;

sub TIESCALAR {
    my $class = shift;
    my %args  = @_;
    return bless { %args, dummy => 'foo default value' }, $class;
}

sub STORE {
    my ( $self, $value ) = @_;
    $self->{data} = $value;
    return $value;
}

sub FETCH {
    my ($self) = @_;

    # print "\t\t",'@.....@.....@..... MeScalar read',"\n";
    return $self->{data} || $self->{dummy};
}

package Toto;

sub new {
    my %h;
    tie %h, 'myHash', 'dummy key' => 'dummy value' or die;
    $h{data1} = 'value1';

    my $type    = shift;
    my $tkstuff = shift;
    my $scalar  = 'dummy scalar ref value';
    my $self    = {
        'key1'  => 'example of value for key1',
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
        'tied hash'        => \%h
    };

    tie( $self->{tied_scalar}, 'MyScalar', 'dummy key' => 'dummy value' )
        or die;

    $self->{tied_scalar} = 'some scalar huh?';

    bless $self, $type;
}

package main;

ok( 1, "compiled" );

my $toto;
my $mw = eval { MainWindow->new };

SKIP: {
    skip "Cannot open Tk", 4 unless defined $mw;

    my $w_menu = $mw->Frame( -relief => 'raised', -borderwidth => 2 );
    $w_menu->pack( -fill => 'x' );

    my $f = $w_menu->Menubutton( -text => 'File', -underline => 0 )->pack( -side => 'left' );
    $f->command( -label => 'Quit', -command => sub { $mw->destroy; } );

    my $dummy = new Toto($mw);
    ok( $dummy, "created dummy object" );

    $mw->Label( -text => "use right button to get editor menu" )->pack;
    my $fm = $mw->Frame;
    $fm->pack;
    $fm->Label( -text => 'Monitoring hash->{key1} value:' )->pack(qw/-side left/);
    my $mon =
        $fm->Label( -textvariable => \$dummy->{key1} )->pack(qw/-side left/);
    ok( 1, "Created some data monitors" );

    my $objEd = $mw->ObjEditor(
        '-caller' => $dummy,
        -direct   => 1,

        #destroyable => 0,
        -title => 'test editor'
    )->pack( -expand => 1, -fill => 'both' );

    $mw->idletasks;
    ok( $objEd, "Created obj editor" );

    sub scan {
        my $topName = shift;
        $objEd->yview($topName);

        foreach my $c ( $objEd->infoChildren($topName) ) {
            $objEd->displaySubItem($c);
            scan($c);

            #print $c,"\n";
            last if $c =~ /root\|2/;
        }
        $mw->idletasks;
    }

    sub refresh {
        $mw->idletasks;
        $mw->after(1000);    # sleep 300ms
    }

    if ($trace) {
        MainLoop;            # Tk's
    }
    else {
        scan('root');
        $objEd->displaySubItem('root|1');

        # modify string entry
        my $menu = $objEd->modify_menu('root|1');    # string entry
        refresh;

        # since call to Dialog is blocking, we must pass this sub ref to a
        # timer
        my $sub = sub {
            my $dialog = $objEd->get_current_dialog;
            $dialog->Subwidget('Entry')->insert( 0, 'yada' );
            refresh;
            $dialog->Subwidget('B_OK')->invoke;
        };
        $mw->after( 1000, $sub );

        # Invoked Dialog will block until B_OK is pressed
        $menu->invoke(1);
        refresh;

    }

    ok( 1, "mainloop done" );

}

