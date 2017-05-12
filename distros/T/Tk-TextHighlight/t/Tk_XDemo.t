# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use blib;
use Tk;
use Test::More tests => 1;
require Tk::MainWindow;
require Tk::HList;
require Tk::TextHighlight;

if (!$ENV{PERL_MM_USE_DEFAULT} && !$ENV{AUTOMATED_TESTING}) {
	my $main = eval { MainWindow->new };
	if ($main) { 	
		my $ed;
		my $prevstx = 'None';   #WE NEED THIS SINCE browsecmd() IS CALLED *TWICE* - WHEN MOUSE IS PRESSED, AND *AGAIN* IMMEDIATELY WHEN RELEASED:
		my $pl = $main->Scrolled('HList',
			-scrollbars => 'osoe',
			-browsecmd => sub {
				my $stx = shift;

				if ($stx ne $prevstx) {
					my $lang = ($stx eq 'Kate') ? 'Kate::Perl' : $stx;
					$ed->configure(-syntax => $lang, '-rules' => undef);
					select(undef, undef, undef, 0.1);   #SEEM TO SOMETIMES NEED A SLIGHT DELAY FOR SYNTAX CHANGE TO CATCH UP.
					$ed->Load("samples/$stx.test");
					$prevstx = $stx;
				}
			},
		)->pack(
			-side => 'left', 
			-fill => 'y'
		);

		$ed = $main->Scrolled('TextHighlight',
			-wrap => 'none',
			-syntax => 'None',
			-scrollbars => 'se',
		)->pack(
			-side => 'left',
			-expand => 1,
			-fill => 'both',
		);
		my $haveKateInstalled = 0;
		eval "use Syntax::Highlight::Engine::Kate; \$haveKateInstalled = 1; 1";
		if ($haveKateInstalled) {
			my ($sections) = $ed->fetchKateInfo;
			$ed->addKate2ViewMenu($sections);
		}

		my @plugs = $ed->highlightPlugList;
		foreach my $p (@plugs) {
			$pl->add($p,
				-text => $p,
			);
		}
		$main->configure(-menu => $ed->menu);
		$main->MainLoop;
	}
}

BEGIN { use_ok('Tk::TextHighlight::RulesEditor') };   #NEEDED THIS TO MAKE TEST HARNESS PASS?!?!?!
