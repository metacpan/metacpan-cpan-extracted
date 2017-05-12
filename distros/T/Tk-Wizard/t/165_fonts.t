use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);
use WizTestSettings;

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
	elsif ($^O eq 'freebsd'){
		plan skip_all => "OS=freebsd - testers have reported 'Tk_FreeColor called with bogus color' but no OS to dev on atm";
	}
    else {
        plan tests => 30;
		$mwTest->destroy if Tk::Exists($mwTest);
		use_ok('Tk::Wizard');
		use_ok('WizTestSettings');
    }

foreach my $size ( 4, 8, 12 ) {
	foreach my $font (qw( Arial Courier Times )) {
		my $wizard = Tk::Wizard->new(
			-basefontsize	=> $size,
			-fontfamily		=> $font,
		);
		isa_ok( $wizard, "Tk::Wizard", "Obj for $font $size" );

		WizTestSettings::add_test_pages(
			$wizard,
			-wait => $ENV{TEST_INTERACTIVE} ? -1 : 1,
		);

		$wizard->Show;
		pass("before MainLoop for $font $size");
		MainLoop;
		pass('after MainLoop for $font $size');
	}
}

pass 'after foreach loop';
