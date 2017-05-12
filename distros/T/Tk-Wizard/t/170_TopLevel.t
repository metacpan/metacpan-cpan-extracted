
# $Id: 70_TopLevel.t,v 1.10 2007/08/08 04:20:43 martinthurn Exp $

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
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard');
    use_ok('WizTestSettings');

my $VERSION = do { my @r = ( q$Revision: 1.10 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use strict;
use FileHandle;
autoflush STDOUT 1;
use Cwd;

my $root = cwd =~ /\/t$/ ? '..' : '.';

use vars qw/$GET_DIR $user_chosen_dir $SPLASH/;

our $WAIT = 100;
my $MW;

#
# Instantiate Wizard
#
my $looped = 0;
for my $inst ( 1 .. 2 ) {
    my $wizard;
    if ( $inst == 1 ) {
        $MW     = Tk::MainWindow->new;
        $wizard = $MW->Wizard(
            -title => "Test v$VERSION For Wizard $Tk::Wizard::VERSION",

            # -subtitle => 'with explicit parent MainWindow',
            -style => 'top',
        );
    }
    else {
        $wizard = Tk::Wizard->new(
            -title => "Test v$VERSION For Wizard $Tk::Wizard::VERSION",

            # -subtitle => 'without explicit parent',
            -style => 'top',
        );
    }
    isa_ok( $wizard, "Tk::Wizard" );

    #
    # Create pages
    #
    $SPLASH = $wizard->addPage( sub { page_splash( $wizard, $looped ) } );
    is( $SPLASH, 1 );
    is( 2, $wizard->addPage( sub { page_one($wizard) } ) );
    my $p = $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait     => $WAIT,
                -title    => "Finished",
                -subtitle => "Please press Finish to leave the Wizard.",
                -text     => "If you saw some error messages, they came from Tk::DirTree, and show "
                  . "that some of your drives are inacessible - perhaps a CD-ROM drive without "
                  . "media.  Such warnings can be turned off - please see the documentation for details."
            );
        }
    );
    ok($p);

    #isa_ok($wizard->parent, "Tk::Wizard");
    ok(1);
    $wizard->Show;
    if ( $inst == 1 ) {
        ok( defined $MW, 'mw here' );
        isa_ok( $MW, 'Tk::MainWindow' );
        $MW->destroy;
    }
    MainLoop();
    ok(1);
    undef $wizard;
}    # for

exit;

sub page_splash {
    my ( $wizard, $looped ) = ( shift, shift );
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait     => $WAIT,
        -title    => ( $looped == 0 ? "Welcome to the Wizard" : "Testing the Old Style" ),
        -subtitle => "It's just a test",
        -text =>
"This Wizard is a simple test of the Wizard, and nothing more.\n\nNo software will be installed, but you'll hopefully see a licence agreement page, and a directory listing page.",
    );
    return $frame;
}

sub page_one {
    my $wizard = shift;
    my $frame  = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Page One",
        -subtitle =>
'The text found in the -subtitle parameter appears here on the screen; quite a long string I trust: and sadly ugly still',
        -text =>
"-text goes here.\n\nTk::Wizard is but a baby, and needs your help to grow into a happy, healthy, well-adjusted widget. Sadly, I've only been using Tk::* for a couple of weeks, and all this packing takes a bit of getting used to. And I'm also working to a deadline on the project which bore this Wizard, so please excuse some coding which is currently rather slip-shod, but which be tightened in the future."
    );
    return $frame;
}

sub page_bye {
    my $wizard = shift;

    # diag('start page_bye');
    my $frame = $wizard->blank_frame(
        -wait  => $WAIT,
        -title => "Page Bye!",
        -text  => "Thanks for testing!"
    );
    return $frame;
}    # page_bye

__END__

