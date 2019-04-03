# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tk-JFileDialog.t'

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

BEGIN { use_ok('Tk::JFileDialog') };   #NEEDED THIS TO MAKE TEST HARNESS PASS?!?!?!

if (!$ENV{PERL_MM_USE_DEFAULT} && !$ENV{AUTOMATED_TESTING}) {

diag( "Testing Tk::JFileDialog, Testing v$Tk::JFileDialog::VERSION, Perl $], $^X" );
diag( "will popup Tk window now...");

$SIG{__WARN__} = sub { };

	our $MainWin;
	our $path;
	sub sam {
		$MainWin = eval { MainWindow->new; };
		if ($MainWin) {

			$MainWin->title("JFileDialog v$Tk::JFileDialog::VERSION Test");
			$path = '.';

			$topLabel = $MainWin->Label(-text => 'Select a File or Path');
			$topLabel->pack(
					-fill	=> 'x',
					-expand	=> 'yes',
					-side => 'top',
					-padx	=> '2m',
					-pady	=> '2m');

			$ButtonFrame = $MainWin->Label();
			$ButtonFrame->pack(
					-fill	=> 'x',
					-expand	=> 'yes',
					-padx	=> '2m',
					-side => 'top',
					-pady	=> '2m');

			$FileButton = $ButtonFrame->Button(
					-padx => 11,
					-pady =>  4,
					-text => 'Select File',
					-underline => 7,
					-command => [\&getfile]);
			$FileButton->pack(-side=>'left', -expand=>1, -padx=>'2m', -pady=>'2m');
			$MultiFileButton = $ButtonFrame->Button(
					-padx => 11,
					-pady =>  4,
					-text => 'Select File(s)',
					-underline => 7,
					-command => [\&getfiles]);
			$MultiFileButton->pack(-side=>'left', -expand=>1, -padx=>'2m', -pady=>'2m');

			$DirButton = $ButtonFrame->Button(
					-padx => 11,
					-pady =>  4,
					-text => 'Select Path',
					-underline => 7,
					-command => [\&getpath]);
			$DirButton->pack(-side=>'left', -expand=>1, -padx=>'2m', -pady=>'2m');

			$QuitButton = $ButtonFrame->Button(
					-padx => 11,
					-pady =>  4,
					-text => 'Quit',
					-underline => 0,
					-command => sub {
						##TEST HARNESS WILL FAIL:	 exit(0);
						$MainWin->destroy();
					});
			$QuitButton->pack(-side=>'left', -expand=>1, -padx=>'2m', -pady=>'2m');

			$MainWin->update;

			$QuitButton->bind('<Return>' => "Invoke");
			$FileButton->bind('<Return>' => "Invoke");
			$MainWin->bind('<Escape>' => [$QuitButton => "Invoke"]);

			##TEST HARNESS WILL FAIL:		MainLoop;
			while (Tk::MainWindow->Count)
			{
				DoOneEvent(ALL_EVENTS);
			}

			diag "ok, done (Success)!\n";

			return 1;
		}
	}

	sub getfile
	{
		my $mytitle = "Select file:";
		my ($create) = 0;
		my ($fileDialog) = $MainWin->JFileDialog(
				-Title=> $mytitle,
				-Path => $path,
				-History => 12,
				-HistDeleteOk => 1,
				-HistFile => "./FileHistory.txt",
				-Create => 1,
				-nonLatinFilenames => 1,
		);

		$myfile = $fileDialog->Show();
		if ($myfile =~ /\S/o)
		{
			$topLabel->configure(-text => "file: $myfile");
		}
	}

	sub getfiles
	{
		my $mytitle = "Select file(s):";
		my ($create) = 0;
		my ($fileDialog) = $MainWin->JFileDialog(
				-Title=> $mytitle,
				-Path => $path,
				-SelectMode => 'multiple',
				-HistDeleteOk => 1,
				-Create => 1,
				-nonLatinFilenames => 1,
		);

		$myfile = $fileDialog->Show();
		if ($myfile =~ /\S/o)
		{
			$topLabel->configure(-text => "file: $myfile");
		}
	}

	sub getpath
	{
		my $mytitle = "Select Directory:";
		my ($create) = 0;
		my ($fileDialog) = $MainWin->JFileDialog(
				-Title=> $mytitle,
				-Path => $path,
				-History => 12,
				-HistFile => "./PathHistory.txt",
				-PathFile => "./PathHistory.txt",
				-SelDir => 1,
				-Create => 0,
				-nonLatinFilenames => 1,
		);

		$myfile = $fileDialog->Show();
		if ($myfile =~ /\S/)
		{
			$topLabel->configure(-text => "Path: $myfile");
		}
		$path = $myfile;
	}
} else {
	diag( "ok, done (Skipping Demo program - no X-session)." );
}

unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	is(&sam(), 1, 'running Tk::JFileDialog sample program.');
	diag( "Testing sample Tk::JFileDialog program." );
}

__END__
