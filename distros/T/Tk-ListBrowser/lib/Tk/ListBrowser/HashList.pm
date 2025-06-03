package Tk::ListBrowser::HashList;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;

$VERSION =  0.09;

sub new {
	my $class = shift;
	my $self = {
		INDEX => {},
		LIST => [],
	};
	bless($self, $class);
	return $self
}

sub add {
	my ($self, $entry, $index) = @_;
	if ($self->exist($entry)) {
		croak "Entry '$entry' already exists";
		return
	}
	my $l = $self->{LIST};
	my $h = $self->{INDEX};
	if (defined $index) {
		$h->{$entry->name} = $index;
		splice(@$l, $index, 0, $entry);
		$self->build($index);
	} else {
		$h->{$entry->name} = @$l;
		push @$l, $entry;
	}
}

sub build {
	my ($self, $index) = @_;
	$index = 0 unless defined $index;
	my $l = $self->{LIST};
	my $i = $self->{INDEX};
	grep {	$i->{$l->[$_]->name} = $_ } $index .. @$l - 1;
}

sub delete {
	my ($self, $name) = @_;
	my $l = $self->{LIST};
	my $index = $self->index($name);
	if (defined $index) {
		my ($del) = splice(@$l, $index, 1);
		$del->clear;
		my $i = $self->{INDEX};
		delete $i->{$name};
		$self->build($index);
		return $del
	}
	croak "Entry '$name' not found";
	return undef
}

sub exist {
	my ($self, $name) = @_;
#	croak "name not defined" unless defined $name;
	my $i = $self->{INDEX};
	return exists $i->{$name};
}

sub first {
	my $self = shift;
	return $self->{LIST}->[0]
}

sub get {
	my ($self, $name) = @_;
	my $l = $self->{LIST};
	my $i = $self->{INDEX}->{$name};
	return $l->[$i] if defined $i;
	return undef
}

sub getAll {
	my $self = shift;
	my $l = $self->{LIST};
	return @$l
}

sub getIndex {
	my ($self, $index) = @_;
	return undef unless defined $index;
	my $l = $self->{LIST};
	if (($index < 0) or ($index > @$l - 1)) {
		croak "Index '$index' out of range";
		return undef ;
	}
	return $l->[$index];
}

sub index {
	my ($self, $name) = @_;
	my $h = $self->{INDEX};
	return $h->{$name};
}

sub indexLast {
	my $self = shift;
	my $l = $self->{LIST};
	my $last = $self->size - 1;
	return $last
}

sub last {
	my $self = shift;
	return $self->{LIST}->[$self->indexLast]
}

sub size {
	my $l = $_[0]->{LIST};
	my $s = @$l;
	return $s
}

1;