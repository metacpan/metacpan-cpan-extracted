use warnings;
use strict;
my $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
use ExtUtils::testlib;
use FileHandle;
use Test::More;
use Tk;
use lib qw(../lib . t/);

    eval { require IO::Capture::Stderr::Extended };
    if ( $@ ) {
        plan skip_all => 'Test requires IO::Capture::Stderr::Extended: '.$@;
    }
    else {
		my $mwTest;
		eval { $mwTest = Tk::MainWindow->new };
		if ($@) {
			plan skip_all => 'Test irrelevant without a display';
		}
		else {
			plan tests => 12;
		}
		$mwTest->destroy if Tk::Exists($mwTest);
		use_ok('Tk::Wizard');
	    use_ok('WizTestSettings');
	}

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 555;

my $oICS   = IO::Capture::Stderr::Extended->new;
my $wizard = Tk::Wizard->new( -title => $0, );
isa_ok( $wizard, "Tk::Wizard" ) or BAIL_OUT;

$wizard->configure( -preNextButtonAction => sub { &preNext($wizard) } );
is(
    $wizard->addSplashPage(
        -wait  => 100,
        -title => "Page 1",
    ),
    1,
    'splash is 1'
);

my $the_chosen_one;
is(
    $wizard->addSingleChoicePage(
        -title	  => 'Page 2',
        -wait     => $WAIT,
        -variable => \$the_chosen_one,
        -choices  => [
            {
                -title    => 'This is the only choice',
                -subtitle => 'My subtitle',
                -value    => 20,
            },
        ],
    ),
    2,
    'page is 2'
);

is(
    $wizard->addSingleChoicePage(
        -title	  => 'Page 3',
        -wait     => $WAIT,
        -variable => \$the_chosen_one,
        -choices  => [
            {
                -title    => 'This is choice 1',
                -value    => 30,
                -subtitle => 'My subtitle is longer than my title',
                -selected => 1,
            },
            {
                -title    => 'This is choice 2',
                -subtitle => 'My subtitle is longer than my title',
                -value    => 99,
            },
        ],
    ),
    3,
    'page is 3'
);

is(
    $wizard->addSingleChoicePage(
        -title	  => 'Page 4',
        -wait     => $WAIT,
        -variable => \$the_chosen_one,
        -choices  => [
            {
                -title    => 'This is wrong choice 1',
                -subtitle => 'lil sub',
                -value    => 99,
            },
            {
                -title    => 'This is correct choice',
                -value    => 40,
                -selected => 1,
            },
            {
                -title    => 'This is wrong choice 2',
                -subtitle => 'lil sub',
                -value    => 98,
            },
        ],
    ),
    4,
    'page is 4'
);

$wizard->addSplashPage(
    -title	=> 'Page 5',
    -wait  	=> 100,
    -text  	=> "Thanks for testing!"
);

$oICS->start;
$wizard->Show;
$oICS->stop;

pass('after Show');
MainLoop();
pass('after MainLoop');

sub preNext {
    my $wiz   = shift;
    my $iPage = $wiz->currentPage;
    if ( ( 1 < $iPage ) && ( $iPage < 5 ) ) {
        is( $the_chosen_one, $iPage * 10, qq{page $iPage correct chosen value} );
    }
    return 1;
}

__END__

