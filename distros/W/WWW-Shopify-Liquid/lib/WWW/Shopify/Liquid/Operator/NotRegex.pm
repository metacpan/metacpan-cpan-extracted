#!/usr/bin/perl
use strict;
use warnings;

# So sick of crap.
package WWW::Shopify::Liquid::Operator::NotRegex;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '!~'; }
sub priority { return 5; }
sub operate { 
	my ($self, $hash, $action, $op1, $op2) = @_;
	return 1 if !defined $op1 && defined $op2;
	return undef unless defined $op1 && defined $op2;
	my @groups = ($op1 !~ m/$op2/);
	return undef if (int(@groups) == 0);
	return \@groups;
}

1;