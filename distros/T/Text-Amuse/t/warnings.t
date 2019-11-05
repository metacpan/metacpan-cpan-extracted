#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;
my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

use Text::Amuse::Functions qw/muse_to_html/;

my $string = '<em> -->%2$s<--';
my $html = muse_to_html($string . "\n");

ok @warnings, "Warnings found";
like $warnings[0], qr{<\Q$string\E>}, "Chunck found";


