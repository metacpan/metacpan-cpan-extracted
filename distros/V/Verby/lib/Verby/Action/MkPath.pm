#!/usr/bin/perl

package Verby::Action::MkPath;
use Moose;

with qw/Verby::Action/;

use File::Path qw/mkpath/;

our $VERSION = "0.05";

sub do {
	my $self = shift;
	my $c = shift;

	my $path = $c->path;

	if ( !defined($path) || !length($path) ){
		$c->logger->log_and_die(level => "error", message => "invalid path");
	}

	$c->logger->info("creating path '$path'");

	mkpath($path)
		or $c->logger->log_and_die(level => "error", message => "couldn't mkpath('$path'): $!");

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	-d $c->path;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::MkPath - Action to create a directory path

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;

	step "Verby::Action::MkPath" => sub {
		my ($self, $c) = @_;
		$c->path("/some/path/that/will/be/created");
	}

=head1 DESCRIPTION

This Action uses L<File::Path/mkpath> to create a directory path.

=head1 METHODS 

=over 4

=item B<do>

Creates the directory C<< $c->path >>.

=item B<verfiy>

Ensures that the directory C<< $c->path >> exists.

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
