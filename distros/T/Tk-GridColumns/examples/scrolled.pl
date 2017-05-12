#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Tk;
use Tk::GridColumns;

my $mw = tkinit( -title => 'Tk::GridColumns example -- Scrolled' );
$mw->geometry( "=300x200+100+100" );

my $gc = $mw->Scrolled(
    'GridColumns' =>
    -scrollbars => 'ose',
    -data => [ map { [ $_, chr 97 + rand $_+5 ] } 1 .. 20 ],
    -columns => \my @columns,
)->pack(
    -fill => 'both',
    -expand => 1,
)->Subwidget( 'scrolled' ); # do not forget this one ;)

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

