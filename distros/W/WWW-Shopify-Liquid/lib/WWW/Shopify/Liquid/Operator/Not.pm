#!/usr/bin/perl

use strict;
use warnings;

# Used in our AST to keep things simple; represents the concatenation of text and other stuff.
# Making this a many-dimensional operator, so that we avoid going too far down the callstack rabbithole.
package WWW::Shopify::Liquid::Operator::Not;
use base 'WWW::Shopify::Liquid::Operator';
use Scalar::Util qw(blessed);
sub symbol { return "!"; }
sub arity { return "unary"; }
sub fixness { return "prefix"; }
sub operate {
	my ($self, $hash, $action, $op) = @_;
	return !$op;
}

1;