use strict;
use warnings;
use Test::More tests => 16;
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
my $handler;
if (defined $app) {
#	$app->DynaMouseWheelBind('Tk::ListBrowser::LBCanvas');

	$ib = $app->ListBrowser(
		-arrange => 'hlist',
		-itemtype => 'text',
		-textanchor => 'w',
		-textside => 'right',
		-textjustify => 'left',
		-selectmode => 'multiple',
		-separator =>'.',

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
	my $af = $app->LabFrame(
		-label => 'Arrange',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $arrange = $ib->cget('-arrange');
	for (qw/row list hlist tree/) {
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

	pause(10);
	$handler = $ib->{HANDLER};
	$app->geometry('500x500+200+200');
}

testaccessors($handler, qw/stack/);

push @tests, (
	[ sub {
		$ib->add('pipoclown', -text => 'pipoclown');
		$ib->add('pipoclown.dikkedeur', -text => 'pipoclown.dikkedeur');
		$ib->add('pipoclown.pipo', -text => 'pipoclown.pipo', -before => 'pipoclown.dikkedeur');
		$ib->add('pipoclown.mamaloe', -text => 'pipoclown.mamaloe', -after => 'pipoclown.pipo');
		$ib->add('pipoclown.pipo.schmink', -text => 'schmink');
		my @list = $ib->infoList;
		return \@list
	}, [ 'pipoclown', 'pipoclown.pipo', 'pipoclown.pipo.schmink', 'pipoclown.mamaloe', 'pipoclown.dikkedeur'], 'hierarchical add' ],
	[ sub {
		my $parent = $ib->infoParent('pipoclown.pipo');
		return $parent
	}, 'pipoclown', 'infoParent' ],
	[ sub {
		my $parent = $ib->infoParent('pipoclown');
		return defined $parent
	}, '', 'infoParent no exist' ],
	[ sub {
		my @list = $ib->infoChildren('pipoclown');
		return \@list
	}, [ 'pipoclown.pipo', 'pipoclown.mamaloe', 'pipoclown.dikkedeur'], 'infoChildren' ],
	[ sub {
		my @list = $ib->infoChildren('pipoclown.pipo');
		return \@list
	}, ['pipoclown.pipo.schmink' ], 'infoChildren 2' ],
	[ sub {
		my @list = $ib->infoChildren('pipoclown.mamaloe');
		return \@list
	}, [ ], 'infoChildren none' ],
	[ sub {
		my @list = $ib->infoChildren('pipoclown.pipo.schmink');
		return \@list
	}, [ ], 'infoChildren none 2' ],
	[ sub {
		$handler->stackPush('comedian');
		return $handler->stackTop
	}, 'comedian', 'handler stackPush / stackTop' ],
	[ sub {
		return $handler->stackSize
	}, 1, 'handler stackSize' ],
	[ sub {
		$handler->stackClear;
		return defined $handler->stackTop
	}, '', 'handler stackClear' ],
	[ sub {
		$handler->stackPush('comedian');
		$handler->stackPull('comedian');
		return defined $handler->stackTop
	}, '', 'handler stackPull' ],
	[ sub {
		$ib->headerCreate('', -text => 'Primary', -sortable => 1);
		$ib->columnCreate('number',
			-itemtype => 'text',
			-background => '#FFFF00', 
			-sortnumerical => 1,
		);
		$ib->headerCreate('number', -text => 'Number', -sortable => 1);

	
		$ib->add('colors', -text => 'colors');
		$ib->itemCreate('colors', 'number',	-text => randnum);
		for ('red', 'green', 'blue') {
			my $name = "colors.$_";
			$ib->add($name, -text => $_); # . $ib->infoParent('colors.red'));
			$ib->itemCreate($name, 'number',	-text => randnum);
			my $dummy = "$name.dummy";
#			print "dummy $dummy\n";
			$ib->add($dummy, -text => randstring(10)); # . $ib->infoParent('colors.red'));
			$ib->itemCreate($dummy, 'number',	-text => randnum);
		}
		$ib->add('colors.yellow', -text => 'yellow');
		$ib->refresh;
		return 1
	}, 1, 'refresh' ],
	[ sub {
		return $handler->maxIndent
	}, 44, 'handler maxIndent' ],
);

starttesting;

