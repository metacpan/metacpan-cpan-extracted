#!perl -Tw

use strict;
use Test::More;

my ( @testwords, @otherwords );

BEGIN {
    @testwords  = qw(the quick brown fox jumps over a lazy dog.);
    @otherwords = ( '', 'xxx', 'A', 'f' );

    plan tests => 14 + 2 * @testwords + 2 * @otherwords;
}

BEGIN { use_ok 'Tie::Hash::Array' }					# test

my $tied = tie my %hash, 'Tie::Hash::Array';
isa_ok $tied, 'Tie::Hash::Array', '$tied';				# test
isa_ok tied %hash, 'Tie::Hash::Array', 'tied %hash';			# test

{
    my $i = 0;
    for (@testwords) { $hash{$_} = $i++ }
}
{
    my $i = 0;
    for (@testwords) {
        ok exists $hash{$_}, "existance of element '$_'";		# tests
        is $hash{$_}, $i++, "value of element '$_'";			# tests
    }
}

is "@{[keys %hash]}", "@{[sort @testwords]}", 'order of keys';		# test

for (@otherwords) {
    ok !exists $hash{$_}, "non-existance of element '$_'";		# tests
    is $hash{$_}, undef, "undefined value for non-existing element '$_'";
									# tests
}

is @{ [ map exists $hash{$_}, @otherwords ] }, @otherwords,
  'exists() in list context';						# test
is @{ [ @hash{@otherwords} ] }, @otherwords, 'FETCH in list context';	# test

{
    my $keys = keys %hash;
    $hash{ $testwords[0] } = 'foo';
    is $hash{ $testwords[0] }, 'foo', 'redefinition of an element';	# test
    $hash{ $testwords[1] } = undef;
    ok !defined $hash{ $testwords[1] }, 'undefined value for element';	# test
    ok exists $hash{ $testwords[1] },
      'exists() for element with undefined value';			# test
    cmp_ok keys %hash, '==', $keys, 'number of keys after redefinitons';# test
    is delete $hash{ $testwords[2] }, 2, 'return value from delete()';	# test
    ok !defined delete $hash{ $testwords[2] },
      'deleting a non-existant element';				# test
    cmp_ok keys %hash, '==', $keys - 1, 'number of keys after delete';	# test
}

%hash = ();
cmp_ok keys %hash, '==', 0, 'number of keys after clearing the hash';	# test
