package smallnum::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.10';
use overload;
require XSLoader;
XSLoader::load('smallnum::XS', $VERSION);

sub import {
        _set_precision($_[1]) if $_[1];
        _set_offset($_[2]) if $_[2];
        overload::constant integer => \&_smallnum;
        overload::constant float => \&_smallnum;
        overload::constant binary => \&_smallnum;
}

1;

__END__

=head1 NAME

smallnum::XS - faster transparent "SmallNumber" support for Perl

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	use smallnum::XS;
	10 + 20.452433483  # 30.45
	20.3743543 - 10.1 # 10.27
	15 / 5.34, # 2.81
	9 * 0.01, # 0.09

	...
	 
	use smallnum::XS '0.1';
	10 + 20.452433483  # 30.5
	20.3743543 - 10.1 # 10.3
	15 / 5.34, # 2.8
	9 * 0.01, # 0.1

	...

	use smallnum::XS '1';
	10 + 20.452433483  # 31
	20.3743543 - 10.1 # 10
	15 / 5.34, # 3
	9 * 0.01, # 0

=head1 BENCHMARK

	use Benchmark qw(:all);
	use smallnum;
	use smallnum::XS;

	timethese(10000000, {
		'smallnum' => sub {
			my $int = smallnum::_smallnum(10.42356);
			my $int2 = smallnum::_smallnum(2.22);
			$int = $int / $int2;
		},
		'XS' => sub {
			my $int = smallnum::XS::_smallnum(10000);
			my $int2 = smallnum::XS::_smallnum(2.22);
			$int = $int / $int2;
		}
	});

...

	Benchmark: timing 10000000 iterations of XS, smallnum...
		XS:  4 wallclock secs ( 3.50 usr +  0.12 sys =  3.62 CPU) @ 2762430.94/s (n=10000000)
	  smallnum:  8 wallclock secs ( 7.42 usr +  0.06 sys =  7.48 CPU) @ 1336898.40/s (n=10000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-smallnum-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=smallnum-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc smallnum::XS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=smallnum-XS>

=item * Search CPAN

L<https://metacpan.org/release/smallnum-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of smallnum::XS
