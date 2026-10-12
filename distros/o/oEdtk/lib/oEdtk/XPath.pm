package oEdtk::XPath;

use strict;
use warnings;

use base 'XML::XPath';
our $VERSION		= 2.1109;

sub findTextValue {
	my ($self, $path, $context) = @_;
	my $val = $self->findvalue($path, $context);
	return "$val";
}

1;
