=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<PositiveInt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 20;

use_ok('Type::Tiny::XS');

ok !Type::Tiny::XS::PositiveInt(0)        => 'no 0';
ok !Type::Tiny::XS::PositiveInt("0")      => 'no "0"';
ok  Type::Tiny::XS::PositiveInt(123)      => 'yes 123';
ok  Type::Tiny::XS::PositiveInt("123")    => 'yes "123"';
ok !Type::Tiny::XS::PositiveInt(-123)     => 'no -123';
ok !Type::Tiny::XS::PositiveInt("-123")   => 'no "-123"';
ok !Type::Tiny::XS::PositiveInt("")       => 'no ""';
ok !Type::Tiny::XS::PositiveInt(undef)    => 'no undef';
ok !Type::Tiny::XS::PositiveInt("x")      => 'no "x"';
ok !Type::Tiny::XS::PositiveInt("-")      => 'no "-"';
ok !Type::Tiny::XS::PositiveInt([1])      => 'no [1]';
ok !Type::Tiny::XS::PositiveInt("1.2")    => 'no "1.2"';
ok !Type::Tiny::XS::PositiveInt("1.0")    => 'no "1.0"';
ok !Type::Tiny::XS::PositiveInt("123\n")  => 'no "123\\n"';
ok !Type::Tiny::XS::PositiveInt("\n123")  => 'no "\\n123"';

ok  Type::Tiny::XS::PositiveInt(   2 ** 30  ) => 'large positive int';
ok  Type::Tiny::XS::PositiveInt(   2 ** 31  ) => 'very large positive int';
ok !Type::Tiny::XS::PositiveInt( -(2 ** 30) ) => 'large negative int';
ok !Type::Tiny::XS::PositiveInt( -(2 ** 31) ) => 'very large negative int';
