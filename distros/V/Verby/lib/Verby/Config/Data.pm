#!/usr/bin/perl

package Verby::Config::Data;
use Moose;

our $VERSION = "0.05";

use List::MoreUtils qw/uniq/;
use Carp qw/croak/;

has data => (
	isa => "HashRef",
	is  => "rw",
	default => sub { return {} },
);

has parents => (
	isa => "ArrayRef",
	is  => "ro",
	auto_deref => 1,
	required   => 1,
);

around new => sub {
	my $next = shift;
	my ( $class, @parents ) = @_;

	$class->$next( parents => [ uniq @parents ] );
};

sub DEMOLISH {
	my $self = shift;
	untie %{ $self->{data} } if tied $self->{data};
}

sub AUTOLOAD {
	(our $AUTOLOAD) =~ /::([^:]+)$/;

	my $field = $1;

	my $sub = sub {
		my $self = shift;
		$self->set($field, @_) if @_;
		$self->get($field);
	};

	{
		no strict;
		*{ $field } = $sub;
	}

	goto &$sub;
}

sub set {
	my $self = shift;
	croak "$self is not mutable";
}

sub get {
	my $self = shift;
	my $key = shift;
	($self->search($key) || return)->extract($key);
}

sub extract {
	my $self = shift;
	my $key = shift;
	$self->data->{$key};
}

sub exists {
	my $self = shift;
	my $key = shift;
	$self->data->{$key} || exists $self->data->{$key}; # XXX workaround for Tie::Memoize
}

sub search {
	my $self = shift;
	my $key = shift;

	if ( $self->exists($key) ) {
		return $self;
	} else {
		my @matches = uniq map { $_->search($key) } $self->parents;
		if ( @matches == 1 ) {
			return $matches[0];
		} else {
			Log::Dispatch::Config->instance->warn("Parents config sources conflict over $key: @matches") if @matches;
			return;
		}
	}
}

sub derive {
	my ( $self, $class ) = @_;
	$class ||= ref $self;

	$class->new($self);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Data - 

=head1 SYNOPSIS

	use Verby::Config::Data;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<set>

=item B<get>

=item B<extract>

=item B<exists>

=item B<search>

=item B<derive>

=item B<data>

=item B<parents>

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
