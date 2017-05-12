package Tree::Navigator::View;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

sub render {
  my ($self, $node, %args) = @_;

  return [500, ['Content-type' => 'text/plain'], 
               ["attempt to render() from abstract class View.pm"]];
}

1; # end of package Tree::Navigator::View
