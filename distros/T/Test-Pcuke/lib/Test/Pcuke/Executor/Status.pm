package Test::Pcuke::Executor::Status;

use warnings;
use strict;

=head1 NAME

Test::Pcuke::Executor::Status - status of the step execution

=head1 SYNOPSIS

TODO SYNOPSIS

    use Test::Pcuke::Executor::Status;

    my $status = Test::Pcuke::Executor::Status->new($status, $exception);
    ...

=head1 METHODS

=head2 new

=cut

sub new {
	my ($class, $status, $exception) = @_;
	
	$status ||= 'undef';
	
	return bless {
		_status		=> $status,
		_exception	=> $exception
	}, $class;
}

=head2 status

Returns the status string passed to the constructor

=cut

sub status {
	my ($self) = @_;
	return $self->{_status};
}

=head2 exception 

Returns the exception passed to the constructor

=cut

sub exception {
	my ($self) = @_;
	return $self->{_exception};
}

1; # End of Test::Pcuke::Executor::Status
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Executor::Status


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
