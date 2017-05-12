package Tk::Chart::Utils;

#=====================================================================================
# $Author    : Djibril Ousmanou                                                      $
# $Copyright : 2011                                                                  $
# $Update    : 21/10/2011 12:44:13                                                   $
# $AIM       : Private functions and public shared methods between Tk::Chart modules $
#=====================================================================================

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '1.04';

use Exporter;
use POSIX qw / floor /;

my @module_export = qw (
  _maxarray   _minarray   _isanumber _roundvalue
  zoom        zoomx      zoomy       clearchart
  _quantile   _moy       _nonoutlier _get_controlpoints
  enabled_automatic_redraw           disabled_automatic_redraw
  _delete_array_doublon redraw       add_data
  delete_balloon                     set_balloon
  _isainteger                        _set_data_cumulate_percent
);
my @modules_display = qw/ display_values /;

use base qw/ Exporter /;
our @EXPORT      = @module_export;
our @EXPORT_OK   = @modules_display;
our %EXPORT_TAGS = (
  DUMMIES => \@module_export,
  DISPLAY => \@modules_display,
);

my $EMPTY = q{};

sub _delete_array_doublon {
  my ($ref_tab) = @_;

  my %temp;
  return grep { !$temp{$_}++ } @{$ref_tab};
}

sub _maxarray {
  my ($ref_number) = @_;
  my $max;

  for my $chiffre ( @{$ref_number} ) {
    next if ( !_isanumber($chiffre) );
    $max = _max( $max, $chiffre );
  }

  return $max;
}

sub _minarray {
  my ($ref_number) = @_;
  my $min;

  for my $chiffre ( @{$ref_number} ) {
    next if ( !_isanumber($chiffre) );

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
  my ($ref_values) = @_;

  my $total_values = scalar @{$ref_values};

  return if ( $total_values == 0 );

  my $moy = 0;
  for my $value ( @{$ref_values} ) {
    $moy += $value;
  }

  $moy = ( $moy / $total_values );

  return $moy;
}

sub _ispair {
  my ($number) = @_;

  if ( !_isainteger($number) ) {
    croak "$number not an integer\n";
  }

  if ( $number % 2 == 0 ) {
    return 1;
  }

  return;
}

sub _isainteger {
  my ($number) = @_;

  if ( ( defined $number ) and ( $number =~ m{^\d+$} ) ) {
    return 1;
  }

  return;
}

sub _median {
  my ($ref_values) = @_;

  # sort data
  my @values = sort { $a <=> $b } @{$ref_values};
  my $total_values = scalar @values;
  my $median;

  # Number of data pair
  if ( _ispair($total_values) ) {

    # 2 values for center
    my $value1 = $values[ $total_values / 2 ];
    my $value2 = $values[ ( $total_values - 2 ) / 2 ];
    $median = ( $value1 + $value2 ) / 2;
  }

  # Number of data impair
  else {
    $median = $values[ ( $total_values - 1 ) / 2 ];
  }

  return $median;
}

# The Quantile is calculated as the same excel algorithm and
# is equivalent to quantile type 7 in R quantile package.
sub _quantile {
  my ( $ref_data, $quantile_number ) = @_;

  my @values = sort { $a <=> $b } @{$ref_data};
  if ( not defined $quantile_number ) { $quantile_number = 1; }

  if ( $quantile_number == 0 ) { return $values[0]; }

  my $count = scalar @{$ref_data};

  if ( $quantile_number == 4 ) { return $values[ $count - 1 ]; }

  my $k_quantile = ( ( $quantile_number / 4 ) * ( $count - 1 ) + 1 );
  my $f_quantile = $k_quantile - POSIX::floor($k_quantile);
  $k_quantile = POSIX::floor($k_quantile);

  # interpolation
  my $ak_quantile     = $values[ $k_quantile - 1 ];
  my $akplus_quantile = $values[$k_quantile];

  # Calcul quantile
  my $quantile = $ak_quantile + ( $f_quantile * ( $akplus_quantile - $ak_quantile ) );

  return $quantile;
}

sub _nonoutlier {
  my ( $ref_values, $q1, $q3 ) = @_;

  # interquartile range,
  my $iqr = $q3 - $q1;

  # low and up boundaries
  my $low_boundary = $q1 - ( 1.5 * $iqr );
  my $up_boundary  = $q3 + ( 1.5 * $iqr );

  # largest non-outlier and smallest non-outlier
  my ( $l_nonoutlier, $s_nonoutlier );
  for my $value ( sort { $a <=> $b } @{$ref_values} ) {
    if ( $value > $low_boundary ) {
      $s_nonoutlier = $value;
      last;
    }
  }

  for my $value ( reverse sort { $a <=> $b } @{$ref_values} ) {
    if ( $value < $up_boundary ) {
      $l_nonoutlier = $value;
      last;
    }
  }

  return ( $s_nonoutlier, $l_nonoutlier );
}

sub _roundvalue {
  my ($value) = @_;
  if ( $value > 10000 ) {
    return sprintf '%.2e', $value;
  }
  return sprintf '%.5g', $value;
}

# Test if value is a real number
sub _isanumber {
  my ($value) = @_;

  if ( not defined $value ) {
    return;
  }
  if ( $value
    =~ /^(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$/
    )
  {
    return 1;
  }

  return;
}

sub _get_controlpoints {
  my ( $cw, $ref_array ) = @_;

  my $nbrelt = scalar @{$ref_array};

  if ( $nbrelt <= 4 ) {
    return $ref_array;
  }

  # First element
  my @all_controlpoints = ( $ref_array->[0], $ref_array->[1] );

  for ( my $i = 0; $i <= $nbrelt; $i = $i + 2 ) {
    my @point_a = ( $ref_array->[$i], $ref_array->[ $i + 1 ] );
    my @point_b = ( $ref_array->[ $i + 2 ], $ref_array->[ $i + 3 ] );
    my @point_c = ( $ref_array->[ $i + 4 ], $ref_array->[ $i + 5 ] );

    last if ( !$ref_array->[ $i + 5 ] );

    # Equation between pointa and PointC
    # Coef = (yc -ya) / (xc -xa)
    # D1 : Y = Coef * X + (ya - (Coef * xa))
    my $coef = ( $point_c[1] - $point_a[1] ) / ( $point_c[0] - $point_a[0] );

    # Equation for D2 ligne paralelle to [AC] with PointB
    # D2 : Y = (Coef * X) + yb - (coef * xb)
    # The 2 control points
    my $d2line = sub {
      my ($x) = @_;

      my $y = ( $coef * $x ) + $point_b[1] - ( $coef * $point_b[0] );
      return $y;
    };

    # distance
    my $distance = 0.95;

    # xc1 = ( (xb - xa ) / 2 ) + xa
    # yc1 = via D2
    my @control_point1;
    $control_point1[0] = ( $distance * ( $point_b[0] - $point_a[0] ) ) + $point_a[0];
    $control_point1[1] = $d2line->( $control_point1[0] );
    push @all_controlpoints, ( $control_point1[0], $control_point1[1] );

    # points
    push @all_controlpoints, ( $point_b[0], $point_b[1] );

    # xc2 = ( (xc - xb ) / 2 ) + xb
    # yc2 = via D2
    my @control_point2;
    $control_point2[0] = ( ( 1 - $distance ) * ( $point_c[0] - $point_b[0] ) ) + $point_b[0];
    $control_point2[1] = $d2line->( $control_point2[0] );

    push @all_controlpoints, ( $control_point2[0], $control_point2[1] );
  }

  push @all_controlpoints, $ref_array->[ $nbrelt - 2 ], $ref_array->[ $nbrelt - 1 ];

  return \@all_controlpoints;
}

sub _set_data_cumulate_percent {
  my ( $cw, $ref_data ) = @_;

  # x-axis
  my @new_data = ( $ref_data->[0] );

  # Number of data and values in a data
  my $number_values = scalar @{ $ref_data->[0] };
  my $number_data   = scalar @{$ref_data} - 1;
  push @new_data, [] for ( 1 .. $number_data );

  # Change data to set percent data instead values
  for my $index_value ( 0 .. $number_values - 1 ) {
    my $sum = 0;

    # Sum calculate
    for my $index_data ( 1 .. $number_data ) {
      if ( $ref_data->[$index_data][$index_value] ) { $sum += $ref_data->[$index_data][$index_value]; }
    }

    # Change value
    for my $index_data ( 1 .. $number_data ) {
      next if ( ! $ref_data->[$index_data][$index_value] );
      my $new_value = ( $ref_data->[$index_data][$index_value] / $sum ) * 100;
      $new_data[$index_data][$index_value] = sprintf '%.5g', $new_value;
    }
  }

  return \@new_data;
}

sub redraw {
  my ($cw) = @_;

  $cw->_chartconstruction;
  return;
}

sub delete_balloon {
  my ($cw) = @_;

  $cw->{RefChart}->{Balloon}{State} = 0;
  $cw->_balloon();

  return;
}

sub add_data {
  my ( $cw, $ref_data, $legend ) = @_;

  # Doesn't work for Pie graph
  if ( $cw->class eq 'Pie' ) {
    $cw->_error("This method 'add_data' not allowed for Tk::Chart::Pie\n");
    return;
  }

  my $refdata = $cw->{RefChart}->{Data}{RefAllData};

  # Cumulate pourcent => data change
  my $cumulatepercent = $cw->cget( -cumulatepercent );
  if ( defined $cumulatepercent and $cumulatepercent == 1 ) {
    $refdata = $cw->{RefChart}->{Data}{RefAllDataBeforePercent};
  }

  push @{$refdata}, $ref_data;
  if ( $cw->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    push @{ $cw->{RefChart}->{Legend}{DataLegend} }, $legend;
  }

  $cw->plot($refdata);

  return;
}

sub set_balloon {
  my ( $cw, %options ) = @_;

  $cw->{RefChart}->{Balloon}{State} = 1;

  if ( defined $options{-colordatamouse} ) {
    if ( scalar @{ $options{-colordatamouse} } < 2 ) {
      $cw->_error(
        "Can't set -colordatamouse, you have to set 2 colors\nEx : -colordatamouse => ['red','green'],", 1 );
    }
    else {
      $cw->{RefChart}->{Balloon}{ColorData} = $options{-colordatamouse};
    }
  }
  if ( defined $options{-morepixelselected} ) {
    $cw->{RefChart}->{Balloon}{MorePixelSelected} = $options{-morepixelselected};
  }
  if ( defined $options{-background} ) {
    $cw->{RefChart}->{Balloon}{Background} = $options{-background};
  }

  $cw->_balloon();

  return;
}

sub zoom {
  my ( $cw, $zoom ) = @_;

  my ( $new_width, $new_height ) = $cw->_zoomcalcul( $zoom, $zoom );
  $cw->configure( -width => $new_width, -height => $new_height );
  $cw->toplevel->geometry($EMPTY);

  return 1;
}

sub zoomx {
  my ( $cw, $zoom ) = @_;

  my ( $new_width, $new_height ) = $cw->_zoomcalcul( $zoom, undef );
  $cw->configure( -width => $new_width );
  $cw->toplevel->geometry($EMPTY);

  return 1;
}

sub zoomy {
  my ( $cw, $zoom ) = @_;

  my ( $new_width, $new_height ) = $cw->_zoomcalcul( undef, $zoom );
  $cw->configure( -height => $new_height );
  $cw->toplevel->geometry($EMPTY);

  return 1;
}

# Clear the Canvas Widget
sub clearchart {
  my ($cw) = @_;

  $cw->update;
  $cw->delete( $cw->{RefChart}->{TAGS}{AllTagsChart} );

  return;
}

sub display_values {
  my ( $cw, $ref_data, %options ) = @_;

  # Doesn't work for Pie graph
  if ( $cw->class eq 'Pie' ) {
    $cw->_error("This method 'display_values' not allowed for Tk::Chart::Pie\n");
    return;
  }
  elsif ( $cw->class eq 'Bars' ) {
    $cw->_error("This method 'display_values' not allowed for Tk::Chart::Bars\n");
    return;
  }

  if ( !( defined $ref_data and ref $ref_data eq 'ARRAY' ) ) {
    $cw->_error( 'data not defined', 1 );
    return;
  }
  $cw->{RefChart}->{Data}{RefDataToDisplay}       = $ref_data;
  $cw->{RefChart}->{Data}{RefOptionDataToDisplay} = \%options;

  if ( $cw->class eq 'Areas' ) {
    foreach my $ref_value ( @{$ref_data} ) {
      unshift @{$ref_value}, undef;
    }
  }

  if ( defined $cw->{RefChart}->{Data}{PlotDefined} ) {
    $cw->redraw;
  }

  return;
}

sub enabled_automatic_redraw {
  my ($cw) = @_;

  my $class = $cw->class;
  foreach my $key (qw{ Down End Home Left Next Prior Right Up }) {
    $cw->Tk::bind( "Tk::Chart::$class", "<Key-$key>",         undef );
    $cw->Tk::bind( "Tk::Chart::$class", "<Control-Key-$key>", undef );
  }

  # recreate graph after widget resize
  $cw->Tk::bind( '<Configure>' => sub { $cw->_chartconstruction; } );
  return;
}

sub disabled_automatic_redraw {
  my ($cw) = @_;

  my $class = $cw->class;
  foreach my $key (qw{ Down End Home Left Next Prior Right Up }) {
    $cw->Tk::bind( "Tk::Chart::$class", "<Key-$key>",         undef );
    $cw->Tk::bind( "Tk::Chart::$class", "<Control-Key-$key>", undef );
  }

  # recreate graph after widget resize
  $cw->Tk::bind( '<Configure>' => undef );
  return;
}

1;

__END__

=head1 NAME

Tk::Chart::Utils - Private Tk::Chart methods

=head1 SYNOPSIS

none

=head1 DESCRIPTION

none

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

L<Tk::Chart>

=cut
