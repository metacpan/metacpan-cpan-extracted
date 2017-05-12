=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<NonEmptyStr>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 9;

use_ok('Type::Tiny::XS');

ok  Type::Tiny::XS::NonEmptyStr("Hello")     => 'yes "Hello"';
ok  Type::Tiny::XS::NonEmptyStr("123")       => 'yes "123"';
ok  Type::Tiny::XS::NonEmptyStr(123)         => 'yes 123';
ok  Type::Tiny::XS::NonEmptyStr(0)           => 'yes 0';
ok !Type::Tiny::XS::NonEmptyStr("")          => 'no ""';
ok !Type::Tiny::XS::NonEmptyStr(undef)       => 'no undef';
ok !Type::Tiny::XS::NonEmptyStr([])          => 'no []';
ok !Type::Tiny::XS::NonEmptyStr({})          => 'no {}';
