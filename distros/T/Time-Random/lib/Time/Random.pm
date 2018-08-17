package Time::Random;
use 5.006; use strict; use warnings; our $VERSION = '0.05';
use Time::Piece;
use base 'Import::Export';
our %EX = (
	time_random => [qw/all/],
);

sub time_random {
	my %args = scalar @_ == 1 ? %{ $_[0] } : @_;
	$args{$_} = $args{$_} 
		? $args{strptime} 
			? Time::Piece->strptime($args{$_}, $args{strptime})->epoch
			: ref $args{$_}
				? $args{$_}->epoch()
				: $args{$_}
		: $_ eq 'to' ? time : ($args{to} - int(rand(86400)))
	foreach qw/to from/;
	$args{time} = gmtime($args{to} - int(rand($args{to} - $args{from}))); 
	$args{strftime} ? $args{time}->strftime($args{strftime}) : $args{time};
}

1;

__END__

=head1 NAME

Time::Random - Generate a random time in time.

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use Time::Random qw/time_random/;

	my $time = time_random(
		from => '1531909277',
	);

	# $time, 'Time::Piece';
	
	$time->epoch();
	$time->strftime('%y-%m-%d %H:%M:%S');
	...

	my $time = time_random(
		from => '18-07-11 13:54:55',
		to => '18-07-18 13:54:55',
		strptime => '%y-%m-%d %H:%M:%S',
		strftime => '%y-%m-%d %H:%M:%S'
	);

=head1 EXPORT

=head2 time_random
 
=cut

=head1 AUTHOR

lnation, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-random at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Random>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Time::Random

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Random>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Time-Random>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-Random>

=item * Search CPAN

L<http://search.cpan.org/dist/Time-Random/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 lnation.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


