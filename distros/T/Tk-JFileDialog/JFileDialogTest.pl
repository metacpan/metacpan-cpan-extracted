#!/usr/bin/perl -s 

use lib './lib';

use Tk;                   #LOAD TK STUFF
use Tk::JFileDialog;

$MainWin = MainWindow->new;

$MainWin->title('JFileDialog Test');
$path = $ENV{HOME} || '.';

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
		-command => sub { exit(0); });
$QuitButton->pack(-side=>'left', -expand=>1, -padx=>'2m', -pady=>'2m');

$MainWin->update;

$QuitButton->bind('<Return>' => "Invoke");
$FileButton->bind('<Return>' => "Invoke");
$MainWin->bind('<Escape>' => [$QuitButton => "Invoke"]);

MainLoop;

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
			-PathFile => "./Bookmarks.txt",
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
			#-QuickSelect => 2,
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
			-Path => $ENV{HOME} || '.',
			-History => 12,
			-HistFile => "./PathHistory.txt",
			-PathFile => "./Bookmarks.txt",
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

__END__
