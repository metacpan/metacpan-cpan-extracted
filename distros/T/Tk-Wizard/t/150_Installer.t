use strict;
use warnings;

use ExtUtils::testlib;
use File::Path;
use Test::More;
use FindBin '$Bin';
use Tk;
use lib qw(../lib . t/);

my $VERSION = 1.14;

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    } else {
		$mwTest->destroy if Tk::Exists($mwTest);
		eval { use LWP::UserAgent };
		if ($@){
			plan skip_all => "LWP not found";
		} else {
			my $ua = LWP::UserAgent->new;
			$ua->timeout(10);
			$ua->env_proxy;
			my $response = $ua->get('http://search.cpan.org/');
			if (not $response or $response->is_error ) {
				plan skip_all => "LWP cannot get cpan, guess we're not able to get online";
			} else {
				plan tests => 21;
				pass('can get cpan with LWP-UserAgent');
				use_ok('WizTestSettings');
				use_ok("Tk::Wizard");
				use_ok("Tk::Wizard::Installer" => 2.034);
			}
		}
	}

my $WAIT      = 100;
my $test_dir  = $Bin.'/temp/';

my $get_files = {
    'http://www.cpan.org/' => "$test_dir/cpan_index.html",
};

# This sometimes fails - why?
# Lee: Never failed for me.
my $wizard = Tk::Wizard::Installer->new( -title => "Installer Test", );

isa_ok( $wizard, 'Tk::Wizard::Installer' );
isa_ok( $wizard->parent, "Tk::MainWindow", "Parent" );

ok(
    $wizard->configure(
        -finishButtonAction  => sub { pass('Finished'); 1; },
    ),
    'Configure'
);

isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

# Create pages
my $SPLASH = $wizard->addPage( sub { page_splash($wizard) } );
is( $SPLASH, 1, 'Splash page is first' );

ok(
    $wizard->addDownloadPage(
        -wait  => $WAIT,
        -files => $get_files,
        #-on_error => 1,
        -no_retry => 1,
    ),
    'addDownloadPage'
);

ok(
    $wizard->addPage(
        sub {
            return $wizard->blank_frame(
                -wait     => $WAIT,
                -title    => "Finished",
                -subtitle => "Please.",
            );
        }
    ),
    'Add finish page'
);

isa_ok( $wizard->{_pages}, 'ARRAY', 'Page list array' );
is( scalar( @{ $wizard->{_pages} } ), 3, 'Number of pages' );
foreach ( 1 .. 3 ) {
    isa_ok( $wizard->{_pages}->[0], 'CODE', 'Page in list' );
}

foreach my $f (values %$get_files) {
    unlink $f;    # Ignore return code
    ok( !-f $f, "before test, destination local file $f does not exist" );
}

ok( $wizard->Show, "Show" );
Tk::Wizard::Installer::MainLoop();
pass("Exited MainLoop");

foreach my $f (values %$get_files) {
    ok( -f $f, "Post test: destination local file $f exists" );
}
is(rmtree($test_dir), 2, 'Removed temp dir and files');


sub page_splash {
    my $wizard = shift;
    my ( $frame, @pl ) = $wizard->blank_frame(
        -wait     => $WAIT,
        -title    => "Installer Test",
        -subtitle => "Testing",
    );
    return $frame;
}


__END__
