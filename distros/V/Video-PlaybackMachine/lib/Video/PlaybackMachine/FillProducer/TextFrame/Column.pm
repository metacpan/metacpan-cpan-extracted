package Video::PlaybackMachine::FillProducer::TextFrame::Column;

our $VERSION = '0.09'; # VERSION

use Moo;

has 'image' => ( 'is' => 'ro' );

has 'text' => ( 'is' => 'ro' );

# TODO: Make 'wrap_width' a parameter to 'new'

sub draw {
  my $self = shift;
  my ($x, $y, $width) = @_;

  my $y_curr = $y;
  foreach my $line ( $self->get_lines($width) ) {
    chomp($line);
    my ($width, $height) = $self->{'image'}->get_text_size($line);
    $self->{'image'}->draw_text($x, $y_curr, $line);
    $y_curr += $height;
  }
}

sub get_dimensions {
  my $self = shift;
  my ($wrap_width) = @_;
  my ($width, $height) = $self->_wrap_lines($wrap_width);
  return $width, $height;
}


sub get_lines {
  my $self = shift;
  my ($wrap_width) = @_;
  my (undef, undef, @lines) = $self->_wrap_lines($wrap_width);
  return @lines;
}


sub _wrap_lines {
  my $self = shift;
  my ($wrap_width) = @_;


  my @lines = ();
  my $total_height = 0;
  my $max_width = 0;

  foreach my $text ( split(/\n/, $self->text() ) ) {

    my @atoms = split(/(\s+)/, $text);
    
    my $curr_line = shift @atoms;
    defined $curr_line or $curr_line = '';
    my ($line_width, $line_height) = $self->{'image'}->get_text_size($curr_line);
    $total_height += $line_height;

    
    foreach my $atom (@atoms) {
      my ($width, $height) = $self->{'image'}->get_text_size($atom);

      # If the current atom makes the line wrap, do it
      if ( ( $line_width + $width ) > $wrap_width ) {
	push(@lines, $curr_line);
	$curr_line = $atom;
	$max_width = $line_width if $line_width > $max_width;
	$line_width = $width;
	$total_height += $height;
      }
      # Otherwise, append atom to current line
      else {
	$curr_line .= $atom;
	$line_width += $width;
      }
    }
    push(@lines, $curr_line);
    $max_width = $line_width if $line_width > $max_width;
  }

  return $max_width, $total_height, @lines;
  
}

no Moo;

1;