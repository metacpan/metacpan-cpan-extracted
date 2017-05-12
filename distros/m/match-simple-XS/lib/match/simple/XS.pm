package match::simple::XS;

use 5.008000;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

require Carp;
require XSLoader;
XSLoader::load('match::simple::XS', $VERSION);

sub _regexp { scalar($_[0] =~ $_[1]) }

if ($] >= 5.010)
{
	eval q[
		no warnings;
		use overload ();
		sub _smartmatch {
			overload::Method($_[1], "~~")
				? !!( $_[0] ~~ $_[1] )
				: Carp::croak("match::simple::XS cannot match")
		}
	];
}
else
{
	eval q[
		sub _smartmatch {
			Carp::croak("match::simple::XS cannot match")
		}
	];
}

1;
__END__

=head1 NAME

match::simple::XS - XS backend for match::simple

=head1 SYNOPSIS

  use match::simple;

=head1 DESCRIPTION

Nothing to see here; move along.

=head1 SEE ALSO

L<match::simple>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

Thanks to alh, bulk88, rafl, leont, and ilmari on the I<< #xs >> IRC
channel for helping me translate a bunch ideas from Perl to XS.

The XS source code for L<Scalar::Util> was also very useful.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

