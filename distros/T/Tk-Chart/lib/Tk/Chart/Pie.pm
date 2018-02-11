package Tk::Chart::Pie;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2018                                               $
# $Update    : 09/02/2018                                         $
# $AIM       : Create pie graph                                   $
#==================================================================

use vars qw($VERSION);
$VERSION = '1.06';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Pie';

sub Populate {

  my ( $cw, $ref_parameters ) = @_;

  # Get initial parameters
  $cw->{RefChart} = $cw->_initconfig();

  $cw->SUPER::Populate($ref_parameters);

  $cw->Advertise( 'GradientColor' => $cw );
  $cw->Advertise( 'canvas'        => $cw->SUPER::Canvas );
  $cw->Advertise( 'Canvas'        => $cw->SUPER::Canvas );

  # remove highlightthickness if necessary
  if ( !exists $ref_parameters->{-highlightthickness} ) {
    $cw->configure( -highlightthickness => 0 );
  }

  # ConfigSpecs
  $cw->ConfigSpecs(
    -title         => [ 'PASSIVE', 'Title',         'Title',         undef ],
    -titlecolor    => [ 'PASSIVE', 'Titlecolor',    'TitleColor',    'black' ],
    -titlefont     => [ 'PASSIVE', 'Titlefont',     'TitleFont',     $cw->{RefChart}->{Font}{DefaultTitle} ],
    -titleposition => [ 'PASSIVE', 'Titleposition', 'TitlePosition', 'center' ],
    -width         => [ 'SELF',    'width',         'Width',         $cw->{RefChart}->{Canvas}{Width} ],
    -height        => [ 'SELF',    'height',        'Height',        $cw->{RefChart}->{Canvas}{Height} ],

    -linewidth  => [ 'PASSIVE', 'Linewidth',  'LineWidth',  2 ],
    -startangle => [ 'PASSIVE', 'Startangle', 'StartAngle', 0 ],
    -colordata  => [ 'PASSIVE', 'Colordata',  'ColorData',  $cw->{RefChart}->{Legend}{Colors} ],

    -legendcolor => [ 'PASSIVE', 'Legendcolor', 'LegendColor', 'black' ],
    -setlegend   => [ 'PASSIVE', 'Setlegend',   'SetLegend',   1 ],
    -piesize     => [ 'PASSIVE', 'Piesize',   'PieSize',   360 ],

	-legendfont => [ 'PASSIVE', 'Legendfont',  'LegendFont',  $cw->{RefChart}->{Legend}{legendfont} ],
	
    # verbeose mode
    -verbose => [ 'PASSIVE', 'verbose', 'Verbose', 1 ],
  );

  $cw->Delegates( DEFAULT => $cw, );

  # recreate graph after widget resize
  $cw->enabled_automatic_redraw();
  $cw->disabled_gradientcolor();
}

sub plot {
  my ( $cw, $ref_data ) = @_;

  if ( not defined $ref_data ) {
    $cw->_error('data not defined');
    return;
  }

  if ( scalar @{$ref_data} != 2 ) {
    $cw->_error('You must have 2 arrays in data array');
    return;
  }

  # Check array size
  $cw->{RefChart}->{Data}{NumberXValues} = scalar @{ $ref_data->[0] };
  foreach my $ref_array ( @{$ref_data} ) {
    if ( scalar @{$ref_array} != $cw->{RefChart}->{Data}{NumberXValues} ) {
      $cw->_error( 'Make sure that every array has the same size in plot data method', 1 );
      return;
    }
  }

  # Check array size
  foreach my $data ( @{ $ref_data->[1] } ) {
    if ( defined $data and !_isanumber($data) ) {
      $data = $cw->{RefChart}->{Data}{SubstitutionValue};
    }
  }

  $cw->{RefChart}->{Data}{MaxValue}    = _maxarray( $ref_data->[1] );
  $cw->{RefChart}->{Data}{NbrSlice}    = scalar @{ $ref_data->[0] };
  $cw->{RefChart}->{Data}{RefAllData}  = $ref_data;
  $cw->{RefChart}->{Data}{PlotDefined} = 1;

  $cw->_chartconstruction;

  return;
}

sub _titlepie {
  my ($cw) = @_;

  my $title         = $cw->cget( -title );
  my $titlecolor    = $cw->cget( -titlecolor );
  my $titlefont     = $cw->cget( -titlefont );
  my $titleposition = $cw->cget( -titleposition );

  # Title verification
  if ( !$title ) {
    $cw->{RefChart}->{Title}{Height} = 0;
    return;
  }

  # Space before the title
  my $width_empty_before_title = $cw->{RefChart}->{Canvas}{WidthEmptySpace};

  # Coordinates title
  $cw->{RefChart}->{Title}{Ctitrex}
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace} + ( $cw->{RefChart}->{Pie}{Width} / 2 );
  $cw->{RefChart}->{Title}{Ctitrey}
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace} + ( $cw->{RefChart}->{Title}{Height} / 2 );

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
    -width  => $cw->{RefChart}->{Pie}{Width},
    -anchor => $anchor,
    -tags   => [ $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
  );
  return if ( $anchor =~ m{^left|right$} );

  # get title information
  my ($height);
  ( $cw->{RefChart}->{Title}{Ctitrex},
    $cw->{RefChart}->{Title}{Ctitrey},
    $cw->{RefChart}->{Title}{Width}, $height
  ) = $cw->bbox( $cw->{RefChart}->{Title}{IdTitre} );

  # Title too long
  if ( $cw->{RefChart}->{Title}{Ctitrey} < $cw->{RefChart}->{Canvas}{HeightEmptySpace} ) {

    # delete title
    $cw->delete( $cw->{RefChart}->{Title}{IdTitre} );

    $cw->{RefChart}->{Title}{Ctitrex} = $width_empty_before_title;
    $cw->{RefChart}->{Title}{Ctitrey}
      = $cw->{RefChart}->{Canvas}{HeightEmptySpace} + ( $cw->{RefChart}->{Title}{Height} / 2 );

    # cut title
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
    -font => $titlefont,
    -fill => $titlecolor,
  );

  return;
}

sub _viewdata {
  my ($cw) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $piesize            = $cw->cget( -piesize );
  
  if ( ($piesize <= 0) or ($piesize > 360) ) {
    $cw->_error("The value of -piesize option must be between 1 and 360 degrees", 1);
    return;
  }
  
  # Height legend
  $cw->_legend();

  # Coordinates for rectangle pie
  $cw->{RefChart}->{Pie}{x1} = $cw->{RefChart}->{Canvas}{WidthEmptySpace};
  $cw->{RefChart}->{Pie}{y1}
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $cw->{RefChart}->{Title}{Height}
    + $cw->{RefChart}->{Canvas}{HeightEmptySpace};

  $cw->{RefChart}->{Pie}{x2} = $cw->{RefChart}->{Pie}{x1} + $cw->{RefChart}->{Pie}{Width};

  $cw->{RefChart}->{Pie}{y2}
    = $cw->{RefChart}->{Canvas}{Height}
    - ( 2 * $cw->{RefChart}->{Canvas}{WidthEmptySpace} )
    - $cw->{RefChart}->{Legend}{Height};

  # Calculate the number of degrees for value = 1
  my $somme = 0;
  foreach my $data ( @{ $cw->{RefChart}->{Data}{RefAllData}->[1] } ) {
    $somme += $data;
  }
  $cw->{RefChart}->{Pie}{DegreeOneValue} = $piesize / $somme;

  # pie
  my ( $degrees, $start ) = ( 0, $cw->cget( -startangle ) );
  my $indice_color = 0;
  my $index_legend = 0;
  for my $indice ( 0 .. $cw->{RefChart}->{Data}{NbrSlice} - 1 ) {
    my $value = $cw->{RefChart}->{Data}{RefAllData}->[1]->[$indice];
    $degrees = $cw->{RefChart}->{Pie}{DegreeOneValue} * $value;

    my $color = $legendmarkercolors->[$indice_color];
    if ( not defined $color ) {
      $indice_color = 0;
      $color        = $legendmarkercolors->[$indice_color];
    }
    my $tag = $index_legend . $cw->{RefChart}->{TAGS}{Legend} . $cw->{RefChart}->{TAGS}{Pie};
    $cw->createArc(
      $cw->{RefChart}->{Pie}{x1},
      $cw->{RefChart}->{Pie}{y1},
      $cw->{RefChart}->{Pie}{x2},
      $cw->{RefChart}->{Pie}{y2},
      -extent => $degrees,
      -fill   => $color,
      -start  => $start,
      -tags   => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      -width  => $cw->cget( -linewidth ),
      -style => 'pieslice',
    );
    $cw->{RefChart}{Pie}{$tag}{color} = $color;
    $cw->{RefChart}{Pie}{$tag}{percent} = "$value (" . _roundvalue( ( $value * 100 ) / $somme ) . '%)';

    $start += $degrees;
    $indice_color++;
    $index_legend++;
  }

  return 1;
}

sub _checkheightpie {
  my ($cw) = @_;

  my $total
    = ( $cw->{RefChart}->{Canvas}{HeightEmptySpace} 
      + $cw->{RefChart}->{Title}{Height}
      + ( 2 * $cw->{RefChart}->{Canvas}{HeightEmptySpace} )
      + $cw->{RefChart}->{Legend}{Height}
      + $cw->{RefChart}->{Title}{Height} );
  while ( $total > $cw->{RefChart}->{Canvas}{Height} ) {
    $cw->{RefChart}->{Canvas}{Height} += $cw->{RefChart}->{Legend}{Height};

    $cw->configure( -height => $cw->{RefChart}->{Canvas}{Height} );
  }

  return;
}

sub _legend {
  my ($cw) = @_;

  my $setlegend = $cw->cget( -setlegend );
  if ( !( defined $setlegend and $setlegend == 1 ) ) {
    return;
  }

SETLEGEND:

  # One legend width
  $cw->{RefChart}->{Legend}{LengthOneLegend}
    = +$cw->{RefChart}->{Legend}{SpaceBeforeCube}    # Espace entre chaque légende
    + $cw->{RefChart}->{Legend}{WCube}               # Cube (largeur)
    + $cw->{RefChart}->{Legend}{SpaceAfterCube}      # Espace apres cube
    + $cw->{RefChart}->{Legend}{WidthText}           # longueur du texte de la légende
    ;

  # Number of legends per line
  $cw->{RefChart}->{Legend}{NbrPerLine}
    = int( $cw->{RefChart}->{Pie}{Width} / $cw->{RefChart}->{Legend}{LengthOneLegend} );

  if ( $cw->{RefChart}->{Legend}{NbrPerLine} == 0 ) {
    $cw->{RefChart}->{Legend}{NbrPerLine} = 1;
  }

  # Number of legends (total)
  $cw->{RefChart}->{Legend}{NbrLegend} = scalar @{ $cw->{RefChart}->{Data}{RefAllData}->[0] };

=for NumberLines:
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
  $cw->{RefChart}->{Legend}{Height} = $cw->{RefChart}->{Legend}{NbrLine} * $cw->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  $cw->{RefChart}->{Legend}{CurrentNbrPerLine} = $cw->{RefChart}->{Legend}{NbrPerLine};
  if ( $cw->{RefChart}->{Legend}{NbrLegend} < $cw->{RefChart}->{Legend}{NbrPerLine} ) {
    $cw->{RefChart}->{Legend}{CurrentNbrPerLine} = $cw->{RefChart}->{Legend}{NbrLegend};

  }

  # Get the biggest length of legend text
  my @length_legend = map { length; } @{ $cw->{RefChart}->{Data}{RefAllData}->[0] };
  my $biggest_legend = _maxarray( \@length_legend );

  # 100 pixel =>  13 characters, 1 pixel =>  0.13 pixels then 1 character = 7.69 pixels
  $cw->{RefChart}->{Legend}{WidthOneCaracter} = 7.69;

  # Max pixel width for a legend text for us
  $cw->{RefChart}->{Legend}{LengthTextMax}
    = int( $cw->{RefChart}->{Legend}{WidthText} / $cw->{RefChart}->{Legend}{WidthOneCaracter} );

  # We have free space
  my $diff = $cw->{RefChart}->{Legend}{LengthTextMax} - $biggest_legend;

  # Get new size width for a legend text with one pixel security
  if ( $diff > 1 ) {
    $cw->{RefChart}->{Legend}{WidthText} -= ( $diff - 1 ) * $cw->{RefChart}->{Legend}{WidthOneCaracter};
    goto SETLEGEND;
  }

  $cw->_checkheightpie();

  return;
}

sub _viewlegend {
  my ($cw) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $legendcolor        = $cw->cget( -legendcolor );
  my $legendfont         = $cw->cget( -legendfont );
  my $setlegend          = $cw->cget( -setlegend );
  if ( !( defined $setlegend and $setlegend == 1 ) ) {
    return;
  }

  my $index_color  = 0;
  my $index_legend = 0;

  # Balloon
  my %msgballoon;

  for my $number_line ( 0 .. $cw->{RefChart}->{Legend}{NbrLine} ) {
    my $x1_cube = $cw->{RefChart}->{Canvas}{WidthEmptySpace} + $cw->{RefChart}->{Legend}{SpaceBeforeCube};

    my $y1_cube
      = $cw->{RefChart}->{Pie}{y2} 
      + $cw->{RefChart}->{Canvas}{HeightEmptySpace}
      + ( $number_line * $cw->{RefChart}->{Legend}{HLine} );

    my $x2_cube    = $x1_cube + $cw->{RefChart}->{Legend}{WCube};
    my $y2_cube    = $y1_cube - $cw->{RefChart}->{Legend}{HCube};
    my $xtext      = $x2_cube + $cw->{RefChart}->{Legend}{SpaceAfterCube};
    my $ytext      = $y2_cube;
    my $max_length = $cw->{RefChart}->{Legend}{LengthTextMax};

  LEGEND:
    for my $number_leg_in_line ( 0 .. $cw->{RefChart}->{Legend}{NbrPerLine} - 1 ) {
      last LEGEND
        if ( not defined $cw->{RefChart}->{Data}{RefAllData}->[0]->[$index_legend] );
      my $line_color = $legendmarkercolors->[$index_color];
      if ( not defined $line_color ) {
        $index_color = 0;
        $line_color  = $legendmarkercolors->[$index_color];
      }
      my $tag = $index_legend . $cw->{RefChart}->{TAGS}{Legend};

      $cw->createRectangle(
        $x1_cube, $y1_cube, $x2_cube, $y2_cube,
        -fill    => $line_color,
        -outline => $line_color,
        -tags    => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      );

      # Cut legend text if too long
      my $legend     = $cw->{RefChart}->{Data}{RefAllData}->[0]->[$index_legend];
      my $new_legend = $legend;
      if ( length $new_legend > $max_length ) {
        $max_length -= 3;
        $new_legend =~ s/^(.{$max_length}).*/$1/;
        $new_legend .= '...';
      }

      my $id = $cw->createText(
        $xtext, $ytext,
        -text   => $new_legend,
        -anchor => 'nw',
        -tags   => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -fill   => $legendcolor,

      );
      if ( defined $legendfont ) {
        $cw->itemconfigure( $id, -font => $legendfont );
      }

      $index_color++;
      $index_legend++;

      # cube
      $x1_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};
      $x2_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xtext += $cw->{RefChart}->{Legend}{LengthOneLegend};

      my $pie_tag = $tag . $cw->{RefChart}->{TAGS}{Pie};
      $cw->bind(
        $tag,
        '<Enter>',
        sub {
          my $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[0];
          if ( $other_color eq $cw->{RefChart}{Pie}{$pie_tag}{color} ) {
            $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[1];
          }
          $cw->itemconfigure( $pie_tag, -fill => $other_color, );
        }
      );

      $cw->bind(
        $tag,
        '<Leave>',
        sub {
          $cw->itemconfigure( $pie_tag, -fill => $cw->{RefChart}{Pie}{$pie_tag}{color}, );
        }
      );

      $msgballoon{$tag}     = "$legend - " . $cw->{RefChart}{Pie}{$pie_tag}{percent};
      $msgballoon{$pie_tag} = "$legend - " . $cw->{RefChart}{Pie}{$pie_tag}{percent};
    }
  }

  # Balloon
  # Destroy the existing ballon to use new data.
  if ( defined $cw->{RefChart}->{Balloon}{Obj} ) {
    $cw->{RefChart}->{Balloon}{Obj}->destroy;
    $cw->{RefChart}->{Balloon}{Obj} = undef;
  }
  
  # Create the balloon
  $cw->{RefChart}->{Balloon}{Obj} = $cw->Balloon(
      -statusbar  => $cw,
      -background => $cw->{RefChart}->{Balloon}{Background},
    );

    $cw->{RefChart}->{Balloon}{Obj}->attach(
      $cw,
      -balloonposition => 'mouse',
      -msg             => \%msgballoon,
    );

  return;
}

1; # End of Tk::Chart::Pie

__END__

=head1 NAME

Tk::Chart::Pie - Extension of Canvas widget to create a pie graph. 

=head1 DESCRIPTION

Tk::Chart::Pie is an extension of the Canvas widget. It is an easy way to build an 
interactive pie graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

When the mouse cursor passes over a pie slice or its entry in the legend, 
the pie slice turn to a color (that you can change) and a balloon box display to help identify it. 

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

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  
  use Tk;
  use Tk::Chart::Pie;
  my $mw = MainWindow->new( -title => 'Tk::Chart::Pie example', );
  
  my $chart = $mw->Pie(
    -title => 'Registered public CPAN countries sites' . "\n"
      . 'around the World (266 sites, 61 countries in 19 July 2011)',
    -background => 'white',
    -linewidth  => 2,
  )->pack(qw / -fill both -expand 1 /);
  
  my @data = (
    [ 'Africa', 'Asia', 'Central America', 'Europe', 'North America', 'Oceania', 'South America' ],
    [ 2,        16,     1,                 32,       3,               3,         4 ],
  );
  
  $chart->plot( \@data );
  
  MainLoop();


=head1 STANDARD OPTIONS

B<-background>          B<-borderwidth>	      B<-closeenough>	         B<-confine>
B<-cursor>	            B<-height>	          B<-highlightbackground>	 B<-highlightcolor>
B<-highlightthickness>	B<-insertbackground>  B<-insertborderwidth>    B<-insertofftime>	
B<-insertontime>        B<-insertwidth>       B<-relief>               B<-scrollregion> 
B<-selectbackground>    B<-selectborderwidth> B<-selectforeground>     B<-takefocus> 
B<-width>               B<-xscrollcommand>    B<-xscrollincrement>     B<-yscrollcommand> 
B<-yscrollincrement>

=head1 WIDGET-SPECIFIC OPTIONS 

Many options allow you to configure your graph as you want. 
The default configuration is already OK, but you can change it.

=over 4

=item Name:	B<Title>

=item Class:	B<Title>

=item Switch:	B<-title>

Title of your graph.
  
  -title => 'My pie graph title',

Default : B<undef>

=item Name:	B<Titleposition>

=item Class:	B<TitlePosition>

=item Switch:	B<-titleposition>

Position of title : B<center>, B<left> or B<right>
  
  -titleposition => 'left',

Default : B<center>

=item Name:	B<Titlecolor>

=item Class:	B<TitleColor>

=item Switch:	B<-titlecolor>

Title color of your graph.
  
  -titlecolor => 'red',

Default : B<black>

=item Name:	B<Titlefont>

=item Class:	B<TitleFont>

=item Switch:	B<-titlefont>

Set the font for the title text. See also textfont option. 
  
  -titlefont => 'Times 15 {normal}',

Default : B<{Times} 12 {bold}>

=item Name:	B<Titleheight>

=item Class:	B<TitleHeight>

=item Switch:	B<-titleheight>

Height for title graph space.
  
  -titleheight => 100,

Default : B<40>

=item Name:	B<Linewidth>

=item Class:	B<LineWidth>

=item Switch:	B<-linewidth>

Set width of all lines slice pie inthe graph.
 
  -linewidth => 10,

Default : B<1>

=item Name:	B<Colordata>

=item Class:	B<ColorData>

=item Switch:	B<-colordata>

This controls the colors of the lines. This should be a reference to an array of color names.
 
  -colordata => [ qw(green pink blue cyan) ],

Default : 

  [ 'red',     'green',   'blue',    'yellow',  'purple',  'cyan',
    '#996600', '#99A6CC', '#669933', '#929292', '#006600', '#FFE100',
    '#00A6FF', '#009060', '#B000E0', '#A08000', 'orange',  'brown',
    'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
  ],

The default array contain 24 colors. If you have more than 24 samples, the next line 
will have the color of the first array case (red).

=item Name:	B<Piesize>

=item Class:	B<PieSize>

=item Switch:	B<-piesize>

The piesize represents the size of the pie graph. It must be between 1 and 360 degrees. 
You can change this value to draw a pie graph in a full circle, a semicircle, quadrant...

  -piesize => 180, # Pie graph will be display in a half circle

Default : B<360>

=item Name:	B<Startangle>

=item Class:	B<StartAngle>

=item Switch:	B<-startangle>

The angle at which the first data slice will be displayed, with 0 degrees being "3 o'clock".

  -startangle => 90,

Default : B<0>

=item Name:	B<verbose>

=item Class:	B<Verbose>

=item Switch:	B<-verbose>

Warning will be print if necessary.
 
  -verbose => 0,

Default : B<1>

=item Name:	B<Legendcolor>

=item Class:	B<LegendColor>

=item Switch:	B<-legendcolor>

Color of legend text.
 
  -legendcolor => 'white',

Default : B<'black'>

=item Name:	B<Legendfont>

=item Class:	B<Legendfont>

=item Switch:	B<-legendfont>

Font of text legend.
 
  -legendfont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {normal}>

=item Name:	B<Setlegend>

=item Class:	B<SetLegend>

=item Switch:	B<-setlegend>

If set to true value, the legend will be display.
 
  -setlegend => 0,

Default : B<1>

=back

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

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

=head2 clearchart

=over 4

=item I<$pie_chart>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 plot

=over 4

=item I<$pie_chart>->B<plot>(I<\@data, ?arg>)

Use this method to create your pie graph.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the legend values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::Chart::Pie 
will complain and refuse to compile the graph.

  my @data = (
     [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
     [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
  );

@data have to contain two arrays, the legend values and the values of the datasets.

If you don't have a value for a point in a dataset, you can use undef, 
and the point will be skipped.

  [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


=item *

-substitutionvalue => I<real number>,

If you have a no real number value in a dataset, it will be replaced by a constant value.

Default : B<0>


  my @data = (
      [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
      [ 1,     '--',     5,     6,     3,     1.5,   1,     3,     4 ],
  );
  $pie_chart->plot( \@data,
    -substitutionvalue => '12',
  );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (ex : 12, .25, 02.25, 5.2e+11, etc ...) 
  

=back

=head2 redraw

Redraw the graph. 

If you have used clearchart for any reason, it is possible to redraw the graph.
Tk::Chart::Pie supports the configure and cget methods described in the L<Tk::options> manpage.
If you use configure method to change a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, call B<redraw> method to 
resolv the bug.

  ...
  $mw->Button(
  -text    => 'Change title', 
  -command => sub { 
      $pie_chart->configure(-title  => 'other title'); 
    }, 
  )->pack;
  ...
  # title will be changed but not displayed if you not resize the widget.
    
  ...
  $mw->Button(
    -text => 'Change title', 
    -command => sub { 
      $pie_chart->configure(-title  => 'other title'); 
      $pie_chart->redraw; 
    } 
  )->pack;
  ...
  # OK, title will be changed and displayed without resize the widget.

=head2 zoom

$pie_chart-E<gt>B<zoom>(I<integer>);

Zoom the graph (vertical and horizontal zoom).

  Ex : 300*300 size
  $pie_chart->zoom(50); # size divide by 2 => 150*150
  ...
  $pie_chart->zoom(200); # size multiplie by 2 => 600*600
  ...
  $pie_chart->zoom(120); # 20% add in each axis => 360*360
  ...
  $pie_chart->zoom(100); # original resize 300*300. 


=head2 zoomx

Horizontal zoom.

  # original canvas size 300*300
  $pie_chart->zoomx(50); # new size : 150*300
  ...
  $pie_chart->zoom(100); # new size : 300*300

=head2 zoomy

Vertical zoom.

  # original canvas size 300*300
  $pie_chart->zoomy(50); # new size : 300*150
  ...
  $pie_chart->zoom(100); # new size : 300*300

=head1 EXAMPLES

In the B<demo> directory, you have a lot of script examples with their screenshot. 
See also the L<http://search.cpan.org/dist/Tk-Chart/MANIFEST> web page of L<Tk::Chart>.

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Pie


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

=head1 COPYRIGHT & LICENSE

Copyright 2011 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut