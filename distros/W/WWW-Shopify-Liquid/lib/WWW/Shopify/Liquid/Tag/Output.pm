
package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';

sub max_arguments { return 1; }
sub abstract { return 0; }

sub new { 
	my ($package, $line, $arguments) = @_;
	my $self = { arguments => $arguments, line => $line };
	return bless $self, $package;
}

sub operate {
	my ($self, $hash, $argument) = @_;
	return $argument;
}

1;