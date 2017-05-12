
# $Id: 30_pb.t,v 1.10 2007/08/08 04:22:35 martinthurn Exp $

use strict;

my $VERSION = do { my @r = ( q$Revision: 1.10 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
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
        plan tests => 9;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('WizTestSettings');
    use_ok('Tk::Wizard');
    use_ok('Tk::ProgressBar');

our $PB;     # Index number of page
our $bar;    # Progress bar

my $wizard = new Tk::Wizard(
    -title => "ProgressBar Test",
);
isa_ok( $wizard, "Tk::Wizard" );
$wizard->configure(
    -postNextButtonAction => sub { &postNextButtonAction($wizard); },
    -preNextButtonAction  => sub { &preNextButtonAction($wizard); },
    # -finishButtonAction   => sub { ok(1); $wizard->destroy; 1; },
);
isa_ok( $wizard->cget( -preNextButtonAction ), "Tk::Callback" );

is( 1, $wizard->addPage( sub { page_splash($wizard) } ), "Page one" );
$PB = $wizard->addPage( sub { pb($wizard) } );
is( 2, $PB, "Page two" );
is( 3, $wizard->addPage( sub { page_finish($wizard) } ), "Page three" );
$wizard->Show;
MainLoop;
pass;
exit;

sub page_splash {
    my $wizard = shift;
    my $frame  = $wizard->blank_frame(
        -wait  => 1,
        -title => "Welcome to the Wizard Test 'pb'",
        -text  => "This script tests and hopefully demonstrates the 'postNextButtonAction' feature.\n\n"
          . "When you click Next, a Tk::ProgressBar widget should slowly be udpated."
          . "\n\nHowever in the test, the -wait flag means you don't have to..."
    );
    return $frame;
}


sub page_finish {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -title => "Wizard Test 'pb' Complete",
        -text  => "Thanks, bye.",
    );
    $frame->after( 100, sub { $wizard->forward } );
    return $frame;
}

sub pb {
    my $wizard = shift;
    my $frame  = $wizard->blank_frame(
#        -wait => 1, ### Using this with a progress bar really messes things up!, How so?
        -title    => "postNextButtonAction Test",
        -subtitle => "Updating a progress bar in real-time",
        -text     => "The bar should fill, thanks to calling the 'update' method upon the Wizard, "
          . "and the Next button should only become available when the job is done."
    );
    $frame->configure( -bg => 'magenta' );    # for debugging
    $bar = $frame->ProgressBar(
        -colors      => [ 0 => 'yellow' ],
        -borderwidth => 2,
        -relief      => 'sunken',
        -from        => 0,
        -to          => 3,
        -height      => 15,
      )->pack(
        -padx   => 10,
        -pady   => 10,
        -side   => 'top',
        -fill   => 'x',
        -expand => 1
      );
    $wizard->{backButton}->configure( -state => 'disable' );
    $wizard->{nextButton}->configure( -state => 'disable' );
    $wizard->update;
    return $frame;
}

sub preNextButtonAction {
    my $wizard = shift;
    # diag('this is preNextButtonAction');
    1;
}

sub postNextButtonAction {

    my $wizard = shift;
    my $iPage  = $wizard->currentPage;

    # diag(qq'this is postNextButtonAction on page $iPage');
    if ( $iPage == $PB ) {

        # diag('step 0');
        $wizard->update;

        # diag('step 1');
        foreach my $i ( 1 .. $bar->cget( -to ) ) {
            sleep 1;
            $bar->value($i);

            # diag('step 2.1');
            $bar->update;
        }

        # diag('step 3');
        $wizard->{nextButton}->configure( -state => "normal" );

        # diag('step 4');
        $wizard->{nextButton}->after( 100, sub { $wizard->forward } );

        # diag('step 5');
    }

    # diag('step 6');
    return 1;
}

__END__

