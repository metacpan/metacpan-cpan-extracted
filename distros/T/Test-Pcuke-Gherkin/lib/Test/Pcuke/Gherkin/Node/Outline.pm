package Test::Pcuke::Gherkin::Node::Outline;

use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';

=head1 NAME

Test::Pcuke::Gherkin::Node::Outline - Scenario Outline class

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Node::Outline;

    my $outline = Test::Pcuke::Gherkin::Node::Outline->new();
    # TODO code example

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $args) = @_;
	
	$args->{'_nsteps'}		= {pass=>0, fail=>0, undef=>0 };
	$args->{'_nscenarios'}	= {pass=>0, fail=>0, undef=>0 };
	
	my $self = $class->SUPER::new(
		immutables	=> [qw{title}],
		properties	=> [qw{_nsteps _nscenarios examples steps}],
		args		=> $args,
	);
	
	return $self;
}

sub set_title {
	my ($self, $title) = @_;
	$self->_set_immutable('title', $title);
}

sub title { $_[0]->_get_immutable('title') }

sub add_examples {
	my ($self, $examples) = @_;
	$self->_add_property('examples', $examples);
}

sub examples { $_[0]->_get_property('examples') }

sub add_step {
	my ($self, $step) = @_;
	$self->_add_property('steps', $step);
}

sub execute {
	my ($self, $background) = @_;
	my $scenarioses = $self->examples;
	my $steps = $self->_get_property('steps');
	
	for ( @$scenarioses ){
		$_->execute( $steps, $background );
		$self->collect_stats( $_ );
	}
}

sub collect_stats {
	my ($self, $scenarios) = @_;
	my $nsteps = $self->nsteps;
	my $nscenarios = $self->nscenarios;
	
	my $asteps = $scenarios->nsteps;
	my $ascenarios = $scenarios->nscenarios;
	
	for (qw{pass fail undef}) {
		$nsteps->{$_}		+= $asteps->{$_};
		$nscenarios->{$_}	+= $ascenarios->{$_};
	}
	
	$self->_set_property('_nsteps', $nsteps);
	$self->_set_property('_nscenarios', $nscenarios);
}

sub steps { $_[0]->_get_property('steps'); }

sub nsteps {
	my ($self, $status) = @_;
	my $nsteps = $self->_get_property('_nsteps');
	return $status ? 
		  $nsteps->{$status}
		: $nsteps;	
}

sub nscenarios {
	my ($self, $status) = @_;
	my $nscenarios = $self->_get_property('_nscenarios');
	
	return $status ?
		  $nscenarios->{$status}
		: $nscenarios;
}



1; # End of Test::Pcuke::Gherkin::Node::Outline
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Outline


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

