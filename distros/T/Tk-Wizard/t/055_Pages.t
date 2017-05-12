use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.01 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use File::Path;
use Test::More;
use Tk;
use lib qw(../lib . t/);
use Cwd;

# $ENV{TEST_INTERACTIVE} = 1;

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok("Tk::Wizard" => 2.084);
    use_ok('WizTestSettings');

my $WAIT   		= $ENV{TEST_INTERACTIVE} ? 0 : 111;

chdir ".." if getcwd =~ /\Wt$/;




my $page_count	= 0;
my $wizard = Tk::Wizard->new( -title => "Add Page Test", );
isa_ok( $wizard, 'Tk::Wizard' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

my $SPLASH = $wizard->addSplashPage(
	-wait     => $WAIT,
	-title    => "Add Page Test",
	-subtitle => "Testing Tk::Wizard $Tk::Wizard::VERSION",
	-text     => "Testing call to addPage without a code ref."
);
is( $SPLASH, 1, 'Splash page is first' );
$page_count++;

ok(
	$wizard->addPage(
		-wait     => $WAIT,
		-title    => "Middle Page",
		-subtitle => "Nothing to see here...",
		-text     => "Please report bugs via rt.cpan.org"
	),
	'Added final page 2'
);
$page_count++;

ok(
	$wizard->addPage(
		-wait     => $WAIT,
		-title    => "Finished",
		-subtitle => "Click 'Finish' to kill the Wizard.",
		-text     => "Please report bugs via rt.cpan.org"
	),
	'Added final page 3'
);
$page_count++;

isa_ok( $wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{_pages} } ), $page_count, 'Number of pages' );

foreach my $iPage ( 1 .. $page_count ) {
	isa_ok( $wizard->{_pages}->[ $iPage - 1 ], 'CODE', "Page $iPage in list" );
}

ok( $wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );



