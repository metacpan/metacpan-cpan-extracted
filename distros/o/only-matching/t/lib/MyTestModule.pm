package t::lib::MyTestModule;

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub import {
	my $class = shift;
	$main::LOADED += 10;
	$main::LOADED += scalar(@_);
	return 1;
}

1;
