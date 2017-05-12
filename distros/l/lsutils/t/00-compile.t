use Test::Simple 'no_plan';
use strict;
use lib './lib';
require 't/testing.pl';
use Cwd;
use vars qw($_part $cwd);
use LEOCHARRE::Dir::Lsutils ':all';
$cwd = cwd();

ok( 1, 'compiled' );

ok setup();
ok -d 't/tmp';
ok cleanup();
ok ! -d 't/tmp';















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


