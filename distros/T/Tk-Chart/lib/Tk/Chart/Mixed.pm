package Tk::Chart::Mixed;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 21/10/2011 22:25:00                                $
# $AIM       : Create Mixed graph                                 $
#==================================================================

use vars qw($VERSION);
$VERSION = '1.05';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES :DISPLAY /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Mixed';

my $POINT = q{.};

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

    # bars
    -overwrite       => [ 'PASSIVE', 'Overwrite',       'OverWrite',       0 ],
    -cumulate        => [ 'PASSIVE', 'Cumulate',        'Cumulate',        0 ],
    -spacingbar      => [ 'PASSIVE', 'Spacingbar',      'SpacingBar',      1 ],
    -showvalues      => [ 'PASSIVE', 'Showvalues',      'ShowValues',      0 ],
    -barsvaluescolor => [ 'PASSIVE', 'BarsValuescolor', 'BarsValuesColor', 'black' ],
    -outlinebar      => [ 'PASSIVE', 'Outlinebar',      'OutlineBar',      'black' ],

    # splines
    -bezier => [ 'PASSIVE', 'Bezier', 'Bezier', 0 ],
    -spline => [ 'PASSIVE', 'Spline', 'Spline', 0 ],

    # points
    -pointline  => [ 'PASSIVE', 'Pointline',  'PointLine',  0 ],
    -markersize => [ 'PASSIVE', 'Markersize', 'MarkerSize', 8 ],
    -markers => [ 'PASSIVE', 'Markers', 'Markers', [ 1 .. 8 ] ],

    # mixed
    -typemixed   => [ 'PASSIVE', 'Typemixed',   'TypeMixed',   undef ],
    -defaulttype => [ 'PASSIVE', 'Defaulttype', 'DefaulTtype', 'lines' ],

    # Areas
    -outlinearea => [ 'PASSIVE', 'Outlinearea', 'OutlineArea', 'black' ],
    -viewsection => [ 'PASSIVE', 'Viewsection', 'ViewSection', 0 ],
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

  # bind legend and Mixed
  for my $index_legend ( 1 .. $cw->{RefChart}->{Legend}{LegendTextNumber} ) {

    my $legend_tag = $index_legend . $cw->{RefChart}->{TAGS}{Legend};
    my $mixed_tag  = $index_legend . $cw->{RefChart}->{TAGS}{Mixed};

    $cw->bind(
      $legend_tag,
      '<Enter>',
      sub {
        my $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[0];

        # Change color if bar have the same color
        if ( $other_color eq $cw->{RefChart}{Mixed}{$mixed_tag}{color} ) {
          $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[1];
        }
        $cw->itemconfigure( $mixed_tag, -fill => $other_color, );
        my $element_type = $cw->type($mixed_tag);
        if ( $element_type =~ m{^polygon|oval|arc$} ) {
          $cw->itemconfigure( $mixed_tag, -outline => $other_color, );
        }
      }
    );

    $cw->bind(
      $legend_tag,
      '<Leave>',
      sub {
        $cw->itemconfigure( $mixed_tag, -fill => $cw->{RefChart}{Mixed}{$mixed_tag}{color}, );

        my $element_type = $cw->type($mixed_tag);
        if ( $element_type =~ m{^polygon|oval|arc$} ) {
          $cw->itemconfigure( $mixed_tag, -outline => $cw->{RefChart}{Mixed}{$mixed_tag}{color}, );
        }

        # Allow value bar to display
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{BarValues}, -fill => 'black', );

        # area outline
        my $outlinearea = $cw->cget( -outlinearea );
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{Area}, -outline => $outlinearea, );

        # area outlinebar
        my $outlinebar = $cw->cget( -outlinebar );
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{Bar}, -outline => $outlinebar, );

      }
    );
  }

  return;
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

  if ( not defined $ref_legend or ref $ref_legend ne 'ARRAY' ) {
    $cw->_error(
      "Can't set -data in set_legend method. Bad data\nEg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  my @legend_option = qw / -box -legendmarkerheight -legendmarkerwidth -heighttitle /;

  foreach my $optionname (@legend_option) {
    if (  ( defined $info_legend{$optionname} )
      and ( !_isainteger( $info_legend{$optionname} ) ) )
    {
      $cw->_error(
        "'Can't set $optionname to "
          . "'$info_legend{$optionname}', $info_legend{$optionname}' isn't numeric",
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
  my $index_marker = 0;

  # initialisation of balloon message
  #$cw->{RefChart}->{Legend}{MsgBalloon} = {};
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

      # Marker type to display
      my $defaulttype = $cw->cget( -defaulttype );
      my $marker_type = $cw->cget( -typemixed )->[$index_legend] || $defaulttype;

      if ( $marker_type eq 'lines' or $marker_type eq 'dashlines' ) {
        my $y1       = $y2_cube - ( ( $y2_cube - $y1_cube ) / 2 );
        my $y2       = $y1;
        my $dashline = $cw->cget( -dashline );
        $dashline = $POINT if ( $marker_type eq 'dashlines' );

        $cw->createLine(
          $x1_cube, $y1, $x2_cube, $y2,
          -fill  => $line_color,
          -width => 4,
          -dash  => $dashline,
          -tags  => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        );
      }
      elsif ( $marker_type eq 'points' ) {
        my $markersize = $cw->cget( -markersize );
        my $markers    = $cw->cget( -markers );
        my $num_marker = $markers->[$index_marker];
        if ( not defined $num_marker ) {
          $index_marker = 0;
          $num_marker   = $markers->[$index_marker];
        }
        my $ref_type = $cw->_getmarkertype($num_marker);
        my %option;
        if ( $ref_type->[1] == 1 ) {
          $option{-fill} = $line_color;
        }
        if ( $num_marker =~ m{^[125678]$} ) {
          $option{-outline} = $line_color;
        }
        my $x = $x1_cube + ( ( $x2_cube - $x1_cube ) / 2 );
        my $y = $y1_cube + ( ( $y2_cube - $y1_cube ) / 2 );
        $option{-tags} = [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ];
        $cw->_createtype(
          x      => $x,
          y      => $y,
          pixel  => 10,
          type   => $ref_type->[0],
          option => \%option,
        );
        $index_marker++;
      }
      else {
        $cw->createRectangle(
          $x1_cube, $y1_cube, $x2_cube, $y2_cube,
          -fill    => $line_color,
          -outline => $line_color,
          -tags    => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        );
      }

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
      my $mixed_tag = $index_legend . $cw->{RefChart}->{TAGS}{Mixed};
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

  my $ref_typemixed = $cw->cget( -typemixed );
  my $defaulttype   = $cw->cget( -defaulttype );
  my $ref_data      = $cw->{RefChart}->{Data}{RefAllData};

  # number of value for x-axis
  $cw->{RefChart}->{Data}{xtickNumber} = $cw->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $cw->{RefChart}->{Axis}{Xaxis}{Width} / ( $cw->{RefChart}->{Data}{xtickNumber} + 1 );

  my $number_bar_data   = 1;    # Number of bar data
  my $number_point_data = 1;
  my $id_data           = 0;
  $cw->{Index}{Color}{Line} = 0;
  $cw->{Index}{Marker}{id}  = 0;

  my @cumulatey = (0) x scalar @{ $ref_data->[0] };

  # each list data
  foreach my $ref_array_data ( @{$ref_data} ) {

    # skipp legend
    if ( $id_data == 0 ) {
      $id_data++;
      next;
    }

    my $type = $ref_typemixed->[ $id_data - 1 ] || $defaulttype;
    if ( $type eq 'lines' ) {
      $cw->_viewdata_lines( $ref_array_data, $id_data );
    }
    elsif ( $type eq 'dashlines' ) {
      $cw->_viewdata_lines( $ref_array_data, $id_data, $POINT );    # . for dash
    }
    elsif ( $type eq 'bars' ) {
      $cw->_viewdata_bars( $ref_array_data, \@cumulatey, $number_bar_data, $id_data );
      $number_bar_data++;
    }
    elsif ( $type eq 'points' ) {
      $cw->_viewdata_points( $ref_array_data, $id_data );
      $number_point_data++;
    }
    elsif ( $type eq 'areas' ) {
      $cw->_viewdata_areas( $ref_array_data, $id_data );
    }
    else {
      $cw->_error( "Type '$type' unknown", 1 );
    }

    $id_data++;
  }

  return 1;
}

sub _viewdata_areas {
  my ( $cw, $ref_array_data, $id_data ) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $viewsection        = $cw->cget( -viewsection );
  my $outlinearea        = $cw->cget( -outlinearea );
  my $index_color        = $cw->{Index}{Color}{Line};
  my $line_color         = $legendmarkercolors->[$index_color];
  my $number_data        = 1;
  my $tag                = $id_data . $cw->{RefChart}->{TAGS}{Mixed};
  my $tag2               = $id_data . "_$number_data" . $cw->{RefChart}->{TAGS}{Mixed};
  $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag2} = $cw->{RefChart}->{Legend}{DataLegend}->[ $id_data - 1 ];
  my $tag_area = $cw->{RefChart}->{TAGS}{Area};

  my @pointsdata;    # coordinate x and y
  my @dash_points_xlines;

  # First point, in x-axis
  my $firstx
    = $cw->{RefChart}->{Axis}{Cx0} 
    + $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    - ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
  my $firsty = $cw->{RefChart}->{Axis}{Cy0};

  #update=
  if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
    $firsty -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
  }
  push @pointsdata, ( $firstx, $firsty );

  foreach my $data ( @{$ref_array_data} ) {
    if ( not defined $data ) {
      $number_data++;
      next;
    }

    # coordinates x and y values
    my $x
      = $cw->{RefChart}->{Axis}{Cx0} 
      + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
      - ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
    my $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

    #update=
    if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
      $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }

    push @pointsdata, ( $x, $y );

    push @dash_points_xlines, $x, $y;
    $number_data++;
  }

  # Last point, in x-axis
  my $lastx
    = $cw->{RefChart}->{Axis}{Cx0} 
    + ( $number_data - 1 ) * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    - ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );

  my $lasty = $cw->{RefChart}->{Axis}{Cy0};

  #update=
  if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
    $lasty -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
  }
  push @pointsdata, ( $lastx, $lasty );

  $cw->createPolygon(
    @pointsdata,
    -fill    => $line_color,
    -tags    => [ $tag, $tag2, $tag_area, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    -width   => $cw->cget( -linewidth ),
    -outline => $outlinearea,
  );

  # display Dash line
  if ( defined $viewsection and $viewsection == 1 ) {
    for ( my $i = 0; $i < scalar @dash_points_xlines; $i++ ) {
      my $index_x1 = $i;
      my $index_y1 = $i + 1;
      my $index_x2 = $i;
      $cw->createLine(
        $dash_points_xlines[$index_x1],
        $dash_points_xlines[$index_y1],
        $dash_points_xlines[$index_x2],
        $cw->{RefChart}->{Axis}{Cy0},
        -dash => $POINT,
        -tags =>
          [ $tag, $tag_area, $cw->{RefChart}->{TAGS}{DashLines}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      );
      $i++;
    }
  }

  # Display values above each points of lines
  my $line_number = $id_data - 1;
  $cw->_display_line( \@pointsdata, $line_number );

  $cw->{RefChart}{Line}{$tag}{color} = $line_color;

  $index_color++;
  $cw->{Index}{Color}{Line} = $index_color;
  $cw->{RefChart}{Mixed}{$tag}{color} = $line_color;

  return 1;
}

sub _viewdata_points {
  my ( $cw, $ref_array_data, $id_data ) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $markersize         = $cw->cget( -markersize );
  my $markers            = $cw->cget( -markers );
  my $index_color        = $cw->{Index}{Color}{Line};
  my $index_marker       = $cw->{Index}{Marker}{id};
  my $line_color         = $legendmarkercolors->[$index_color];
  my $num_marker         = $markers->[$index_marker] || $markers->[0];
  my $number_data        = 1;
  my $tag                = $id_data . $cw->{RefChart}->{TAGS}{Mixed};
  my $tag_point          = $cw->{RefChart}->{TAGS}{Point};

  $cw->{RefChart}{Point}{$tag}{color} = $line_color;

  my @pointsdata;    # coordinate x and y
  foreach my $data ( @{$ref_array_data} ) {
    if ( not defined $data ) {
      $number_data++;
      next;
    }

    # coordinates x and y values
    my $x
      = $cw->{RefChart}->{Axis}{Cx0} 
      + ( $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} )
      - ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
    my $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

    #update=
    if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
      $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }

    my $tag2 = $id_data . "_$number_data" . $cw->{RefChart}->{TAGS}{Mixed};
    $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag2} = $cw->{RefChart}->{Legend}{DataLegend}->[ $id_data - 1 ];

    my %option = (
      -tags  => [ $tag, $tag2, $tag_point, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      -width => $cw->cget( -linewidth ),
    );
    my $ref_type = $cw->_getmarkertype($num_marker);
    if ( $ref_type->[1] == 1 ) {
      $option{-fill} = $line_color;
    }
    if ( $num_marker =~ m{^[125678]$} ) {
      $option{-outline} = $line_color;
    }

    $cw->_createtype(
      x      => $x,
      y      => $y,
      pixel  => $markersize,
      type   => $ref_type->[0],
      option => \%option,
    );
    $number_data++;
    push @pointsdata, ( $x, $y );
  }

  # Display values above each points of lines
  my $line_number = $id_data - 1;
  $cw->_display_line( \@pointsdata, $line_number );

  $index_color++;
  $cw->{Index}{Color}{Line} = $index_color;
  $index_marker++;
  $cw->{Index}{Marker}{id} = $index_marker;
  $cw->{RefChart}{Mixed}{$tag}{color} = $line_color;

  return 1;
}

sub _viewdata_bars {
  my ( $cw, $ref_array_data, $ref_cumulatey, $number_bar_data, $id_data ) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $overwrite          = $cw->cget( -overwrite );
  my $cumulate           = $cw->cget( -cumulate );
  my $spacingbar         = $cw->cget( -spacingbar );
  my $showvalues         = $cw->cget( -showvalues );
  my $outlinebar         = $cw->cget( -outlinebar );
  my $barsvaluescolor    = $cw->cget( -barsvaluescolor );

  my $index_color = $cw->{Index}{Color}{Line};
  my $line_color  = $legendmarkercolors->[$index_color];
  my $number_data = 1;                                     # Number of data
  my $tag_bar     = $cw->{RefChart}->{TAGS}{Bar};

  my $width_bar
    = $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / $cw->{RefChart}->{Data}{NumberRealDataBars};

  foreach my $data ( @{$ref_array_data} ) {
    if ( not defined $data ) {
      push @{$ref_cumulatey}, 0;
      $number_data++;
      next;
    }

    my ( $x, $y, $x0, $y0 ) = ();
    if ( $overwrite == 1 or $cumulate == 1 ) {

      # coordinates x and y values
      $x = $cw->{RefChart}->{Axis}{Cx0} + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
      $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

      # coordinates x0 and y0 values
      $x0 = $x - $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
      $y0 = $cw->{RefChart}->{Axis}{Cy0};

      # cumulate bars
      if ( $cumulate == 1 ) {

        $y -= $ref_cumulatey->[ $number_data - 1 ];
        $y0 = $y + ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

        $ref_cumulatey->[ $number_data - 1 ] += ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      # space between bars
      if ( $spacingbar == 1 ) {
        $x -= $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 4;
        $x0 += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 4;
      }
    }

    # No overwrite
    else {
      $x
        = $cw->{RefChart}->{Axis}{Cx0} 
        + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
        - ( ( $cw->{RefChart}->{Data}{NumberRealDataBars} - $number_bar_data ) * $width_bar );
      $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

      #update=
      if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
        $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      # coordinates x0 and y0 values
      $x0 = $x - $width_bar;
      $y0 = $cw->{RefChart}->{Axis}{Cy0};

      # space between bars
      if ( $spacingbar == 1 ) {
        $x -= $width_bar / 4;
        $x0 += $width_bar / 4;
      }
    }

    #update=
    if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
      $y0 -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }

    my $tag  = $id_data . $cw->{RefChart}->{TAGS}{Mixed};
    my $tag2 = $id_data . "_$number_data" . $cw->{RefChart}->{TAGS}{Mixed};
    $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag2}
      = "Sample : $cw->{RefChart}->{Data}{RefAllData}->[0]->[$number_data-1]\n" . "Value : $data";

    $cw->createRectangle(
      $x0, $y0, $x, $y,
      -fill    => $line_color,
      -tags    => [ $tag, $tag2, $tag_bar, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      -width   => $cw->cget( -linewidth ),
      -outline => $outlinebar,
    );
    if ( $showvalues == 1 ) {
      $cw->createText(
        $x0 + ( $x - $x0 ) / 2,
        $y - 8,
        -text => $data,
        -font => $cw->{RefChart}->{Font}{DefaultBarValues},
        -tags =>
          [ $tag, $tag_bar, $cw->{RefChart}->{TAGS}{BarValues}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -fill => $barsvaluescolor,
      );
    }

    $cw->{RefChart}{Mixed}{$tag}{color} = $line_color;
    $number_data++;
  }

  $index_color++;
  $cw->{Index}{Color}{Line} = $index_color;
  return 1;
}

sub _viewdata_lines {
  my ( $cw, $ref_array_data, $id_data, $dash ) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $bezier             = $cw->cget( -bezier );
  my $spline             = $cw->cget( -spline );

  my $index_color = $cw->{Index}{Color}{Line};
  my $line_color  = $legendmarkercolors->[$index_color];
  my $number_data = 1;                                     # Number of data
  my $tag_line;
  if ( defined $dash ) {
    $tag_line = $cw->{RefChart}->{TAGS}{Line};
  }
  else {
    $tag_line = $cw->{RefChart}->{TAGS}{PointLine};
  }
  my $tag2 = $id_data . "_$number_data" . $cw->{RefChart}->{TAGS}{Mixed};
  $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag2} = $cw->{RefChart}->{Legend}{DataLegend}->[ $id_data - 1 ];

  my @pointsdata;                                          # coordinate x and y
  foreach my $data ( @{$ref_array_data} ) {
    if ( not defined $data ) {
      $number_data++;
      next;
    }

    # coordinates x and y values
    my $x = ( $cw->{RefChart}->{Axis}{Cx0} + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} )
      - ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
    my $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

    #update=
    if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
      $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }
    push @pointsdata, ( $x, $y );
    $number_data++;
  }

  my $tag = $id_data . $cw->{RefChart}->{TAGS}{Mixed};

  # Add control points
  my @points_data_without_controlpoints;
  if ( $spline == 1 and $bezier == 1 ) {
    @points_data_without_controlpoints = @pointsdata;
    my $ref_pointsdata = $cw->_get_controlpoints( \@pointsdata );
    @pointsdata = @{$ref_pointsdata};
  }

  $cw->createLine(
    @pointsdata,
    -fill   => $line_color,
    -tags   => [ $tag, $tag2, $tag_line, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    -width  => $cw->cget( -linewidth ),
    -smooth => $bezier,
    -dash   => $dash,
  );

  # Display values above each points of lines
  my $line_number = $id_data - 1;
  if (@points_data_without_controlpoints) {
    @pointsdata                        = @points_data_without_controlpoints;
    @points_data_without_controlpoints = ();
    undef @points_data_without_controlpoints;
  }

  if ( !( $spline == 0 and $bezier == 1 ) ) {
    $cw->_display_line( \@pointsdata, $line_number );
  }

  $cw->{RefChart}{Mixed}{$tag}{color} = $line_color;

  $index_color++;
  $cw->{Index}{Color}{Line} = $index_color;

  if ( $spline == 0 and $bezier == 1 and $cw->{RefChart}->{Data}{RefDataToDisplay} ) {
    $cw->_error('The values are not displayed because the curve crosses only by the extreme points.');
  }

  return 1;
}

sub display_order {
  my ( $cw, $ref_order ) = @_;

  if ( not defined $ref_order ) {
    $ref_order = $cw->{RefChart}->{Mixed}{DisplayOrder};
    if ( not defined $ref_order ) { return; }
  }

  my %tag = (
    areas     => $cw->{RefChart}->{TAGS}{Area},
    bars      => $cw->{RefChart}->{TAGS}{Bar},
    lines     => $cw->{RefChart}->{TAGS}{Line},
    dashlines => $cw->{RefChart}->{TAGS}{PointLine},
    points    => $cw->{RefChart}->{TAGS}{Point},
  );

  # Get order from user and store it
  my @order = grep { exists $tag{$_} } _delete_array_doublon($ref_order);

  # Ticks always in background
  $tag{AllTick} = $cw->{RefChart}->{TAGS}{AllTick};
  unshift @order, 'AllTick';

  # tag pile order
  for my $i ( 0 .. $#order ) {
    my $next = $i + 1;
    for ( $next .. $#order ) {
      my $test_tag_next = $cw->find( 'withtag', $tag{ $order[$next] } );
      my $test_tag_i    = $cw->find( 'withtag', $tag{ $order[$i] } );
      if ( $test_tag_next and $test_tag_i ) {
        $cw->raise( $tag{ $order[$next] }, $tag{ $order[$i] } );
      }
    }
  }
  return 1;
}

sub plot {
  my ( $cw, $ref_data, %option ) = @_;

  my $overwrite     = $cw->cget( -overwrite );
  my $cumulate      = $cw->cget( -cumulate );
  my $yticknumber   = $cw->cget( -yticknumber );
  my $ref_typemixed = $cw->cget( -typemixed );
  my $yminvalue     = $cw->cget( -yminvalue );
  my $ymaxvalue     = $cw->cget( -ymaxvalue );
  my $interval      = $cw->cget( -interval );

  if ( defined $option{-substitutionvalue}
    and _isanumber( $option{-substitutionvalue} ) )
  {
    $cw->{RefChart}->{Data}{SubstitutionValue} = $option{-substitutionvalue};
  }

  $cw->{RefChart}->{Data}{NumberRealDataBars} = 0;
  if ( defined $ref_typemixed ) {
    foreach my $type ( @{$ref_typemixed} ) {
      if ( defined $type and $type eq 'bars' ) {
        $cw->{RefChart}->{Data}{NumberRealDataBars}++;
      }
    }
  }

  # USe -defaulttype to calculated number of bar data
  elsif ( $cw->cget( -defaulttype ) eq 'bars' ) {
    $cw->{RefChart}->{Data}{NumberRealDataBars} = scalar @{$ref_data} - 1;
  }

  if ( not defined $ref_data ) {
    $cw->_error('data not defined');
    return;
  }

  if ( scalar @{$ref_data} <= 1 ) {
    $cw->_error('You must have at least 2 arrays');
    return;
  }

  # Check legend and data size
  if ( my $ref_legend = $cw->{RefChart}->{Legend}{DataLegend} ) {
    if ( !$cw->_checksizelegend_data( $ref_data, $ref_legend ) ) {
      undef $cw->{RefChart}->{Legend}{DataLegend};
    }
  }

  # Check array size
  $cw->{RefChart}->{Data}{NumberXValues} = scalar @{ $ref_data->[0] };
  my $i         = 0;
  my @arraytemp = (0) x scalar @{ $ref_data->[0] };
  foreach my $ref_array ( @{$ref_data} ) {
    if ( scalar @{$ref_array} != $cw->{RefChart}->{Data}{NumberXValues} ) {
      $cw->_error( 'Make sure that every array has the ' . 'same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      my $j = 0;
      foreach my $data ( @{$ref_array} ) {
        if ( ( defined $data ) and ( !_isanumber($data) ) ) {
          $data = $cw->{RefChart}->{Data}{SubstitutionValue};
        }
        elsif ( defined $data ) {
          $arraytemp[$j] += $data;    # For cumulate option
        }
        $j++;
      }
      $cw->{RefChart}->{Data}{MaxYValue}
        = _maxarray( [ $cw->{RefChart}->{Data}{MaxYValue}, _maxarray($ref_array) ] );
      $cw->{RefChart}->{Data}{MinYValue}
        = _minarray( [ $cw->{RefChart}->{Data}{MinYValue}, _minarray($ref_array) ] );
    }
    $i++;
  }

  $cw->{RefChart}->{Data}{RefXLegend} = $ref_data->[0];
  $cw->{RefChart}->{Data}{RefAllData} = $ref_data;

  if ( $cumulate == 1 ) {
    $cw->{RefChart}->{Data}{MaxYValue} = _maxarray( \@arraytemp );
    $cw->{RefChart}->{Data}{MinYValue} = _minarray( \@arraytemp );
  }

  $cw->_manage_minmaxvalues( $yticknumber, $cumulate );

  # Plotting ok
  $cw->{RefChart}->{Data}{PlotDefined} = 1;
  $cw->_chartconstruction;

  return 1;
}

1;
__END__


=head1 NAME

Tk::Chart::Mixed - Extension of Canvas widget to create mixed graph. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Mixed;
  
  my $mw = MainWindow->new(
    -title      => 'Tk::Chart::Mixed',
    -background => 'white',
  );
  
  my @types = ( 'areas', 'bars', 'lines', 'points', 'bars', 'dashlines' );
  my $chart = $mw->Mixed(
    -title      => 'Tk::Chart::Mixed',
    -xlabel     => 'X Label',
    -ylabel     => 'Y Label',
    -background => '#D0D0FF',
    -linewidth  => 2,
    -typemixed  => \@types,
    -markers    => [ 3, 5, 6 ],
  
    -longticks => 1,
  )->pack(qw / -fill both -expand 1 /);
  
  my @data = (
    [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
    [ 90,    29,    25,    6,     -20,   1,     1,     3,     4 ],
    [ 15,    10,    5,     2,     3,     5,     7,     9,     12 ],
    [ 1,     2,     12,    6,     3,     5,     1,     23,    5 ],
    [ 15,    12,    24,    33,    19,    8,     6,     15,    21 ],
    [ 15,    2,     52,    6,     3,     17.5,  1,     43,    10 ],
    [ 30,    2,     5,     6,     3,     1.5,   1,     3,     4 ],
    [ 24,    12,    35,    20,    13,    31.5,  41,    6,     25 ],
  
  );
  
  # Add a legend to the graph
  my @legends = @types;
  $chart->set_legend(
    -title       => "Title legend",
    -data        => [ 'legend 1', 'legend 2', 'legend 3', 'legend 4', 'legend 5', 'legend 6', 'legend 7', ],
    -titlecolors => "blue",
  );
  
  # Add help identification
  $chart->set_balloon();
  
  # Create the graph
  $chart->plot( \@data );
  
  # background order wanted
  $chart->display_order( [qw/ areas lines bars  dashlines points /] );
  
  MainLoop();

=head1 DESCRIPTION

Tk::Chart::Mixed is an extension of the Canvas widget. It is an easy way to build an 
interactive graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

In the same graph, you can create lines, bars, areas, line points, points.
You can change the color, font of title, labels (x and y) of the graph.
You can set an interactive legend.  
The axes can be automatically scaled or set by the code. 

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

=item Name:	B<Typemixed>

=item Class:	B<TypeMixed>

=item Switch:	B<-typemixed>

This controls the graph types to display in the same order as data set. This should be a reference to an array of graph types.

The different types are : B<areas>, B<bars>, B<lines>, B<dashlines> and B<points>

 -typemixed => [ 'areas', 'bars', 'lines' ]
 -typemixed => [ 'lines',  undef, 'areas' ]

values that are undefined will be set to -defaulttype option.

Default : B<undef>

=item Name:	B<Defaulttype>

=item Class:  B<DefaultType>

=item Switch: B<-defaulttype>

The type of graph to draw for data sets that either have no type set, or that have undef type set.

The different types are : B<areas>, B<bars>, B<lines>, B<dashlines> or B<points>

 -defaulttype => 'bars',

Default : B<'lines'>

=back


=head1 WIDGET-SPECIFIC OPTIONS like Tk::Chart::Points

These options are specific to point lines graph creation.

=over 4

=item Name:	B<Pointline>

=item Class:	B<PointLine>

=item Switch:	B<-pointline>

Set a true value to create point lines graph.  

 -pointline => 1, # 0 or 1

Default : B<0>

=item Name:	B<Markersize>

=item Class:	B<MarkerSize>

=item Switch:	B<-markersize>

The size of the markers used in points graphs, in pixels. 

 -markersize => 10, # integer

Default : B<8>

=item Name:	B<Markers>

=item Class:	B<Markers>

=item Switch:	B<-markers>

This controls the order of markers in points graphs. 
This should be a reference to an array of numbers:

 -markers => [3, 5, 6],

  Available markers are: 
  
  1:  filled square 
  2:  open square 
  3:  horizontal cross
  4:  diagonal cross
  5:  filled diamond
  6:  open diamond
  7:  filled circle
  8:  open circle
  9:  horizontal line
  10: vertical line

Default : B<[1,2,3,4,5,6,7,8]>
Note that the last two are not part of the default list.

=back


=head1 WIDGET-SPECIFIC OPTIONS for graphs with axes.

See L<Tk::Chart::Lines/"WIDGET-SPECIFIC OPTIONS">

=head1 WIDGET-SPECIFIC OPTIONS like Tk::Chart::Spline

=over 4

=item Name:	B<Bezier>

=item Class:	B<Bezier>

=item Switch:	B<-bezier>

To create lines graph as BE<eacute>zier curve. The curve crosses only by the 
extreme points (the first and the last).

 -bezier => 1, # 0 or 1

Default : B<0>

=item Name:	B<Spline>

=item Class:	B<Spline>

=item Switch:	B<-spline>

To create lines graph as BE<eacute>zier curve. The curve crosses by all points. 
The B<-bezier> option has to be set to B<1>.
 
 -spline => 1, # 0 or 1

Default : B<0>

=back

=head1 WIDGET-SPECIFIC OPTIONS like Tk::Chart::Bars

=over 4

=item Name:	B<Overwrite>

=item Class:	B<OverWrite>

=item Switch:	B<-overwrite>

If set to 0, bars of different data sets will be drawn next to each other. 
If set to 1, they will be drawn in front of each other.

 -overwrite => 1, # 0 or 1

Default : B<0>

=item Name:	B<Cumulate>

=item Class:	B<Cumulate>

=item Switch:	B<-cumulate>

If this attribute is set to a true value, the data sets will be cumulated. 
This means that they will be stacked on top of each other. 

A side effect of this is that overwrite will be set to a true value.

If you have negative values in your data sets, setting this option might 
produce odd results. Of course, the graph itself would be quite meaningless.

 -cumulate => 1, # 0 or 1

Default : B<0>

=item Name:	B<Showvalues>

=item Class:	B<ShowValues>

=item Switch:	B<-showvalues>

Set this to 1 to display the value of each data point above the point or bar itself. 
No effort is being made to ensure that there is enough space for the text.

If -overwrite or -cumulate set to 1, some text value could be hide by bars.

 -showvalues => 0, # 0 or 1

Default : B<1>

=item Name:	B<Spacingbar>

=item Class:	B<SpacingBar>

=item Switch:	B<-spacingbar>

Set this to 1 to display remove space between each bar. 

 -spacingbar => 0, # 0 or 1

Default : B<1>

=item Name:	B<Outlinebar>

=item Class:	B<OutlineBar>

=item Switch:	B<-outlinebar>

Change color of border bars.

  -outlinebar => 'blue',

Default : B<'black'>

=back

=head1 WIDGET-SPECIFIC OPTIONS like Tk::Chart::Areas

=over 4

=item Name:	B<Viewsection>

=item Class:	B<ViewSection>

=item Switch:	B<-viewsection>

If set to true value, we will see area sections separate by dash lines.

 -viewsection => 1, # 0 or 1

Default : B<0>

=item Name:	B<Outlinearea>

=item Class:	B<OutlineArea>

=item Switch:	B<-outlinearea>

Change color of border area.

  -outlinearea => 'blue',

Default : B<'black'>

=back

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 add_data

=over 4

=item I<$chart>->B<add_data>(I<\@NewData, ?$legend>)

This method allows you to add data in your graph. If you have already plot data using plot method and 
if you want to add new data, you can use this method.
Your graph will be updade.

=back

=over 8

=item *

I<Data array reference>

Fill an array of arrays with the values of the datasets (I<\@data>). 
Make sure that every array has the same size, otherwise Tk::Chart::Lines 
will complain and refuse to compile the graph.

 my @NewData = (1,10,12,5,4);
 $chart->add_data(\@NewData);

If your last graph has a legend, you have to add a legend entry for the new dataset. Otherwise, 
the legend graph will not be display (see below).

=item *

I<$legend>

 my @NewData = (1,10,12,5,4);
 my $legend = 'New data set';
 $chart->add_data(\@NewData, $legend);

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

If you call this method, you disable help identification which has been enabled with set_balloon method.

=back

=head2 disabled_automatic_redraw

=over 4

=item I<$chart>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $chart->disabled_automatic_redraw;  

=back

=head2 display_order

=over 4

=item I<$chart>->B<display_order>(I<?\@types>)

Manage the display order of the various graphs.

  $chart->display_order( [qw/ bars areas lines dashlines points /] );

In this example, the bars will be in the background, followed by areas, lines, dashlines and points.

  $chart->display_order; # Default configuration

Default : B<[qw/ areas bars lines dashlines points /]> 

=back

=head2 display_values

=over 4

=item I<$chart>->B<display_values>(I<\@data_point_value>)

To plot the value of data near the point (Line, Spline, Point, Area graph), call this method to control in a generic manner.

  my @data_point_value = (
    [ 9,   2,   5,     6,   3,   1,   1,   3,   4 ],        # The first line data
    undef,                                                  # The second line data
    [ 'A', 'B', undef, 'D', 'E', 'F', 'G', 'H', undef ],    # The third line data
  );
  $chart->display_values( \@data_point_value );

In this example, values are added above each point of the first and third graph. 
The second line is undef, no values are printed in the graph. 
B value is printed above the second point of the third line data.

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
Make sure that every array have the same size, otherwise Tk::Chart::Mixed 
will complain and refuse to compile the graph.

 my @data = (
     [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
     [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4  ],
     [ 4,     2,     5,     2,     3,     5.5,   7,     9,     4  ],
     [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
 );

@data have to contain a least two arrays, the x values and the values of the datasets.

If you don't have a value for a point in a dataset, you can use undef, 
and the point will be skipped.

 [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


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
Tk::Chart::Mixed supports the configure and cget methods described in the L<Tk::options> manpage.
If you use configure method to change a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, call B<redraw> method to 
resolv the bug.

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
the line and its entry will be turn into a color (that you can change) to help the identification. 
B<set_legend> method must be set if you want to enabled identification.

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
the color of the line when mouse cursor passes over a entry in the legend. If the line 
has the same color, the second color will be used.

 -colordatamouse => ['blue', 'green'],

Default : -colordatamouse => B<[ '#7F9010', '#CB89D3' ]>

=item *

=back

=head2 set_legend

=over 4

=item I<$chart>->B<set_legend>(I<? %options>)

View a legend for the graph and allow to enabled identification help by using B<set_balloon> method.

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

    perldoc Tk::Chart::Mixed


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
