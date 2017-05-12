#!/usr/bin/perl

package Verby::Action::Untar;
use Moose;

with qw/Verby::Action::Run/;

our $VERSION = "0.04";

use Archive::Tar;
use File::Spec;
use File::stat;

sub do {
	my ( $self, $c ) = @_;

	my $tarball = $c->tarball;
	my $dest    = $c->dest;
	
	$c->logger->info("untarring '$tarball' into '$dest'");

	$self->create_poe_session(
		c       => $c,
		program => sub {
			chdir $dest;

			$self->tar_archive($c)->extract
				or $c->logger->log_and_die("Archive::Tar->extract did not return a true value");
		},
		program_debug_string => "Archive::Tar child",
	);
}

sub finished {
	my ( $self, $c ) = @_;
	$c->logger->info("finished untarring");
	$self->confirm($c);
}

sub verify {
	my ( $self, $c ) = @_;

	my $dest = $c->dest;

	my $main_dir; # the main directory in the archive, if any

	my $i;

	my $tarball = $self->tar_archive( $c );

	foreach my $spec ( $tarball->list_files([qw/name size mtime/]) ) {
		my ( $name, $size, $mtime ) = @{ $spec }{qw/name size mtime/};

		# determine the top level unpack directory
		my $top_dir = (File::Spec->splitdir($name))[0];
		if ( defined $main_dir ) {
			if ( $top_dir ne $main_dir ) {
				$c->logger->warn("Archive has no main directory");
				$main_dir = '';
			}
		} else {
			$main_dir = $top_dir;
		}

		my $destfile = File::Spec->catfile($dest, $name);
		my $existing = stat($destfile);
		unless ( $existing and ( -d $destfile or $existing->size == $size && $existing->mtime == $mtime ) ) {
			$c->logger->warn("file '$name' requires re-extraction") if $i; # it's ok only for the first file to be missing
			return undef;
		}

		$i++;
	}

	$c->main_dir(File::Spec->catdir($dest, $main_dir));

	return 1;
}

sub tar_archive {
	my ( $self, $c ) = @_;
	$c->archive_object || $c->archive_object(Archive::Tar::LogError->new($c->tarball));
}

package Archive::Tar::LogError;
use base qw(Archive::Tar);

use Log::Dispatch::Config;

sub _error {
    Log::Dispatch::Config->instance->log_and_die( level => "error", message => $_[1] );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Untar - Action to un-tar an archive.

=head1 SYNOPSIS

	use Verby::Action::Untar;

=head1 DESCRIPTION

This Action, using L<Archive::Tar>, will untar a given archive.

=head1 METHODS 

=over 4

=item B<do>

Fork off command to unpack the tarfile using L<Verby::Action::Run>.

=back

=head1 PARAMETERS

=over 4

=item B<tarball>

The path to the archive that will require extraction.

=item B<dest>

The path to extract into.

=back

=head1 OUTPUT PARAMETERS

=over 4

=item B<main_dir>

When the tar archive is a single-directory archive, this field will be set to
that root directory.

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
