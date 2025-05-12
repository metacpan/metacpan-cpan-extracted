use strict;
use warnings;
use Test::More tests => 101;
use Test::Tk;
require Tk::Photo;
require Tk::LabFrame;
use Tk::PNG;
use Time::HiRes qw(time);

BEGIN {
	use_ok('Tk::ListBrowser');
	use_ok('Tk::ListBrowser::Bar');
	use_ok('Tk::ListBrowser::BaseItem');
	use_ok('Tk::ListBrowser::Column');
	use_ok('Tk::ListBrowser::Data');
	use_ok('Tk::ListBrowser::Entry');
	use_ok('Tk::ListBrowser::FilterEntry');
	use_ok('Tk::ListBrowser::HList');
	use_ok('Tk::ListBrowser::Item');
	use_ok('Tk::ListBrowser::LBCanvas');
	use_ok('Tk::ListBrowser::LBHeader');
	use_ok('Tk::ListBrowser::List');
	use_ok('Tk::ListBrowser::Row');
	use_ok('Tk::ListBrowser::SelectXPM');
	use_ok('Tk::ListBrowser::SideColumn');
	use_ok('Tk::ListBrowser::Tree');
};

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
my $item;
my $image;
my $handler;
my $data;
if (defined $app) {
#	$app->DynaMouseWheelBind('Tk::ListBrowser::LBCanvas');
	$image = $app->Photo(
		-file => "t/icons/edit-cut.png",
		-format => 'png',
	);

	$ib = $app->ListBrowser(
		#options to play with
#		-marginleft => 80,
#		-marginright => 80,
#		-margintop => 80,
#		-marginbottom => 80,
#		-arrange => 'list',
#		-arrange => 'row',
#		-filterforce => 1,
#		-motionselect => 1,
#		-nofilter => 1,
#		-textanchor => 'w',
#		-textside => 'right',
#		-textjustify => 'left',
#		-height => 200,
#		-width => 200,
#		-font => 'Hack 10',

		#options needed to make tests succeed
		-wraplength => 70,
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
	)->pack(-expand =>1, -fill => 'both');
	$item = $ib->add('miny', -image => $image);
	$handler = $ib->{HANDLER};
	$data = Tk::ListBrowser::Data->new($ib);
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
	for (qw/bar column list row/) {
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

	my $sf = $app->LabFrame(
		-label => 'Text side',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $textside = $ib->cget('-textside');
	for (qw/top bottom left right/) {
		$sf->Radiobutton(
			-text => $_,
			-variable => \$textside,
			-value => $_,
			-command => sub {
				$ib->configure('-textside', $textside);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}

	my $wf = $app->LabFrame(
		-label => 'Wrap length',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $wraplength = $ib->cget('-wraplength');
	my $spin = $wf->Spinbox(
		-from => 0,
		-to => 200,
		-command => sub {
			$wraplength = shift;
			$ib->configure('-wraplength', $wraplength) if ($wraplength =~ /^\d+$/);
			$ib->refresh;
		},
		-textvariable => \$wraplength,
	)->pack(-side => 'left');
	$spin->bind('<KeyRelease>', sub {
		$ib->configure('-wraplength', $wraplength) if ($wraplength =~ /^\d+$/);
		$ib->refresh;
	});

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
				$ib->configure('-itemtype', $type);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}

	my $smf = $app->LabFrame(
		-label => 'Select mode',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $smode = $ib->cget('-selectmode');
	for (qw/single multiple/) {
		$smf->Radiobutton(
			-text => $_,
			-variable => \$smode,
			-value => $_,
			-command => sub {
				$ib->configure('-selectmode', $smode);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}
	my $smsf = $app->LabFrame(
		-label => 'Select style',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $style = $ib->cget('-selectstyle');
	for (qw/anchor simple/) {
		$smsf->Radiobutton(
			-text => $_,
			-variable => \$style,
			-value => $_,
			-command => sub {
				$ib->configure('-selectstyle', $style);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}

	my $jf = $app->LabFrame(
		-label => 'Text justify',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $justify = $ib->cget('-textjustify');
	for (qw/left center right/) {
		$jf->Radiobutton(
			-text => $_,
			-variable => \$justify,
			-value => $_,
			-command => sub {
#				$ib->clear;
				$ib->configure('-textjustify', $justify);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}

	my $hf = $app->LabFrame(
		-label => 'Text anchor',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	my $anchor = $ib->cget('-textanchor');
	for ('', qw/n ne nw s se sw e w/) {
		$hf->Radiobutton(
			-text => "'$_'",
			-variable => \$anchor,
			-value => $_,
			-command => sub {
#				$ib->clear;
				$ib->configure('-textanchor', $anchor);
				$ib->refresh;
			},
		)->pack(-side => 'left');
	}

	$app->geometry('500x800+200+200');
	pause(200);
}

testaccessors($data, qw/pool opened/);
testaccessors($ib, qw/cellHeight cellImageHeight cellImageWidth
	cellTextHeight cellTextWidth cellWidth forceWidth header listWidth sortActive/);
testaccessors($item, qw/background cguideH cguideV cimage cindicator column cimage 
	crect	ctext data font foreground hidden imageX imageY itemtype opened owner rectX
	rectY row textanchor textjustify textside textX textY/);
testaccessors($handler, qw/cellHeight cellImageHeight cellImageWidth 
	cellTextHeight cellTextWidth cellWidth/);

push @tests, (
	[ sub { return defined $ib }, 1, 'ListBrowser widget created' ],
	[ sub { return defined $handler }, 1, 'Tk::ListBrowser::Row created' ],
	[ sub { return defined $data }, 1, 'Tk::ListBrowser::Data created' ],
	[ sub {
		$data->add('miny', -image => $image);
		$data->add('inny', -image => $image, -before => 'miny');
		$data->add('minny', -image => $image, -after => 'inny');
		$data->add('mo', -image => $image);
		my @l = $data->infoList;
		return \@l
	}, [qw/inny minny miny mo/], 'data add / list' ],
	[ sub {
		my $t = $data->get('miny');
		return $t->name
	}, 'miny', 'data get' ],
	[ sub {
		return $data->exists('miny');
	}, 1, 'data exists' ],
	[ sub {
		return $data->exists('humptydumpty');
	}, '', 'data no exists' ],
	[ sub {
		my $t = $data->get('miny');
		return $t->name
	}, 'miny', 'get' ],
	[ sub {
		my @all = $data->getAll;
		my $size = @all;
		return $size
	}, 4, 'getAll' ],
	[ sub {
		return $data->index('mo');
		}, 3, 'index' ],
	[ sub {
		$data->itemConfigure('miny', -data => 'new data');
		return $data->itemCget('miny', '-data');
	}, 'new data', 'data itemConfigure / itemCget' ],
	[ sub {
		$data->delete('miny');
		return $data->exists('miny');
	}, '', 'data delete' ],


	[ sub {
		$ib->add('inny', -image => $image, -before => 'miny');
		$ib->add('minny', -image => $image, -after => 'inny');
		$ib->add('mo', -image => $image);
		my @l = $ib->infoList;
		return \@l
	}, [qw/inny minny miny mo/], 'add' ],
	[ sub {
		my $t = $ib->get('miny');
		return $t->name
	}, 'miny', 'get' ],
	[ sub {
		my @t = $ib->getAll;
		my $size = @t;
		return $size;
	}, 4, 'getAll' ],
	[ sub {
		$ib->delete('miny');
		$ib->delete('minny');
		my @l = $ib->infoList;
		return \@l
	}, [qw/inny mo/], 'delete' ],
	[ sub {
		$ib->deleteAll;
		my @l = $ib->infoList;
		return \@l
	}, [], 'deleteAll' ],

	[ sub {
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
		my @l = $ib->infoList;
		my $size = @l;
		return $size
	}, 744, 'load' ],
	[ sub {
		return $ib->index('accessories-text-editor.png');
		}, 0, 'index' ],
	[ sub {
		$ib->selectionSet('edit-find.png', 'document-new.png');
		my @l = $ib->selectionGet;
		return \@l
	}, ['document-new.png', 'document-save.png', 'edit-cut.png', 'edit-find.png'], 'selectionGet' ],
	[ sub {
		$ib->selectionClear;
		my @l = $ib->selectionGet;
		return \@l
	}, [], 'selectionGet no selection' ],
	[ sub {
		return defined $ib->anchorGet
	}, '', 'anchorGet no anchor' ],
	[ sub {
		$ib->anchorSet('arrow-down.png');
		return defined $ib->anchorGet
	}, 1, 'anchorSet' ],
	[ sub {
		return $ib->infoAnchor;
	}, 'arrow-down.png', 'infoAnchor' ],
	[ sub {
		return $ib->infoData('arrow-down.png');
	}, 'DATAarrow-down.png', 'infoData' ],
	[ sub {
		return $ib->infoExists('arrow-down.png');
	}, 1, 'infoExists' ],
	[ sub {
		return $ib->infoExists('arrow-down.png_no_exist');
	}, '', 'infoExists no exist' ],
	[ sub {
		return $ib->infoFirst;
	}, 'accessories-text-editor.png', 'infoFirst' ],
	[ sub {
		$ib->hide('arrow-down.png');
		return $ib->infoHidden('arrow-down.png');
	}, 1, 'hide / infoHidden hidden' ],
	[ sub {
		$ib->show('arrow-down.png');
		return $ib->infoHidden('arrow-down.png');
	}, '', 'show / infoHidden shown' ],
	[ sub {
		return $ib->infoLast;
	}, 'system-file-manager.png60', 'infoLast' ],
	[ sub {
		return $ib->infoNext('accessories-text-editor.png');
	}, 'arrow-down.png', 'infoNext' ],
	[ sub {
		my $n = $ib->infoNext('system-file-manager.png60');
		return defined $n
	}, '', 'infoNext none' ],
	[ sub {
		return $ib->infoPrev('system-file-manager.png');
	}, 'multimedia-volume-control.png', 'infoPrev' ],
	[ sub {
		my $n = $ib->infoPrev('accessories-text-editor.png');
		return defined $n
	}, '', 'infoPrev none' ],
	[ sub {
		return $ib->entryCget('arrow-down.png', '-data');
	}, 'DATAarrow-down.png', 'entryCget' ],
	[ sub {
		$ib->entryConfigure('arrow-down.png', -data => 'new data');
		return $ib->entryCget('arrow-down.png', '-data');
	}, 'new data', 'entryConfigure' ],
	[ sub {
		$ib->refresh;
		return 1
	}, 1, 'refresh' ],
	[ sub {
		return $ib->indexColumnRow(0, 0);
		}, 0, 'indexColumnRow' ],
);

starttesting;

