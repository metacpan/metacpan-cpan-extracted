package Tk::ForDummies::Graph::Boxplots;

use warnings;
use strict;
use Carp;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 19/06/2010 22:47:22
# AIM       : Create bars graph
#==================================================================

use vars qw($VERSION);
$VERSION = '1.06';

use base qw/Tk::Derived Tk::Canvas::GradientColor/;
use Tk::Balloon;

use Tk::ForDummies::Graph::Utils qw (:DUMMIES);
use Tk::ForDummies::Graph qw (:DUMMIES);

Construct Tk::Widget 'Boxplots';

sub Populate {

  my ( $CompositeWidget, $RefParameters ) = @_;

  # Get initial parameters
  $CompositeWidget->{RefInfoDummies} = _InitConfig();

  $CompositeWidget->SUPER::Populate($RefParameters);

  $CompositeWidget->Advertise( 'GradientColor' => $CompositeWidget );
  $CompositeWidget->Advertise( 'canvas'        => $CompositeWidget->SUPER::Canvas );
  $CompositeWidget->Advertise( 'Canvas'        => $CompositeWidget->SUPER::Canvas );

  # remove highlightthickness if necessary
  unless ( exists $RefParameters->{-highlightthickness} ) {
    $CompositeWidget->configure( -highlightthickness => 0 );
  }

  $CompositeWidget->ConfigSpecs(
    -title      => [ 'PASSIVE', 'Title',      'Title',      undef ],
    -titlecolor => [ 'PASSIVE', 'Titlecolor', 'TitleColor', 'black' ],
    -titlefont =>
      [ 'PASSIVE', 'Titlefont', 'TitleFont', $CompositeWidget->{RefInfoDummies}->{Font}{DefaultTitle} ],
    -titleposition => [ 'PASSIVE', 'Titleposition', 'TitlePosition', 'center' ],
    -titleheight =>
      [ 'PASSIVE', 'Titleheight', 'TitleHeight', $CompositeWidget->{RefInfoDummies}->{Title}{Height} ],

    -xlabel      => [ 'PASSIVE', 'Xlabel',      'XLabel',      undef ],
    -xlabelcolor => [ 'PASSIVE', 'Xlabelcolor', 'XLabelColor', 'black' ],
    -xlabelfont =>
      [ 'PASSIVE', 'Xlabelfont', 'XLabelFont', $CompositeWidget->{RefInfoDummies}->{Font}{DefaultLabel} ],
    -xlabelposition => [ 'PASSIVE', 'Xlabelposition', 'XLabelPosition', 'center' ],
    -xlabelheight   => [
      'PASSIVE',      'Xlabelheight',
      'XLabelHeight', $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight}
    ],
    -xlabelskip => [ 'PASSIVE', 'Xlabelskip', 'XLabelSkip', 0 ],

    -xvaluecolor    => [ 'PASSIVE', 'Xvaluecolor',    'XValueColor',    'black' ],
    -xvaluevertical => [ 'PASSIVE', 'Xvaluevertical', 'XValueVertical', 0 ],
    -xvaluespace    => [
      'PASSIVE',     'Xvaluespace',
      'XValueSpace', $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight}
    ],
    -xvalueview   => [ 'PASSIVE', 'Xvalueview',   'XValueView',   1 ],
    -yvalueview   => [ 'PASSIVE', 'Yvalueview',   'YValueView',   1 ],
    -xvaluesregex => [ 'PASSIVE', 'Xvaluesregex', 'XValuesRegex', qr/.+/ ],

    -ylabel      => [ 'PASSIVE', 'Ylabel',      'YLabel',      undef ],
    -ylabelcolor => [ 'PASSIVE', 'Ylabelcolor', 'YLabelColor', 'black' ],
    -ylabelfont =>
      [ 'PASSIVE', 'Ylabelfont', 'YLabelFont', $CompositeWidget->{RefInfoDummies}->{Font}{DefaultLabel} ],
    -ylabelposition => [ 'PASSIVE', 'Ylabelposition', 'YLabelPosition', 'center' ],
    -ylabelwidth    => [
      'PASSIVE',     'Ylabelwidth',
      'YLabelWidth', $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth}
    ],

    -yvaluecolor => [ 'PASSIVE', 'Yvaluecolor', 'YValueColor', 'black' ],

    -labelscolor => [ 'PASSIVE', 'Labelscolor', 'LabelsColor', undef ],
    -valuescolor => [ 'PASSIVE', 'Valuescolor', 'ValuesColor', undef ],
    -textcolor   => [ 'PASSIVE', 'Textcolor',   'TextColor',   undef ],
    -textfont    => [ 'PASSIVE', 'Textfont',    'TextFont',    undef ],

    -boxaxis      => [ 'PASSIVE', 'Boxaxis',      'BoxAxis',      0 ],
    -noaxis       => [ 'PASSIVE', 'Noaxis',       'NoAxis',       0 ],
    -zeroaxisonly => [ 'PASSIVE', 'Zeroaxisonly', 'ZeroAxisOnly', 0 ],
    -zeroaxis     => [ 'PASSIVE', 'Zeroaxis',     'ZeroAxis',     0 ],
    -longticks    => [ 'PASSIVE', 'Longticks',    'LongTicks',    0 ],

    -xtickheight => [
      'PASSIVE',     'Xtickheight',
      'XTickHeight', $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}
    ],
    -xtickview => [ 'PASSIVE', 'Xtickview', 'XTickView', 1 ],

    -yticknumber => [
      'PASSIVE',     'Yticknumber',
      'YTickNumber', $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickNumber}
    ],
    -ytickwidth =>
      [ 'PASSIVE', 'Ytickwidth', 'YtickWidth', $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth} ],
    -ytickview => [ 'PASSIVE', 'Ytickview', 'YTickView', 1 ],

    -alltickview => [ 'PASSIVE', 'Alltickview', 'AllTickView', 1 ],

    -width  => [ 'SELF', 'width',  'Width',  $CompositeWidget->{RefInfoDummies}->{Canvas}{Width} ],
    -height => [ 'SELF', 'height', 'Height', $CompositeWidget->{RefInfoDummies}->{Canvas}{Height} ],

    -linewidth => [ 'PASSIVE', 'Linewidth', 'LineWidth', 1 ],
    -colordata =>
      [ 'PASSIVE', 'Colordata', 'ColorData', $CompositeWidget->{RefInfoDummies}->{Legend}{Colors} ],
    -spacingbar => [ 'PASSIVE', 'Spacingbar', 'SpacingBar', 1 ],
  );

  $CompositeWidget->Delegates( DEFAULT => $CompositeWidget, );

  # recreate graph after widget resize
  $CompositeWidget->enabled_automatic_redraw();
  $CompositeWidget->disabled_gradientcolor();
}

sub _Balloon {
  my ($CompositeWidget) = @_;

  # balloon defined and user want to stop it
  if ( defined $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}
    and $CompositeWidget->{RefInfoDummies}->{Balloon}{State} == 0 )
  {
    $CompositeWidget->_DestroyBalloonAndBind();
    return;
  }

  # balloon not defined and user want to stop it
  elsif ( $CompositeWidget->{RefInfoDummies}->{Balloon}{State} == 0 ) {
    return;
  }

  # balloon defined and user want to start it again (may be new option)
  elsif ( defined $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}
    and $CompositeWidget->{RefInfoDummies}->{Balloon}{State} == 1 )
  {

    # destroy the balloon, it will be re create above
    $CompositeWidget->_DestroyBalloonAndBind();
  }

  # Balloon creation
  $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj} = $CompositeWidget->Balloon(
    -statusbar  => $CompositeWidget,
    -background => $CompositeWidget->{RefInfoDummies}->{Balloon}{Background},
  );
  $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}->attach(
    $CompositeWidget,
    -balloonposition => 'mouse',
    -msg             => $CompositeWidget->{RefInfoDummies}->{Legend}{MsgBalloon},
  );

  # no legend, no bind
  unless ( my $LegendTextNumber = $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber} ) {
    return;
  }

  # bind legend and bars
  for my $IndexLegend ( 1 .. $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber} ) {

    my $LegendTag  = $IndexLegend . $CompositeWidget->{RefInfoDummies}->{TAGS}{Legend};
    my $BoxplotTag = $IndexLegend . $CompositeWidget->{RefInfoDummies}->{TAGS}{Boxplot};

    $CompositeWidget->bind(
      $LegendTag,
      '<Enter>',
      sub {
        my $OtherColor = $CompositeWidget->{RefInfoDummies}->{Balloon}{ColorData}->[0];

        # Change color if bar have the same color
        if ( $OtherColor eq $CompositeWidget->{RefInfoDummies}{Boxplot}{$BoxplotTag}{color} ) {
          $OtherColor = $CompositeWidget->{RefInfoDummies}->{Balloon}{ColorData}->[1];
        }
        $CompositeWidget->itemconfigure(
          $BoxplotTag,
          -fill  => $OtherColor,
          -width => $CompositeWidget->cget( -linewidth )
            + $CompositeWidget->{RefInfoDummies}->{Balloon}{MorePixelSelected},
        );
      }
    );

    $CompositeWidget->bind(
      $LegendTag,
      '<Leave>',
      sub {
        $CompositeWidget->itemconfigure(
          $BoxplotTag,
          -fill  => $CompositeWidget->{RefInfoDummies}{Boxplot}{$BoxplotTag}{color},
          -width => $CompositeWidget->cget( -linewidth ),
        );

        # Allow value bar to display
        $CompositeWidget->itemconfigure( $CompositeWidget->{RefInfoDummies}->{TAGS}{BarValues},
          -fill => 'black', );
      }
    );
  }

  return;
}

sub boxplot_information {
  my ($CompositeWidget) = @_;

  # Test if plot defined
  unless ( defined $CompositeWidget->{RefInfoDummies}->{Data}{PlotDefined} ) {
    $CompositeWidget->_error( 'You have to plot before get boxplots informations', 1 );
  }

  my @boxplot_information;
  my @AllData = @{ $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} };
  my $NbrData = scalar @AllData;
  my ( $dim1, $dim2 ) = ( 0, 0 );

  # Read data and store information in A dimension table and hash.
  foreach my $SampleNumber ( 1 .. $NbrData - 1 ) {

    # Fisrt dimension
    $dim1 = $SampleNumber - 1;
    $dim2 = 0;

    # Get information foreach sample
    foreach my $RefData ( @{ $AllData[$SampleNumber] } ) {
      my ( $Q1, $Q2, $Q3 ) = ( _Quantile( $RefData, 1 ), _Quantile( $RefData, 2 ), _Quantile( $RefData, 3 ) );
      my ( $SnonOutlier, $LnonOutlier ) = _NonOutlier( $RefData, $Q1, $Q3 );
      $boxplot_information[$dim1][$dim2] = {
        mean                 => _moy($RefData),
        median               => $Q2,
        Q1                   => $Q1,
        Q3                   => $Q3,
        largest_non_outlier  => $LnonOutlier,
        smallest_non_outlier => $SnonOutlier,
        outliers             => [],
      };

      foreach my $value ( @{$RefData} ) {
        if ( $value < $SnonOutlier or $value > $LnonOutlier ) {
          push( @{ $boxplot_information[$dim1][$dim2]->{outliers} }, $value );
        }
      }
      $dim2++;
    }
  }

  return \@boxplot_information;
}

sub set_legend {
  my ( $CompositeWidget, %InfoLegend ) = @_;
  my $RefLegend = $InfoLegend{-data};
  unless ( defined $RefLegend ) {
    $CompositeWidget->_error(
      "Can't set -data in set_legend method. "
        . "May be you forgot to set the value\n"
        . "Eg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  unless ( defined $RefLegend and ref($RefLegend) eq 'ARRAY' ) {
    $CompositeWidget->_error(
      "Can't set -data in set_legend method. Bad data\n"
        . "Eg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  my @LegendOption = qw / -box -legendmarkerheight -legendmarkerwidth -heighttitle /;

  foreach my $OptionName (@LegendOption) {
    if ( defined $InfoLegend{$OptionName}
      and $InfoLegend{$OptionName} !~ m{^\d+$} )
    {
      $CompositeWidget->_error(
        "'Can't set $OptionName to " . "'$InfoLegend{$OptionName}', $InfoLegend{$OptionName}' isn't numeric",
        1
      );
    }
  }

  # Check legend and data size
  if ( my $RefData = $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} ) {
    unless ( $CompositeWidget->_CheckSizeLengendAndData( $RefData, $RefLegend ) ) {
      undef $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend};
      return;
    }
  }

  # Get Legend options
  # Title
  if ( defined $InfoLegend{-title} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{title} = $InfoLegend{-title};
  }
  else {
    undef $CompositeWidget->{RefInfoDummies}->{Legend}{title};
    $CompositeWidget->{RefInfoDummies}->{Legend}{HeightTitle} = 0;
  }

  # Title and legend font
  if ( defined $InfoLegend{-titlefont} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{titlefont} = $InfoLegend{-titlefont};
  }
  if ( defined $InfoLegend{-legendfont} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{legendfont} = $InfoLegend{-legendfont};
  }

  # box legend
  if ( defined $InfoLegend{-box} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{box} = $InfoLegend{-box};
  }

  # title color
  if ( defined $InfoLegend{-titlecolors} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{titlecolors} = $InfoLegend{-titlecolors};
  }

  # legendmarkerheight
  if ( defined $InfoLegend{-legendmarkerheight} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{HCube} = $InfoLegend{-legendmarkerheight};
  }

  # legendmarkerwidth
  if ( defined $InfoLegend{-legendmarkerwidth} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{WCube} = $InfoLegend{-legendmarkerwidth};
  }

  # heighttitle
  if ( defined $InfoLegend{-heighttitle} ) {
    $CompositeWidget->{RefInfoDummies}->{Legend}{HeightTitle} = $InfoLegend{-heighttitle};
  }

  # Get the biggest length of legend text
  my @LengthLegend = map { length; } @{$RefLegend};
  my $BiggestLegend = _MaxArray( \@LengthLegend );

  # 100 pixel =>  13 characters, 1 pixel =>  0.13 pixels then 1 character = 7.69 pixels
  $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter} = 7.69;

  # Max pixel width for a legend text for us
  $CompositeWidget->{RefInfoDummies}->{Legend}{LengthTextMax}
    = int( $CompositeWidget->{RefInfoDummies}->{Legend}{WidthText}
      / $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter} );

  # We have free space
  my $Diff = $CompositeWidget->{RefInfoDummies}->{Legend}{LengthTextMax} - $BiggestLegend;

  # Get new size width for a legend text with one pixel security
  $CompositeWidget->{RefInfoDummies}->{Legend}{WidthText}
    -= ( $Diff - 1 ) * $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter};

  # Store Reference data
  $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend} = $RefLegend;
  $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLegend}  = scalar @{$RefLegend};

  return 1;
}

sub _Legend {
  my ( $CompositeWidget, $RefLegend ) = @_;

  # One legend width
  $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend}
    = +$CompositeWidget->{RefInfoDummies}->{Legend}{SpaceBeforeCube}    # space between each legend
    + $CompositeWidget->{RefInfoDummies}->{Legend}{WCube}               # width legend marker
    + $CompositeWidget->{RefInfoDummies}->{Legend}{SpaceAfterCube}      # space after marker
    + $CompositeWidget->{RefInfoDummies}->{Legend}{WidthText}           # legend text width allowed
    ;

  # Number of legends per line
  $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine}
    = int( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width}
      / $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend} );
  $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine} = 1
    if ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine} == 0 );

  # How many legend we will have
  $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber}
    = scalar @{ $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} } - 1;

=for NumberLines:
  We calculate the number of lines set for the legend graph.
  If wa can set 11 legends per line, then for 3 legend, we will need one line
  and for 12 legends, we will need 2 lines
  If NbrLeg / NbrPerLine = integer => get number of lines
  If NbrLeg / NbrPerLine = float => int(float) + 1 = get number of lines

=cut

  $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine}
    = $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber}
    / $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine};
  unless (
    int( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine} )
    == $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine} )
  {
    $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine}
      = int( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine} ) + 1;
  }

  # Total Height of Legend
  $CompositeWidget->{RefInfoDummies}->{Legend}{Height}
    = $CompositeWidget->{RefInfoDummies}->{Legend}{HeightTitle}    # Hauteur Titre légende
    + $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine}
    * $CompositeWidget->{RefInfoDummies}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber}
    < $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine} )
  {
    $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine}
      = $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber};
  }

  return;
}

sub _ViewLegend {
  my ($CompositeWidget) = @_;

  # legend option
  my $LegendTitle        = $CompositeWidget->{RefInfoDummies}->{Legend}{title};
  my $legendmarkercolors = $CompositeWidget->cget( -colordata );
  my $legendfont         = $CompositeWidget->{RefInfoDummies}->{Legend}{legendfont};
  my $titlecolor         = $CompositeWidget->{RefInfoDummies}->{Legend}{titlecolors};
  my $titlefont          = $CompositeWidget->{RefInfoDummies}->{Legend}{titlefont};

  # display legend title
  if ( defined $LegendTitle ) {
    my $xLegendTitle = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin}
      + $CompositeWidget->{RefInfoDummies}->{Legend}{SpaceBeforeCube};
    my $yLegendTitle
      = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight};

    $CompositeWidget->createText(
      $xLegendTitle,
      $yLegendTitle,
      -text   => $LegendTitle,
      -anchor => 'nw',
      -font   => $titlefont,
      -fill   => $titlecolor,
      -width  => $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width},
      -tags   => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{TitleLegend},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
  }

  # Display legend
  my $IndexColor  = 0;
  my $IndexLegend = 0;

  for my $NumberLine ( 0 .. $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLine} - 1 ) {
    my $x1Cube = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin}
      + $CompositeWidget->{RefInfoDummies}->{Legend}{SpaceBeforeCube};
    my $y1Cube
      = ( $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin}
        + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}
        + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight}
        + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight}
        + $CompositeWidget->{RefInfoDummies}->{Legend}{HeightTitle}
        + $CompositeWidget->{RefInfoDummies}->{Legend}{HLine} / 2 )
      + $NumberLine * $CompositeWidget->{RefInfoDummies}->{Legend}{HLine};

    my $x2Cube    = $x1Cube + $CompositeWidget->{RefInfoDummies}->{Legend}{WCube};
    my $y2Cube    = $y1Cube - $CompositeWidget->{RefInfoDummies}->{Legend}{HCube};
    my $xText     = $x2Cube + $CompositeWidget->{RefInfoDummies}->{Legend}{SpaceAfterCube};
    my $yText     = $y2Cube;
    my $MaxLength = $CompositeWidget->{RefInfoDummies}->{Legend}{LengthTextMax};

  LEGEND:
    for my $NumberLegInLine ( 0 .. $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine} - 1 ) {

      my $LineColor = $legendmarkercolors->[$IndexColor];
      unless ( defined $LineColor ) {
        $IndexColor = 0;
        $LineColor  = $legendmarkercolors->[$IndexColor];
      }

      # Cut legend text if too long
      my $Legende = $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend}->[$IndexLegend];
      next unless ( defined $Legende );
      my $NewLegend = $Legende;

      if ( length $NewLegend > $MaxLength ) {
        $MaxLength -= 3;
        $NewLegend =~ s/^(.{$MaxLength}).*/$1/;
        $NewLegend .= '...';
      }

      my $Tag = ( $IndexLegend + 1 ) . $CompositeWidget->{RefInfoDummies}->{TAGS}{Legend};
      $CompositeWidget->createRectangle(
        $x1Cube, $y1Cube, $x2Cube, $y2Cube,
        -fill    => $LineColor,
        -outline => $LineColor,
        -tags    => [ $Tag, $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
      );

      my $Id = $CompositeWidget->createText(
        $xText, $yText,
        -text   => $NewLegend,
        -anchor => 'nw',
        -tags   => [ $Tag, $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
      );
      if ($legendfont) {
        $CompositeWidget->itemconfigure( $Id, -font => $legendfont, );
      }

      $IndexColor++;
      $IndexLegend++;

      # cube
      $x1Cube += $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend};
      $x2Cube += $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend};

      # Text
      $xText += $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend};
      my $BoxplotTag = $IndexLegend . $CompositeWidget->{RefInfoDummies}->{TAGS}{Boxplot};

      # balloon on legend
      $CompositeWidget->{RefInfoDummies}->{Legend}{MsgBalloon}->{$Tag} = $Legende;

      last LEGEND
        if ( $IndexLegend == $CompositeWidget->{RefInfoDummies}->{Legend}{LegendTextNumber} );
    }
  }

  # box legend
  my $x1Box = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin};
  my $y1Box
    = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight};
  my $x2Box
    = $x1Box
    + ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrPerLine}
      * $CompositeWidget->{RefInfoDummies}->{Legend}{LengthOneLegend} );

  # Reajuste box if width box < legend title text
  my @InfoLegendTitle = $CompositeWidget->bbox( $CompositeWidget->{RefInfoDummies}->{TAGS}{TitleLegend} );
  if ( $InfoLegendTitle[2] and $x2Box <= $InfoLegendTitle[2] ) {
    $x2Box = $InfoLegendTitle[2] + 2;
  }
  my $y2Box = $y1Box + $CompositeWidget->{RefInfoDummies}->{Legend}{Height};
  $CompositeWidget->createRectangle(
    $x1Box, $y1Box, $x2Box, $y2Box,
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{BoxLegend},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  return;
}

sub _axis {
  my ($CompositeWidget) = @_;

  # x axis width
  $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width}
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{Width}
    - ( 2 * $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth}
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth} );

  # get Height legend
  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLegend} > 0 ) {
    $CompositeWidget->_Legend( $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend} );
  }

  # Height y axis
  $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{Height}    # Largeur canvas
    - (
    2 * $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}          # 2 fois les espace vides
      + $CompositeWidget->{RefInfoDummies}->{Title}{Height}                     # Hauteur du titre
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}           # Hauteur tick (axe x)
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight}    # Hauteur valeurs axe
      + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight}         # Hauteur x label
      + $CompositeWidget->{RefInfoDummies}->{Legend}{Height}                    # Hauteur légende
    );

  #===========================
  # Y axis
  # Set 2 points (CxMin, CyMin) et (CxMin, CyMax)
  $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin}                             # Coordonnées CxMin
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}             # Largeur vide
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth}            # Largeur label y
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth}       # Largeur valeur axe y
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth};             # Largeur tick axe y

  $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax}                             # Coordonnées CyMax
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}            # Hauteur vide
    + $CompositeWidget->{RefInfoDummies}->{Title}{Height}                       # Hauteur titre
    ;

  $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin}                             # Coordonnées CyMin
    = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax}                         # Coordonnées CyMax (haut)
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}                 # Hauteur axe Y
    ;

  # display Y axis
  $CompositeWidget->createLine(
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{yAxis},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  #===========================
  # X axis
  # Set 2 points (CxMin,CyMin) et (CxMax,CyMin)
  # ou (Cx0,Cy0) et (CxMax,Cy0)
  $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax} = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width};

  # Bottom x axis
  $CompositeWidget->createLine(
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin},
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{xAxis},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  # POINT (0,0)
  # min positive value >= 0
  if ( $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} >= 0 ) {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0} = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin};
    $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0} = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin};

    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{HeightUnit}    # Height unit for value = 1
      = $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}
      / ( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} - 0 );
  }

  # min positive value < 0
  else {

    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{HeightUnit}    # Height unit for value = 1
      = $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}
      / ( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue}
        - $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} );
    $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0} = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin};
    $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0}
      = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin}
      + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{HeightUnit}
        * $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} );

    # X Axis (0,0)
    $CompositeWidget->createLine(
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0},
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0},
      $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax},
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0},
      -tags => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{xAxis0},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
  }

  return;
}

sub _xtick {
  my ($CompositeWidget) = @_;

  my $xvaluecolor = $CompositeWidget->cget( -xvaluecolor );
  my $longticks   = $CompositeWidget->cget( -longticks );

  # x coordinates y ticks on bottom x axis
  my $Xtickx1 = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin};
  my $Xticky1 = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin};

  # x coordinates y ticks on 0,0 x axis if the graph have only y value < 0
  if (  $CompositeWidget->cget( -zeroaxisonly ) == 1
    and $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} > 0 )
  {
    $Xticky1 = $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0};
  }

  my $Xtickx2 = $Xtickx1;
  my $Xticky2 = $Xticky1 + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight};

  # Coordinates of x values (first value)
  my $XtickxValue = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin}
    + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
  my $XtickyValue = $Xticky2 + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight} / 2 );
  my $NbrLeg = scalar( @{ $CompositeWidget->{RefInfoDummies}->{Data}{RefXLegend} } );

  my $xlabelskip = $CompositeWidget->cget( -xlabelskip );

  # index of tick and vlaues that will be skip
  my %IndiceToSkip;
  if ( defined $xlabelskip ) {
    for ( my $i = 1; $i <= $NbrLeg; $i++ ) {
      $IndiceToSkip{$i} = 1;
      $i += $xlabelskip;
    }
  }

  for ( my $Indice = 1; $Indice <= $NbrLeg; $Indice++ ) {
    my $data = $CompositeWidget->{RefInfoDummies}->{Data}{RefXLegend}->[ $Indice - 1 ];

    # tick
    $Xtickx1 += $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick};
    $Xtickx2 = $Xtickx1;

    # tick legend
    my $RegexXtickselect = $CompositeWidget->cget( -xvaluesregex );

    if ( $data =~ m{$RegexXtickselect} ) {
      next unless ( defined $IndiceToSkip{$Indice} );

      # Long tick
      if ( defined $longticks and $longticks == 1 ) {
        $Xticky1 = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax};
        $Xticky2 = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin};
      }

      $CompositeWidget->createLine(
        $Xtickx1, $Xticky1, $Xtickx2, $Xticky2,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{xTick},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTick},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
      );
      if (  defined $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick}
        and defined $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter} )
      {
        my $MaxLength    = $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick};
        my $WidthData    = $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter} * length $data;
        my $NbrCharacter = int( $MaxLength / $CompositeWidget->{RefInfoDummies}->{Legend}{WidthOneCaracter} );
        if ( defined $MaxLength and $WidthData > $MaxLength ) {
          $data =~ s/^(.{$NbrCharacter}).*/$1/;
          $data .= '...';
        }
      }

      $CompositeWidget->createText(
        $XtickxValue,
        $XtickyValue,
        -text => $data,
        -fill => $xvaluecolor,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{xValues},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllValues},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],

        #        %option,
      );

    }
    $XtickxValue += $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick};
  }

  return;
}

sub _ViewData {
  my ($CompositeWidget) = @_;

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );
  my $spacingbar         = $CompositeWidget->cget( -spacingbar );
  my $showvalues         = $CompositeWidget->cget( -showvalues );

  # number of value for x axis
  $CompositeWidget->{RefInfoDummies}->{Data}{xtickNumber}
    = $CompositeWidget->{RefInfoDummies}->{Data}{NumberXValues};

  # Space between x ticks
  $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width}
    / ( $CompositeWidget->{RefInfoDummies}->{Data}{xtickNumber} + 1 );

  my $IdData     = 0;
  my $IndexColor = 0;
  my $WidthBar   = $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick}
    / $CompositeWidget->{RefInfoDummies}->{Data}{NumberRealData};

  # Spacing if necessary
  my $SpacingPixel = 0;
  if ( $spacingbar == 1 ) {
    $SpacingPixel = $WidthBar / 4;
  }

  my $YMin0           = $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0};
  my $XMin0           = $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0};
  my $YaxisHeightUnit = $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{HeightUnit};
  foreach my $RefArrayData ( @{ $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} } ) {
    if ( $IdData == 0 ) {
      $IdData++;
      next;
    }
    my $NumberData = 1;    # Number of data
                           # each boxplot
    foreach my $Refdata ( @{$RefArrayData} ) {
      unless ( defined $Refdata and scalar @{$Refdata} > 3 ) {
        $NumberData++;
        next;
      }

      # statistic calcul
      my $Quantile1 = _Quantile( $Refdata, 1 );
      my $Quantile2 = _Quantile( $Refdata, 2 );
      my $Quantile3 = _Quantile( $Refdata, 3 );
      my ( $SnonOutlier, $LnonOutlier ) = _NonOutlier( $Refdata, $Quantile1, $Quantile3 );
      my $moy = _moy($Refdata);

      # Boxplot graph coord
      my $x
        = $XMin0 
        + $NumberData * $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{SpaceBetweenTick}
        - ( ( $CompositeWidget->{RefInfoDummies}->{Data}{NumberRealData} - $IdData ) * $WidthBar );
      my $x0 = $x - $WidthBar + $SpacingPixel;
      my $xc = ( $x + $x0 ) / 2;

      # y Boxplot
      my $yQuantile1   = $YMin0 - ( $Quantile1 * $YaxisHeightUnit );
      my $yQuantile3   = $YMin0 - ( $Quantile3 * $YaxisHeightUnit );
      my $yQuantile2   = $YMin0 - ( $Quantile2 * $YaxisHeightUnit );
      my $ySnonOutlier = $YMin0 - ( $SnonOutlier * $YaxisHeightUnit );
      my $yLnonOutlier = $YMin0 - ( $LnonOutlier * $YaxisHeightUnit );
      my $ymoy         = $YMin0 - ( $moy * $YaxisHeightUnit );
      $moy = sprintf( "%.2f", $moy );

      # color
      my $LineColor = $legendmarkercolors->[$IndexColor];
      unless ( defined $LineColor ) {
        $IndexColor = 0;
        $LineColor  = $legendmarkercolors->[$IndexColor];
      }

      # tag
      my $tag  = $IdData . '_' . $NumberData . $CompositeWidget->{RefInfoDummies}->{TAGS}{Boxplot};
      my $tag2 = $IdData . $CompositeWidget->{RefInfoDummies}->{TAGS}{Boxplot};
      $CompositeWidget->{RefInfoDummies}{Boxplot}{$tag2}{color} = $LineColor;
      my $Message;
      if ( $Message = $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend}->[ $IdData - 1 ] ) {
        $Message .= " : \n";
      }
      $Message .= <<"MESSAGE";
  Sample : $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData}->[0]->[$NumberData-1]
  Largest non-outlier : $LnonOutlier
  75th percentile : $Quantile3
  Median : $Quantile2
  Mean : $moy
  25th percentile : $Quantile1
  Smallest non-outlier : $SnonOutlier
MESSAGE
      $CompositeWidget->{RefInfoDummies}->{Legend}{MsgBalloon}->{$tag} = $Message;

      # D9
      $CompositeWidget->createLine(
        $x0,
        $yLnonOutlier,
        $x,
        $yLnonOutlier,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );
      $CompositeWidget->createLine(
        $xc,
        $yLnonOutlier,
        $xc,
        $yQuantile3,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );

      # D1
      $CompositeWidget->createLine(
        $x0,
        $ySnonOutlier,
        $x,
        $ySnonOutlier,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );
      $CompositeWidget->createLine(
        $xc,
        $ySnonOutlier,
        $xc,
        $yQuantile1,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );

      # box : median
      $CompositeWidget->createRectangle(
        $x0,
        $yQuantile1,
        $x,
        $yQuantile3,
        -tags => [
          $tag2, $tag,
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
        -fill  => $LineColor,
      );

      # Q2 : median
      $CompositeWidget->createLine(
        $x0,
        $yQuantile2,
        $x,
        $yQuantile2,
        -tags => [
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
          $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );

      # Moy
      $CompositeWidget->_CreateType(
        x      => $xc,
        y      => $ymoy,
        pixel  => 6,
        type   => 'horizontal cross',
        option => {
          -tags => [
            $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
            $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
          ],
          -width => $CompositeWidget->cget( -linewidth ),
        },
      );

      # outlier
      foreach my $value ( @{$Refdata} ) {
        if ( $value < $SnonOutlier or $value > $LnonOutlier ) {
          my $OutlierTag = $IdData . '_' . $NumberData . "_$value" . 'Outlier';
          $CompositeWidget->{RefInfoDummies}->{Legend}{MsgBalloon}->{$OutlierTag} = "outlier : $value";

          my $yOutlier = $YMin0 - ( $value * $YaxisHeightUnit );
          $CompositeWidget->_CreateType(
            x      => $xc,
            y      => $yOutlier,
            pixel  => 6,
            type   => 'diagonal cross',
            option => {
              -tags => [
                $OutlierTag,
                $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
                $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
              ],
              -width => $CompositeWidget->cget( -linewidth ),
            },
          );
          $CompositeWidget->_CreateType(
            x      => $xc,
            y      => $yOutlier,
            pixel  => 6,
            type   => 'horizontal cross',
            option => {
              -tags => [
                $OutlierTag,
                $CompositeWidget->{RefInfoDummies}->{TAGS}{AllData},
                $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
              ],
              -width => $CompositeWidget->cget( -linewidth ),
            },
          );
        }
      }

      $NumberData++;

    }

    $IdData++;
    $IndexColor++;
  }

  return 1;
}

sub plot {
  my ( $CompositeWidget, $RefData, %option ) = @_;

  my $yticknumber = $CompositeWidget->cget( -yticknumber );

  if ( defined $option{-substitutionvalue}
    and _isANumber( $option{-substitutionvalue} ) )
  {
    $CompositeWidget->{RefInfoDummies}->{Data}{SubstitutionValue} = $option{-substitutionvalue};
  }

  $CompositeWidget->{RefInfoDummies}->{Data}{NumberRealData} = scalar( @{$RefData} ) - 1;

  unless ( defined $RefData ) {
    $CompositeWidget->_error('data not defined');
    return;
  }

  unless ( scalar @{$RefData} > 1 ) {
    $CompositeWidget->_error('You must have at least 2 arrays');
    return;
  }

  # Check legend and data size
  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLegend} > 0 ) {
    my $RefLegend = $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend};
    unless ( $CompositeWidget->_CheckSizeLengendAndData( $RefData, $RefLegend ) ) {
      undef $CompositeWidget->{RefInfoDummies}->{Legend}{DataLegend};
    }
  }

  # Check array size
  $CompositeWidget->{RefInfoDummies}->{Data}{NumberXValues} = scalar @{ $RefData->[0] };
  my $i         = 0;
  my @arrayTemp = (0) x scalar @{ $RefData->[0] };
  foreach my $RefArray ( @{$RefData} ) {
    unless ( scalar @{$RefArray} == $CompositeWidget->{RefInfoDummies}->{Data}{NumberXValues} ) {
      $CompositeWidget->_error( 'Make sure that every array has the ' . 'same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      foreach my $RefArray2 ( @{$RefArray} ) {

        # First data must be an array ref
        unless ( ref $RefArray2 eq 'ARRAY' ) {
          $CompositeWidget->_error( 'Each boxplot data must be in an array reference', 1 );
        }
        foreach my $data ( @{$RefArray2} ) {
          if ( defined $data and !_isANumber($data) ) {
            $data = $CompositeWidget->{RefInfoDummies}->{Data}{SubstitutionValue};
          }
        }
      }

      # max, min
      foreach my $RefArray2 ( @{$RefArray} ) {
        $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue}
          = _MaxArray( [ $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue}, _MaxArray($RefArray2) ] );
        $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue}
          = _MinArray( [ $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue}, _MinArray($RefArray2) ] );

        # Size each data points
        if ( scalar @{$RefArray2} < 4 and scalar @{$RefArray2} > 0 ) {
          my $data = join( ',', @{$RefArray2} );
          $data = "[$data]";
          $CompositeWidget->_error(
            "Data set $data does not contain the minimum of 4 data points.\n" . "It has been skipped." );
        }
      }

    }
    $i++;
  }

  $CompositeWidget->{RefInfoDummies}->{Data}{RefXLegend}  = $RefData->[0];
  $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData}  = $RefData;
  $CompositeWidget->{RefInfoDummies}->{Data}{PlotDefined} = 1;

  if ( $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} > 0 ) {
    $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} = 0;
  }
  while ( ( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} / $yticknumber ) % 5 != 0 ) {
    $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue}
      = int( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} + 1 );
  }

  $CompositeWidget->_GraphForDummiesConstruction;

  return 1;
}

1;
__END__

=head1 NAME

Tk::ForDummies::Graph::Boxplots - DEPRECATED : now use Tk::Chart.

=head1 DEPRECATED

DEPRECATED : please does not use this module, but use now L<Tk::Chart>.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::ForDummies::Graph::Boxplots;
  
  my $mw = new MainWindow(
    -title      => 'Tk::ForDummies::Graph::Boxplots example',
    -background => 'white',
  );
  
  my $GraphDummies = $mw->Boxplots(
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
  my @Legends = ( 'legend 1', 'legend 2' );
  $GraphDummies->set_legend(
    -title       => 'Title legend',
    -data        => \@Legends,
  );
  
  # Add help identification
  $GraphDummies->set_balloon();
  
  # Create the graph
  $GraphDummies->plot( \@data );
  
  MainLoop();

=head1 DESCRIPTION

Tk::ForDummies::Graph::Boxplots is an extension of the Canvas widget. It is an easy way to build  
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

  $GraphDummies->enabled_gradientcolor();
  $GraphDummies->set_gradientcolor(
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

=item Name:	B<Spacingbar>

=item Class: B<SpacingBar>

=item Switch:	B<-spacingbar>

Set this to 1 to display remove space between each boxplot. 

 -spacingbar => 0, # 0 or 1

Default : B<1>

=back

=head1 WIDGET-SPECIFIC OPTIONS like Tk::ForDummies::Graph::Lines

Many options allow you to configure your graph as you want. 
The default configuration is already OK, but you can change it.
these are the same options as L<Tk::ForDummies::Graph::Lines> module


=over 4

=item Name:	B<Title>

=item Class: B<Title>

=item Switch:	B<-title>

Title of your graph.

 -title => 'My graph title',

Default : B<undef>

=item Name:	B<Titleposition>

=item Class:	B<TitlePosition>

=item Switch:	B<-titleposition>

Position of title : B<center>, B<left> or B<right>
  
 -titleposition => 'left',

Default : B<center>

=item Name:	B<Titlecolor>

=item Class: B<TitleColor>

=item Switch:	B<-titlecolor>

Title color of your graph.

 -titlecolor => 'red',

Default : B<black>

=item Name:	B<Titlefont>

=item Class: B<TitleFont>

=item Switch:	B<-titlefont>

Set the font for the title text. See also textfont option. 

 -titlefont => 'Times 15 {normal}',

Default : B<{Times} 12 {bold}>

=item Name:	B<Titleheight>

=item Class: B<TitleHeight>

=item Switch:	B<-titleheight>

Height for title graph space.

 -titleheight => 100,

Default : B<40>

=item Name:	B<Xlabel>

=item Class: B<XLabel>

=item Switch:	B<-xlabel>

The label to be printed just below the x axis.

 -xlabel => 'X label',

Default : B<undef>

=item Name:	B<Xlabelcolor>

=item Class:	B<XLabelColor>

=item Switch:	B<-xlabelcolor>

Set x label color. See also textcolor option.

 -xlabelcolor => 'red',

Default : B<black>

=item Name:	B<Xlabelfont>

=item Class: B<XLabelFont>

=item Switch:	B<-xlabelfont>

Set the font for the x label text. See also textfont option.

 -xlabelfont => 'Times 15 {normal}',

Default : B<{Times} 10 {bold}>

=item Name:	B<Xlabelheight>

=item Class: B<XLabelHeight>

=item Switch:	B<-xlabelheight>

Height for x label space.

 -xlabelheight => 50,

Default : B<30>

=item Name:	B<Xlabelskip>

=item Class: B<XLabelSkip>

=item Switch:	B<-xlabelskip>

Print every xlabelskip number under the tick on the x axis. If you have a 
dataset wich contain many points, the tick and x values will be overwrite 
on the graph. This option can help you to clarify your graph.
Eg: 

  # ['leg1', 'leg2', ...'leg1000', 'leg1001', ... 'leg2000'] => There are 2000 ticks and text values on x axis.
  -xlabelskip => 1 => ['leg1', 'leg3', 'leg5', ...]        # => 1000 ticks will be display.

See also -xvaluesregex option.

 -xlabelskip => 2,

Default : B<0>

=item Name:	B<Xvaluecolor>

=item Class: B<XValueColor>

=item Switch:	B<-xvaluecolor>

Set x values colors. See also textcolor option.

 -xvaluecolor => 'red',

Default : B<black>

=item Name:	B<Xvaluespace>

=item Class:	B<XValueSpace>

=item Switch:	B<-xvaluespace>

Width for x values space.

 -xvaluespace => 50,

Default : B<30>

=item Name:	B<Xvalueview>

=item Class:	B<XvalueView>

=item Switch:	B<-xvalueview>

View values on x axis.
 
 -xvalueview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Xvaluesregex>

=item Class:	B<XValuesRegex>

=item Switch:	B<-xvaluesregex>

View the x values which will match with regex. It allows you to display tick on x axis and values 
that you want. You can combine it with -xlabelskip to display many dataset.

 ...
 ['leg1', 'leg2', 'data1', 'data2', 'symb1', 'symb2']
 ...

 -xvaluesregex => qr/leg/i,

On the graph, just leg1 and leg2 will be display.

Default : B<qr/.+/>

=item Name:	B<Ylabel>

=item Class:	B<YLabel>

=item Switch:	B<-ylabel>

The labels to be printed next to y axis.

 -ylabel => 'Y label',

Default : B<undef>

=item Name:	B<Ylabelcolor>

=item Class:	B<YLabelColor>

=item Switch:	B<-ylabelcolor>

Set the color of y label. See also textcolor option. 

 -ylabelcolor => 'red',

Default : B<black>

=item Name:	B<Ylabelfont>

=item Class:	B<YLabelFont>

=item Switch:	B<-ylabelfont>

Set the font for the y label text. See also textfont option. 

 -ylabelfont => 'Times 15 {normal}',

Default : B<{Times} 10 {bold}>

=item Name:	B<Ylabelwidth>

=item Class:	B<YLabelWidth>

=item Switch:	B<-ylabelwidth>

Width of space for y label.

 -ylabelwidth => 30,

Default : B<5>

=item Name:	B<Yvaluecolor>

=item Class:	B<YValueColor>

=item Switch:	B<-yvaluecolor>

Set the color of y values. See also valuecolor option.

 -yvaluecolor => 'red',

Default : B<black>

=item Name:	B<Yvalueview>

=item Class:	B<YvalueView>

=item Switch:	B<-yvalueview>

View values on y axis.
 
 -yvalueview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Labelscolor>

=item Class: B<LabelsColor>

=item Switch:	B<-labelscolor>

Combine xlabelcolor and ylabelcolor options. See also textcolor option.

 -labelscolor => 'red',

Default : B<undef>

=item Name:	B<Valuescolor>

=item Class: B<ValuesColor>

=item Switch:	B<-valuescolor>

Set the color of x, y values in axis. It combines xvaluecolor 
and yvaluecolor options.

 -valuescolor => 'red',

Default : B<undef>

=item Name:	B<Textcolor>

=item Class: B<TextColor>

=item Switch:	B<-textcolor>

Set the color of x, y labels and title text. 
It combines titlecolor, xlabelcolor and ylabelcolor options.

 -textcolor => 'red',

Default : B<undef>

=item Name:	B<Textfont>

=item Class: B<TextFont>

=item Switch:	B<-textfont>

Set the font of x, y labels and title text. It combines titlefont, 
xlabelfont and ylabelfont options.

 -textfont => 'Times 15 {normal}',

Default : B<undef>

=item Name:	B<Longticks>

=item Class: B<LongTicks>

=item Switch:	B<-longticks>

If long_ticks is a true value, ticks will be drawn the same length as the axes.

 -longticks => 1, #  0 or 1

Default : B<0>

=item Name:	B<Boxaxis>

=item Class: B<BoxAxis>

=item Switch:	B<-boxaxis>

Draw the axes as a box.

 -boxaxis => 0, #  0 or 1

Default : B<1>

=item Name:	B<Noaxis>

=item Class: B<NoAxis>

=item Switch:	B<-noaxis>

Hide the axis with ticks and values ticks.

 -noaxis => 1, # 0 or 1

Default : B<0>

=item Name:	B<Zeroaxis>

=item Class: B<ZeroAxis>

=item Switch:	B<-zeroaxis>

If set to a true value, the axis for y values will only be drawn. 
This might be useful in case your graph contains negative values, 
but you want it to be clear where the zero value is
(see also zeroaxisonly and boxaxis).

 -zeroaxis => 1, # 0 or 1

Default : B<0>

=item Name:	B<Zeroaxisonly>

=item Class:	B<ZeroAxisOnly>

=item Switch:	B<-zeroaxisonly>

If set to a true value, the zero x axis will be drawn and no axis 
at the bottom of the graph will be drawn. 
The labels for X values will be placed on the zero x axis.
This works if there is at least one negative value in dataset.

 -zeroaxisonly => 1, # 0 or 1

Default : B<0>

=item Name:	B<Xtickheight>

=item Class:	B<XTickHeight>

=item Switch:	B<-xtickheight>

Set height of all x ticks.

 -xtickheight => 10,

Default : B<5>

=item Name:	B<Xtickview>

=item Class:	B<XTickView>

=item Switch:	B<-xtickview>

View x ticks of graph.

 -xtickview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Yticknumber>

=item Class: B<YTickNumber>

=item Switch:	B<-yticknumber>

Number of ticks to print for the Y axis.

 -yticknumber => 10,

Default : B<4>

=item Name:	B<Ytickwidth>

=item Class: B<YtickWidth>

=item Switch:	B<-ytickwidth>

Set width of all y ticks.
 
 -ytickwidth => 10,

Default : B<5>

=item Name:	B<Ytickview>

=item Class: B<YTickView>

=item Switch:	B<-ytickview>

View y ticks of graph.

 -ytickview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Alltickview>

=item Class: B<AllTickView>

=item Switch:	B<-alltickview>

View all ticks of graph. Combines xtickview and ytickview options.

 -alltickview => 0, # 0 or 1

Default : B<undef>

=item Name:	B<Linewidth>

=item Class: B<LineWidth>

=item Switch:	B<-linewidth>

Set width of all lines graph of dataset.

 -linewidth => 10,

Default : B<1>

=item Name:	B<Colordata>

=item Class: B<ColorData>

=item Switch:	B<-colordata>

This controls the colors of the lines. This should be a reference 
to an array of color names.

 -colordata => [ qw(green pink blue cyan) ],

Default : 

  [ 'red',     'green',   'blue',    'yellow',  'purple',  'cyan',
    '#996600', '#99A6CC', '#669933', '#929292', '#006600', '#FFE100',
    '#00A6FF', '#009060', '#B000E0', '#A08000', 'orange',  'brown',
    'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
  ],

The default array contains 24 colors. If you have more than 24 samples, the next line 
will have the color of the first array case (red).

=back

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 add_data

=over 4

=item I<$GraphDummies>->B<add_data>(I<\@NewData, ?$legend>)

This method allows you to add data in your graph. If you have already plot data 
using plot method and if you want to add new data, you can use this method.
Your graph will be updade.

=back

=over 8

=item *

I<Data array reference>

Fill an array of arrays with the values of the datasets (I<\@data>). 
Make sure that every array has the same size, otherwise 
Tk::ForDummies::Graph::Lines will complain and refuse to compile the graph.

  my $one     = [ 210 .. 275 ];
  my $two     = [ 180, 190, 200, 220, 235, 245 ];
  my $three   = [ 40, 140 .. 150, 160 .. 180, 250 ];
  my $four    = [ 100 .. 125, 136 .. 140 ];
  my $five    = [ 10 .. 50, 100, 180 ];
  my @NewData = ( $one, $two, $three, $four, $five );
  $GraphDummies->add_data( \@NewData, 'new legend' );

If your last graph has a legend, you have to add a 
legend entry for the new dataset. Otherwise, 
the legend graph will not be display (see below).

=item *

I<$legend>

  my $legend = 'New data set';
  $GraphDummies->add_data(\@NewData, $legend);

=back

=head2 boxplot_information

=over 4

=item I<$GraphDummies>->B<boxplot_information>

Use this method if you want to get the informations about all boxplots 
(25th percentile (Q1), 75th percentile (Q3), smallest non-outlier, 
largest non-outlier, median and mean). This method returns an array reference. 
The informations are stored in a hash reference.

  my $ArrayRefInformation = $GraphDummies->boxplot_information();
  
  # Print information of boxplot @{$data[2][3]} (2th sample, 4th data )
  print "Boxplot @{$data[2][3]} (2th sample, 4th data )\n";
  print "Outliers : @{$ArrayRefInformation->[1][3]->{outliers}}\n";
  print '25th percentile (Q1) : ', $ArrayRefInformation->[1][3]->{Q1}, "\n";
  print '75th percentile (Q3) :',  $ArrayRefInformation->[1][3]->{Q3}, "\n";
  print 'Smallest non-outlier : ',
    $ArrayRefInformation->[1][3]->{smallest_non_outlier}, "\n";
  print 'Largest non-outlier :', $ArrayRefInformation->[1][3]->{largest_non_outlier},
    "\n";
  print 'Median : ', $ArrayRefInformation->[1][3]->{median}, "\n";
  print 'Mean : ',   $ArrayRefInformation->[1][3]->{mean},   "\n";

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

  $Ref_hash_information = $ArrayRefInformation->[2][1];
  # 25th percentile (Q1)
  print $Ref_hash_information->{Q1};
  # Smallest non-outlier
  print $Ref_hash_information->{smallest_non_outlier};

The quantile is calculated with the same algorithm as Excel and type 
7 quantile R package.

=back

=head2 clearchart

=over 4

=item I<$GraphDummies>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 delete_balloon

=over 4

=item I<$GraphDummies>->B<delete_balloon>

If you call this method, you disable help identification which has been enabled 
with set_balloon method.

=back

=head2 disabled_automatic_redraw

=over 4

=item I<$GraphDummies>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $GraphDummies->disabled_automatic_redraw;  

=back

=head2 enabled_automatic_redraw

=over 4

=item I<$GraphDummies>->B<enabled_automatic_redraw>

Use this method to allow your graph to be recreated automatically when the widget size change. When the graph 
is created for the first time, this method is called. 

  $GraphDummies->enabled_automatic_redraw;  

=back

=head2 plot

=over 4

=item I<$GraphDummies>->B<plot>(I<\@data, ?arg>)

To display your graph the first time, plot the graph by using this method.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the x values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::ForDummies::Graph::Boxplots 
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
 $GraphDummies->plot( \@data,
   -substitutionvalue => '12',
 );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (Eg : 12, .25, 02.25, 5.2e+11, ...) 

=back

=head2 redraw

Redraw the graph. 

If you have used clearchart for any reason, it is possible to redraw the graph.
Tk::ForDummies::Graph::Boxplots supports the configure and cget methods 
described in the L<Tk::options> manpage. If you use configure method to change 
a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, 
call B<redraw> method to resolv the bug.

 ...
 $fenetre->Button(-text => 'Change xlabel', -command => sub { 
   $GraphDummies->configure(-xlabel => 'red'); 
   } 
 )->pack;
 ...
 # xlabel will be changed but not displayed if you not resize the widget.
  
 ...
 $fenetre->Button(-text => 'Change xlabel', -command => sub { 
   $GraphDummies->configure(-xlabel => 'red'); 
   $GraphDummies->redraw; 
   } 
 )->pack;
 ...
 # OK, xlabel will be changed and displayed without resize the widget.

=head2 set_balloon

=over 4

=item I<$GraphDummies>->B<set_balloon>(I<? %Options>)

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

=item I<$GraphDummies>->B<set_legend>(I<? %Options>)

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

-legendfont => I<string>

Set the font to legend text.

 -legendfont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {normal}>

=item *

-box => I<boolean>

Set a box around all legend.

 -box => 0,

Default : B<1>

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

zoom the graph. The x axis and y axis will be zoomed. If your graph has 
a 300*300 size, after a zoom(200), the graph will have a 600*600 size.

$GraphDummies->zoom(I<$zoom>);

$zoom must be an integer great than 0.

 $GraphDummies->zoom(50); # size divide by 2 => 150*150
 ...
 $GraphDummies->zoom(200); # size multiplie by 2 => 600*600
 ...
 $GraphDummies->zoom(120); # 20% add in each axis => 360*360
 ...
 $GraphDummies->zoom(100); # original resize 300*300. 


=head2 zoomx

zoom the graph the x axis.

 # original canvas size 300*300
 $GraphDummies->zoomx(50); # new size : 150*300
 ...
 $GraphDummies->zoom(100); # new size : 300*300

=head2 zoomy

zoom the graph the y axis.

 # original canvas size 300*300
 $GraphDummies->zoomy(50); # new size : 300*150
 ...
 $GraphDummies->zoom(100); # new size : 300*300


=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-ForDummies-Graph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-ForDummies-Graph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::ForDummies::Graph>, L<Tk::ForDummies::Graph::FAQ>, L<GD::Graph>, L<Tk::Graph>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::ForDummies::Graph::Boxplots

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-ForDummies-Graph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-ForDummies-Graph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-ForDummies-Graph>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-ForDummies-Graph/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
