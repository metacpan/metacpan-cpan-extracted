
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::Eval;
use base 'WWW::Shopify::Liquid::Filter';

sub min_arguments { return 0; }
sub max_arguments { return 0; }


sub render {
	my ($self, $renderer, $hash) = @_;	
	my $operand = !$self->is_processed($self->{operand}) ? $self->{operand}->render($renderer, $hash) : $self->{operand};
	
	my $ast = $renderer->parent->parse_text($operand);
	my $clone_hash = $renderer->clone_hash;
	$renderer->clone_hash(0);
	my ($result) = $renderer->render($hash, $ast);
	$renderer->clone_hash($clone_hash);
	return $result;
}

1;
