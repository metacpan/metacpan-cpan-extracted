use strict;
use warnings;
my $VERSION = do { my @r = ( q$Revision: 2.077 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use lib qw(../lib . t/);


my $mwTest;
eval { $mwTest = Tk::MainWindow->new };
if ($@) {
    plan skip_all => 'Test irrelevant without a display';
}
else {
    plan tests => 6;
}
$mwTest->destroy if Tk::Exists($mwTest);

use_ok('Tk::Wizard');
use_ok('WizTestSettings');

foreach my $style ( qw(top 95)) {

    my $wizard = Tk::Wizard->new(
        -style      => $style,
    );

    isa_ok( $wizard, "Tk::Wizard" );

    WizTestSettings::add_test_pages(
		$wizard,
		-wait => $ENV{TEST_INTERACTIVE} ? -1 : 1,
	);

    eval { $wizard->Show };

    if ($@){
		fail "Failed to show";
		warn $@;
	} else {
		MainLoop;
		pass 'after MainLoop';
	}
}

