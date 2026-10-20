package Fitnesse::Slim::Test::MethodNameResolution::NewLibrary;

use strict;
use warnings;

sub new { bless {}, $_[0] }
sub get_http_status { 'newest library HTTP status' }

1;
