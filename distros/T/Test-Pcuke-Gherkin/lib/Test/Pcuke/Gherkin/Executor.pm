package Test::Pcuke::Gherkin::Executor;

use warnings;
use strict;

use Test::Pcuke::Gherkin::Executor::Status;

=head1 NAME

Test::Pcuke::Gherkin::Executor - do nothing step executor

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Gherkin::Executor;

    # TODO code sample
    ...

=head1 METHODS

=head2 new

=cut

sub new {
	my ($self) = @_;
	my $instance = {};
	
	bless $instance, $self;
}

sub execute {
	my ($self, $step) = @_;
	
	my $warning = 
		'Default executor does nothing with the step '
		. $step->type
		. ' '
		. $step->title;
	warn $warning;
	
	return Test::Pcuke::Gherkin::Executor::Status->new;
}

1; # End of Test::Pcuke::Gherkin::Executor
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::Executor


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
