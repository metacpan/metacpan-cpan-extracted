#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Tk;
use Tk::GridColumns;

my $mw = tkinit( -title => 'Tk::GridColumns example -- Appearance' );

my $gc = $mw->GridColumns(
    -data => [ map { [ $_, chr 97 + rand $_*2 ] } 1 .. 10 ],
    -columns => \my @columns,
    -bg => 'black',
    -colattr => {
        -fg => 'green', -bg => 'black',
        -activeforeground => 'green',
        -activebackground => 'black',
    },
    -itemattr => { -fg => 'green', -bg => 'black' },
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

$gc->refresh;

MainLoop;

__END__

