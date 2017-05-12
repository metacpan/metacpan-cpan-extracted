#!/usr/bin/perl

package Verby::Config::Source::ARGV;
use Moose;

extends qw/Verby::Config::Data/;

our $VERSION = "0.05";

use Getopt::Casual;

sub BUILD {
	my $self = shift;

	my %data = map {
		(my $key = $_) =~ s/^-+//; # Getopt::Casual exposes '--foo', etc.
		$key => $ARGV{$_};
	} keys %ARGV;

	$self->data( \%data );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Source::ARGV - L<Verby::Config::Data> fields from the command line

=head1 SYNOPSIS

	use Verby::Config::Source::ARGV;

	my $argv = Verby::Config::Source::ARGV->new
	my $config_hub = Verby::Config::Data->new($argv, $other_source);

Use a field

	sub do {
		my ($self, $c) = @_;
		print $c->handbag;
	}

And then on the command line, set it:

	my_app.pl --handbag=gucci

=head1 DESCRIPTION

This module is useful for getting some global keys set or perhaps overridden on
the command line.

=head1 METHODS

=over 4

=item B<new>

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
