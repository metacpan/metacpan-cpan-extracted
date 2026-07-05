use strict;
use warnings;
use Test::More tests => 13;
use Test::Tk;
use Tk;

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';


BEGIN {
	use_ok('Tk::FileBrowser');
};

#$delay = 1000;
my $pause = 300;
my $fb;
my $testfolder = 't/testfolder';

########################################################
#Setting up testfolder

my @folders = ($testfolder, "$testfolder/Directory1", "$testfolder/directory2", "$testfolder/Folder1",
	"$testfolder/folder2");
#my @folders = ($testfolder);
#my @folders = ();
for (@folders) {
	my $dir = $_;
	for (1, 2) {
		my $file;
		if ($_ eq 1) {
			$file = "File$_.txt";
			symlink("$testfolder/$file", "$dir/Link$_") unless $mswin;
		} else {
			$file = "file$_.txt";
			symlink("$testfolder/$file", "$dir/link$_") unless $mswin;
		}
	}
}

########################################################
#Helper routines

sub shown {
	my $path = shift;
	my @shown = ();
	my @children;
	if (defined $path) {
		@children = $fb->infoChildren($path);
	} else {
		@children = $fb->infoRoot;
	}
	for (@children) {
		my $c = $_;
		next if $c =~ /_place_holder_/;
		unless ($fb->infoHidden($c)) {
			push @shown, $c ;
			my $item = $fb->get($c);
			if ($item->isDir) {
				my $s = shown($c);
				push @shown, @$s;
			}
		}
	}
	return \@shown
}

createapp;

if (defined $app) {
	$app->geometry('640x400+100+100');
	$fb = $app->FileBrowser(
		-columns => [qw[Size Modified Type Link Big]],
		-columntypes => [
			Big => {
				data => sub { my $i = shift; return $i->type },
				options => [-sortfield => 'data', -sortnumerical => 1],
				display => sub {
					my $data = shift;
					my $size = $data->size;
					return '' unless defined $size;
					return 'X' if $size > 2048;
					return '';
				},
				test => sub {
					return $fb->testSize(@_);
				},
				width => 40,
			},
		],
#		-directoriesfirst => 0,
		-invokefile => sub { my $f = shift; print "invoking: $f\n" },
#		-showhidden => 1,
#		-sorton => 'Modified',
#		-sorton => 'Size',
#		-sortorder => 'descending',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
	$app->Button(
		-text => 'Refresh',
		-command => sub { $fb->refresh },
	)->pack;
}

#testaccessors($fb, 'noRefresh', 'sorton', 'sortorder');
#
my @firstload = ('Directory1', 'directory2', 'Folder1', 'folder2', 'File1.txt', 'file2.txt',
	'Link1', 'link2');
@firstload = ('Directory1', 'directory2', 'Folder1', 'folder2', 'File1.txt', 'file2.txt') if $mswin;

my @nodirsfirst = ('Directory1', 'directory2', 'File1.txt', 'file2.txt', 'Folder1', 'folder2', 'Link1', 'link2');
@nodirsfirst = ('Directory1', 'directory2', 'File1.txt', 'file2.txt', 'Folder1', 'folder2') if $mswin;

my @casesort = ('Directory1', 'File1.txt', 'Folder1', 'Link1', 'directory2', 'file2.txt', 'folder2', 'link2');
@casesort = ('Directory1', 'File1.txt', 'Folder1', 'directory2', 'file2.txt', 'folder2') if $mswin;

my @descendingsort = ('link2', 'folder2', 'file2.txt', 'directory2','Link1', 'Folder1', 'File1.txt', 'Directory1');
@descendingsort =  ('folder2', 'file2.txt', 'directory2', 'Folder1',  'File1.txt', 'Directory1') if $mswin;

my @filter = ('folder2',  'file2.txt', 'directory2', 'Folder1', 'File1.txt', 'Directory1', );

my @filtercase = ('folder2',  'file2.txt', 'directory2', 'Folder1', 'Directory1', );

my @filterfolders = ('file2.txt', 'File1.txt');

my @filterfolderscase = ('file2.txt');

push @tests, (
	[ sub { return defined $fb }, 1, 'FileBrowser widget created' ],
	[ sub { return defined $fb->Subwidget('LB') }, 1, 'ListBrowser widget found' ],

	[ sub {
		$fb->load($testfolder);
		pause($pause);
		my $shown = shown;
		return $shown;
	}, \@firstload, 'Loaded testfolder' ],

	[ sub {
		$fb->configure(-directoriesfirst => 0);
		$fb->load($testfolder);
		pause($pause);
		return shown;
	}, \@nodirsfirst, 'No directories first' ],

	[ sub {
		$fb->configure(-casedependantsort => 1);
		$fb->load($testfolder);
		pause($pause);
		return shown;
	}, \@casesort, 'Case dependant sort' ],

	[ sub {
		$fb->configure(-sortorder => 'descending');
		$fb->load($testfolder);
		pause($pause);
		return shown;
	}, \@descendingsort, 'Sort name descending' ],

	[ sub {
		$fb->configure(-loadfilter => 'fi');
		$fb->load($testfolder);
		pause($pause);
		return shown;
	}, \@filter, 'Load filter fi' ],

	[ sub {
		$fb->configure(-loadfilterfolders => 1);
		$fb->load($testfolder);
		pause($pause);
		return shown;
	}, \@filterfolders, 'Load filter folders fi' ],

	[ sub {
		return 1 if $mswin; #skip Windows
		$fb->configure(-casedependantsort => 0);
		$fb->configure(-directoriesfirst => 1);
		$fb->configure(-loadfilter => '');
		$fb->configure(-loadfilterfolders => 0);
		$fb->configure(-sortorder => 'ascending');
		$fb->load('~');
		pause($pause);
		my $home = $ENV{HOME};
		return $fb->folder eq $home
	}, 1, 'Loaded home folder' ],

	[ sub {
#		pause($pause);
		$fb->load;
		return 1
	}, 1, 'Loaded current folder' ],
);


starttesting;


########################################################
#Cleaning up testfolder

for (@folders) {
	my $dir = $_;
	for (1, 2) {
		my $link;
		if ($_ eq 1) {
			$link = "Link$_";
		} else {
			$link = "link$_";
		}
		$link = "$dir/$link";
		unlink($link);
	}
}
















