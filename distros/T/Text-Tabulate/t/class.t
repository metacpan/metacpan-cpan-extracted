#!perl

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;

use Test::More tests => 7;

# Tests
BEGIN { use_ok('Text::Tabulate'); }

# Load the data.
#$/ = '';	# paragraph mode.
#my @data = split(/\n/, <DATA>);
##ok($#data, 'data loaded');

# Test the routine.

my $tab;
ok($tab = new Text::Tabulate(), "constructor");

# Error in constructor.
$tab = '';
eval { $tab = new Text::Tabulate(
	'tab'=>'x',
	'rabbit'=>'white'
); };
ok(!$tab, "constructor with non-option");

$tab = '';
eval { $tab = new Text::Tabulate(
	'tab'=>'x',
	'rabbit'
); };

ok(!$tab, "constructor with odd number of arguments");

# Constructor with options.
ok($tab = new Text::Tabulate('-tab'=>'x'), "constructor with options");

ok($tab->configure('tab' => 'y'), "configure");
my $err = eval { $tab->configure('tabx' => 'y'); };
ok(!$err, "configure with non-option");

exit;

