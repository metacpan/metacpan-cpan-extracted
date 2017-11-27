
use strict;
use warnings;

package WWW::Shopify::Liquid::Pipeline;
use Scalar::Util qw(weaken blessed looks_like_number);
sub register_tag { }
sub register_operator {
	die new WWW::Shopify::Liquid::Exception("Cannot have a unary operator, that has infix notation.") if $_[1]->arity eq "unary" && $_[1]->fixness eq "infix";
}
sub register_filter { }
sub deregister_operator { }
sub deregister_tag { }
sub deregister_filter { }
sub strict { $_[0]->{strict} = $_[1] if defined $_[1]; return $_[0]->{strict}; }
sub file_context { $_[0]->{file_context} = $_[1] if @_ > 1; return $_[0]->{file_context}; }
sub parent { 
	if (defined $_[1]) {
		$_[0]->{parent} = $_[1];
		weaken($_[0]->{parent});
	}
	return $_[0]->{parent};
}

sub is_processed { 
	return !ref($_[1]) ||
		(ref($_[1]) eq "ARRAY" && int(grep { !$_[0]->is_processed($_) } @{$_[1]}) == 0) ||
		(ref($_[1]) eq "HASH" && int(grep { !$_[0]->is_processed($_[1]->{$_}) } keys(%{$_[1]})) == 0) || 
		(blessed($_[1]) && ref($_[1]) !~ m/^WWW::Shopify::Liquid/ && !$_[1]->isa('WWW::Shopify::Liquid::Element'));
}

# If static is true, we do not create new indices, we return null.
sub variable_reference {
	my ($self, $hash, $indices, $static) = @_;
	
	if (blessed($indices) && $indices->isa('WWW::Shopify::Liquid::Token::Variable')) {
		$indices = [map { $_->{core} } @{$indices->{core}}];
	}
	
	my @vars = @$indices;
	my $inner_hash = $hash;
	for (0..$#vars-1) {
		if (looks_like_number($vars[$_]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
			if (!defined $inner_hash->[$vars[$_]]) {
				return () if $static;
				$inner_hash->[$vars[$_]] = {};
			}
			$inner_hash = $inner_hash->[$vars[$_]];
		} else {
			if (blessed($inner_hash) && $inner_hash->isa('WWW::Shopify::Liquid::Resolver')) {
				$inner_hash = $inner_hash->resolver->($inner_hash, $hash, $vars[$_]);
			} else {
				if (!exists $inner_hash->{$vars[$_]}) {
					return () if $static;
					$inner_hash->{$vars[$_]} = {};
				}
				$inner_hash = $inner_hash->{$vars[$_]};
			}
		}
	}
	if (looks_like_number($vars[-1]) && ref($inner_hash) && ref($inner_hash) eq "ARRAY") {
		return (\$inner_hash->[$vars[-1]], $inner_hash, $vars[-1]) if int(@$inner_hash) > $vars[-1] || !$static;
	} else {
		return (\$inner_hash->{$vars[-1]}, $inner_hash, $vars[-1]) if exists $inner_hash->{$vars[-1]} || !$static;
	}
	return ();
}

sub make_method_calls { $_[0]->{make_method_calls} = $_[1] if @_ > 1; return $_[0]->{make_method_calls}; }

1;