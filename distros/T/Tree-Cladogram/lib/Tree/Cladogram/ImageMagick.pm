package Tree::Cladogram::ImageMagick;

use parent 'Tree::Cladogram';

use Image::Magick;

use Moo;

use Types::Standard qw/Int/;

has title_x =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has title_y =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '1.04';

# ------------------------------------------------

sub _calculate_leaf_name_bounds
{
	my($self)			= @_;
	my($image)			= Image::Magick -> new(size => '1 x 1');
	my($result)			= $image -> Read('canvas:white');
	my($leaf_font_size)	= $self -> leaf_font_size;
	my($x_step)			= $self -> x_step;

	my($attributes);
	my(@metrics);
	my($x);
	my($y);

	$self -> root -> walk_down
	({
		callback =>
		sub
		{
			my($node)		= @_;
			my(@metrics)	= $image -> QueryFontMetrics
								(
									font		=> $self -> leaf_font_file,
									pointsize	=> $self -> leaf_font_size,
									text		=> $node -> name,
									x			=> 0,
									y			=> 0,
								);
			$attributes				= $node -> attributes;
			$x						= $$attributes{x} + $x_step + 4;
			$y						= $$attributes{y} + int($leaf_font_size / 2);
			$$attributes{bounds}	= [$x, $y, $x + $metrics[11] + 1, $y + $metrics[5]];

			$node -> attributes($attributes);

			return 1; # Keep walking.
		},
		_depth	=> 0,
	});

} # End of _calculate_leaf_name_bounds.

# ------------------------------------------------

sub _calculate_title_metrics
{
	my($self, $image, $maximum_x, $maximum_y) = @_;
	my(@metrics) = $image -> QueryFontMetrics
					(
						font		=> $self -> title_font_file,
						pointsize	=> $self -> title_font_size,
						text		=> $self -> title,
						x			=> 0,
						y			=> 0,
					);

	$self -> title_width($metrics[11] + 1);
	$self -> title_x(int( ($maximum_x - $metrics[11]) / 2) );
	$self -> title_y($maximum_y - $self -> leaf_font_size);

} # End of _calculate_title_metrics.

# ------------------------------------------------

sub create_image
{
	my($self, $maximum_x, $maximum_y) = @_;
	my($image) = Image::Magick -> new(size => "$maximum_x x $maximum_y");

	$image -> Read('canvas:white');
	$self -> _calculate_title_metrics($image, $maximum_x, $maximum_y) if (length($self -> title) );

	if ($self -> draw_frame)
	{
		# The advantage of Draw over Border is that the former
		# draws /on/ the image, thereby not making it larger.

		my(@x) = (0, ($maximum_x - 1), ($maximum_x - 1), 0);
		my(@y) = (0, 0, ($maximum_y - 1), ($maximum_y - 1) );

		$image -> Draw
			(
				fill		=> 'none',
				primitive	=> 'polyline',
				points		=> "$x[0],$y[0] $x[1],$y[1] $x[2],$y[2] $x[3],$y[3] $x[0],$y[0]",
				stroke		=> $self -> frame_color,
				strokewidth	=> 1,
			);
	}

	return $image;

} # End of create_image.

# ------------------------------------------------

sub draw_horizontal_branch
{
	my($self, $image, $middle_attributes, $daughter_attributes, $final_offset) = @_;
	my($branch_width)	= $self -> branch_width - 1;
	my($x_step)			= $self -> x_step;
	my(@x)				= ($$middle_attributes{x}, $$daughter_attributes{x} + $x_step + $final_offset);
	my(@y)				= ($$daughter_attributes{y}, $$daughter_attributes{y} + $branch_width);
	my($result)			= $image -> Draw
							(
								fill		=> $self -> branch_color,
								method		=> 'replace',
								points		=> "$x[0],$y[0] $x[1],$y[1]",
								primitive	=> 'rectangle',
							);

} # End of draw_horizontal_branch.

# ------------------------------------------------

sub draw_leaf_name
{
	my($self, $image, $name, $daughter_attributes, $final_offset) = @_;

	if ( (length($name) > 0) && ($name !~ /^\d+$/) )
	{
		my($bounds)		= $$daughter_attributes{bounds};
		$$bounds[0]		+= $final_offset;
		$$bounds[2]		+= $final_offset;
		my($font_size)	= $self -> leaf_font_size;

		$image -> Annotate
		(
			antialias	=> 'false',
			font		=> $self -> leaf_font_file,
			gravity		=> 'forget',
			pointsize	=> $font_size,
			stroke		=> $self -> leaf_font_color,
			strokewidth	=> 1,
			text		=> $name,
			x			=> $$bounds[0],
			y			=> $$bounds[1],
		);

		if ($self -> debug)
		{
			my($fuchsia)	= 'fuchsia';
			my(@x)			= ($$bounds[0], $$bounds[2], $$bounds[2], $$bounds[0]);
			my(@y)			= ($$bounds[1], $$bounds[1], $$bounds[3], $$bounds[3]);
			@y				= map{$_ - $font_size} @y; # WTF?
			my($result)		= $image -> Draw
								(
									fill		=> 'none',
									points		=> "$x[0],$y[0] $x[1],$y[1] $x[2],$y[2] $x[3],$y[3] $x[0],$y[0]",
									primitive	=> 'polyline',
									stroke		=> $fuchsia,
									strokewidth	=> 1,
								);

			die $result if $result;
		}
	}

} # End of draw_leaf_name.

# ------------------------------------------------

sub draw_root_branch
{
	my($self, $image)			= @_;
	my($branch_width)			= $self -> branch_width - 1;
	my($attributes)				= $self -> root -> attributes;
	my(@daughters)				= $self -> root -> daughters;
	my($daughter_attributes)	= $daughters[0] -> attributes;
	my(@x)						= ($$daughter_attributes{x}, $self -> left_margin);
	my(@y)						= ($$daughter_attributes{y}, $$attributes{y} + $branch_width);
	my($result)					= $image -> Draw
									(
										fill		=> $self -> branch_color,
										method		=> 'replace',
										points		=> "$x[0],$y[0] $x[1],$y[1]",
										primitive	=> 'rectangle',
									);

} # End of draw_root_branch.

# ------------------------------------------------

sub draw_title
{
	my($self, $image, $maximum_x, $maximum_y) = @_;
	my($title) = $self -> title;

	if (length($title) > 0)
	{
		$image -> Annotate
		(
			antialias	=> 'false',
			font		=> $self -> title_font_file,
			gravity		=> 'forget',
			pointsize	=> $self -> title_font_size,
			stroke		=> $self -> title_font_color,
			strokewidth	=> 1,
			text		=> $title,
			x			=> $self -> title_x,
			y			=> $self -> title_y,
		);
	}

} # End of draw_title.

# ------------------------------------------------

sub draw_vertical_branch
{
	my($self, $image, $middle_attributes, $daughter_attributes) = @_;
	my($branch_width)	= $self -> branch_width - 1;
	my($x_step)			= $self -> x_step;
	my(@x)				= ($$middle_attributes{x}, $$middle_attributes{x} + $branch_width);
	my(@y)				= ($$middle_attributes{y}, $$daughter_attributes{y});
	my($result)			= $image -> Draw
							(
								fill		=> $self -> branch_color,
								method		=> 'replace',
								points		=> "$x[0],$y[0] $x[1],$y[1]",
								primitive	=> 'rectangle',
							);

} # End of draw_vertical_branch.

# ------------------------------------------------

sub write
{
	my($self, $image, $file_name) = @_;

	$image -> Write($file_name);
	$self -> log('Wrote ' . $file_name);

} # End of write.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Tree::Cladogram::ImageMagick> - Render a cladogram using Imager or Image::Magick

=head1 Synopsis

See L<Tree::Cladogram/Synopsis>.

=head1 Description

See L<Tree::Cladogram/Description>.

=head1 Distributions

See L<Tree::Cladogram/Distributions>.

=head1 Constructor and Initialization

See L<Tree::Cladogram/Constructor and Initialization>.

=head1 Methods

See L<Tree::Cladogram/Methods>.

=head1 FAQ

See L<Tree::Cladogram/FAQ>.

=head1 See Also

See L<Tree::Cladogram/See Also>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Tree-Cladogram>

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<https://github.com/ronsavage/Tree-Cladogram/issues>

=head1 Author

L<Tree::Cladogram> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

My homepage: L<http://savage.net.au/>

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
