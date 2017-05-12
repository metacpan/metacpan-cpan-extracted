use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::EscapeHTML;
use base 'WWW::Shopify::Liquid::Filter';

use HTML::Entities qw(encode_entities);

sub min_arguments { return 0; }
sub max_arguments { return 0; }
sub operate { 
	my ($self, $hash, $operand) = @_;
	return undef unless $operand;
	return encode_entities($operand);
}

1;