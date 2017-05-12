=pod

=encoding utf-8

=head1 PURPOSE

Test that L<Types::ReadOnly> works with L<Moo>.

=head1 DEPENDENCIES

Requires Moo 1.000000; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008;
use strict;
use warnings;
use Test::More 0.96;
use Test::Requires { "Moo" => '1.000000' };
use Test::Fatal;

use Types::Standard -types;
use Types::ReadOnly -types;

my $SciNum = Locked[ Dict[ mantissa => Num, exponent => Optional[Int] ] ];
$SciNum->coercion->add_type_coercions(
	Str, q{do{
		require Math::BigFloat;
		my $tmp = 'Math::BigFloat'->new($_);
		+{ mantissa => $tmp->mantissa->bstr, exponent => $tmp->exponent->bstr };
	}},
);

{
	package Measurement;
	use Moo;
	has magnitude => (
		is     => 'ro',
		isa    => $SciNum,
		coerce => $SciNum->coercion,
	);
	has unit => (
		is     => 'ro',
		isa    => Types::Standard::Str,
	);
	sub to_string {
		my $self = shift;
		$self->magnitude->{exponent}
			? sprintf(
				'%fE%d %s',
				$self->magnitude->{mantissa},
				$self->magnitude->{exponent},
				$self->unit,
			)
			: sprintf(
				'%f %s',
				$self->magnitude->{mantissa},
				$self->unit,
			)
	}
}

for my $X (
	[{ mantissa => '1.74', exponent => 0 }, '1.740000 m', 1.74, 0],
	[{ mantissa => '1.74' }, '1.740000 m', 1.74, undef],
	['1.74', '174.000000E-2 m', 174, -2],
)
{
	my ($mag, $to_string, $mantissa, $exponent) = @$X;
	subtest "Measurement with magnitude ".Type::Tiny::_dd($mag) => sub {
		my $height = new_ok 'Measurement' => [ magnitude => $mag, unit => 'm' ];
		is($height->magnitude->{mantissa}, $mantissa, '... mantissa is ok');
		is($height->magnitude->{exponent}, $exponent, '... exponent is ok');
		like(
			exception { $height->magnitude->{exponant} },
			qr{^Attempt to access disallowed key 'exponant' in a restricted hash},
			'... magnitude hashref has locked keys',
		);
		is($height->to_string, $to_string, '... and $height->to_string works');
		done_testing;
	};
}

done_testing;

