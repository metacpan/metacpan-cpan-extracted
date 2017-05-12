package Test::Pcuke::Gherkin::Node::Feature;
use warnings;
use strict;

use base qw{Test::Pcuke::Gherkin::Node};
use Carp;

=head1 NAME

Test::Pcuke::Gherkin::Node::Feature - Represents a feature

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Node::Feature;
    #TODO
    ...

=head1 METHODS

=head2 new

=cut

sub new {
	my($class, $args) = @_;
	
	my $properties	= [ qw{scenarios _nsteps _nscenarios} ];
	my $immutables	= [ qw{title narrative background} ];
	
	$args->{_nsteps}	= { pass=>0, undef=>0, fail=>0};
	$args->{_nscenarios}= { pass=>0, undef=>0, fail=>0};
	
	my $self = $class->SUPER::new(
		properties	=> $properties,
		immutables	=> $immutables,
		args 		=> $args
	);	
	
	return $self;
}

sub set_title { 
	my ($self, $title) = @_;
	$self->_set_immutable('title', $title);	
}

sub set_narrative { 
	my ($self, $narrative) = @_;
	
	$self->_set_immutable('narrative', $narrative);
}


sub title { $_[0]->_get_immutable('title') || q{} }
sub narrative{ $_[0]->_get_immutable('narrative') || q{} }

sub add_scenario {
	my ($self, $scenario) = @_;
	
	$self->_add_property('scenarios', $scenario);
}

sub add_outline {
	my ($self, $outline) = @_;
	$self->add_scenario( $outline );
}

sub set_background {
	my ($self, $bgr) = @_;
	$self->_set_immutable('background', $bgr);
}

sub background { $_[0]->_get_immutable('background') }

sub scenarios {
	my ($self) = @_;
	return $self->_get_property('scenarios');
}

sub execute {
	my ($self) = @_;
	my $scenarios = $self->_get_property('scenarios');
	
	foreach ( @$scenarios ) {
		$_->execute( $self->background );
		$self->collect_stats( $_ );		
	}
	
	return $self;
}

sub collect_stats {
	my ($self, $scenario) = @_;
	
	my $nsteps		= $self->nsteps;
	my $nscenarios	= $self->nscenarios;
	
	my $asteps		= $scenario->nsteps;
	my $ascenarios	= $scenario->nscenarios;
	
	for (qw{pass fail undef}) {
		$nsteps->{$_}		+= $asteps->{$_};
		$nscenarios->{$_}	+= $ascenarios->{$_};
	}
	
	$self->_set_property('_nsteps', $nsteps);
	$self->_set_property('_nscenarios', $nscenarios);
}

sub nsteps		{
	my ($self, $status) = @_;
	
	my $nsteps = $self->_get_property('_nsteps');
	
	return $status ?
		  $nsteps->{$status}
		: $nsteps;	 
}

sub nscenarios	{ 
	my ($self, $status) = @_;
	my $nscenarios = $self->_get_property('_nscenarios');
	
	return $status ?
		  $nscenarios->{$status}
		: $nscenarios;
}

1; # End of Test::Pcuke::Gherkin::Node::Feature
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Feature


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

