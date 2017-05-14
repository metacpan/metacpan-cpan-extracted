
=head1 Name

  VPTK_Geometry.pm - abstract editor widget's geometry class

=cut

package vptk_w::VPTK_Geometry;
use strict;

# Constructor - just create empty instance
sub new {
  my $class = shift;
  die "ERROR: missing class name"
    unless $class;
  die "ERROR: uneven arguments number (@_)"
    if scalar(@_)%2;
  return bless {@_} => $class;
}

# Putter/Getter method
sub GeometryData {
  my $this = shift;

  die "ERROR: missing instance"
    unless $this;
  die "ERROR: uneven arguments number (@_)"
    if scalar(@_)%2;
  if(@_) { %$this = @_; }
  else { return %$this; }
}

# Main method - drawing
sub ApplyGeometry {
  my $this = shift;

  die "ERROR: missing instance"
    unless $this;
  my $widget = shift;
  die "ERROR: missing widget"
    unless $widget;
  my $geometry_manager = $this->{'geometry'};
  # we should separate geometry manager name from it's parameters:
  my %geometry_data = %$this;
  delete $geometry_data{'geometry'};
  # now the hash contain only geometry manager parameters
  if($geometry_manager eq 'pack')     {  $widget->pack(%geometry_data); }
  elsif($geometry_manager eq 'place') {  $widget->place(%geometry_data); }
  elsif($geometry_manager eq 'grid')  {  $widget->grid(%geometry_data); }
  else {
    die "ERROR: unknown geometry manager ($geometry_manager)";
  }
}

1;#)
