use strict;
use warnings;

use Test::More tests => 14;
use Text::Levenshtein::Damerau;

my $tld = Text::Levenshtein::Damerau->new('four');

#Test scalar argument
is( $tld->dld('four'), 0, 'test helper matching');
is( $tld->dld('for'), 1, 'test helper insertion');
is( $tld->dld('fourth'), 2, 'test helper deletion');
is( $tld->dld('fuor'), 1, 'test helper transposition');
is( $tld->dld('fxxr'), 2, 'test helper substitution');
is( $tld->dld('FOuR'), 3, 'test helper case');
is( $tld->dld(''), 4, 'test helper empty');

#Test array reference argument
my @list = ('four','fourty','fourteen','');
is_deeply($tld->dld({ list => \@list }), { four => 0, fourty => 2, fourteen => 4, '', => 4 }, 'test dld(\@array_ref)');


#Test some utf8
use utf8;
no warnings; # Work around for Perl 5.6 and setting output encoding
my $tld_utf8 = Text::Levenshtein::Damerau->new('ⓕⓞⓤⓡ');

#Test utf8 scalar argument
is( $tld_utf8->dld('ⓕⓞⓤⓡ'), 0, 'test helper matching (utf8)');
is( $tld_utf8->dld('ⓕⓞⓡ'), 1, 'test helper insertion (utf8)');
is( $tld_utf8->dld('ⓕⓞⓤⓡⓣⓗ'), 2, 'test helper deletion (utf8)');
is( $tld_utf8->dld('ⓕⓤⓞⓡ'), 1, 'test helper transposition (utf8)');
is( $tld_utf8->dld('ⓕⓧⓧⓡ'), 2, 'test helper substitution (utf8)');

#Test utf8 array reference argument
my @list_utf8 = ('ⓕⓞⓤⓡ','ⓕⓞⓡ','ⓕⓤⓞⓡ','');
is_deeply($tld_utf8->dld({ list => \@list_utf8 }), { 'ⓕⓞⓤⓡ' => 0, 'ⓕⓞⓡ' => 1, 'ⓕⓤⓞⓡ' => 1, '' => 4 }, 'test dld(\@array_ref) (utf8)');


