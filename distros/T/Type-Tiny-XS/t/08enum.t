=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<Enum>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use_ok('Type::Tiny::XS');

my $check = Type::Tiny::XS::get_coderef_for('Enum[foo,bar,baz,123]');

ok  $check->("foo")                         => 'yes "foo"';
ok  $check->("bar")                         => 'yes "bar"';
ok  $check->("baz")                         => 'yes "baz"';
ok  $check->("123")                         => 'yes "123"';
ok  $check->( 123 )                         => 'yes 123';
ok !$check->("quux")                        => 'no "quux"';
ok !$check->("FOO")                         => 'no "FOO"';
ok !$check->({})                            => 'no {}';
ok !$check->([])                            => 'no []';
ok !$check->("")                            => 'no ""';
ok !$check->(undef)                         => 'no undef';

if ( eval { require Type::Parser } ) {
	my $quoted_check = Type::Tiny::XS::get_coderef_for('Enum["a b", "c, d", "-\""]');
	
	ok  $quoted_check->("a b")                         => 'yes "a b"';
	ok  $quoted_check->("c, d")                        => 'yes "c, d"';
	ok  $quoted_check->("-\"")                         => 'yes "-\""';
	ok !$quoted_check->("quux")                        => 'no "quux"';
	ok !$quoted_check->("FOO")                         => 'no "FOO"';
	ok !$quoted_check->({})                            => 'no {}';
	ok !$quoted_check->([])                            => 'no []';
	ok !$quoted_check->("")                            => 'no ""';
	ok !$quoted_check->(undef)                         => 'no undef';
}

done_testing;
