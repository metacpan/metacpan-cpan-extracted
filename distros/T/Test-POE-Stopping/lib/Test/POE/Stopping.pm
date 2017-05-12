package Test::POE::Stopping;

=pod

=head1 NAME

Test::POE::Stopping - Test if a POE process has nothing left to do

=head1 DESCRIPTION

L<POE> is a curious beast, as most asynchronous environments are.

But in regards to testing, one of the more interesting (and when it's not
working properly, annoying) situations is how to tell if the POE-controlled
process will, or has, stopped.

The obvious solution is to just say something like

  POE::Kernel->run;
  pass( "POE stopped" );

But this isn't really useful to us, because this test never fails, it just
deadlocks forever if some event generator is left around.

B<Test::POE::Stopped> takes an introspective method in determining this.

In your test script, a top level controlling session should be set up.

In this session, you should set a delayed alarm, that SHOULD fire after
everything is finished, and POE should have naturally stopped.

The delayed alarm will keep POE from returning, but it should make the alarm
the very last event called.

In this event you call the C<poe_stopping> function, which will examine the
running L<POE::Kernel> to see if it displays the characteristics of one
with the last event in progress (no other sessions, empty queue, no event
generators, etc).

If POE is B<not> stopping, then the C<poe_stopping> function will emit a
fail result and then do a hard-stop of the POE kernel so that at least your
test script ends.

=cut

use 5.006;
use strict;
use warnings;
use YAML::Tiny     1.38 ();
use Test::More     0.80 ();
use Test::Builder  0.80 ();
use POE           1.310 qw( Session );
use POE::API::Peek 2.17 ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	require Exporter;
	$VERSION = '1.09';
	@ISA     = 'Exporter';
	@EXPORT  = 'poe_stopping';
}

sub import {
	my $class = shift;
	my $pkg   = caller;
	my $test  = Test::Builder->new;
	$test->exported_to($pkg);
	$test->plan(@_);
	$class->export_to_level(1, $class, 'poe_stopping');
}

sub fail {
	my $test = Test::Builder->new;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	$test->ok( 0, 'POE appears to be stopping cleanly' );
	$test->diag( YAML::Tiny->new(@_)->write_string );
	$poe_kernel->stop;
}





#####################################################################
# Main Methods

=pod

=head2 poe_stopping

  poe_stopping();

The C<poe_stopping> test checks the kernel to see if, after the current
event, the POE kernel will have nothing else left to do and so will stop.

=cut

sub poe_stopping {
	my $api  = POE::API::Peek->new;
	my $test = Test::Builder->new;

	# The kernel should be running
	unless ( $api->is_kernel_running ) {
		Test::More::diag("POE kernel is not running");
		return fail();
	}

	# Get the session information
	my @sessions = map {
		session_summary($_)
	} $api->session_list;

	# Remove the master session
	@sessions = grep {
		$_->{id} ne POE::Kernel->ID
	} @sessions;

	# Check we aren't trying to terminate POE in a nested event
	my $i      = 0;
	my $invoke = 0;
	while ( my @c = caller($i++) ) {
		if ( $c[3] eq 'POE::Session::_invoke_state' ) {
			$invoke++;
		}
	}
	unless ( $invoke == 1 ) {
		my $rv = fail(@sessions);
		Test::More::diag("Tried to stop within nested events $invoke deep (probably due to using ->call)");
		return $rv;
	}

	# There should only be one session left
	my $session  = $sessions[0];
	unless ( @sessions == 1 ) {
		return fail(@sessions);
	}

	# It should be the current session
	unless ( $session->{current} ) {
		return fail(@sessions);
	}

	# There should be no registered aliases
	if ( $session->{alias} ) {
		return fail(@sessions);
	}

	# There should be no extra references
	if ( $session->{extra} ) {
		return fail(@sessions);
	}

	# There should be no handles on the session
	if ( $session->{handles} ) {
		return fail(@sessions);
	}

	# There should be no events left for this session
	if ( $session->{queue}->{distinct} ) {
		return fail(@sessions);
	}

	# There should be no registered signals
	if ( $session->{signals} ) {
		return fail(@sessions);
	}

	# There should be no child sessions
	if ( $session->{children} ) {
		return fail(@sessions);
	}

	# There should be no other kernel events left
	# (other than maybe a stat tick)
	my $kqueue = scalar grep {
		$_->{destination}->isa('POE::Kernel')
		and
		$_->{event} ne '_stat_tick'
	} $api->event_queue_dump;

	# All the evidence says that we are stopping
	Test::Builder->new->ok( 1, 'POE appears to be stopping cleanly' );

	return @sessions;
}

sub session_summary {
	my $session  = shift;
	my $api      = POE::API::Peek->new;
	my $current  = $api->current_session;
	my @children = $api->get_session_children($session);
	my %signals  = eval {
		$api->signals_watched_by_session($session);
	};
	if ( $@ and $@ =~ /^Can\'t use an undefined value as a HASH reference/ ) {
		%signals = ();
	}

	my @queue = $api->event_queue_dump;
	my @to = grep {
		$_->{destination}->isa('POE::Session')
		and
		$_->{destination}->ID == $current->ID
	} @queue;
	my @from = grep {
		$_->{source}->isa('POE::Session')
		and
		$_->{source}->ID == $current->ID
	} @queue;
	my @distinct = do {
		my %seen = ();
		grep { ! $seen{$_}++ } ( @from, @to )
	};

	my $summary = {
		id       => $session->ID,
		alias    => $api->session_alias_count($session),
		refs     => $api->get_session_refcount($session),
		extra    => $api->get_session_extref_count($session),
		handles  => $api->session_handle_count($session),
		signals  => scalar(keys %signals),
		current  => ($current->ID eq $session->ID) ? 1 : 0,
		children => scalar(@children),
		queue    => {
			distinct => scalar(@distinct),
			from     => scalar(@from),
			to       => scalar(@to),
		},
	};
	return $summary;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-POE-Stopping>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
