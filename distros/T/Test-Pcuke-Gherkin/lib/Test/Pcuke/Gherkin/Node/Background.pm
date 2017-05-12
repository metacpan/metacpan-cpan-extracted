package Test::Pcuke::Gherkin::Node::Background;

use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';

=head1 NAME

Test::Cucumber::Background - background of the scenarios in a feature

=head1 SYNOPSIS

TODO synopsis

    use Test::Pcuke::Gherkin::Node::Background;

    my $background = Test::Pcuke::Gherkin::Node::Background->new();
    # TODO code example

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $args) = @_;
	
	my $self = $class->SUPER::new(
		immutables	=> ['title'],
		properties	=> ['steps'],
		args		=> $args,
	);
	
	$self->_clear_stats;
	
	return $self;
}

sub title { $_[0]->_get_immutable('title') || q{} }
sub set_title { $_[0]->_set_immutable('title', $_[1]) }

sub add_step {
	my ($self, $step) = @_;
	$self->_add_property('steps', $step);
}

sub steps { $_[0]->_get_property('steps') || []; }

sub execute {
	my ($self) = @_;
	
	$self->_clear_stats;
	
	my $steps = $self->_get_property('steps');
	
	for ( @$steps ) {
		$_->execute();
		$self->collect_stats( $_ );
	 }
}

sub collect_stats {
	my ($self, $step) = @_;
	
	my $nsteps = $self->nsteps;
	$nsteps->{ $step->status }++;
	$self->_set_property('_nsteps', $nsteps);
}

sub _clear_stats { $_[0]->_set_property('_nsteps', {fail=>0, pass=>0, undef=>0}) }

sub nsteps {
	my ($self, $status) = @_;
	my $nsteps = $self->_get_property('_nsteps');
	
	return $status ?
		  $nsteps->{$status}
		: $nsteps;
}

1; # End of Test::Cucumber::Background
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Background


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


