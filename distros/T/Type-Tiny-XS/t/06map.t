=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<Map>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 7;

use_ok('Type::Tiny::XS');

my $check = Type::Tiny::XS::get_coderef_for('Map[Int,Str]');

ok  $check->({})                            => 'yes {}';
ok  $check->({ 1 => "foo", 2 => "bar" })    => 'yes { 1=>"foo", 2=>"bar" }';
ok !$check->({ 1 => "foo", 2 => undef })    => 'no { 1=>"foo", 2=>undef }';
ok !$check->({ 1 => "foo", z => "bar" })    => 'no { 1=>"foo", z=>"bar" }';
ok !$check->([])                            => 'no []';
ok !$check->(undef)                         => 'no undef';

