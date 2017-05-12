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
use Test::More tests => 12;

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
