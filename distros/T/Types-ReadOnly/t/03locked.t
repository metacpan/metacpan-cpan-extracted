=pod

=encoding utf-8

=head1 PURPOSE

Test the C<Locked> type constraint wrapper.

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
use Test::TypeTiny -all;
use Test::Fatal;

use Types::Standard -types;
use Types::ReadOnly -types;
use Hash::Util ();

my $my_hash = HashRef[ Undef ];
my $my_lock = Locked[ $my_hash ];
my $foo     = $my_lock->create_child_type(name => 'Foo');

isa_ok(Locked, 'Type::Tiny');
isa_ok($my_lock, 'Type::Tiny');

ok( $my_lock->is_a_type_of(Locked), '$my_lock->is_a_type_of(Locked)');
ok( $my_lock->is_a_type_of($my_hash), '$my_lock->is_a_type_of($my_hash)');
ok( $my_lock->is_strictly_a_type_of(Locked), '!$my_lock->is_strictly_a_type_of(Locked)');
ok(!$my_lock->is_strictly_a_type_of($my_hash), '$my_lock->is_strictly_a_type_of($my_hash)');

ok( $foo->is_a_type_of(Locked), '$foo->is_a_type_of(Locked)');
ok( $foo->is_a_type_of($my_hash), '$foo->is_a_type_of($my_hash)');
ok( $foo->is_strictly_a_type_of(Locked), '!$foo->is_strictly_a_type_of(Locked)');
ok(!$foo->is_strictly_a_type_of($my_hash), '$foo->is_strictly_a_type_of($my_hash)');

my $hash1 = { foo => undef };
my $hash2 = { foo => undef };  &Hash::Util::lock_keys($hash2);
my $hash3 = { foo => "xxx" };  &Hash::Util::lock_keys($hash3);

like(
	exception { my $bar = $hash2->{bar} },
	qr{^Attempt to access disallowed key 'bar' in a restricted hash},
	'hashes can be locked',
);

should_pass($hash1, $my_hash);
should_pass($hash2, $my_hash);
should_fail($hash3, $my_hash);
should_fail($hash1, $my_lock);
should_pass($hash2, $my_lock);
should_fail($hash3, $my_lock);

SKIP: {
	skip 'need to make _strict_check work via recursion!!', 3 if EXTENDED_TESTING;
	should_fail($hash1, $foo);
	should_pass($hash2, $foo);
	should_fail($hash3, $foo);
};

my $my_dict     = Dict[ foo => Int, bar => Optional[Int] ];
my $locked_dict = Locked[ $my_dict ];

ok($locked_dict->can_be_inlined, "$locked_dict can be inlined");
ok($locked_dict->coercion->can_be_inlined, "$locked_dict coercion can be inlined");

my $dict1 = { foo => 1 };  &Hash::Util::lock_keys($dict1, qw/foo/);
my $dict2 = { foo => 1 };  &Hash::Util::lock_keys($dict2, qw/foo bar/);
my $dict3 = { foo => 1 };  &Hash::Util::lock_keys($dict3, qw/foo bar baz/);

should_pass($_, $my_dict) for $dict1, $dict2, $dict3;
should_fail($dict1, $locked_dict);
should_pass($dict2, $locked_dict);
should_fail($dict3, $locked_dict);

my $new = $locked_dict->coerce({ foo => 42 });
ok( Types::ReadOnly::_hashref_locked($new), 'coercion locks keys' );
is_deeply(
	[ sort { $a cmp $b } &Hash::Util::legal_keys($new) ],
	[ qw/ bar foo / ],
	'coercion locks the correct keys'
);

my $Rounded   = Int->plus_coercions(Num, q{int($_)});
my $Challenge = Locked[ Dict[ a => $Rounded, b => Optional[$Rounded] ] ];

my $x = $Challenge->coerce({ a => 1.1, b => 2.2 });
my $y = $Challenge->coerce({ a => 3.3 });

ok( Types::ReadOnly::_hashref_locked($_), 'coercion locks keys' ) for $x, $y;
is_deeply(
	[ sort { $a cmp $b } &Hash::Util::legal_keys($_) ],
	[ qw/ a b / ],
	'coercion locks the correct keys'
) for $x, $y;
is($x->{a}, 1, 'required key coerced properly');
is($x->{b}, 2, 'optional key coerced properly');
is($y->{a}, 3, 'required key coerced properly');
ok(!exists $y->{b}, 'missing key ignored during coercion');

done_testing;
