use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);

    eval { require IO::Capture::Stderr::Extended };
    if ( $@ ) {
        plan skip_all => 'Test requires IO::Capture::Stderr::Extended';
    } else {
		my $mwTest;
		eval { $mwTest = Tk::MainWindow->new };
		if ($@) {
			plan skip_all => 'Test irrelevant without a display';
		}
		else {
			plan tests => 3;
			$mwTest->destroy if Tk::Exists($mwTest);

			use_ok('Tk::Wizard'=>':old') or BAIL_OUT;
			use_ok('WizTestSettings');
		}
	}


$ENV{TEST_INTERACTIVE} = 0;
my $RadioChoice = 'N';
my $Count		= -1;
my $WAIT		= $ENV{TEST_INTERACTIVE} ? -1 : 100;

my $wiz = Tk::Wizard->new(
	-title => 'Test 300_next.t',
);

$wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait => $WAIT,
			-title => "Page 1",
			-text  => "Checks a one-time bug in Wizard::_NextButtonEventCycle.",
		);
	},
	-preNextButtonAction => sub{1}
);

$wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait => $WAIT,
			-title => "Page 2",
			-text  => "Testing preNextButtonAction counter",
		);
	},
	-preNextButtonAction  => sub {
		# Returns true (to continue) on second call
		$Count ++;
		# On first calling...
		if ($Count == 0){
			# ...click the next button after a short time
			$wiz->Subwidget('nextButton')->after(2000,
				sub {
					# INFO "X" x 50;
					$wiz->Subwidget('nextButton')->invoke
				},
			);
		}
		return $Count;
	},
);


$wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait => $WAIT,
			-title => "Final Page (3)",
			-text  => "Done."
		);
	},
);



$wiz->Show;
MainLoop;

ok("Finished");

exit;

=head1 NAME

300_next.t

=head1 DESCRIPTION

See L<http://rt.cpan.org/Ticket/Display.html?id=37333|http://rt.cpan.org/Ticket/Display.html?id=37333>

Checks a one-time bug in C<Wizard::_NextButtonEventCycle>.

=cut



