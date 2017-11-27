#!/usr/bin/perl
use strict;
use warnings;


package WWW::Shopify::Liquid::Operator::Regex;
use base 'WWW::Shopify::Liquid::Operator';
sub symbol { return '=~'; }
sub priority { return 5; }

# Ensures that regexes can't be used maliciously.
no re 'eval';
use re::engine::RE2 (-strict => 1, -max_mem => (2**24));

sub operate { 
	my ($self, $hash, $action, $op1, $op2) = @_;
	return undef unless defined $op1 && defined $op2;
	my @groups = ($op1 =~ m/$op2/);
	return undef if (int(@groups) == 0);
	return \@groups;
}

1;