package Tk::Chart;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2018                                               $
# $Update    : 09/02/2018                                         $
# $AIM       : Private functions for Tk::Chart modules            $
#==================================================================

use strict;
use warnings;
use Carp;
use Tk::Chart::Utils qw / :DUMMIES /;

use vars qw($VERSION);
$VERSION = '1.22';

use Exporter;

my @module_export = qw (
  _treatparameters         _initconfig      _error
  _checksizelegend_data    _zoomcalcul      _destroyballoon_bind
  _createtype              _getmarkertype   _display_line
  _box                     _title           _xlabelposition
  _ylabelposition          _ytick           _chartconstruction
  _manage_minmaxvalues     _display_xticks  _display_yticks
  _get_configspecs
);

use base qw/ Exporter /;

our @EXPORT_OK = @module_export;
our %EXPORT_TAGS = ( DUMMIES => \@module_export );
my $DASH = q{.};
my ( $MIN_ANGLE, $MAX_ANGLE ) = ( 0, 360 );
my $BORDERWITH_PLUS = 15;
my $PERCENT         = 100;

sub _get_configspecs {

  my $ref_config = _initconfig();

  my %configuration = (
    -title         => [ 'PASSIVE', 'Title',         'Title',         undef ],
    -titlecolor    => [ 'PASSIVE', 'Titlecolor',    'TitleColor',    'black' ],
    -titlefont     => [ 'PASSIVE', 'Titlefont',     'TitleFont',     $ref_config->{Font}{DefaultTitle} ],
    -titleposition => [ 'PASSIVE', 'Titleposition', 'TitlePosition', 'center' ],
    -titleheight   => [ 'PASSIVE', 'Titleheight',   'TitleHeight',   $ref_config->{Title}{Height} ],

    -xlabel         => [ 'PASSIVE', 'Xlabel',         'XLabel',         undef ],
    -xlabelcolor    => [ 'PASSIVE', 'Xlabelcolor',    'XLabelColor',    'black' ],
    -xlabelfont     => [ 'PASSIVE', 'Xlabelfont',     'XLabelFont',     $ref_config->{Font}{DefaultLabel} ],
    -xlabelposition => [ 'PASSIVE', 'Xlabelposition', 'XLabelPosition', 'center' ],
    -xlabelheight => [ 'PASSIVE', 'Xlabelheight', 'XLabelHeight', $ref_config->{Axis}{Xaxis}{xlabelHeight} ],
    -xlabelskip   => [ 'PASSIVE', 'Xlabelskip',   'XLabelSkip',   0 ],

    -xvaluecolor    => [ 'PASSIVE', 'Xvaluecolor',    'XValueColor',    'black' ],
    -xvaluefont     => [ 'PASSIVE', 'Xvaluefont',     'XValueFont',     $ref_config->{Font}{DefaultXValues} ],
    -xvaluesregex => [ 'PASSIVE', 'Xvaluesregex', 'XValuesRegex', qr/.+/ ],
    -xvaluespace    => [ 'PASSIVE', 'Xvaluespace', 'XValueSpace', $ref_config->{Axis}{Xaxis}{ScaleValuesHeight} ],
    -xvaluevertical => [ 'PASSIVE', 'Xvaluevertical', 'XValueVertical', 0 ],
    -xvalueview     => [ 'PASSIVE', 'Xvalueview',   'XValueView',   1 ],
    -yvaluefont     => [ 'PASSIVE', 'Yvaluefont',     'YValueFont',     $ref_config->{Font}{DefaultYValues} ],
    -yvalueview   => [ 'PASSIVE', 'Yvalueview',   'YValueView',   1 ],

    -ylabel         => [ 'PASSIVE', 'Ylabel',         'YLabel',         undef ],
    -ylabelcolor    => [ 'PASSIVE', 'Ylabelcolor',    'YLabelColor',    'black' ],
    -ylabelfont     => [ 'PASSIVE', 'Ylabelfont',     'YLabelFont',     $ref_config->{Font}{DefaultLabel} ],
    -ylabelposition => [ 'PASSIVE', 'Ylabelposition', 'YLabelPosition', 'center' ],
    -ylabelwidth => [ 'PASSIVE', 'Ylabelwidth', 'YLabelWidth', $ref_config->{Axis}{Yaxis}{ylabelWidth} ],

    -yvaluecolor => [ 'PASSIVE', 'Yvaluecolor', 'YValueColor', 'black' ],

    -labelscolor => [ 'PASSIVE', 'Labelscolor', 'LabelsColor', undef ],
    -valuescolor => [ 'PASSIVE', 'Valuescolor', 'ValuesColor', undef ],
    -textcolor   => [ 'PASSIVE', 'Textcolor',   'TextColor',   undef ],
    -textfont    => [ 'PASSIVE', 'Textfont',    'TextFont',    undef ],

    -axiscolor    => [ 'PASSIVE', 'Axiscolor',    'AxisColor',    'black' ],
    -boxaxis      => [ 'PASSIVE', 'Boxaxis',      'BoxAxis',      0 ],
    -noaxis       => [ 'PASSIVE', 'Noaxis',       'NoAxis',       0 ],
    -zeroaxisonly => [ 'PASSIVE', 'Zeroaxisonly', 'ZeroAxisOnly', 0 ],
    -zeroaxis     => [ 'PASSIVE', 'Zeroaxis',     'ZeroAxis',     0 ],
    -longticks    => [ 'PASSIVE', 'Longticks',    'LongTicks',    0 ],

    -xlongticks      => [ 'PASSIVE', 'XLongticks',      'XLongTicks',      0 ],
    -ylongticks      => [ 'PASSIVE', 'YLongticks',      'YLongTicks',      0 ],
    -xlongtickscolor => [ 'PASSIVE', 'XLongtickscolor', 'XLongTicksColor', '#B3B3B3' ],
    -ylongtickscolor => [ 'PASSIVE', 'YLongtickscolor', 'YLongTicksColor', '#B3B3B3' ],
    -longtickscolor  => [ 'PASSIVE', 'Longtickscolor',  'LongTicksColor',  undef ],

    -xtickheight => [ 'PASSIVE', 'Xtickheight', 'XTickHeight', $ref_config->{Axis}{Xaxis}{TickHeight} ],
    -xtickview   => [ 'PASSIVE', 'Xtickview',   'XTickView',   1 ],

    -yminvalue => [ 'PASSIVE', 'Yminvalue', 'YMinValue', 0 ],
    -ymaxvalue => [ 'PASSIVE', 'Ymaxvalue', 'YMaxValue', undef ],
    -interval  => [ 'PASSIVE', 'interval',  'Interval',  0 ],

    # image size
    -width  => [ 'SELF', 'width',  'Width',  $ref_config->{Canvas}{Width} ],
    -height => [ 'SELF', 'height', 'Height', $ref_config->{Canvas}{Height} ],

    -yticknumber => [ 'PASSIVE', 'Yticknumber', 'YTickNumber', $ref_config->{Axis}{Yaxis}{TickNumber} ],
    -ytickwidth  => [ 'PASSIVE', 'Ytickwidth',  'YtickWidth',  $ref_config->{Axis}{Yaxis}{TickWidth} ],
    -ytickview   => [ 'PASSIVE', 'Ytickview',   'YTickView',   1 ],

    -alltickview => [ 'PASSIVE', 'Alltickview', 'AllTickView', 1 ],

    -linewidth => [ 'PASSIVE', 'Linewidth', 'LineWidth', 1 ],
    -colordata => [ 'PASSIVE', 'Colordata', 'ColorData', $ref_config->{Legend}{Colors} ],

    -legendfont => [ 'PASSIVE', 'Legendfont',  'LegendFont',  $ref_config->{Legend}{legendfont} ],

    # verbose mode
    -verbose => [ 'PASSIVE', 'verbose', 'Verbose', 1 ],
  );

  return \%configuration;
}

sub _initconfig {
  my $cw            = shift;
  my %configuration = (
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
      DefaultXValues     => '{Times} 8 {normal}',
      DefaultYValues     => '{Times} 8 {normal}',
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
      textcolor       => 'black',
      legendcolor     => 'black',
      Colors          => [
        'red',     'green',   'blue',    'yellow',  'purple',  'cyan',    '#996600', '#99A6CC',
        '#669933', '#929292', '#006600', '#FFE100', '#00A6FF', '#009060', '#B000E0', '#A08000',
        'orange',  'brown',   'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
      ],
      NbrLegend => 0,
      box       => 0,
	  legendfont => '{Times} 8 {normal}',
    },
    'TAGS' => {
      AllTagsChart => '_AllTagsChart',
      AllAXIS      => '_AllAXISTag',
      yAxis        => '_yAxisTag',
      xAxis        => '_xAxisTag',
      'xAxis0'     => '_0AxisTag',
      BoxAxis      => '_BoxAxisTag',
      xTick        => '_xTickTag',
      yTick        => '_yTickTag',
      AllTick      => '_AllTickTag',
      'xValue0'    => '_xValue0Tag',
      xValues      => '_xValuesTag',
      yValues      => '_yValuesTag',
      AllValues    => '_AllValuesTag',
      TitleLegend  => '_TitleLegendTag',
      BoxLegend    => '_BoxLegendTag',
      AllData      => '_AllDataTag',
      AllPie       => '_AllPieTag',
      Area         => '_AreaTag',
      Pie          => '_PieTag',
      PointLine    => '_PointLineTag',
      Line         => '_LineTag',
      Point        => '_PointTag',
      Bar          => '_BarTag',
      Mixed        => '_MixedTag',
      Legend       => '_LegendTag',
      DashLines    => '_DashLineTag',
      AllBars      => '_AllBars',
      BarValues    => '_BarValuesTag',
      Boxplot      => '_BoxplotTag',
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
    'Mixed' => { DisplayOrder => [qw/ areas bars lines dashlines points /], },
  );

  return \%configuration;
}

sub _treatparameters {
  my ($cw) = @_;

  my @integer_option = qw /
    -xlabelheight -xlabelskip     -xvaluespace  -ylabelwidth
    -boxaxis      -noaxis         -zeroaxisonly -xtickheight
    -xtickview    -yticknumber    -ytickwidth   -linewidth
    -alltickview  -xvaluevertical -titleheight  -gridview
    -ytickview    -overwrite      -cumulate     -spacingbar
    -showvalues   -startangle     -viewsection  -zeroaxis
    -longticks    -markersize     -pointline
    -smoothline   -spline         -bezier
    -interval     -xlongticks     -ylongticks   -setlegend
    -piesize      -cumulatepercent
    /;

  foreach my $option_name (@integer_option) {
    my $data = $cw->cget($option_name);
    if ( ( defined $data ) and ( !_isainteger($data) ) ) {
      $cw->_error( "Can't set $option_name to '$data', $data' isn't numeric", 1 );
      return;
    }
  }

  my $xvaluesregex = $cw->cget( -xvaluesregex );
  if ( ( defined $xvaluesregex ) and ( ref $xvaluesregex ne 'Regexp' ) ) {
    $cw->_error(
      "Can't set -xvaluesregex to '$xvaluesregex', $xvaluesregex' is not a regex expression\nEx : -xvaluesregex => qr/my regex/;",
      1
    );
    return;
  }

  my $gradient = $cw->cget( -gradient );
  if ( ( defined $gradient ) and ( ref $gradient ne 'HASH' ) ) {
    $cw->_error( "Can't set -gradient to '$gradient', " . "$gradient' is not a hash reference expression\n",
      1 );
    return;
  }

  my $colors = $cw->cget( -colordata );
  if ( ( defined $colors ) and ( ref $colors ne 'ARRAY' ) ) {
    $cw->_error(
      "Can't set -colordata to '$colors', '$colors' is not an array reference\nEx : -colordata => ['blue','#2400FF',...]",
      1
    );
    return;
  }
  my $markers = $cw->cget( -markers );
  if ( ( defined $markers ) and ( ref $markers ne 'ARRAY' ) ) {
    $cw->_error(
      "Can't set -markers to '$markers', $markers' is not an array reference\nEx : -markers => [5,8,2]", 1 );

    return;
  }
  my $type_mixed = $cw->cget( -typemixed );
  if ( ( defined $type_mixed ) and ( ref $type_mixed ne 'ARRAY' ) ) {
    $cw->_error(
      "Can't set -typemixed to '$type_mixed', $type_mixed' is not an array reference\nEx : -typemixed => ['bars','lines',...]",
      1
    );

    return;
  }

  if ( my $xtickheight = $cw->cget( -xtickheight ) ) {
    $cw->{RefChart}->{Axis}{Xaxis}{TickHeight} = $xtickheight;
  }

  # -smoothline deprecated, use -bezier
  if ( my $smoothline = $cw->cget( -smoothline ) ) {
    $cw->configure( -bezier => $smoothline );
  }

  if ( my $xvaluespace = $cw->cget( -xvaluespace ) ) {
    $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} = $xvaluespace;
  }

  if ( my $noaxis = $cw->cget( -noaxis ) and $cw->cget( -noaxis ) == 1 ) {
    $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} = 0;
    $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}  = 0;
    $cw->{RefChart}->{Axis}{Yaxis}{TickWidth}         = 0;
    $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}        = 0;
  }

  if ( my $title = $cw->cget( -title ) ) {
    if ( my $titleheight = $cw->cget( -titleheight ) ) {
      $cw->{RefChart}->{Title}{Height} = $titleheight;
    }
  }
  else {
    $cw->{RefChart}->{Title}{Height} = 0;
  }

  if ( my $xlabel = $cw->cget( -xlabel ) ) {
    if ( my $xlabelheight = $cw->cget( -xlabelheight ) ) {
      $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight} = $xlabelheight;
    }
  }
  else {
    $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight} = 0;
  }

  if ( my $ylabel = $cw->cget( -ylabel ) ) {
    if ( my $ylabel_width = $cw->cget( -ylabelWidth ) ) {
      $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth} = $ylabel_width;
    }
  }
  else {
    $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth} = 0;
  }

  if ( my $ytickwidth = $cw->cget( -ytickwidth ) ) {
    $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} = $ytickwidth;
  }

  if ( my $valuescolor = $cw->cget( -valuescolor ) ) {
    $cw->configure( -xvaluecolor => $valuescolor );
    $cw->configure( -yvaluecolor => $valuescolor );
  }

  if ( my $textcolor = $cw->cget( -textcolor ) ) {
    $cw->configure( -titlecolor  => $textcolor );
    $cw->configure( -xlabelcolor => $textcolor );
    $cw->configure( -ylabelcolor => $textcolor );
  }
  elsif ( my $labelscolor = $cw->cget( -labelscolor ) ) {
    $cw->configure( -xlabelcolor => $labelscolor );
    $cw->configure( -ylabelcolor => $labelscolor );
  }

  if ( my $textfont = $cw->cget( -textfont ) ) {
    $cw->configure( -titlefont  => $textfont );
    $cw->configure( -xlabelfont => $textfont );
    $cw->configure( -ylabelfont => $textfont );
  }
  if ( my $startangle = $cw->cget( -startangle ) ) {
    if ( $startangle < $MIN_ANGLE or $startangle > $MAX_ANGLE ) {
      $cw->configure( -startangle => 0 );
    }
  }

=for borderwidth:
  If user call -borderwidth option, the graph will be trunc.
  Then we will add HeightEmptySpace and WidthEmptySpace.

=cut

  if ( my $borderwidth = $cw->cget( -borderwidth ) ) {
    $cw->{RefChart}->{Canvas}{HeightEmptySpace} = $borderwidth + $BORDERWITH_PLUS;
    $cw->{RefChart}->{Canvas}{WidthEmptySpace}  = $borderwidth + $BORDERWITH_PLUS;
  }

  #update=
  my $yminvalue = $cw->cget( -yminvalue );
  if ( ( defined $yminvalue ) and ( !_isanumber($yminvalue) ) ) {
    $cw->_error( "-yminvalue option must be a number or real number ($yminvalue)", 1 );
    return;
  }
  my $ymaxvalue = $cw->cget( -ymaxvalue );
  if ( ( defined $ymaxvalue ) and ( !_isanumber($ymaxvalue) ) ) {
    $cw->_error( '-ymaxvalue option must be a number or real number', 1 );
    return;
  }

  if ( defined $yminvalue and defined $ymaxvalue ) {
    if ( $ymaxvalue <= $yminvalue ) {
      $cw->_error( '-ymaxvalue must be greater than -yminvalue option', 1 );
      return;
    }
  }

  return 1;
}

sub _checksizelegend_data {
  my ( $cw, $ref_data, $ref_legend ) = @_;

  # Check legend size
  if ( not defined $ref_legend ) {
    $cw->_error('legend not defined');
    return;
  }
  my $size_legend = scalar @{$ref_legend};

  # Check size between legend and data
  my $size_data = scalar @{$ref_data} - 1;
  if ( $size_legend != $size_data ) {
    $cw->_error('Legend and array size data are different');
    return;
  }

  return 1;
}

sub _zoomcalcul {
  my ( $cw, $zoomx, $zoomy ) = @_;

  if (
    !(   ( defined $zoomx and _isanumber($zoomx) and $zoomx > 0 )
      or ( defined $zoomy and _isanumber($zoomy) and $zoomy > 0 )
    )
    )
  {
    $cw->_error( 'zoom value must be defined, numeric and great than 0', 1 );
    return;
  }

  my $current_width  = $cw->{RefChart}->{Canvas}{Width};
  my $current_height = $cw->{RefChart}->{Canvas}{Height};

  my ( $new_width, $new_height );
  my $cent_percent_width  = ( $PERCENT / $cw->{RefChart}->{Zoom}{CurrentX} ) * $current_width;
  my $cent_percent_height = ( $PERCENT / $cw->{RefChart}->{Zoom}{CurrentY} ) * $current_height;
  if ( defined $zoomx ) { $new_width                        = ( $zoomx / $PERCENT ) * $cent_percent_width; }
  if ( defined $zoomy ) { $new_height                       = ( $zoomy / $PERCENT ) * $cent_percent_height; }
  if ( defined $zoomx ) { $cw->{RefChart}->{Zoom}{CurrentX} = $zoomx; }
  if ( defined $zoomy ) { $cw->{RefChart}->{Zoom}{CurrentY} = $zoomy; }

  return ( $new_width, $new_height );
}

sub _destroyballoon_bind {
  my ($cw) = @_;

  # balloon defined and user want to stop it
  if ( $cw->{RefChart}->{Balloon}{Obj}
    and Tk::Exists $cw->{RefChart}->{Balloon}{Obj} )
  {
    $cw->{RefChart}->{Balloon}{Obj}->configure( -state => 'none' );
    $cw->{RefChart}->{Balloon}{Obj}->detach($cw);
    undef $cw->{RefChart}->{Balloon}{Obj};
  }

  return;
}

sub _error {
  my ( $cw, $error_message, $croak ) = @_;

  my $verbose = $cw->cget( -verbose );
  if ( defined $croak and $croak == 1 ) {
    croak "[BE CARREFUL] : $error_message\n";
  }
  else {
    carp "[WARNING] : $error_message\n" if ( defined $verbose and $verbose == 1 );
  }

  return;
}

sub _getmarkertype {
  my ( $cw, $number ) = @_;
  my %marker_type = (

    # Num      Type                Filled
    '1'  => [ 'square',           '1' ],
    '2'  => [ 'square',           '0' ],
    '3'  => [ 'horizontal cross', '1' ],
    '4'  => [ 'diagonal cross',   '1' ],
    '5'  => [ 'diamond',          '1' ],
    '6'  => [ 'diamond',          '0' ],
    '7'  => [ 'circle',           '1' ],
    '8'  => [ 'circle',           '0' ],
    '9'  => [ 'horizontal line',  '1' ],
    '10' => [ 'vertical line',    '1' ],
  );

  if ( !$marker_type{$number} ) { return; }

  return $marker_type{$number};
}

=for _createtype
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

sub _createtype {
  my ( $cw, %ref_coord ) = @_;

  if ( $ref_coord{type} eq 'circle' or $ref_coord{type} eq 'square' ) {
    my $x1 = $ref_coord{x} - ( $ref_coord{pixel} / 2 );
    my $y1 = $ref_coord{y} + ( $ref_coord{pixel} / 2 );
    my $x2 = $ref_coord{x} + ( $ref_coord{pixel} / 2 );
    my $y2 = $ref_coord{y} - ( $ref_coord{pixel} / 2 );

    if ( $ref_coord{type} eq 'circle' ) {
      $cw->createOval( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
    }
    else {
      $cw->createRectangle( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
    }
  }
  elsif ( $ref_coord{type} eq 'horizontal cross' ) {
    my $x1 = $ref_coord{x};
    my $y1 = $ref_coord{y} - ( $ref_coord{pixel} / 2 );
    my $x2 = $x1;
    my $y2 = $ref_coord{y} + ( $ref_coord{pixel} / 2 );
    my $x3 = $ref_coord{x} - ( $ref_coord{pixel} / 2 );
    my $y3 = $ref_coord{y};
    my $x4 = $ref_coord{x} + ( $ref_coord{pixel} / 2 );
    my $y4 = $y3;
    $cw->createLine( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
    $cw->createLine( $x3, $y3, $x4, $y4, %{ $ref_coord{option} } );
  }
  elsif ( $ref_coord{type} eq 'diagonal cross' ) {
    my $x1 = $ref_coord{x} - ( $ref_coord{pixel} / 2 );
    my $y1 = $ref_coord{y} + ( $ref_coord{pixel} / 2 );
    my $x2 = $ref_coord{x} + ( $ref_coord{pixel} / 2 );
    my $y2 = $ref_coord{y} - ( $ref_coord{pixel} / 2 );
    my $x3 = $x1;
    my $y3 = $y2;
    my $x4 = $x2;
    my $y4 = $y1;
    $cw->createLine( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
    $cw->createLine( $x3, $y3, $x4, $y4, %{ $ref_coord{option} } );
  }
  elsif ( $ref_coord{type} eq 'diamond' ) {
    my $x1 = $ref_coord{x} - ( $ref_coord{pixel} / 2 );
    my $y1 = $ref_coord{y};
    my $x2 = $ref_coord{x};
    my $y2 = $ref_coord{y} + ( $ref_coord{pixel} / 2 );
    my $x3 = $ref_coord{x} + ( $ref_coord{pixel} / 2 );
    my $y3 = $ref_coord{y};
    my $x4 = $ref_coord{x};
    my $y4 = $ref_coord{y} - ( $ref_coord{pixel} / 2 );
    $cw->createPolygon( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, %{ $ref_coord{option} } );
  }
  elsif ( $ref_coord{type} eq 'vertical line' ) {
    my $x1 = $ref_coord{x};
    my $y1 = $ref_coord{y} - ( $ref_coord{pixel} / 2 );
    my $x2 = $ref_coord{x};
    my $y2 = $ref_coord{y} + ( $ref_coord{pixel} / 2 );
    $cw->createLine( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
  }
  elsif ( $ref_coord{type} eq 'horizontal line' ) {
    my $x1 = $ref_coord{x} - ( $ref_coord{pixel} / 2 );
    my $y1 = $ref_coord{y};
    my $x2 = $ref_coord{x} + ( $ref_coord{pixel} / 2 );
    my $y2 = $ref_coord{y};
    $cw->createLine( $x1, $y1, $x2, $y2, %{ $ref_coord{option} } );
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

# $cw->_display_line($ref_points, $line_number);
sub _display_line {
  my ( $cw, $ref_points, $line_number ) = @_;

  my $ref_data_to_display = $cw->{RefChart}->{Data}{RefDataToDisplay};
  if ( !( defined $ref_data_to_display and defined $ref_data_to_display->[$line_number] ) ) { return; }

  my %options;
  my $font  = $cw->{RefChart}->{Data}{RefOptionDataToDisplay}{'-font'};
  my $color = $cw->{RefChart}->{Data}{RefOptionDataToDisplay}{'-foreground'};
  if ( defined $font )  { $options{'-font'} = $font; }
  if ( defined $color ) { $options{'-fill'} = $color; }

  my $indice_point = 0;

DISPLAY:
  foreach my $value ( @{ $ref_data_to_display->[$line_number] } ) {
    if ( defined $value ) {
      my $x = $ref_points->[$indice_point];
      $indice_point++;
      my $y = $ref_points->[$indice_point] - 10;
      $cw->createText(
        $x, $y,
        -text => $value,
        %options,
      );
      $indice_point++;
      last DISPLAY if ( not defined $ref_points->[$indice_point] );
      next DISPLAY;
    }
    $indice_point += 2;
  }

  return;
}

sub _box {
  my ($cw) = @_;

  my $axiscolor = $cw->cget( -axiscolor );
  if ( $cw->cget( -boxaxis ) == 0 ) {
    return;
  }

  # close axis
  # X axis 2
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMax},
    $cw->{RefChart}->{Axis}{CxMax},
    $cw->{RefChart}->{Axis}{CyMax},
    -tags => [
      $cw->{RefChart}->{TAGS}{BoxAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Y axis 2
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMax},
    $cw->{RefChart}->{Axis}{CyMin},
    $cw->{RefChart}->{Axis}{CxMax},
    $cw->{RefChart}->{Axis}{CyMax},
    -tags => [
      $cw->{RefChart}->{TAGS}{BoxAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  return;
}

sub _display_xticks {
  my ( $cw, $x_tickx1, $x_ticky1, $x_tickx2, $x_ticky2 ) = @_;

  my $longticks       = $cw->cget( -longticks );
  my $xlongticks      = $cw->cget( -xlongticks );
  my $xlongtickscolor = $cw->cget( -xlongtickscolor );
  my $longtickscolor  = $cw->cget( -longtickscolor );
  my $axiscolor       = $cw->cget( -axiscolor );

  # Only short xticks
  $cw->createLine(
    $x_tickx1,
    $x_ticky1,
    $x_tickx2,
    $x_ticky2,
    -tags => [
      $cw->{RefChart}->{TAGS}{xTick}, $cw->{RefChart}->{TAGS}{AllTick},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Long xTicks
  if ( ( defined $longticks and $longticks == 1 ) or ( defined $xlongticks and $xlongticks == 1 ) ) {
    $x_ticky1 = $cw->{RefChart}->{Axis}{CyMax};
    $x_ticky2 = $cw->{RefChart}->{Axis}{CyMin};
    $cw->createLine(
      $x_tickx1,
      $x_ticky1,
      $x_tickx2,
      $x_ticky2,
      -tags => [
        $cw->{RefChart}->{TAGS}{xTick}, $cw->{RefChart}->{TAGS}{AllTick},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $longtickscolor || $xlongtickscolor,
      -dash => $DASH,
    );
  }

  return 1;
}

sub _display_yticks {
  my ( $cw, $y_tickx1, $y_ticky1, $y_tickx2, $y_ticky2 ) = @_;

  my $longticks       = $cw->cget( -longticks );
  my $ylongticks      = $cw->cget( -ylongticks );
  my $ylongtickscolor = $cw->cget( -ylongtickscolor );
  my $longtickscolor  = $cw->cget( -longtickscolor );
  my $axiscolor       = $cw->cget( -axiscolor );

  # Only short yticks
  $cw->createLine(
    $y_tickx1,
    $y_ticky1,
    $y_tickx2,
    $y_ticky2,
    -tags => [
      $cw->{RefChart}->{TAGS}{yTick}, $cw->{RefChart}->{TAGS}{AllTick},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Long yTicks
  if ( ( defined $longticks and $longticks == 1 ) or ( defined $ylongticks and $ylongticks == 1 ) ) {
    $y_tickx1 = $cw->{RefChart}->{Axis}{CxMin};
    $y_tickx2 = $cw->{RefChart}->{Axis}{CxMax};
    $cw->createLine(
      $y_tickx1,
      $y_ticky1,
      $y_tickx2,
      $y_ticky2,
      -tags => [
        $cw->{RefChart}->{TAGS}{yTick}, $cw->{RefChart}->{TAGS}{AllTick},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $longtickscolor || $ylongtickscolor,
      -dash => $DASH,
    );
  }

  return 1;
}

sub _ytick {
  my ($cw) = @_;

  my $yminvalue  = $cw->cget( -yminvalue );
  my $longticks  = $cw->cget( -longticks );
  my $yvaluefont = $cw->cget( -yvaluefont );
  $cw->{RefChart}->{Axis}{Yaxis}{TickNumber} = $cw->cget( -yticknumber );

  # space between y ticks
  my $space      = $cw->{RefChart}->{Axis}{Yaxis}{Height} / $cw->{RefChart}->{Axis}{Yaxis}{TickNumber};
  my $unit_value = ( $cw->{RefChart}->{Data}{MaxYValue} - $cw->{RefChart}->{Data}{MinYValue} )
    / $cw->{RefChart}->{Axis}{Yaxis}{TickNumber};

  for my $tick_number ( 1 .. $cw->{RefChart}->{Axis}{Yaxis}{TickNumber} ) {

    # Display y ticks
    my $y_tickx1 = $cw->{RefChart}->{Axis}{Cx0};
    my $y_ticky1 = $cw->{RefChart}->{Axis}{CyMin} - ( $tick_number * $space );
    my $y_tickx2 = $cw->{RefChart}->{Axis}{Cx0} - $cw->{RefChart}->{Axis}{Yaxis}{TickWidth};
    my $y_ticky2 = $cw->{RefChart}->{Axis}{CyMin} - ( $tick_number * $space );

    my $y_valuex = $cw->{RefChart}->{Axis}{Cx0}
      - ( $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth} / 2 );
    my $y_valuey = $y_ticky1;
    my $value    = $unit_value * $tick_number + $cw->{RefChart}->{Data}{MinYValue};
    next if ( $value == 0 );

    # round value if to long
    $value = _roundvalue($value);

    # Display yticks short or long
    $cw->_display_yticks( $y_tickx1, $y_ticky1, $y_tickx2, $y_ticky2 );

    $cw->createText(
      $y_valuex,
      $y_valuey,
      -text => $value,
      -fill => $cw->cget( -yvaluecolor ),
      -font => $yvaluefont,
      -tags => [
        $cw->{RefChart}->{TAGS}{yValues}, $cw->{RefChart}->{TAGS}{AllValues},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  # Display 0 value or not
  if (
    !(   $cw->{RefChart}->{Data}{MinYValue} == 0
      or ( defined $yminvalue and $yminvalue > 0 )
      or ( $cw->{RefChart}->{Data}{MinYValue} > 0 )
    )
    )
  {
    $cw->createText(
      $cw->{RefChart}->{Axis}{Cx0} - ( $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} ),
      $cw->{RefChart}->{Axis}{Cy0},
      -text => 0,
      -font => $yvaluefont,
      -tags => [
        $cw->{RefChart}->{TAGS}{xValue0}, $cw->{RefChart}->{TAGS}{AllValues},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  # Display the minimale value
  $cw->createText(
    $cw->{RefChart}->{Axis}{CxMin}
      - ( $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth} / 2 ),

    $cw->{RefChart}->{Axis}{CyMin},
    -text => _roundvalue( $cw->{RefChart}->{Data}{MinYValue} ),
    -fill => $cw->cget( -yvaluecolor ),
    -font => $yvaluefont,
    -tags => [
      $cw->{RefChart}->{TAGS}{yValues}, $cw->{RefChart}->{TAGS}{AllValues},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
  );

  # Long tick
  if ( ( not defined $longticks ) or ( $longticks != 1 ) ) {
    $cw->createLine(
      $cw->{RefChart}->{Axis}{Cx0},
      $cw->{RefChart}->{Axis}{CyMin} - $space,
      $cw->{RefChart}->{Axis}{Cx0} - $cw->{RefChart}->{Axis}{Yaxis}{TickWidth},
      $cw->{RefChart}->{Axis}{CyMin} - $space,
      -tags => [
        $cw->{RefChart}->{TAGS}{yTick}, $cw->{RefChart}->{TAGS}{AllTick},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  return;
}

sub _title {
  my ($cw) = @_;

  my $title         = $cw->cget( -title );
  my $title_color   = $cw->cget( -titlecolor );
  my $title_font    = $cw->cget( -titlefont );
  my $titleposition = $cw->cget( -titleposition );

  # Title verification
  if ( !$title ) { return; }

  # Space before the title
  my $width_empty_before_title
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace} 
    + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
    + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth};

  # Coordinates title
  $cw->{RefChart}->{Title}{Ctitrex}
    = ( $cw->{RefChart}->{Axis}{Xaxis}{Width} / 2 ) + $width_empty_before_title;
  $cw->{RefChart}->{Title}{Ctitrey}
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace} + ( $cw->{RefChart}->{Title}{Height} / 2 );

  # -width to createText
  $cw->{RefChart}->{Title}{'-width'} = $cw->{RefChart}->{Axis}{Xaxis}{Width};

  # display title
  my $anchor;
  if ( $titleposition eq 'left' ) {
    $cw->{RefChart}->{Title}{Ctitrex}  = $width_empty_before_title;
    $anchor                            = 'nw';
    $cw->{RefChart}->{Title}{'-width'} = 0;
  }
  elsif ( $titleposition eq 'right' ) {
    $cw->{RefChart}->{Title}{Ctitrex}  = $width_empty_before_title + $cw->{RefChart}->{Axis}{Xaxis}{Width};
    $cw->{RefChart}->{Title}{'-width'} = 0;
    $anchor                            = 'ne';
  }
  else {
    $anchor = 'center';
  }
  $cw->{RefChart}->{Title}{IdTitre} = $cw->createText(
    $cw->{RefChart}->{Title}{Ctitrex},
    $cw->{RefChart}->{Title}{Ctitrey},
    -text   => $title,
    -width  => $cw->{RefChart}->{Title}{'-width'},
    -anchor => $anchor,
    -tags   => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
  );
  if ( $anchor eq 'left' and $anchor eq 'right' ) { return; }

  # get title information
  my ($height);
  ( $cw->{RefChart}->{Title}{Ctitrex},
    $cw->{RefChart}->{Title}{Ctitrey},
    $cw->{RefChart}->{Title}{Width}, $height
  ) = $cw->bbox( $cw->{RefChart}->{Title}{IdTitre} );

  if ( $cw->{RefChart}->{Title}{Ctitrey} < $cw->{RefChart}->{Canvas}{HeightEmptySpace} ) {

    # cut title
    $cw->delete( $cw->{RefChart}->{Title}{IdTitre} );

    $cw->{RefChart}->{Title}{Ctitrex} = $width_empty_before_title;
    $cw->{RefChart}->{Title}{Ctitrey}
      = $cw->{RefChart}->{Canvas}{HeightEmptySpace} + ( $cw->{RefChart}->{Title}{Height} / 2 );

    $cw->{RefChart}->{Title}{'-width'} = 0;

    # display title
    $cw->{RefChart}->{Title}{IdTitre} = $cw->createText(
      $cw->{RefChart}->{Title}{Ctitrex},
      $cw->{RefChart}->{Title}{Ctitrey},
      -text   => $title,
      -width  => $cw->{RefChart}->{Title}{'-width'},
      -anchor => 'nw',
      -tags   => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  $cw->itemconfigure(
    $cw->{RefChart}->{Title}{IdTitre},
    -font => $title_font,
    -fill => $title_color,
  );
  return;
}

sub _xlabelposition {
  my ($cw) = @_;

  my $xlabel = $cw->cget( -xlabel );

  # no x_label
  if ( not defined $xlabel ) { return; }

  # coordinate (CxlabelX, CxlabelY)
  my $before_xlabel_x
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace} 
    + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
    + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth};
  my $before_xlabel_y
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $cw->{RefChart}->{Title}{Height}
    + $cw->{RefChart}->{Axis}{Yaxis}{Height}
    + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
    + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight};

  $cw->{RefChart}->{Axis}{Xaxis}{CxlabelX} = $before_xlabel_x + ( $cw->{RefChart}->{Axis}{Xaxis}{Width} / 2 );
  $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY}
    = $before_xlabel_y + ( $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight} / 2 );

  # display xlabel
  $cw->{RefChart}->{Axis}{Xaxis}{Idxlabel} = $cw->createText(
    $cw->{RefChart}->{Axis}{Xaxis}{CxlabelX},
    $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY},
    -text  => $xlabel,
    -width => $cw->{RefChart}->{Axis}{Xaxis}{Width},
    -tags  => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
  );

  # get info ylabel xlabel
  my ( $width, $height );
  ( $cw->{RefChart}->{Axis}{Xaxis}{CxlabelX}, $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY}, $width, $height )
    = $cw->bbox( $cw->{RefChart}->{Axis}{Xaxis}{Idxlabel} );

  if ( $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY} < $before_xlabel_y ) {

    $cw->delete( $cw->{RefChart}->{Axis}{Xaxis}{Idxlabel} );

    $cw->{RefChart}->{Axis}{Xaxis}{CxlabelX} = $before_xlabel_x;
    $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY}
      = $before_xlabel_y + ( $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight} / 2 );

    # display xlabel
    $cw->{RefChart}->{Axis}{Xaxis}{Idxlabel} = $cw->createText(
      $cw->{RefChart}->{Axis}{Xaxis}{CxlabelX},
      $cw->{RefChart}->{Axis}{Xaxis}{CxlabelY},
      -text   => $xlabel,
      -width  => 0,
      -anchor => 'nw',
      -tags   => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  $cw->itemconfigure(
    $cw->{RefChart}->{Axis}{Xaxis}{Idxlabel},
    -font => $cw->cget( -xlabelfont ),
    -fill => $cw->cget( -xlabelcolor ),
  );

  return;
}

sub _ylabelposition {
  my ($cw) = @_;

  my $ylabel = $cw->cget( -ylabel );

  # no y_label
  if ( not defined $ylabel ) {
    return;
  }

  # coordinate (CylabelX, CylabelY)
  $cw->{RefChart}->{Axis}{Yaxis}{CylabelX}
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace} + ( $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth} / 2 );
  $cw->{RefChart}->{Axis}{Yaxis}{CylabelY}
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $cw->{RefChart}->{Title}{Height}
    + ( $cw->{RefChart}->{Axis}{Yaxis}{Height} / 2 );

  # display ylabel
  $cw->{RefChart}->{Axis}{Yaxis}{Idylabel} = $cw->createText(
    $cw->{RefChart}->{Axis}{Yaxis}{CylabelX},
    $cw->{RefChart}->{Axis}{Yaxis}{CylabelY},
    -text  => $ylabel,
    -font  => $cw->cget( -ylabelfont ),
    -width => $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth},
    -fill  => $cw->cget( -ylabelcolor ),
    -tags  => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
  );

  # get info ylabel
  my ( $width, $height );
  ( $cw->{RefChart}->{Axis}{Yaxis}{CylabelX}, $cw->{RefChart}->{Axis}{Yaxis}{CylabelY}, $width, $height )
    = $cw->bbox( $cw->{RefChart}->{Axis}{Yaxis}{Idylabel} );

  return;
}

sub _manage_minmaxvalues {
  my ($cw) = @_;

  # Bars : Cumulate percent => min = 0 and max = 100
  my $cumulatepercent = $cw->cget( -cumulatepercent );
  if ( defined $cumulatepercent and $cumulatepercent == 1 ) {
    $cw->{RefChart}->{Data}{MinYValue} = 0;
    $cw->{RefChart}->{Data}{MaxYValue} = 100;
    return 1;
  }

  my $cumulate    = $cw->cget( -cumulate );
  my $yticknumber = $cw->cget( -yticknumber );
  my $yminvalue   = $cw->cget( -yminvalue );
  my $ymaxvalue   = $cw->cget( -ymaxvalue );
  my $interval    = $cw->cget( -interval );

  if ( defined $yminvalue and defined $ymaxvalue ) {
    if (
      !((     $ymaxvalue >= $cw->{RefChart}->{Data}{MaxYValue}
          and $yminvalue <= $cw->{RefChart}->{Data}{MinYValue}
        )
        or ( defined $interval and $interval == 1 )
      )
      )
    {
      $cw->_error('-yminvalue and -ymaxvalue do not include all data');
    }
  }

  if ( defined $cumulate and $cumulate == 1 and $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
    $cw->{RefChart}->{Data}{MinYValue} = 0;
  }

  if ( !( defined $interval and $interval == 1 ) ) {
    if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
      $cw->{RefChart}->{Data}{MinYValue} = 0;
    }
    while ( ( $cw->{RefChart}->{Data}{MaxYValue} / $yticknumber ) % 5 != 0 ) {
      $cw->{RefChart}->{Data}{MaxYValue} = int( $cw->{RefChart}->{Data}{MaxYValue} + 1 );
    }

    if ( defined $yminvalue and $yminvalue != 0 ) {
      $cw->{RefChart}->{Data}{MinYValue} = $yminvalue;
    }
    if ( defined $ymaxvalue and $ymaxvalue != 0 ) {
      $cw->{RefChart}->{Data}{MaxYValue} = $ymaxvalue;
    }
  }

  return 1;
}

sub _chartconstruction {
  my ($cw) = @_;

  if ( not defined $cw->{RefChart}->{Data}{PlotDefined} ) {
    return;
  }

  $cw->clearchart();
  $cw->_treatparameters();

  # For background gradient color
  $cw->set_gradientcolor;

  # Height and Width canvas
  $cw->{RefChart}->{Canvas}{Width}  = $cw->width;
  $cw->{RefChart}->{Canvas}{Height} = $cw->height;

  # Pie graph
  if ( $cw->class eq 'Pie' ) {

    # Width Pie
    $cw->{RefChart}->{Pie}{Width}
      = $cw->{RefChart}->{Canvas}{Width} - ( 2 * $cw->{RefChart}->{Canvas}{WidthEmptySpace} );

    if ( $cw->{RefChart}->{Data}{RefAllData} ) {
      $cw->_titlepie;
      $cw->_viewdata;
      $cw->_viewlegend();
    }
    return;
  }

  $cw->_axis();
  $cw->_box();
  $cw->_ylabelposition();
  $cw->_xlabelposition();
  $cw->_title();

  if ( $cw->class eq 'Lines' ) {
    if ( $cw->cget( -pointline ) == 1 ) {
      $cw->_viewdatapoints();
    }
    else {
      $cw->_viewdatalines();
    }
  }
  else {
    $cw->_viewdata();
  }

  #
  if ( $cw->cget( -noaxis ) != 1 ) {
    $cw->_xtick();
    $cw->_ytick();
  }

  if ( $cw->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    $cw->_viewlegend();
    $cw->_balloon();
  }

  # If Y value < 0, don't display O x-axis
  if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{xAxis0} );
    $cw->delete( $cw->{RefChart}->{TAGS}{xValue0} );
  }

  # Axis
  if ( $cw->cget( -noaxis ) == 1 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{AllAXIS} );
    $cw->delete( $cw->{RefChart}->{TAGS}{AllTick} );
    $cw->delete( $cw->{RefChart}->{TAGS}{AllValues} );
  }
  if (  $cw->cget( -zeroaxisonly ) == 1
    and $cw->{RefChart}->{Data}{MaxYValue} > 0
    and $cw->{RefChart}->{Data}{MinYValue} < 0 )
  {
    $cw->delete( $cw->{RefChart}->{TAGS}{xAxis} );
  }
  if ( $cw->cget( -zeroaxis ) == 1 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{xAxis0} );
    $cw->delete( $cw->{RefChart}->{TAGS}{xTick} );
    $cw->delete( $cw->{RefChart}->{TAGS}{xValues} );
  }
  if ( $cw->cget( -xvalueview ) == 0 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{xValues} );
  }
  if ( $cw->cget( -yvalueview ) == 0 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{yValues} );
  }

  # ticks
  my $alltickview = $cw->cget( -alltickview );
  if ( defined $alltickview ) {
    if ( $alltickview == 0 ) {
      $cw->delete( $cw->{RefChart}->{TAGS}{AllTick} );
    }
    else {
      $cw->configure( -ytickview => 1 );
      $cw->configure( -xtickview => 1 );
    }
  }
  else {
    if ( $cw->cget( -xtickview ) == 0 ) {
      $cw->delete( $cw->{RefChart}->{TAGS}{xTick} );
    }
    if ( $cw->cget( -ytickview ) == 0 ) {
      $cw->delete( $cw->{RefChart}->{TAGS}{yTick} );
    }
  }

  # Legend
  if ( $cw->{RefChart}->{Legend}{box} == 0 ) {
    $cw->delete( $cw->{RefChart}->{TAGS}{BoxLegend} );
  }

  if ( $cw->class eq 'Mixed' ) {

    # Order displaying data
    $cw->display_order;
  }

  # Ticks always in background
  $cw->raise( $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTick} );

  # values displayed above the bars must be display over the bars
  my $showvalues = $cw->cget( -showvalues );
  if ( defined $showvalues and $showvalues == 1 ) {
    $cw->raise( $cw->{RefChart}->{TAGS}{BarValues}, $cw->{RefChart}->{TAGS}{AllBars} );
  }
  return 1;
}

1;

__END__

=head1 NAME

Tk::Chart - Extension of Canvas widget to create a graph like GDGraph. 

=head1 SYNOPSIS

use Tk::Chart::B<ModuleName>;

=head1 DESCRIPTION

B<Tk::Chart> is a module to create and display graphs on a Tk widget. 
The module is written entirely in Perl/Tk.

You can set a background gradient color by using L<Tk::Canvas::GradientColor> methods.

You can change the color, font of title, labels (x and y) of graphs.
You can set an interactive legend. The axes can be automatically scaled or set by the code.

When the mouse cursor passes over a plotted lines, bars, pies or its entry in the legend, 
they will be turned to a color to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

L<Tk::Chart::Areas>, 
Extension of Canvas widget to create an area lines graph. 

L<Tk::Chart::Bars>,  
Extension of Canvas widget to create bars graph with vertical bars.

L<Tk::Chart::Boxplots>,  
Extension of Canvas widget to create boxplots graph. 

L<Tk::Chart::FAQ>,  
Frequently Asked Questions about L<Tk::Chart>.

L<Tk::Chart::Lines>, 
Extension of Canvas widget to create lines graph. 
With this module it is possible to plot quantitative variables according to qualitative variables.

L<Tk::Chart::Mixed>,  
Extension of Canvas widget to create a graph mixed with lines, lines points, splines, bars, points and areas. 

L<Tk::Chart::Pie>,  
Extension of Canvas widget to create a pie graph. 

L<Tk::Chart::Points>, 
Extension of Canvas widget to create point lines graph. 

L<Tk::Chart::Splines>, 
To create lines graph as B<B>E<eacute>B<zier curve>. 

=head1 EXAMPLES

In the B<demo> directory, you have a lot of script examples with their screenshot. 
See also the L<http://search.cpan.org/dist/Tk-Chart/MANIFEST> web page of L<Tk::Chart>.

=head1 SEE ALSO

See L<Tk::Chart::FAQ>, L<Tk::Canvas::GradientColor>, L<GD::Graph>, L<Tk::Graph>, L<Tk::LineGraph>, L<Tk::PlotDataset>, L<Chart::Plot::Canvas>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart
    perldoc Tk::Chart::Areas
    perldoc Tk::Chart::Bars
    perldoc Tk::Chart::Boxplots
    perldoc Tk::Chart::FAQ
    perldoc Tk::Chart::Lines
    perldoc Tk::Chart::Mixed
    perldoc Tk::Chart::Pie
    perldoc Tk::Chart::Points
    perldoc Tk::Chart::Splines

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

Copyright 2017 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
