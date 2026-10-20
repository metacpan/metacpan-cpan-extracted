package Fitnesse::Slim::Test::Library::SystemUnderTestFallback;

use strict;
use warnings;

sub new { bless {}, $_[0] }
sub sut_only { 'library' }
sub library_only { 'library' }

1;
