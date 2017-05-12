package Tie::Handle::Flock;

use warnings;
use strict;

require Tie::Handle;
our @ISA = qw(Tie::StdHandle);
our $VERSION = '0.01';

use Fcntl qw(:flock :seek);

# WRITE this, scalar, length, offset
sub WRITE {
	my $fh = shift;
	$fh->lock();
	$fh->SUPER::WRITE( @_ );
	$fh->unlock();
}

# PRINT this, LIST
sub PRINT {
	my $fh = shift;
	$fh->lock();
	$fh->SUPER::PRINT( @_ );
	$fh->unlock();
}

# PRINTF this, format, LIST
sub PRINTF {
	my $fh = shift;
	$fh->lock();
	$fh->SUPER::PRINTF( @_ );
	$fh->unlock();
}

sub lock {
	my ($fh) = @_;
	flock($fh, LOCK_EX);
	seek( $fh, 0, SEEK_END );
}

sub unlock {
	my ($fh) = @_;
	flock($fh, LOCK_UN);
}


__PACKAGE__; # End of Tie::Handle::Flock

__END__

=pod

=head1 NAME

Tie::Handle::Flock - exclusive locking write handle

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Tie::Handle::Flock;

	tie *FH, 'Tie::Handle::Flock', '>', 'some_file.txt';

	print FH "exclusive lock obtained for duration of the write\n";

=head1 METHODS

=over 4

=item WRITE

method called when something writes to the filehandle

=item PRINT

method called when something prints to the filehandle

=item PRINTF

method called when something prints formatted text to the filehandle

=item lock

method called to obtoin an exclusive lock on the filehandle prior to any write activity

=item unlock

method called to release the exclusive lock after the write is complete

=back

=head1 AUTHOR

Ivan Heffner, C<< <iheffner at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-handle-flock at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Handle-Flock>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Handle::Flock


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Handle-Flock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Handle-Flock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Handle-Flock>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Handle-Flock/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ivan Heffner, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
