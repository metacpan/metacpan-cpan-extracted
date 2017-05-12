package Tk::ForDummies::Graph;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 20/09/2010 20:45:57
# AIM       : Private functions for Dummies Graph modules
#==================================================================
use strict;
use warnings;
use Carp;
use Tk::ForDummies::Graph::Utils qw (:DUMMIES);
use vars qw($VERSION);
$VERSION = '1.14';

use Exporter;

my @ModuleToExport = qw (
  _TreatParameters         _InitConfig    _error
  _CheckSizeLengendAndData _ZoomCalcul    _DestroyBalloonAndBind
  _CreateType              _GetMarkerType _display_line
  _box                     _title         _XLabelPosition
  _YLabelPosition          _ytick         _GraphForDummiesConstruction
);

our @ISA         = qw(Exporter);
our @EXPORT_OK   = @ModuleToExport;
our %EXPORT_TAGS = ( DUMMIES => \@ModuleToExport );

sub _InitConfig {
  my $CompositeWidget = shift;
  my %Configuration   = (
    'Axis' => {
      Cx0   => undef,
      Cx0   => undef,
      CxMin => undef,
      CxMax => undef,
      CyMin => undef,
      CyMax => undef,
      Xaxis => {
        Width             => undef,
        Height            => undef,
        xlabelHeight      => 30,
        ScaleValuesHeight => 30,
        TickHeight        => 5,
        CxlabelX          => undef,
        CxlabelY          => undef,
        Idxlabel          => undef,
        IdxTick           => undef,
        TagAxis0          => 'Axe00',
      },
      Yaxis => {
        ylabelWidth      => 5,
        ScaleValuesWidth => 60,
        TickWidth        => 5,
        TickNumber       => 4,
        Width            => undef,
        Height           => undef,
        CylabelX         => undef,
        CylabelY         => undef,
        Idylabel         => undef,
      },
    },
    'Balloon' => {
      Obj               => undef,
      Message           => {},
      State             => 0,
      ColorData         => [ '#000000', '#CB89D3' ],
      MorePixelSelected => 2,
      Background        => 'snow',
      BalloonMsg        => undef,
      IdLegData         => undef,
    },
    'Canvas' => {
      Height           => 400,
      Width            => 400,
      HeightEmptySpace => 20,
      WidthEmptySpace  => 20,
      YTickWidth       => 2,
    },
    'Data' => {
      RefXLegend             => undef,
      RefAllData             => undef,
      PlotDefined            => undef,
      MaxYValue              => undef,
      MinYValue              => undef,
      GetIdData              => {},
      SubstitutionValue      => 0,
      NumberRealData         => undef,
      RefDataToDisplay       => undef,
      RefOptionDataToDisplay => undef,
    },
    'Font' => {
      Default            => '{Times} 10 {normal}',
      DefaultTitle       => '{Times} 12 {bold}',
      DefaultLabel       => '{Times} 10 {bold}',
      DefaultLegend      => '{Times} 8 {normal}',
      DefaultLegendTitle => '{Times} 8 {bold}',
      DefaultBarValues   => '{Times} 8 {normal}',
    },
    'Legend' => {
      HeightTitle     => 30,
      HLine           => 20,
      WCube           => 10,
      HCube           => 10,
      SpaceBeforeCube => 5,
      SpaceAfterCube  => 5,
      WidthText       => 250,
      NbrLegPerLine   => undef,
      '-width'        => undef,
      Height          => 0,
      Width           => undef,
      LengthOneLegend => undef,
      DataLegend      => undef,
      LengthTextMax   => undef,
      GetIdLeg        => {},
      title           => undef,
      titlefont       => '{Times} 12 {bold}',
      titlecolors     => 'black',
      Colors          => [
        'red',     'green',   'blue',    'yellow',  'purple',  'cyan',    '#996600', '#99A6CC',
        '#669933', '#929292', '#006600', '#FFE100', '#00A6FF', '#009060', '#B000E0', '#A08000',
        'orange',  'brown',   'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
      ],
      NbrLegend => 0,
      box       => 0,
    },
    'TAGS' => {
      AllTagsDummiesGraph => '_AllTagsDummiesGraph',
      AllAXIS             => '_AllAXISTag',
      yAxis               => '_yAxisTag',
      xAxis               => '_xAxisTag',
      'xAxis0'            => '_0AxisTag',
      BoxAxis             => '_BoxAxisTag',
      xTick               => '_xTickTag',
      yTick               => '_yTickTag',
      AllTick             => '_AllTickTag',
      'xValue0'           => '_xValue0Tag',
      xValues             => '_xValuesTag',
      yValues             => '_yValuesTag',
      AllValues           => '_AllValuesTag',
      TitleLegend         => '_TitleLegendTag',
      BoxLegend           => '_BoxLegendTag',
      AllData             => '_AllDataTag',
      AllPie              => '_AllPieTag',
      Area                => '_AreaTag',
      Pie                 => '_PieTag',
      PointLine           => '_PointLineTag',
      Line                => '_LineTag',
      Point               => '_PointTag',
      Bar                 => '_BarTag',
      Mixed               => '_MixedTag',
      Legend              => '_LegendTag',
      DashLines           => '_DashLineTag',
      BarValues           => '_BarValuesTag',
      Boxplot             => '_BoxplotTag',
    },
    'Title' => {
      Ctitrex  => undef,
      Ctitrey  => undef,
      IdTitre  => undef,
      '-width' => undef,
      Width    => undef,
      Height   => 40,
    },
    'Zoom' => {
      CurrentX => 100,
      CurrentY => 100,
    },
  );

  return \%Configuration;
}

sub _TreatParameters {
  my ($CompositeWidget) = @_;

  my @IntegerOption = qw /
    -xlabelheight -xlabelskip     -xvaluespace  -ylabelwidth
    -boxaxis      -noaxis         -zeroaxisonly -xtickheight
    -xtickview    -yticknumber    -ytickwidth   -linewidth
    -alltickview  -xvaluevertical -titleheight  -gridview
    -ytickview    -overwrite      -cumulate     -spacingbar
    -showvalues   -startangle     -viewsection  -zeroaxis
    -longticks    -markersize     -pointline
    -smoothline   -spline         -bezier
    /;

  foreach my $OptionName (@IntegerOption) {
    my $data = $CompositeWidget->cget($OptionName);
    if ( defined $data and $data !~ m{^\d+$} ) {
      $CompositeWidget->_error( "'Can't set $OptionName to `$data', $data' isn't numeric", 1 );
      return;
    }
  }

  my $xvaluesregex = $CompositeWidget->cget( -xvaluesregex );
  if ( defined $xvaluesregex and ref($xvaluesregex) !~ m{^Regexp$}i ) {
    $CompositeWidget->_error(
      "'Can't set -xvaluesregex to `$xvaluesregex', "
        . "$xvaluesregex' is not a regex expression\nEx : "
        . "-xvaluesregex => qr/My regex/;",
      1
    );
    return;
  }

  my $gradient = $CompositeWidget->cget( -gradient );
  if ( defined $gradient and ref($gradient) !~ m{^hash$}i ) {
    $CompositeWidget->_error(
      "'Can't set -gradient to `$gradient', " . "$gradient' is not a hash reference expression\n", 1 );
    return;
  }

  my $Colors = $CompositeWidget->cget( -colordata );
  if ( defined $Colors and ref($Colors) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -colordata to `$Colors', "
        . "$Colors' is not an array reference\nEx : "
        . "-colordata => [\"blue\",\"#2400FF\",...]",
      1
    );
    return;
  }
  my $Markers = $CompositeWidget->cget( -markers );
  if ( defined $Markers and ref($Markers) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -markers to `$Markers', "
        . "$Markers' is not an array reference\nEx : "
        . "-markers => [5,8,2]",
      1
    );

    return;
  }
  my $Typemixed = $CompositeWidget->cget( -typemixed );
  if ( defined $Typemixed and ref($Typemixed) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -typemixed to `$Typemixed', "
        . "$Typemixed' is not an array reference\nEx : "
        . "-typemixed => ['bars','lines',...]",
      1
    );

    return;
  }

  if ( my $xtickheight = $CompositeWidget->cget( -xtickheight ) ) {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight} = $xtickheight;
  }

  # -smoothline deprecated, use -bezier
  if ( my $smoothline = $CompositeWidget->cget( -smoothline ) ) {
    $CompositeWidget->configure( -bezier => $smoothline );
  }

  if ( my $xvaluespace = $CompositeWidget->cget( -xvaluespace ) ) {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight} = $xvaluespace;
  }

  if ( my $noaxis = $CompositeWidget->cget( -noaxis ) and $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight} = 0;
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth}  = 0;
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth}         = 0;
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}        = 0;
  }

  if ( my $title = $CompositeWidget->cget( -title ) ) {
    if ( my $titleheight = $CompositeWidget->cget( -titleheight ) ) {
      $CompositeWidget->{RefInfoDummies}->{Title}{Height} = $titleheight;
    }
  }
  else {
    $CompositeWidget->{RefInfoDummies}->{Title}{Height} = 0;
  }

  if ( my $xlabel = $CompositeWidget->cget( -xlabel ) ) {
    if ( my $xlabelheight = $CompositeWidget->cget( -xlabelheight ) ) {
      $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight} = $xlabelheight;
    }
  }
  else {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight} = 0;
  }

  if ( my $ylabel = $CompositeWidget->cget( -ylabel ) ) {
    if ( my $ylabelWidth = $CompositeWidget->cget( -ylabelWidth ) ) {
      $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth} = $ylabelWidth;
    }
  }
  else {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth} = 0;
  }

  if ( my $ytickwidth = $CompositeWidget->cget( -ytickwidth ) ) {
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth} = $ytickwidth;
  }

  if ( my $valuescolor = $CompositeWidget->cget( -valuescolor ) ) {
    $CompositeWidget->configure( -xvaluecolor => $valuescolor );
    $CompositeWidget->configure( -yvaluecolor => $valuescolor );
  }

  if ( my $textcolor = $CompositeWidget->cget( -textcolor ) ) {
    $CompositeWidget->configure( -titlecolor  => $textcolor );
    $CompositeWidget->configure( -xlabelcolor => $textcolor );
    $CompositeWidget->configure( -ylabelcolor => $textcolor );
  }
  elsif ( my $labelscolor = $CompositeWidget->cget( -labelscolor ) ) {
    $CompositeWidget->configure( -xlabelcolor => $labelscolor );
    $CompositeWidget->configure( -ylabelcolor => $labelscolor );
  }

  if ( my $textfont = $CompositeWidget->cget( -textfont ) ) {
    $CompositeWidget->configure( -titlefont  => $textfont );
    $CompositeWidget->configure( -xlabelfont => $textfont );
    $CompositeWidget->configure( -ylabelfont => $textfont );
  }
  if ( my $startangle = $CompositeWidget->cget( -startangle ) ) {
    if ( $startangle < 0 or $startangle > 360 ) {
      $CompositeWidget->configure( -startangle => 0 );
    }
  }
  if ( my $longticks = $CompositeWidget->cget( -longticks ) ) {
    if ( $longticks == 1 ) {
      $CompositeWidget->configure( -boxaxis => 1 );
    }
  }

=for borderwidth:
  If user call -borderwidth option, the graph will be trunc.
  Then we will add HeightEmptySpace and WidthEmptySpace.

=cut

  if ( my $borderwidth = $CompositeWidget->cget( -borderwidth ) ) {
    $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace} = $borderwidth + 15;
    $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}  = $borderwidth + 15;
  }

  return 1;
}

sub _CheckSizeLengendAndData {
  my ( $CompositeWidget, $RefData, $RefLegend ) = @_;

  # Check legend size
  unless ( defined $RefLegend ) {
    $CompositeWidget->_error('legend not defined');
    return;
  }
  my $SizeLegend = scalar @{$RefLegend};

  # Check size between legend and data
  my $SizeData = scalar @{$RefData} - 1;
  unless ( $SizeLegend == $SizeData ) {
    $CompositeWidget->_error('Legend and array size data are different');
    return;
  }

  return 1;
}

sub _ZoomCalcul {
  my ( $CompositeWidget, $ZoomX, $ZoomY ) = @_;

  if ( ( defined $ZoomX and !( _isANumber($ZoomX) or $ZoomX > 0 ) )
    or ( defined $ZoomY and !( _isANumber($ZoomY) or $ZoomY > 0 ) )
    or ( not defined $ZoomX and not defined $ZoomY ) )
  {
    $CompositeWidget->_error( 'zoom value must be defined, numeric and great than 0', 1 );
    return;
  }

  my $CurrentWidth  = $CompositeWidget->{RefInfoDummies}->{Canvas}{Width};
  my $CurrentHeight = $CompositeWidget->{RefInfoDummies}->{Canvas}{Height};

  my $CentPercentWidth  = ( 100 / $CompositeWidget->{RefInfoDummies}->{Zoom}{CurrentX} ) * $CurrentWidth;
  my $CentPercentHeight = ( 100 / $CompositeWidget->{RefInfoDummies}->{Zoom}{CurrentY} ) * $CurrentHeight;
  my $NewWidth          = ( $ZoomX / 100 ) * $CentPercentWidth
    if ( defined $ZoomX );
  my $NewHeight = ( $ZoomY / 100 ) * $CentPercentHeight
    if ( defined $ZoomY );

  $CompositeWidget->{RefInfoDummies}->{Zoom}{CurrentX} = $ZoomX
    if ( defined $ZoomX );
  $CompositeWidget->{RefInfoDummies}->{Zoom}{CurrentY} = $ZoomY
    if ( defined $ZoomY );

  return ( $NewWidth, $NewHeight );
}

sub _DestroyBalloonAndBind {
  my ($CompositeWidget) = @_;

  # balloon defined and user want to stop it
  if ( $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}
    and Tk::Exists $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj} )
  {
    $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}->configure( -state => 'none' );
    $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}->detach($CompositeWidget);

    #$CompositeWidget->{RefInfoDummies}->{Balloon}{Obj}->destroy;

    undef $CompositeWidget->{RefInfoDummies}->{Balloon}{Obj};
  }

  return;
}

sub _error {
  my ( $CompositeWidget, $ErrorMessage, $Croak ) = @_;

  if ( defined $Croak and $Croak == 1 ) {
    croak "[BE CARREFUL] : $ErrorMessage\n";
  }
  else {
    warn "[WARNING] : $ErrorMessage\n";
  }

  return;
}

sub _GetMarkerType {
  my ( $CompositeWidget, $Number ) = @_;
  my %MarkerType = (

    # N°      Type                Filled
    1  => [ 'square',           1 ],
    2  => [ 'square',           0 ],
    3  => [ 'horizontal cross', 1 ],
    4  => [ 'diagonal cross',   1 ],
    5  => [ 'diamond',          1 ],
    6  => [ 'diamond',          0 ],
    7  => [ 'circle',           1 ],
    8  => [ 'circle',           0 ],
    9  => [ 'horizontal line',  1 ],
    10 => [ 'vertical line',    1 ],
  );

  return unless ( defined $MarkerType{$Number} );

  return $MarkerType{$Number};
}

=for _CreateType
  Calculate different points coord to create a rectangle, circle, 
  verticale or horizontal line, a cross, a plus and a diamond 
  from a point coord.
  Arg : Reference of hash
  {
    x      => value,
    y      => value,
    pixel  => value,
    type   => string, (circle, cross, plus, diamond, rectangle, Vline, Hline )
    option => Hash reference ( {-fill => xxx, -outline => yy, ...} )
  }

=cut

sub _CreateType {
  my ( $CompositeWidget, %Refcoord ) = @_;

  if ( $Refcoord{type} eq 'circle' or $Refcoord{type} eq 'square' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );

    if ( $Refcoord{type} eq 'circle' ) {
      $CompositeWidget->createOval( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    }
    else {
      $CompositeWidget->createRectangle( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    }
  }
  elsif ( $Refcoord{type} eq 'horizontal cross' ) {
    my $x1 = $Refcoord{x};
    my $y1 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x2 = $x1;
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x3 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y3 = $Refcoord{y};
    my $x4 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y4 = $y3;
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    $CompositeWidget->createLine( $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'diagonal cross' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x3 = $x1;
    my $y3 = $y2;
    my $x4 = $x2;
    my $y4 = $y1;
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    $CompositeWidget->createLine( $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'diamond' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y};
    my $x2 = $Refcoord{x};
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x3 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y3 = $Refcoord{y};
    my $x4 = $Refcoord{x};
    my $y4 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    $CompositeWidget->createPolygon( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'vertical line' ) {
    my $x1 = $Refcoord{x};
    my $y1 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x};
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'horizontal line' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y};
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y};
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
  }
  else {
    return;
  }

  return 1;
}

=for _display_line
  Dispay point
  Arg : Reference of hash
  {
    x      => value,
    y      => value,
    pixel  => value,
    type   => string, (circle, cross, plus, diamond, rectangle, Vline, Hline )
    option => Hash reference ( {-fill => xxx, -outline => yy, ...} )
  }

=cut

# $CompositeWidget->_display_line($RefPoints, $LineNumber);
sub _display_line {
  my ( $CompositeWidget, $RefPoints, $LineNumber ) = @_;

  my $RefDataToDisplay = $CompositeWidget->{RefInfoDummies}->{Data}{RefDataToDisplay};
  return unless ( defined $RefDataToDisplay and defined $RefDataToDisplay->[$LineNumber] );

  my %options;
  my $font  = $CompositeWidget->{RefInfoDummies}->{Data}{RefOptionDataToDisplay}{'-font'};
  my $color = $CompositeWidget->{RefInfoDummies}->{Data}{RefOptionDataToDisplay}{'-foreground'};
  $options{'-font'} = $font  if ( defined $font );
  $options{'-fill'} = $color if ( defined $color );

  my $indice_point = 0;

DISPLAY:
  foreach my $value ( @{ $RefDataToDisplay->[$LineNumber] } ) {
    if ( defined $value ) {
      my $x = $RefPoints->[$indice_point];
      $indice_point++;
      my $y = $RefPoints->[$indice_point] - 10;
      $CompositeWidget->createText(
        $x, $y,
        -text => $value,
        %options,
      );
      $indice_point++;
      last DISPLAY unless defined $RefPoints->[$indice_point];
      next DISPLAY;
    }
    $indice_point += 2;
  }

  return;
}

sub _box {
  my ($CompositeWidget) = @_;

  # close axis
  # X axis 2
  $CompositeWidget->createLine(
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{BoxAxis},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  # Y axis 2
  $CompositeWidget->createLine(
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax},
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{BoxAxis},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  return;
}

sub _ytick {
  my ($CompositeWidget) = @_;

  my $longticks = $CompositeWidget->cget( -longticks );
  $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickNumber} = $CompositeWidget->cget( -yticknumber );

  # space between y ticks
  my $Space = $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}
    / $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickNumber};
  my $UnitValue
    = ( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue}
      - $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} )
    / $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickNumber};

  for my $TickNumber ( 1 .. $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickNumber} ) {

    # Display y ticks
    my $Ytickx1 = $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0};
    my $Yticky1 = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin} - ( $TickNumber * $Space );
    my $Ytickx2 = $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0}
      - $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth};
    my $Yticky2 = $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin} - ( $TickNumber * $Space );

    my $YValuex
      = $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0}
      - ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth}
        + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth} / 2 );
    my $YValuey = $Yticky1;
    my $Value   = $UnitValue * $TickNumber + $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue};
    next if ( $Value == 0 );

    # Long tick
    if ( defined $longticks and $longticks == 1 ) {
      $Ytickx1 = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin};
      $Ytickx2 = $CompositeWidget->{RefInfoDummies}->{Axis}{CxMax};
    }

    # round value if to long
    if ( $Value > 1000000 or length $Value > 7 ) {
      $Value = _roundValue($Value);
    }

    $CompositeWidget->createLine(
      $Ytickx1, $Yticky1, $Ytickx2, $Yticky2,
      -tags => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{yTick},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTick},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
    $CompositeWidget->createText(
      $YValuex, $YValuey,
      -text => $Value,
      -fill => $CompositeWidget->cget( -yvaluecolor ),
      -tags => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{yValues},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllValues},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
  }

  # Display 0 value
  unless ( $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} == 0 ) {
    $CompositeWidget->createText(
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0}
        - ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth} ),
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cy0},
      -text => 0,
      -tags => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{xValue0},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllValues},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
  }

  # Display the minimale value
  $CompositeWidget->createText(
    $CompositeWidget->{RefInfoDummies}->{Axis}{CxMin} - (
          $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth}
        + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth} / 2
    ),
    $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin},
    -text => _roundValue( $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} ),
    -fill => $CompositeWidget->cget( -yvaluecolor ),
    -tags => [
      $CompositeWidget->{RefInfoDummies}->{TAGS}{yValues},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllValues},
      $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
    ],
  );

  # Long tick
  unless ( defined $longticks and $longticks == 1 ) {
    $CompositeWidget->createLine(
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0},
      $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin} - $Space,
      $CompositeWidget->{RefInfoDummies}->{Axis}{Cx0}
        - $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth},
      $CompositeWidget->{RefInfoDummies}->{Axis}{CyMin} - $Space,
      -tags => [
        $CompositeWidget->{RefInfoDummies}->{TAGS}{yTick},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTick},
        $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph},
      ],
    );
  }

  return;
}

sub _title {
  my ($CompositeWidget) = @_;

  my $Title         = $CompositeWidget->cget( -title );
  my $TitleColor    = $CompositeWidget->cget( -titlecolor );
  my $TitleFont     = $CompositeWidget->cget( -titlefont );
  my $titleposition = $CompositeWidget->cget( -titleposition );

  # Title verification
  unless ($Title) {
    return;
  }

  # Space before the title
  my $WidthEmptyBeforeTitle
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth};

  # Coordinates title
  $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex}
    = ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width} / 2 ) + $WidthEmptyBeforeTitle;
  $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey}
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}
    + ( $CompositeWidget->{RefInfoDummies}->{Title}{Height} / 2 );

  # -width to createText
  $CompositeWidget->{RefInfoDummies}->{Title}{'-width'}
    = $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width};

  # display title
  my $anchor;
  if ( $titleposition eq 'left' ) {
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex}  = $WidthEmptyBeforeTitle;
    $anchor                                               = 'nw';
    $CompositeWidget->{RefInfoDummies}->{Title}{'-width'} = 0;
  }
  elsif ( $titleposition eq 'right' ) {
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex}
      = $WidthEmptyBeforeTitle + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width};
    $CompositeWidget->{RefInfoDummies}->{Title}{'-width'} = 0;
    $anchor = 'ne';
  }
  else {
    $anchor = 'center';
  }
  $CompositeWidget->{RefInfoDummies}->{Title}{IdTitre} = $CompositeWidget->createText(
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex},
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey},
    -text   => $Title,
    -width  => $CompositeWidget->{RefInfoDummies}->{Title}{'-width'},
    -anchor => $anchor,
    -tags   => [ $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
  );
  return if ( $anchor =~ m{^left|right$} );

  # get title information
  my ($Height);
  ( $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex},
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey},
    $CompositeWidget->{RefInfoDummies}->{Title}{Width}, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefInfoDummies}->{Title}{IdTitre} );

  if ( $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey}
    < $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace} )
  {

    # cut title
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{Title}{IdTitre} );

    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex} = $WidthEmptyBeforeTitle;
    $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey}
      = $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}
      + ( $CompositeWidget->{RefInfoDummies}->{Title}{Height} / 2 );

    $CompositeWidget->{RefInfoDummies}->{Title}{'-width'} = 0;

    # display title
    $CompositeWidget->{RefInfoDummies}->{Title}{IdTitre} = $CompositeWidget->createText(
      $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrex},
      $CompositeWidget->{RefInfoDummies}->{Title}{Ctitrey},
      -text   => $Title,
      -width  => $CompositeWidget->{RefInfoDummies}->{Title}{'-width'},
      -anchor => 'nw',
      -tags   => [ $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
    );
  }

  $CompositeWidget->itemconfigure(
    $CompositeWidget->{RefInfoDummies}->{Title}{IdTitre},
    -font => $TitleFont,
    -fill => $TitleColor,
  );
  return;
}

sub _XLabelPosition {
  my ($CompositeWidget) = @_;

  my $xlabel = $CompositeWidget->cget( -xlabel );

  # no x_label
  unless ( defined $xlabel ) {
    return;
  }

  # coordinate (CxlabelX, CxlabelY)
  my $BeforexlabelX
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{TickWidth};
  my $BeforexlabelY
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}
    + $CompositeWidget->{RefInfoDummies}->{Title}{Height}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{TickHeight}
    + $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{ScaleValuesHeight};

  $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelX}
    = $BeforexlabelX + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width} / 2 );
  $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY}
    = $BeforexlabelY + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight} / 2 );

  # display xlabel
  $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Idxlabel} = $CompositeWidget->createText(
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelX},
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY},
    -text  => $xlabel,
    -width => $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Width},
    -tags  => [ $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
  );

  # get info ylabel xlabel
  my ( $width, $Height );
  ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelX},
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY},
    $width, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Idxlabel} );

  if ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY} < $BeforexlabelY ) {

    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Idxlabel} );

    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelX} = $BeforexlabelX;
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY}
      = $BeforexlabelY + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{xlabelHeight} / 2 );

    # display xlabel
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Idxlabel} = $CompositeWidget->createText(
      $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelX},
      $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{CxlabelY},
      -text   => $xlabel,
      -width  => 0,
      -anchor => 'nw',
      -tags   => [ $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
    );
  }

  $CompositeWidget->itemconfigure(
    $CompositeWidget->{RefInfoDummies}->{Axis}{Xaxis}{Idxlabel},
    -font => $CompositeWidget->cget( -xlabelfont ),
    -fill => $CompositeWidget->cget( -xlabelcolor ),
  );

  return;
}

sub _YLabelPosition {
  my ($CompositeWidget) = @_;

  my $ylabel = $CompositeWidget->cget( -ylabel );

  # no y_label
  unless ( defined $ylabel ) {
    return;
  }

  # coordinate (CylabelX, CylabelY)
  $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelX}
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace}
    + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth} / 2 );
  $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelY}
    = $CompositeWidget->{RefInfoDummies}->{Canvas}{HeightEmptySpace}
    + $CompositeWidget->{RefInfoDummies}->{Title}{Height}
    + ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Height} / 2 );

  # display ylabel
  $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Idylabel} = $CompositeWidget->createText(
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelX},
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelY},
    -text  => $ylabel,
    -font  => $CompositeWidget->cget( -ylabelfont ),
    -width => $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{ylabelWidth},
    -fill  => $CompositeWidget->cget( -ylabelcolor ),
    -tags  => [ $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTagsDummiesGraph}, ],
  );

  # get info ylabel
  my ( $Width, $Height );
  ( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelX},
    $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{CylabelY},
    $Width, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefInfoDummies}->{Axis}{Yaxis}{Idylabel} );

  return;
}

sub _GraphForDummiesConstruction {
  my ($CompositeWidget) = @_;

  unless ( defined $CompositeWidget->{RefInfoDummies}->{Data}{PlotDefined} ) {
    return;
  }

  $CompositeWidget->clearchart();
  $CompositeWidget->_TreatParameters();

  # For background gradient color
  $CompositeWidget->set_gradientcolor;

  # Pie graph
  if ( $CompositeWidget->class eq 'Pie' ) {

    # Width Pie
    $CompositeWidget->{RefInfoDummies}->{Pie}{Width} = $CompositeWidget->{RefInfoDummies}->{Canvas}{Width}
      - ( 2 * $CompositeWidget->{RefInfoDummies}->{Canvas}{WidthEmptySpace} );

    if ( $CompositeWidget->{RefInfoDummies}->{Data}{RefAllData} ) {
      $CompositeWidget->_titlepie;
      $CompositeWidget->_ViewData;
      $CompositeWidget->_ViewLegend();
    }
    return;
  }

  # Height and Width canvas
  $CompositeWidget->{RefInfoDummies}->{Canvas}{Width}  = $CompositeWidget->width;
  $CompositeWidget->{RefInfoDummies}->{Canvas}{Height} = $CompositeWidget->height;

  $CompositeWidget->_axis();
  $CompositeWidget->_box();
  $CompositeWidget->_YLabelPosition();
  $CompositeWidget->_XLabelPosition();
  $CompositeWidget->_title();

  if ( $CompositeWidget->class eq 'Lines' ) {
    if ( $CompositeWidget->cget( -pointline ) == 1 ) {
      $CompositeWidget->_ViewDataPoints();
    }
    else {
      $CompositeWidget->_ViewDataLines();
    }
  }
  else {
    $CompositeWidget->_ViewData();
  }

  #
  unless ( $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->_xtick();
    $CompositeWidget->_ytick();
  }

  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{NbrLegend} > 0 ) {
    $CompositeWidget->_ViewLegend();
    $CompositeWidget->_Balloon();
  }

  # If Y value < 0, don't display O x axis
  if ( $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} < 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xAxis0} );
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xValue0} );
  }

  # Axis
  if ( $CompositeWidget->cget( -boxaxis ) == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{BoxAxis} );
  }
  if ( $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{AllAXIS} );
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTick} );
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{AllValues} );
  }
  if (  $CompositeWidget->cget( -zeroaxisonly ) == 1
    and $CompositeWidget->{RefInfoDummies}->{Data}{MaxYValue} > 0
    and $CompositeWidget->{RefInfoDummies}->{Data}{MinYValue} < 0 )
  {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xAxis} );
  }
  if ( $CompositeWidget->cget( -zeroaxis ) == 1 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xAxis0} );
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xTick} );
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xValues} );
  }
  if ( $CompositeWidget->cget( -xvalueview ) == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xValues} );
  }
  if ( $CompositeWidget->cget( -yvalueview ) == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{yValues} );
  }

  # ticks
  my $alltickview = $CompositeWidget->cget( -alltickview );
  if ( defined $alltickview ) {
    if ( $alltickview == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{AllTick} );
    }
    else {
      $CompositeWidget->configure( -ytickview => 1 );
      $CompositeWidget->configure( -xtickview => 1 );
    }
  }
  else {
    if ( $CompositeWidget->cget( -xtickview ) == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{xTick} );
    }
    if ( $CompositeWidget->cget( -ytickview ) == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{yTick} );
    }
  }

  # Legend
  if ( $CompositeWidget->{RefInfoDummies}->{Legend}{box} == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefInfoDummies}->{TAGS}{BoxLegend} );
  }

  if ( $CompositeWidget->class eq 'Mixed' ) {

    # Order displaying data
    $CompositeWidget->display_order;
  }
  return 1;
}

1;

__END__

=head1 NAME

Tk::ForDummies::Graph - DEPRECATED : now use Tk::Chart. 

=head1 SYNOPSIS

DEPRECATED : please does not use this module, but use now L<Tk::Chart>.

=head1 DESCRIPTION

B<Tk::ForDummies::Graph> is a module to create and display graphs on a Tk widget. 
The module is written entirely in Perl/Tk.

You can set a background gradient color by using L<Tk::Canvas::GradientColor> methods.

You can change the color, font of title, labels (x and y) of graphs.
You can set an interactive legend. The axes can be automatically scaled or set by the code.

When the mouse cursor passes over a plotted line, bars, pie or its entry in the legend, 
its entry will be turned to a color to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

L<Tk::ForDummies::Graph::Lines>, 
Extension of Canvas widget to create lines graph. 
With this module it is possible to plot quantitative variables according to qualitative variables.

L<Tk::ForDummies::Graph::Splines>, 
To create lines graph as B<B>E<eacute>B<zier curve>. 

L<Tk::ForDummies::Graph::Areas>, 
Extension of Canvas widget to create an area lines graph. 

L<Tk::ForDummies::Graph::Bars>,  
Extension of Canvas widget to create bars graph with vertical bars.

L<Tk::ForDummies::Graph::Pie>,  
Extension of Canvas widget to create a pie graph. 

L<Tk::ForDummies::Graph::Mixed>,  
Extension of Canvas widget to create a graph mixed with lines, lines points, splines, bars, points and areas. 

L<Tk::ForDummies::Graph::Boxplots>,  
Extension of Canvas widget to create boxplots graph. 

=head1 EXAMPLES

See the samples directory in the distribution, and read documentations for each modules Tk::ForDummies::Graph::B<ModuleName>.

=head1 SEE ALSO

See L<Tk::ForDummies::Graph::FAQ>, L<Tk::Canvas::GradientColor>, L<GD::Graph>, L<Tk::Graph>, L<Tk::LineGraph>, L<Tk::PlotDataset>, L<Chart::Plot::Canvas>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-fordummies-graph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-ForDummies-Graph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::ForDummies::Graph
    perldoc Tk::ForDummies::Graph::Lines
    perldoc Tk::ForDummies::Graph::Splines
    perldoc Tk::ForDummies::Graph::Points
    perldoc Tk::ForDummies::Graph::Bars
    perldoc Tk::ForDummies::Graph::Areas
    perldoc Tk::ForDummies::Graph::Mixed
    perldoc Tk::ForDummies::Graph::Pie
    perldoc Tk::ForDummies::Graph::FAQ
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
