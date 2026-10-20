package Fitnesse::Slim::Test::UnannotatedConstructor;

use strict;
use warnings;

sub new { bless { value => $_[1] }, $_[0] }
sub value { $_[0]{value} }

1;
