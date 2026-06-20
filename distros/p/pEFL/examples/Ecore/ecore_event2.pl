use strict;
use warnings;

use pEFL::Ecore;
use pEFL::Ecore::Event::PerlEvent;

use Devel::Peek;

pEFL::Ecore::init();

my $event_type = pEFL::Ecore::EventType->new();

my $handler1 = pEFL::Ecore::EventHandler->add($event_type,\&_event_handler1_cb,"dataone");
my $handler2 = pEFL::Ecore::EventHandler->add($event_type,\&_event_handler2_cb,"datatwo");

my $i = 0;
for ($i=0; $i <= 15; $i++) {
	print "Fire event with type $event_type and data $i\n";
	my $hash = {number => $i};
	my $event = pEFL::Ecore::Event->add_pv($event_type, $hash);
}

print "Start the main loop\n";
pEFL::Ecore::Mainloop::begin();

exit 0;

sub _event_handler1_cb {
	my ($data, $ev_type, $ev_info) = @_;
	
	my $str = $data;
	my $s_ev = pEFL::ev_info2obj($ev_info, "pEFL::Ecore::Event::PerlEvent");
	my $hash = $s_ev->perl_sv();
	my $number = $hash->{number};
	#Devel::Peek::Dump($number);
	
	print "event handler1: number=$number, data=$str\n";
	
	if (($number % 2) == 0) {
		return ECORE_CALLBACK_DONE;
	} 
	
	return ECORE_CALLBACK_PASS_ON;
}

sub _event_handler2_cb {
	my ($data, $ev_type, $ev_info) = @_;
	
	my $hash = pEFL::ev_info2pv($ev_info);
	my $number = $hash->{number};
	
	print "event handler2: number=$number\n";
	
	if ($number == 5) {
		# TODO: EventHandler->data_set|get not yet implemented :-(
	}
	elsif ($number >= 10) {
		print "finish main loop\n";
		pEFL::Ecore::Mainloop::quit();
	}
	
	return ECORE_CALLBACK_DONE
}
