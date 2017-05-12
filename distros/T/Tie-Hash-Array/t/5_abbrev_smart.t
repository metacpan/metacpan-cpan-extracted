#!perl -Tw

use strict;
use Test::More;

my ( @testwords, %unique_abbrev, @non_unique_abbrev );

BEGIN {
    @testwords = (
        [qw(Sunday Sonntag Dimanche Domenica)],         # 0
        [qw(Monday Montag Lundi Lunedi)],               # 1
        [qw(Tuesday Dienstag Mardi Martedi)],           # 2
        [qw(Wednesday Mittwoch Mercredi Mercoledi)],    # 3
        [qw(Thursday Donnerstag Jeudi Giovedi)],        # 4
        [qw(Friday Freitag Vendredi Venerdi)],          # 5
        [qw(Saturday Samstag Samedi Sabato)]            # 6
    );
    %unique_abbrev = (
        L  => 1,
        W  => 3,
        J  => 4,
        G  => 4,
        F  => 5,
        V  => 5,
        So => 0,
        Su => 0,
        Mo => 1,
        # Lu => 1,
        Tu => 2,
        Ma => 2,
        # We => 3,
        Mi => 3,
        Me => 3,
        Th => 4,
        # Je => 4,
        # Gi => 4,
        # Fr => 5,
        # Ve => 5,
        Sa => 6
    );
    @non_unique_abbrev = ( qw(S D M T Di Do), '' );

    plan tests => 10 + 2 * keys(%unique_abbrev) + 2 * @non_unique_abbrev;
}

BEGIN { use_ok 'Tie::Hash::Abbrev::Smart' }				# test

my $tied = tie my %hash, 'Tie::Hash::Abbrev::Smart';
isa_ok $tied, 'Tie::Hash::Abbrev::Smart', '$tied';			# test
isa_ok tied %hash, 'Tie::Hash::Abbrev::Smart', 'tied %hash';		# test

my @words;
for ( my $i = $#testwords ; $i >= 0 ; --$i ) {
    for ( @{ $testwords[$i] } ) {
        $hash{$_} = $i;
        push @words, $_;
    }
}

cmp_ok keys %hash, '==', @words, 'number of elements';			# test

while ( my ( $key, $value ) = each %unique_abbrev ) {
    ok exists $hash{$key}, "exists() for unique abbreviation '$key'";	# tests
    cmp_ok $hash{$key}, '==', $value, "value for abbreviation '$key'";	# tests
}

for (@non_unique_abbrev) {
    ok !exists $hash{$_}, "!exists() for non-unique abbreviation '$_'";	# tests
    ok !defined $hash{$_}, "!defined() for non-unique abbreviation '$_'";
									# tests
}

$hash{ $non_unique_abbrev[0] } = 'X';
cmp_ok keys %hash, '==', @words + 1,
  'number of keys after insertion of a non-unique abbrevation';		# test
is delete $hash{ $non_unique_abbrev[0] }, 'X', 'delete()';		# test

$hash{foo} = 'bar';
cmp_ok keys %hash, '==', @words + 1, 'number of keys after insertion';	# test
ok eq_array(
    [ delete @hash{ keys %unique_abbrev, 'foo' } ],
    [ (undef) x keys %unique_abbrev, 'bar' ]
  ),
  'delete() in list context';						# test
cmp_ok keys %hash, '==', @words, 'number of elements after deletion';	# test

{									# test
    my @expected;
    while ( my ( $key, $value ) = each %unique_abbrev ) {
        push @expected, ($value) x grep( /^\Q$key/, @words );
    }
    if (
        eq_array [ my @deleted =
              tied(%hash)->delete_abbrev( keys %unique_abbrev ) ],
        \@expected
      )
    {
        cmp_ok keys %hash, '==', @words - @expected,
          'number of elements after deletion';				# test
    }
    else {
        sub list { '(' . join ( ',', map "'$_'", @_ ) . ')' }
        diag 'delete_abbrev(): Expected '
          . list(@expected)
          . ",\nbut got "
          . list @deleted						# test
    }
}
