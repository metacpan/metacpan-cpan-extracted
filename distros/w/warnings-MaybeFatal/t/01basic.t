=pod

=encoding utf-8

=head1 PURPOSE

Test that warnings::MaybeFatal works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib "t/lib";
use lib "lib";

use Test::More;
use Test::Warnings qw(warning);
use Test::Fatal qw(exception);

use warnings::MaybeFatal;

$@ = undef;
eval q{
	use strict;
	use warnings;
	use warnings::MaybeFatal;
	"Hello world";
	1;
};

like(
	$@,
	qr/^Useless use/,
	'fatal warning at compile-time',
) or diag explain($@);

my $w = warning { join(undef, 1, 2) };

like(
	$w,
	qr/^Use of uninitialized value/,
	'warning at run-time',
) or diag explain($w);

my $x = warning { require ThisShouldWarn };

like(
	$x,
	qr/^Useless use/,
	'warning at compile-time in another scope',
) or diag explain($x);

my $y;
($] < 5.010)
	? warning {  # spurious warning from Try::Tiny
		$y = exception { require ThisShouldDie }
	}
	: do {
		$y = exception { require ThisShouldDie }
	};

like(
	$y,
	qr/^Useless use/,
	'fatal warning at compile-time in another scope',
) or diag explain($y);

my ($z1, $z2);
$z2 = warning {
	$z1 = exception { require ThisShouldDieToo };
};

# spurious warning from Try::Tiny
$z2 = $z2->[0] if ref($z2) and $] < 5.010;

like(
	$z1,
	qr/^Subroutine xxx redefined/,
	'unimport works',
) or diag explain($z1);

like(
	$z2,
	qr/^Subroutine yyy redefined/,
	'unimport works',
) or diag explain($z2);

done_testing;
