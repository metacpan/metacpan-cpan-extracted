use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use ExtUtils::testlib;
use Test::More;
use Tk;
use Cwd;
use lib qw(../lib . t/);

    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 5;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard');
    use_ok('WizTestSettings');


my $wizard = Tk::Wizard->new;
isa_ok( $wizard, "Tk::Wizard" );

chdir ".." if getcwd =~ /\Wt$/;

$wizard->addSplashPage(
    -wait      => $ENV{TEST_INTERACTIVE} ? 0 : 1,
);

$wizard->addTextFramePage(
    -wait      => $ENV{TEST_INTERACTIVE} ? 0 : 1,
    -title     => "1: Text from literal",
    -boxedtext => \"This is in a box", # "
);

$wizard->addTextFramePage(
    -wait      => $ENV{TEST_INTERACTIVE} ? 0 : 1,
    -subtitle  => "2: Text from filename",
    -boxedtext => 't/perl_licence_blab.txt',
);

$wizard->Show;

pass('before MainLoop');
MainLoop;
pass('after MainLoop');

exit 0;

__END__
