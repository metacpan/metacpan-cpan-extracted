package Text::Trac::Macro::HelloWorld;

use strict;
use warnings;

our $VERSION = '0.20';

sub process {
	my ( $class, $c, @args ) = @_;
	return 'Hello World, args = ' . join ', ', @args;
}

1;
