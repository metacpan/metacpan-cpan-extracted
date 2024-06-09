use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;
require Tk::CodeText;
require Tk::Balloon;
use Data::Dumper;
BEGIN { use_ok('Tk::CodeText::TagsEditor') };

#$delay = 3000;

createapp;

my @defaultattributes = (
	'Alert' => [-background => '#DB7C47', -foreground => '#FFFFFF'],
	'Annotation' => [-foreground => '#5A5A5A'],
	'Attribute' => [-foreground => '#00B900', -weight => 'bold'],
	'BaseN' => [-foreground => '#0000A9'],
	'BuiltIn' => [-foreground => '#B500E6'],
	'Char' => [-foreground => '#FF00FF'],
	'Comment' => [foreground => '#5A5A5A', -slant => 'italic'],
	'CommentVar' => [-foreground => '#5A5A5A', -slant => 'italic', -weight => 'bold'],
	'Constant' => [-foreground => '#0000FF', -weight => 'bold'],
	'ControlFlow' => [-foreground => '#0062AD'],
	'DataType' => [-foreground => '#0080A8', -weight => 'bold'],
	'DecVal' => [-foreground => '#9C4E2B'],
	'Documentation' => [-foreground => '#7F5A41', -slant => 'italic'],
	'Error' => [-background => '#FF0000', -foreground => '#FFFF00'],
	'Extension' => [-foreground => '#9A53D1'],
	'Float' => [-foreground => '#9C4E2B', -weight => 'bold'],
	'Function' => [-foreground => '#008A00'],
	'Import' => [-foreground => '#950000', -slate => 'italic'],
	'Information' => [foreground => '#5A5A5A', -weight => 'bold'],
	'Keyword' => [-weight => 'bold'],
	'Normal' => [],
	'Operator' => [-foreground => '#85530E'],
	'Others' => [-foreground => '#FF6200'],
	'Preprocessor' => [-slant => 'italic'],
	'RegionMarker' => [-background => '#00CFFF'],
	'SpecialChar' => [-foreground => '#9A53D1'],
	'SpecialString' => [-foreground => '#FF4449'],
	'String' => [-foreground => '#FF0000'],
	'Variable' => [-foreground => '#0000FF', -weight => 'bold'],
	'VerbatimString' => [-foreground => '#FF4449', -weight => 'bold'],
	'Warning' => [-background => '#FFFF00', -foreground => '#FF0000'],
);

my $tags;
if (defined $app) {
	my $text = $app->CodeText(
		-font => 'Monospace 12',
	);
	
	$tags = $app->TagsEditor(
		-defaultbackground => $text->Subwidget('XText')->cget('-background'),
		-defaultforeground => $text->Subwidget('XText')->cget('-foreground'),
		-defaultfont => $text->Subwidget('XText')->cget('-font'),
		-balloon => $app->Balloon,
		-historyfile => 't/color_history',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
	$text->destroy;
 	$app->after(500, sub { 
		$tags->put(@defaultattributes);
		$tags->updateAll;
 	});
	my $bframe = $app->Frame->pack(-fill => 'x');
	$bframe->Button(
		-text => 'Get',
		-command => sub { print Dumper $tags->get },
	)->pack(-side => 'left');
	$app->geometry('500x600+200+200');
}

push @tests, (
	[ sub { return defined $tags }, 1, 'TagsEditor widget created' ],
);

starttesting;

