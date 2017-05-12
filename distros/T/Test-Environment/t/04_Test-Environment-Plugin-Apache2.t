#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 6;

use FindBin '$Bin';

use Test::Differences;
#use Test::Exception;
use English '-no_match_vars';

use File::Spec;

use lib File::Spec->catdir($Bin, 'lib-no-Apache2');

my $original_execute;
BEGIN {
	use_ok 'Test::Environment', qw{
		Apache2
	};
}


exit main();

sub main {
	use_ok 'Apache2::RequestRec';
	use_ok 'Apache2::Filter';
	use_ok 'Apache2::Log';
	use_ok 'Apache2::Request';
	
	eval 'use Apache2::NonExisting';
	is($@, '', 'check loading libs from t/lib-no-Apache2');
	
	return 0;
}
