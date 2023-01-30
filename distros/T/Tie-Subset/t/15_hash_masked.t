#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Hash::Masked>.

=head1 Author, Copyright, and License

Copyright (c) 2023 Hauke Daempfling (haukex@zero-g.net).

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

BEGIN { use_ok 'Tie::Subset::Hash::Masked' }

## no critic (RequireTestLabels)

# tie-ing
my %hash = ( aaa => 123, bbb => 456, ccc => 789, def => 111, ghi => 222, jkl => 333 );
tie my %masked, 'Tie::Subset::Hash::Masked', \%hash, [qw/ aaa bbb ccc yyy zzz /];
is_deeply \%masked, {def=>111,ghi=>222,jkl=>333};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789,def=>111,ghi=>222,jkl=>333};
isa_ok tied(%masked), 'Tie::Subset::Hash::Masked';

# Fetching
is $masked{aaa}, undef;
is $masked{bbb}, undef;
is $masked{ccc}, undef;
is $masked{def}, 111;
is $masked{ghi}, 222;
is $masked{jkl}, 333;
is $masked{ddd}, undef;
is $masked{zzz}, undef;

# Storing
ok $masked{def}=888;
{
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w = warns {
		ok !defined($masked{aaa}=999);
		ok !defined($masked{yyy}=999);
	};
	is grep({/\bassigning to masked key 'aaa'/i} @w), 1;
	is grep({/\bassigning to masked key 'yyy'/i} @w), 1;
}
is_deeply \%masked, {def=>888,ghi=>222,jkl=>333};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789,def=>888,ghi=>222,jkl=>333};
ok $masked{xxx}=777;
is_deeply \%masked, {def=>888,ghi=>222,jkl=>333,xxx=>777};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789,def=>888,ghi=>222,jkl=>333,xxx=>777};

# exists
ok exists $masked{ghi};
ok exists $masked{xxx};
ok !exists $masked{aaa};
ok !exists $masked{zzz};
ok !exists $masked{lll};

# Iterating
# mostly tested above via the is_deeply checks
ok delete $hash{jkl}; # remove from underlying hash
is_deeply [sort keys %masked], [qw/ def ghi xxx /];
is_deeply [sort values %masked], [222,777,888];

# Scalar
SKIP: {
	skip "test fails on pre-5.8.9 Perls", 1 if $] lt '5.008009';
	# Since it's mostly here for code coverage, it's ok to skip it
	# scalar(%hash) really only gets useful on Perl 5.26+ anyway (returns the number of keys)
	if ( $] lt '5.026' )
		{ is scalar(%masked), scalar( %{tied(%masked)->{hash}} ) }
	else
		{ is scalar(%masked), 3 }
}

# delete-ing
{
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w = warns {
		ok !defined(delete $masked{ccc});
		ok !defined(delete $masked{zzz});
	};
	is grep({/\bdeleting masked key 'ccc'/i} @w), 1;
	is grep({/\bdeleting masked key 'zzz'/i} @w), 1;
}
ok !defined(delete $masked{fff});
ok delete $masked{ghi};
is_deeply \%masked, {def=>888,xxx=>777};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789,def=>888,xxx=>777};
ok delete @masked{qw/def xxx/};
is_deeply \%masked, {};
is_deeply \%hash, {aaa=>123,bbb=>456,ccc=>789};

isa_ok tied(%masked), 'Tie::Subset::Hash::Masked';

# Errors
ok exception { tie my %foo, 'Tie::Subset::Hash::Masked', {x=>1,y=>2}, ['x'], 'foo' };
ok exception { tie my %foo, 'Tie::Subset::Hash::Masked', [], ['x'] };
ok exception { tie my %foo, 'Tie::Subset::Hash::Masked', {x=>1,y=>2}, {} };
ok exception { tie my %foo, 'Tie::Subset::Hash::Masked', {x=>1,y=>2}, [undef] };
ok exception { tie my %foo, 'Tie::Subset::Hash::Masked', {x=>1,y=>2}, [\'x'] };

# Not Supported
{
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		%masked = ();
	};
}

# Untie
untie %masked;
is_deeply \%masked, {};

done_testing;
