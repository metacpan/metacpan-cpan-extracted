use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

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
			plan tests => 7;

			$mwTest->destroy if Tk::Exists($mwTest);

			use_ok('Tk::Wizard'=>':old') or BAIL_OUT;
			use_ok('WizTestSettings');
		}
	}

# $ENV{TEST_INTERACTIVE} = undef;

my $wiz = Tk::Wizard->new(
	-background => 'blue',
	-style      => 'top',
	-debug		=> 1,
);

isa_ok( $wiz, "Tk::Wizard" );

$wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait     => $ENV{TEST_INTERACTIVE}? 0 : 1,
			-title    => "Intro Page Title",
			-subtitle => "Intro Page Subtitle",
			-text     => "A two page wizard should issue a warning if warnings are enabled for the category",
		);
	}
);

$wiz->addPage(
	sub {
		$wiz->blank_frame(
			-wait     => $ENV{TEST_INTERACTIVE}? 0 : 1,
			-title    => "Intro Page Title",
			-subtitle => "Intro Page Subtitle",
			-text     => "A two page wizard should issue a warning if warnings are enabled for the category",
		);
	}
);

my $capture = IO::Capture::Stderr::Extended->new;
$capture->start;
$wiz->Show;
$capture->stop;
is( $capture->matches(qr/Showing a Wizard with 2 pages/), 1, 'few pages warning' );

pass('before MainLoop');
MainLoop;
pass('after MainLoop');

pass('after foreach loop');
exit 0;

__END__
