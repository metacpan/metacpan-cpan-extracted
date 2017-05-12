package Video::PlaybackMachine::FillProducer::TextFrame::Row;

our $VERSION = '0.09'; # VERSION

use Moo;

use Video::PlaybackMachine::FillProducer::TextFrame::Column;

has 'image' => ( is => 'ro' );
has 'border' => ( is => 'ro' );
has 'columns' => ( is => 'ro' );
has 'dimensions' => ( is => 'lazy' );

sub BUILDARGS {
	my ($type, @args) = @_;
	my ($image, $border, @columns) = @args;
	
	return {
	     image => $image,
	     border => $border,
	     columns => [ 
			 map { Video::PlaybackMachine::FillProducer::TextFrame::Column->new(
			 	image => $image, 
			 	text => $_
			 ); } @columns
			],
	    };
	
}

sub _build_dimensions {
	my $self = shift;
	
    my $total_width = 0;
    my $max_height = 0;

    foreach my $column ( $self->get_columns() ) {
      my ($width, $height) = $column->get_dimensions( $self->image()->get_width() - $total_width );
      $total_width += ($width + $self->border());
      $max_height = $height if $height > $max_height;
    }

	return [$total_width - $self->{'border'}, $max_height];
}

sub get_columns {
	my $self = shift;

  return @{ $self->columns() };
}

sub get_dimensions {
  my $self = shift;

  return @{ $self->dimensions() };

}

sub get_width {
  my $self = shift;
  my ($width, undef) = $self->get_dimensions();
  return $width;
}

sub get_height {
  my $self = shift;
  my (undef, $height) = $self->get_dimensions();
  return $height;
}

sub draw {
  my $self = shift;
  my ($x, $y) = @_;

  my $currx = $x;
  foreach my $column ( $self->get_columns() ) {
    my $width_left = $self->image()->get_width() - $currx;
    $column->draw($currx, $y,  $width_left);
    $currx += ($column->get_dimensions($width_left))[0];
    $currx += $self->border();
  }
  return 1;
}

no Moo;

1;

