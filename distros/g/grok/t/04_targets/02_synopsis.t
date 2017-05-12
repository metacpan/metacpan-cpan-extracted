use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 4;

my $grok = catfile('bin', 'grok');

my $s02        = qx/$^X $grok s02/;
my $s04        = qx/$^X $grok s04-control/;
my $s26        = qx/$^X $grok s26/;
my $s32_except = qx/$^X $grok s32-except/;

like($s02, qr/Synopsis 2/, "Got S02");
like($s04, qr/Synopsis 4/, "Got S04");
TODO: {
    local $TODO = 'Perl6::Perldoc might not be able to parse this';
    like($s26, qr/Synopsis 26/, "Got S26");
};
like($s32_except, qr/Synopsis 32: Setting Library - Exception/, "Got S32-exception");
