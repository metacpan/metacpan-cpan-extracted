use strict;
use warnings;
use Test::More tests => 42;
use Test::Tk;
require Tk::Photo;
require Tk::LabFrame;
require Tk::ListBrowser;
#use Tk::DynaMouseWheelBind;
use Tk::PNG;
use Time::HiRes qw(time);

sub randnum {
	return rand(10)
}
my @chars = (qw/a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 0 _/);
my $charsize = @chars;

sub randstring {
	my $length = shift;
	my $string = '';
	for (0 .. $length) {
		my $index = int(rand($charsize));
		my $char = $chars[$index];
		$string = "$string$char";
	}
	my $flag = int(rand(2));
	$string = ucfirst($string) if $flag;
	return $string;
}

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
@images = sort @images;

my $ib;
my $sc;
if (defined $app) {
#	$app->DynaMouseWheelBind('Tk::ListBrowser::LBCanvas');

	$ib = $app->ListBrowser(
		-arrange => 'list',
		-textanchor => 'w',
		-textside => 'right',
		-textjustify => 'left',
		-selectmode => 'multiple',
		-filtercolumns => 1,

#		-marginleft => 80,
#		-margintop => 80,
#		-marginbottom => 80,
#		-marginright => 80,

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
	$sc = $ib->columnCreate('test');
	my $mf = $app->LabFrame(
		-label => 'Move column Thrd',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	$mf->Button(
		-command => sub {
			my $i = $ib->columnIndex('rebmun');
			$i --;
			$ib->columnMove('rebmun', $i);
			$ib->refresh;
		},
		-text => 'Left',
	)->pack(-side => 'left');
	$mf->Button(
		-command => sub {
			my $i = $ib->columnIndex('rebmun');
			$i ++;
			$ib->columnMove('rebmun', $i);
			$ib->refresh;
		},
		-text => 'Right',
	)->pack(-side => 'left');

	$app->geometry('500x400+200+200');
}

testaccessors($sc, qw/background cellImageWidth cellTextWidth cellWidth forceWidth foreground header itemtype/);

push @tests, (
	[ sub {
		$ib->columnRemove('test');
		return defined $ib
	}, 1, 'ListBrowser widget created' ],
	[ sub {
		my $start = time;
		for (@images) {
			my $text = $_;
			$ib->add($_,
				-data => "DATA$text",
				-text => $text,
				-image => $ib->Photo(
					-file => "t/icons/$_",
					-format => 'png',
				),
			);
		}
		for (0 ..60) {
			my $num = $_;
			for (@images) {
				my $text = $_;
				$ib->add("$_$num",
					-data => "DATA$text",
					-text => "$text$num",
					-image => $ib->Photo(
						-file => "t/icons/$_",
						-format => 'png',
					),
				);
			}
		}
		my $finish = time;
		my $duration = $finish - $start;
		my @l = $ib->infoList;
		my $size = @l;
		my $rate = $size / $duration;
		print "It took $duration seconds to load $size entries. This is $rate entries per second\n";
		$ib->refresh;
		return $size
	}, 744, 'refresh' ],
	[ sub {
		my @l = $ib->columnList;
		return \@l 
	}, [], 'columnList' ],
	[ sub {
		$ib->columnCreate('pipodol');
		my @l = $ib->columnList;
		return \@l 
	}, ['pipodol'], 'columnCreate' ],
	[ sub {
		$ib->columnCreate('number', 
			-background => '#FFFF00', 
			-before => 'pipodol',
			-sortnumerical => 1,
		);
#		$ib->columnCreate('number', -before => 'pipodol');
		my @l = $ib->columnList;
		return \@l 
	}, ['number', 'pipodol'], 'columnCreate' ],
	[ sub {
		$ib->columnCreate('string', -after => 'number');
		my @l = $ib->columnList;
		return \@l 
	}, ['number', 'string', 'pipodol'], 'columnCreate' ],
	[ sub {
		$ib->columnMove('pipodol', 0);
		my @l = $ib->columnList;
		return \@l 
	}, ['pipodol', 'number', 'string'], 'columnMove' ],
	[ sub {
		return $ib->columnExists('pipodol');
	}, 1, 'columnExists true' ],
	[ sub {
		return $ib->columnExists('qjqpepk');
	}, '', 'columnExists false' ],
	[ sub {
		my $col = $ib->columnGet('pipodol');
		return $col->name
	}, 'pipodol', 'columnGet' ],
	[ sub {
		$ib->columnConfigure('pipodol', '-background', 'green');
		my $col = $ib->columnGet('pipodol');
		return $col->background
	}, 'green', 'columnConfigure' ],
	[ sub {
		return $ib->columnCget('pipodol', '-background');
	}, 'green', 'columnExists false' ],
	[ sub {
		return $ib->columnIndex('pipodol');
	}, 0, 'columnIndex' ],
	[ sub {
		$ib->columnRemove('pipodol');
		return 	$ib->columnExists('pipodol')
	}, '', 'columnRemove pipodol' ],
	[ sub {
		$ib->columnRemove('string');
		return 	$ib->columnExists('string')
	}, '', 'columnRemove string' ],
	[ sub {
		return $ib->itemExists('edit-cut.png', 'number');
	}, '', 'itemExists false' ],
	[ sub {
		$ib->columnCreate('rebmun', -background => '#80FF80');
#		$ib->columnCreate('rebmun');
		$ib->columnCreate('bernum', -background => '#80FFFF');
#		$ib->columnCreate('bernum');
		my $count = 0;
		for (@images) {
			$ib->itemCreate($_, 'number',
				-background => '#f954e0', 
				-text => randnum,
			);
			$ib->itemCreate($_, 'rebmun',
#				-background => '#25a48a',
				-text => randstring(8)
			);
			$ib->itemCreate($_, 'bernum', -text => randstring(16));
			$count ++
		}
		return 1
	}, 1, 'itemCreate' ],
	[ sub {
		return $ib->itemExists('edit-cut.png', 'number');
	}, 1, 'itemExists true' ],
	[ sub {
		my $i = $ib->itemGet('edit-cut.png', 'number');
		return $i->name;
	}, 'edit-cut.png', 'itemGet' ],
	[ sub {
		$ib->itemConfigure('edit-cut.png', 'number', '-background' => 'green');
		return $ib->itemGet('edit-cut.png', 'number')->background
	}, 'green', 'itemConfigure' ],
	[ sub {
		return $ib->itemCget('edit-cut.png', 'number', '-background')
	}, 'green', 'itemCget' ],
	[ sub {
		$ib->itemRemove('edit-cut.png', 'number');
		return $ib->itemExists('edit-cut.png', 'number');
	}, '', 'itemRemove' ],
	[ sub {
		$ib->headerCreate('', -sortable => 1);
		return defined $ib->headerGet('');
	}, 1, 'headerCreate headerGet main' ],
	[ sub {
		return $ib->headerExists('');
	}, 1, 'headerExists main' ],
	[ sub {
		$ib->headerCreate('number');
		return defined $ib->headerGet('number');
	}, 1, 'headerCreate headerGet column' ],
	[ sub {
		return $ib->headerExists('number');
	}, 1, 'headerExists column' ],
	[ sub {
		return $ib->headerExists('bernum');
	}, '', 'headerExists false' ],
	[ sub {
		$ib->headerConfigure('', '-text', 'pocahontas');
		return $ib->headerCget('', '-text');
	}, 'pocahontas', 'headerConfigure headerCget main' ],
	[ sub {
		$ib->headerConfigure('number', '-text', 'xena');
		return $ib->headerCget('number', '-text');
	}, 'xena', 'headerConfigure headerCget column' ],
	[ sub {
		$ib->headerRemove('');
		return $ib->headerExists('');
	}, '', 'headerRemove main' ],
	[ sub {
		$ib->headerRemove('number');
		return $ib->headerExists('number');
	}, '', 'headerRemove column' ],
	[ sub {
#		$ib->Subwidget('Canvas')->Label(-text => 'Try this!')->pack(-fill => 'x');
		$ib->headerCreate('',
			-text => 'Primary',
			-sortable => 1,
		);
		$ib->headerCreate('number',
			-text => 'Sec',
			-sortable => 1,
		);
		$ib->headerCreate('rebmun',
			-text => 'Thrd',
			-sortable => 1,
		);
		$ib->headerCreate('bernum',
			-text => 'Frth',
			-sortable => 1,
		);
#		$ib->configure('sorton' => '');
#		$ib->sortMode('', 'ascending');
#		$ib->sortList;
		$ib->refresh;
	}, '', 'refresh' ],
);

starttesting;

