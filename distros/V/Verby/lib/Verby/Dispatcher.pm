#!/usr/bin/perl

package Verby::Dispatcher;
use Moose;

our $VERSION = "0.05";

use Set::Object;
use Verby::Context;
use Carp qw/croak/;
use Tie::RefHash;

use POE;

require overload;

has step_set => (
	isa => "Set::Object",
	is	=> "ro",
	default => sub { Set::Object->new },
);

has satisfied_set => (
	isa => "Set::Object",
	is	=> "ro",
	default => sub { Set::Object->new },
);

has cxt_of_step => (
	isa => "HashRef",
	is	=> "ro",
	default => sub {
		tie my %cxt_of_step, "Tie::RefHash";
		return \%cxt_of_step;
	},
);

has derivable_cxts => (
	isa => "HashRef",
	is	=> "ro",
	default => sub {
		tie my %derivable_cxts, "Tie::RefHash";
		return \%derivable_cxts;
	},
);

has config_hub => (
	isa => "Object",
	is	=> "rw",
	default => sub {
		require Verby::Config::Data;
		Verby::Config::Data->new;
	},
);

has global_context => (
	isa => "Object",
	is	=> "ro",
	lazy	=> 1,
	default => sub { $_[0]->config_hub->derive("Verby::Context") },
);

has resource_pool => (
	isa => "POE::Component::ResourcePool",
	is  => "ro",
	predicate => "has_resource_pool",
);

sub add_step {
	my $self = shift;

	my $steps = $self->step_set;

	foreach my $step (@_) {
		next if $steps->includes($step);

		$self->add_step($step->depends);

		(my $logger = $self->global_context->logger)->debug("adding step $step");
		$steps->insert($step);
	}
}

sub add_steps {
	my $self = shift;
	$self->add_step(@_);
}

sub get_cxt {
	my $self = shift;
	my $step = shift;

	$self->cxt_of_step->{$step} ||= Verby::Context->new($self->get_derivable_cxts($step));
}

sub get_derivable_cxts {
	my $self = shift;
	my $step = shift;

	@{ $self->derivable_cxts->{$step} ||= (
		$step->provides_cxt
			? [ Verby::Context->new($self->get_parent_cxts($step)) ]
			: [ $self->get_parent_cxts($step) ]
	)};
}

sub get_parent_cxts {
	my $self = shift;
	my $step = shift;

	if ( my @cxts = map { $self->get_derivable_cxts($_) } $step->depends ) {
		return @cxts;
	} else {
		return $self->global_context;
	}
}

sub create_poe_sessions {
	my ( $self ) = @_;

	my $g_cxt = $self->global_context;
	$g_cxt->logger->debug("Creating parent POE session");

	POE::Session->create(
		inline_states => {
			_start => sub {
				my ( $kernel, $heap ) = @_[KERNEL, HEAP];
				my $self = $heap->{verby_dispatcher};

				# FIXME
				# handle sigint

				my $g_cxt = $self->global_context;

				my $all_steps = $self->step_set;
				my $satisfied = $self->satisfied_set;

				my $pending = $all_steps->difference( $satisfied );

				foreach my $step ( $pending->members ) {
					$g_cxt->logger->debug("Creating POE session for step $step");

					POE::Session->create(
						inline_states => {
							_start => sub {
								my ( $kernel, $session) = @_[KERNEL, SESSION];

								$kernel->sig("VERBY_STEP_FINISHED" => "step_finished");
								$kernel->refcount_increment( $session->ID, "unresolved_dependencies" );

								$kernel->yield("try_executing_step");
							},
							step_finished => sub {
								my ( $kernel, $heap, $done ) = @_[KERNEL, HEAP, ARG1];

								my $deps = $heap->{dependencies};

								if ( $deps->includes($done) ) {
									$deps->remove( $done );
									$kernel->yield("try_executing_step") unless $deps->size;
								}
							},
							try_executing_step => sub {
								my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];

								return if $heap->{dependencies}->size; # don't run if we're waiting
								return if $heap->{ran}++; # don't run twice

								$heap->{g_cxt}->logger->debug("All dependencies of '$step' have finished, starting");

								$kernel->sig("VERBY_STEP_FINISHED"); # we're no longer waiting for other steps to finish
								$kernel->refcount_decrement( $session->ID, "unresolved_dependencies" );

								if ( my $pool = $heap->{resource_pool} and my @req = $heap->{step}->resources ) {
									$heap->{resource_request} = $pool->request(
										params => { @req },
										event  => "execute_step",
									);
								} else {
									$kernel->call( $session, "execute_step" );
								}
							},
							execute_step => sub {
								my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];

								# this may create child sessions. If it doesn't this session will go away
								$heap->{verby_dispatcher}->start_step( $heap->{step}, \@_ );
							},
							_stop => sub {
								my ( $kernel, $heap ) = @_[KERNEL, HEAP];
								my $step = $heap->{step};

								if ( my $request = delete $heap->{resource_request} ) {
									$request->dismiss;
								}

								$heap->{g_cxt}->logger->info("step $step has finished.");

								$_->() for @{ $heap->{post_hooks} };

								return $step;
							},
							DIE     => sub { $_[HEAP]{g_cxt}->logger->warn("cought exception: @_") },
							_child  => sub { $_[HEAP]{g_cxt}->logger->debug("Step $_[HEAP]{step} _child event: $_[ARG0]") },
						},
						heap => {
							%{ $heap },
							step         => $step,
							dependencies => Set::Object->new( $step->depends )->difference($satisfied),
							ran          => 0,
							post_hooks   => [],
						},
					);
				}
			},
			_child => sub {
				my ( $kernel, $session, $heap, $type, $step ) = @_[KERNEL, SESSION, HEAP, ARG0, ARG2];

				if ( $type eq "lose" ) {
					$heap->{satisfied}->insert($step);
					$kernel->signal( $session, "VERBY_STEP_FINISHED", $step );
				}
			},
			DIE   => sub { $_[HEAP]{g_cxt}->logger->warn("cought exception: @_") },
			_stop => sub { $_[HEAP]{g_cxt}->logger->debug("parent POE session closing") },
		},
		heap => {
			verby_dispatcher => $self,
			g_cxt            => $g_cxt, # convenience
			satisfied        => $self->satisfied_set,
			( $self->has_resource_pool ? ( resource_pool => $self->resource_pool ) : () ),
		}
	);
}

sub do_all {
	my $self = shift;
	$self->create_poe_sessions;
	$self->global_context->logger->debug("Starting POE main loop");
	$poe_kernel->run;
}

sub start_step {
	my ( $self, $step, $poe ) = @_;

	my $g_cxt = $self->global_context;
	my $cxt = $self->get_cxt($step);

	if ($step->is_satisfied($cxt, $poe)){
		$g_cxt->logger->debug("step $step has already been satisfied, running isn't necessary.");
		return;
	}

	$g_cxt->logger->debug("starting step $step");
	$step->do($cxt, $poe);
}

sub _set_members_query {
	my $self = shift;
	my $set = shift;
	return wantarray ? $set->members : $set->size;
}

sub steps {
	my $self = shift;
	$self->_set_members_query($self->step_set);
}

sub is_satisfied {
	my $self = shift;
	my $step = shift;

	croak "$step is not registered at all"
		unless $self->step_set->contains($step);

	$self->satisfied_set->contains($step);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Dispatcher - Takes steps and executes them. Sort of like what make(1) is to a
Makefile.

=head1 SYNOPSIS

	use Verby::Dispatcher;
	use Verby::Config::Data; # or something equiv

	my $c = Verby::Config::Data->new(); # ... needs the "logger" field set

	my $d = Verby::Dispatcher->new;
	$d->config_hub($c);

	$d->add_steps(@steps);

	$d->do_all;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=item B<resource_pool>

If provided with a L<POE::Component::ResourcePool> instance, that resource pool
will be used to handle resource allocation.

The L<Verby::Step/resources> method is used to declare the required resources
for each step.

=item B<step_set>

Returns the L<Set::Object> that is used for internal bookkeeping of the steps
involved.

=item B<satisfied_set>

Returns the L<Set::Object> that is used to track which steps are satisfied.

=item B<config_hub>

The configuration hub that all contexts inherit from.

Defaults to an empty parameter set.

=item B<global_context>

The global context objects.

Defaults to a derivation of B<config_hub>.

=head1 METHODS

=over 4

=item B<new>

Returns a new L<Verby::Dispatcher>. Duh!

=item B<add_steps *@steps>

=item B<add_step *@steps>

Add a number of steps into the dispatcher pool.

Anything returned from L<Verby::Step/depends> is aggregated recursively here, and
added into the batch too.

=item B<do_all>

Calculate all the dependencies, and then dispatch in order.

=back

=begin private

=over 4

=item B<is_satisfied $step>

Whether or not $step does not need to be executed (because it was already
executed or because it didn't need to be in the first place).

=item B<get_cxt $step>

Returns the context associated with $step. This is where $step will write it's
data.

=item B<get_derivable_cxts $step>

Returns the contexts to derive from, when creating a context for $step.

If $step starts a new context (L<Step/provides_cxt> is true) then a new context
is created here, derived from get_parent_cxts($step). Otherwise it simply
returns get_parent_cxts($step).

Note that when a step 'provides a context' this really means that a new context
is created, and this context is derived for the step, and any step that depends
on it.

=item B<get_parent_cxts $step>

If $step depends on any other steps, take their contexts. Otherwise, returns
the global context.

=item B<start_step $step>

Starts the 

=item B<steps>

Returns a list of steps that the dispatcher cares about.

=back

=end

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it.

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>
stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
