# VTree -- Tix Virtual base class needed to implement the Tree widget.
#
# This should not be used directly by the application programmer.
#
# Derived from VTree.tcl in Tix 4.1
# Thanks to rsi@earthling.net for VStack.pm
#
# Chris Dean <ctdean@cogit.com> 

package Tk::VTree;

require 5.004;

use Tk::Derived;
use Tk::HList;

use strict;
use vars qw( @ISA $VERSION );
@ISA = qw( Tk::Derived Tk::HList );
$VERSION = '0.02';

BEGIN { 
    die "Patched version of HList.pm required" 
        unless( $Tk::HList::VERSION =~ /ctd/ || $Tk::HList::VERSION > 2.013 );
}

sub Populate {
    my( $w, $args ) = @_;

    $args->{-indicatorcmd} ||= sub { $w->IndicatorCmd( @_ ) };
    $w->SUPER::Populate( $args );
        
    $w->ConfigSpecs(
        -ignoreinvoke => ["PASSIVE",  "ignoreInvoke", "IgnoreInvoke", 0],
        -opencmd      => ["CALLBACK", "openCmd",      "OpenCmd",
                          sub { $w->OpenCmd( @_ ) } ],
        -closecmd     => ["CALLBACK", "closeCmd",     "CloseCmd", 
                          sub { $w->CloseCmd( @_ ) } ] );
}

sub IndicatorCmd {
    my( $w, $ent ) = @_;

    my $event = $w->tixEventType;
    my $mode = $w->GetMode( $ent );

    if( $event eq "<Arm>" ) {
        if( $mode eq "open" ) {
            $w->_indicator_image( $ent, "plusarm" );
        } else {
            $w->_indicator_image( $ent, "minusarm" );
        }
    } elsif( $event eq "<Disarm>" ) {
        if( $mode eq "open" ) {
            $w->_indicator_image( $ent, "plus" );
        } else {
            $w->_indicator_image( $ent, "minus" );
        }
    } elsif( $event eq "<Activate>" ) {
        $w->Activate( $ent, $mode );
        $w->Callback( -browsecmd => $ent );
    }
}

sub GetMode {
    my( $w, $ent ) = @_;

    return( "none" ) unless $w->indicatorExists( $ent );

    my $img = $w->_indicator_image( $ent );
    return( "open" ) if( $img eq "plus" || $img eq "plusarm" );
    return( "close" );
}

sub Activate {
    my( $w, $ent, $mode ) = @_;

    if( $mode eq "open" ) {
        $w->Callback( -opencmd => $ent );
        $w->_indicator_image( $ent, "minus" );
    } else {
        $w->Callback( -closecmd => $ent );
        $w->_indicator_image( $ent, "plus" );
    }
}

sub SetMode {
    my( $w, $ent, $mode ) = @_;

    if( $mode eq "open" ) {
        $w->indicatorCreate( $ent, qw/-itemtype image/ );
        $w->_indicator_image( $ent, "plus" );
    } elsif( $mode eq "close" ) {
        $w->indicatorCreate( $ent, qw/-itemtype image/ );
        $w->_indicator_image( $ent, "minus" );
    } elsif( $mode eq "none" ) {
        if( $w->indicatorExists( $ent ) ) {
            $w->indicatorDelete( $ent );
            delete $w->privateData()->{$ent};
        }
    }
}

sub OpenCmd {
    my( $w, $ent ) = @_;

    # The default action
    foreach my $kid ($w->infoChildren( $ent )) {
        $w->show( -entry => $kid );
    }
}

sub CloseCmd {
    my( $w, $ent ) = @_;

    # The default action
    foreach my $kid ($w->infoChildren( $ent )) {
        $w->hide( -entry => $kid );
    }
}

sub Command {
    my( $w, $ent ) = @_;

    return if $w->{Configure}{-ignoreInvoke};

    $w->Activate( $ent, $w->GetMode( $ent ) ) if $w->indicatorExists( $ent );
}

sub _indicator_image {
    my( $w, $ent, $image ) = @_;
    my $data = $w->privateData();
    if( defined $image ) {
        $data->{$ent} = $image;
        $w->indicatorConfigure( $ent, -image => $w->tixGetimage( $image ) );
    }
    return( $data->{$ent} );
}


1;
