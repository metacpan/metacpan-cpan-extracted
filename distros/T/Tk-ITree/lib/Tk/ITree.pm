package Tk::ITree;
# Tree -- TixTree widget
#
# Derived from Tree.tcl in Tix 4.1
#
# Chris Dean <ctdean@cogit.com>
# Changes: Renee Baecker <module@renee-baecker.de>

=head1 NAME

Tk::ITree - Shamelessly copied Tk::Tree widget

=cut

use vars qw($VERSION);
$VERSION = '0.01';

use Tk ();
use Tk::Derived;
use Tk::HList;
use base  qw(Tk::Derived Tk::HList);
use strict;

Construct Tk::Widget 'ITree';

sub Tk::Widget::ScrlTree { shift->Scrolled('ITree' => @_) }

my $minusimg = '#define indicatorclose_width 11
#define indicatorclose_height 11
static unsigned char indicatorclose_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xfd, 0x05,
   0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

my $plusimg = '#define indicatoropen_width 11
#define indicatoropen_height 11
static unsigned char indicatoropen_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0xfd, 0x05,
   0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

=head1 SYNOPSIS

 require Tk::ITree;
 my $tree= $window->ITree(@options)->pack;

=head1 DESCRIPTION

B<Tk::ITree> is a an almost exact copy of L<Tk::Tree>. This one performs
a bit better under a dark desktop theme.

The reason for copying instead of inheriting is that just the method i
needed to change is a hidden one.

All cudos go to the original authors.

You can use all config options and methods of the Tree widget.

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-indicatorminusimg>

Set or get the I<plus> indicator image. By default it is set
to a Bitmap of I<indicatorminus.xbm> included in this distribution.

=item Switch: B<-indicatorminusimg>

Set or get the I<plus> indicator image. By default it is set
to a Bitmap of I<indicatorminus.xbm> included in this distribution.

=back

=cut

sub Populate
{
 my( $w, $args ) = @_;

 $w->SUPER::Populate( $args );

 my $l = $w->Label;
 my $fg = $l->cget('-foreground');
 $l->destroy;
 $w->ConfigSpecs(
	-indicatorminusimg => ['PASSIVE', undef, undef, $w->Bitmap(
		-data => $minusimg,
		-foreground => $fg,
	)],
	-indicatorplusimg => ['PASSIVE', undef, undef, $w->Bitmap(
		-data => $plusimg,
		-foreground => $fg,
	)],
        -ignoreinvoke => ['PASSIVE',  'ignoreInvoke', 'IgnoreInvoke', 0],
        -opencmd      => ['CALLBACK', 'openCmd',      'OpenCmd', 'OpenCmd' ],
        -indicatorcmd => ['CALLBACK', 'indicatorCmd', 'IndicatorCmd', 'IndicatorCmd'],
        -closecmd     => ['CALLBACK', 'closeCmd',     'CloseCmd', 'CloseCmd'],
        -indicator    => ['SELF', 'indicator', 'Indicator', 1],
        -indent       => ['SELF', 'indent', 'Indent', 20],
        -width        => ['SELF', 'width', 'Width', 20],
        -itemtype     => ['SELF', 'itemtype', 'Itemtype', 'imagetext'],
	-foreground   => ['SELF'],
       );
}

sub autosetmode
{
 my( $w ) = @_;
 $w->setmode();
}

sub add_pathimage
{
 my ($w,$path,$imgopen,$imgclose) = @_;
 $imgopen  ||= "minusarm";
 $imgclose ||= "plusarm";
  
 my $separator = $w->cget(-separator);
  
 $path =~ s/([\.?()|])/\\$1/g;
 $path =~ s/\$/\\\$/g;
 $path =~ s/\\\$$/\$/;
 $path =~ s/\*/[^$separator]+/g;
  
 push(@{$w->{Images}},[$path,$imgopen,$imgclose]);
}

sub child_entries
{
 my ($w,$path,$depth) = @_;
  
 my $level =  1;
 $depth  ||=  1;
 $path   ||= '';
  
 my @children = $w->_get_childinfos($depth,$level,$path);
  
 return wantarray ? @children : scalar(@children);
}

sub _get_childinfos
{
 my ($w,$maxdepth,$level,$path) = @_;
 my @children = $w->infoChildren($path);
 my @tmp;
  
 if($level < $maxdepth)
  {
   for my $child(@children)
    {
     push(@tmp,$w->_get_childinfos($maxdepth,$level +1,$child));
    }
  }
  
 push(@children,@tmp);
  
 return @children;
}

sub IndicatorCmd
{
 my( $w, $ent, $event ) = @_;

 my $mode = $w->getmode( $ent );

 if ( $event eq '<Arm>' )
  {
   if ($mode eq 'open' )
    {
     #$w->_indicator_image( $ent, 'plusarm' );
     $w->_open($ent);
    }
   else
    {
     #$w->_indicator_image( $ent, 'minusarm' );
     $w->_close($ent);
    }
  }
 elsif ( $event eq '<Disarm>' )
  {
   if ($mode eq 'open' )
    {
     #$w->_indicator_image( $ent, 'plus' );
     $w->_open($ent);
    }
   else
    {
     #$w->_indicator_image( $ent, 'minus' );
     $w->_close($ent);
    }
  }
 elsif( $event eq '<Activate>' )
  {
   $w->Activate( $ent, $mode );
   $w->Callback( -browsecmd => $ent );
  }
}

sub close
{
 my( $w, $ent ) = @_;
 my $mode = $w->getmode( $ent );
 $w->Activate( $ent, $mode ) if( $mode eq 'close' );
}

sub open
{
 my( $w, $ent ) = @_;
 my $mode = $w->getmode( $ent );
 $w->Activate( $ent, $mode ) if( $mode eq 'open' );
}

sub getmode
{
 my( $w, $ent ) = @_;

 return( 'none' ) unless $w->indicatorExists( $ent );

 my $img = $w->_indicator_image( $ent );
 if ($img eq "plus" || $img eq "plusarm" || grep{$img eq $_->[2]}@{$w->{Images}})
  {
   return( 'open' );
  }
 return( 'close' );
}

sub setmode
{
 my ($w,$ent,$mode) = @_;
 unless (defined $mode)
  {
   $mode = 'none';
   my @args;
   push(@args,$ent) if defined $ent;
   my @children = $w->infoChildren( @args );
   if ( @children )
    {
     $mode = 'close';
     foreach my $c (@children)
      {
       $mode = 'open' if $w->infoHidden( $c );
       $w->setmode( $c );
      }
    }
  }

 if (defined $ent)
  {
   if ( $mode eq 'open' )
    {
     #$w->_indicator_image( $ent, 'plus' );
     $w->_open($ent);
    }
   elsif ( $mode eq 'close' )
    {
     #$w->_indicator_image( $ent, 'minus' );
     $w->_close($ent);
    }
   elsif( $mode eq 'none' )
    {
     $w->_indicator_image( $ent, undef );
    }
  }
}

sub _open
{
 my ($w,$ent) = @_;
 $w->_indicator_image( $ent, "plus" );
 for my $entry (@{$w->{Images}})
  {
   if($ent =~ $entry->[0])
    {
     $w->_indicator_image( $ent, $entry->[2] );
    }
  }
}

sub _close
{
 my ($w,$ent) = @_;
 $w->_indicator_image( $ent, "minus" );
 for my $entry (@{$w->{Images}})
  {
   if($ent =~ $entry->[0])
    {
     $w->_indicator_image( $ent, $entry->[1] );
    }
  }
}

sub Activate
{
 my( $w, $ent, $mode ) = @_;
 if ( $mode eq 'open' )
  {
   $w->Callback( -opencmd => $ent );
   #$w->_indicator_image( $ent, 'minus' );
   $w->_close($ent);
  }
 elsif ( $mode eq 'close' )
  {
   $w->Callback( -closecmd => $ent );
   #$w->_indicator_image( $ent, 'plus' );
   $w->_open($ent);
  }
 else
  {

  }
}

sub OpenCmd
{
 my( $w, $ent ) = @_;
 # The default action
 foreach my $kid ($w->infoChildren( $ent ))
  {
   $w->show( -entry => $kid );
  }
}

sub CloseCmd
{
 my( $w, $ent ) = @_;

 # The default action
 foreach my $kid ($w->infoChildren( $ent ))
  {
   $w->hide( -entry => $kid );
  }
}

sub Command
{
 my( $w, $ent ) = @_;

 return if $w->{Configure}{-ignoreInvoke};

 $w->Activate( $ent, $w->getmode( $ent ) ) if $w->indicatorExists( $ent );
}

sub _indicator_image
{
 my( $w, $ent, $image ) = @_;
 my $data = $w->privateData();
 if (@_ > 2)
  {
   if (defined $image)
    {
     $w->indicatorCreate( $ent, -itemtype => 'image' )
         unless $w->indicatorExists($ent);
     $data->{$ent} = $image;
		my $bmp;
		if ($image eq 'minus') {
			$bmp = $w->cget('-indicatorminusimg');
		} elsif ($image eq 'plus') {
			$bmp = $w->cget('-indicatorplusimg');
		} else {
			$bmp = $w->$w->Getimage( $image )
		}
      $w->indicatorConfigure( $ent, -image => $bmp  );
    }
   else
    {
     $w->indicatorDelete( $ent ) if $w->indicatorExists( $ent );
     delete $data->{$ent};
    }
  }
 return $data->{$ent};
}

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 LICENSE

Same as perl.

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;

__END__

#  Copyright (c) 1996, Expert Interface Technologies
#  See the file "license.terms" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
#  The file man.macros and some of the macros used by this file are
#  copyrighted: (c) 1990 The Regents of the University of California.
#               (c) 1994-1995 Sun Microsystems, Inc.
#  The license terms of the Tcl/Tk distrobution are in the file
#  license.tcl.

