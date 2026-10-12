package singleton;

=head1 NAME

signleton - class realised singleton constructor

=cut

=head1 SYNOPSIS

Usage:

	use singleton;
	my $object = singleton new Class;

=head1 VERSION

0.2

=head1 AUTHOR

Developed by Ivan Trunaev.

Contacts <ivan@trunaev.ru>

=cut


use strict;
use warnings;
use 5.022;

our $VERSION = '0.2';

sub main::singleton {
	my $obj   = shift;
	my $class = ref $obj or return;
	state $s = {};
	$s->{$class} //= $obj;
	return $s->{$class};
}

1;
