package Venn::Chart;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou              $
# $Copyright : 2011                          $
# $Update    : 01/01/2011 00:00:00           $
# $AIM       : Create a Venn diagram image   $
#==================================================================

use GD;
use GD::Graph::hbars;
use GD::Graph::colour;
use GD::Text::Align;
use List::Compare;

use vars qw($VERSION);
$VERSION = '1.02';

my %DEFAULT = (
  Hlegend => 70,
  Htitle  => 30,
  space   => 10,
  colors  => [ [ 189, 66, 238, 0 ], [ 255, 133, 0, 0 ], [ 0, 107, 44, 0 ] ],
);
my $WIDTH           = 500;
my $HEIGHT          = 500;
my $MIN_LEGEND      = 2;
my $MAX_LEGEND      = 3;
my $MIN_PLOT        = $MIN_LEGEND;
my $MAX_PLOT        = $MAX_LEGEND;
my $MIN_LIST_REGION = 3;
my $MAX_LIST_REGION = 7;
my $CUBE_SIZE       = 10;
my @RGB_WHITE       = ( 255, 255, 255 );
my @RGB_BLACK       = ( 0, 0, 0 );
my @RGBA            = ( 0, 0, 0, 0 );
my @DEGREES         = ( 0, 360 );
my $SLASH           = q{/};

sub new {
  my ( $self, $width, $height ) = @_;

  $self = ref($self) || $self;
  my $this = {};
  bless $this, $self;

  $this->{_width}  = $width  || $WIDTH;
  $this->{_height} = $height || $HEIGHT;
  $this->{_dim}{Ht}         = 0;
  $this->{_dim}{HLeg}       = 0;
  $this->{_dim}{space}      = $DEFAULT{space};
  $this->{_colors}          = $DEFAULT{colors};
  $this->{_circles}{number} = 0;
  $this->{_legends}{number} = 0;

  return $this;
}

sub set {
  my ( $this, %param ) = @_;

  carp("set method deprecated, please use set_options method\n");
  $this->set_options(%param);

  return 1;
}

sub set_options {
  my ( $this, %param ) = @_;
  $this->{_colors} = $param{'-colors'} || $DEFAULT{colors};

  if ( exists $param{'-title'} ) {
    $this->{_title} = $param{'-title'};
    $this->{_dim}{Ht} = $DEFAULT{Htitle};
  }
  return 1;
}

sub set_legends {
  my ( $this, @legends ) = @_;
  $this->{_legends}{number} = scalar @legends;

  if ( $this->{_legends}{number} < $MIN_LEGEND or $this->{_legends}{number} > $MAX_LEGEND ) {
    carp("You must set $MIN_LEGEND or $MAX_LEGEND legends");
    return;
  }

  $this->{_legend} = \@legends;
  $this->{_dim}{HLeg} = $DEFAULT{Hlegend};

  return 1;
}

sub _legend {
  my ( $this, $image ) = @_;

  # Coords
  my $cubex1 = $DEFAULT{space};
  my $cubey1 = $this->{_dim}{Ht} + $this->{_dim}{Hc} + $CUBE_SIZE;
  my $cubex2 = $cubex1 + $CUBE_SIZE;
  my $cubey2 = $cubey1 + $CUBE_SIZE;
  my $xtext  = $cubex2 + $CUBE_SIZE;
  my $ytext  = $cubey1;

  for ( 0 .. 2 ) {
    my $idcolor = $_ + 1;
    last if ( !( $this->{_legend}->[$_] and $this->{_conf_color}{"color$idcolor"} ) );
    $image->filledRectangle( $cubex1, $cubey1, $cubex2, $cubey2, $this->{_conf_color}{"color$idcolor"} );
    $image->string( gdMediumBoldFont, $xtext, $ytext, $this->{_legend}->[$_], $this->{_conf_color}{black} );
    $cubey1 = $cubey2 + $CUBE_SIZE;
    $cubey2 = $cubey1 + $CUBE_SIZE;
    $ytext  = $cubey1;
  }

  return 1;
}

sub plot {
  my ( $this, @data ) = @_;
  $this->{_circles}{number} = scalar @data;
  if ( $this->{_circles}{number} < $MIN_PLOT or $this->{_circles}{number} > $MAX_PLOT ) {
    croak("You must plot $MIN_PLOT or $MAX_PLOT lists");
  }

  $this->{_dim}{R} = ( $this->{_width} - ( $MIN_PLOT * $this->{_dim}{space} ) ) / $MAX_PLOT;
  $this->{_dim}{D} = $this->{_dim}{R} * $MIN_PLOT;

  # Check Height dimension and recalcul space
  my $diff
    = ( $this->{_dim}{Ht} + $this->{_dim}{D} + $this->{_dim}{R} + $this->{_dim}{HLeg} - $this->{_height} );
  if ( $diff > 0 ) {
    $this->{_dim}{space} += ( $diff / $MIN_PLOT );
    $this->{_dim}{R} = ( $this->{_width} - ( $MIN_PLOT * $this->{_dim}{space} ) ) / $MAX_PLOT;
    $this->{_dim}{D} = $this->{_dim}{R} * $MIN_PLOT;
  }

  my $image = GD::Image->new( $this->{_width}, $this->{_height} );

  $this->{_conf_color}{white} = $image->colorAllocate(@RGB_WHITE);
  $this->{_conf_color}{black} = $image->colorAllocate(@RGB_BLACK);

  # make the background transparent and interlaced
  $image->transparent( $this->{_conf_color}{white} );
  $image->interlaced('true');

  # display circle
  if ( $this->{_title} ) { $this->_title($image); }
  $this->_circle( $image, @data );
  if ( $this->{_legend} ) { $this->_legend($image); }

  $this->{_gd}{plot} = $image;

  return $image;
}

sub _title {
  my ( $this, $image ) = @_;

  if ( not defined $image ) { return; }

  $this->{_coords}{xtitle} = $this->{_dim}{space};
  $this->{_coords}{ytitle} = $this->{_dim}{Ht} / 2;

  my $align = GD::Text::Align->new(
    $image,
    valign => 'center',
    halign => 'center',
    colour => $this->{_conf_color}{black},
  );

  $align->set_font(gdMediumBoldFont);
  $align->set_text( $this->{_title} );
  $align->draw( $this->{_width} / 2, $this->{_coords}{ytitle}, 0 );

  return 1;
}

sub _circle {
  my ( $this, $image, $ref_data1, $ref_data2, $ref_data3 ) = @_;

  if ( not defined $image ) { return; }

  # Venn with 2 circles
  # Coords
  $this->{_coords}{xc1} = $this->{_dim}{space} + $this->{_dim}{R};
  $this->{_coords}{yc1} = $this->{_dim}{R} + $this->{_dim}{Ht};

  $this->{_coords}{xc2} = $this->{_coords}{xc1} + $this->{_dim}{R};
  $this->{_coords}{yc2} = $this->{_coords}{yc1};

  # display circles
  $image->arc(
    $this->{_coords}{xc1},
    $this->{_coords}{yc1},
    $this->{_dim}{D},
    $this->{_dim}{D},
    @DEGREES, $this->{_conf_color}{black}
  );
  $image->arc(
    $this->{_coords}{xc2},
    $this->{_coords}{yc2},
    $this->{_dim}{D},
    $this->{_dim}{D},
    @DEGREES, $this->{_conf_color}{black}
  );

  # text circle
  my $lcm     = List::Compare->new( { lists => [ $ref_data1, $ref_data2, $ref_data3 ], } );
  my @list1   = $lcm->get_unique(0);
  my $data1   = scalar @list1;
  my @list2   = $lcm->get_unique(1);
  my $data2   = scalar @list2;
  my @list3   = $lcm->get_unique(2);
  my $data3   = scalar @list3;
  my @list123 = $lcm->get_intersection;
  my $data123 = scalar @list123;

  my $lc     = List::Compare->new( $ref_data1, $ref_data2 );
  my @list12 = $lc->get_intersection;
  my $lc12   = List::Compare->new( \@list12, \@list123 );
  @list12 = $lc12->get_unique;
  my $data12 = scalar @list12;

  $lc = List::Compare->new( $ref_data1, $ref_data3 );
  my @list13 = $lc->get_intersection;
  my $lc13 = List::Compare->new( \@list13, \@list123 );
  @list13 = $lc13->get_unique;
  my $data13 = scalar @list13;

  $lc = List::Compare->new( $ref_data2, $ref_data3 );
  my @list23 = $lc->get_intersection;
  my $lc23 = List::Compare->new( \@list23, \@list123 );
  @list23 = $lc23->get_unique;
  my $data23 = scalar @list23;

  # for get_regions
  $this->{_regions} = [ $data1, $data2, $data12 ];
  $this->{_listregions} = [ \@list1, \@list2, \@list12 ];

  $this->{_coords}{xt1} = $this->{_dim}{space} + ( $this->{_dim}{R} / $MAX_PLOT );
  $this->{_coords}{yt1} = $this->{_coords}{yc1};

  $this->{_coords}{xt2} = $this->{_dim}{space} + $this->{_dim}{D} + ( $this->{_dim}{R} / $MAX_PLOT );
  $this->{_coords}{yt2} = $this->{_coords}{yc1};

  $this->{_coords}{xt12} = $this->{_coords}{xc1} + ( $this->{_dim}{R} / $MIN_PLOT );
  $this->{_coords}{yt12} = $this->{_coords}{yc1} - ( $this->{_dim}{R} / $MIN_PLOT );

  if ( $this->{_colors}->[0] and $this->{_colors}->[1] ) {
    $this->{_conf_color}{color1} = $image->colorAllocateAlpha( @{ $this->{_colors}->[0] } );
    $this->{_conf_color}{color2} = $image->colorAllocateAlpha( @{ $this->{_colors}->[1] } );
    my $ref_color12 = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[1] );
    $this->{_conf_color}{color12} = $image->colorAllocateAlpha( @{$ref_color12} );

    $image->fill( $this->{_coords}{xt1},  $this->{_coords}{yt1},  $this->{_conf_color}{color1} );
    $image->fill( $this->{_coords}{xt2},  $this->{_coords}{yt2},  $this->{_conf_color}{color2} );
    $image->fill( $this->{_coords}{xt12}, $this->{_coords}{yt12}, $this->{_conf_color}{color12} );

    $this->{_colors_regions} = [ $this->{_colors}->[0], $this->{_colors}->[1], $ref_color12 ];
  }
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt1},
    $this->{_coords}{yt1},
    $data1, $this->{_conf_color}{black}
  );
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt2},
    $this->{_coords}{yt2},
    $data2, $this->{_conf_color}{black}
  );
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt12},
    $this->{_coords}{yt12},
    $data12, $this->{_conf_color}{black}
  );
  $this->{_dim}{Hc} = $this->{_dim}{D};

  # Venn with 3 circles
  if ( defined $ref_data3 ) {
    $this->{_coords}{xc3} = $this->{_coords}{xc1} + ( $this->{_dim}{R} / $MIN_PLOT );
    $this->{_coords}{yc3} = $this->{_coords}{yc1} + $this->{_dim}{R};

    $image->arc(
      $this->{_coords}{xc3},
      $this->{_coords}{yc3},
      $this->{_dim}{D},
      $this->{_dim}{D},
      @DEGREES, $this->{_conf_color}{black}
    );

    $this->{_coords}{xt3} = $this->{_coords}{xc3};
    $this->{_coords}{yt3} = $this->{_coords}{yc3} + ( $this->{_dim}{R} / $MIN_PLOT );

    $this->{_coords}{xt13} = $this->{_coords}{xc1} - ( $this->{_dim}{D} / ( $MAX_PLOT * 2 ) );
    $this->{_coords}{yt13} = $this->{_coords}{yc3} - ( $this->{_dim}{R} / $MIN_PLOT );

    $this->{_coords}{xt23} = $this->{_coords}{xc2};
    $this->{_coords}{yt23} = $this->{_coords}{yc3} - ( $this->{_dim}{R} / $MAX_PLOT );

    $this->{_coords}{xt123} = $this->{_coords}{xt3};
    $this->{_coords}{yt123} = $this->{_coords}{yc3} - 2 * ( $this->{_dim}{R} / $MAX_PLOT );

    if ( $this->{_colors}->[2] ) {
      $this->{_conf_color}{color3} = $image->colorAllocateAlpha( @{ $this->{_colors}->[2] } );
      my $ref_color13 = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[2] );
      my $ref_color23 = $this->_moy_color( $this->{_colors}->[1], $this->{_colors}->[2] );
      my $ref_color123
        = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[1], $this->{_colors}->[2] );
      $this->{_conf_color}{color13}  = $image->colorAllocateAlpha( @{$ref_color13} );
      $this->{_conf_color}{color23}  = $image->colorAllocateAlpha( @{$ref_color23} );
      $this->{_conf_color}{color123} = $image->colorAllocateAlpha( @{$ref_color123} );

      $image->fill( $this->{_coords}{xt3},   $this->{_coords}{yt3},   $this->{_conf_color}{color3} );
      $image->fill( $this->{_coords}{xt13},  $this->{_coords}{yt13},  $this->{_conf_color}{color13} );
      $image->fill( $this->{_coords}{xt23},  $this->{_coords}{yt23},  $this->{_conf_color}{color23} );
      $image->fill( $this->{_coords}{xt123}, $this->{_coords}{yt123}, $this->{_conf_color}{color123} );
      push @{ $this->{_colors_regions} }, $this->{_colors}->[2], $ref_color13, $ref_color23, $ref_color123;
    }

    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt3},
      $this->{_coords}{yt3},
      $data3, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt13},
      $this->{_coords}{yt13},
      $data13, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt23},
      $this->{_coords}{yt23},
      $data23, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt123},
      $this->{_coords}{yt123},
      $data123, $this->{_conf_color}{black}
    );

    $this->{_dim}{Hc} = $this->{_dim}{D} + $this->{_dim}{R};
    push @{ $this->{_regions} }, $data3, $data13, $data23, $data123;
    push @{ $this->{_listregions} }, \@list3, \@list13, \@list23, \@list123;
  }

  return 1;
}

sub get_list_regions {
  my $this = shift;

  if ( $this->{_listregions} ) { return @{ $this->{_listregions} }; }
  return;
}

sub get_regions {
  my $this = shift;

  if ( $this->{_regions} ) { return @{ $this->{_regions} }; }
  return;
}

sub get_colors_regions {
  my $this = shift;

  if ( @{ $this->{_regions} } == $MIN_LIST_REGION or @{ $this->{_regions} } == $MAX_LIST_REGION ) {
    return @{ $this->{_colors_regions} };

  }
  else {
    croak('No data to plot');
  }
  return;
}

sub _moy_color {
  my ( $this, @couleurs ) = @_;
  my ( $R, $G, $B, $A ) = @RGBA;
  foreach my $ref_couleur (@couleurs) {
    my ( $R2, $G2, $B2, $A2 ) = @{$ref_couleur};
    $R += $R2;
    $G += $G2;
    $B += $B2;
    $A += $A2;
  }
  my $total = scalar @couleurs;

  my @moy_couleur = ( int( $R / $total ), int( $G / $total ), int( $B / $total ), int( $A / $total ) );
  return \@moy_couleur;
}

sub plot_histogram {
  my $this = shift;

  # Get data regions
  my @regions = $this->get_regions();
  my ( @data, @names );
  if ( scalar @regions == $MIN_LIST_REGION ) {
    @data = (
      [ 'Region 1',  'Region 2',  'Region 1/2', ],
      [ $regions[0], undef,       undef, ],
      [ undef,       $regions[1], undef, ],
      [ undef,       undef,       $regions[2], ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
    );
  }
  elsif ( scalar @regions == $MAX_LIST_REGION ) {
    @data = (
      [ 'Region 1',  'Region 2',  'Region 1/2', 'Region 3',  'Region 1/3', 'Region 2/3', 'Region 1/2/3' ],
      [ $regions[0], undef,       undef,        undef,       undef,        undef,        undef, ],
      [ undef,       $regions[1], undef,        undef,       undef,        undef,        undef, ],
      [ undef,       undef,       $regions[2],  undef,       undef,        undef,        undef, ],
      [ undef,       undef,       undef,        $regions[3], undef,        undef,        undef, ],
      [ undef,       undef,       undef,        undef,       $regions[4],  undef,        undef, ],
      [ undef,       undef,       undef,        undef,       undef,        $regions[5],  undef, ],
      [ undef,       undef,       undef,        undef,       undef,        undef,        $regions[6], ],
    );

  }
  else {
    croak('No data to plot an histogram');
  }

  my $graph = GD::Graph::bars->new( $this->{_width}, $this->{_height} );

  if ( $this->{_circles}{number} == $MIN_LEGEND and $this->{_legends}{number} == $MIN_LEGEND ) {
    @names = (
      $this->{_legend}->[0],
      $this->{_legend}->[1],
      $this->{_legend}->[0] . $SLASH . $this->{_legend}->[1],
    );
    $graph->set_legend(@names);
  }
  elsif ( $this->{_circles}{number} == $MAX_LEGEND and $this->{_legends}{number} == $MAX_LEGEND ) {
    @names = (
      $this->{_legend}->[0],
      $this->{_legend}->[1],
      $this->{_legend}->[0] . $SLASH . $this->{_legend}->[1],
      $this->{_legend}->[2],
      $this->{_legend}->[0] . $SLASH . $this->{_legend}->[2],
      $this->{_legend}->[1] . $SLASH . $this->{_legend}->[2],
      $this->{_legend}->[0] . $SLASH . $this->{_legend}->[1] . $SLASH . $this->{_legend}->[2],
    );
    $graph->set_legend(@names);
  }
  elsif ( $this->{_circles}{number} > 0
    and $this->{_legends}{number} > 0
    and $this->{_circles}{number} != $this->{_legends}{number} )
  {
    carp("You have to set $this->{_circles}{number} legends if you want to see a legend");
  }

  $graph->set(
    cumulate      => 'true',
    box_axis      => 0,
    x_ticks       => 0,
    x_plot_values => 0,
  ) or carp $graph->error;

  my @color_regions = map { GD::Graph::colour::rgb2hex( @{$_}[ 0 .. 2 ] ) } $this->get_colors_regions();
  $graph->set( dclrs => \@color_regions );
  my $gd = $graph->plot( \@data ) or croak $graph->error;

  return $gd;
}

1;    # End of Venn::Chart

__END__

=head1 NAME

Venn::Chart - Create a Venn diagram using GD.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use warnings;
  use Carp;
  use strict;
  
  use Venn::Chart;
  
  # Create the Venn::Chart constructor
  my $venn_chart = Venn::Chart->new( 400, 400 ) or die("error : $!");
  
  # Set a title and a legend for our chart
  $venn_chart->set_options( -title => 'Venn diagram' );
  $venn_chart->set_legends( 'Team 1', 'Team 2', 'Team 3' );
  
  # 3 lists for the Venn diagram
  my @team1 = qw/abel edward momo albert jack julien chris/;
  my @team2 = qw/edward isabel antonio delta albert kevin jake/;
  my @team3 = qw/gerald jake kevin lucia john edward/;
  
  # Create a diagram with gd object
  my $gd_venn = $venn_chart->plot( \@team1, \@team2, \@team3 );
  
  # Create a Venn diagram image in png, gif and jpeg format
  open my $fh_venn, '>', 'VennChart.png' or die("Unable to create png file\n");
  binmode $fh_venn;
  print {$fh_venn} $gd_venn->png;
  close $fh_venn or die('Unable to close file');
  
  # Create an histogram image of Venn diagram (png, gif and jpeg format)
  my $gd_histogram = $venn_chart->plot_histogram;
  open my $fh_histo, '>', 'VennHistogram.png' or die("Unable to create png file\n");
  binmode $fh_histo;
  print {$fh_histo} $gd_histogram->png;
  close $fh_histo or die('Unable to close file');
  
  # Get data list for each intersection or unique region between the 3 lists
  my @ref_lists = $venn_chart->get_list_regions();
  my $list_number = 1;
  foreach my $ref_region ( @ref_lists ) {
    print "List $list_number : @{ $ref_region }\n";
    $list_number++;
  }

=head1 DESCRIPTION

Venn::Chart create a Venn diagram image using L<GD> module with 2 or 3 data lists. A title and a legend can be added in the chart. 
It is possible to create an histogram chart with the different data regions of Venn diagram using L<GD::Graph> module.

=head1 CONSTRUCTOR/METHODS

=head2 new

This constructor allows you to create a new Venn::Chart object.

B<$venn_chart = Venn::Chart-E<gt>new($width, $height)>

The new() method is the main constructor for the Venn::Chart module. It creates a new blank image of the specified width and height.

  # Create Venn::Chart constructor
  my $venn_chart = Venn::Chart->new( 400, 400 );

The default width and height size are 500 pixels.

=head2 set

Do not use this method. It has been replaced by B<set_options> method. 

=head2 set_options

Set the image title and colors of the diagrams.

B<$venn_chart-E<gt>set_options( -attrib =E<gt> value, ... )>

=over 4

=item B<-title> =E<gt> I<string>

Specifies the title.

  -title => 'Venn diagram',

=back

=over 4

=item B<-colors> =E<gt> I<array reference>

Specifies the RGBA colors of the 2 or 3 lists. This allocates a color with the specified red, green, and blue components, plus the specified alpha channel for each circle. 
The alpha value may range from 0 (opaque) to 127 (transparent). The alphaBlending function changes the way this alpha channel affects the resulting image.  

    -colors => [ [ 98, 66, 238, 0 ], [ 98, 211, 124, 0 ], [ 110, 205, 225, 0 ] ],

Default : B<[ [ 189, 66, 238, 0 ], [ 255, 133, 0, 0 ], [ 0, 107, 44, 0 ] ]>

=back

  $venn_chart->set_options( 
    -title  => 'Venn diagram',
    -colors => [ [ 98, 66, 238, 0 ], [ 98, 211, 124, 0 ], [ 110, 205, 225, 0 ] ],
  );

=head2 set_legends

Set the image legends. This method set a legend which represents the title of each 2 or 3 diagrams (circles).

B<$venn_chart-E<gt>set_legends( I<legend1, legend2, legend3> )>

  # Set title and a legend for our chart
  $venn_chart->set_legends('Diagram1', 'Diagram2', 'Diagram3');


=head2 plot

Plots the chart, and returns the GD::Image object.

B<$venn_chart-E<gt>plot( I<array reference list> )>

  my $gd = $venn_chart->plot(\@list1, \@list2, \@list3);

To create your image, do whatever your current version of GD allows you to do to save the file. For example: 

  open my $fh_image, '>', 'venn.png' or die("Error : $!");
  binmode $fh_image;
  print {$fh_image} $gd->png;
  close $fh_image or die('Unable to close file');


=head2 get_list_regions

Get a list of array reference which contains data for each intersection or unique region between the 2 or 3 lists.

B<$venn_chart-E<gt>get_list_regions()>

=over 4

=item B<Case : 2 lists>

  my $gd_venn   = $venn_chart->plot( \@team1, \@team2 );
  my @ref_lists = $venn_chart->get_list_regions();

@ref_lists will contain 3 array references.
  
  @{ $ref_lists[0] } => unique elements of @team1 between @team1 and @team2    
  @{ $ref_lists[1] } => unique elements of @team2 between @team1 and @team2
  @{ $ref_lists[2] } => intersection elements between @team1 and @team2   

=back

=over 4

=item B<Case : 3 lists>

  my $gd_venn   = $venn_chart->plot( \@team1, \@team2, \@team3 );
  my @ref_lists = $venn_chart->get_list_regions();

@ref_lists will contain 7 array references.
  
  @{ $ref_lists[0] } => unique elements of @team1 between @team1, @team2 and @team3    
  @{ $ref_lists[1] } => unique elements of @team2 between @team1, @team2 and @team3  
  @{ $ref_lists[2] } => intersection elements between @team1 and @team2   
  @{ $ref_lists[3] } => unique elements of @team3 between @team1, @team2 and @team3  
  @{ $ref_lists[4] } => intersection elements between @team3 and @team1  
  @{ $ref_lists[5] } => intersection elements between @team3 and @team2  
  @{ $ref_lists[6] } => intersection elements between @team1, @team2 and @team3

=back

Example :

  my @team1 = qw/abel edward momo albert jack julien chris/;
  my @team2 = qw/edward isabel antonio delta albert kevin jake/;
  my @team3 = qw/gerald jake kevin lucia john edward/;
    
  my $gd_venn = $venn_chart->plot( \@team1, \@team2, \@team3 );
  my @lists   = $venn_chart->get_list_regions();

  Result of @lists
  [ 'jack', 'momo', 'chris', 'abel', 'julien' ], # Unique of @team1
  [ 'delta', 'isabel', 'antonio' ],              # Unique of @team2
  [ 'albert' ],                                  # Intersection between @team1 and @team2
  [ 'john', 'gerald', 'lucia' ],                 # Unique of @team3
  [],                                            # Intersection between @team3 and @team1
  [ 'jake', 'kevin' ],                           # Intersection between @team3 and @team2
  [ 'edward' ]                                   # Intersection between @team1, @team2 and @team3


=head2 get_regions

Get an array displaying the object number of each region of the Venn diagram.

B<$venn_chart-E<gt>get_regions()>

  my $gd_venn = $venn_chart->plot( \@team1, \@team2, \@team3 );
  my @regions = $venn_chart->get_regions;

  @regions contains 5, 3, 1, 3, 0, 2, 1

=head2 get_colors_regions

Get an array contains the colors (in an array reference) used for each region in Venn diagram.

B<$venn_chart-E<gt>get_colors_regions()>

  my @colors_regions = $venn_chart->get_colors_regions;

  @colors_regions = (
    [R, G, B, A], [R, G, B, A], [R, G, B, A],
    [R, G, B, A], [R, G, B, A], [R, G, B, A],
    [R, G, B, A]
  ); 


  @{ $colors_regions[0] } => color of @{ $ref_lists[0] }    
  @{ $colors_regions[1] } => color of @{ $ref_lists[1] }
  @{ $colors_regions[2] } => color of @{ $ref_lists[2] }   
  @{ $colors_regions[3] } => color of @{ $ref_lists[3] }  
  @{ $colors_regions[4] } => color of @{ $ref_lists[4] }
  @{ $colors_regions[5] } => color of @{ $ref_lists[5] }
  @{ $colors_regions[6] } => color of @{ $ref_lists[6] }

=head2 plot_histogram

Plots an histogram displaying each region of the Venn diagram which returns the GD::Image object.

B<$venn_chart-E<gt>plot_histogram>

To create the histogram, the Venn diagram have to be already created. 

  # Create histogram of Venn diagram image in png, gif and jpeg format
  my $gd_histogram = $venn_chart->plot_histogram;
  
  open my $fh_histo, '>', 'VennHistogram.png' or die('Unable to create file');
  binmode $fh_histo;
  print {$fh_histo} $gd_histogram->png;
  close $fh_histo or die('Unable to close file');

If you want to create and design the histogram yourself, use L<GD::Graph> module and play with data obtained with L</"get_regions"> methods.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-venn-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Venn-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

See L<GD>, L<GD::Graph>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Venn::Chart


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Venn-Chart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Venn-Chart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Venn-Chart>

=item * Search CPAN

L<http://search.cpan.org/dist/Venn-Chart/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Djibril Ousmanou.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

