package Video::PlaybackMachine::FillProducer::TextFrame::TextTable;

our $VERSION = '0.09'; # VERSION

use Video::PlaybackMachine::FillProducer::TextFrame::Row;

use Moo;

has 'image' => ( 'is' => 'ro' );

has 'border' => ( 'is' => 'ro' );

has 'rows' => ( 'is' => 'ro', default => sub { return [] } );

has 'height' => ( 'is' => 'rw', 'default' => 0 );

has 'width' => ( 'is' => 'rw', 'default' => 0 );

sub add_row {
  my $self = shift;
  my (@columns) = @_;

  my $row = 
    Video::PlaybackMachine::FillProducer::TextFrame::Row->new(
							      $self->image(),
							      $self->border(),
							      @columns);
  
  # Return undef if we're too long (vertically) for the screen
  my $new_height = $self->height() + $row->get_height() + $self->border();
  $new_height > $self->image()->get_height()
    and return;
  $self->height( $new_height );

  # Update maximum width
  $self->width( $row->get_width() )
    if $row->get_width() > $self->width();

  # Store the row
  push(@{ $self->rows() }, $row);

  return 1;
}

sub get_start_ycoord {
  my $self = shift;

  return int(($self->image()->get_height() - $self->height()) / 2);
}

sub get_start_xcoord {
  my $self = shift;

  return int(($self->image()->get_width() - $self->width()) / 2);

}

sub draw {
  my $self = shift;

  my $x = $self->get_start_xcoord();
  my $y = $self->get_start_ycoord();
  foreach my $row (@{ $self->rows() }) {
    $row->draw($x, $y);
    $y += $row->get_height();
  }
}

no Moo;

1;
