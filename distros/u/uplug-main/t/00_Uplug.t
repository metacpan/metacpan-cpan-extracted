#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';


use Test::More;

use Uplug;
ok(1, 'load Uplug module');    # If we made it this far, we're ok.

done_testing;

