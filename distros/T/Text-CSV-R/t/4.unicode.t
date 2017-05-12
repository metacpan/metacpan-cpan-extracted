#!perl -T
use charnames ":full";

use Text::CSV::R qw(:all);
use Data::Dumper;

use Test::More;
if ($] < 5.008) {
    my $msg = 'Unicode requires Perl > 5.008';
    plan skip_all => $msg;
}
else {
    plan tests => 2;
}    

my $M_ref = read_csv('t/testfiles/unicode.dat', header=>0, encoding => 'utf8');

is($M_ref->[1][1], "U2 should \N{SKULL AND CROSSBONES}", 
    'read unicode file correctly');

open my $IN, '<:encoding(utf8)', 't/testfiles/unicode.dat';
$M_ref = read_csv($IN, header=>0, encoding => 'utf8');
close $IN;

is($M_ref->[1][1], "U2 should \N{SKULL AND CROSSBONES}", 
    'read unicode file correctly');
