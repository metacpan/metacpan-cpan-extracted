package Test::Pcuke::Gherkin::Node::Scenarios;

use warnings;
use strict;

use base 'Test::Pcuke::Gherkin::Node';
=head1 NAME

Test::Pcuke::Gherkin::Node::Scenarios - scenarios aka examples

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Node::Scenarios;

    my $scenarios = Test::Pcuke::Gherkin::Node::Scenarios->new();
    # TODO code example

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $args) = @_;
	
	my $self = $class->SUPER::new(
		immutables	=> [qw{title table}],
		args		=> $args,
	);
	
	return $self;
}

sub set_title { $_[0]->_set_immutable('title', $_[1]) }
sub title { $_[0]->_get_immutable('title') || q{} }

sub set_table { $_[0]->_set_immutable('table', $_[1]) }
sub table { $_[0]->_get_immutable('table') }

sub execute {
	my ($self, $steps, $background) = @_;
	
	$self->table->execute( $steps, $background );
}

sub nsteps { $_[0]->table->nsteps }
sub nscenarios { $_[0]->table->nscenarios }



1; # End of Test::Pcuke::Gherkin::Node::Scenarios
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Node::Scenarios


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


