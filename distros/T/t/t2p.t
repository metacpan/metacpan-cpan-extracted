use strict;
use warnings;

use T2 Basic => [qw/ok done_testing/];
use T2::P 'SRand';
use T2::P '+Data::Dumper';

t2 ok => ($INC{'Test2/Plugin/SRand.pm'}, "Loaded SRand plugin");

t2 ok => (t2p->can('Dumper'), "Imports go to t2p");

t2->done_testing;
