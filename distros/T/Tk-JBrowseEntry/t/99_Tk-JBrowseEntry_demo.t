# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tk-JBrowseEntry.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use blib;
use File::Basename;
use Tk;
use Tk ':eventtypes';

use Test::More tests => ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) ? 1 : 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { use_ok('Tk::JBrowseEntry') };   #NEEDED THIS TO MAKE TEST HARNESS PASS?!?!?!

if (!$ENV{PERL_MM_USE_DEFAULT} && !$ENV{AUTOMATED_TESTING}) {

diag( "Testing Tk::JBrowseEntry, Testing v$Tk::JBrowseEntry::VERSION, Perl $], $^X" );
diag( "will popup Tk window now...");

$SIG{__WARN__} = sub { };

	our $MainWin;
	our $path;
	sub sam {
		$MainWin = eval { MainWindow->new; };
		if ($MainWin) {
			my $dbname1 = 'cows';
			my $dbname2 = 'foxes';
			my $dbname3 = 'goats';
			my $dbname5 = 'default';

			$MainWin->title("JBrowseEntry v$Tk::JBrowseEntry::VERSION Test");
			$path = '.';

			my $jb1 = $MainWin->JBrowseEntry(
				-label => 'Normal:',
				-variable => \$dbname1,
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats cats)],
				-width  => 12);
			$jb1->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb2a = $MainWin->JBrowseEntry(
				-label => 'Text:',
				-variable => \$dbname2,
				-state => 'text',
				-choices => [qw(pigs cows foxes goats cats)],
				-width  => 12);
			$jb2a->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb2 = $MainWin->JBrowseEntry(
				-label => 'TextOnly:',
				-variable => \$dbname2,
				-state => 'textonly',
				-choices => [qw(pigs cows foxes goats cats)],
				-width  => 12);
			$jb2->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb3 = $MainWin->JBrowseEntry(
				-label => 'ReadOnly:',
				-variable => \$dbname3,
				-choices => [qw(pigs cows foxes goats cats)],
				-state => 'readonly',
				-width  => 12);
			$jb3->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb4 = $MainWin->JBrowseEntry(
				-label => 'Disabled:',
				-variable => \$dbname3,
				-state => 'disabled',
				-choices => [qw(pigs cows foxes goats cats)],
				-width  => 12);
			$jb4->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb5 = $MainWin->JBrowseEntry(
				-label => 'Scrolled List:',
				-width => 12,
				-default => $dbname5,
				-height => 4,
				-variable => \$dbname5,
				-browsecmd => sub {print "-browsecmd!\n";},
				-listcmd => sub {print "-listcmd!\n";},
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
			$jb5->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb6 = $MainWin->JBrowseEntry(
				-label => 'Button Focus Also:',
				-btntakesfocus => 1,
				-width => 12,
				-height => 4,
				-variable => \$dbname6,
				-browsecmd => sub {print "-browsecmd!\n";},
				-listcmd => sub {print "-listcmd!\n";},
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
			$jb6->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb8 = $MainWin->JBrowseEntry(
				-label => 'Button Focus Only:',
				-takefocus => 0,
				-btntakesfocus => 1,
				-width => 12,
				-height => 4,
				-variable => \$dbname6,
				-browsecmd => sub {print "-browsecmd!\n";},
				-listcmd => sub {print "-listcmd!\n";},
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
			$jb8->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');
			my $jb7 = $MainWin->JBrowseEntry(
				-label => 'Skip Focus:',
				-takefocus => 0,
				-btntakesfocus => 0,
				-width => 12,
				-height => 4,
				-variable => \$dbname7,
				-browsecmd => sub {print "-browsecmd!\n";},
				-listcmd => sub {print "-listcmd!\n";},
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats horses sheep dogs cats ardvarks default)]);
			$jb7->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');

			$jb7->choices([qw(First Second Fifth Sixth)]);   #REPLACE LIST CHOICES!
			$jb7->insert(2, 'Third', 'Fourth');              #ADD MORE AFTER 1ST 2.
			$jb7->insert('end', [qw(Seventh Oops Nineth)]);  #ADD STILL MORE AT END.
			$jb7->delete(7);                                 #REMOVE ONE.

			my $jb9 = $MainWin->JBrowseEntry(
				-label => 'Bouncy:',
				-altbinding => 'list=bouncy',
				-variable => \$dbname1,
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats)],
				-width  => 12);
			$jb9->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');

			my $jb10 = $MainWin->JBrowseEntry(
				-label => 'Fixed:',
				-fixedlist => 'bottom',
				-variable => \$dbname1,
				-state => 'normal',
				-choices => [qw(pigs cows foxes goats)],
				-width  => 12);
			$jb10->pack(
				-side   => 'top', -pady => '10', -anchor => 'w');

			$b = $MainWin->Button(-text => 'Quit', -command => sub {
				##TEST HARNESS WILL FAIL:	 exit(0);
				$MainWin->destroy();
			});
			$b->pack(-side => 'top');
			 $jb1->focus;

			##TEST HARNESS WILL FAIL:		MainLoop;
			while (Tk::MainWindow->Count)
			{
				DoOneEvent(ALL_EVENTS);
			}

			diag "ok, done (Success)!\n";

			return 1;
		}
	}

} else {
	diag( "ok, done (Skipping Demo program - no X-session)." );
}

unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	is(&sam(), 1, 'running Tk::JBrowseEntry sample program.');
	diag( "Testing sample Tk::JBrowseEntry program." );
}

__END__
