package Tk::ROTextHighlight;

use vars qw($VERSION);
$VERSION = '1.2';
use base qw(Tk::Derived Tk::ROText);
use Tk qw(Ev);
use strict;
use Storable;
use File::Basename;

my $blockHighlight = 0;     #USED TO PREVENT RECURSIVE CALLS TO RE-HIGHLIGHT!
my $nodoEvent = 0;          #USED TO PREVENT REPEATING (RUN-AWAY) SCROLLING!
Construct Tk::Widget 'ROTextHighlight';

sub Populate {
	my ($cw,$args) = @_;
	$cw->SUPER::Populate($args);
	$cw->ConfigSpecs(
		-autoindent => [qw/PASSIVE autoindent Autoindent/, 0],
		-match => [qw/PASSIVE match Match/, '[]{}()'],
		-matchoptions	=> [qw/METHOD matchoptions Matchoptions/, 
			[-background => 'red', -foreground => 'yellow']],
		-indentchar => [qw/PASSIVE indentchar Indentchar/, "\t"],
		-disablemenu => [qw/PASSIVE disablemenu Disablemenu/, 0],
		-commentchar => [qw/PASSIVE commentchar Commentchar/, "#"],
		-colorinf => [qw/PASSIVE undef undef/, []],
		-colored => [qw/PASSIVE undef undef/, 0],
		-syntax	=> [qw/PASSIVE syntax Syntax/, 'None'],
		-rules	=> [qw/PASSIVE undef undef/, undef],
		-rulesdir	=> [qw/PASSIVE rulesdir Rulesdir/, ''],
		-updatecall	=> [qw/PASSIVE undef undef/, sub {}],
		-noRulesMenu => [qw/PASSIVE undef undef/, 0],       #JWT: ADDED FEATURE.
		-noSyntaxMenu => [qw/PASSIVE undef undef/, 0],      #JWT: ADDED FEATURE.
		-noRulesEditMenu => [qw/PASSIVE undef undef/, 0],   #JWT: ADDED FEATURE.
		-noSaveRulesMenu => [qw/PASSIVE undef undef/, 0],   #JWT: ADDED FOR BACKWARD COMPATABILITY.
		-noPlugInit => [qw/PASSIVE undef undef/, 0],        #JWT: ADDED FOR BACKWARD COMPATABILITY.
		-highlightInBackground => [qw/PASSIVE undef undef/, 0],    #JWT: SELF-EXPLANATORY.
		DEFAULT => [ 'SELF' ],
	);
	$cw->bind('<Configure>', sub { $cw->highlightVisual });
	$cw->bind('<Return>', sub { $cw->doAutoIndent });
	$cw->markSet('match', '0.0');
	$cw->bind('<Control-p>', \&jumpToMatchingChar);
}

sub jumpToMatchingChar  #ADDED 20060630 JWT TO CAUSE ^p TO WORK LIKE VI & SUPERTEXT - JUMP TO MATCHING CHARACTER!
{
	my $cw = shift;
	$cw->markSet('insert', $cw->index('insert'));
	my $pm = -1;
	eval { $pm = $cw->index('MyMatch'); };
	if ($pm >= 0)
	{
		my $prevMatch = $cw->index('insert');
		$prevMatch .= '.0'  unless ($prevMatch =~ /\./o);
		$cw->markSet('insert', $cw->index('MyMatch'));
		$cw->see('insert');
		$cw->markSet('MyMatch', $prevMatch);
	}
}

sub ClassInit   #JWT: ADDED FOR VI-LIKE Control-P JUMP TO MATCHING BRACKET FEATURE.
{
	my ($class,$w) = @_;
	
	$class->SUPER::ClassInit($w);

	# reset default Tk::Text binds
	$w->bind($class,	'<Control-p>', sub {} );
	return $class;
}

sub clipboardCopy {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->SUPER::clipboardCopy(@_);
	}
}

sub clipboardCut {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->SUPER::clipboardCut(@_);
	}
}

sub clipboardPaste {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->tagRemove('sel', '1.0', 'end');
		return;
	}
	$cw->SUPER::clipboardPaste(@_);
}

sub delete {
	my $cw = shift;
	my $begin = $_[0];
	if (defined($begin)) {
		$begin = $cw->linenumber($begin);
	} else { 
		$begin = $cw->linenumber('insert');
	};
	my $end = $_[1];
	if (defined($end)) {
		$end = $cw->linenumber($end);
	} else { 
		$end = $begin;
	};
	$cw->SUPER::delete(@_);
	$cw->highlightCheck($begin, $end);
}

sub doAutoIndent {
	my $cw = shift;
	if ($cw->cget('-autoindent')) {
		my $i = $cw->index('insert linestart');
		if ($cw->compare($i, ">", '0.0')) {
			my $s = $cw->get("$i - 1 lines", "$i - 1 lines lineend");
#			if ($s =~ /\S/)  #JWT: UNCOMMENT TO CAUSE SUBSEQUENT BLANK LINES TO NOT BE AUTOINDENTED.
#			{
				#$s =~ /^(\s+)/;  #CHGD. TO NEXT 20060701 JWT TO FIX "e" BEING INSERTED INTO LINE WHEN AUTOINDENT ON?!
				$s =~ /^(\s*)/o;
				if ($1) {
					$cw->insert('insert', $1);
				}
				$cw->insert('insert', $cw->cget('-indentchar'))
						if ($s =~ /\{\s*$/o);   #ADDED 20060701 JWT - ADD AN INDENTION IF JUST OPENED A BLOCK!
#			}
		}
	}
}

sub EditMenuItems {
	my $cw = shift;
	return [
		@{$cw->SUPER::EditMenuItems},
		["command"=>'Select', -command => [$cw => 'adjustSelect']]
	];
}

sub EmptyDocument {
	my $cw = shift;
	my @r = $cw->SUPER::EmptyDocument(@_);
	$cw->highlightPurge(1);
	return @r
}

sub highlight {
	my ($cw, $begin, $end) = @_;
#	return $begin  if ($blockHighlight);   #PREVENT RECURSIVE CALLING WHILST ALREADY REHIGHLIGHTING!
	$blockHighlight = 1;
	if (not defined($end)) { $end = $begin + 1};
	#save selection and cursor position
	my @sel = $cw->tagRanges('sel');
#	my $cursor = $cw->index('insert'); 
	#go over the source code line by line.
	while ($begin < $end) {
		$cw->highlightLine($begin);
		$begin++; #move on to next line.
	};
	#restore original cursor and selection
#	$cw->markSet('insert', $cursor);
#1	if ($sel[0]) {
#1		$cw->tagRaise('sel');   #JWT:REMOVED 20060703 SO THAT HIGHLIGHTING STAYS ON SELECTED STUFF AFTER SELECTION MOVES OVER UNTAGGED TEXT.
#1	};
	$blockHighlight = 0;
	return $begin;
}

sub highlightCheck {
	my ($cw, $begin, $end) = @_;
	my $col = $cw->cget('-colored');
	my $cli = $cw->cget('-colorinf');
	if ($begin <= $col) {
		#The operation occurred in an area that was highlighted already
		if ($begin < $end) {
			#it was a multiline operation, so highlighting is not reliable anymore
			#restart hightlighting from the beginning of the operation.
			$cw->highlightPurge($begin);
		} else {
			#just re-highlight the modified line.
			my $hlt = $cw->highlightPlug;
			my $i = $cli->[$begin];
			$cw->highlight($begin);
			if (($col < $cw->linenumber('end')) and (not $hlt->stateCompare($i))) {
			#the proces ended inside a multiline token. try to fix it.
				$cw->highlightPurge($begin);
			}
		};
		$cw->matchCheck;
	} else {
		$cw->highlightVisual;
	}
}

sub highlightLine {
	my ($cw, $num) = @_;
	my $hlt = $cw->highlightPlug;
	my $cli = $cw->cget('-colorinf');
	my $k = $cli->[$num - 1];
	$hlt->stateSet(@$k);
#	remove all existing tags in this line
	my $begin = "$num.0"; my $end = $cw->index("$num.0 lineend");
	my $rl = $hlt->rules;
	foreach my $tn (@$rl) {
		$cw->tagRemove($tn->[0], $begin, $end);
	}	
	my $txt = $cw->get($begin, $end); #get the text to be highlighted
	my @v;
	if ($txt) { #if the line is not empty
		my $pos = 0;
		my $start = 0;
		my @h = $hlt->highlight("$txt\n");     #JWT:  ADDED "\n" TO MAKE KATE WORK!
		while (@h ne 0) {
			$start = $pos;
			$pos += shift @h;
			my $tag = shift @h;
			$cw->tagAdd($tag, "$num.$start", "$num.$pos");
		};
		$cw->DoOneEvent(2)  unless ($nodoEvent
				|| !$cw->cget('-highlightInBackground'));       #DON'T PREVENT USER-INTERACTION WHILE RE-HILIGHTING!
	};
	$cli->[$num] = [ $hlt->stateGet ];
}

sub highlightPlug {
	my $cw = shift;
	my $plug = $cw->Subwidget('formatter');
	my $syntax = $cw->cget('-syntax');
	$syntax =~ s/\:\:.*$//o;
	my $rules = $cw->cget('-rules');
	if (not defined($plug)) {
		$plug = $cw->highlightPlugInit;
	} elsif (ref($syntax)) {
		if ($syntax ne $plug) {
			$plug = $cw->highlightPlugInit;
		}
	} elsif ($syntax ne $plug->syntax) {
		$cw->rulesDelete;
		$plug = $cw->highlightPlugInit;
		$cw->highlightPurge(1);
	} elsif (defined($rules)) {
#		if ($rules ne $plug->rules) {   #JWT: CHGD TO NEXT TO PREVENT INFINITE RECURSION WHEN "None" HIGHLIGHTER IS USED!
		if ($#{$rules} >= 0 && $rules ne $plug->rules) {
			$cw->rulesDelete;
			$plug->rules($rules);
			$cw->rulesConfigure;
			$cw->highlightPurge(1);
		}
	} else {
		$cw->rulesDelete;
		$cw->highlightPlugInit;
		$cw->highlightPurge(1);
	}
	return $plug
}

sub highlightPlugInit {
	my $cw = shift;
	my $syntax = $cw->cget('-syntax');
	if (not defined($cw->cget('-rules'))) { $cw->rulesFetch };
	my $plug;
	my $lang = '';
	if (ref($syntax)) {
		$plug = $syntax;
	} else {
	$lang = $1  if ($syntax =~ s/\:\:(.*)$//o);
		my @opt = ();
		if (my $rules = $cw->cget('-rules')) {
			push(@opt, $rules);
		}
		my $evalStr = "require Tk::TextHighlight::$syntax; \$plug = new Tk::TextHighlight::$syntax("
			.($lang ? "'$lang', " : '') . "\@opt);";
		eval $evalStr;
		#JWT: ADDED UNLESS 20060703 TO PROPERLY INITIALIZE RULES FROM PLUGIN, IF NO .rules FILE DEFINED.
		unless ($@ || !defined($plug) || !defined($plug->rules)
				|| $cw->cget('-noPlugInit'))
		{
			my $rules = $plug->rules;
			$cw->configure(-rules => \@$rules);
		}
	}
	$cw->Advertise('formatter', $plug);
	$cw->rulesConfigure;
	my $bg = $cw->cget(-background);
	my ($red, $green, $blue) = $cw->rgb($bg);   #JWT: NEXT 11 ADDED 20070802 TO PREVENT INVISIBLE TEXT!
	my @rgb = sort {$b <=> $a} ($red, $green, $blue);
	my $max = $rgb[0]+$rgb[1];  #TOTAL BRIGHTEST 2.
	my $daytime = 1;
	my $currentrules = $plug->rules;
	if ($max <= 52500) {
		$daytime = 0;
		#print "-NIGHT 65!\n";
		for (my $k=0;$k<=$#{$currentrules};$k++)
		{
			if ($currentrules->[$k]->[2] eq 'black')
			{
				$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],'white');
			}
		};
	}
	for (my $k=0;$k<=$#{$currentrules};$k++)
	{
		if (defined($currentrules->[$k]->[2]) and $currentrules->[$k]->[2] eq $bg)
		{
			$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],($daytime ? 'black' : 'white'));
		}
	};
	$cw->update;
	unless ($cw->cget('-noSyntaxMenu'))  #JWT:  ADDED TO ENSURE VIEW RADIO-BUTTON PROPERLY INITIALIZED/SET.
	{
		my @kateMenus;
		my $ViewSyntaxMenu = $cw->menu->entrycget('View','-menu')->entrycget('Syntax','-menu');
		my $lastMenuIndex = $ViewSyntaxMenu->index('end');

		#WE MUST FETCH THE VARIABLE REFERENCE USED BY THE "View" MENU RADIO-BUTTONS SO 
		#THAT OUR NEW RADIO BUTTONS SHARE SAME VARIABLE (OTHERWISE, WILL HAVE >1 LIT AT
		#SAME TIME!

		my $var;
		foreach my $i (0..$lastMenuIndex)
		{
			if ($ViewSyntaxMenu->type($i) =~ /radiobutton/o)
			{
				$var = $ViewSyntaxMenu->entrycget($i, '-variable');
				tie $$var,'Tk::Configure',$cw,'-syntax';
				unless (ref($syntax))
				{
					$$var = $lang ? ($syntax.'::'.$lang) : $syntax;
				}
				last;
			}
		}
	}
	return $plug;
}

sub highlightPlugList {
	my $cw = shift;
	my @ml = ();
	my $haveKate = 0;
	foreach my $d (@INC) {
		my @fl = <$d/Tk/TextHighlight/*.pm>;
		foreach my $file (@fl) {
			my ($name, $path, $suffix) = fileparse($file, "\.pm");
			if ($name eq 'Kate') {   #JWT:ADDED THIS PART OF CONDITIONAL 20160118:
				eval 'use Syntax::Highlight::Engine::Kate; $haveKate = 1; 1'  unless ($haveKate);
				if ($haveKate) {
					unless (grep { ($name eq $_) } @ml) { push(@ml, $name); };
				}
#CHGD. TO NEXT 20160119:			}			} elsif (($name ne 'None') and ($name ne 'Template')) {
			} elsif ($name !~ /^(?:None|Template|RulesEditor)/o) {
				#avoid duplicates
				unless (grep { ($name eq $_) } @ml) { push(@ml, $name); };
			}
		}
	}
	return sort @ml;
}

sub highlightPurge {
	my ($cw, $line) = @_;
	$cw->configure('-colored' => $line);
	my $cli = $cw->cget('-colorinf');
	if (@$cli) { splice(@$cli, $line) };
	$cw->highlightVisual;
}

sub highlightVisual {
	my $cw = shift;
	return  if ($blockHighlight);
	my $end = $cw->visualend;
	my $col = $cw->cget('-colored');
	if ($col < $end) {
		$col = $cw->highlight($col, $end);
		$cw->configure(-colored => $col);
	};
	$cw->matchCheck;
}

sub insert {
	my $cw = shift;
	my $pos = shift;
	$pos = $cw->index($pos);
	my $begin = $cw->linenumber("$pos - 1 chars");
	$cw->SUPER::insert($pos, @_);
	$cw->highlightCheck($begin, $cw->linenumber("insert lineend"));
}

sub Insert {
	my $cw = shift;
	$cw->SUPER::Insert(@_);
	$cw->see('insert');
}

sub InsertKeypress {
	my ($cw,$char) = @_;
	if ($char ne '') {
		my $index = $cw->index('insert');
		my $line = $cw->linenumber($index);
		if ($char =~ /^\S$/o and !$cw->OverstrikeMode and !$cw->tagRanges('sel')) {
			my $undo_item = $cw->getUndoAtIndex(-1);
			if (defined($undo_item) &&
				($undo_item->[0] eq 'delete') &&
				($undo_item->[2] == $index)
			) {
				$cw->Tk::Text::insert($index,$char);
				$undo_item->[2] = $cw->index('insert');
				$cw->highlightCheck($line, $line);
				$cw->see('insert');   #ADDED 20060703 TO ALLOW USER TO SEE WHAT HE'S TYPING PAST END OF LINE (THIS IS BROKEN IN TEXTUNDO TOO).
				return;
			}
		}
		$cw->addGlobStart;
		$cw->Tk::Text::InsertKeypress($char);
		$cw->addGlobEnd;
	}
}

sub linenumber {
	my ($cw, $index) = @_;
	if (not defined($index)) { $index = 'insert'; }
	my $id = $cw->index($index);
	my ($line, $pos ) = split(/\./o, $id);
	return $line;
}

sub Load {
	my $cw = shift;
	my @r = $cw->SUPER::Load(@_);
	$cw->highlightVisual;
	return @r;
}

sub matchCheck {
	my $cw = shift;
	my $c = $cw->get('insert', 'insert + 1 chars');
	my $p = $cw->index('match');
	if ($p ne '0.0') {
		$cw->tagRemove('Match', $p, "$p + 1 chars");
		$cw->markSet('match', '0.0');
		$cw->markUnset('MyMatch');
	}
	if ($c) {
		my $v = $cw->cget('-match');
		my $p = index($v, $c);
		if ($p ne -1) { #a character in '-match' has been detected.
			my $count = 0;
			my $found = 0;
			if ($p % 2) {
				my $m = substr($v, $p - 1, 1);
				$cw->matchFind('-backwards', $c, $m, 
					$cw->index('insert'),
#					$cw->index('@0,0'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
					$cw->index('0.0'),
				);
			} else {
				my $m = substr($v, $p + 1, 1);
#				print "searching -forwards, $c, $m\n";
				$cw->matchFind('-forwards', $c, $m,
					$cw->index('insert + 1 chars'),
#					$cw->index($cw->visualend . '.0 lineend'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
					$cw->index('end'),
				);
			}
		}
	}
	$cw->updateCall;
}

sub matchFind {
	my ($cw, $dir, $char, $ochar, $start, $stop) = @_;
	#first of all remove a previous match highlight;
	my $pattern = "\\$char|\\$ochar";
	my $found = 0;
	my $count = 0;
	while ((not $found) and (my $i = $cw->search(
		$dir, '-regexp', '-nocase', '--', $pattern, $start, $stop
	))) {
		my $k = $cw->get($i, "$i + 1 chars");
#		print "found $k at $i and count is $count\n";
		if ($k eq $ochar) {
			if ($count > 0) {
#				print "decrementing count\n";
				$count--;
				if ($dir eq '-forwards') {
					$start = $cw->index("$i + 1 chars");
				} else {
					$start = $i;
				}
			} else {
#				print "Found !!!\n";
				$cw->markSet('match', $i);
				$cw->tagAdd('Match', $i, "$i + 1 chars");
				$cw->markSet('MyMatch', $i);
				$cw->tagRaise('Match');
				$found = 1;
			}
		} elsif ($k eq $char) {
#			print "incrementing count\n";
			$count++;
			if ($dir eq '-forwards') {
				$start = $cw->index("$i + 1 chars");
			} else {
				$start = $i;
			}
		} elsif ($i eq $start) {
			$found = 1;
		}
	}
}

sub matchoptions {
	my $cw = shift;
	if (my $o = shift) {
		my @op = ();
		if (ref($o)) {
			@op = @$o;
		} else {
			@op = split(/\s+/o, $o);
		}
		$cw->tagConfigure('Match', @op);
	}
}


sub PostPopupMenu {
	my $cw = shift;
	my @r;
	if (not $cw->cget('-disablemenu')) {
		@r = $cw->SUPER::PostPopupMenu(@_);		
	}
}

sub rulesConfigure {
	my $cw = shift;
	if (my $plug = $cw->Subwidget('formatter')) {
		my $rules = $plug->rules;
		my @r = @$rules;
		foreach my $k (@r) {
			$cw->tagConfigure(@$k);
		};
		$cw->configure(-colored => 1, -colorinf => [[ $plug->stateGet]]);
	}
}

sub setRule     #ADDED 20060530 JWT TO PERMIT CHANGING INDIVIDUAL RULES.
{
	my $cw = shift;
	my @rule = @_;

	if (my $plug = $cw->Subwidget('formatter'))
	{
		my $rules = $plug->rules;
		my @r = @$rules;
		for (my $k=0;$k<=$#r;$k++)
		{
			if ($rule[0] eq $r[$k]->[0])
			{
				@{$r[$k]} = @rule;
			}
		};
		$cw->configure(-rules => \@r);
	}
}

sub rulesDelete {
	my $cw = shift;
	if (my $plug = $cw->Subwidget('formatter')) {
		my $rules = $plug->rules;
		foreach my $r (@$rules) {
			$cw->tagDelete($r->[0]);
		}
	}
}


sub rulesEdit {
	my $cw = shift;
	require Tk::TextHighlight::RulesEditor;
	$cw->RulesEditor(
		-class => 'Toplevel',
	);
}

sub rulesFetch {
	my $cw = shift;
	my $dir = $cw->cget('-rulesdir');
	my $syntax = $cw->cget('-syntax');
	$cw->configure(-rules => undef);
#	print "rulesFetch called\n";
	my $result = 0;
	if ($dir and (-e "$dir/$syntax.rules")) {
		my $file = "$dir/$syntax.rules";
#		print "getting $file\n";
		if (my $rl = retrieve("$dir/$syntax.rules")) {
#			print "configuring\n";
			$cw->configure(-rules => $rl);
			$result = 1;
		}
	}
	return $result;
}

sub rulesSave {
	my $cw = shift;
	my $dir = $cw->cget('-rulesdir');
#	print "rulesSave called\n";
	if ($dir) {
		my $syntax = $cw->cget('-syntax');
		my $file = "$dir/$syntax.rules";
		store($cw->cget('-rules'), $file);
	}
}

sub scan {
	my $cw = shift;
	my @r = $cw->SUPER::scan(@_);
	$cw->highlightVisual;
	return @r;
}

sub selectionModify {
	my ($cw, $char, $mode) = @_;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges eq 2) {
		my $start = $cw->index($ranges[0]);
		my $end = $cw->index($ranges[1]);
#		print "doing from $start to $end\n";
		while ($cw->compare($start, "<", $end)) {
#			print "going to do something\n";
			if ($mode) {
				if ($cw->get("$start linestart", "$start linestart + 1 chars") eq $char) {
					$cw->delete("$start linestart", "$start linestart + 1 chars");
				}
			} else {
				$cw->insert("$start linestart", $char)
			}
			$start = $cw->index("$start + 1 lines");
		}
		$cw->tagAdd('sel', @ranges);
	}
}

# SelectTo --
# This procedure is invoked to extend the selection, typically when
# dragging it with the mouse. Depending on the selection mode (character,
# word, line) it selects in different-sized units. This procedure
# ignores mouse motions initially until the mouse has moved from
# one character to another or until there have been multiple clicks.
#
# Arguments:
# w - The text window in which the button was pressed.
# index - Index of character at which the mouse button was pressed.
sub SelectTo
{
	my ($w, $index, $mode)= @_;
	$Tk::selectMode = $mode if defined ($mode);
	my $cur = $w->index($index);
	my $anchor = $w->index('insert');
	$Tk::mouseMoved = ($w->compare($cur,'!=',$anchor)) ? 1 : 0;
	$Tk::selectMode = 'char' unless (defined $Tk::selectMode);
	$mode = $Tk::selectMode;
	my ($first,$last);
	if ($mode eq 'char') {
		if ($w->compare($cur,'<','anchor')) {
			$first = $cur;
			$last = 'anchor';
		} else {
			$first = 'anchor';
			$last = $cur
		}
	} elsif ($mode eq 'word') {
		if ($w->compare($cur,'<','anchor')) {
			$first = $w->index("$cur wordstart");
			$last = $w->index('anchor - 1c wordend')
		} else {
			$first = $w->index('anchor wordstart');
			$last = $w->index("$cur wordend")
		}
	} elsif ($mode eq 'line') {		if ($w->compare($cur,'<','anchor')) {
			$first = $w->index("$cur linestart");
			$last = $w->index('anchor - 1c lineend + 1c')
		} else {
			$first = $w->index('anchor linestart');
			$last = $w->index("$cur lineend + 1c")
		}
	}
	if ($Tk::mouseMoved || $Tk::selectMode ne 'char') {
		$w->tagRemove('sel','1.0',$first);
		$w->tagAdd('sel',$first,$last);
		$w->tagRemove('sel',$last,'end');
		$w->idletasks;
	}
}

sub adjustSelect {
	my ($w) = @_;
	my $Ev = $w->XEvent;
	$w->SelectTo($Ev->xy,'char');
}

sub syntax {
	my $cw = shift;
	if (@_) {
		my $name = shift;
		my $fm;
		eval ("require Tk::TextHighlight::$name;	\$fm = new Tk::TextHighlight::$name(\$cw);");
		$cw->Advertise('formatter', $fm);
		$cw->configure('-langname' => $name);
	}
	return $cw->cget('-langname');
}

sub yview {
	my $cw = shift;
	my @r = ();
	if (@_) {
		@r = $cw->SUPER::yview(@_);
		if ($_[1] > 0) {   #ONLY RE-HIGHLIGHT IF SCROLLING DOWN (PREV. LINES ALREADY HIGHLIGHTED)!
			my ($p) = caller;
			$nodoEvent = 1  if ($p =~ /scroll/io);   #THIS PREVENTS REPEATING (RUN-AWAY) SCROLLING!
			$cw->highlightVisual;
		}
	} else {
		@r = $cw->SUPER::yview;
	}
	return @r;
}

sub see {
	my $cw = shift;
	my @r = $cw->SUPER::see(@_);
	$cw->highlightVisual;
	return @r
}

sub updateCall {
	my $cw = shift;
	my $call = $cw->cget('-updatecall');
	&$call;
	$nodoEvent = 0;
}

sub ViewMenuItems {
	my $cw = shift;
	my $s;
	tie $s,'Tk::Configure',$cw,'-syntax';
	my @stx = ('None', $cw->highlightPlugList);
	my @rad = (['command' => 'Reset', -command => sub {
		$cw->configure('-rules' => undef);
		$cw->highlightPlug;
	}]);
	foreach my $n (@stx) {
		push(@rad, [
			'radiobutton' => $n,
			-variable => \$s,
			-value => $n,
			-command => sub {
				$cw->configure('-rules' => undef);
				$cw->highlightPlug;
			}
		]);
	}
	my $dir = $cw->cget('-rulesdir');
	my $syntax = $cw->cget('-syntax');
	my $menuExt = \@{$cw->SUPER::ViewMenuItems};
	unless ($cw->cget('-noRulesMenu'))
	{
		push (@{$menuExt},
				['cascade'=>'Syntax',
					-menuitems => [@rad],
				])  unless ($cw->cget('-noSyntaxMenu'));
		push (@{$menuExt},
				['command'=>'Rules Editor',
					-command => sub { $cw->rulesEdit },
				])  unless ($cw->cget('-noRulesEditMenu'));
		push (@{$menuExt},
				['command'=>'Save Rules',
					-command => sub { $cw->rulesSave },
				])  if (!$cw->cget('-noSaveRulesMenu') && $dir 
						&& (-w $dir));
	}
	return $menuExt;
}

sub visualend {
	my $cw = shift;
	my $end = $cw->linenumber('end - 1 chars');
	my ($first, $last) = $cw->Tk::Text::yview;
	my $vend = int($last * $end) + 2;
	if ($vend > $end) {
		$vend = $end;
	}
	return $vend;
}

sub fetchKateInfo   #FETCH LISTS OF KATE LANGUAGES AND FILE EXTENSION PATTERNS W/O KATE:
{
	#IT IS NECESSARY TO FETCH THIS INFORMATION W/O USING KATE METHODS SINCE WE MAY NOT
	#HAVE CREATED A KATE OBJECT WHEN THIS IS NEEDED!
	#We return 3 hash-references:  1st can be passed to addkate2viewmenu() to add the 
	#Kate languages to the Syntax.View menu.  the keys are "Kate::language" and the 
	#values are what's needed to instantiate Kate for that language.  the 2nd is 
	#a list of file-extension pattern suitable for matching against file-names and 
	#the values are the reccomended Kate language for that file-extension.

	my $cw = shift;

	my (%sectionHash, %extHash, %syntaxHash);

	foreach my $i (@INC)
	{
		if (-e "$i/Syntax/Highlight/Engine/Kate.pm"
				&& open KATE, "$i/Syntax/Highlight/Engine/Kate.pm")
		{
			my $inExtensions = 0;
			my $inSyntaxes = 0;
			my $inSections = 0;
			while (<KATE>)
			{
				chomp;
				$inExtensions = 1  if (/\$self\-\>\{\'extensions\'\}\s*\=\s*\{/o);
				$inSections = 1  if  (/\$self\-\>\{\'sections\'\}\s*\=\s*\{/o);
				$inSyntaxes = 1  if  (/\$self\-\>\{\'syntaxes\'\}\s*\=\s*\{/o);
				if ($inSections)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[/o)
					{
						$inSections = $1;
						@{$sectionHash{$inSections}} = ();
					}
					elsif (/\'([^\']+)\'\s*\,/o)
					{
						push (@{$sectionHash{$inSections}}, $1);
					}
					elsif (/\}\;/o)
					{
						$inSections = 0;
					}
				}
				elsif ($inExtensions)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[\'([^\']+)\'/o)
					{
						my $one = '^'.$1.'$';
						my $two = $2;
						$one =~ s/\./\\\./o;
						$one =~ s/\*/\.\*/go;
						$extHash{$one} = "Kate::$two";
					}
					elsif (/\}\;/o)
					{
						$inExtensions = 0;
					}
				}
				elsif ($inSyntaxes)
				{
					if (/\'([^\']+)\'\s*\=\>\s*\[\'([^\']+)\'/o)
					{
						$syntaxHash{$1} = $2;
					}
					elsif (/\}\;/o)
					{
						$inSyntaxes = 0;
						close KATE;
						last;
					}
				}
			}
			close KATE;
			last;
		}
	}
	return (\%sectionHash, \%extHash, \%syntaxHash);
}

sub addKate2ViewMenu    #ADD ALL KATE-LANGUAGES AS OPTIONS TO THE "View" MENU:
{
	my $cw = shift;
	my $sectionHash = shift;

	return undef  if ($cw->cget('-noRulesMenu') || $cw->cget('-noSyntaxMenu'));

	my $ViewSyntaxMenu = $cw->menu->entrycget('View','-menu')->entrycget('Syntax','-menu');
	my $lastMenuIndex = $ViewSyntaxMenu->index('end');

	#WE MUST FETCH THE VARIABLE REFERENCE USED BY THE "View" MENU RADIO-BUTTONS SO 
	#THAT OUR NEW RADIO BUTTONS SHARE SAME VARIABLE (OTHERWISE, WILL HAVE >1 LIT AT
	#SAME TIME!

	my $var;
	my $kateIndx = 'end';
	foreach my $i (0..$lastMenuIndex)
	{
		if ($ViewSyntaxMenu->type($i) =~ /radiobutton/o)
		{
			$var = $ViewSyntaxMenu->entrycget($i, '-variable');
			tie $$var,'Tk::Configure',$cw,'-syntax';
			if ($ViewSyntaxMenu->entrycget($i, '-label') eq 'Kate')
			{
				$ViewSyntaxMenu->delete($i);   #REMOVE THE "Kate" ENTRY, SINCE WE'RE ADDING KATE STUFF SEPARATELY!
#UNCOMMENT TO INSERT KATE MENUS IN ALPHABETICAL ORDER IN VIEW MENU:								$kateIndx = $i;    #SAVE IT'S MENU-LOCATION SO WE CAN INSERT THE KATE MENU TREE THERE.
				last;
			}
		}
	}

	#NOW ADD OUR "KATE" RADIO-BUTTONS!

	my ($nextMenu, $menuTitle);
	foreach my $sect (sort keys %{$sectionHash})
	{
		$nextMenu = $ViewSyntaxMenu->Menu;
		foreach my $lang (@{$sectionHash->{$sect}})
		{
			$menuTitle = "Kate::$lang";
			$nextMenu->radiobutton( -label => $menuTitle,
					-variable => $var,
					-value => $menuTitle,
					-command => sub
			{
				$cw->configure('-rules' => undef);
				$cw->highlightPlug;
			}
			);
		}
		$ViewSyntaxMenu->insert($kateIndx, 'cascade', -label => "Kate: $sect...",
				-menu => $nextMenu);
		++$kateIndx  if ($kateIndx =~ /^\d/o);
	}
}

1;

__END__
