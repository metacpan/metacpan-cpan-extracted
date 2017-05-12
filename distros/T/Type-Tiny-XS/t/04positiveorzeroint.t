=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<PositiveOrZeroInt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 16;

use_ok('Type::Tiny::XS');

ok  Type::Tiny::XS::PositiveOrZeroInt(0)        => 'yes 0';
ok  Type::Tiny::XS::PositiveOrZeroInt("0")      => 'yes "0"';
ok  Type::Tiny::XS::PositiveOrZeroInt(123)      => 'yes 123';
ok  Type::Tiny::XS::PositiveOrZeroInt("123")    => 'yes "123"';
ok !Type::Tiny::XS::PositiveOrZeroInt(-123)     => 'no -123';
ok !Type::Tiny::XS::PositiveOrZeroInt("-123")   => 'no "-123"';
ok !Type::Tiny::XS::PositiveOrZeroInt("")       => 'no ""';
ok !Type::Tiny::XS::PositiveOrZeroInt(undef)    => 'no undef';
ok !Type::Tiny::XS::PositiveOrZeroInt("x")      => 'no "x"';
ok !Type::Tiny::XS::PositiveOrZeroInt("-")      => 'no "-"';
ok !Type::Tiny::XS::PositiveOrZeroInt([1])      => 'no [1]';
ok !Type::Tiny::XS::PositiveOrZeroInt("1.2")    => 'no "1.2"';
ok !Type::Tiny::XS::PositiveOrZeroInt("1.0")    => 'no "1.0"';
ok !Type::Tiny::XS::PositiveOrZeroInt("123\n")  => 'no "123\\n"';
ok !Type::Tiny::XS::PositiveOrZeroInt("\n123")  => 'no "\\n123"';
