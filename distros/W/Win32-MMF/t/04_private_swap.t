use strict;
use warnings;
use Test::More tests => 1;
use Win32::MMF::Shareable { namespace=>"MySwapfile", swapfile=>"C:/private.swp", size=>1024*1024 };

is( (-s "C:/private.swp"), 1024*1024, "Private swap OK" );

