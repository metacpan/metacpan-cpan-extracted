use strict;
use warnings;
use Test::More tests => 2;
use Test::Tk;
require Tk::Photo;
require Tk::LabFrame;
require Tk::ListBrowser;
require Tk::ListBrowser::Entry;
use Tk::PNG;
use Time::HiRes qw(time);


$delay = 1000;

createapp;

my @images;
if (opendir( my $dh, 't/icons')) {
	while (my $file = readdir($dh)) {
		next if $file eq '.';
		next if $file eq '..';
		push @images, $file;
	}
	closedir $dh
} else {
	warn 'cannot open icons folder'
}
@images = sort { lc($a) cmp lc($b) } @images;

my %arranges = (
	bar => {
		-arrange => 'bar',
		-textside => 'bottom',
		-textanchor => '',
		-wraplength => 56,

		-cellheight => 124,
		-cellwidth => 65,
		-celltextheight => 96,
		-celltextwidth => 65,
	},
	column => {
		-arrange => 'column',
		-textside => 'right',
		-textanchor => 'w',
		-wraplength => 0,

		-cellheight => 38,
		-cellwidth => 226,
		-celltextheight => 24,
		-celltextwidth => 198,
	},
	list => {
		-arrange => 'list',
		-textanchor => 'w',
		-textside => 'right',
		-wraplength => 0,

		-cellheight => 38,
		-cellwidth => 226,
		-celltextheight => 24,
		-celltextwidth => 198,
	},
	row => {
		-arrange => 'row',
		-textside => 'bottom',
		-textanchor => '',
		-wraplength => 56,

		-cellheight => 124,
		-cellwidth => 65,
		-celltextheight => 96,
		-celltextwidth => 65,
	},
);

my $arrange = 'row';
my $ib;
my $item;
my $image;
my $mode = 'add';
my $time = 0;

sub newarrange {
	print "newarrange $arrange\n";
	my $arg = shift;
	print "$arg\n" if defined $arg;
	$ib->clear;
	$ib->deleteAll;

	my $a = $arranges{$arrange};
	$ib->configure('-cellimageheight' => 38);
	$ib->configure('-cellimagewidth' => 38);
	my %ar = %$a;
	$ib->configure('-arrange', $arrange);
	my $h = delete $ar{'-cellheight'};
	$ib->configure('-cellheight' => $h);
	my $w = delete $ar{'-cellwidth'};
	$ib->configure('-cellwidth' => $w);
	$ib->listWidth($w);
	my $th = delete $ar{'-celltextheight'};
	$ib->configure('-celltextheight' => $th);
	my $tw = delete $ar{'-celltextwidth'};
	$ib->configure('-celltextwidth' => $tw);
	for (keys %ar) {
		$ib->configure($_, $ar{$_})
	}
	
	for (0 ..60) {
		my $num = $_;
		for (@images) {
#			my $num = '';
			my $text = $_;
			if ($mode eq 'add') {
				$ib->add("$_$num",
					-data => "DATA$text",
					-text => "$text$num",
					-image => $ib->Photo(
						-file => "t/icons/$_",
						-format => 'png',
					),
				);
			} else {
				my $entry = new Tk::ListBrowser::Entry(
					-name => "$_$num",
					-listbrowser => $ib,
					-data => "DATA$text",
					-text => "$text$num",
					-image => $ib->Photo(
						-file => "t/icons/$_",
						-format => 'png',
					),
				);
				$ib->insert($entry, 0);
			}
#			last
		}
	}
}

if (defined $app) {
#	$app->DynaMouseWheelBind('Tk::ListBrowser::LBCanvas');
	$image = $app->Photo(
		-file => "t/icons/edit-cut.png",
		-format => 'png',
	);

	$ib = $app->ListBrowser(

		#options needed to make tests succeed
#		-wraplength => 70,
		-autorefresh => 1,
		-selectmode => 'multiple',
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
	); 
	$ib->configure('-cellimageheight' => 38);
	$ib->configure('-cellimagewidth' => 38);
	newarrange;
	pause(500);
	$ib->pack(-expand =>1, -fill => 'both');

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
#			print "refresh took $tt\ncell height: ", $ib->cellHeight, 
#			"\ncell width: ", $ib->cellWidth,
#			"\nimage height: ", $ib->cellImageHeight,
#			"\nimage width: ", $ib->cellImageWidth,
#			"\ntext height: ", $ib->cellTextHeight,
#			"\ntext width: ", $ib->cellTextWidth, "\n";
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
	for (qw/bar column list row/) {
		$af->Radiobutton(
			-text => $_,
			-variable => \$arrange,
			-value => $_,
			-command => \&newarrange,
		)->pack(-side => 'left');
	}
	my $mf = $app->LabFrame(
		-label => 'Mode',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	for (qw/add insert/) {
		$mf->Radiobutton(
			-text => $_,
			-variable => \$mode,
			-value => $_,
		)->pack(-side => 'left');
	}
	$mf->Label(-text => 'Time:')->pack(-side => 'left');
	$mf->Label(-width => 16, -anchor => 'w', -textvariable => \$time)->pack(-side => 'left');
	
#		print "image height: ", $ib->cellImageHeight,
#		"\nimage width: ", $ib->cellImageWidth, "\n";


	$app->geometry('500x500+200+200');
	pause(200);
}

push @tests, (
);

starttesting;

