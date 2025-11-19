use 5.010001;
use strict;
use warnings;

package Types::Capabilities::CoercedValue::STACK;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002001';

use parent 'Types::Capabilities::CoercedValue::ARRAYREF';

sub new {
	my $class = shift;
	my $new = bless [ @{+shift} ], $class;
	return $new;
}

1;

__END__
