use strict;
use warnings;

use Test::More tests => 2;
use Text::Levenshtein::Damerau;

my $tld = Text::Levenshtein::Damerau->new('four');
my @list = ('fourty','fuor','fourth','fourteen','');
is($tld->dld_best_match({ list => \@list }), 'fuor', 'test dld_best_distance');


#Test some utf8
use utf8;
no warnings; # Work around for Perl 5.6 and setting output encoding
my $tld_utf8 = Text::Levenshtein::Damerau->new('ⓕⓞⓤⓡ');
my @list_utf8 = ('ⓕⓤⓞⓡ','ⓕⓞⓤⓡⓣⓗ','ⓕⓧⓧⓡ','');
is($tld_utf8->dld_best_match({ list => \@list_utf8 }), 'ⓕⓤⓞⓡ', 'test dld_best_distance (utf8)');
