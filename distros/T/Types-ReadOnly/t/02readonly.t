=pod

=encoding utf-8

=head1 PURPOSE

Test the C<ReadOnly> type constraint wrapper.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008;
use strict;
use warnings;
use Test::More 0.96;
use Test::TypeTiny;
use Test::Fatal;

use Types::Standard -types;
use Types::ReadOnly -types;

my $x = {};
&Internals::SvREADONLY($x, 1);
my $y = [];
&Internals::SvREADONLY($y, 1);

my $roHash = ReadOnly[HashRef];
ok($roHash->can_be_inlined, "$roHash can be inlined");
ok($roHash->coercion->can_be_inlined, "$roHash coercion can be inlined");

should_pass($x, $roHash);
should_fail({}, $roHash);
should_fail($y, $roHash);
should_fail([], $roHash);

my $r = $roHash->coerce({ foo => 1, bar => 2 });
should_pass($r, $roHash, 'can coerce to ReadOnly');
is_deeply($r, { foo => 1, bar => 2 }, '... result of coercion has correct deep structure');

{
	my $Rounded = Int->plus_coercions(Num, q{int($_)});
	my $roTuple = ReadOnly[ Tuple[ $Rounded, HashRef ] ];
	my $r2 = $roTuple->coerce([1.1, { foo => 4 }]);
	should_pass($r2, $roTuple, "can coerce to $roTuple (testing with string of code)");
	is_deeply($r2, [1, { foo => 4}], '... result of coercion has correct deep structure');
}

{
	my $Rounded = Int->plus_coercions(Num, sub {int($_)});
	my $roTuple = ReadOnly[ Tuple[ $Rounded, HashRef ] ];
	my $r2 = $roTuple->coerce([1.1, { foo => 4 }]);
	should_pass($r2, $roTuple, "can coerce to $roTuple (testing with coderef)");
	is_deeply($r2, [1, { foo => 4}], '... result of coercion has correct deep structure');
}

done_testing;
