use strict;
use warnings;
use Test::More tests => 29;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::CodeText') };

#$delay = 3500;
createapp;

my $text;
if (defined $app) {
	$text = $app->CodeText(
		-autoindent => 1,
		-autocomplete => 1,
		-tabs => '7m',
		-font => 'Monospace 12',
		-logcall => sub { print STDERR shift, "\n" },
#		-modifiedcall => sub { my $index = shift; print "index $index\n"; },
#		-readonly => 1,
		-syntax => 'XML',
	)->pack(
		-expand => 1,
		-fill => 'both',
	) if defined $app;

	$text->Subwidget('Statusbar')->Button(
		-text=> 'Reset',
		-relief => 'flat',
		-command => ['clear', $text], 
	)->pack(-side => 'left');

	$text->Subwidget('Statusbar')->Button(
		-text=> 'Load Ref file',
		-relief => 'flat',
		-command => ['load', $text, 't/ref_file.pl'], 
	)->pack(-side => 'left');

	$text->Subwidget('Statusbar')->Button(
		-text=> 'Bm new',
		-relief => 'flat',
		-command => ['bookmarkNew', $text], 
	)->pack(-side => 'left');

	$text->Subwidget('Statusbar')->Button(
		-text=> 'Bm clear',
		-relief => 'flat',
		-command => ['bookmarkRemove', $text], 
	)->pack(-side => 'left');

	my $menu;
	$menu = $app->Menu(
		-menuitems => [
			[ cascade => '~File',
				-menuitems => [
					[ command => '~Load', -command => sub {
						my $file = $app->getOpenFile;
						$text->load($file) if defined $file;
					}],
					[ command => '~Save', -command => sub {
						my $file = $app->getSaveFile;
						$text->save($file) if defined $file;
					}],
				]
			],
			[ cascade => '~Edit',
				-menuitems => [ $text->EditMenuItems ],
			],
			[ cascade => '~Search',
				-menuitems => $text->SearchMenuItems,
			],
			[ cascade => '~View',
				-menuitems => [ $text->ViewMenuItems ],
			],
			[ cascade => '~Bookmarks',
				-postcommand => sub { $text->bookmarkMenuPop($menu, 'Bookmarks') },
				-menuitems => [ $text->bookmarkMenuItems ],
			],
		],
	);
	$app->configure(-menu => $menu);
	$app->geometry('800x600+200+200');
}

#testing accessors
testaccessors($text, qw /Colored ColorInf FoldButtons highlightinterval linespercycle LoopActive NoHighlighting SaveFirstVisible SaveLastVisible/);

push @tests, (
	[ sub { return defined $text }, 1, 'CodeText widget created' ],
	[ sub { return $text->syntax }, 'XML', 'Syntax set to XML' ],
	[ sub { 
		$text->configure(-syntax => 'Perl');
		return $text->syntax 
	}, 'Perl', 'Syntax set to Perl' ],
	[ sub { 
		$text->load('Makefile.PL');
		pause(100);
		$text->bookmarkNew(12);
		return $text->bookmarked(12);
	}, 1, 'Line 12 of Makefile.PL bookmarked' ],
	[ sub { 
		$text->goTo('16.0');
		$text->bookmarkNew();
		return $text->bookmarked(16);
	}, 1, 'Line 16 of Makefile.PL bookmarked' ],
	[ sub {
		my @list = $text->bookmarkList;
		return \@list
	}, [ 12, 16 ], 'Bookmark list' ],
	[ sub { 
		$text->bookmarkRemove(12);
		return $text->bookmarked(12);
	}, '', 'Bookmark line 12 of Makefile.PL removed' ],
	[ sub {
		my @list = $text->bookmarkList;
		return \@list
	}, [ 16] , 'Bookmark list2' ],
	[ sub {
		for (10, 22, 28) {
			$text->bookmarkNew($_);
		}
		$text->goTo('1.0');
		$text->bookmarkNext;
		return $text->linenumber('insert');
	}, 10, 'Bookmark Next 10' ],
	[ sub {
		$text->bookmarkNext;
		return $text->linenumber('insert');
	}, 16, 'Bookmark Next 16' ],
	[ sub {
		$text->bookmarkNext;
		return $text->linenumber('insert');
	}, 22, 'Bookmark Next 22' ],
	[ sub {
		$text->bookmarkNext;
		return $text->linenumber('insert');
	}, 28, 'Bookmark Next 28' ],
	[ sub {
		$text->bookmarkNext;
		return $text->linenumber('insert');
	}, 28, 'Bookmark Last 28' ],
	[ sub {
		$text->bookmarkPrev;
		return $text->linenumber('insert');
	}, 22, 'Bookmark Previous 22' ],
	[ sub {
		$text->bookmarkPrev;
		return $text->linenumber('insert');
	}, 16, 'Bookmark Previous 16' ],
	[ sub {
		$text->bookmarkPrev;
		return $text->linenumber('insert');
	}, 10, 'Bookmark Previous 10' ],
	[ sub {
		$text->bookmarkPrev;
		return $text->linenumber('insert');
	}, 10, 'Bookmark First 10' ],
);


starttesting;


