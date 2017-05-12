# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TipJar-Template-fill.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict; 

use Test;
BEGIN { plan tests => 5 };
use TipJar::Template::fill;
ok(1); # If we made it this far, we're ok.

#########################


# don't believe the h2xs-generated comments -- test::more
# is NOT used here -- maybe I set -b too low

our %fill;
$fill{foo} = 'bar';
ok('bar' , fill('[foo]'));# 'interpolation from default hash');


my %myfill;
$myfill{foo} = 'bar';
ok('bar',fill('[foo]',\%myfill));# ,'interpolation from named hash');

my %subvars;
use TipJar::Template::fill
	fill => 'subst',
	hashref => \%subvars,
	_args => 1,
	regex => 'X(.*?)Y';

my $template = 'fooXfooY barXbarY bazXbarY';

@subvars{qw/foo bar baz/} = (1,27,82);

ok(subst($template), 'foo1 bar27 baz27');# 'a whole bunch of things');

$subst_args{regex} = qr/\b(\w+)X/;
ok(subst($template), '1fooY 27barY 82barY');#, 'on-fly regex change');

	
