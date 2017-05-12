#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Operator::Array;
use base 'WWW::Shopify::Liquid::Operator';
use List::Util qw(first);
use Scalar::Util qw(looks_like_number);
sub symbol { return '..'; }
sub priority { return 7; }
sub operate { 
	my ($self, $hash, $type, $op1, $op2) = @_;
	die new WWW::Shopify::Liquid::Exception::Renderer::Arguments($self, "Both operands must be integers.") unless defined $op1 && defined $op2 && looks_like_number($op1) && looks_like_number($op2);
	return [$op1..$op2];
}
sub requires_grouping { return 1; }

1;