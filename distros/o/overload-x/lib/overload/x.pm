package overload::x;
use 5.006; use strict; use warnings; our $VERSION = '1.01';
use base 'Import::Export';
use Clone qw(clone);

our %EX = (
	n => [qw/all/],
	x => [qw/all/]
);

use overload
	'x' => \&x;

sub n {
	my $n = shift;
	bless \$n, __PACKAGE__;
}

sub x {
	my ($times, $obj) = @_;
	my @times = map {
		ref $obj ? clone($obj) : $obj
	} 1 .. (ref $times ? $$times : $times);
	wantarray ? @times : \@times;
}

1;

__END__

=head1 NAME

overload::x - x on refs

=for html
<a href="https://travis-ci.org/ThisUsedToBeAnEmail/overload-x"><img src="https://travis-ci.org/ThisUsedToBeAnEmail/overload-x.png?branch=master" alt="Build Status"></a>
<a href="https://coveralls.io/r/ThisUsedToBeAnEmail/overload-x?branch=master"><img src="https://coveralls.io/repos/ThisUsedToBeAnEmail/overload-x/badge.png?branch=master" alt="Coverage Status"></a>
<a href="https://metacpan.org/pod/overload-x"><img src="https://badge.fury.io/pl/overload-x.svg" alt="CPAN version"></a>

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	use overlord::x qw/n/;

	my $arrayOfObjs = Obj->new x n(5)

	my ($one, $two, $three, $four) = @{ [qw/1 2 3/] x n(4) }

	####

	my $arrayOfObjs = x(5, Obj->new)
	my ($one, $two, $three, $four) = x(4, [qw/1 2 3/])

=head2 n

Bless an integer into an overload::x object (So you have an object with x overloaded)

=head2 x

This function is fundermentally just a clone function which takes an integer index to replicate the passed object by.

It is called when the overloaded x is triggered via n() or you can additionally instantiate this directly by passing in the index replication and object.

	my ($one, $two, $three, $four) = x(4, [qw/1 2 3/])

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-overload-x at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=overload-x>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc overload::x

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=overload-x>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/overload-x>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/overload-x>

=item * Search CPAN

L<http://search.cpan.org/dist/overload-x/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 LNATION.

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

1; # End of overload::x
