package Tk::Taxis;

use 5.008006;
use strict;
use warnings::register( 'Tk::Taxis' );

our $VERSION = '2.03';

################################## defaults ####################################

use constant WIDTH       => 400;
use constant HEIGHT      => 400;
use constant POPULATION  => 20;
use constant PREFERENCE  => [ 100, 100 ];
use constant TUMBLE      => 0.03;
use constant SPEED       => 0.006;
use constant IMAGES      => "woodlice";
use constant FILL        => [ [ 'white', 'gray' ],
                              [ 'white', 'gray' ] ];
use constant LEFT_FILL  => "white"; # deprecated
use constant RIGHT_FILL => "gray";  # deprecated
use constant CALCULATION => 
							sub 
							{
								my ( $critter ) = @_;
								my %boundries   = $critter->get_boundries();
								my ( $x, $y )   = $critter->get_pos();
								return
									$x / $boundries{ width  },
									$y / $boundries{ height };
							};
							
################################### widget #####################################

use Tk qw( DoOneEvent DONT_WAIT );
use Tk::Taxis::Critter;

require Tk::Frame;
our @ISA = ( 'Tk::Frame' );

Tk::Widget->Construct( 'Taxis' );

sub Populate
{   
	my ( $taxis, $options ) = @_;
	my $canvas = $taxis->Canvas();
	$taxis->Advertise( 'canvas' => $canvas );
	$canvas->pack();
	
	$taxis->{ _supress_redraw } = 1; # so no multiple redraws on initialisation
	$taxis->images(      delete $options->{ -images }       || IMAGES );
	$taxis->preference(  delete $options->{ -preference }   || PREFERENCE );
	$taxis->tumble(      delete $options->{ -tumble }       || TUMBLE );
	$taxis->speed(       delete $options->{ -speed }        || SPEED );
	$taxis->width(       delete $options->{ -width }        || WIDTH );
	$taxis->height(      delete $options->{ -height }       || HEIGHT );
	$taxis->population(  delete $options->{ -population }   || POPULATION );
	$taxis->fill(        delete $options->{ -fill }         || FILL );
	$taxis->calculation( delete $options->{ -calculation }  || CALCULATION );
	
	# deprecated options
	if ( $options->{ -left_fill } )
	{
		$taxis->left_fill(   delete $options->{ -left_fill }    || LEFT_FILL );
	}
	if ( $options->{ -right_fill } )
	{
		$taxis->right_fill(  delete $options->{ -right_fill }   || RIGHT_FILL );
	}

	$taxis->{ _supress_redraw } = 0;	
	$taxis->refresh();
	
	$taxis->ConfigSpecs
	(
		-images      => [ 'METHOD', 'images',      'Images',      undef ],
		-preference  => [ 'METHOD', 'preference',  'Preference',  undef ],
		-tumble      => [ 'METHOD', 'tumble',      'Tumble',      undef ],
		-speed       => [ 'METHOD', 'speed',       'Speed',       undef ],
		-width       => [ 'METHOD', 'width',       'Width',       undef ],
		-height      => [ 'METHOD', 'height',      'Height',      undef ],
		-population  => [ 'METHOD', 'population',  'Population',  undef ],
		-fill        => [ 'METHOD', 'fill',        'Fill',        undef ],
		-calculation => [ 'METHOD', 'calculation', 'Calculation', undef ],
		DEFAULT      => [ $canvas ],
	);
	$taxis->SUPER::Populate( $options );
	$taxis->Delegates( DEFAULT => $canvas );
}

################################### images #####################################

sub images
{
	my ( $taxis, $images ) = @_;
	if ( $images )
	{
		$taxis->{ images } = $images;
		unless ( $taxis->{ image_bank }{ $images } )
		{
			$taxis->{ image_bank }{ $images } =
			{
				n  => $taxis->Photo( -file => $taxis->_find_image( "n.gif"  ) ),
				ne => $taxis->Photo( -file => $taxis->_find_image( "ne.gif" ) ),
				e  => $taxis->Photo( -file => $taxis->_find_image( "e.gif"  ) ),
				se => $taxis->Photo( -file => $taxis->_find_image( "se.gif" ) ),
				s  => $taxis->Photo( -file => $taxis->_find_image( "s.gif"  ) ),
				sw => $taxis->Photo( -file => $taxis->_find_image( "sw.gif" ) ),
				w  => $taxis->Photo( -file => $taxis->_find_image( "w.gif"  ) ),
				nw => $taxis->Photo( -file => $taxis->_find_image( "nw.gif" ) ),
				0  => $taxis->Photo(),
			};
		}
		$taxis->image_height
		(
			$taxis->{ image_bank }{ $images }{ n }->height() || 50
		);	
		$taxis->image_width
		( 
			$taxis->{ image_bank }{ $images }{ n }->width()  || 50
		);
		$taxis->refresh();
	}
	return $taxis->{ images };
}

sub _find_image
{
	my ( $taxis, $file ) = @_;
	my $dir = $taxis->{ images };
	my $found;
	if ( my ( $path ) = $dir =~ /^\@(.*)$/ )
	{
		$found = ( grep { -e $_ } "$path/$file" )[ 0 ];
		warnings::warn( "No such file $path/$file" ) unless $found;
	}
	else
	{
		$found = 
		   ( grep { -f $_ } map { "$_/Tk/Taxis/images/$dir/$file" } @INC )[ 0 ];
		warnings::warn( "No such file \@INC/Tk/Taxis/images/$dir/$file" )
			unless $found;
	}
	return $found;
}

sub _create_critter_image
{
	my ( $taxis, $critter ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	my @pos    = $critter->get_pos();
	my $id     = $critter->get_id();
	my $image  = 
		$taxis->{ image_bank }{ $taxis->{ images } }{ $critter->get_orient() };
	if ( defined $id )
	{
		$canvas->coords( $id, $pos[ 0 ], $pos[ 1 ] );
		$canvas->itemconfigure( $id, -image => $image );
	}
	else
	{
		my $id = $canvas->create
			( 'image', $pos[ 0 ], $pos[ 1 ], 
				-anchor => 'center', -image  => $image );
		$critter->set_id( $id );
	}
	return $taxis;
}

sub _hide_critter_image
{
	my ( $taxis, $critter ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	my $id     = $critter->get_id();
	my $image  = $taxis->{ image_bank }{ $taxis->{ images } }{ 0 };
	if ( defined $id )
	{
		$canvas->itemconfigure( $id, -image => $image );
	}
	return $taxis;
}

sub image_height
{
	my ( $taxis, $image_height ) = @_;
	if ( defined $image_height )
	{
		$taxis->{ image_height } = $image_height;
	}
	return $taxis->{ image_height };
}

sub image_width
{
	my ( $taxis, $image_width ) = @_;
	if ( defined $image_width )
	{
		$taxis->{ image_width } = $image_width;
	}
	return $taxis->{ image_width };
}

################################## critters ####################################

sub preference
{
	my ( $taxis, $preference ) = @_;
	if ( defined $preference )
	{
		$preference = [ $preference ] unless ref $preference;
		for my $i ( 0 .. 1 )
		{
			if ( defined $preference->[ $i ] )
			{
				if ( abs $preference->[ $i ] < 1 )
				{
					warnings::warn( "Absolute value of preference must be greater than 1" );
					${ $preference }[ $i ] = 1;
				}
			}
			else
			{
				$preference->[ $i ] = 1;
			}
		}
		$taxis->{ preference } = $preference;
	}
	return $taxis->{ preference };
}

sub tumble
{
	my ( $taxis, $tumble ) = @_;
	if ( defined $tumble )
	{	
		if ( $tumble > 1 )
		{
			warnings::warn( "Tumble value too high, setting to 1" );
			$tumble = 1;
		}
		elsif ( $tumble < 0 )
		{
			warnings::warn( "Tumble value too low, setting to 0" );
			$tumble = 0;
		}
		$taxis->{ tumble } = $tumble;
	}
	return $taxis->{ tumble };
}

sub speed
{
	my ( $taxis, $speed ) = @_;
	if ( defined $speed )
	{
		my $canvas = $taxis->Subwidget( 'canvas' );
		my $max_x  = $canvas->cget( -width );
		my $max_y  = $canvas->cget( -height );
		my $min_speed = 2 / sqrt ( $max_x**2 + $max_y**2 );
		if ( $speed < $min_speed )
		{
			warnings::warn( "Speed too low, setting to minimum value of $min_speed" );
			$speed = $min_speed;
				# or they sit there and spin
		}
		$taxis->{ speed } = $speed;
	}
	return $taxis->{ speed };
}

sub calculation
{
	my ( $taxis, $calculation ) = @_;
	if ( defined $calculation )
	{
		$taxis->{ calculation } = $calculation;
	}
	return $taxis->{ calculation };
}

#################################### taxis #####################################

sub taxis
{
	my ( $taxis, $options ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	if ( $taxis->{ critters } )
	{
		my $critter;
		for my $i ( 1 .. $taxis->{ population } )
		{
			$critter = $taxis->{ critters }[ $i ];
			$critter->move();
			$taxis->_create_critter_image( $critter );
		}
		DoOneEvent( DONT_WAIT ); 
	}
	return $taxis;
}

#################################### arena #####################################

sub population
{
	my ( $taxis, $population ) = @_;
	if ( defined $population )
	{
		$taxis->{ population } = abs $population;
		$taxis->refresh();
	}
	if ( wantarray )
	{
		my $canvas = $taxis->Subwidget( 'canvas' );
		my ( $top_left, $top_right, $bottom_left, $bottom_right ) 
		=  ( 0,         0,          0,            0             );
		my $vert_limit  = $canvas->cget( -height ) / 2;
		my $horiz_limit = $canvas->cget( -width )  / 2;
		for my $i ( 1 .. $taxis->{ population } )
		{
			if ( ${ $taxis->{ critters } }[ $i ]{ pos }[ 1 ] 
					<= $vert_limit )
			{
				${ $taxis->{ critters } }[ $i ]{ pos }[ 0 ] 
					<= $horiz_limit ? 
						$top_left++ : 
							$top_right++;	
			}
			else
			{
				${ $taxis->{ critters } }[ $i ]{ pos }[ 0 ] 
					<= $canvas->cget( -width ) / 2 ? 
						$bottom_left++ : 
							$bottom_right++;					
			} 
		}
		return 
			(
				top          => ( $top_left     + $top_right ),
				bottom       => ( $bottom_left  + $bottom_right ),
				left         => ( $bottom_left  + $top_left ),
				right        => ( $bottom_right + $top_right ),
				top_left     => $top_left,
				bottom_left  => $bottom_left,
				top_right    => $top_right,
				bottom_right => $bottom_right,
				total        => ( $top_left + $top_right + $bottom_left + $bottom_right ),
			);			
	}
	else
	{
		return $taxis->{ population };
	}
}

sub width
{
	my ( $taxis, $width ) = @_;
	if ( $width )
	{
		$taxis->{ width } = $width;
		$taxis->refresh();
	}
	return $taxis->{ width };
}

sub height
{
	my ( $taxis, $height ) = @_;
	if ( $height )
	{
		$taxis->{ height } = $height;
		$taxis->refresh();
	}
	return $taxis->{ height };	
}

sub fill
{
	my ( $taxis, $fill ) = @_;
	if ( defined $fill )
	{
		if ( not ref $fill )
		{
			$taxis->{ fill } = [ [ $fill, $fill ], [ $fill, $fill ] ];
		}
		elsif ( ref $fill && 
				( not ref $fill->[0] ) && 
					( not ref $fill->[1] ) )
		{
			$taxis->{ fill } = [ [ $fill->[0], $fill->[1] ], 
			                     [ $fill->[0], $fill->[1] ] ];
		}
		elsif ( ref $fill->[0] && ref $fill->[1] )
		{
			$taxis->{ fill } = [ [ $fill->[0][0], $fill->[0][1] ], 
			                     [ $fill->[1][0], $fill->[1][1] ] ];			
		}
		else
		{
			warnings::warn( "Invalid argument to fill" );
			return;
		}
		$taxis->refresh();
	}
	return $taxis->{ fill };
}

sub left_fill
{
	my ( $taxis, $left_fill ) = @_;
	if ( $left_fill )
	{
		warnings::warn( "left_fill is deprecated, use fill instead" );
		$taxis->{ fill }[0][0] = $left_fill;
		$taxis->{ fill }[1][0] = $left_fill;
		$taxis->refresh();
	}
	return $taxis->{ fill }[0][0];	
}
	
sub right_fill
{
	my ( $taxis, $right_fill ) = @_;
	if ( $right_fill )
	{
		warnings::warn( "right_fill is deprecated, use fill instead" );
		$taxis->{ fill }[0][1] = $right_fill;
		$taxis->{ fill }[1][1] = $right_fill;
		$taxis->refresh();
	}
	return $taxis->{ fill }[1][1];	
}

sub refresh
{
	my ( $taxis, $options ) = @_;
	return if $taxis->{ _supress_redraw };
	my $canvas = $taxis->Subwidget( 'canvas' );
	$canvas->configure( -width  => $taxis->width()  );
	$canvas->configure( -height => $taxis->height() );
	my $max_x  = $taxis->{ width };
	my $max_y  = $taxis->{ height };
	if ( $taxis->{ arena } )
	{
		my ( $top_left, $top_right, $bottom_left, $bottom_right ) 
					= @{ $taxis->{ arena } };
		$canvas->coords
			( $top_left, 0, 0, $max_x/2, $max_y/2 );
		$canvas->itemconfigure( $top_left, -fill => $taxis->{fill}[0][0] );
		
		$canvas->coords
			( $top_right, $max_x/2, 0, $max_x, $max_y/2 );
		$canvas->itemconfigure( $top_right, -fill => $taxis->{fill}[0][1] );
		
		$canvas->coords
			( $bottom_left, 0, $max_y/2, $max_x/2, $max_y);	
		$canvas->itemconfigure( $bottom_left, -fill => $taxis->{fill}[1][0] );
		
		$canvas->coords
			( $bottom_right, $max_x/2, $max_y/2, $max_x, $max_y );		
		$canvas->itemconfigure( $bottom_right, -fill => $taxis->{fill}[1][1] );
		
	}
	else
	{
		my $top_left = $canvas->create
			( 'rectangle', 0, 0, $max_x/2, $max_y/2,
				-fill => $taxis->{fill}[0][0] );
		
		my $top_right = $canvas->create
			( 'rectangle', $max_x/2, 0, $max_x, $max_y/2,
				-fill => $taxis->{fill}[0][1] );
		
		my $bottom_left = $canvas->create
			( 'rectangle', 0, $max_y/2, $max_x/2, $max_y,
				-fill => $taxis->{fill}[1][0] );
		
		my $bottom_right = $canvas->create
			( 'rectangle', $max_x/2, $max_y/2, $max_x, $max_y,
				-fill => $taxis->{fill}[1][1] );

		$taxis->{ arena } = [ $top_left, $top_right, $bottom_left, $bottom_right ];
	}
	my $i;
	for ( $i = 1 ; $i <= $taxis->{ population } ; $i++ )
	{
		my $critter = $taxis->{ critters }[ $i ];
		unless ( $critter )
		{
			$critter = Tk::Taxis::Critter->new( -taxis => $taxis );
			$taxis->{ critters }[ $i ] = $critter;
		}
		$critter->randomise();
		$taxis->_create_critter_image( $critter );
	}
	for my $j ( $i .. @{ $taxis->{ critters } } - 1  )
	{
		
		# We don't delete the critters from the critters arrayref, 
		# we just keep track of the current population size, and 
		# grow this as appropriate; we only hide their images from view in the 
		# canvas. We do this because we cannot satifactorily 
		# delete images from canvases, as this appears to cause memory leakage
		# even if we delete all references, and call the delete method on all 
		# widgets. I presume this is a bug in Tk::Canvas, as it works for other 
		# imaged widgets. This way we only get as big as the largest population 
		# called during the life of the script.
		
		my $critter = $taxis->{ critters }[ $j ];
		$taxis->_hide_critter_image( $critter );
	}
	DoOneEvent( DONT_WAIT ); 
	return $taxis;
}

1;

__END__

=head1 NAME

Tk::Taxis - Perl extension for simulating biological taxes

=head1 SYNOPSIS

  use Tk::Taxis;
  my $taxis = $mw->Taxis( -width => 200, -height => 100 )->pack();
  $taxis->configure( -population => 20 );
  $taxis->taxis() while 1;

=head1 ABSTRACT

Simulates the biological movement called taxis

=head1 DESCRIPTION

Organisms such as bacteria respond to gradients in chemicals, light, I<etc>, by 
a process called taxis ('movement'). This module captures some of the spirit of 
this model of organismal movement. Bacteria are unable to measure differential
gradients of chemicals along the length of their cells. Instead, they measure
the concentration at a given point, move a little, measure it again, then if
they find they are running B<up> a favourable concentration gradient, they 
reduce their tumbling frequency (the probability that they will randomly change 
direction). In this way, they effect a random walk that is biased up the 
gradient. 

=head2 METHODS

C<Tk::Taxis> is a composite widget, so to invoke a new instance, you need to 
call it in the usual way...

  my $taxis = $mw->Taxis( -option => value )->pack();
  $taxis->configure ( -option => value );
  my $number = $taxis->cget( -option );

or similar. This widget is based on Frame and implements a Canvas. Configurable 
options are mostly forwarded to the Canvas subwidget, which be directly accessed
by the C<Subwidget('canvas')> method. Options specific to the C<Tk::Taxis> 
widget are listed below. If you try to pass in values too low or high (as 
specified below), the module will C<warn> and set a default minimum or maximum 
instead. These options can be set in the constructor, and get/set by the 
standard C<cget> and C<configure> methods.

=over 4

=item * C<-width>

Sets the width of the taxis arena in pixels. Defaults to 400 pixels.

=item * C<-height>

Sets the height of the taxis arena. You are advised to set the height and width
when constructing the widget, rather than configuring them after the event, as
this will result in repeated redrawings of the canvas. Defaults to 400 pixels.

=item * C<-tumble>

This sets the default tumble frequency, I<i.e.> the tumble frequency when the 
critters are moving B<down> the concentration gradient. Values less than 0 or
more than 1 will be truncated to 0 or 1. Defaults to 0.03.

=item * C<-speed>

This sets the speed of the critters. When the critters are moved, the run length
is essentially set to C<rand( diagonal_of_canvas ) * speed * cos rotation>. If 
there is no rotation, the maximum run length will be simply be the diagonal of 
the canvas multiplied by the speed. If you try to set a speed lower than C<2 / 
diagonal_of_canvas>, it will be ignored, and this minimum value will be used 
instead, otherwise your critters, moving a fractional number of pixels, will sit 
there and spin like tops. Defaults to 0.006.

=item * C<-images>

This takes a string argument which is the path to a directory containing images
to display as critters. If this begins with an C<@> sign, this will be taken to 
be a real path. Otherwise, it will be taken to be a default image set. This may
currently be 'woodlice' or 'bacteria' (these images are located in directories 
of the same name in C<@INC/Tk/Taxis/images/>). There must be eight images, named 
C<n.gif>, C<ne.gif>, C<e.gif>, C<se.gif>, C<s.gif>, C<sw.gif>, C<w.gif> and 
C<nw.gif>, each showing the critter in a different orientation (n being 
vertical, e being pointing to the right, I<etc>). These images should all have
the same dimensions. Defaults to 'woodlice'.

=item * C<-population>

This takes an integer argument to configure the size of the population. If 
C<cget( -population )> is called, the return value depends on context: the
total population is returned in scalar context, but in list context, a hash is
returned, with keys C<total>, C<top_left>, C<top>, C<left>, C<bottom_right>,
I<etc>, indicating the number of critters in each quadrant, half and in total.
(This is a slight change from the version 1 API, where left and right counts
were returned in list context). Defaults to 20.

=item * C<-fill>

=item * C<-fill =E<gt> 'red'>

=item * C<-fill =E<gt> [ 'red', 'blue' ]>

=item * C<-fill =E<gt> [ [ 'red', 'blue' ], [ 'red', 'blue' ] ]> 

This takes arguments to set the fill colour of the quadrants of the arena. The 
arguments should be standard C<Tk> colour strings, I<e.g.> "red" or "#00FF44". 
If the argument is a single string, this will be used to fill the whole arena;
if an arrayref, the fills will be applied to the left and right repectively;
if an arrayref of arrayrefs, the fills will be applied thusly... 

      $taxis->configure( -fill => [ 
          [ 'top_left_colour',    'top_right_colour' ],
          [ 'bottom_left_colour', 'bottom_right_colour' ]
      ] ); 

The C<left_fill> and C<right_fill> methods are available for backwards 
compatibility with the version 1 API, but they are deprecated.

=item * C<-preference>

=item * C<-preference =E<gt> 100>

=item * C<-preference =E<gt> [ 100, -100 ]>

=item * C<-preference =E<gt> [ $preference_for_right, $preference_for_bottom ]>

This takes arguments indicating the preference the critters have for the 
right hand side and bottom of the taxis arena. If the argument is a single 
integer, this indicates a left/right preference and the top/bottom preference 
will be set to indifference. An arrayref argument can be used to set both 
left/right and top/bottom preference. The arguments must have an I<absolute>
value greater than 1 (values less than this will be reset to 1), but a negative
sign can be used to indicate a preference for the top and/or left rather than
the bottom and/or right. 

When the critters are moving B<up> the left/right gradient, the probability of a
tumble will be reduced. This is achieved by dividing the default tumble by 
the left/right preference value. Further division by the top/bottom preference 
value will be carried out independently if a critter is also moving up the
top/bottom gradient. Absolute values of 1 will therefore yield indifference.

Returns an arrayref of the preference values.

=item * C<-calculation>

This takes a coderef argument that determines the value of the top/bottom and
left/right gradients. The coderef will I<not> be sanity checked, but I<must>
behave as if it were a method of a C<Tk::Taxis::Critter> object. When the 
coderef is invoked it will be given a critter object as its only argument, 
allowing the code access to the methods in that class, such as C<get_boundries>
and C<get_pos> (see L<Tk::Taxis::Critter>). The coderef I<must> return the x and
y gradient values. By default the calculation coderef is... 

    sub 
    {
        my ( $critter ) = @_;
        my %boundries   = $critter->get_boundries();
        my ( $x, $y )   = $critter->get_pos();
        return
            $x / $boundries{ width  },  # x gradient value
            $y / $boundries{ height };  # y gradient value
    };

=back

These options can also all be called as similarly named methods. There are also 
two additional public methods...

=over 4

=item * C<taxis>

This executes one cycle of the taxis simulation. Embed calls to this in a 
C<while> loop to run the simulation. See the script C<eg/woodlice.pl> for an 
example of how to embed an interruptable loop within a handrolled main-loop, or
CAVEATS below.

=item * C<refresh>

This refreshes the taxis arena, resizing and recolouring as necessary.

=back

Two final methods available are C<image_height> and C<image_width>, which
get/set the height and width of the image used as a critter. It is inadvisable
to set these, but the C<Tk::Taxis::Critter> class requires read-only access to 
them.

=head1 CAVEATS

Those used to writing...

  MainLoop();

in every C<Tk> script should note that because the simulation requires its 
B<own> event loop I<within> the event loop of the main program, this will not 
work out of the box. The best solution I have found is this...

  # import some semantics 
  use Tk qw( DoOneEvent DONT_WAIT );
  use Tk::Taxis;
  use Time::HiRes;
  my $mw = new MainWindow;
  my $taxis = $mw->Taxis()->pack();

  # this tells us whether we are running the simulation or not
  my $running = 1;
  
  # minimum refresh rate
  my $refresh = 0.02; # 20 ms
  
  # home-rolled event loop
  while ( 1 )
  {
    my $finish = $refresh + Time::HiRes::time;
    $taxis->taxis() if $running;
    while ( Time::HiRes::time < $finish  )
      # take up some slack time if the loop executes too quickly
    { 
      DoOneEvent( DONT_WAIT );
    }
  }
  
  # arrange for a start/stop Button or similar to invoke this callback
  sub start_toggle
  {
  	$running = $running ? 0 : 1;
  }

As every call to C<taxis> involves iterating over the entire population, when 
that population is small, the iterations occur more quickly than when the 
population is large. This event loop ensures that small populations do not
whizz around madly (as would be the case if we used a simple C<while> loop), 
whilst ensuring that large populations do not cause the script to hang in deep
recursion (as would be the case if we used a timed C<repeat> callback and a
default C<MainLoop()>).

=head1 SEE ALSO

L<Tk::Taxis::Critter>

=head1 AUTHOR

Steve Cook, E<lt>steve@steve.gb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Steve Cook

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
