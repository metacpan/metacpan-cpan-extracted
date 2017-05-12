package Tk::Chart::Boxplots;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 21/10/2011 22:26:28                                $
# $AIM       : Create boxplots                                    $
#==================================================================

use vars qw($VERSION);
$VERSION = '1.05';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Boxplots';

my $UNDERSCORE = '_';
my $COMMA = q{,};

sub Populate {

  my ( $cw, $ref_parameters ) = @_;

  # Get initial parameters
  $cw->{RefChart} = _initconfig();

  $cw->SUPER::Populate($ref_parameters);

  $cw->Advertise( 'GradientColor' => $cw );
  $cw->Advertise( 'canvas'        => $cw->SUPER::Canvas );
  $cw->Advertise( 'Canvas'        => $cw->SUPER::Canvas );

  # remove highlightthickness if necessary
  if ( !exists $ref_parameters->{-highlightthickness} ) {
    $cw->configure( -highlightthickness => 0 );
  }

  my $ref_configcommon = _get_configspecs();

  # ConfigSpecs
  $cw->ConfigSpecs(

    # Common options
    %{$ref_configcommon},

    -spacingbar        => [ 'PASSIVE', 'Spacingbar',        'SpacingBar',        1 ],
    -boxplotlinescolor => [ 'PASSIVE', 'BoxplotLinescolor', 'BoxplotLinesColor', 'black' ],
  );

  $cw->Delegates( DEFAULT => $cw, );

  # recreate graph after widget resize
  $cw->enabled_automatic_redraw();
  $cw->disabled_gradientcolor();

  return;
}

sub _balloon {
  my ($cw) = @_;

  # balloon defined and user want to stop it
  if ( defined $cw->{RefChart}->{Balloon}{Obj}
    and $cw->{RefChart}->{Balloon}{State} == 0 )
  {
    $cw->_destroyballoon_bind();
    return;
  }

  # balloon not defined and user want to stop it
  elsif ( $cw->{RefChart}->{Balloon}{State} == 0 ) {
    return;
  }

  # balloon defined and user want to start it again (may be new option)
  elsif ( defined $cw->{RefChart}->{Balloon}{Obj}
    and $cw->{RefChart}->{Balloon}{State} == 1 )
  {

    # destroy the balloon, it will be re create above
    $cw->_destroyballoon_bind();
  }

  # Balloon creation
  $cw->{RefChart}->{Balloon}{Obj} = $cw->Balloon(
    -statusbar  => $cw,
    -background => $cw->{RefChart}->{Balloon}{Background},
  );
  $cw->{RefChart}->{Balloon}{Obj}->attach(
    $cw,
    -balloonposition => 'mouse',
    -msg             => $cw->{RefChart}->{Legend}{MsgBalloon},
  );

  # no legend, no bind
  if ( !$cw->{RefChart}->{Legend}{LegendTextNumber} ) {
    return;
  }

  # bind legend and bars
  for my $index_legend ( 1 .. $cw->{RefChart}->{Legend}{LegendTextNumber} ) {

    my $legend_tag  = $index_legend . $cw->{RefChart}->{TAGS}{Legend};
    my $boxplot_tag = $index_legend . $cw->{RefChart}->{TAGS}{Boxplot};

    $cw->bind(
      $legend_tag,
      '<Enter>',
      sub {
        my $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[0];

        # Change color if bar have the same color
        if ( $other_color eq $cw->{RefChart}{Boxplot}{$boxplot_tag}{color} ) {
          $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[1];
        }
        $cw->itemconfigure(
          $boxplot_tag,
          -fill  => $other_color,
          -width => $cw->cget( -linewidth ) + $cw->{RefChart}->{Balloon}{MorePixelSelected},
        );
      }
    );

    $cw->bind(
      $legend_tag,
      '<Leave>',
      sub {
        $cw->itemconfigure(
          $boxplot_tag,
          -fill  => $cw->{RefChart}{Boxplot}{$boxplot_tag}{color},
          -width => $cw->cget( -linewidth ),
        );

        # Allow value bar to display
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{BarValues}, -fill => 'black', );
      }
    );
  }

  return;
}

sub boxplot_information {
  my ($cw) = @_;

  # Test if plot defined
  if ( not defined $cw->{RefChart}->{Data}{PlotDefined} ) {
    $cw->_error( 'You have to plot before get boxplots informations', 1 );
  }

  my @boxplot_information;
  my @alldata  = @{ $cw->{RefChart}->{Data}{RefAllData} };
  my $nbr_data = scalar @alldata;
  my ( $dim1, $dim2 ) = ( 0, 0 );

  # Read data and store information in A dimension table and hash.
  foreach my $sample_number ( 1 .. $nbr_data - 1 ) {

    # Fisrt dimension
    $dim1 = $sample_number - 1;
    $dim2 = 0;

    # Get information foreach sample
    foreach my $ref_data ( @{ $alldata[$sample_number] } ) {
      my ( $q1, $q2, $q3 )
        = ( _quantile( $ref_data, 1 ), _quantile( $ref_data, 2 ), _quantile( $ref_data, 3 ) );
      my ( $s_nonoutlier, $l_nonoutlier ) = _nonoutlier( $ref_data, $q1, $q3 );
      $boxplot_information[$dim1][$dim2] = {
        mean                 => _moy($ref_data),
        median               => $q2,
        Q1                   => $q1,
        Q3                   => $q3,
        largest_non_outlier  => $l_nonoutlier,
        smallest_non_outlier => $s_nonoutlier,
        outliers             => [],
      };

      foreach my $value ( @{$ref_data} ) {
        if ( $value < $s_nonoutlier or $value > $l_nonoutlier ) {
          push @{ $boxplot_information[$dim1][$dim2]->{outliers} }, $value;
        }
      }
      $dim2++;
    }
  }

  return \@boxplot_information;
}

sub set_legend {
  my ( $cw, %info_legend ) = @_;

  my $ref_legend = $info_legend{-data};
  if ( not defined $ref_legend ) {
    $cw->_error(
      "Can't set -data in set_legend method. May be you forgot to set the value\nEg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  if ( !( defined $ref_legend and ref $ref_legend eq 'ARRAY' ) ) {
    $cw->_error(
      "Can't set -data in set_legend method. Bad data\nEg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  my @legend_option = qw / -box -legendmarkerheight -legendmarkerwidth -heighttitle /;

  foreach my $option_name (@legend_option) {
    if ( (defined $info_legend{$option_name} ) and (! _isainteger( $info_legend{$option_name} ) ) ) {
      $cw->_error(
        "'Can't set $option_name to "
          . "'$info_legend{$option_name}', $info_legend{$option_name}' isn't numeric",
        1
      );
    }
  }

  # Check legend and data size
  if ( my $ref_data = $cw->{RefChart}->{Data}{RefAllData} ) {
    if ( !$cw->_checksizelegend_data( $ref_data, $ref_legend ) ) {
      undef $cw->{RefChart}->{Legend}{DataLegend};
      return;
    }
  }

  # Get Legend options
  # Title
  if ( defined $info_legend{-title} ) {
    $cw->{RefChart}->{Legend}{title} = $info_legend{-title};
  }
  else {
    undef $cw->{RefChart}->{Legend}{title};
    $cw->{RefChart}->{Legend}{HeightTitle} = 0;
  }

  # Title and legend font
  if ( defined $info_legend{-titlefont} ) {
    $cw->{RefChart}->{Legend}{titlefont} = $info_legend{-titlefont};
  }
  if ( defined $info_legend{-legendfont} ) {
    $cw->{RefChart}->{Legend}{legendfont} = $info_legend{-legendfont};
  }

  # box legend
  if ( defined $info_legend{-box} ) {
    $cw->{RefChart}->{Legend}{box} = $info_legend{-box};
  }

  # title color
  if ( defined $info_legend{-titlecolors} ) {
    $cw->{RefChart}->{Legend}{titlecolors} = $info_legend{-titlecolors};
  }

  # text color
  if ( defined $info_legend{-legendcolor} ) {
    $cw->{RefChart}->{Legend}{legendcolor} = $info_legend{-legendcolor};
  }

  # legendmarkerheight
  if ( defined $info_legend{-legendmarkerheight} ) {
    $cw->{RefChart}->{Legend}{HCube} = $info_legend{-legendmarkerheight};
  }

  # legendmarkerwidth
  if ( defined $info_legend{-legendmarkerwidth} ) {
    $cw->{RefChart}->{Legend}{WCube} = $info_legend{-legendmarkerwidth};
  }

  # heighttitle
  if ( defined $info_legend{-heighttitle} ) {
    $cw->{RefChart}->{Legend}{HeightTitle} = $info_legend{-heighttitle};
  }

  # Get the biggest length of legend text
  my @length_legend = map { length; } @{$ref_legend};
  my $biggest_legend = _maxarray( \@length_legend );

  # 100 pixel =>  13 characters, 1 pixel =>  0.13 pixels then 1 character = 7.69 pixels
  $cw->{RefChart}->{Legend}{WidthOneCaracter} = 7.69;

  # Max pixel width for a legend text for us
  $cw->{RefChart}->{Legend}{LengthTextMax}
    = int( $cw->{RefChart}->{Legend}{WidthText} / $cw->{RefChart}->{Legend}{WidthOneCaracter} );

  # We have free space
  my $diff = $cw->{RefChart}->{Legend}{LengthTextMax} - $biggest_legend;

  # Get new size width for a legend text with one pixel security
  $cw->{RefChart}->{Legend}{WidthText} -= ( $diff - 1 ) * $cw->{RefChart}->{Legend}{WidthOneCaracter};

  # Store Reference data
  $cw->{RefChart}->{Legend}{DataLegend} = $ref_legend;
  $cw->{RefChart}->{Legend}{NbrLegend}  = scalar @{$ref_legend};

  return 1;
}

sub _legend {
  my ( $cw, $ref_legend ) = @_;

  # One legend width
  $cw->{RefChart}->{Legend}{LengthOneLegend}
    = +$cw->{RefChart}->{Legend}{SpaceBeforeCube}    # space between each legend
    + $cw->{RefChart}->{Legend}{WCube}               # width legend marker
    + $cw->{RefChart}->{Legend}{SpaceAfterCube}      # space after marker
    + $cw->{RefChart}->{Legend}{WidthText}           # legend text width allowed
    ;

  # Number of legends per line
  $cw->{RefChart}->{Legend}{NbrPerLine}
    = int( $cw->{RefChart}->{Axis}{Xaxis}{Width} / $cw->{RefChart}->{Legend}{LengthOneLegend} );
  if ( $cw->{RefChart}->{Legend}{NbrPerLine} == 0 ) { $cw->{RefChart}->{Legend}{NbrPerLine} = 1; }

  # How many legend we will have
  $cw->{RefChart}->{Legend}{LegendTextNumber} = scalar @{ $cw->{RefChart}->{Data}{RefAllData} } - 1;

=for NumberLines:
  We calculate the number of lines set for the legend graph.
  If wa can set 11 legends per line, then for 3 legend, we will need one line
  and for 12 legends, we will need 2 lines
  If NbrLeg / NbrPerLine = integer => get number of lines
  If NbrLeg / NbrPerLine = float => int(float) + 1 = get number of lines

=cut

  $cw->{RefChart}->{Legend}{NbrLine}
    = $cw->{RefChart}->{Legend}{LegendTextNumber} / $cw->{RefChart}->{Legend}{NbrPerLine};
  if ( int( $cw->{RefChart}->{Legend}{NbrLine} ) != $cw->{RefChart}->{Legend}{NbrLine} ) {
    $cw->{RefChart}->{Legend}{NbrLine} = int( $cw->{RefChart}->{Legend}{NbrLine} ) + 1;
  }

  # Total Height of Legend
  $cw->{RefChart}->{Legend}{Height} = $cw->{RefChart}->{Legend}{HeightTitle}    # Hauteur Titre légende
    + $cw->{RefChart}->{Legend}{NbrLine} * $cw->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  if ( $cw->{RefChart}->{Legend}{LegendTextNumber} < $cw->{RefChart}->{Legend}{NbrPerLine} ) {
    $cw->{RefChart}->{Legend}{NbrPerLine} = $cw->{RefChart}->{Legend}{LegendTextNumber};
  }

  return;
}

sub _viewlegend {
  my ($cw) = @_;

  # legend option
  my $legend_title       = $cw->{RefChart}->{Legend}{title};
  my $legendmarkercolors = $cw->cget( -colordata );
  my $legendfont         = $cw->{RefChart}->{Legend}{legendfont};
  my $titlecolor         = $cw->{RefChart}->{Legend}{titlecolors};
  my $titlefont          = $cw->{RefChart}->{Legend}{titlefont};
  my $axiscolor          = $cw->cget( -axiscolor );

  # display legend title
  if ( defined $legend_title ) {
    my $x_legend_title = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Legend}{SpaceBeforeCube};
    my $y_legend_title
      = $cw->{RefChart}->{Axis}{CyMin} 
      + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
      + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
      + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight};

    $cw->createText(
      $x_legend_title,
      $y_legend_title,
      -text   => $legend_title,
      -anchor => 'nw',
      -font   => $titlefont,
      -fill   => $titlecolor,
      -width  => $cw->{RefChart}->{Axis}{Xaxis}{Width},
      -tags   => [ $cw->{RefChart}->{TAGS}{TitleLegend}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  # Display legend
  my $index_color  = 0;
  my $index_legend = 0;

  for my $number_line ( 0 .. $cw->{RefChart}->{Legend}{NbrLine} - 1 ) {
    my $x1_cube = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Legend}{SpaceBeforeCube};
    my $y1_cube
      = ( $cw->{RefChart}->{Axis}{CyMin} 
        + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
        + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
        + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight}
        + $cw->{RefChart}->{Legend}{HeightTitle}
        + $cw->{RefChart}->{Legend}{HLine} / 2 )
      + $number_line * $cw->{RefChart}->{Legend}{HLine};

    my $x2_cube    = $x1_cube + $cw->{RefChart}->{Legend}{WCube};
    my $y2_cube    = $y1_cube - $cw->{RefChart}->{Legend}{HCube};
    my $xtext      = $x2_cube + $cw->{RefChart}->{Legend}{SpaceAfterCube};
    my $ytext      = $y2_cube;
    my $max_length = $cw->{RefChart}->{Legend}{LengthTextMax};

  LEGEND:
    for my $number_leg_in_line ( 0 .. $cw->{RefChart}->{Legend}{NbrPerLine} - 1 ) {

      my $line_color = $legendmarkercolors->[$index_color];
      if ( not defined $line_color ) {
        $index_color = 0;
        $line_color  = $legendmarkercolors->[$index_color];
      }

      # Cut legend text if too long
      my $legend = $cw->{RefChart}->{Legend}{DataLegend}->[$index_legend];
      next if ( not defined $legend );
      my $new_legend = $legend;

      if ( length $new_legend > $max_length ) {
        $max_length -= 3;
        $new_legend =~ s/^(.{$max_length}).*/$1/;
        $new_legend .= '...';
      }

      my $tag = ( $index_legend + 1 ) . $cw->{RefChart}->{TAGS}{Legend};
      $cw->createRectangle(
        $x1_cube, $y1_cube, $x2_cube, $y2_cube,
        -fill    => $line_color,
        -outline => $line_color,
        -tags    => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      );

      my $id = $cw->createText(
        $xtext, $ytext,
        -text   => $new_legend,
        -anchor => 'nw',
        -tags   => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -fill   => $cw->{RefChart}->{Legend}{legendcolor},
      );
      if ($legendfont) {
        $cw->itemconfigure( $id, -font => $legendfont, );
      }

      $index_color++;
      $index_legend++;

      # cube
      $x1_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};
      $x2_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xtext += $cw->{RefChart}->{Legend}{LengthOneLegend};
      my $boxplot_tag = $index_legend . $cw->{RefChart}->{TAGS}{Boxplot};

      # balloon on legend
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag} = $legend;

      last LEGEND
        if ( $index_legend == $cw->{RefChart}->{Legend}{LegendTextNumber} );
    }
  }

  # box legend
  my $x1box = $cw->{RefChart}->{Axis}{CxMin};
  my $y1box
    = $cw->{RefChart}->{Axis}{CyMin} 
    + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
    + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
    + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight};
  my $x2box = $x1box + ( $cw->{RefChart}->{Legend}{NbrPerLine} * $cw->{RefChart}->{Legend}{LengthOneLegend} );

  # Reajuste box if width box < legend title text
  my @info_legend_title = $cw->bbox( $cw->{RefChart}->{TAGS}{TitleLegend} );
  if ( $info_legend_title[2] and $x2box <= $info_legend_title[2] ) {
    $x2box = $info_legend_title[2] + 2;
  }
  my $y2box = $y1box + $cw->{RefChart}->{Legend}{Height};
  $cw->createRectangle(
    $x1box, $y1box, $x2box, $y2box,
    -tags    => [ $cw->{RefChart}->{TAGS}{BoxLegend}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    -outline => $axiscolor,
  );

  return;
}

sub _axis {
  my ($cw) = @_;

  my $axiscolor = $cw->cget( -axiscolor );

  # x-axis width
  $cw->{RefChart}->{Axis}{Xaxis}{Width}
    = $cw->{RefChart}->{Canvas}{Width}
    - ( 2 * $cw->{RefChart}->{Canvas}{WidthEmptySpace} 
      + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
      + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
      + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} );

  # get Height legend
  if ( $cw->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    $cw->_legend( $cw->{RefChart}->{Legend}{DataLegend} );
  }

  # Height y-axis
  $cw->{RefChart}->{Axis}{Yaxis}{Height} = $cw->{RefChart}->{Canvas}{Height}    # Largeur canvas
    - (
    2 * $cw->{RefChart}->{Canvas}{HeightEmptySpace}                             # 2 fois les espace vides
      + $cw->{RefChart}->{Title}{Height}                                        # Hauteur du titre
      + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}                              # Hauteur tick (axe x)
      + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}                       # Hauteur valeurs axe
      + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight}                            # Hauteur x label
      + $cw->{RefChart}->{Legend}{Height}                                       # Hauteur légende
    );

  #===========================
  # Y axis
  # Set 2 points (CxMin, CyMin) et (CxMin, CyMax)
  $cw->{RefChart}->{Axis}{CxMin}                                                # Coordonnées CxMin
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace}                                # Largeur vide
    + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}                               # Largeur label y
    + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}                          # Largeur valeur axe y
    + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth};                                # Largeur tick axe y

  $cw->{RefChart}->{Axis}{CyMax}                                                # Coordonnées CyMax
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace}                               # Hauteur vide
    + $cw->{RefChart}->{Title}{Height}                                          # Hauteur titre
    ;

  $cw->{RefChart}->{Axis}{CyMin}                                                # Coordonnées CyMin
    = $cw->{RefChart}->{Axis}{CyMax}                                            # Coordonnées CyMax (haut)
    + $cw->{RefChart}->{Axis}{Yaxis}{Height}                                    # Hauteur axe Y
    ;

  # display Y axis
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMin},
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMax},
    -tags => [
      $cw->{RefChart}->{TAGS}{yAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  #===========================
  # X axis
  # Set 2 points (CxMin,CyMin) et (CxMax,CyMin)
  # ou (Cx0,Cy0) et (CxMax,Cy0)
  $cw->{RefChart}->{Axis}{CxMax} = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Axis}{Xaxis}{Width};

  # Bottom x-axis
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMin},
    $cw->{RefChart}->{Axis}{CxMax},
    $cw->{RefChart}->{Axis}{CyMin},
    -tags => [
      $cw->{RefChart}->{TAGS}{xAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # POINT (0,0)
  $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit}    # Height unit for value = 1
    = $cw->{RefChart}->{Axis}{Yaxis}{Height}
    / ( $cw->{RefChart}->{Data}{MaxYValue} - $cw->{RefChart}->{Data}{MinYValue} );

  # min positive value >= 0
  if ( $cw->{RefChart}->{Data}{MinYValue} >= 0 ) {
    $cw->{RefChart}->{Axis}{Cx0} = $cw->{RefChart}->{Axis}{CxMin};
    $cw->{RefChart}->{Axis}{Cy0} = $cw->{RefChart}->{Axis}{CyMin};
  }

  # min positive value < 0
  else {
    $cw->{RefChart}->{Axis}{Cx0} = $cw->{RefChart}->{Axis}{CxMin};
    $cw->{RefChart}->{Axis}{Cy0} = $cw->{RefChart}->{Axis}{CyMin}
      + ( $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} * $cw->{RefChart}->{Data}{MinYValue} );

    # X Axis (0,0)
    $cw->createLine(
      $cw->{RefChart}->{Axis}{Cx0},
      $cw->{RefChart}->{Axis}{Cy0},
      $cw->{RefChart}->{Axis}{CxMax},
      $cw->{RefChart}->{Axis}{Cy0},
      -tags => [
        $cw->{RefChart}->{TAGS}{xAxis0}, $cw->{RefChart}->{TAGS}{AllAXIS},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $axiscolor,
    );
  }

  return;
}

sub _xtick {
  my ($cw) = @_;

  my $xvaluecolor    = $cw->cget( -xvaluecolor );
  my $longticks      = $cw->cget( -longticks );
  my $xvaluevertical = $cw->cget( -xvaluevertical );
  my $xvaluefont     = $cw->cget( -xvaluefont );

  # x coordinates y ticks on bottom x-axis
  my $x_tickx1 = $cw->{RefChart}->{Axis}{CxMin};
  my $x_ticky1 = $cw->{RefChart}->{Axis}{CyMin};

  # x coordinates y ticks on 0,0 x-axis if the graph have only y value < 0
  if (  $cw->cget( -zeroaxisonly ) == 1
    and $cw->{RefChart}->{Data}{MaxYValue} > 0 )
  {
    $x_ticky1 = $cw->{RefChart}->{Axis}{Cy0};
  }

  my $x_tickx2 = $x_tickx1;
  my $x_ticky2 = $x_ticky1 + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight};

  # Coordinates of x values (first value)
  my $xtick_xvalue
    = $cw->{RefChart}->{Axis}{CxMin} + ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
  my $xtick_yvalue = $x_ticky2 + ( $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} / 2 );
  my $nbrleg = scalar( @{ $cw->{RefChart}->{Data}{RefXLegend} } );

  my $xlabelskip = $cw->cget( -xlabelskip );

  # index of tick and vlaues that will be skip
  my %indice_skip;
  if ( defined $xlabelskip ) {
    for ( my $i = 1; $i <= $nbrleg; $i++ ) {
      $indice_skip{$i} = 1;
      $i += $xlabelskip;
    }
  }

  for my $indice ( 1 .. $nbrleg ) {
    my $data = $cw->{RefChart}->{Data}{RefXLegend}->[ $indice - 1 ];

    # tick
    $x_tickx1 += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    $x_tickx2 = $x_tickx1;

    # tick legend
    my $regex_xtickselect = $cw->cget( -xvaluesregex );

    if ( $data =~ m{$regex_xtickselect} ) {
      if ( not defined $indice_skip{$indice} ) {
        $xtick_xvalue += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
        next;
      }

      # Display xticks short or long
      $cw->_display_xticks( $x_tickx1, $x_ticky1, $x_tickx2, $x_ticky2 );

#      if (  defined $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
#        and defined $cw->{RefChart}->{Legend}{WidthOneCaracter} )
#      {
#        my $max_length    = $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
#        my $width_data    = $cw->{RefChart}->{Legend}{WidthOneCaracter} * length $data;
#        my $nbr_character = int( $max_length / $cw->{RefChart}->{Legend}{WidthOneCaracter} );
#        if ( (defined $max_length) and ($width_data > $max_length) and ( not defined $xvaluevertical or $xvaluevertical != 1 ) ) {
#          $data =~ s/^(.{$nbr_character}).*/$1/;
#          $data .= '...';
#        }
#      }

      my $id_xtick_value = $cw->createText(
        $xtick_xvalue,
        $xtick_yvalue,
        -text   => $data,
        -fill   => $xvaluecolor,
        -font   => $xvaluefont,      
        -width  => $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}, 
        -anchor => 'n',     
        -tags   => [
          $cw->{RefChart}->{TAGS}{xValues}, $cw->{RefChart}->{TAGS}{AllValues},
          $cw->{RefChart}->{TAGS}{AllTagsChart},
        ],

        #        %option,
      );
      if ( defined $xvaluevertical and $xvaluevertical == 1 ) {
        $cw->itemconfigure($id_xtick_value, -width => 5, -anchor => 'n',);
      }

    }
    $xtick_xvalue += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
  }

  return;
}

sub _viewdata {
  my ($cw) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $spacingbar         = $cw->cget( -spacingbar );
  my $boxplotlinescolor  = $cw->cget( -boxplotlinescolor );

  # number of value for x-axis
  $cw->{RefChart}->{Data}{xtickNumber} = $cw->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $cw->{RefChart}->{Axis}{Xaxis}{Width} / ( $cw->{RefChart}->{Data}{xtickNumber} + 1 );

  my $id_data     = 0;
  my $index_color = 0;
  my $width_bar = $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / $cw->{RefChart}->{Data}{NumberRealData};

  # Spacing if necessary
  my $spacing_pixel = 0;
  if ( $spacingbar == 1 ) {
    $spacing_pixel = $width_bar / 4;
  }

  my $ymin0             = $cw->{RefChart}->{Axis}{Cy0};
  my $xmin0             = $cw->{RefChart}->{Axis}{Cx0};
  my $yaxis_height_unit = $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit};
  foreach my $ref_arraydata ( @{ $cw->{RefChart}->{Data}{RefAllData} } ) {
    if ( $id_data == 0 ) {
      $id_data++;
      next;
    }
    my $number_data = 1;    # Number of data
                            # each boxplot
    foreach my $ref_data ( @{$ref_arraydata} ) {
      if ( !( defined $ref_data and scalar @{$ref_data} > 3 ) ) {
        $number_data++;
        next;
      }

      # statistic calcul
      my $quantile1 = _quantile( $ref_data, 1 );
      my $quantile2 = _quantile( $ref_data, 2 );
      my $quantile3 = _quantile( $ref_data, 3 );
      my ( $s_nonoutlier, $l_nonoutlier ) = _nonoutlier( $ref_data, $quantile1, $quantile3 );
      my $moy = _moy($ref_data);

      # Boxplot graph coord
      my $x
        = $xmin0 
        + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
        - ( ( $cw->{RefChart}->{Data}{NumberRealData} - $id_data ) * $width_bar );
      my $x0 = $x - $width_bar + $spacing_pixel;
      my $xc = ( $x + $x0 ) / 2;

      # y Boxplot
      my $yquantile1     = $ymin0 - ( $quantile1 * $yaxis_height_unit );
      my $yquantile3     = $ymin0 - ( $quantile3 * $yaxis_height_unit );
      my $yquantile2     = $ymin0 - ( $quantile2 * $yaxis_height_unit );
      my $y_s_nonoutlier = $ymin0 - ( $s_nonoutlier * $yaxis_height_unit );
      my $y_l_nonoutlier = $ymin0 - ( $l_nonoutlier * $yaxis_height_unit );
      my $ymoy           = $ymin0 - ( $moy * $yaxis_height_unit );

      #update=
      if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
        $yquantile1     += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
        $yquantile3     += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
        $yquantile2     += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
        $y_s_nonoutlier += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
        $y_l_nonoutlier += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
        $ymoy           += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
      }
      $moy = sprintf '%.2f', $moy;

      # color
      my $line_color = $legendmarkercolors->[$index_color];
      if ( not defined $line_color ) {
        $index_color = 0;
        $line_color  = $legendmarkercolors->[$index_color];
      }

      # tag
      my $tag  = $id_data . $UNDERSCORE . $number_data . $cw->{RefChart}->{TAGS}{Boxplot};
      my $tag2 = $id_data . $cw->{RefChart}->{TAGS}{Boxplot};
      $cw->{RefChart}{Boxplot}{$tag2}{color} = $line_color;
      my $message;
      if ( $message = $cw->{RefChart}->{Legend}{DataLegend}->[ $id_data - 1 ] ) {
        $message .= " : \n";
      }
      $message .= <<"MESSAGE";
  Sample : $cw->{RefChart}->{Data}{RefAllData}->[0]->[$number_data-1]
  Largest non-outlier : $l_nonoutlier
  75th percentile : $quantile3
  Median : $quantile2
  Mean : $moy
  25th percentile : $quantile1
  Smallest non-outlier : $s_nonoutlier
MESSAGE
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag} = $message;

      # D9
      $cw->createLine(
        $x0,
        $y_l_nonoutlier,
        $x,
        $y_l_nonoutlier,
        -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width => $cw->cget( -linewidth ),
        -fill  => $boxplotlinescolor,
      );
      $cw->createLine(
        $xc,
        $y_l_nonoutlier,
        $xc,
        $yquantile3,
        -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width => $cw->cget( -linewidth ),
        -fill  => $boxplotlinescolor,
      );

      # D1
      $cw->createLine(
        $x0,
        $y_s_nonoutlier,
        $x,
        $y_s_nonoutlier,
        -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width => $cw->cget( -linewidth ),
        -fill  => $boxplotlinescolor,
      );
      $cw->createLine(
        $xc,
        $y_s_nonoutlier,
        $xc,
        $yquantile1,
        -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width => $cw->cget( -linewidth ),
        -fill  => $boxplotlinescolor,
      );

      # box : median
      $cw->createRectangle(
        $x0,
        $yquantile1,
        $x,
        $yquantile3,
        -tags => [ $tag2, $tag, $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width   => $cw->cget( -linewidth ),
        -fill    => $line_color,
        -outline => $boxplotlinescolor,
      );

      # Q2 : median
      $cw->createLine(
        $x0,
        $yquantile2,
        $x,
        $yquantile2,
        -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -width => $cw->cget( -linewidth ),
        -fill  => $boxplotlinescolor,
      );

      # Moy
      $cw->_createtype(
        x      => $xc,
        y      => $ymoy,
        pixel  => 6,
        type   => 'horizontal cross',
        option => {
          -tags  => [ $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
          -width => $cw->cget( -linewidth ),
          -fill  => $boxplotlinescolor,
        },
      );

      # outlier
      foreach my $value ( @{$ref_data} ) {
        if ( $value < $s_nonoutlier or $value > $l_nonoutlier ) {
          my $outlier_tag = $id_data . $UNDERSCORE . $number_data . "_$value" . 'Outlier';
          $cw->{RefChart}->{Legend}{MsgBalloon}->{$outlier_tag} = "outlier : $value";

          my $y_outlier = $ymin0 - ( $value * $yaxis_height_unit );
          if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
            $y_outlier += ( $cw->{RefChart}->{Data}{MinYValue} * $yaxis_height_unit );
          }
          $cw->_createtype(
            x      => $xc,
            y      => $y_outlier,
            pixel  => 6,
            type   => 'diagonal cross',
            option => {
              -tags =>
                [ $outlier_tag, $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
              -width => $cw->cget( -linewidth ),
              -fill  => $boxplotlinescolor,
            },
          );
          $cw->_createtype(
            x      => $xc,
            y      => $y_outlier,
            pixel  => 6,
            type   => 'horizontal cross',
            option => {
              -tags =>
                [ $outlier_tag, $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
              -width => $cw->cget( -linewidth ),
              -fill  => $boxplotlinescolor,
            },
          );
        }
      }

      $number_data++;

    }

    $id_data++;
    $index_color++;
  }

  return 1;
}

sub plot {
  my ( $cw, $ref_data, %option ) = @_;

  my $yticknumber = $cw->cget( -yticknumber );
  my $yminvalue   = $cw->cget( -yminvalue );
  my $ymaxvalue   = $cw->cget( -ymaxvalue );
  my $interval    = $cw->cget( -interval );

  if ( defined $option{-substitutionvalue}
    and _isanumber( $option{-substitutionvalue} ) )
  {
    $cw->{RefChart}->{Data}{SubstitutionValue} = $option{-substitutionvalue};
  }

  $cw->{RefChart}->{Data}{NumberRealData} = scalar( @{$ref_data} ) - 1;

  if ( not defined $ref_data ) {
    $cw->_error('data not defined');
    return;
  }

  if ( scalar @{$ref_data} <= 1 ) {
    $cw->_error('You must have at least 2 arrays');
    return;
  }

  # Check legend and data size
  if ( $cw->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    my $ref_legend = $cw->{RefChart}->{Legend}{DataLegend};
    if ( !$cw->_checksizelegend_data( $ref_data, $ref_legend ) ) {
      undef $cw->{RefChart}->{Legend}{DataLegend};
    }
  }

  # Check array size
  $cw->{RefChart}->{Data}{NumberXValues} = scalar @{ $ref_data->[0] };
  my $i          = 0;
  my @array_temp = (0) x scalar @{ $ref_data->[0] };
  foreach my $refarray ( @{$ref_data} ) {
    if ( scalar @{$refarray} != $cw->{RefChart}->{Data}{NumberXValues} ) {
      $cw->_error( 'Make sure that every array has the same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      foreach my $refarray2 ( @{$refarray} ) {

        # First data must be an array ref
        if ( ref $refarray2 ne 'ARRAY' ) {
          $cw->_error( 'Each boxplot data must be in an array reference', 1 );
        }
        foreach my $data ( @{$refarray2} ) {
          if ( ( defined $data ) and ( !_isanumber($data) ) ) {
            $data = $cw->{RefChart}->{Data}{SubstitutionValue};
          }
        }
      }

      # max, min
      foreach my $refarray2 ( @{$refarray} ) {
        $cw->{RefChart}->{Data}{MaxYValue}
          = _maxarray( [ $cw->{RefChart}->{Data}{MaxYValue}, _maxarray($refarray2) ] );
        $cw->{RefChart}->{Data}{MinYValue}
          = _minarray( [ $cw->{RefChart}->{Data}{MinYValue}, _minarray($refarray2) ] );

        # Size each data points
        if ( scalar @{$refarray2} < 4 and scalar @{$refarray2} > 0 ) {
          my $data = join $COMMA, @{$refarray2};
          $data = "[$data]";
          $cw->_error("Data set $data does not contain the minimum of 4 data points.\nIt has been skipped.");
        }
      }

    }
    $i++;
  }

  $cw->{RefChart}->{Data}{RefXLegend}  = $ref_data->[0];
  $cw->{RefChart}->{Data}{RefAllData}  = $ref_data;
  $cw->{RefChart}->{Data}{PlotDefined} = 1;

  $cw->_manage_minmaxvalues($yticknumber);
  $cw->_chartconstruction;

  return 1;
}

1;
__END__

=head1 NAME

Tk::Chart::Boxplots - Extension of Canvas widget to create boxplots graph. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Boxplots;
  
  my $mw = MainWindow->new(
    -title      => 'Tk::Chart::Boxplots example',
    -background => 'white',
  );
  
  my $chart = $mw->Boxplots(
    -title      => 'My graph title',
    -xlabel     => 'X Label',
    -ylabel     => 'Y Label',
    -background => 'snow',
  )->pack(qw / -fill both -expand 1 /);
  
  my $one   = [ 210 .. 275 ];
  my $two   = [ 180, 190, 200, 220, 235, 245 ];
  my $three = [ 40, 140 .. 150, 160 .. 180, 250 ];
  my $four  = [ 100 .. 125, 136 .. 140 ];
  my $five  = [ 10 .. 50, 100, 180 ];
  
  my @data = (
    [ '1st', '2nd', '3rd',  '4th', '5th' ],
    [ $one,  $two,  $three, $four, $five ],
    [ [-25, 1..15], [-45, 25..45, 100], [70, 42..125], undef, [180..250] ],
    # ...
  );
  
  # Add a legend to the graph
  my @legends = ( 'legend 1', 'legend 2' );
  $chart->set_legend(
    -title       => 'Title legend',
    -data        => \@legends,
  );
  
  # Add help identification
  $chart->set_balloon();
  
  # Create the graph
  $chart->plot( \@data );
  
  MainLoop();

=head1 DESCRIPTION

Tk::Chart::Boxplots is an extension of the Canvas widget. It is an easy way to build  
interactive boxplots (also known as a B<box-and-whisker diagram> or B<plot>) 
graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

You can change the color, font of title, labels (x and y) of the graph.
You can set an interactive legend.  
The axes can be automatically scaled or set by the code. 

When the mouse cursor passes over a boxplot, its outlier or its entry in the legend, 
the boxplot and its entry will be turned to a color (that you can change) to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

=head1 BACKGROUND GRADIENT COLOR

You can set a background gradient color by using all methods of L<Tk::Canvas::GradientColor>. By 
default, it is not enabled.

To enabled background gradient color the first time, you firstly have to call B<enabled_gradientcolor> method and configure 
your color and type of gradient with B<set_gradientcolor>.

  $chart->enabled_gradientcolor();
  $chart->set_gradientcolor(
      -start_color => '#6585ED',
      -end_color   => '#FFFFFF',
  );

Please, read L<Tk::Canvas::GradientColor/"WIDGET-SPECIFIC METHODS"> documentation to know all available configurations.

=head1 STANDARD OPTIONS

B<-background>          B<-borderwidth>	      B<-closeenough>	         B<-confine>
B<-cursor>	            B<-height>	          B<-highlightbackground>	 B<-highlightcolor>
B<-highlightthickness>	B<-insertbackground>  B<-insertborderwidth>    B<-insertofftime>	
B<-insertontime>        B<-insertwidth>       B<-relief>               B<-scrollregion> 
B<-selectbackground>    B<-selectborderwidth> B<-selectforeground>     B<-takefocus> 
B<-width>               B<-xscrollcommand>    B<-xscrollincrement>     B<-yscrollcommand> 
B<-yscrollincrement>

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:	B<BoxplotLinescolor>

=item Class: B<BoxplotLinesColor>

=item Switch:	B<-boxplotlinescolor>

Color of lines of boxplots. 

 -boxplotlinescolor => 'red',

Default : B<black>

=item Name:	B<Spacingbar>

=item Class: B<SpacingBar>

=item Switch:	B<-spacingbar>

Set this to 1 to display remove space between each boxplot. 

 -spacingbar => 0, # 0 or 1

Default : B<1>

=back

=head1 WIDGET-SPECIFIC OPTIONS for graphs with axes.

See L<Tk::Chart::Lines/"WIDGET-SPECIFIC OPTIONS">

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 add_data

=over 4

=item I<$chart>->B<add_data>(I<\@newdata, ?$legend>)

This method allows you to add data in your graph. If you have already plot data 
using plot method and if you want to add new data, you can use this method.
Your graph will be updade.

=back

=over 8

=item *

I<Data array reference>

Fill an array of arrays with the values of the datasets (I<\@data>). 
Make sure that every array has the same size, otherwise 
Tk::Chart::Lines will complain and refuse to compile the graph.

  my $one     = [ 210 .. 275 ];
  my $two     = [ 180, 190, 200, 220, 235, 245 ];
  my $three   = [ 40, 140 .. 150, 160 .. 180, 250 ];
  my $four    = [ 100 .. 125, 136 .. 140 ];
  my $five    = [ 10 .. 50, 100, 180 ];
  my @newdata = ( $one, $two, $three, $four, $five );
  $chart->add_data( \@newdata, 'new legend' );

If your last graph has a legend, you have to add a 
legend entry for the new dataset. Otherwise, 
the legend graph will not be display (see below).

=item *

I<$legend>

  my $legend = 'New data set';
  $chart->add_data(\@newdata, $legend);

=back

=head2 boxplot_information

=over 4

=item I<$chart>->B<boxplot_information>

Use this method if you want to get the informations about all boxplots 
(25th percentile (Q1), 75th percentile (Q3), smallest non-outlier, 
largest non-outlier, median and mean). This method returns an array reference. 
The informations are stored in a hash reference.

  my $ref_array_information = $chart->boxplot_information();
  
  # Print information of boxplot @{$data[2][3]} (2th sample, 4th data )
  print "Boxplot @{$data[2][3]} (2th sample, 4th data )\n";
  print "Outliers : @{$ref_array_information->[1][3]->{outliers}}\n";
  print '25th percentile (Q1) : ', $ref_array_information->[1][3]->{Q1}, "\n";
  print '75th percentile (Q3) :',  $ref_array_information->[1][3]->{Q3}, "\n";
  print 'Smallest non-outlier : ',
    $ref_array_information->[1][3]->{smallest_non_outlier}, "\n";
  print 'Largest non-outlier :', $ref_array_information->[1][3]->{largest_non_outlier},
    "\n";
  print 'Median : ', $ref_array_information->[1][3]->{median}, "\n";
  print 'Mean : ',   $ref_array_information->[1][3]->{mean},   "\n";

if you have this data :

  my @data = (
      [ '1st', '2nd', '3rd',  '4th', '5th' ],
      [ [ list data00 ],  [list data01],  [list data02], ],
      [ [ list data10 ],  [list data11],  [list data12], ],
      [ [ list data20 ],  [list data21],  [list data22], ],
      #...
    );

To get the informations about boxplot B<list data21>, you have to read hash reference 
like this :

  $ref_hash_information = $ref_array_information->[2][1];
  # 25th percentile (Q1)
  print $ref_hash_information->{Q1};
  # Smallest non-outlier
  print $ref_hash_information->{smallest_non_outlier};

The quantile is calculated with the same algorithm as Excel and type 
7 quantile R package.

=back

=head2 clearchart

=over 4

=item I<$chart>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 delete_balloon

=over 4

=item I<$chart>->B<delete_balloon>

If you call this method, you disable help identification which has been enabled 
with set_balloon method.

=back

=head2 disabled_automatic_redraw

=over 4

=item I<$chart>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $chart->disabled_automatic_redraw;  

=back

=head2 enabled_automatic_redraw

=over 4

=item I<$chart>->B<enabled_automatic_redraw>

Use this method to allow your graph to be recreated automatically when the widget size change. When the graph 
is created for the first time, this method is called. 

  $chart->enabled_automatic_redraw;  

=back

=head2 plot

=over 4

=item I<$chart>->B<plot>(I<\@data, ?arg>)

To display your graph the first time, plot the graph by using this method.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the x values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::Chart::Boxplots 
will complain and refuse to compile the graph.

  my @data = (
    [ '1st', '2nd', '3rd',  '4th', '5th' ],
    [ [100 .. 125, 136 .. 140 ],  [22..89],  [12,54,88,10], [12,11,23,14..98,45], [0..55,11,12] ],
    [ [-25..-5, 1..15], [-45, 25..45, 100], [70, 42..125], [100, 30, 88, 95, 115, 155], [180..250] ],
    #...
  );
  
@data have to contain a least two arrays, the x values and the values of the datasets.
Each boxplot (array eg: [22..89]) have to contain at least 4 data.

 [22,1,14] => wrong

If you don't have a value for a point in a dataset, you can use undef, 
and the point will be skipped.

 [ undef,  [22..89],  [12,54,88,10], undef, [0..55,11,12] ],


=item *

-substitutionvalue => I<real number>,

If you have a no real number value in a dataset, it will be replaced by a constant value.

Default : B<0>

 my @data = (
      [     '1st',   '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
      [         1,    '--',     5,     6,     3,   1.5,     1,     3,     4 ],
      [ 'mistake',       2,     5,     2,     3,  'NA',     7,     9,     4 ],
      [         1,       2,    52,     6,     3,  17.5,     1,    43,     4 ],
 );
 $chart->plot( \@data,
   -substitutionvalue => '12',
 );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (Eg : 12, .25, 02.25, 5.2e+11, ...) 

=back

=head2 redraw

Redraw the graph. 

If you have used clearchart for any reason, it is possible to redraw the graph.
Tk::Chart::Boxplots supports the configure and cget methods 
described in the L<Tk::options> manpage. If you use configure method to change 
a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, 
call B<redraw> method to resolv the bug.

  ...
  $mw->Button(
  -text    => 'Change xlabel', 
  -command => sub { 
      $chart->configure(-xlabel => 'red'); 
    }, 
  )->pack;
  ...
  # xlabel will be changed but not displayed if you not resize the widget.
    
  ...
  $mw->Button(
    -text => 'Change xlabel', 
    -command => sub { 
      $chart->configure(-xlabel => 'red'); 
      $chart->redraw; 
    } 
  )->pack;
  ...
  # OK, xlabel will be changed and displayed without resize the widget.

=head2 set_balloon

=over 4

=item I<$chart>->B<set_balloon>(I<? %options>)

If you call this method, you enable help identification.
When the mouse cursor passes over a plotted line or its entry in the legend, 
the line and its entry will be turn into a color (that you can change) 
to help the identification. B<set_legend> method must be set if you want to 
enabled identification.

=back

=over 8

=item *

-background => I<string>

Set a background color for the balloon.

 -background => 'red',

Default : B<snow>

=item *

-colordatamouse => I<Array reference>

Specify an array reference wich contains 2 colors. The first color specifies 
the color of the line when mouse cursor passes over a entry in the legend. 
If the line has the same color, the second color will be used.

 -colordatamouse => ['blue', 'green'],

Default : -colordatamouse => B<[ '#7F9010', '#CB89D3' ]>

=item *

-morepixelselected => I<integer>

When the mouse cursor passes over an entry in the legend, 
the line width increase. 

 -morepixelselected => 5,

Default : B<1>

=back

=head2 set_legend

=over 4

=item I<$chart>->B<set_legend>(I<? %options>)

View a legend for the graph and allow to enabled identification help by using 
B<set_balloon> method.

=back

=over 8

=item *

-title => I<string>

Set a title legend.

 -title => 'My title',

Default : B<undef>

=item *

-titlecolors => I<string>

Set a color to legend text.

 -titlecolors => 'red',

Default : B<black>

=item *

-titlefont => I<string>

Set the font to legend title text.

 -titlefont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {bold}>

=item *

-legendcolor => I<color>

Color of legend text.

 -legendcolor => 'white',

Default : B<'black'>

=item *

-legendfont => I<string>

Set the font to legend text.

 -legendfont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {normal}>

=item *

-box => I<boolean>

Set a box around all legend.

 -box => 1, # or 0

Default : B<0>

=item *

-legendmarkerheight => I<integer>

Change the heigth of marker for each legend entry. 

 -legendmarkerheight => 5,

Default : B<10>

=item *

-legendmarkerwidth => I<integer>

Change the width of marker for each legend entry. 

 -legendmarkerwidth => 5,

Default : B<10>

=item *

-heighttitle => I<integer>

Change the height title legend space. 

 -heighttitle => 75,

Default : B<30>

=back

=head2 zoom

$chart-E<gt>B<zoom>(I<integer>);

Zoom the graph. The x-axis and y-axis will be zoomed. If your graph has 
a 300*300 size, after a zoom(200), the graph will have a 600*600 size.

  $chart->zoom(50); # size divide by 2 => 150*150
  ...
  $chart->zoom(200); # size multiplie by 2 => 600*600
  ...
  $chart->zoom(120); # 20% add in each axis => 360*360
  ...
  $chart->zoom(100); # original resize 300*300. 


=head2 zoomx

Zoom the graph the x-axis.

 # original canvas size 300*300
 $chart->zoomx(50); # new size : 150*300
 ...
 $chart->zoom(100); # new size : 300*300

=head2 zoomy

Zoom the graph the y-axis.

 # original canvas size 300*300
 $chart->zoomy(50); # new size : 300*150
 ...
 $chart->zoom(100); # new size : 300*300


=head1 EXAMPLES

In the B<demo> directory, you have a lot of script examples with their screenshot. 
See also the L<http://search.cpan.org/dist/Tk-Chart/MANIFEST> web page of L<Tk::Chart>.

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>, L<Tk::Graph>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-Chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Boxplots

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Chart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Chart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Chart>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Chart/>

=back

=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2011 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
