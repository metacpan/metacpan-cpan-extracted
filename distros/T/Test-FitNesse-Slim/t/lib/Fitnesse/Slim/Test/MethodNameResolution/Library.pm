package Fitnesse::Slim::Test::MethodNameResolution::Library;

use strict;
use warnings;

sub new { bless {}, $_[0] }
sub get_http_status { 'library HTTP status' }
sub missing { 'library-only method' }

1;
