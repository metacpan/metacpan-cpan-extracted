#!/usr/bin/perl 

use Test::More tests => 23;
use FindBin;
use strict;
use warnings;
use VANAMBURG::PacketFactory;

use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok('VANAMBURG::PacketFactory') || print "Bail out!";
}
my $packet = VANAMBURG::PacketFactory->create_packet("AC,AS,AD,AH");
isa_ok($packet, 'VANAMBURG::Packet');
ok($packet->card_count == 4, '4 cards');
ok($packet->get_card(0)->abbreviation eq 'AC', 'ac is first');
ok($packet->get_card(1)->abbreviation eq 'AS', 'as is second');
ok($packet->get_card(2)->abbreviation eq 'AD', 'ad is third');
ok($packet->get_card(3)->abbreviation eq 'AH', 'ah is fourth');

my $csv = $packet->to_abbreviation_csv_string;
ok($csv eq "AC,AS,AD,AH", 'csv abbrev string from packet');

my $stack = VANAMBURG::PacketFactory->create_stack("AC,AS,AD,AH");
isa_ok($stack, 'VANAMBURG::Packet');
ok($stack->card_count == 4, '4 cards');
ok($stack->get_card(0)->stack_number == 1, 'stack number 1');
ok($stack->get_card(1)->stack_number == 2, 'stack number 2');
ok($stack->get_card(2)->stack_number == 3, 'stack number 3');
ok($stack->get_card(3)->stack_number == 4, 'stack number 4');




my $aronson = VANAMBURG::PacketFactory->create_stack_aronson; 
ok($aronson->card_count == 52, 'aronson card count');

my $joyal_chased = VANAMBURG::PacketFactory->create_stack_joyal_chased;
ok($joyal_chased->card_count == 52, 'joyal chased card count');

my $joyal_shocked = VANAMBURG::PacketFactory->create_stack_joyal_shocked;
ok($joyal_shocked->card_count == 52, 'joyal shocked card count');

my $tamariz = VANAMBURG::PacketFactory->create_stack_mnemonica;
ok($tamariz->card_count == 52, 'tamariz card count');

my $osterlind = VANAMBURG::PacketFactory->create_stack_breakthrough_card_system;
ok($osterlind->card_count == 52, 'osterlind card count');

my $si_shocked_3 = VANAMBURG::PacketFactory->create_si_stebbins_shocked_3step;
ok($si_shocked_3->card_count == 52, 'si shocked 3 card count');

my $si_shocked_4 = VANAMBURG::PacketFactory->create_si_stebbins_shocked_4step;
ok($si_shocked_4->card_count == 52, 'si shocked 4 card count');

my $si_chased_3 = VANAMBURG::PacketFactory->create_si_stebbins_chased_3step;
ok($si_chased_3->card_count == 52, 'si chased 3 card count');

my $si_chased_4 = VANAMBURG::PacketFactory->create_si_stebbins_chased_4step;
ok($si_chased_4->card_count == 52, 'si chased 4 card count');
