use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 1.14 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);

my $cap;

    eval { require IO::Capture::Stderr::Extended };
	$cap = !$@;

	my $mwTest;
	eval { $mwTest = Tk::MainWindow->new };
	if ($@) {
		plan skip_all => 'Test irrelevant without a display';
	}
	else {
		plan tests => 28
	}
	$mwTest->destroy if Tk::Exists($mwTest);
	use_ok('WizTestSettings');
	use_ok('Tk::Wizard');


my $WAIT = 1;
my $capture;

ZERO: {
	my $wizard = Tk::Wizard->new;
    isa_ok( $wizard, "Tk::Wizard" );
    is( 1, $wizard->addSplashPage( -wait => $WAIT ), 'One page' );

	# FAIL Tk-Wizard-2.133 amd64-freebsd 6.2-prerelease
	# t/112_AutoDestroy........# Looks like you planned 28 tests but only ran 4.
	# Looks like your test died just after 4.
	# dubious
	# 	Test returned status 255 (wstat 65280, 0xff00)
	# DIED. FAILED tests 5-28
	# 	Failed 24/28 tests, 14.29% okay

    if ($cap){
		$capture = IO::Capture::Stderr::Extended->new;
		$capture->start;
	    $wizard->Show;
	    $capture->stop;
	} else {
		no warnings "Tk::Wizard";
	    eval { $wizard->Show };
	}

    SKIP: {
		skip "No IO Capture", 1 unless $cap;
    	is( $capture->matches(qr'Showing a Wizard with 1 page!'), 1, 'got warning' );
	}
    MainLoop;
    pass('Pretest');
}


ONE: {
    my $wizard = Tk::Wizard->new( -title => "Test", );
    isa_ok( $wizard, "Tk::Wizard" );
    is( 1, $wizard->addPage( sub { $wizard->blank_frame( -wait => $WAIT ) } ), 'pre page' );
    is( 2, $wizard->addPage( sub { page_splash($wizard) } ), 'p1' );
    is( 3, $wizard->addPage( sub { page_finish($wizard) } ), 'p2' );

    $wizard->Show;
    MainLoop;

    isa_ok( $wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle" );
    pass('end of ONE');
}



TWO: {
    my $wizard = new Tk::Wizard( -title => "Test", );
    isa_ok( $wizard, "Tk::Wizard" );
    $wizard->configure(
        -preFinishButtonAction => sub { ok( 1, 'TWO preFinish' ); },
        -finishButtonAction    => sub {
            ok( 1, 'TWO finish' );
            $wizard->destroy;
            1;
        },
    );
    isa_ok( $wizard->cget( -finishButtonAction ), "Tk::Callback" );
    is( 1, $wizard->addPage( sub { page_splash($wizard) } ), "TWO page one" );
    is( 2, $wizard->addPage( sub { page_finish($wizard) } ), "TWO page two" );

    if ($cap){
		$capture = IO::Capture::Stderr::Extended->new;
		$capture->start;
	    $wizard->Show;
	    $capture->stop;
	} else {
		no warnings "Tk::Wizard";
	    $wizard->Show;
	}

    SKIP: {
		skip "No IO Capture", 1 unless $cap;
		is( $capture->matches(qr'Showing a Wizard with 2 pages!'), 1, 'got warning' )
			or diag join",", $capture->all_screen_lines();
	}

    MainLoop;
    pass( 'Done TWO' );
}

THREE: {
    my $wizard = new Tk::Wizard( -title => "Test", );
    isa_ok( $wizard, "Tk::Wizard" );
    $wizard->configure(
        -preFinishButtonAction => sub { ok( 1, 'THREE preFinish' ); },
        -finishButtonAction    => sub { ok( 1, 'THREE finish' ); },
    );
    is( 1, $wizard->addPage( sub { page_splash($wizard) } ), 'THREE addPage 1' );
    is( 2, $wizard->addPage( sub { page_finish($wizard) } ), 'THREE addPage 2' );

    if ($cap){
		$capture = IO::Capture::Stderr::Extended->new;
		$capture->start;
	    $wizard->Show;
	    $capture->stop;
	} else {
		no warnings "Tk::Wizard";
	    $wizard->Show;
	}

	SKIP: {
		skip "No IO Capture", 1 unless $cap;
		is( $capture->matches(qr'Showing a Wizard with 2 pages!'), 1, 'got warning' )
			or diag join",", $capture->all_screen_lines();
	}

    MainLoop;
    isa_ok( $wizard, "Tk::Wizard", "Wizard survived CloseWindowEventCycle" );
    pass( 'end of THREE block' );
}


sub page_splash {
    my $wizard = shift;
    my $frame = $wizard->blank_frame( -wait => $WAIT );
    return $frame;
}

sub page_finish {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Wizard Test 'pb' Complete",
        -text  => "Thanks for running this test.",
    );
    return $frame;
}

__END__

