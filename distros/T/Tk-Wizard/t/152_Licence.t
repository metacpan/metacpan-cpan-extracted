use strict;
use warnings;

my $VERSION = 1.16;

use ExtUtils::testlib;
use File::Path;
use Test::More;
use Tk;
use lib qw( lib t/);

use Cwd;

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan "no_plan";    # TODO Can't count tests atm
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok("Tk::Wizard::Installer");
    use_ok('WizTestSettings');

my $WAIT   = $ENV{TEST_INTERACTIVE} ? 0 : 111;
my @form = qw( 1 2 );
my @dest = qw( 3 4 );

our $TEMP_DIR = 't/tmp';
mkdir( $TEMP_DIR, 0777 );
if ( !-d $TEMP_DIR ) {
    mkdir $TEMP_DIR or bail_out($!);
}

my $testdir = "$TEMP_DIR/__perltk_wizard";
if ( !-d $testdir ) {
    mkdir $testdir or bail_out($!);
}

for (@form) {
    my $form = "$testdir/$_";
    local *OUT;
    ok( open( OUT, '>', $form ), qq'opened $form for write' ) or bail_out($!);
    ok(
        print( OUT "Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n"
              . scalar(localtime) . "\n\n"
        ),
        qq'wrote contents to $form'
    );
    ok( close OUT, qq'closed $form' );
}

for (@dest) {
    my $sDest = "$testdir/$_";
    unlink $sDest;
    # Make sure destination files do NOT exist:
    ok( !-e $sDest, qq'destination file $sDest does not exist before test' );
}

if ( $ENV{TEST_INTERACTIVE} ) {
    # Add some stuff that will fail, so we can see what exactly happens:
    unshift @form, 'no_such_file';
    unshift @dest, 'no_such_dir';
}

my $page_count = 0;
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok( $wizard->configure( -finishButtonAction => sub { ok( 1, 'Finished' ); 1 }, ), 'Configured' );
isa_ok( $wizard->cget( -finishButtonAction ), "Tk::Callback" );

# Create pages
my $SPLASH = $wizard->addSplashPage(
    -wait     => $WAIT,
    -title    => "Installer Test",
    -subtitle => "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
    -text     => "Test Installer's addFileListPage feature for RT #19300."
);
is( $SPLASH, 1, 'Splash page is first' );

$page_count++;

ok(
    $wizard->addLicencePage(
        -preNextButton => sub {},
        -wait     => $WAIT,
        -filepath => 't/dos.txt',
    ),
    'added DOS license page'
);

$page_count++;

ok(
    $wizard->addLicencePage(
        -wait     => $WAIT,
        -filepath => 't/unix.txt',
    ),
    'added UNIX license page'
);

$page_count++;

ok(
    $wizard->addLicencePage(
        -wait     => $WAIT,
        -filepath => 't/extra.txt',
    ),
    'added "extra" license page'
);

$page_count++;

ok(
    $wizard->addFileListPage(
        -slowdown => $ENV{TEST_INTERACTIVE} ? 2000 : 0,
        -wait     => $WAIT,
        -copy     => 1,
        -from => [ map { "$testdir/$_" } @form ],
        -to   => [ map { "$testdir/$_" } @dest ],
    ),
    'added File List page'
);

$page_count++;

ok(
    $wizard->addSplashPage(
        -wait     => $WAIT,
        -title    => "Finished",
        -subtitle => "Click 'Finish' to kill the Wizard.",
        -text     => "Please report bugs via rt.cpan.org"
    ),
    'Added finish page'
);

$page_count++;

isa_ok( $wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{_pages} } ), $page_count, 'Number of pages' );

foreach my $iPage ( 1 .. $page_count ) {
    isa_ok( $wizard->{_pages}->[ $iPage - 1 ], 'CODE', qq'Page $iPage in list' );
}

ok( $wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );

rmtree $TEMP_DIR;

sub bail_out {
    diag 'BAIL OUT';
    diag @_;
    exit;
}

__END__
