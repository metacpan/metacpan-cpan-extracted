#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::NotEquals;
use base 'WWW::Shopify::Liquid::Operator';
use Scalar::Util qw(looks_like_number);
sub symbol { return ('!=', '<>'); }
sub priority { return 5; }
use Data::Compare;
sub operate { 
	my ($self, $hash, $action, $op1, $op2) = @_;
	return 0 if !defined $op1 && !defined $op2;
	return 1 if defined $op1 xor defined $op2;
	return $op1 != $op2 if (ref($op1) && ref($op2) && ref($op1) eq "DateTime" && ref($op2) eq "DateTime");
	return !Compare($op1, $op2) if (ref($op1) && ref($op2));
	my $episilon = 0.00000000001;
	return abs($op1 - $op2) > $episilon if looks_like_number($op1) && looks_like_number($op2);
	return ($op1 cmp $op2) != 0;
}
1;