#!/usr/bin/perl

use strict;
use warnings;

use lib './lib/';

use Test::More tests=>8;

BEGIN { use_ok( 'WWW::LiveDepartureBoards' )}

print STDERR "\n >>>\n WARNING!\n The following tests require a live Internet connection.\nThey may also fail if ran when trains are not running.\n >>>\n";

my $farringdon = WWW::LiveDepartureBoards->new({station_code => 'ZFD'});

ok (defined $farringdon);
ok ($farringdon->isa('WWW::LiveDepartureBoards'));

my @details1 = $farringdon->departures();
ok(scalar(@details1));

my @details2 = $farringdon->departures(['Wimbledon','Sutton (Surrey)']);
ok(scalar(@details2));

ok(scalar(@details1) > scalar(@details2));

my $salisbury = WWW::LiveDepartureBoards->new({station_code => 'SAL'});
my @details3 = $salisbury->destination('TIS');
ok(scalar(@details3));

$salisbury = WWW::LiveDepartureBoards->new({station_code => 'SAL'});
my @details4 = $salisbury->destination({station_code => 'tis'});
ok(scalar(@details4));
