package Fitnesse::Slim::Test::ZeroArityConstructor;

use strict;
use warnings;

our $CONSTRUCTIONS = 0;

sub slim_constructor_signature { { parameters => [] } }
sub new { ++$CONSTRUCTIONS; bless {}, $_[0] }
sub ready { 'ready' }

1;
