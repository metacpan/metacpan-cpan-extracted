#!/usr/bin/perl
use strict;
use warnings;

# So sick of crap.
package WWW::Shopify::Liquid::Operator::Regex;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '=~'; }
sub priority { return 5; }
sub operate { 
	my ($self, $hash, $action, $op1, $op2) = @_;
	return undef unless defined $op1 && defined $op2;
	my @groups = ($op1 =~ m/$op2/);
	return undef if (int(@groups) == 0);
	return \@groups;
}

1;