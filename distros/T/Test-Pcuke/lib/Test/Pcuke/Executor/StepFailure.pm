package Test::Pcuke::Executor::StepFailure;

use warnings;
use strict;

=head1 NAME

Test::Pcuke::Executor::StepFailure - The great new Test::Pcuke::Executor::StepFailure!

=head1 SYNOPSIS

Here is a somewhat artificial example:

    use Test::Pcuke::Executor::StepFailure;
    
	my $exception;
	
	{
		local $@;
		eval {
    		die Test::Pcuke::Executor::StepFailure->new('message');	
		};
		$exception = $@;
	}
	
	if (ref $exception eq 'Test::Pcuke::Executor::StepFailure' ) {
		print "Failure: " . $exception->message;
	}
	else {
		die $exception;
	}
    

=head1 METHODS

=head2 new $message

=cut

sub new {
	my ($class, $msg) = @_;
	
	bless { _msg => $msg}, $class;
}

=head2 message

Returns a message passed to the constructor

=cut

sub message {
	my ($self) = @_;
	return $self->{_msg} || q{};
}


1; # End of Test::Pcuke::Executor::StepFailure
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Executor::StepFailure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is released under the following license: artistic


=cut


