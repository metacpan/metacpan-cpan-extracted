use strict;
use warnings;
use Test::More tests => 51;
use Test::Tk;
require Tk::Photo;
require Tk::LabFrame;
#use Tk::DynaMouseWheelBind;
use Tk::PNG;

BEGIN {
	use_ok('Tk::ListBrowser::LBCanvas');
	use_ok('Tk::ListBrowser::Bar');
	use_ok('Tk::ListBrowser::Column');
	use_ok('Tk::ListBrowser::Item');
	use_ok('Tk::ListBrowser::List');
	use_ok('Tk::ListBrowser::Row');
	use_ok('Tk::ListBrowser');
};

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
if (defined $app) {
#	$app->DynaMouseWheelBind('Tk::ListBrowser::LBCanvas');
	$image = $app->Photo(
		-file => "t/icons/edit-cut.png",
		-format => 'png',
	);

	$ib = $app->ListBrowser(
		#options to play with
#		-arrange => 'list',
#		-arrange => 'row',
#		-filteron => 1,
#		-motionselect => 1,
#		-nofilter => 1,
#		-textanchor => 'w',
#		-textside => 'right',
#		-textjustify => 'left',
#		-height => 200,
#		-width => 200,

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
	my $bf = $app->LabFrame(
		-label => 'Tools',
		-labelside => 'acrosstop',
	)->pack(-fill => 'x');
	$bf->Button(
		-command => sub { $ib->clear },
		-text => 'Clear',
	)->pack(-side => 'left');
	$bf->Button(
		-command => sub { $ib->refresh },
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
}

testaccessors($item, qw/cimage crect column ctext data hidden image row text/);
testaccessors($handler, qw/cellHeight cellImageHeight cellImageWidth cellTextHeight cellTextWidth cellWidth/);

push @tests, (
	[ sub { return defined $ib }, 1, 'ListBrowser widget created' ],
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
		$ib->refresh;
		my @l = $ib->infoList;
		my $size = @l;
		return $size
	}, 744, 'refresh' ],
	[ sub {
		pause(50);
		return $ib->index('accessories-text-editor.png');
		}, 0, 'index' ],
	[ sub {
		return $ib->indexColumnRow(0, 0);
		}, 0, 'indexColumnRow' ],
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
);

starttesting;

