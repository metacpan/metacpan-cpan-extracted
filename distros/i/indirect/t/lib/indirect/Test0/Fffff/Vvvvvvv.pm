package indirect::Test0::Fffff::Vvvvvvv;

use warnings;
use strict;

my $f;
sub import {
	my($class, %args) = @_;
	$f = bless({ x => $args{x}, y => $args{y} }, $class);
}

1;
