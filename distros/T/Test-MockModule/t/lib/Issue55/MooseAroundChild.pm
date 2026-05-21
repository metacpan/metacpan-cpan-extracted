package Issue55::MooseAroundChild;
use Moose;
extends 'Issue55::MooseAroundParent';
around foo => sub { 2 };
1;
