use strict;
use warnings;

my $VERSION = 1.16;

use File::Path;
use Test::More;
use Tk;
use lib qw(lib t/);
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


chdir ".." if getcwd =~ /\Wt$/;
my $WAIT   = $ENV{TEST_INTERACTIVE} ? 0 : 111;

my @from = qw( 1 2 );
my $dest_subdir = 'mydir/';
my @dest = map { $dest_subdir.$_} qw( 3 4 );

my $TEMP_DIR = 't/tmp';
mkdir( $TEMP_DIR, 0777 );
if ( !-d $TEMP_DIR ) {
    mkdir $TEMP_DIR or bail_out($!);
}

my $testdir = "$TEMP_DIR/__perltk_wizard/";
mkdir $testdir or bail_out($!)
	if not -d $testdir;

my $uninstall_db = getcwd."/".$TEMP_DIR."/uninstall.db";


# DBM files of uninstaller may be lying around during dev
unlink $uninstall_db.'.dir' if -e $uninstall_db.'.dir';
unlink $uninstall_db.'.pag' if -e $uninstall_db.'.pag';


for (@from) {
    my $from = "$testdir/$_";
    local *OUT;
    ok( open( OUT, '>', $from ), "opened $from for write" ) or bail_out($!);
    ok( print OUT "Tk::Wizard::Installer Test. Please ignore or delete.\n\nThis is file $_\n\n"
        . scalar(localtime) . "\n\n"
        . "wrote contents to $from"
    );
    ok( close OUT, "closed $from");
}

for (@dest) {
    my $sDest = "$testdir/$_";
    unlink $sDest;
    # Make sure destination files to NOT exist:
    ok( !-e $sDest, "destination file $sDest does not exist before test" );
}

if ( $ENV{TEST_INTERACTIVE} ) {
    # Add some stuff that will fail, so we can see what exactly happens:
    unshift @from, 'no_such_file';
    unshift @dest, 'no_such_dir';
}

#
# Create INSTALL pages
#

my $page_count = 0;
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok( $wizard->configure( -finishButtonAction => sub { ok( 1, 'Finished' ); 1 }, ), 'Configured' );
isa_ok( $wizard->cget( -finishButtonAction ), "Tk::Callback" );

my $SPLASH = $wizard->addSplashPage(
    -wait     => $WAIT,
    -title    => "Installer Test",
    -subtitle => "Testing Tk::Wizard::Installer $Tk::Wizard::Installer::VERSION",
    -text     => "Test Installer's addFileListPage feature for RT #19300."
);
is( $SPLASH, 1, 'Splash page is first' );
$page_count++;

ok(
    $wizard->addFileCopyPage(
        -slowdown 	=> $ENV{TEST_INTERACTIVE} ? 2000 : 0,
        -wait     	=> $WAIT,
        -copy     	=> 1,
        -from 		=> [ map { "$testdir/$_" } @from ],
        -to   		=> [ map { "$testdir/$_" } @dest ],
        -uninstall_db => $uninstall_db,
    ),
    'Added File List page'
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
    isa_ok( $wizard->{_pages}->[ $iPage - 1 ], 'CODE', "Page $iPage in list" );
}

ok( $wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );






#
# Test uninstaller
#

ok( exists ($wizard->{_uninstall_db_path}),
	"Created value for _uninstall_db_path"
);

diag "TEST: _uninstall_db_path = $wizard->{_uninstall_db_path}" if exists $wizard->{_uninstall_db_path};

ok( (-e $wizard->{_uninstall_db_path}.'.dir'),
	"Created .dir file for _uninstall_db_path"
);
ok( (-e $wizard->{_uninstall_db_path}.'.pag'),
	"Created .pag file for _uninstall_db_path"
);



$page_count = 0;
my $un_wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );
isa_ok( $un_wizard, 'Tk::Wizard::Installer', 'uninstaller' );


# Create pages
#
$un_wizard->addSplashPage(
    -wait     => $WAIT,
    -title    => "Uninstaller Test",
    -subtitle => "Testing Tk::Wizard::Installer uninstaller routine $Tk::Wizard::Installer::VERSION",
    -text     => "Test Installer's uninstall feature for RT #...."
);
$page_count++;

ok(
    $un_wizard->addUninstallPage(
        -wait     	  => $WAIT,
        -uninstall_db => $uninstall_db,
    ),
    'Added Uninstall Page'
);
$page_count++;

ok(
    $un_wizard->addSplashPage(
        -wait     => $WAIT,
        -title    => "Finished",
        -subtitle => "Click 'Finish' to kill the Wizard.",
        -text     => "Please report bugs via rt.cpan.org"
    ),
    'Added finish page'
);
$page_count++;

isa_ok( $un_wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $un_wizard->{_pages} } ), $page_count, 'Number of pages' );

foreach my $iPage ( 1 .. $page_count ) {
    isa_ok( $un_wizard->{_pages}->[ $iPage - 1 ], 'CODE', "Page $iPage in list" );
}


ok( $un_wizard->Show, "Show" );
MainLoop();
ok( 1, "Exited MainLoop" );

ok( not(-e $uninstall_db.'.dir'), 'Module removed uninstaller .dir file');
ok( not(-e $uninstall_db.'.pag'), 'Module removed uninstaller .pag file');

{
	if (-d $testdir.$dest_subdir){
		opendir my $d,$testdir.$dest_subdir or BAIL_OUT "Could not open $testdir.$dest_subdir - $@";
		fail('dir exists');
		is( scalar( grep {!/^\.+$/} readdir $d ), 0, 'no files in test dir');
		closedir $d;
	} else {
		pass 'no dir?';
		ok( not(-d $testdir.$dest_subdir), 'Removed test dir '.$testdir.$dest_subdir);
	}
}

END {
	rmtree $TEMP_DIR;
	unlink $uninstall_db.'.dir';
	unlink $uninstall_db.'.pag';
}

sub bail_out {
    diag @_;
    exit;
}


