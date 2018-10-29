#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Hash>.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Tie_Subset_Testlib;

use Test::More;

BEGIN { use_ok 'Tie::Subset::Hash' }

## no critic (RequireTestLabels)

# tie-ing
my %hash = ( aaa => 123, bbb => 456, ccc => 789, def => 111, ghi => 222, jkl => 333 );
tie my %subset, 'Tie::Subset::Hash', \%hash, [qw/ aaa bbb ccc yyy zzz /];
is_deeply \%subset, {aaa=>123,bbb=>456,ccc=>789};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789,def=>111,ghi=>222,jkl=>333};
isa_ok tied(%subset), 'Tie::Subset::Hash';

subtest 'Tie::Subset' => sub {
	use_ok 'Tie::Subset';
	# basically a copy of the "tie-ing" tests, but with Tie::Subset instead of ::Hash
	my %hh = ( aaa => 123, bbb => 456, ccc => 789, def => 111, ghi => 222, jkl => 333 );
	tie my %ss, 'Tie::Subset', \%hh, [qw/ aaa bbb ccc yyy zzz /];
	is_deeply \%ss, {aaa=>123,bbb=>456,ccc=>789};
	is_deeply \%hh, {aaa=>123,bbb=>456,ccc=>789,def=>111,ghi=>222,jkl=>333};
	isa_ok tied(%ss), 'Tie::Subset::Hash';
};

# Fetching
is $subset{aaa}, 123;
is $subset{bbb}, 456;
is $subset{ccc}, 789;
is $subset{def}, undef;
is $subset{ghi}, undef;
is $subset{jkl}, undef;
is $subset{ddd}, undef;
is $subset{zzz}, undef;

# Storing
ok $subset{aaa}=888;
{
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w = warns {
		ok !defined($subset{ghi}=999);
		ok !defined($subset{eee}=999);
	};
	is grep({/\bassigning to unknown key 'ghi'/i} @w), 1;
	is grep({/\bassigning to unknown key 'eee'/i} @w), 1;
}
is_deeply \%subset, {aaa=>888,bbb=>456,ccc=>789};
is_deeply \%hash, {aaa=>888,bbb=>456,ccc=>789,def=>111,ghi=>222,jkl=>333};
ok $subset{zzz}=777;
is_deeply \%subset, {aaa=>888,bbb=>456,ccc=>789,zzz=>777};
is_deeply \%hash, {aaa=>888,bbb=>456,ccc=>789,def=>111,ghi=>222,jkl=>333,zzz=>777};

# exists
ok exists $subset{bbb};
ok exists $subset{zzz};
ok !exists $subset{yyy};
ok !exists $subset{ghi};

# Iterating
# mostly tested above via the is_deeply checks
ok delete $hash{bbb}; # remove from underlying hash
is_deeply [sort keys %subset], [qw/ aaa ccc zzz /];
is_deeply [sort values %subset], [777,789,888];

# delete-ing
{
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w = warns {
		ok !defined(delete $subset{jkl});
		ok !defined(delete $subset{fff});
	};
	is grep({/\bdeleting unknown key 'jkl'/i} @w), 1;
	is grep({/\bdeleting unknown key 'fff'/i} @w), 1;
}
ok !defined(delete $subset{yyy});
ok delete $subset{ccc};
is_deeply \%subset, {aaa=>888,zzz=>777};
is_deeply \%hash, {aaa=>888,def=>111,ghi=>222,jkl=>333,zzz=>777};
ok delete @subset{qw/aaa zzz/};
is_deeply \%subset, {};
is_deeply \%hash, {def=>111,ghi=>222,jkl=>333};

isa_ok tied(%subset), 'Tie::Subset::Hash';

done_testing;
