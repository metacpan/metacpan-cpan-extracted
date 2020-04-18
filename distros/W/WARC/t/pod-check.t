# Tests for WARC library POD					# -*- CPerl -*-

use strict;
use warnings;

use File::Find;
use Test::More;

BEGIN { my $have_pod_checker = 0;
	eval {require Pod::Checker; $have_pod_checker = 1;};
	plan skip_all => 'Need Pod::Checker for checking POD syntax'
	  unless $have_pod_checker;
	plan skip_all =>
	  'Need at least Pod::Checker 1.43; have '.$Pod::Checker::VERSION
	    unless eval {Pod::Checker->VERSION('1.43')} }

use Pod::Checker;

my @PODS = ();
find({wanted => sub { push @PODS, $File::Find::name
			if -f $File::Find::name and m/(?:pm|pod)$/ },
      no_chdir => 1}, 'lib');

plan tests => scalar @PODS;

foreach my $pod_file (@PODS) {
  my $checker = new Pod::Checker -warnings => 2;
  $checker->parse_from_file($pod_file, '>&STDERR');
  ok($checker->name
     && $checker->num_errors == 0 && $checker->num_warnings == 0,
     'POD text in '.$pod_file.' for '.($checker->name or '???'))
    or diag("Error reported by Pod::Checker $Pod::Checker::VERSION");
}
