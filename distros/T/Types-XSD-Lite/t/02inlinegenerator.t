=pod

=encoding utf-8

=head1 PURPOSE

Test inline generators for Types::XSD::Lite types.

=head1 DEPENDENCIES

Requires L<Moo> 1.003000.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on a script by Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires { 'Moo'              => '1.003000' };
use Test::Requires { 'Types::XSD::Lite' => '0.003'    };

my $USE_MOO;
BEGIN { $USE_MOO = @ARGV?shift:1 };

use Types::XSD::Lite qw[NonNegativeInteger];

my ($t1, $t2) = (
	NonNegativeInteger[ maxInclusive => 9 ],
	NonNegativeInteger[ maxInclusive => 9 ],
);

if ($USE_MOO)
{
	package Foo;
	use if $USE_MOO, 'Moo';
	has(ccd => (
		is  => 'ro',
		isa => $t1,
	));
	__PACKAGE__->new(ccd => 1);
}

is($t1->{uniq}, $t2->{uniq});

ok(! $t1->_is_null_constraint);

like(
	exception { $t1->(10) },
	qr/did not pass type constraint/,
);

{
	my $code = $t1->inline_check('$VALUE');
	my $pass = eval "my \$VALUE = 10; $code";
	ok(!$pass) or note("CODE: $code");
}

note explain [ $t1->inlined->($t1, '$VALUE') ];

done_testing;
