#!/usr/bin/perl

package Verby::Action::Make;
use Moose;

with qw(Verby::Action::Run::Unconditional);

our $VERSION = "0.05";

has make_path => (
	isa => "Str",
	is  => "rw",
	default => "make",
);

has num_jobs => (
	isa => "Int",
	is  => "rw",
	default => 1,
);

has silent => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

sub do {
	my ( $self, $c ) = @_;

	my $wd       = $c->workdir;
	my $makefile = $c->makefile;
	my @targets  = (($c->target || ()), @{ $c->targets || [] });

	my $num_jobs = $self->num_jobs;
	my $silent   = $self->silent;

	$c->is_make_test(1) if "@targets" eq "test";

	my @cli = (
		$self->make_path,
		"-j$num_jobs",
		( $silent ? "-s" : () ),
		( defined($makefile) ? ( "-f" => $makefile ) : () ),
		"-C" => $wd,
		@targets,
	);

	$self->create_poe_session(
		c   => $c,
		cli => \@cli,
	);
}

sub finished {
	my ( $self, $c ) = @_;

	my $out = $c->stdout;
	chomp($out);
	$c->logger->info("test output:\n$out") if $c->is_make_test;

	$self->confirm($c);
}

around exit_code_is_ok => sub {
	my $next = shift;
	my ( $self, $c ) = @_;
	
	if ( $c->is_make_test and $c->allow_test_failurei ) {
		# GNU make exits with '2' on any error in a subtool
		# this is not perfect, but it's something
		$c->program_exit == 2 || $self->$next($c);
	} else {
		$self->$next($c);
	}
};

sub log_extra {
	my ( $self, $c ) = @_;
	" in " . $c->workdir;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Make - Action to run make(1).

=head1 SYNOPSIS

	use Verby::Action::Make;

=head1 DESCRIPTION

=head1 METHODS 

=over 4

=item B<do>

Run the make command with the specified parameters and fields.

=item B<log_extra>

Used by the Run role to provide better log messages.

=item B<finished>

Called by the Run role when the job has finished, 

=back

=head1 PARAMETERS

=over 4

=item B<target>

=item B<targets>

The make targets to run, like e.g. C<test>.

Optional.

=item B<workdir>

The directory in which the makefile should be found. This is passed as the
C<-C> option to C<make>.

=item B<makefile>

If defined, passed as the C<-f> option to make.

=back

=head1 FIELDS

=over 4

=item B<make_path>

The name of the command to run. Defaults to C<make>, but can be overridden to
use e.g. C<gmake>, or something not in $PATH.

=item B<num_jobs>

The C<-j> flag to make. Defaults to 1.

=item B<silent>

Whether or not to pass the C<-s> option to make. Defaults to true.

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
