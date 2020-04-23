package smallnum;

use strict;
use warnings;
use POSIX ();

our $VERSION = '0.05';

use overload fallback => 1, 
	'""' => \&num,
	'*' => \&multiply,
	'/' => \&divide;

our $precision = .01;
our $offset = 0.5555555;

sub import {
	$precision = $_[1] if $_[1];
	$offset = $_[2] if $_[2];
	overload::constant integer => \&smallnum;
	overload::constant float => \&smallnum;
	overload::constant binary => \&smallnum;
}

sub smallnum {
	my $n = shift;
	bless \$n, __PACKAGE__;
}

sub num {
	my $num = _sref($_[0]);
 	return $num >= 0 
		? $precision * int(($num + ($offset * $precision)) / $precision)
		: $precision * POSIX::ceil(($num - $offset * $precision) / $precision);
}

sub divide {
	my (@ot) = (_sref($_[0]), _sref($_[1])); 
	return $ot[0] && $ot[1]
		? smallnum($_[2] ? ($ot[1] / $ot[0]) : ($ot[0] / $ot[1])) 
		: smallnum(0);
}

sub multiply {
	my (@ot) = (_sref($_[0]), _sref($_[1])); 
	return smallnum($ot[1] * $ot[0]);
}

sub _sref { ref $_[0] ? ${$_[0]} : $_[0] }

# bug on negatives?
# todo

=head1 NAME

smallnum - Transparent "SmallNumber" support for Perl

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use smallnum;

	10 + 20.452433483  # 30.45
	20.3743543 - 10.1 # 10.27
	15 / 5.34, # 2.81
	9 * 0.01, # 0.09

	...
	
	use smallnum '0.1';

	10 + 20.452433483  # 30.5
	20.3743543 - 10.1 # 10.3
	15 / 5.34, # 2.8
	9 * 0.01, # 0.1

	...

	use smallnum '1';

	10 + 20.452433483  # 31
	20.3743543 - 10.1 # 10
	15 / 5.34, # 3
	9 * 0.01, # 0

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-smallnum at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=smallnum>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc smallnum

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=smallnum>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/smallnum>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/smallnum>

=item * Search CPAN

L<https://metacpan.org/release/smallnum>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of smallnum
