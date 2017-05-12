#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Tk;
use Tk::GridColumns;

my $mw = tkinit( -title => 'Tk::GridColumns example -- Editable' );

my $gc = $mw->GridColumns(
    -data => \my @data, # ease the data access
    -columns => \my @columns,
    -item_bindings => { '<Double-ButtonPress-1>' => \&edit_item },
)->pack(
    -fill => 'both',
    -expand => 1,
);

@columns = (
    {
        -text => 'Number',
        -command => $gc->sort_cmd( 0, 'num' ),
    },
    {
        -text => 'String',
        -command => $gc->sort_cmd( 1, 'abc' ),
        -weight => 1,
    },
);

@data = map { [ $_, chr 97 + rand $_*2 ] } 1 .. 10;

$gc->refresh;

MainLoop;

sub edit_item {
    my( $self, $w, $row, $col ) = @_;
    
    $w->destroy; # destroy the widget that currently displays the data
    
    my $entry = $self->Entry(
        -textvariable => \$data[$row][$col],
        -width => 0,
    )->grid(
        -row => $row+1,
        -column => $col,
        -sticky => 'nsew',
    );
    
    $entry->selectionRange( 0, 'end' );
    $entry->focus; # so the user can instantly start editing

    $entry->bind( '<Return>' => sub { $self->refresh_items } );
    $entry->bind( '<FocusOut>' => sub { $self->refresh_items } );
} # edit_item

__END__

