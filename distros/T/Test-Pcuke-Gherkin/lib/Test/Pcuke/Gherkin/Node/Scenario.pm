package Test::Pcuke::Gherkin::Node::Scenario;
use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';

=head1 NAME

Test::Cucumber::Scenario - Represents a scenario

=head1 SYNOPSIS

Perhaps a little code snippet.

    use Test::Pcuke::Gherkin::Node::Scenario;
    # TODO
    ...

=head1 METHODS

=head2 new

=cut

sub new {
	my($class, $args) = @_;
	
	my $properties	= [ qw{steps _nsteps} ];
	my $immutables	= [ qw{title executor} ];
	
	$args->{_nsteps} = {
		pass=>0,
		fail=>0,
		undef=>0
	};
	
	my $self = $class->SUPER::new(
		properties	=> $properties,
		immutables	=> $immutables,
		args		=> $args
	);	
	
	return $self;
}

sub set_title {
	my ($self, $title) = @_;
	$self->_set_immutable('title', $title);
}

sub title { $_[0]->_get_immutable('title') || q{}; }


sub add_step {
	my ($self, $step) = @_;
	$self->_add_property('steps', $step);
}

sub steps {
	my ($self) = @_;
	return $self->_get_property('steps');
}


sub nsteps {
	my ($self, $status) = @_;
	my $nsteps = $self->_get_property('_nsteps');
	
	return $status ?
		  $nsteps->{$status}
		: $nsteps;
}

sub nscenarios {
	my ($self, $status) = @_;
	
	my $nsteps = $self->nsteps;
	my $nscenarios;
	
	if ( $nsteps->{fail} > 0 ) {
		$nscenarios = { pass=>0, fail=>1, undef=>0 };
	}
	elsif ( $nsteps->{undef} > 0 ) {
		$nscenarios = { pass=>0, fail=>0, undef=>1 };
	}
	else {
		$nscenarios = { pass=>1, fail=>0, undef=>0 };
	}
	
	return $status ?
		  $nscenarios->{$status}
		: $nscenarios;
}


sub execute {
	my ($self, $background) = @_;
	
	my $executor = $self->_get_immutable('executor');
	if ( $executor && $executor->can('reset_world') ) {
		$executor->reset_world;
	}
	
	my $steps = $self->_get_property('steps');
	
	if ( $background ){
		$background->execute;
		$self->collect_stats($background);
	}
	
	foreach my $step (@$steps) {
		$step->execute();
		$self->collect_stats($step);
	}
}

sub collect_stats {
	my ($self, $step) = @_;
	
	my $nsteps = $self->nsteps;
	
	if ( $step->can('nsteps') ) {
		my $bg_nsteps = $step->nsteps;
		for (qw{pass fail undef}) {
			$nsteps->{$_} += $bg_nsteps->{$_};
		}
	}
	else {
		# a step
		$nsteps->{ $step->status }++;
	}
}


1; # End of Test::Pcuke::Gherkin::Node::Scenario

=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Scenario


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut

