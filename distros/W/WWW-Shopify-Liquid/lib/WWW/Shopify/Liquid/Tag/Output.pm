
package WWW::Shopify::Liquid::Tag::Output;
use base 'WWW::Shopify::Liquid::Tag::Free';

use Scalar::Util qw(blessed);
sub max_arguments { return 1; }
sub abstract { return 0; }

sub new { 
	my ($package, $line, $arguments) = @_;
	my $self = { arguments => $arguments, line => $line };
	return bless $self, $package;
}

sub operate {
	my ($self, $hash, $argument) = @_;
	return "$argument" if !ref($argument) || blessed($argument);
	return '';
	
}

1;