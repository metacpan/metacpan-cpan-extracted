use strict;
use warnings;
use Test::More tests => 7;
use Test::Tk;
use Cwd;
use Config;
use Tk;
require Tk::Photo;
require Tk::LabFrame;
require Tk::ListBrowser;
use Time::HiRes qw(time);

$delay = 1000;

createapp;

my @dataset = (
	['first', 0],
	['second', 0],
	['third', 0],
	['files', 1],
	['files/first', 0],
	['files/second', 0],
	['files/third', 0],
	['files/.', 2],
	['files/..', 2],
	['folders', 1],
	['folders/.', 2],
	['folders/..', 2],
	['folders/first', 1],
	['folders/second', 1],
	['folders/third', 1],
	['folders/third/lastoffspring', 1],
	['mix', 1],
	['mix/.', 2],
	['mix/..', 2],
	['mix/first', 0],
	['mix/second', 1],
	['mix/third', 0],
	['.', 2],
	['..', 2],
);
my $sep = '/';
my $noload = '';
my $dirimg;
my $filimg;
#my $loaddir = '.';
my $loaddir = cwd;
#my $loaddir = '/home/haje/Pictures';
my $ib;

sub add {
	my ($name, %options) = @_;
	print "$name\n";
	$ib->add($name, %options)
}

sub load {
	my $dir = shift;
	$ib->configure(-separator => '\\') if $Config{'osname'} eq 'MSWin32';
	$dir = $loaddir unless defined $dir;
	if (opendir(my $h, $dir)) {
		my @items;
		while (my $item = readdir($h)) {
			push @items, $item
		}
		closedir($h);
		@items = sort { lc($a) cmp lc($b) } @items;
		for (@items) {
			my $item = $_;
			my $full = "$dir$sep$item";
			my $name = substr($full, length($loaddir) + 1, length($full));
			next if $item =~ /^\.[^\.]+/; #no secret files
			if ($item =~ /^\.+$/) {
				add($name, -text => $item, -image => $dirimg, -priority => 2, -background => '#FFFF80');
			} elsif (-l $full) {
				add($name, -text => $item, -foreground => '#0000FF', -image => $filimg, -priority => 0);
			} elsif (-d $full) {
				add($name, -text => $item, -image => $dirimg, -priority => 1, -opened => 0);
				load($full);
			} else {
				add($name, -text => $item, -image => $filimg, -priority => 0);
			}
		}
	}
}

if (defined $app) {
	$dirimg = $app->Pixmap(-file => Tk->findINC('folder.xpm'));
	$filimg = $app->Pixmap(-file => Tk->findINC('file.xpm'));
	
	#setup listbrowser widget;
	$ib = $app->ListBrowser(
		-arrange => 'tree',
		-itemtype => 'imagetext',
		-textanchor => 'w',
		-textside => 'right',
		-textjustify => 'left',
		-selectmode => 'multiple',
		-separator => $sep,
		-sortfield => 'text',
		-filterfield => 'text',

		-browsecmd => sub {
			print "browsecmd ";
			for (@_) { print  "$_ " }
			print "\n";
		},
		-command => sub {
			print "command ";
			for (@_) { print  "$_ " }
			print "\n";
		},
	)->pack(-expand =>1, -fill => 'both');
	$ib->forceWidth(200);
	$ib->headerCreate('',
		-text => 'Name',
		-sortable => 1,
	);

	#setup columns
	for ('Modified', 'Created', 'Accessed') {
		my $col = $ib->columnCreate($_,
			-itemtype => 'text',
			-filterfield => 'text',
			-sortfield => 'text',
		);
		$col->forceWidth(100);
		$ib->headerCreate($_,
			-text => $_,
			-sortable => 1,
		);
	}

	#load directory
#	load($dir);
	for (@dataset) {
		my ($name, $priority) = @$_;
		my $text;
		if ($name =~ /\.(^\.*)$/) {
			$text = $1
		} else {
			$text = $name
		}
		my %opt = (-priority => $priority, -text => $text);
		if ($priority eq 0) { $opt{'-image'} = $filimg }
		if ($priority eq 1) { $opt{'-image'} = $dirimg }
		if ($priority eq 2) { 
			$opt{'-image'} = $dirimg;
			$opt{'-background'} = '#FFFF80';
		}
		add($name, %opt);
	}

	#set up tools
	my $bf = $app->LabFrame(
		-label => 'Tools',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	$bf->Button(
		-command => sub { $ib->clear },
		-text => 'Clear',
	)->pack(-side => 'left');
	$bf->Button(
		-command => sub {
			my $ts = time;
			$ib->refresh;
			my $te = time;
			my $tt = $te - $ts;
			print "refresh took $tt\n";
		},
		-text => 'Refresh',
	)->pack(-side => 'left');
	$bf->Button(
		-command => sub { $ib->selectAll },
		-text => 'Select all',
	)->pack(-side => 'left');
	$bf->Button(
		-command => sub { $ib->selectionClear },
		-text => 'Clear selection',
	)->pack(-side => 'left');
	my $af = $app->LabFrame(
		-label => 'Arrange',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $arrange = $ib->cget('-arrange');
	for (qw/row column tree/) {
		$af->Radiobutton(
			-text => $_,
			-variable => \$arrange,
			-value => $_,
			-command => sub {
				$ib->clear;
				$ib->configure('-arrange', $arrange);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}
	my $tf = $app->LabFrame(
		-label => 'Item type',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $type = $ib->cget('itemtype');
	for (qw/image imagetext text/) {
		$tf->Radiobutton(
			-text => $_,
			-variable => \$type,
			-value => $_,
			-command => sub {
				$ib->clear;
				$ib->configure('-itemtype', $type);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}
	my $sf = $app->LabFrame(
		-label => 'Select style',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $sstyle = $ib->cget('-selectstyle');
	for (qw/anchor simple/) {
		$sf->Radiobutton(
			-text => $_,
			-variable => \$sstyle,
			-value => $_,
			-command => sub {
				$ib->clear;
				$ib->configure('-selectstyle', $sstyle);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}


#	pause(100);
#	$ib->closeAll;
#	my @list = $ib->infoList;
#	print "\n";
#	for (@list) { print "$_\n" }
#	print "\n";

	$app->geometry('500x600+200+200');
}

push @tests, (
	[ sub {
		return $ib->infoLastChild('folders');
	}, 'folders/third', 'infoLastChild' ],
	[ sub {
		return $ib->infoLastOffspring('folders');
	}, 'folders/third/lastoffspring', 'infoLastOffspring' ],
	[ sub {
		return $ib->priorityMax;
	}, 2, 'priorityMax' ],
#	[ sub {
#		my @a = $ib->getAll;
#		my @l = $ib->priorityGet(2, @a);
#		my @r;
#		for (@l) { push @r, $_->name }
#		return \@r
#	}, ['.', '..', 'files/.', 'files/..', 'folders/.', 'folders/..', 'mix/.', 'mix/..'], 'priorityGet' ],
	[ sub {
		$ib->refresh;
		return 1
	}, 1, 'refresh' ],
	[ sub {
		return 1 if $noload;
		$ib->deleteAll;
		my $start = time;
		load;
		my $finish = time;
		my $duration = $finish - $start;
		my @l = $ib->infoList;
		my $s = @l;
		my $rate = $s / $duration;
		print "It took $duration seconds to load $s entries. This is $rate entries per second\n";
		$ib->closeAll;
		$ib->refresh;
		print "listsize $s\n";
		return 1
	}, 1, 'refresh' ],
);

starttesting;

