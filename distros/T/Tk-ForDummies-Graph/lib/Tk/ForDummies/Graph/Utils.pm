package Tk::ForDummies::Graph::Utils;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 04/06/2010 21:28:09
# AIM       : Private functions and public shared methods
#             between Tk::ForDummies::Graph modules
#==================================================================
use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '1.08';

use Exporter;
use POSIX qw / floor /;

my @ModuleToExport = qw (
  _MaxArray   _MinArray   _isANumber _roundValue
  zoom        zoomx      zoomy       clearchart
  _Quantile   _moy       _NonOutlier _GetControlPoints
  enabled_automatic_redraw           disabled_automatic_redraw
  _delete_array_doublon redraw       add_data
  delete_balloon                     set_balloon
);
my @ModulesDisplay = qw/ display_values /;
our @ISA         = qw(Exporter);
our @EXPORT      = @ModuleToExport;
our @EXPORT_OK   = @ModulesDisplay;
our %EXPORT_TAGS = (
  DUMMIES => \@ModuleToExport,
  DISPLAY => \@ModulesDisplay,
);

sub _delete_array_doublon {
  my ($ref_tab) = @_;

  my %temp;
  return grep { !$temp{$_}++ } @{$ref_tab};
}

sub _MaxArray {
  my ($RefNumber) = @_;
  my $max;

  for my $chiffre ( @{$RefNumber} ) {
    next unless ( defined $chiffre and _isANumber($chiffre) );
    $max = _max( $max, $chiffre );
  }

  return $max;
}

sub _MinArray {
  my ($RefNumber) = @_;
  my $min;

  for my $chiffre ( @{$RefNumber} ) {
    next unless ( defined $chiffre and _isANumber($chiffre) );

    $min = _min( $min, $chiffre );
  }

  return $min;
}

sub _max {
  my ( $a, $b ) = @_;
  if ( not defined $a ) { return $b; }
  if ( not defined $b ) { return $a; }
  if ( not defined $a and not defined $b ) { return; }

  if   ( $a >= $b ) { return $a; }
  else              { return $b; }

  return;
}

sub _min {
  my ( $a, $b ) = @_;
  if ( not defined $a ) { return $b; }
  if ( not defined $b ) { return $a; }
  if ( not defined $a and not defined $b ) { return; }

  if   ( $a <= $b ) { return $a; }
  else              { return $b; }

  return;
}

sub _moy {
  my ($RefValues) = @_;

  my $TotalValues = scalar( @{$RefValues} );

  return if ( $TotalValues == 0 );

  my $moy = 0;
  for my $value ( @{$RefValues} ) {
    $moy += $value;
  }

  $moy = ( $moy / $TotalValues );

  return $moy;
}

sub _isPair {
  my ($number) = @_;

  unless ( defined $number and $number =~ m{^\d+$} ) {
    croak "$number not an integer\n";
  }

  if ( $number % 2 == 0 ) {
    return 1;
  }

  return;
}

sub _Median {
  my ($RefValues) = @_;

  # sort data
  my @values = sort { $a <=> $b } @{$RefValues};
  my $TotalValues = scalar(@values);
  my $median;

  # Number of data pair
  if ( _isPair($TotalValues) ) {

    # 2 values for center
    my $Value1 = $values[ $TotalValues / 2 ];
    my $Value2 = $values[ ( $TotalValues - 2 ) / 2 ];
    $median = ( $Value1 + $Value2 ) / 2;
  }

  # Number of data impair
  else {
    $median = $values[ ( $TotalValues - 1 ) / 2 ];
  }

  return $median;
}

# The Quantile is calculated as the same excel algorithm and
# is equivalent to quantile type 7 in R quantile package.
sub _Quantile {
  my ( $RefData, $QuantileNumber ) = @_;

  my @Values = sort { $a <=> $b } @{$RefData};
  $QuantileNumber = 1 unless ( defined $QuantileNumber );

  return $Values[0] if ( $QuantileNumber == 0 );

  my $count = scalar @{$RefData};

  return $Values[ $count - 1 ] if ( $QuantileNumber == 4 );

  my $K_quantile = ( ( $QuantileNumber / 4 ) * ( $count - 1 ) + 1 );
  my $F_quantile = $K_quantile - POSIX::floor($K_quantile);
  $K_quantile = POSIX::floor($K_quantile);

  # interpolation
  my $aK_quantile     = $Values[ $K_quantile - 1 ];
  my $aKPlus_quantile = $Values[$K_quantile];

  # Calcul quantile
  my $quantile = $aK_quantile + ( $F_quantile * ( $aKPlus_quantile - $aK_quantile ) );

  return $quantile;
}

sub _NonOutlier {
  my ( $RefValues, $Q1, $Q3 ) = @_;

  # interquartile range,
  my $IQR = $Q3 - $Q1;

  # low and up boundaries
  my $LowBoundary = $Q1 - ( 1.5 * $IQR );
  my $UpBoundary  = $Q3 + ( 1.5 * $IQR );

  # largest non-outlier and smallest non-outlier
  my ( $LnonOutlier, $SnonOutlier );
  for my $Value ( sort { $a <=> $b } @{$RefValues} ) {
    if ( $Value > $LowBoundary ) {
      $SnonOutlier = $Value;
      last;
    }
  }

  for my $Value ( sort { $b <=> $a } @{$RefValues} ) {
    if ( $Value < $UpBoundary ) {
      $LnonOutlier = $Value;
      last;
    }
  }

  return ( $SnonOutlier, $LnonOutlier );
}

sub _roundValue {
  my ($Value) = @_;
  return sprintf( "%.2g", $Value );
}

# Test if value is a real number
sub _isANumber {
  my ($Value) = @_;

  if ( $Value
    =~ /^(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$/
    )
  {
    return 1;
  }

  return;
}

sub _GetControlPoints {
  my ( $CompositeWidget, $RefArray ) = @_;

  my $NbrElt = scalar @{$RefArray};

  unless ( $NbrElt > 4 ) {
    return $RefArray;
  }

  # First element
  my @AllControlPoints = ( $RefArray->[0], $RefArray->[1] );

  for ( my $i = 0; $i <= $NbrElt; $i = $i + 2 ) {
    my @PointA = ( $RefArray->[$i], $RefArray->[ $i + 1 ] );
    my @PointB = ( $RefArray->[ $i + 2 ], $RefArray->[ $i + 3 ] );
    my @PointC = ( $RefArray->[ $i + 4 ], $RefArray->[ $i + 5 ] );

    last unless ( defined $RefArray->[ $i + 5 ] );

    # Equation between PointA and PointC
    # Coef = (yc -ya) / (xc -xa)
    # D1 : Y = Coef * X + (ya - (Coef * xa))
    my $coef = ( $PointC[1] - $PointA[1] ) / ( $PointC[0] - $PointA[0] );

    # Equation for D2 ligne paralelle to [AC] with PointB
    # D2 : Y = (Coef * X) + yb - (coef * xb)
    # The 2 control points
    my $D2line = sub {
      my ($x) = @_;

      my $y = ( $coef * $x ) + $PointB[1] - ( $coef * $PointB[0] );
      return $y;
    };

    # distance
    my $distance = 0.95;

    # xc1 = ( (xb - xa ) / 2 ) + xa
    # yc1 = via D2
    my @ControlPoint1;
    $ControlPoint1[0] = ( $distance * ( $PointB[0] - $PointA[0] ) ) + $PointA[0];
    $ControlPoint1[1] = $D2line->( $ControlPoint1[0] );
    push( @AllControlPoints, ( $ControlPoint1[0], $ControlPoint1[1] ) );

    # points
    push( @AllControlPoints, ( $PointB[0], $PointB[1] ) );

    # xc2 = ( (xc - xb ) / 2 ) + xb
    # yc2 = via D2
    my @ControlPoint2;
    $ControlPoint2[0] = ( ( 1 - $distance ) * ( $PointC[0] - $PointB[0] ) ) + $PointB[0];
    $ControlPoint2[1] = $D2line->( $ControlPoint2[0] );

    push( @AllControlPoints, ( $ControlPoint2[0], $ControlPoint2[1] ) );
  }

  push( @AllControlPoints, $RefArray->[ $NbrElt - 2 ], $RefArray->[ $NbrElt - 1 ] );

  return \@AllControlPoints;
}

sub redraw {
  my ($CompositeWidget) = @_;

  $CompositeWidget->_GraphForDummiesConstruction;
  return;
}

sub delete_balloon {
  my ($CompositeWidget) = @_;

  $CompositeWidget->{RefInfoDummies}->{Balloon}{State} = 0;
  $CompositeWidget->_Balloon();

  return;
}

sub add_data {
  my ( $CompositeWidget, $Refdata, $legend ) = @_;

  # Doesn't work for Pie graph
  if ( $CompositeWidget->class eq 'Pie' ) {
    $CompositeWidget->_error("This method 'add_data' not allowed for Tk::ForDummies::Graph::Pie\n");
    return;
  }

  push( @{ $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} }, $Refdata );
  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLegend} > 0 ) {
    push @{ $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend} }, $legend;
  }

  $CompositeWidget->plot( $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} );

  return;
}

sub set_balloon {
  my ( $CompositeWidget, %options ) = @_;

  $CompositeWidget->{RefInfoDummies}->{Balloon}{State} = 1;

  if ( defined $options{-colordatamouse} ) {
    if ( scalar @{ $options{-colordatamouse} } < 2 ) {
      $CompositeWidget->_error(
        "Can't set -colordatamouse, you have to set 2 colors\n" . "Ex : -colordatamouse => ['red','green'],",
        1
      );
    }
    else {
      $CompositeWidget->{RefInfoDummies}->{Balloon}{ColorData} = $options{-colordatamouse};
    }
  }
  if ( defined $options{-morepixelselected} ) {
    $CompositeWidget->{RefInfoDummies}->{Balloon}{MorePixelSelected} = $options{-morepixelselected};
  }
  if ( defined $options{-background} ) {
    $CompositeWidget->{RefInfoDummies}->{Balloon}{Background} = $options{-background};
  }

  $CompositeWidget->_Balloon();

  return;
}

sub zoom {
  my ( $CompositeWidget, $Zoom ) = @_;

  my ( $NewWidth, $NewHeight ) = $CompositeWidget->_ZoomCalcul( $Zoom, $Zoom );
  $CompositeWidget->configure( -width => $NewWidth, -height => $NewHeight );
  $CompositeWidget->toplevel->geometry('');

  return 1;
}

sub zoomx {
  my ( $CompositeWidget, $Zoom ) = @_;

  my ( $NewWidth, $NewHeight ) = $CompositeWidget->_ZoomCalcul( $Zoom, undef );
  $CompositeWidget->configure( -width => $NewWidth );
  $CompositeWidget->toplevel->geometry('');

  return 1;
}

sub zoomy {
  my ( $CompositeWidget, $Zoom ) = @_;

  my ( $NewWidth, $NewHeight ) = $CompositeWidget->_ZoomCalcul( undef, $Zoom );
  $CompositeWidget->configure( -height => $NewHeight );
  $CompositeWidget->toplevel->geometry('');

  return 1;
}

# Clear the Canvas Widget
sub clearchart {
  my ($CompositeWidget) = @_;

  $CompositeWidget->update;
  $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph} );

  return;
}

sub display_values {
  my ( $CompositeWidget, $ref_data, %options ) = @_;

  # Doesn't work for Pie graph
  if ( $CompositeWidget->class eq 'Pie' ) {
    $CompositeWidget->_error("This method 'display_values' not allowed for Tk::ForDummies::Graph::Pie\n");
    return;
  }
  elsif ( $CompositeWidget->class eq 'Bars' ) {
    $CompositeWidget->_error("This method 'display_values' not allowed for Tk::ForDummies::Graph::Bars\n");
    return;
  }

  unless ( defined $ref_data and ref($ref_data) eq 'ARRAY' ) {
    $CompositeWidget->_error( 'data not defined', 1 );
    return;
  }
  $CompositeWidget->{RefInfoDummies}->{Data}{RefDataToDisplay}       = $ref_data;
  $CompositeWidget->{RefInfoDummies}->{Data}{RefOptionDataToDisplay} = \%options;

  if ( $CompositeWidget->class eq 'Areas' ) {
    foreach my $ref_value ( @{$ref_data} ) {
      unshift @{$ref_value}, undef;
    }
  }

  if ( defined $CompositeWidget->{RefInfoDummies}->{Data}{PlotDefined} ) {
    $CompositeWidget->redraw;
  }

  return;
}

sub enabled_automatic_redraw {
  my ($CompositeWidget) = @_;
  
  my $class = $CompositeWidget->class;
  foreach my $key ( qw{ Down End Home Left Next Prior Right Up } ) {
    $CompositeWidget->Tk::bind("Tk::ForDummies::Graph::$class", "<Key-$key>",         undef);
    $CompositeWidget->Tk::bind("Tk::ForDummies::Graph::$class", "<Control-Key-$key>", undef);
  }
  # recreate graph after widget resize
  $CompositeWidget->Tk::bind( '<Configure>' => sub { $CompositeWidget->_GraphForDummiesConstruction; } );
  return;
}

sub disabled_automatic_redraw {
  my ($CompositeWidget) = @_;

  my $class = $CompositeWidget->class;
  foreach my $key ( qw{ Down End Home Left Next Prior Right Up } ) {
    $CompositeWidget->Tk::bind("Tk::ForDummies::Graph::$class", "<Key-$key>",         undef);
    $CompositeWidget->Tk::bind("Tk::ForDummies::Graph::$class", "<Control-Key-$key>", undef);
  }
  # recreate graph after widget resize
  $CompositeWidget->Tk::bind( '<Configure>' => undef );
  return;
}

1;
