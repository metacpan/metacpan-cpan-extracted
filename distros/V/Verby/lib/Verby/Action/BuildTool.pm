#!/usr/bin/perl

package Verby::Action::BuildTool;
use Moose;

with qw/Verby::Action::Run/;

use File::Spec;
use File::stat;

has command => (
	isa => "Str",
	is  => "rw",
	default => $^X,
);

has script => (
	isa => "Str",
	is  => "rw",
	default => "Makefile.PL",
);

has target => (
	isa => "Str",
	is  => "rw",
	default => "Makefile",
);

sub do {
	my ( $self, $c ) = @_;

	my $wd = $c->workdir || $c->logger->log_and_die(level => "error", message => "No working directory provided");
	my @args = @{ $c->additional_args || [] };

	$self->create_poe_session(
		c    => $c, 
		cli  => [ $self->command, $self->script, @args ],
		init => sub { chdir $wd },
	);
}

sub finished {
	my ( $self, $c ) = @_;
	$self->confirm( $c );
}

sub log_extra {
	my ( $self, $c ) = @_;
	" in " . $c->workdir;
}

sub verify {
	my ( $self, $c ) = @_;

	my $target = File::Spec->catfile($c->workdir, $self->target);
	my $script = File::Spec->catfile($c->workdir, $self->script);

	unless (-e $target) {
	   $c->error("$target doesn't exist");
	   return;
	}
	
	unless ( stat($target)->mtime >= stat($script)->mtime ) {
		$c->error("$target is out of date");
		return;
	}

	return 1;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::BuildTool - Action to run 'perl Makefile.PL' or something
similar in a specific directory.

=head1 SYNOPSIS

	use Verby::Action::MakefilePL;

=head1 DESCRIPTION

This action runs something like 'perl Makefile.PL' (the C<script> field) if the
C<target> field (it's output file) seems out of date.

=head1 METHODS 

=over 4

=item B<do>

Run the C<script> in the specified directory, using C<command>.

=item B<log_extra>

Used by the Run role to improve the log messages.

=item B<verfiy>

Ensures that the C<target> file exists next to the C<script> file, and that is
as new or newer than C<script>.

=back

=head1 FIELDS

=over 4

=item B<command>

Defaults to C<$^X> (the process used to invoke the currently running perl
program, probably "perl" or the shebang line).

=item B<script>

Defaults to C<Makefile.PL>.

=item B<target>

Defaults to C<Makefile>.

=back

=head1 PARAMETERS

=over 4

=item C<workdir>

The directory in which to run the script.

=item C<additional_args>

An optional array ref for additional parameters to send to the script.

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
