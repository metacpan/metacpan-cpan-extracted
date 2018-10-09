use strict;
use warnings;

package WWW::Shopify::Liquid::Dialect::Web::Filter::Highlight;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 1; }
sub max_arguments { return 1; }
sub operate { 
	my ($self, $hash, $operand, $terms) = @_;
	my $replacement = "(" . join("|", map { quotemeta($_) } (ref($terms) && ref($terms) eq 'ARRAY' ? @$terms : $terms)) . ")";
	$operand =~ s/$replacement/<strong>$1<\/strong>/ig;
	return $operand;
}

1;