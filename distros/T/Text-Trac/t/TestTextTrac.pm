package t::TestTextTrac;
use strict;
use warnings;

use Test::Base -Base;
use Text::Trac;

our @EXPORT = qw( run_tests );

sub run_tests {
	delimiters('###');
	filters { input => 'parse', expected => 'chomp' };
	run_is 'input' => 'expected';
}

package t::TestTextTrac::Filter;
use strict;
use warnings;
use Test::Base::Filter -Base;

my $p = Text::Trac->new( trac_url => 'http://trac.mizzy.org/public/' );

sub parse {
	$p->parse(@_);
	return $p->html;
}

1;
