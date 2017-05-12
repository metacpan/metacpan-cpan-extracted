package Tk::Taxis::Critter;

use 5.008006;
use strict;
use warnings::register;

our $VERSION = '2.03';

use constant PI => 4 * atan2( 1, 1 );

sub new
{
	my ( $class, %options ) = @_;
	my $critter = { };
	$critter->{ taxis } = $options{ -taxis };
	die( "Can't create critter without -taxis option" )
		unless ref $critter->{ taxis };
	bless $critter, $class;
	$critter->randomise();
	return $critter;	
}

sub get_boundries
{
	my ( $critter ) = @_;
	my $min_x   = $critter->{ taxis }{ image_width } / 2;
	my $max_x   = $critter->{ taxis }->width() - $min_x;
	my $min_y   = $critter->{ taxis }{ image_height } / 2;
	my $max_y   = $critter->{ taxis }->height() - $min_y;	
	my $width   = $critter->{ taxis }->width();
	my $height  = $critter->{ taxis }->height();
	return
	(
		min_x  => $min_x, 
		max_x  => $max_x, 
		min_y  => $min_y,
		max_y  => $max_y,
		width  => $width,
		height => $height,
	);
}

sub randomise
{
	my ( $critter )          = @_;
	my %b                    = $critter->get_boundries();
	$critter->{ direction }  = rand ( 2 * PI );
	$critter->set_orient();
	$critter->{ height }     = 
		$critter->{ taxis }->image_height() || 50;
	$critter->{ width }     = 
		$critter->{ taxis }->image_width()  || 50;
	my $x = $b{ min_x } + int rand( 1 + $b{ max_x } - $b{ min_x } );
	my $y = $b{ min_y } + int rand( 1 + $b{ max_y } - $b{ min_y } );
	$critter->set_pos( $x, $y );
	$critter->{ last_value } = [ 0, 0 ]; # initial value doesn't much matter
	return $critter;
}

sub move
{
	my ( $critter )          = @_;
	my %b                    = $critter->get_boundries();
	my ( $x_pos, $y_pos )    = $critter->get_pos();
	my $preference           = $critter->{ taxis }->preference();
	
	my @new_values = $critter->{ taxis }->calculation()->( $critter );
		# call the calculation subref as if it were a method of critter
	$critter->{ tumble } = $critter->{ taxis }->tumble();
	for my $i ( 0 .. 1 )
	{
		if ( $preference->[ $i ] > 0 )
		{
			$critter->{ tumble } /= ( abs $preference->[ $i ] )
				if $new_values[ $i ] - $critter->{ last_value }[ $i ] > 0;
		}
		else
		{
			$critter->{ tumble } /= ( abs $preference->[ $i ] )
				if $new_values[ $i ] - $critter->{ last_value }[ $i ] < 0;
		}
	}
	$critter->{ last_value } = [ @new_values ];
	if ( rand( 1 ) < $critter->{ tumble } )
	{
		my $rotation = rand(  PI / 2 );
		$rotation = int rand ( 2 ) ? $rotation : - $rotation;
		$critter->{ direction } 
			= $critter->{ direction } + $rotation; 
	}
	$critter->set_orient();
	my $run_length = 
		rand( sqrt( $b{max_y}**2 + $b{max_x}**2 ) ) 
			* $critter->{ taxis }->speed();
	my $new_x = $x_pos + 
		int( $run_length * cos $critter->{ direction } );
	my $new_y = $y_pos + 
		int( $run_length * sin $critter->{ direction } );
	$new_x = $new_x >= $b{ max_x } ? $b{ max_x } : $new_x;
	$new_y = $new_y >= $b{ max_y } ? $b{ max_y } : $new_y;
	$new_x = $new_x <= $b{ min_x } ? $b{ min_x } : $new_x;
	$new_y = $new_y <= $b{ min_y } ? $b{ min_y } : $new_y;
	$critter->set_pos( $new_x, $new_y );	
	return $critter;
}

sub set_orient
{
	my ( $critter, $orient ) = @_;
	unless ( $orient )
	{
		for ( $critter->{ direction } )
		{
			my $max = 2 * PI;
			my $rad = $_ -  $max * int( $_ / $max );
			$rad += 2 * PI if $rad < 0;
			( $rad < 1*PI/8  ) && do { $orient = 'e';  last };
			( $rad < 3*PI/8  ) && do { $orient = 'se'; last };
			( $rad < 5*PI/8  ) && do { $orient = 's';  last };
			( $rad < 7*PI/8  ) && do { $orient = 'sw'; last };
			( $rad < 9*PI/8  ) && do { $orient = 'w';  last };
			( $rad < 11*PI/8 ) && do { $orient = 'nw'; last };
			( $rad < 13*PI/8 ) && do { $orient = 'n';  last };
			( $rad < 15*PI/8 ) && do { $orient = 'ne'; last };
			$orient = 'e';
		}
	}
	$critter->{ orient } = $orient;
	return $critter;
}

sub get_orient
{
	my ( $critter ) = @_;
	return $critter->{ orient };
}

sub set_id
{
	my ( $critter, $value ) = @_;
	return $critter->{ id } = $value;	
}

sub get_id
{
	my ( $critter ) = @_;
	return $critter->{ id };
}

sub set_pos
{
	my ( $critter, $x, $y ) = @_;
	$critter->{ pos } = [ $x, $y ];
	return @{ $critter->{ pos } };
}

sub get_pos
{
	my ( $critter ) = @_;
	return @{ $critter->{ pos } };	
}

1;

__END__

=head1 NAME

Tk::Taxis::Critter - Perl extension for simulating critters

=head1 SYNOPSIS

  use Tk::Taxis::Critter;
  my $critter = Tk::Taxis::Critter->new( -taxis => $taxis );
  $critter->randomise();
  $critter->move();

=head1 ABSTRACT

Simulates critters in a taxis object

=head1 DESCRIPTION

This module is used by the C<Tk:::Taxis> class to implement the critter objects
in the taxis simulation. Classes using it require the same interface as 
C<Tk::Taxis> to work, namely one supporting C<width>, C<height>, C<image_width>,
C<image_height>, C<tumble>, C<preference>, C<calculation> and C<speed> methods.

=head1 METHODS

=over 4

=item * C<new( -taxis =E<gt> $taxis )>

Generates a new C<Tk::Taxis::Critter> object. Must be passed the C<-taxis> 
option and object. This object should be a C<Tk::Taxis> object or one 
implementing the methods C<width>, C<height>, C<image_width>, C<image_height>, 
C<tumble>, C<preference>, C<speed> and C<calculation>. The module will 
C<croak> unless it receives this object in its constructor's arguments.

=item * C<randomise>

Randomises the positions of the critters.

=item * C<move>

Moves each critter through one cycle of run-and-tumble.

=item * C<get_pos> and C<set_pos>

Gets the position of the critter. Returns a two item list of x, y coordinates. 
C<set_pos> sets the critters x, y coordinates, and expects a two item list.

=item * C<get_orient> and C<set_orient>

Gets the orientation of the critter: returns a string: either 'n', 'ne', 'e',
'se', 's', 'sw', 'w', or 'nw'. The C<set_orient> method is called with no 
argument: the orientation will be set automatically from internal data.

=item * C<get_id> and C<set_id>

Gets or sets the canvas ID of the critter. Returns this integer.

=item * C<get_boundries>

Gets a hash of numbers describing the area in which the critters may move. The
keys are C<min_x>, C<max_x>, C<min_y>, C<max_y>, C<width> and C<height>. 
The width and height are the physical dimensions of the taxis canvas (as 
specified by the object passed to the constructor), the min and max values take 
into account the size of the critters' images: C<min_x> will be 5px if the 
critter images are 10px wide, since objects cannot be squashed any closer to the
 edges of the canvas than this.

=back

=head1 SEE ALSO

L<Tk::Taxis>

=head1 AUTHOR

Steve Cook, E<lt>steve@steve.gb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Steve Cook

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
