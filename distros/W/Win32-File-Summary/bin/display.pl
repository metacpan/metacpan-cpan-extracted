#!d:/perl/bin/perl -w
use Tk;
use Tk::Dialog;
use Tk::MesgBox;
use Win32::FileOp;

use Win32::File::Summary;
use strict;
my $errormessage = "";
my $haveerror = 0;
my %hash;
my %newInfo;
my $windowtitle = "Document Summary Info";
my $menubar;
my @MenuLabelsFile = ('~File', '~Exit', '~Open File', '~Save');
my $number_of_titles = 0;
my $lab;
my $frame;
my $STR;
my @newentry = ();
my @readonly = ('Print Date', 'Date', 'Creation Date', 'Editing Cycles', 'Cell Count', 'Editing Duration', 
'Table Count','Language', 'Number of Characters', 'Revision Number', 'Create Time/Date', 'Total Editing Time', 
'Creating Application', 'Number of Words', 'Security', 'Last Saved Time/Date', 'Number of Pages', 'Template', 
'Last Printed', 'Image Count', 'Object Count', 'Character Count', 'Word Count', 'Page Count', 'Paragraph Count', 'Last Saved By');
sub GetSummaryInfo
{
	my $file=shift;
	print "befor new\n";
	$STR = Win32::File::Summary->new($file);
	my $result = $STR->Read();
	if(ref($result) eq "SCALAR")
	{
		my $err = $STR->GetError();
		$errormessage = $$err;
		my $error = "Error: $errormessage";
		$lab->configure(-text=>$error);
		$haveerror = 1;
		return;
	} else
	{
		
		%hash = %{ $result };
		$lab->configure(-text=>$file);
		$number_of_titles = keys %hash;
	}
	return 1;
}

my $mw = MainWindow->new();
$mw->title($windowtitle);
$mw->minsize(380,200);
$mw->bind('<Escape>', sub { &close_window } );
$mw->bind('<Control-o>', sub { &select_File } );
$mw->bind('<Control-s>', sub { &Save_File } );
my $mainframe = $mw->Canvas(-relief=> 'groove', -borderwidth=> 1, -height=> 200)->pack('-side'=> 'top', -fill=> 'both');
$lab = $mw->Label(-text=>'Ctrl+o for Open | Ctrl+s for Save | ESC to exit')->pack('-side'=> 'left',-fill=>'both');

$mw->configure(-menu => $menubar = $mw->Menu);
my $filebutton	= $menubar->cascade(-label=>$MenuLabelsFile[0], -tearoff=>0);
      $filebutton->command(-label => $MenuLabelsFile[2], -accelerator=>'Ctrl+o', -command => \&select_File);
    #  $filebutton->command(-label => $MenuLabelsFile[3], -accelerator=>'Ctrl+s', -command => \&Save_File);
      $filebutton->command(-label => $MenuLabelsFile[1], -accelerator=>'ESC', -command => \&close_window);



MainLoop;

sub close_window
{
	$mw->destroy;
}

sub select_File
{
	my $dir = "data";
	undef $STR;
	my %param = (
		handle => 0,
		title => 'Select File',
		dir => $dir,
	);
	my $_file = OpenDialog( \%param );
	if(!$_file) { return; }
	if(GetSummaryInfo($_file))
	{
		DisplayInfo();
	}
}

sub Save_File
{
	my $count = 0;
	foreach (keys %hash)
	{
		if(!IsReadOnly($_)) {
			print "$_=" . $newentry[$count]->get() . "\n";
			$newInfo{$_} = $newentry[$count]->get();
		}
		$count++;
	}
	print "\n";
	foreach (keys %newInfo)
	{
		print " Can be saved: $_=" . $newInfo{$_} . "\n";
	}
	my $ret = $STR->Write(\%newInfo);
	print "\nReturn of write=" . $ret . "\n";
	
}

sub DisplayInfo
{
	my @infos = ();
	my @inframes = ();
	$frame->destroy() if $frame;
	$frame = $mainframe->Frame(-relief=> 'groove', -borderwidth=> 1)->pack('-side'=> 'top', -fill=> 'both',-expand=>1);	# where the Title and Values are displayed
	
	my $count = 0;
	foreach (keys %hash)
	{
		my $value = $hash{$_};
		$inframes[$count] = $frame->Frame(-relief=> 'groove', -borderwidth=> 1)->pack('-side'=> 'top', -fill=> 'both',-expand=>1);
		$inframes[$count]->Label(-text=>$_)->pack('-side'=> 'left',-fill=>'both');
		$newentry[$count] = $inframes[$count]->Entry(-text=>'',-width=>40,-relief=>'flat',-textvariable=>\$infos[$count])->pack(-side=>'right');
		$newentry[$count]->insert(0,$value);
		if(IsReadOnly($_))
		{
			$newentry[$count]->configure(-state=>'disabled');
		}
		$count++;
	}
	$newentry[0]->focus();
}

sub IsReadOnly
{
	my $key = shift;
	foreach (@readonly)
	{
		if($key eq $_) { return 1; }
	}
	return 0;
}

1;
