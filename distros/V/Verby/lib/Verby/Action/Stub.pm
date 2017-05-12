#!/usr/bin/perl

package Verby::Action::Stub;
use Moose;

our $VERSION = "0.05";

with qw/Verby::Action/;

has name => (
	isa => "Str",
	is  => "rw",
	lazy_build => 1,
);

sub _build_name {
	my $self = shift;
	my $class = ref $self;

	$class =~ s/^Verby::Action:://;

	return $class;
}

sub do {
	my ( $self, $c ) = @_;
	$c->done(1);
	$c->logger->debug($self->name . " do");
}

sub verify {
	my ( $self, $c ) = @_;
	$c->logger->debug($self->name . " verify");
	$c->done;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Stub - An action which just logs debug messages.

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;

	my $s = step "Verby::Action::Stub";

=head1 DESCRIPTION

This action is good for use when you need to Stub certain actions.

=head1 METHODS 

=over 4

=item B<do>

Sets C<< $c->done >>.

=item B<verify>

Returns C<< $c->done >>.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
