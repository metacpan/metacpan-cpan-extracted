#!/usr/bin/perl

use Test::Inter;
$o = new Test::Inter 'version', 'start' => 1;

use Cwd;
my($valid,$vers);

if ($ENV{'RELEASE_TESTING'}) {
   my $dir = getcwd();
   if ($dir =~ m,(?:/|^)Test\-Inter\-(\d+\.\d+),) {
      $vers  = $1;
      $valid = 1;
   } else {
      $vers  = 0;
      $valid = 0;
   }
} else {
   $vers  = $Test::Inter::VERSION;
   $valid = 1;
}

$o->ok($valid,             "Valid directory");
$o->ok($vers, $o->version, "Valid version");

$o->done_testing();

