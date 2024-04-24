use strict;
use warnings;
use Test::More tests => 15;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::CodeText') };

# $delay = 3000;
createapp;

my $text;
if (defined $app) {
	$text = $app->CodeText(
		-autoindent => 1,
		-tabs => '7m',
		-font => 'Monospace 12',
		-modifiedcall => sub { my $index = shift; print "index $index\n"; },
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

	$app->configure(-menu => $app->Menu(
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
		],
	));
	$app->geometry('800x600+200+200');
}

#testing accessors
my @accessors = qw(Colored ColorInf FoldButtons FoldInf highlightinterval LoopActive NoHighlighting SaveFirstVisible SaveLastVisible);
for (@accessors) {
	my $method = $_;
	push @tests, [sub {
		my $default = $text->$method;
		$text->$method('blieb');
		my $res1 = $text->$method;
		$text->$method('quep');
		my $res2 = $text->$method;
		$text->$method($default);
		return (($res1 eq 'blieb') and ($res2 eq 'quep'));
	}, 1, "Accessor $method"];
}

push @tests, (
	[ sub { return defined $text }, 1, 'CodeText widget created' ],
	[ sub { return $text->syntax }, 'XML', 'Syntax set to XML' ],
	[ sub { 
		$text->configure(-syntax => 'Perl');
		return $text->syntax 
	}, 'Perl', 'Syntax set to Perl' ],
);


starttesting;


