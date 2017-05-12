package constant::Atom::Strict;
$constant::Atom::Strict::VERSION = '0.10';
use 5.006;
use strict;
use warnings;

use parent 'constant::Atom';
use Carp;


sub tostring {
	my($self) = @_;
	my $class = ref($self);
	croak "Can't cast $class object '".$$self."' into a string.  Use the 'fullname' method for a string representation of this object";	
}

1;
