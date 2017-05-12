package VCS::CSync;

=pod

=head1 NAME

VCS::CSync - Synchronising to local directories from a repository

=head1 DESCRIPTION

This package is the main module for the L<csync> utility.

No specific documentation on module in the C<VCS::CSync> is available.

=cut

use 5.005;
use strict;
use Config::Tiny ();
use Params::Util '_INSTANCE';
use VCS::CSync::Task ();
use overload 'bool' => sub () { 1 };
use overload '""'   => 'file';

use vars qw{$VERSION $TRACE $VERBOSE};
BEGIN {
	$VERSION = '0.02';

	# Destination for trace messages
	$TRACE   = '';

	# Verbose output
	$VERBOSE = '';
}

sub _OBJECT { _INSTANCE(shift, 'UNIVERSAL') }





#####################################################################
# Constructor and Accessors

# Create a new object from a config file
sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $file  = (defined $_[0] and -f $_[0] and -r $_[0]) ? shift : return undef;

	# Load the config file
	my $Config = Config::Tiny->read( $file ) or return undef;

	# Create our basic object
	my $self = bless {
		file  => $file,
		tasks => {},
		}, $class;

	# Add the tasks
	foreach my $section ( %$Config ) {
		my $Task = VCS::CSync::Task->new( $section, $Config->{$section} ) or next;
		$self->add_task($Task) or return undef;
	}

	$self;
}

sub file {
	$_[0]->{file};
}

sub task {
	$_[0]->{tasks}->{$_[1]};
}

sub tasks {
	sort keys %{$_[0]->{tasks}};
}

sub add_task {
	my $self = shift;
	my $Task = _INSTANCE(shift, 'VCS::CSync::Task') or return undef;
	if ( $self->{tasks}->{$Task} ) {
		return error("Found duplicate task " . $Task->dest);
	}
	$self->{tasks}->{$Task} = $Task;
	1;
}





#####################################################################
# Support Functions

# Trace message
sub trace {
	return 1 unless $VERBOSE;
	my @lines = @_;
	foreach my $line ( @lines ) {
		$line .= "\n" unless $line =~ /\n$/;
		if ( $TRACE eq 'STDOUT' ) {
			print STDOUT $line;
		} elsif ( $TRACE eq 'STDERR' ) {
			print STDOUT $line;
		} elsif ( _OBJECT($TRACE) and $TRACE->can('print') ) {
			$TRACE->print( $line );
		}
	}

	1;
}

# Error message.
sub error {
	foreach my $message ( @_ ) {
		next unless defined $message;
		trace("ERROR: $message");
	}
	return undef;
}

# Execute a shell command
sub shell {
	my $cmd = shift;
	trace( "> $cmd" );
	my $rv = system($cmd);
	if ( $rv ) {
		trace($_[0] or "Shell command returned error code $rv");
		return undef;
	}
	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?csync>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy <cpan@ali.as>

=head1 SEE ALSO

L<VCS>, L<VCP>, L<SVK>

=head1 COPYRIGHT

Copyright 2005-2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
