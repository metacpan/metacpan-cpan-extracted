
use strict;
use warnings;
use Test::More tests => 139;
use Test::Tk;

use Data::Dumper;
use Tk;
require Tk::NoteBook;
require Tk::ROText;
BEGIN { use_ok('Tk::XText') };

createapp;

my $text;
my $utext;
my $rtext;
my $btext;
if (defined $app) {
	my $nb = $app->NoteBook->pack(-expand => 1, -fill => 'both');
	my $tp = $nb->add('Widget', -label => 'Widget');
	$text = $tp->XText(
		-modifycall => \&tmodified,
		-tabs => '7m',
		-font => 'Hack 12',
		-menuitems => [
			[command => 'Say something', -command => sub { print "Saying something\n"}],
		]
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	my $up = $nb->add('UPage', -label => 'Undo stack');
	$utext = $up->ROText(
		-tabs => '7m',
		-font => 'Hack 12',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	my $rp = $nb->add('RPage', -label => 'Redo stack');
	$rtext = $rp->ROText(
		-tabs => '7m',
		-font => 'Hack 12',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	my $bp = $nb->add('Buffer', -label => 'Buffer');
	$btext = $bp->ROText(
		-tabs => '7m',
		-font => 'Hack 12',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	my $pos = '';
	my $lines = '';
	my $size = '';
	my $ovr = '';
	my $mod = '';

	my $call;
	$call = sub {
		$pos = $text->index('insert');
		$lines = $text->linenumber('end - 1c');
		$size = length($text->get('1.0', 'end - 1c'));
		if ($text->OverstrikeMode) {
			$ovr = 'OVERWRITE',
		} else {
			$ovr = 'INSERT',
		}
		if ($text->editModified) {
			$mod = 'MODIFIED'
		} else {
			$mod = 'SAVED'
		}
		$app->after(500, $call);
	};
	
	my $sb = $app->Frame->pack(-fill => 'x');

	$sb->Label(
		-text => " Pos:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$pos, 
		-width => 8, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);

	$sb->Label(
		-text => " Lines:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$lines, 
		-width => 5, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);

	$sb->Label(
		-text => " Size:"
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$size, 
		-width => 8, -relief => 'groove')->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$ovr,
		-width => 11, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);
	$sb->Label(
		-textvariable => \$mod, 
		-width => 9, 
		-relief => 'groove'
	)->pack(-side => 'left', -pady => 2);
	$sb->Button(
		-text=> 'Reset', 
		-command => ['clear', $text], 
	)->pack(-side => 'left', -pady => 2);
	$sb->Button(
		-text=> 'Clear modified', 
		-command => sub {
			$text->clearModified(0);
			&tmodified;
		}
	)->pack(-side => 'left', -pady => 2);
	$sb->Button(
		-text=> 'Load Ref file',
		-command => ['load', $text, 'lib/Tk/CodeTextOld.pm'], 
	)->pack(-side => 'left');
	&$call;
}


sub tmodified {
	$utext->delete('1.0', 'end');
	$utext->insert('end', Dumper $text->UndoStack);
	$rtext->delete('1.0', 'end');
	$rtext->insert('end', Dumper $text->RedoStack);
	$btext->delete('1.0', 'end');
	my $buf = $text->Buffer;
	my $bstart = $text->BufferStart;
	my $mode = $text->BufferMode;
	my $mod = $text->BufferModified;
	$btext->insert('end', "buffer      :'$buf'\n");
	$btext->insert('end', "bufferstart :'$bstart'\n");
	$btext->insert('end', "buffermode  :'$mode'\n");
	$btext->insert('end', "modified    :'$mod'\n");
}

#testvalues
my $firstline = "one";
my $middleline =  "otwo\n";
my $secondline = "\ntwo\n";
my $original = "one\ntwo\n";
my $indentedline = "\tone\ntwo\n";
my $indentedsel = "\tone\n\ttwo\n";

my $commentline1 = "#one\ntwo\n";
my $commentsel1 = "#one\n#two\n";

my $commentline2 = "<<-one->>\ntwo\n";
my $commentsel2 = "<<-one\ntwo\n->>";

#some predifined tests and routines
my $init = [ sub { 
	$text->clear; 
	$text->insert('1.0', $original);
	$text->clearModified(0);
	return $text->get('1.0', 'end - 1c');
}, $original, 'Initialise with original text'];
my $ismodified = [ sub { return ($text->editModified >= 1) }, 1, 'Is modified'];
my $isnotmodified = [ sub { return $text->editModified }, 0, 'Is not modified'];
my $reset = [ sub { $text->clear; return $text->get('1.0', 'end - 1c') }, '', 'Reset widget'];

sub backspace {
	my $len = shift;
	$len = 1 unless defined $len;
	while ($len) {
		$text->Backspace;
		$len --;
	}
}

sub del {
	my $len = shift;
	$len = 1 unless defined $len;
	while ($len) {
		$text->Delete;
		$len --;
	}
	
}

sub gettext {
	return $text->get('1.0','end - 1c')
}

sub goTo {
	$text->goTo(shift);
}

sub enter {
	my $string = shift;
	while (length($string) ne 0) {
		$string =~ s/^([\s|\S])//;
		$text->InsertKeypress($1);
	}
}

sub ismodified {
	return $text->editModified(shift)
}

push @tests, (
	[ sub { return defined $text }, 1, 'XText widget created' ],
);

#testing accessors
my @accessors = qw(Buffer BufferMode BufferModified BufferReplace BufferStart);
for (@accessors) {
	my $method = $_;
	push @tests, [sub {
		my $default = $text->$method;
		my $res1 = $text->$method('blieb');
		my $res2 = $text->$method('quep');
		$text->$method($default);
		return (($res1 eq 'blieb') and ($res2 eq 'quep'));
	}, 1, "Accessor $method"];
}

push @tests, (

	#testing inserting and undo redo
	[ sub {
		$text->insert('1.0', $original);
		return gettext; 
	}, $original, 'Inserted text' ],
	
	$ismodified,

	[ sub {
		$text->undo;
		my $t = gettext;
		return gettext; 
	}, '', 'Undo Inserted text' ],
	
	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo Inserted text' ],

	$ismodified,

	[ sub {
		$text->undo;
		my $t = gettext;
		return gettext; 
	}, '', 'Undo Inserted text' ],
	
	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo Inserted text' ],

	$ismodified,
	$init,

	#testing indent line and undo redo
	[ sub {
		$text->markSet('insert', '1.0 lineend');
		$text->indent;
		return gettext; 
	}, $indentedline, 'Indented line' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Iindented line' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $indentedline, 'Redo Idented line' ],


	$ismodified,

	#testing unindent line and undo redo
	[ sub {
		$text->unindent;
		return gettext; 
	}, $original, 'Unindented line' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $indentedline, 'Undo Unindented line' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo Unidented line' ],

	#testing indent selection and undo redo
	$init,
	
	[ sub {
		$text->selectAll;
		$text->indent;
		return gettext; 
	}, $indentedsel, 'Indented selection' ],

	$ismodified,
	
	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Indented selection' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $indentedsel, 'Redo Idented selection' ],

	$ismodified,
	
	#testing unindent selection and undo redo
	[ sub {
		$text->selectAll;
		$text->unindent;
		return gettext; 
	}, $original, 'Unindented selection' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $indentedsel, 'Undo Unindented selection' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo Unidented selection' ],

	#testing comment line 1 with # and undo redo
	$init,

	[ sub {
		$text->configure(-slcomment => '#');
		$text->SetCursor('1.0 lineend');
		$text->comment;
		return gettext; 
	}, $commentline1, 'Comment line 1' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Comment line 1' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $commentline1, 'Redo Comment line 1' ],

	$ismodified,

	#testing uncomment line 1 and undo redo
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->uncomment;
		return gettext; 
	}, $original, 'UnComment line 1' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $commentline1, 'Undo UnComment line 1' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo UnComment line 1' ],

	#testing comment selection 1 and undo redo
	$init,

	[ sub {
		$text->selectAll;
		$text->comment;
		return gettext; 
	}, $commentsel1, 'Comment selection 1' ],

	$ismodified,
	
	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Comment selection 1' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext; 
	}, $commentsel1, 'Redo Comment selection 1' ],

	$ismodified,

	#testing uncomment selection 1 and undo redo
	[ sub {
		$text->selectAll;
		$text->uncomment;
		return gettext; 
	}, $original, 'UnComment selection 1' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $commentsel1, 'Undo UnComment selection 1' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo UnComment selection 1' ],

	#testing comment line 2 with '<<-', '->>' and undo/redo
	[ sub {
		$text->configure(-slcomment => undef);
		$text->configure(-mlcommentstart => '<<-');
		$text->configure(-mlcommentend => '->>');
		$text->unselectAll;
		$text->SetCursor('1.0 lineend');
		$text->comment;
		return gettext; 
	}, $commentline2, 'Comment line 2' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Comment line 2' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $commentline2, 'Redo Comment line 2' ],

	#testing uncomment line 2 and undo redo
	[ sub {
		$text->unselectAll;
		$text->SetCursor('0.0 lineend');
		$text->uncomment;
		return gettext; 
	}, $original, 'UnComment line 2' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $commentline2, 'Undo UnComment line 2' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo UnComment line 2' ],

	#testing comment selection 2 and undo redo
	[ sub {
		$text->selectAll;
		$text->comment;
		return gettext; 
	}, $commentsel2, 'Comment selection 2' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $original, 'Undo Comment selection 2' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $commentsel2, 'Redo Comment selection 2' ],

	#testing comment selection 2 and undo redo
	[ sub {
		$text->selectAll;
		$text->uncomment;
		return gettext; 
	}, $original, 'UnComment selection 2' ],

	[ sub {
		$text->undo;
		return gettext; 
	}, $commentsel2, 'Undo UnComment selection 2' ],

	[ sub {
		$text->redo;
		return gettext; 
	}, $original, 'Redo UnComment selection 2' ],

	#emptying document
	$reset,

	#undo/redo buffer testing
	[ sub {
		enter($original);
		return gettext; 
	}, $original, 'Enter some original' ],

	$ismodified,

	[ sub {
		$text->undo;
		$text->undo;
		$text->undo;
		return gettext;
	}, '', 'Undo x3, Simple undo' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		$text->redo;
		$text->redo;
		return gettext;
	}, $original, 'Redo x3, Simple redo' ],

	$ismodified,
	#backspace key buffering 1

	$init,

	[ sub {
		$text->goTo('end - 1c');
		backspace(5);
		return gettext;
	}, $firstline, 'Backspace x5' ],

	$ismodified,

	[ sub {
		$text->undo;
		$text->undo;
		return gettext;
	}, $original, 'Undo x2, Backspace undo' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		$text->redo;
		return gettext;
	}, $firstline, 'Redo x2, Backspace redo' ],

	$ismodified,

	#backspace key buffering 2
	$init,

	[ sub {
		$text->goTo('1.3');
		backspace(3);
		return gettext;
	}, $secondline, 'Backspace x 3 on first line' ],

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Backspace line 1' ],

	[ sub {
		$text->redo;
		return gettext;
	}, $secondline, 'Redo, Backspace line 1' ],

	#backspace key buffering 3
	$init,

	[ sub {
		$text->goTo('2.0');
		backspace(3);
		return gettext;
	}, $middleline, 'Backspace x 3 on beginning second line' ],

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Backspace x 3 on beginning second line' ],

	[ sub {
		$text->redo;
		return gettext;
	}, $middleline, 'Redo, Backspace x 3 on beginning second line' ],

	#delete buffer testing
	$init,
	
	[ sub {
		$text->goTo('1.3');
		del(5);
		return gettext;
	}, $firstline, 'Delete x 5x 3 on end first line' ],

	$ismodified,

	[ sub {
		$text->undo;
		$text->undo;
		return gettext;
	}, $original, 'Undo, Delete x 5x 3 on end first line' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		$text->redo;
		return gettext;
	}, $firstline, 'Redo, Delete x 5x 3 on end first line' ],

	$ismodified,
	$init,

	[ sub {
		$text->goTo('1.0');
		del(3);
		return gettext;
	}, $secondline, 'Delete x 3 beginning first line' ],

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Delete x 3 on beginning first line' ],

	#overstrike testing
	$init,

	[ sub {
		$text->OverstrikeMode(1);
		$text->goTo('1.2');
		enter('three');
		return gettext;
	}, "onthree\ntwo\n", 'OverstrikeMode' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, OverstrikeMode' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext;
	}, "onthree\ntwo\n", 'Redo, OverstrikeMode' ],

	$ismodified,

	#selection replace testing
	$init,
	
	[ sub {
		$text->selectAll;
		$text->ReplaceSelectionsWith("three\n");
		return gettext;
	}, "three\n", 'Replace selection' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Replace selection' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext;
	}, "three\n", 'Redo, Replace selection' ],

	$ismodified,
	
	#delete selection
	$init,

	[ sub {
		$text->selectAll;
		del;
		return gettext;
	}, "", 'Delete selection' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Delete selection' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext;
	}, "", 'Redo, Delete selection' ],

	$ismodified,
	
	#backspace selection
	$init,

	[ sub {
		$text->selectAll;
		backspace;
		return gettext;
	}, "", 'Backspace selection' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Backspace selection' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext;
	}, "", 'Redo, Backspace selection' ],

	$ismodified,
	
	#key a selection
	$init,

	[ sub {
		$text->selectAll;
		enter('a');
		return gettext;
	}, "a", 'Key a selection' ],

	$ismodified,

	[ sub {
		$text->undo;
		return gettext;
	}, $original, 'Undo, Key a selection' ],

	$isnotmodified,

	[ sub {
		$text->redo;
		return gettext;
	}, "a", 'Redo, Key a selection' ],

	$ismodified,
	
	#emptying document
	$reset,
);

starttesting;

