use strict;
use warnings;
our $VERSION = do { my @r = ( q$Revision: 1.9 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use lib qw(../lib . t/);

    if ( $^O !~ m/mswin32/i ) {
        plan 'skip_all' => 'You are not Windows, you lucky box';
    } else {
    	plan 'no_plan';
	}
	use Tk;
    use_ok('WizTestSettings');
    use_ok('Tk::Wizard' => ':old');
    use_ok('Tk::Wizard::Installer::Win32');

pass('before new');
my $w = Tk::Wizard::Installer::Win32->new;

isa_ok( $w, "Tk::Wizard::Installer::Win32" );
is(
    $w->addSplashPage(
        -wait  => 444,
        -title => "Welcome to the Wizard",
    ),
    1,
    'splash is 1'
);
my $s;
is(
    $w->addStartMenuPage(
        -wait => $ENV{TEST_INTERACTIVE} ? -1 : 999,
        -variable      => \$s,
        -program_group => 'My Group',
    ),
    2,
    'start menu page is 2'
);
is(
    $w->addSplashPage(
        -wait  => 444,
        -title => "Page Bye!",
        -text  => "Thanks for testing!"
    ),
    3,
    'bye is 3'
);
$w->Show;
pass('after Show');
MainLoop();
pass('after MainLoop');

__END__
