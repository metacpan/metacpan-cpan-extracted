=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<Tuple>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 8;

use_ok('Type::Tiny::XS');

my $check = Type::Tiny::XS::get_coderef_for('Tuple[Int,ArrayRef[Int],Undef]');

ok !$check->({})                            => 'no {}';
ok !$check->([])                            => 'no []';
ok !$check->([42])                          => 'no [42]';
ok !$check->([42,[]])                       => 'no [42,[]]';
ok  $check->([42,[],undef])                 => 'yes [42,[],undef]';
ok !$check->([42,["x"],undef])              => 'no [42,["x"],undef]';
ok  $check->([42,[666],undef])              => 'yes [42,[666],undef]';
