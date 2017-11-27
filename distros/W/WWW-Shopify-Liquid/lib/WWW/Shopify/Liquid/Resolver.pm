
use strict;
use warnings;

# Allows for contextual resolution of variables.
package WWW::Shopify::Liquid::Resolver;
sub resolver { return $_[0]->{resolver}; }
sub new {
	my ($package, $resolver) = @_;
	return bless { resolver => $resolver }, $package;
}

1;