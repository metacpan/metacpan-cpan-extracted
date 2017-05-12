#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

# Designed to verify objects for possible malicious uses.
package WWW::Shopify::Liquid::Security;
sub new { 
	my ($package) = @_;
	$package = 'WWW::Shopify::Liquid::Security::None' if $package eq 'WWW::Shopify::Liquid::Security';
	return bless {  }, $package;
}
sub verify { }
sub check_tag { }
sub check_operate { }

package WWW::Shopify::Liquid::Exception::Security;
use base 'WWW::Shopify::Liquid::Exception';

# No checking.
package WWW::Shopify::Liquid::Security::None;
use base 'WWW::Shopify::Liquid::Security';

package WWW::Shopify::Liquid::Security::Strict;
use base 'WWW::Shopify::Liquid::Security';
use Scalar::Util qw(looks_like_number);

sub check_tag {
	my ($self, $ast, @rest) = @_;
}

sub check_operate {
	my ($self, $ast, @rest) = @_;
	my %types = (
		'WWW::Shopify::Liquid::Operator::Array' => sub {
			my ($self, $hash, $type, $op1, $op2) = @_;
			die new WWW::Shopify::Liquid::Exception::Security($self, "Array generation operands are too large.") if looks_like_number($op2) && looks_like_number($op1) && ($op2 - $op1) > 1000;
		}
	);
	
	$types{ref($ast)}->($ast, @rest) if ref($ast) && $types{ref($ast)};
}

1;
