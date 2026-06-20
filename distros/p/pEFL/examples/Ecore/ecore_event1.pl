use strict;
use warnings;

use pEFL::Ecore;

pEFL::Ecore::init();

pEFL::Ecore::EventHandler->add(ECORE_EVENT_SIGNAL_EXIT(),\&_quitter,undef);

pEFL::Ecore::Mainloop::begin();

exit 0;

sub _quitter {
	my ($data, $ev_type, $ev_info) = @_;
	print "Leaving already?\n";
	pEFL::Ecore::Mainloop::quit();
	return ECORE_CALLBACK_DONE();
}