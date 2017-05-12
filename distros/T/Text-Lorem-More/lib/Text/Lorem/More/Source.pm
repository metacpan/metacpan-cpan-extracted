package Text::Lorem::More::Source;

use warnings;
use strict;

use constant DEFAULT_PRIORITY => 2 ** 6;
use Carp;

sub new {
	my $self = bless {}, shift;
	my $generator = shift;
	my $priority = shift;
	$self->{source} = [];

	$self->push($generator, $priority) if defined $generator;

	return $self;
}

sub push {
	my $self = shift;
	my $generator = shift;
	my $priority = shift || DEFAULT_PRIORITY;
	$self->{source} = [ sort { $a->[1] cmp $b->[1] } @{ $self->{source} }, [ $generator, $priority ] ];
}

sub copy {
	my $self = shift;
	my $copy = new __PACKAGE__;
	for (@{ $self->{source} }) {
		$copy->push({ %{ $_->[0] } }, $->[1]);
	}
	return $copy;
}

sub find {
	my $self = shift;
	my $name = shift;

	for (@{ $self->{source} }) {
		next unless defined (my $generatelet = $_->[0]->{$name});
		return $generatelet if ref $generatelet;
		return $self->find($generatelet);
	}

	croak "couldn't find generatelet for \"$name\"";
}

1;
