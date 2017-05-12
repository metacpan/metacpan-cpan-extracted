# $Id: 77_dirselect.t,v 1.7 2007/08/18 00:44:16 martinthurn Exp $

=head1 NAME

200_tasklist.t - test a tasklist

=head1 DESCRIPTION

User story: http://rt.cpan.org/Ticket/Display.html?id=34610

Strangely, after the &update fix, I only see the error in
the user's error script, when it uses C<slee>.

=cut

use strict;

use Cwd;
use ExtUtils::testlib;
use FileHandle;
use Cwd;
use Test::More;
use Tk;
use lib qw(../lib . t/);


my $VERSION = do { my @r = ( q$Revision: 2.079 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };


    my $mwTest;
    eval { $mwTest = Tk::MainWindow->new };
    if ($@) {
        plan skip_all => 'Test irrelevant without a display';
    }
    else {
        plan tests => 10;
    }
    $mwTest->destroy if Tk::Exists($mwTest);
    use_ok('Tk::Wizard' => $VERSION);
    use_ok('WizTestSettings');

autoflush STDOUT 1;

our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 10;

my $wizard = Tk::Wizard->new(
    -title => "Test version $VERSION For Tk::Wizard version $Tk::Wizard::VERSION",
    # -debug => 88,
);

isa_ok( $wizard, "Tk::Wizard" );

$wizard->configure(
    -finishButtonAction  => sub { pass('user clicked finish'); 1; },
);
isa_ok( $wizard->cget( -finishButtonAction ),  "Tk::Callback" );

#
# Create pages
#
is(
    $wizard->addPage( sub {
		$wizard->blank_frame(
			-wait  => $WAIT,
			-title => "Test Wizard",
		);
	}),
    1,
    'splash is 1'
);

is(
	$wizard->addTaskListPage(
		-wait  => 10000,
		-title => "Task List Page",
		-subtitle => "Put a window over me and wawtch me update myself...",
		-tasks => [
			"Get interface name" => sub {
				while (1) {
					sleep(1);
					# $wizard->update;
				}
			}
		],
	),
	2,
	'this is two'
);

is(
    $wizard->addPage(
        sub {
            $wizard->blank_frame(
                -wait  => $WAIT,
                -title => "Bye!",
                -text  => "Thanks for testing!"
            );
        }
    ),
    3,
    'bye is 3'
);

$wizard->Show;
pass('after Show');
MainLoop();
pass('after MainLoop');
undef $wizard;


__END__

