package DBIx::dbMan::MemPool;

use strict;
use locale;
use POSIX;

our $VERSION = '0.04';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	return $obj;
}

sub set {
	my $obj = shift;
	my $name = shift;
	$obj->{$name} = shift;
}

sub get {
	my $obj = shift;
	my $name = shift;
	return undef unless exists $obj->{$name};
	return $obj->{$name};
}

sub register {
	my $obj = shift;
	my $name = shift;
	++$obj->{-registers}->{$name}->{$_} for @_;
}

sub deregister {
	my $obj = shift;
	my $name = shift;
	for (@_) {
		delete $obj->{-registers}->{$name}->{$_} unless --$obj->{-registers}->{$name}->{$_};
	}
}

sub get_register {
	my $obj = shift;
	my $name = shift;
	return () unless exists $obj->{-registers};
	return () unless exists $obj->{-registers}->{$name};
	return keys %{$obj->{-registers}->{$name}};
}
