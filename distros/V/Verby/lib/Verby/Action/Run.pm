#!/usr/bin/perl

package Verby::Action::Run;
use Moose::Role;

with qw/Verby::Action/;

use Carp qw/croak/;

use POE qw/Wheel::Run Filter::Stream/;

sub create_poe_session {
	my ( $self, %heap ) = @_;
	$heap{log_stderr} = 1 unless exists $heap{log_stderr};

	my $accum = $heap{accum} ||= {};

	foreach my $output ( qw/stdout stderr/ ) {
		next if exists $accum->{$output};
		$accum->{$output} = "";
	}

	POE::Session->create(
		object_states => [
			$self => { $self->poe_states(\%heap) },
		],
		heap => \%heap,
	);
}

sub poe_states {
	my ( $self, $heap ) = @_;
	return (
		_start  => "poe_start",
		_stop   => "poe_stop",
		_parent => "poe_parent",
		(map { ("std$_") x 2 } qw/in out err/),
		(map { ($_) x 2 } qw(
			error
			close
			sigchld_handler
			DIE
		)),
	);
}

sub exit_code_is_ok {
	my ( $self, $c ) = @_;
	$c->program_exit == 0;
}

sub confirm_exit_code {
	my ( $self, $c ) = @_;
	$c->logger->log_and_die(level => "error", message => "subprogram " . $c->program_debug_string . " exited with non zero status: " . $c->program_exit)
		unless $self->exit_code_is_ok($c);
}

sub poe_start {
	my ( $self, $kernel, $session, $heap ) = @_[OBJECT, KERNEL, SESSION, HEAP];

	$self->setup_wheel( $kernel, $session, $heap );
}

sub poe_parent {
	$_[HEAP]{c}->logger->debug("Attached to parent");
}

sub sigchld_handler {
	my ( $self, $kernel, $session, $heap, $pid, $child_error ) = @_[ OBJECT, KERNEL, SESSION, HEAP, ARG1, ARG2 ];

	$heap->{c}->logger->debug("sigchild $pid");

	$kernel->refcount_decrement( $session->ID, 'child_processes' );

	$heap->{program_exit} = $child_error;
}

sub setup_wheel {
	my ( $self, $kernel, $session, $heap ) = @_;

	my $wheel = $self->create_wheel( $heap );

	$kernel->refcount_increment( $session->ID, 'child_processes' );

	$kernel->sig_child( $wheel->PID, "sigchld_handler" );

	$heap->{pid_to_wheel}->{ $wheel->PID } = $wheel;
	$heap->{id_to_wheel}->{ $wheel->ID }   = $wheel;

	$self->send_child_input( $wheel, $heap );
}

sub create_wheel {
	my ( $self, $heap ) = @_;

	my $wheel = POE::Wheel::Run->new(
		$self->wheel_program( $heap ),

		$self->default_poe_wheel_events( $heap ),

		$self->additional_poe_wheel_options( $heap ),
	);
	
	$self->log_invocation($heap->{c}, "started $heap->{program_debug_string}");

	return $wheel;
}

sub additional_poe_wheel_options {
	my ( $self, $heap ) = @_;
	return (
		StdinFilter  => POE::Filter::Stream->new(),
		StdoutFilter => POE::Filter::Stream->new(),
		StderrFilter => POE::Filter::Stream->new(),
	);
}

sub default_poe_wheel_events {
	my ( $self, $heap ) = @_;
	return (
		StdinEvent  => "stdin",
		StdoutEvent => "stdout",
		StderrEvent => "stderr",
		ErrorEvent  => "error",
		CloseEvent  => "close",
	);
}

sub wheel_program {
	my ( $self, $heap ) = @_;

	if ( my $program = $heap->{program} ) {
		$heap->{program_debug_string} ||= "'$program'";
		return Program => $program;
	} elsif( my $cli = $heap->{cli} ) {
		if ( my $init = $heap->{init} ) {
			$heap->{program_debug_string} ||= "'@$cli' with init block";
			return Program => sub { $self->$init($heap); exec(@$cli) };
		} else {
			$heap->{program_debug_string} ||= "'@$cli'";
			return Program => $cli;
		}
	} else {
		croak "Either 'program' or 'cli' must be provided";
	}
}

sub send_child_input {
	my ( $self, $wheel, $heap ) = @_;

	if ( my $in = $heap->{in} ) {
		if ( ref($in) eq "SCALAR" ) {
			$in = $$in;
			$heap->{in} = undef;
		} else {
			$in = $in->();
			$heap->{in} = undef unless defined $in;
		}

		$wheel->put( $in );
	} else {
		$wheel->shutdown_stdin;
	}
}

sub DIE {
	my ( $heap, $exception ) = @_[HEAP, ARG0];
	push @{ $heap->{exceptions} ||= [] }, $exception;
}

sub poe_stop {
	my ( $self, $kernel, $heap ) = @_[OBJECT, KERNEL, HEAP];

	$heap->{c}->logger->info("Wheel::Run subsession closing");

	my $c = $heap->{c};

	$c->command_line( $heap->{cli} ) if exists $heap->{cli};
	$c->program( $heap->{program} ) if exists $heap->{program};
	$c->program_debug_string( $heap->{program_debug_string} );
	$c->stdout( $heap->{accum}{stdout} );
	$c->stderr( $heap->{accum}{stderr} );
	$c->program_exit( $heap->{program_exit} >> 8 ) if defined $heap->{program_exit};
	$c->program_exit_full( $heap->{program_exit} );

	$c->program_finished(1);

	$self->confirm_exit_code($c);

	$self->finished($c) if $self->can("finished");
}

sub error {
	my ( $self, $heap ) = @_[OBJECT, HEAP];
	warn("subprogram $heap->{program_debug_string} error: @_[ARG0 .. $#_]") unless $_[ARG1] == 0;
	$heap->{c}->logger->info("subprogram $heap->{program_debug_string} error: @_[ARG0 .. $#_]") unless $_[ARG1] == 0;
}

sub stdin {
	my ( $self, $heap, $wheel_id ) = @_[OBJECT, HEAP, ARG0];
	$self->send_child_input( $heap->{id_to_wheel}{$wheel_id}, $heap );
}

sub stdout {
	my ( $self, $heap, $output ) = @_[OBJECT, HEAP, ARG0];
	$heap->{accum}{stdout} .= $output;
	$self->log_output( $heap->{c}, "stdout", $output ) if $heap->{log_stdout};
}

sub stderr {
	my ( $self, $heap, $output ) = @_[OBJECT, HEAP, ARG0];
	$heap->{accum}{stderr} .= $output;
	$self->log_output( $heap->{c}, "stderr", $output ) if $heap->{log_stderr};
}

sub log_output {
	my ( $self, $c, $name, $output ) = @_;

	chomp($output) if ($output =~ tr/\n// == 1); # if it's one line, trim it
	foreach my $line (split /\n/, $output){ # if it's not split it looks chaotic
		$c->logger->warning("$name: $line");
	}
}

sub close {
	my ( $self, $heap ) = @_[OBJECT, HEAP];
	$heap->{c}->logger->info("program $heap->{program_debug_string} closed all outputs");
}

sub log_invocation {
	my ( $self, $c, $msg ) = @_;

	$c->logger->info($msg . $self->log_extra($c));
}

sub log_extra { "" }

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Run - a base role for actions which wrap L<POE::Wheel::Run>.

=head1 SYNOPSIS

	package MyAction;
	use Moose;

	with qw/Verby::Action::Run/;
	
	sub start {
		my ($self, $c) = @_;
		$self->create_poe_sessio($c, cli => [qw/touch file/]);
	}

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<create_poe_session %args>

This methods creates a sub session that runs the wheel.

=item B<log_extra>

A method that given the context might append something to log messages. used by
L<Verby::Action::Make>, for example.

=item B<log_invocation>

Mostly internal - the default implementation of the logging operation used when
invoking the subcommand.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

L<Verby::Action::Copy> - a L<Verby::Action::Run> subclass.

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
