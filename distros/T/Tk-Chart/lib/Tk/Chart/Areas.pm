package Tk::Chart::Areas;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 21/10/2011 22:26:01                                $
# $AIM       : Create area graph                                  $
#==================================================================

use vars qw($VERSION);
$VERSION = '1.05';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES :DISPLAY /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Areas';

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

    -viewsection => [ 'PASSIVE', 'Viewsection', 'ViewSection', 1 ],
    -outlinearea => [ 'PASSIVE', 'Outlinearea', 'OutlineArea', 'black' ],
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
  if ( ! $cw->{RefChart}->{Legend}{NbrLegend} ) {
    return;
  }

  # bind legend and lines
  for my $index_legend ( 1 .. $cw->{RefChart}->{Legend}{NbrLegend} ) {

    my $legend_tag = $index_legend . $cw->{RefChart}->{TAGS}{Legend};
    my $linetag    = $index_legend . $cw->{RefChart}->{TAGS}{Line};

    $cw->bind(
      $legend_tag,
      '<Enter>',
      sub {
        my $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[0];

        # Change color if line have the same color
        if ( $other_color eq $cw->{RefChart}{Line}{$linetag}{color} ) {
          $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[1];
        }
        $cw->itemconfigure(
          $linetag,
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
          $linetag,
          -fill  => $cw->{RefChart}{Line}{$linetag}{color},
          -width => $cw->cget( -linewidth )
        );

        # Allow dash line to display
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{DashLines}, -fill => 'black', );
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
      "Can't set -data in set_legend method. May be you forgot to set the value\nEx : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  if ( !( defined $ref_legend and ref $ref_legend eq 'ARRAY' ) ) {
    $cw->_error(
      "Can't set -data in set_legend method. Bad data\nEx : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  if ( defined $info_legend{-title} ) {
    $cw->{RefChart}->{Legend}{title} = $info_legend{-title};
  }
  else {
    undef $cw->{RefChart}->{Legend}{title};
    $cw->{RefChart}->{Legend}{HeightTitle} = 5;
  }
  $cw->{RefChart}->{Legend}{titlefont} = $info_legend{-titlefont}
    || $cw->{RefChart}->{Font}{DefaultLegendTitle};
  $cw->{RefChart}->{Legend}{legendfont} = $info_legend{-legendfont}
    || $cw->{RefChart}->{Font}{DefaultLegendTitle};

  if ( _isainteger( $info_legend{-box} ) ) {
    $cw->{RefChart}->{Legend}{box} = $info_legend{-box};
  }
  if ( defined $info_legend{-titlecolors} ) {
    $cw->{RefChart}->{Legend}{titlecolors} = $info_legend{-titlecolors};
  }

  # text color
  if ( defined $info_legend{-legendcolor} ) {
    $cw->{RefChart}->{Legend}{legendcolor} = $info_legend{-legendcolor};
  }

  if ( _isainteger( $info_legend{-legendmarkerheight} ) ) {
    $cw->{RefChart}->{Legend}{HCube} = $info_legend{-legendmarkerheight};
  }
  if ( _isainteger( $info_legend{-legendmarkerwidth} ) ) {
    $cw->{RefChart}->{Legend}{WCube} = $info_legend{-legendmarkerwidth};
  }
  if ( _isainteger( $info_legend{-heighttitle} ) ) {
    $cw->{RefChart}->{Legend}{HeightTitle} = $info_legend{-heighttitle};
  }

  # Check legend and data size
  if ( my $ref_data = $cw->{RefChart}->{Data}{RefAllData} ) {
    $cw->_checksizelegend_data( $ref_data, $ref_legend );
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
    = +$cw->{RefChart}->{Legend}{SpaceBeforeCube}    # space between legend
    + $cw->{RefChart}->{Legend}{WCube}               # Cube (width)
    + $cw->{RefChart}->{Legend}{SpaceAfterCube}      # space after cube
    + $cw->{RefChart}->{Legend}{WidthText}           # length of legend text
    ;

  # Number of legends per line
  $cw->{RefChart}->{Legend}{NbrPerLine}
    = int( $cw->{RefChart}->{Axis}{Xaxis}{Width} / $cw->{RefChart}->{Legend}{LengthOneLegend} );
  if ( $cw->{RefChart}->{Legend}{NbrPerLine} == 0 ) { $cw->{RefChart}->{Legend}{NbrPerLine} = 1; }

  # How many legend we will have
  $cw->{RefChart}->{Legend}{NbrLegend} = scalar @{ $cw->{RefChart}->{Data}{RefAllData} } - 1;

=for NumberLines
  We calculate the number of lines set for the legend graph.
  If wa can set 11 legends per line, then for 3 legend, we will need one line
  and for 12 legends, we will need 2 lines
  If NbrLeg / NbrPerLine = integer => get number of lines
  If NbrLeg / NbrPerLine = float => int(float) + 1 = get number of lines

=cut

  $cw->{RefChart}->{Legend}{NbrLine}
    = $cw->{RefChart}->{Legend}{NbrLegend} / $cw->{RefChart}->{Legend}{NbrPerLine};
  if ( int( $cw->{RefChart}->{Legend}{NbrLine} ) != $cw->{RefChart}->{Legend}{NbrLine} ) {
    $cw->{RefChart}->{Legend}{NbrLine} = int( $cw->{RefChart}->{Legend}{NbrLine} ) + 1;
  }

  # Total Height of Legend
  $cw->{RefChart}->{Legend}{Height} = $cw->{RefChart}->{Legend}{HeightTitle}    # Hauteur Titre légende
    + $cw->{RefChart}->{Legend}{NbrLine} * $cw->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  if ( $cw->{RefChart}->{Legend}{NbrLegend} < $cw->{RefChart}->{Legend}{NbrPerLine} ) {
    $cw->{RefChart}->{Legend}{NbrPerLine} = $cw->{RefChart}->{Legend}{NbrLegend};
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
  $cw->{RefChart}->{Legend}{GetIdLeg} = {};

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
    my $y2_cube     = $y1_cube - $cw->{RefChart}->{Legend}{HCube};
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
      $cw->{RefChart}->{Legend}{GetIdLeg}{$tag} = $index_legend;
      $cw->{RefChart}->{Legend}{GetIdLeg}{$tag} = $index_legend;

      $index_color++;
      $index_legend++;

      # cube
      $x1_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};
      $x2_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xtext += $cw->{RefChart}->{Legend}{LengthOneLegend};

      my $linetag = $index_legend . $cw->{RefChart}->{TAGS}{Line};
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag}     = $legend;
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$linetag} = $legend;

      if ( $index_legend == $cw->{RefChart}->{Legend}{NbrLegend} ) {
        last LEGEND;
      }
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
  if ( $cw->{RefChart}->{Legend}{DataLegend} ) {
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
  $cw->{RefChart}->{Axis}{CxMax}               # Coordonnées CxMax
    = $cw->{RefChart}->{Axis}{CxMin}           # Coordonnées CxMin
    + $cw->{RefChart}->{Axis}{Xaxis}{Width}    # Largeur axe x
    ;

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
  $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} = $cw->{RefChart}->{Axis}{Yaxis}{Height}
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
  my $xtickx1 = $cw->{RefChart}->{Axis}{CxMin};
  my $xticky1 = $cw->{RefChart}->{Axis}{CyMin};

  # x coordinates y ticks on 0,0 x-axis if the graph have only y value < 0
  if (  $cw->cget( -zeroaxisonly ) == 1
    and $cw->{RefChart}->{Data}{MaxYValue} > 0 )
  {
    $xticky1 = $cw->{RefChart}->{Axis}{Cy0};
  }

  my $xtickx2 = $xtickx1;
  my $xticky2 = $xticky1 + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight};

  # Coordinates of x values (first value)
  my $xtick_xvalue = $cw->{RefChart}->{Axis}{CxMin};
  my $xtick_yvalue = $xticky2 + ( $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} / 2 );
  my $nbr_leg       = scalar @{ $cw->{RefChart}->{Data}{RefXLegend} };

  my $xlabelskip = $cw->cget( -xlabelskip );

  # index of tick and vlaues that will be skip
  my %indice_skip;
  if ( defined $xlabelskip ) {
    for ( my $i = 1; $i <= $nbr_leg; $i++ ) {
      $indice_skip{$i} = 1;
      $i += $xlabelskip;
    }
  }

  for my $indice ( 1 .. $nbr_leg ) {
    my $data = $cw->{RefChart}->{Data}{RefXLegend}->[ $indice - 1 ];

    # tick
    $xtickx1 += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    $xtickx2 = $xtickx1;

    # tick legend
    $xtick_xvalue += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    my $regex_xtickselect = $cw->cget( -xvaluesregex );

    if ( $data =~ m{$regex_xtickselect} ) {
     if ( not defined $indice_skip{$indice} ) {
            $xtick_xvalue += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
            next;
      }

      # Display xticks short or long
      $cw->_display_xticks( $xtickx1, $xticky1, $xtickx2, $xticky2 );

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
  }

  return;
}

sub _viewdata {
  my ($cw) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $viewsection        = $cw->cget( -viewsection );
  my $outlinearea        = $cw->cget( -outlinearea );

  my $tag_area = $cw->{RefChart}->{TAGS}{Area};

  # number of value for x-axis
  $cw->{RefChart}->{Data}{xtickNumber} = $cw->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $cw->{RefChart}->{Axis}{Xaxis}{Width} / ( $cw->{RefChart}->{Data}{xtickNumber} + 1 );

  my $id_data     = 0;
  my $index_color = 0;
  foreach my $ref_array_data ( @{ $cw->{RefChart}->{Data}{RefAllData} } ) {
    if ( $id_data == 0 ) {
      $id_data++;
      next;
    }
    my $number_data = 1;    # Number of data
    my @points_data;        # coordinate x and y
    my @dash_points_xlines;

    # First point, in x-axis
    my $fisrtx = $cw->{RefChart}->{Axis}{Cx0} + $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    my $fisrty = $cw->{RefChart}->{Axis}{Cy0};

    #update=
    if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
      $fisrty -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }

    push @points_data, ( $fisrtx, $fisrty );

    foreach my $data ( @{$ref_array_data} ) {
      if ( not defined $data ) {
        $number_data++;
        next;
      }

      # coordinates x and y values
      my $x = $cw->{RefChart}->{Axis}{Cx0} + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
      my $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

      #update=
      if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
        $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      push @points_data, ( $x, $y );

      push @dash_points_xlines, $x, $y;
      $number_data++;

    }

    # Last point, in x-axis
    my $lastx = $cw->{RefChart}->{Axis}{Cx0}
      + ( $number_data - 1 ) * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};

    my $lasty = $cw->{RefChart}->{Axis}{Cy0};

    #update=
    if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
      $lasty -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
    }
    push @points_data, ( $lastx, $lasty );

    my $line_color = $legendmarkercolors->[$index_color];
    if ( not defined $line_color ) {
      $index_color = 0;
      $line_color  = $legendmarkercolors->[$index_color];
    }
    my $tag = $id_data . $cw->{RefChart}->{TAGS}{Line};

    $cw->createPolygon(
      @points_data,
      -fill  => $line_color,
      -tags  => [ $tag_area, $tag, $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      -width => $cw->cget( -linewidth ),
      -outline => $outlinearea,
    );

    # display Dash line
    if ( defined $viewsection and $viewsection == 1 ) {

      # remove first and last points
      for ( 1 .. 2 ) {
        shift @dash_points_xlines;
        pop @dash_points_xlines;
      }

      for ( my $i = 0; $i < scalar(@dash_points_xlines); $i++ ) {
        my $index_x1 = $i;
        my $index_y1 = $i + 1;
        my $index_x2 = $i;
        $cw->createLine(
          $dash_points_xlines[$index_x1],
          $dash_points_xlines[$index_y1],
          $dash_points_xlines[$index_x2],
          $lasty,
          -dash  => $POINT,
          -width => $cw->cget( -linewidth ),
          -tags  => [
            $tag,                               $cw->{RefChart}->{TAGS}{AllData},
            $cw->{RefChart}->{TAGS}{DashLines}, $cw->{RefChart}->{TAGS}{AllTagsChart},
          ],
        );
        $i++;
      }
    }

    # Display values above each points of lines
    my $line_number = $id_data - 1;
    $cw->_display_line( \@points_data, $line_number );

    $cw->{RefChart}{Line}{$tag}{color} = $line_color;

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
    $cw->_checksizelegend_data( $ref_data, $ref_legend );
  }

  # Check array size
  $cw->{RefChart}->{Data}{NumberXValues} = scalar @{ $ref_data->[0] };
  my $i = 0;
  foreach my $ref_array ( @{$ref_data} ) {
    if ( scalar @{$ref_array} != $cw->{RefChart}->{Data}{NumberXValues} ) {
      $cw->_error( 'Make sure that every array has the same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      foreach my $data ( @{$ref_array} ) {
        if ( ( defined $data ) and ( !_isanumber($data) ) ) {
          $data = $cw->{RefChart}->{Data}{SubstitutionValue};
        }
      }

      $cw->{RefChart}->{Data}{MaxYValue}
        = _maxarray( [ $cw->{RefChart}->{Data}{MaxYValue}, _maxarray($ref_array) ] );
      $cw->{RefChart}->{Data}{MinYValue}
        = _minarray( [ $cw->{RefChart}->{Data}{MinYValue}, _minarray($ref_array) ] );
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

Tk::Chart::Areas - Extension of Canvas widget to create area lines graph. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Areas;

  my $mw = MainWindow->new(
    -title      => 'Tk::Chart::Areas example',
    -background => 'white',
  );

  my $chart = $mw->Areas(
    -title  => 'My Area graph title',
    -xlabel => 'X Label',
    -ylabel => 'Y Label',
    -linewidth => 1,

  )->pack(qw / -fill both -expand 1 /);

  my @data = ( 
      ['1st','2nd','3rd','4th','5th','6th','7th', '8th', '9th'],
      [    5,   12,   24,   33,   19,    8,    6,    15,    21],
      [   -1,   -2,   -5,   -6,   -3,  1.5,    1,   1.3,     2]
  );

  # Add a legend to the graph
  my @Legends = ( 'legend 1', 'legend 2', );
  $chart->set_legend(
    -title       => 'Title legend',
    -data        => \@Legends,
    -titlecolors => 'blue',
  );

  # Add help identification
  $chart->set_balloon();

  # Create the graph
  $chart->plot( \@data );

  MainLoop();

=head1 DESCRIPTION

Tk::Chart::Areas is an extension of the Canvas widget. It is an easy way to build an 
interactive Area line graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

You can change the color, font of title, labels (x and y) of the graph.
You can set an interactive legend.  
The axes can be automatically scaled or set by the code. 
With this module it is possible to plot quantitative variables according to qualitative variables.

When the mouse cursor passes over a plotted line or its entry in the legend, 
the line and its entry will be turned to a color (that you can change) to help identify it. 

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

=item Name:	B<Viewsection>

=item Class:	B<ViewSection>

=item Switch:	B<-viewsection>

If set to true value, we will see area sections separate by dash lines.

 -viewsection => 0, # 0 or 1

Default : B<1>

=item Name:	B<Outlinearea>

=item Class:	B<OutlineArea>

=item Switch:	B<-outlinearea>

Change color of border areas.

  -outlinearea => 'blue',

Default : B<'black'>

=back

=head1 WIDGET-SPECIFIC OPTIONS for graphs with axes.

See L<Tk::Chart::Lines/"WIDGET-SPECIFIC OPTIONS">

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

=head2 display_values

=over 4

=item I<$chart>->B<display_values>(I<\@data_point_value>)

To plot the value of data near the points area graph, call this method to control in a generic manner.

  my @data_point_value = (
    [ 9,   2,   5,     6,   3,   1,   1,   3,   4 ],        # The first line data
    undef,                                                  # The second line data
    [ 'A', 'B', undef, 'D', 'E', 'F', 'G', 'H', undef ],    # The third line data
  );
  $chart->display_values( \@data_point_value );

In this example, values are added above each point of the first and third lines. 
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
Make sure that every array have the same size, otherwise Tk::Chart::Areas 
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

-substitutionvalue have to be a real number (ex : 12, .25, 02.25, 5.2e+11, etc ...) 
  

=back

=over 8

=item *

I<\@data_to_display>

Fill an array of arrays with the values of the data to display (I<\@data_to_display>). 

  my @data_to_display = (
    [ 10, 30, 20, 30, 5, 41, 1, 23 ],
    [ 'A', 'B',    'C', 'D', 'E', 5.5,  'F', 'G', 4 ],
    [ 4,   'CPAN', 52,  6,   3,   17.5, 1,   43,  10 ]
  );

If you does not want to display a value for a point, you can use undef, 
and the point value will be skipped.

 [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


=item *

-foreground => I<color>,

Set color of text value.

Default : B<black>

=item *

-font => I<string>,

Set the font to text value.

  -font  => 'Times 12 {bold}', 

=back

=head2 redraw

Redraw the graph. 

If you have used clearchart for any reason, it is possible to redraw the graph.
Tk::Chart::Areas supports the configure and cget methods described in the L<Tk::options> manpage.
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

=item I<$chart>->B<set_balloon>(I<? %Options>)

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
the color of the line when mouse cursor passes over an entry in the legend. If the line 
has the same color, the second color will be used.

 -colordatamouse => ['blue', 'green'],

Default : -colordatamouse => B<[ '#7F9010', '#CB89D3' ]>

=item *

-morepixelselected => I<integer>

When the mouse cursor passes over an entry in the legend, 
the line width increase. 

 -morepixelselected => 5,

Default : B<2>


=back

=head2 set_legend

=over 4

=item I<$chart>->B<set_legend>(I<? %Options>)

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

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-Chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Areas


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
