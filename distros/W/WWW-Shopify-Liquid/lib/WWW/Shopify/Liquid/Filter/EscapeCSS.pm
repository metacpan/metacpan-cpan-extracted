use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::EscapeCSS;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 0; }
sub max_arguments { return 0; }
sub operate { 
	my ($self, $hash, $operand) = @_;
	return undef unless $operand;
	$operand =~ s/<\s*\/\s*style\s*>//g;
	return $operand;
}

1;