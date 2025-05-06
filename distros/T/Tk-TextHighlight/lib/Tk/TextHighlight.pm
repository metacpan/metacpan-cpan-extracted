package Tk::TextHighlight;

use vars qw($VERSION);
$VERSION = '2.2';
use Tk qw(Ev);
use strict;
use Storable;
use File::Basename;

my $blockHighlight = 0;     #USED TO PREVENT RECURSIVE CALLS TO RE-HIGHLIGHT!
my $nodoEvent = 0;          #USED TO PREVENT REPEATING (RUN-AWAY) SCROLLING!
our ($readonly, $TEXTWIDGET, $haveSuperText);

#NOTE:  TextHighlight SUPPORTS USING EITHER SuperText, OR TextUndo (ROText IF USING ROTextOnly SYMLINK).
#       SuperText USES Text (NOT TextUndo).  THE OPTIONAL ROSuperText SYMLINK (uses ROText)
#		IS *NOT* (AND CAN NOT BE) USED HERE!
BEGIN {
	$haveSuperText = 0;
	$readonly = (__FILE__ =~ /RO/o) ? 1 : 0;
	$TEXTWIDGET = 'Tk::Text::SuperText';  #FIRST TRY SuperText:
	my $evalstr = "use $TEXTWIDGET; \$haveSuperText = 1; 1";
	eval $evalstr;
	unless ($haveSuperText) {  #IF SuperText NOT INSTALLED, THEN TRY TextUndo (or ROText):
		$TEXTWIDGET = $readonly ? 'Tk::ROText' : 'Tk::TextUndo';
		$evalstr = "use $TEXTWIDGET; \$haveSuperText = 1; 1";
		eval $evalstr;
	}
	die "e:TextHighlight could not load required widget ($TEXTWIDGET) ($@)!\n"  if ($@);
	$evalstr = "use base ('Tk::Derived', '$TEXTWIDGET')";
	eval $evalstr;
	die "e:TextHighlight could not load base widget ($TEXTWIDGET) ($@)!\n"  if ($@);
};

Construct Tk::Widget 'TextHighlight';

my %syntaxcomments = (  #ALTERNATE COMMENT CHARACTERS FOR SELECTED LANGUAGES (CAN ADD MORE HERE):
	'Kate::C' => '/*',
	'Kate::C++' => '/*',
	'Kate::CPP' => '/*',
	'HTML' => '<!--',
	'Kate::HTML' => '<!--',
	'Kate::Modula-2' => '(*',
	'Kate::Pascal' => '(*',
	'Kate::XML' => '<!--',
);

sub Populate {
	my ($cw,$args) = @_;
	$args->{'-noPopupMenu'} = 0  unless (defined $args->{'-noPopupMenu'});
	$cw->{'-noPopupMenu'} = $args->{'-noPopupMenu'};
	#REMOVE ARGS THAT SUBWIDGETS CAN'T HANDLE:
	my $superargsOK; #THIS INITIALIZATION REQUIRES 2 LINES (my $superargsOK = $args) IS REFERENCE & WILL OVERWRITE LATTER!:
	%{$superargsOK} = %{$args};
	foreach my $badarg (qw(-autoindent -smartindent -match -matchoptions -indentchar
			-disablemenu -commentchar -colorinf -colored -syntax -rules -updatecall 
			-noRulesMenu -noSyntaxMenu -noRulesEditMenu -noSaveRulesMenu -noPlugInit 
			-noPopupMenu -highlightInBackground -syntaxcomments)) {
		delete ($superargsOK->{$badarg})  if (defined($superargsOK->{$badarg}));
	}
	if ($TEXTWIDGET =~ /SuperText/) {
		#ADD ONE THAT IS DIFFERENT (OVERRIDDEN BY OURS):
		$superargsOK->{'-matchingcouples'} = $args->{'-match'}  if (defined $args->{'-match'});
	} else {
		foreach my $badarg (qw(-matchingcouples -showmatching -ansicolor)) {
			delete ($superargsOK->{$badarg})  if (defined($superargsOK->{$badarg}));
			delete ($args->{$badarg})  if (defined($args->{$badarg}));  #-ansicolor MUST ALSO BE REMOVED HERE - DON'T KNOW WHY?!
		}
	}

	$cw->SUPER::Populate($superargsOK);

	my %configSpecs = (
		-autoindent => [qw/PASSIVE autoindent Autoindent/, 0],
		-smartindent => [qw/PASSIVE undef undef/, 1],
		-match => [qw/PASSIVE match Match/, '[]{}()'],
		-matchoptions	=> [qw/METHOD matchoptions Matchoptions/, 
			[-foreground => 'yellow', -background => 'red']], #SuperText'S IS white ON blue, BUT CLASHES W/TOO MANY RULES.
		-indentchar => [qw/PASSIVE indentchar Indentchar/, "\t"],
		-disablemenu => [qw/PASSIVE disablemenu Disablemenu/, 0],
		-commentchar => [qw/PASSIVE commentchar Commentchar/, "#"],
		-syntaxcomments => [qw/PASSIVE undef undef/, 0],    #JWT: ADDED v2 FEATURE.
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
		-noPopupMenu => [qw/PASSIVE noPopupMenu NoPopupMenu/, 0],  #JWT: ADDED v2 FEATURE.
		-highlightInBackground => [qw/PASSIVE undef undef/, 0],    #JWT: SELF-EXPLANATORY.
		-readonly	=> ['METHOD','readOnly','ReadOnly',$readonly],   #JWT: ADDED v2 FEATURE.
		#DO NOT SPECIFY A DEFAULT BG COLOR HERE, IT MESSES UP RULES / SCREEN-SIZE INITIALIZATION!
		#WE LET background() & highlightPlugInit() METHODS TAKE CARE OF IT AT THE PROPER TIME!:
		-background => ['METHOD','background','Background', undef],
		DEFAULT => [ 'SELF' ],
	);
	if ($TEXTWIDGET =~ /SuperText/) {
		$configSpecs{'-showmatching'} = ['PASSIVE','showMatching','ShowMatching',0]; #WE HANDLE THIS!
		#DON'T LET 'EM DISPLAY MATCHES BY DEFAULT WE DON'T (DISTRACTING, BUT USERS CAN OVERRIDE),
		#AS THEIR DEFAULT INCLUDES MORE NON-MIRRORED CHARS, LIKE QUOTES & GRAVS!:
		$configSpecs{'-matchingcouples'} = ['METHOD','matchingCouples','MatchingCouples',"[]{}()"];
	}
	$cw->ConfigSpecs(%configSpecs);

	$cw->bind('<Configure>', sub { $cw->highlightVisual });
	$cw->bind('<Return>', sub { $cw->doAutoIndent(1) });          #HANDLE THESE WITH OUR FUNCTIONS!:
	$cw->bind('<Shift-Return>', sub { $cw->doAutoIndent(0) });
	$cw->bind('<Control-p>', sub { $cw->jumpToMatchingChar(0) });
	$cw->bind('<Control-P>', sub { $cw->jumpToMatchingChar(1) });
	$cw->markSet('match', '0.0');
	$cw->bind('<ButtonRelease-2>', sub { $cw->pastePrimaryAtMouse() });
	if ($cw->{'-noPopupMenu'}) {
		$cw->bind('<ButtonPress-3>', ['extendSelect']);
	} else {
		$cw->bind('<ButtonPress-3>', ['PostPopupMenu', Ev('X'), Ev('Y')]);
		$cw->bind('<Control-Key-m>', sub { $cw->PostPopupMenu($cw->pointerx, $cw->pointery) });
	}
	$cw->bind('<Shift-ButtonPress-3>', ['extendSelect']);
}

sub readonly
{
	my ($w,$val) = @_;

	#NOTE:  $readonly IS HARD-CODED BASED ON STARTUP MODULE, $w->{READONLY} IS SET
	#HERE FOR THE WIDGET, BUT IS *NOT* ALWAYS SET INITIALLY:

	$w->{READONLY} = $readonly  unless (defined $w->{READONLY});
	if ($readonly) {
		return $readonly  unless (defined $val);
		$w->{READONLY} = $readonly;
		$w->adjustMenuState();
		return;
	}
	return $w->{READONLY}  unless (defined $val);

	my $prevval = $w->{READONLY};
	$w->{READONLY} = $val;
	$w->adjustMenuState()  if ($val != $prevval);
}

sub background {
	my ($w,$val) = @_;

	return $w->{'background'}  unless (defined $val);

	#IF CHANGING BACKGROUND, MUST RESET RULE COLORS TO FIX/PREVENT COLOR
	#CONTRAST ILLEGABILITIES (RULES W/FG COLOR SAME AS WINDOW BACKGROUND)
	# **EXCEPT** WHEN BACKGROUND IS INITIALLY SET (BEFORE RULES ARE INITIALIZED)!!!:
	Tk::configure($w, "-background", $val);
	if (defined $w->{'background'}) {  #AVOID RESETTING RULES ON INITIAL STARTUP (WINDOW IGNORES WIDTH/HEIGHT SETTINGS)!
		$w->configure('-rules' => undef);
		$w->highlightPlug;
	}
	$w->{'background'} = $val;
}

sub jumpToMatchingChar  #ADDED 20060630 JWT TO CAUSE ^p TO WORK LIKE VI & SUPERTEXT - JUMP TO MATCHING CHARACTER!
{
	my $cw = shift;
	my $selectbetween = shift || 0;

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
		if ($selectbetween) {
			my @ranges = $cw->tagRanges('sel');
			my $idx = $cw->index('insert');
			if (@ranges && ($cw->compare($idx,'==',$cw->index('sel.first'))
						|| $cw->compare($idx,'==',$cw->index('sel.last - 1c')))) {
				#SELECT EXCLUDING BRACES (WAS ALREADY SELECTED & INCLUDING BRACES):
				$cw->tagRemove('sel','1.0','end');
				$cw->compare($prevMatch,'<',$cw->index('insert'))
						? $cw->tagAdd('sel','MyMatch + 1c','insert')
						: $cw->tagAdd('sel','insert + 1c','MyMatch');
			} else {
				#SELECT INCLUDING BRACES:
				$cw->tagRemove('sel','1.0','end');
				$cw->compare($prevMatch,'<',$cw->index('insert'))
						? $cw->tagAdd('sel','MyMatch','insert + 1c')
						: $cw->tagAdd('sel','insert','MyMatch + 1c');
			}
		}
	}
}

sub ClassInit
{
	my ($class,$w) = @_;
	
	$class->SUPER::ClassInit($w);

	# reset default Tk::Text binds:
	$w->bind($class,	'<Control-p>', sub {} );  #OVERRIDE BINDINGS WE HANDLE EXCLUSIVELY!:
	$w->bind($class,	'<Control-P>', sub {} );          #ADDED SELECT BETWEEN BRACES (INCLUSIVE).
	$w->bind($class,	'<Key-Return>', sub {} )  unless ($TEXTWIDGET =~ /SuperText/);
	$w->bind($class,	'<Key-BackSpace>', 'Backspace' ); #MAKE CONSISTANT BETWEEN ALL SUPPORTED TEXT WIDGETS.
	$w->bind($class,	'<Key-space>', 'Space' );         #MAKE CONSISTANT BETWEEN ALL SUPPORTED TEXT WIDGETS.
	$w->bind($class,	'<Alt-Tab>', 'insertTabChar' );   #ADDED TO ALLOW INSERTION OF TABS!
	$w->bind($class,	'<Tab>', 'insertTab' );           #ADDED TO ALLOW INSERTION OF TABS OR SPACES!
	$w->bind($class,	'<ButtonRelease-2>', '');         #CHECK READONLY STATUS BEFORE PASTING SELECTION!
	return $class;
}

sub clipboardCopy {
	my $cw = shift;
	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->SUPER::clipboardCopy(@_);
	}
}

sub beginUndoBlock
{
	my $cw = shift;

	if ($TEXTWIDGET =~ /SuperText/)   #GROUP CHANGES FOR UNDO (DIFFERENT FN NAMES USED).
	{
		$cw->_BeginUndoBlock;
	}
	elsif ($TEXTWIDGET =~ /TextUndo/)
	{
		$cw->addGlobStart;
	}
	#OTHERWISE NO-OP (UNDO/REDO NOT SUPPORTED).
}

sub endUndoBlock
{
	my $cw = shift;

	if ($TEXTWIDGET =~ /SuperText/)   #ADDED 20080411 TO GROUP CHANGES FOR UNDO.
	{
		$cw->_EndUndoBlock;
	}
	elsif ($TEXTWIDGET =~ /TextUndo/)
	{
		eval $cw->addGlobEnd;
	}
}
sub doAutoIndent {  #WE HANDLE AUTOINDENT NOW FOR EVERYONE!:
	my $cw = shift;

	my $doAutoIndent = $cw->cget('-autoindent') ? shift : 0;
	if ($cw->{READONLY}) {  #JUST POSITION CURSOR ON NEXT LINE (INDENTED IF NEEDED):
		my $marginlen = 1;
		if ($doAutoIndent) {
			my $margin = $cw->get('insert lineend + 1 char', 'insert lineend + 1 char lineend');
			$marginlen = length($1) + 1  if ($margin =~ /^(\s+)/o);
		}
		$cw->SetCursor($cw->index("insert lineend + $marginlen char"));
		$cw->see('insert linestart');
		Tk->break;
		return;
	}

	my $i = $cw->index('insert linestart');
	my $begin = $cw->linenumber($i);
	my $insertStuff = "\n";
	my $s = $cw->get("$i", "$i lineend");
	$cw->beginUndoBlock;
	#if ($s =~ /\S/o)  #JWT: UNCOMMENT TO CAUSE SUBSEQUENT BLANK LINES TO NOT BE AUTOINDENTED.
	#{
		#$s =~ /^(\s+)/;  #JWT:CHGD. TO NEXT 20060701 TO FIX "e" BEING INSERTED INTO LINE WHEN AUTOINDENT ON?!
		$s =~ /^(\s*)/o;
		if ($doAutoIndent) {
			my $thisindent = defined($1) ? $1 : '';
			if ($cw->cget('-smartindent')) {  #TRY TO DO INTELLIGENT (CODE-FRIENDLY) INDENTING BASE ON CURRENT & NEXT LINE:
				my $s2 = '';
				my $thisindlen = length($thisindent);
				my $cc = $cw->cget('-commentchar') || "\x02";  #MUST BE A NON-EMPTY STRING IN NEXT REGEX!:
				eval "\$s2 = \$cw->get('insert + 1 line linestart', 'insert + 1 line lineend')";
				$s2 =~ /^(\s*)/o;
				my $nextindent = defined($1) ? $1 : '';
				my $nextindlen = length($nextindent);
				my $indentchar = $cw->cget('-indentchar');  #NORMALLY A TAB OR MULTIPLE SPACES (== 1 INDENTATION).
				if ($s =~ /[\{\[\(]\s*(?:\Q$cc\E.*)?$/o) {  #CURRENT LINE ENDS IN AN OPENING BRACE (INDENT AT LEAST 1 INDENTATION):
					$insertStuff .= ($nextindlen > $thisindlen) ? $nextindent : "$thisindent$indentchar";
				} else {  #NORMAL LINE (KEEP SAME INDENT UNLESS NEXT LINE FURTHER INDENTED):
					my $afterStuff = $cw->get('insert', "$i lineend");
					$insertStuff .= ($nextindlen < $thisindlen || $s2 =~ /^\s*[\}\]\)]/o) ? $thisindent : $nextindent;
					if (length $afterStuff) {  #WE HIT <Enter> IN MIDDLE OF A LINE:
						if ($afterStuff =~ /^\s*[\}\]\)]/o) {  #WE HIT <Enter> ON A CLOSING BRACE:
							$insertStuff =~ s/$indentchar//;
						} elsif ($cw->get('insert - 1c') =~ /[\{\[\(]/o) {
							$insertStuff .= $indentchar;
						}
					}
				}
			} else {  #JUST DO IT LIKE SuperText:
				$insertStuff .= $thisindent;
			}
		}
	#}  #JWT: UNCOMMENT TO CAUSE SUBSEQUENT BLANK LINES TO NOT BE AUTOINDENTED.
	$cw->insert('insert', $insertStuff);
	$cw->endUndoBlock;
	$cw->see('insert linestart');
	$cw->highlightCheck($begin, $cw->linenumber('end'));
}

sub highlight {
	my ($cw, $begin, $end) = @_;
#	return $begin  if ($blockHighlight);   #PREVENT RECURSIVE CALLING WHILST ALREADY REHIGHLIGHTING!
	$blockHighlight = 1;
	$end = $begin + 1  unless (defined $end);
	#save selection and cursor position
#1	my @sel = $cw->tagRanges('sel');
#1	my $cursor = $cw->index('insert'); 
	#go over the source code line by line.
	while ($begin < $end) {
		$cw->highlightLine($begin);
		$begin++; #move on to next line.
	};
	#restore original cursor and selection
#1	$cw->markSet('insert', $cursor);
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
			#the proces ended inside a multiline token. try to fix it.
			$cw->highlightPurge($begin)
					if (($col < $cw->linenumber('end')) and (not $hlt->stateCompare($i)));
		}
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
#print "--HL:stateSet(".join('|',@$k).") line=$txt=\n";
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
		$plug = $cw->highlightPlugInit  if ($syntax ne $plug);
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
		$cw->{'SYNTAX'} = $syntax;
		if ($cw->cget('-syntaxcomments')) {
			$cw->configure('-commentchar' => (defined $syntaxcomments{$syntax})
					? $syntaxcomments{$syntax} : '#')
		}
		$lang = $1  if ($syntax =~ s/\:\:(.*)$//o);
		my @opt = ();
		if (my $rules = $cw->cget('-rules')) {
			push(@opt, $rules);
		}
		my $evalStr = "require Tk::TextHighlight::$syntax; \$plug = new Tk::TextHighlight::$syntax("
				. ($lang ? "'$lang', " : '') . "\@opt);";
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
#DOESN'T WORK!:	my $bg = $cw->cget('-background');
	my $bg;
	#WARNING:  WE *MUST* HAVE A BACKGROUND HERE, ELSE RULES GO ALL WANKEY!:
	if ($cw->{Configure}{'-background'}) {
		$bg = $cw->{Configure}{'-background'};
	} else {
		my $Palette = $cw->Palette;  #THE PALETTE MAY'VE ALREADY BEEN SET W/O CALLING CONFIGURE TO SET THE BACKGROUND!
		$bg = (defined $Palette->{'background'}) ? $Palette->{'background'} : '#d9d9d9';
	}

	my ($red, $green, $blue) = $cw->rgb($bg);   #JWT: NEXT 11 ADDED 20070802 TO PREVENT INVISIBLE TEXT!
	my @rgb = sort {$b <=> $a} ($red, $green, $blue);
	my $max = $red + 1.5*$green + 0.5*$blue;  #USE SAME RULE AS Tk::setPalette.
	my $daytime = 1;
	my $currentrules = $plug->rules;
	my $TwilightThreshold = defined($Tk::Widget::TwilightThreshold)
			? $Tk::Widget::TwilightThreshold : 100000;

	if ($max <= $TwilightThreshold) {  #IF BG COLOR IS DARK ENOUGH, FORCE RULES WITH NORMAL BLACK-
		$daytime = 0;     #FOREGROUND TO WHITE TO AVOID COLOR CONTRAST ILLEGABILITIES.
		#print "-NIGHT 65!\n";
		for (my $k=0;$k<=$#{$currentrules};$k++)
		{
			$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],'white')
					if ($currentrules->[$k]->[2] eq 'black');
		}
	}
	for (my $k=0;$k<=$#{$currentrules};$k++)
	{
		#RULE FOREGROUND COLOR == BACKGROUND, CHANGE TO BLACK OR WHITE TO KEEP READABLE!
		$cw->setRule($currentrules->[$k]->[0],$currentrules->[$k]->[1],($daytime ? 'black' : 'white'))
				if (defined($currentrules->[$k]->[2]) and $currentrules->[$k]->[2] eq $bg);
	}
	$cw->update;
	unless ($cw->cget('-noSyntaxMenu') || $cw->cget('-noRulesMenu'))  #JWT:  ADDED TO ENSURE VIEW RADIO-BUTTON PROPERLY INITIALIZED/SET.
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
				$$var = $lang ? ($syntax.'::'.$lang) : $syntax  unless (ref $syntax);
				last;
			}
		}
	}
	#IF NO BACKGROUND HAS BEEN SET, USE THE ONE WE SET ABOVE FOR THE RULES & SET IT NOW!:
	$cw->configure('-background' => $bg)  unless ($cw->{Configure}{'-background'});
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
#CHGD. TO NEXT 20160119:			} elsif (($name ne 'None') and ($name ne 'Template')) {
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
	splice(@$cli, $line)  if (@$cli);
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
	}
	$cw->matchCheck;
}

sub linenumber {
	my ($cw, $index) = @_;
	if (not defined($index)) { $index = 'insert'; }
	my $id = $cw->index($index);
	my ($line, $pos ) = split(/\./o, $id);
	return $line;
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
	if ($c && $c =~ /\S/o) {  #DON'T BOTHER IF CHAR IS EMPTY OR WHITESPACE.
		my $v = $cw->cget('-match');
		my $p = index($v, $c);
		if ($p ne -1) { #a character in '-match' has been detected.
			#JWT:ADDED NEXT 2 (INCL CONDITION) 20240729:
			my $cprev = $cw->get('insert - 1 chars', 'insert');
			unless ($cprev =~ /\\/o) {  #AVOID MATCHING ESCAPED BRACES, IE. IN REGICES:
				my $count = 0;
				my $found = 0;
				#ADDED NEXT 2 20240701 TO AVOID MATCHING BRACES IN COMMENTS:
				my $inTags = join('|', $cw->tagNames('insert'));
				unless ($inTags =~ /(?:Comment|String)/o) {
					if ($p % 2) {
						my $m = substr($v, $p - 1, 1);
						$cw->matchFind('-backwards', $c, $m, 
							$cw->index('insert'),
#							$cw->index('@0,0'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
							$cw->index('0.0'),
						);
					} else {
						my $m = substr($v, $p + 1, 1);
						$cw->matchFind('-forwards', $c, $m,
							$cw->index('insert + 1 chars'),
#							$cw->index($cw->visualend . '.0 lineend'),   #CHGD. TO NEXT 20060630 TO PERMIT ^p JUMPING TO MATCHING CHAR OUTSIDE VISIBLE AREA.
							$cw->index('end'),
						);
					}
				}
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
			#JWT:ADDED ALL "inTags" LINES BELOW 20240701 TO AVOID MATCHING BRACES IN COMMENTS:
			my $inTags = join('|', $cw->tagNames($i));
			if ($count > 0) {
				#JWT:ADDED NEXT AND ALTERED NEXT TEST: 20240729 TO AVOID MATCHING ESCAPED BRACES:
				my $kprev = $cw->get("$i - 1 chars", "$i");
				$count--  unless ($inTags =~ /(?:Comment|String)/o || $kprev =~ /\\/o);
				$start = ($dir eq '-forwards') ? $cw->index("$i + 1 chars") : $i;
			} else {
				#JWT:ADDED NEXT AND ALTERED NEXT TEST: 20240729 TO AVOID MATCHING ESCAPED BRACES:
				my $kprev = $cw->get("$i - 1 chars", "$i");
				if ($inTags =~ /(?:Comment|String)/o || $kprev =~ /\\/o) {
					$start = ($dir eq '-forwards') ? $cw->index("$i + 1 chars") : $i;
				} else {
#					print "Found !!!\n";
					$cw->markSet('match', $i);
					$cw->tagAdd('Match', $i, "$i + 1 chars");
					$cw->markSet('MyMatch', $i);
					$cw->tagRaise('Match');
					$found = 1;
				}
			}
		} elsif ($k eq $char) {
			my $inTags = join('|', $cw->tagNames($i));
			#JWT:ADDED NEXT AND ALTERED NEXT TEST: 20240729 TO AVOID MATCHING ESCAPED BRACES:
			my $kprev = $cw->get("$i - 1 chars", "$i");
			$count++  unless ($inTags =~ /(?:Comment|String)/o || $kprev =~ /\\/o);
			$start = ($dir eq '-forwards') ? $cw->index("$i + 1 chars") : $i;
		} elsif ($i eq $start) {  #JWT:THIS *SEEMS* TO NEVER HAPPEN, BUT PREVENTS POTENTIAL INFINITE LOOP, PERHAPS?
			$found = 1;
		}
	}
}

sub matchoptions {
	my $cw = shift;
	if (my $o = shift) {
		my @op = ();
		@op = (ref $o) ? @$o : split(/\s+/o, $o);
		$cw->tagConfigure('Match', @op);
	}
}

sub PostPopupMenu {
	my $cw = shift;
	my @r = $cw->SUPER::PostPopupMenu(@_)
			unless ($cw->cget('-disablemenu') || $cw->cget('-noPopupMenu'));
}

sub rulesConfigure {
	my $cw = shift;
	if (my $plug = $cw->Subwidget('formatter')) {
		my $rules = $plug->rules;
		foreach my $k (@$rules) {
			$cw->tagConfigure(@$k);
		}
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
			@{$r[$k]} = @rule  if ($rule[0] eq $r[$k]->[0]);
		}
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
	if (defined($dir) && $dir) {
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
	#mode==1 means UN(comment|indent).
	my @ranges = $cw->tagRanges('sel');
	if (@ranges eq 2) {
		$cw->beginUndoBlock;
		if ($cw->compare($ranges[0],'>',$ranges[1])) {
			my $x = $ranges[1];
			$ranges[1] = $ranges[0];
			$ranges[0] = $x;
		}
		my $start = $cw->index($ranges[0]);
		my $end = $cw->index($ranges[1]);
		eval  #MAKE SURE WE PUT MARKS AROUND WHAT WILL BE DELETED AND REPLACED:
		{
			$cw->markSet('selstartmk',"$start");
			$cw->markGravity('selstartmk','left');
			$cw->markSet('selendmk',"$end");
			$cw->markGravity('selendmk','right');
		};
		my $endchar = '';  #SET FOR COMMENTS HAVING A STARTING AND ENDING PAIR, IE. /* & */:
		if ($char =~ m#^[\/\(]\*$#o) {  #C, C++, CSS, PASCAL & MODULA-II:
			($endchar = $char) =~ s#(.)(.)#$2$1#;
			$endchar =~ s/\(/\)/o;
		} elsif ($char =~ m#\<\!\-\-#o) {  #HTML, XML:
			$endchar = '-->';
		}
		$cw->tagDelete('sel');
		my $partialLine = ($cw->linenumber($start) == $cw->linenumber($end)) ? 1 : 0;
		if ($partialLine) {  #LESS THAN AN ENTIRE SINGLE LINE IS SELECTED:
			my $commentstring = $cw->get($start, $end);
			$cw->delete("$start", "$end");
			if ($mode && $char eq $cw->cget('-commentchar')) {
				$commentstring =~ s/\Q$char\E ?//;
				$commentstring =~ s/ ?\Q$endchar\E ?//  if ($endchar);
			} else {
				my $pad = ($endchar ? ' ' : '');
				$commentstring = "$char$pad$commentstring$pad$endchar";
			}
			$cw->insert("$start", $commentstring);
		} elsif ($endchar) {  #ENCLOSE SELECTION IN COMMENT BRACKETS (IE. /* <SELECTION> */):
			my $commentstring = $cw->get($start, $end);
			$cw->delete("$start", "$end");
			if ($mode) {
				if ($commentstring =~ /\Q$char\E.+\Q$endchar\E/s) {
					$commentstring =~ s/\Q$char\E\n?//s;
					$commentstring =~ s/\Q$endchar\E\n?/$1/s;
				}
				$cw->insert("$start", $commentstring);
			} else {
				$cw->insert("$start linestart", "$char\n$commentstring$endchar\n");
			}
		} else {  #PREPEND COMMENT (OR INDENT) STRING TO EACH LINE SELECTED:
			while ($cw->compare($start, "<", $end)) {
				if ($mode) {
					$cw->delete("$start linestart", "$start linestart + 1 chars")
							if ($cw->get("$start linestart", "$start linestart + 1 chars") eq $char);
				} else {
					$cw->insert("$start linestart", $char);
				}
				$start = $cw->index("$start + 1 lines");
			}
		}
		$cw->tagAdd('sel', 'selstartmk', 'selendmk');  #RESTORE SELECTION TO THE STUFF UPDATED.
		$cw->endUndoBlock;
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
sub SelectToMouse  #INTERNAL METHOD:
{
	my ($w, $index, $mode)= @_;
	$Tk::selectMode = $mode if defined ($mode);
	my $cur = $w->index($index);
	my $anchor = $w->index('insert');
	eval "my \$a = \$w->index('anchor')";
	return  if ($@);

	$Tk::mouseMoved = ($w->compare($cur,'!=',$anchor)) ? 1 : 0;
	$Tk::selectMode = 'char' unless (defined $Tk::selectMode);
	$mode = $Tk::selectMode;
	my ($first,$last);
	if ($mode eq 'char') {
		if ($w->compare($cur,'<','anchor')) {
			$first = $cur;
			$last = 'anchor';
		} elsif ($w->compare($cur,'==','anchor')) {
			return;
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
	} elsif ($mode eq 'line') {
		if ($w->compare($cur,'<','anchor')) {
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

sub extendSelect {
	my ($w) = @_;
	my $Ev = $w->XEvent;
	$w->SelectToMouse($Ev->xy,'char');
}

sub syntax {
	my $cw = shift;
	if (@_) {
		my $name = shift;
		my $fm;
		eval ("require Tk::TextHighlight::$name;	\$fm = new Tk::TextHighlight::$name(\$cw);");
		$cw->Advertise('formatter', $fm);
		$cw->{'SYNTAX'} = $name;
		if ($cw->cget('-syntaxcomments')) {
			$cw->configure('-commentchar' => (defined $syntaxcomments{$name})
					? $syntaxcomments{$name} : '#')
		}
	}
	return $cw->{'SYNTAX'};
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

sub EditMenuItems {  #INTERNAL METHOD:
	my $cw = shift;
	if ($TEXTWIDGET =~ /SuperText/) {  #SUPERTEXT SUPPORTS UNDO/REDO, BUT DOESN'T DO MENUS:
		return [
			["command"=>'Undo', -command => [$cw => 'undo']],
			["command"=>'Redo', -command => [$cw => 'redo']],
			"-",@{$cw->SUPER::EditMenuItems},
			["command"=>'Select', -command => [$cw => 'extendSelect']],
			"-",
			["command"=>'Comment', -command => [$cw => 'selectionComment']],
			["command"=>'Uncomment', -command => [$cw => 'selectionUnComment']],
			"-",
			["command"=>'Indent', -command => [$cw => 'selectionIndent']],
			["command"=>'Unindent', -command => [$cw => 'selectionUnIndent']],
		];
	} else {
		return [
			@{$cw->SUPER::EditMenuItems},
			["command"=>'Select', -command => [$cw => 'extendSelect']],
			"-",
			["command"=>'Comment', -command => [$cw => 'selectionComment']],
			["command"=>'Uncomment', -command => [$cw => 'selectionUnComment']],
			"-",
			["command"=>'Indent', -command => [$cw => 'selectionIndent']],
			["command"=>'Unindent', -command => [$cw => 'selectionUnIndent']],
		];
	}
}

sub ViewMenuItems {  #INTERNAL METHOD:
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
				['command'=>'ReHighlight',
					-command => sub { $cw->highlightPlugInit },
				]);
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

sub adjustMenuState  #INTERNAL METHOD:
{
	my $w = shift;

	my $state = $w->{READONLY} ? 'disabled' : 'normal';
	my $EditSyntaxMenu = $w->menu->entrycget('Edit','-menu');
	eval "\$EditSyntaxMenu->entryconfigure('Cut', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Paste', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Undo', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Redo', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Comment', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Uncomment', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Indent', -state => \$state)";
	eval "\$EditSyntaxMenu->entryconfigure('Unindent', -state => \$state)";
	my $SearchSyntaxMenu = $w->menu->entrycget('Search','-menu');
	eval "\$SearchSyntaxMenu->entryconfigure('Replace', -state => \$state)";
}

sub visualend {
	my $cw = shift;
	my $end = $cw->linenumber('end - 1 chars');
	my ($first, $last) = $cw->Tk::Text::yview;
	my $vend = int($last * $end) + 2;
	$vend = $end  if ($vend > $end);
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

sub addKate2ViewMenu  #ADD ALL KATE-LANGUAGES AS OPTIONS TO THE "View" MENU:
{
	my $cw = shift;
	my $sectionHash = shift;

	return  if ($cw->cget('-noRulesMenu') || $cw->cget('-noSyntaxMenu'));

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
#UNCOMMENT TO INSERT KATE MENUS IN ALPHABETICAL ORDER IN VIEW MENU:				$kateIndx = $i;    #SAVE IT'S MENU-LOCATION SO WE CAN INSERT THE KATE MENU TREE THERE.
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
		$ViewSyntaxMenu->insert($kateIndx, 'cascade',
				-label => "Kate: $sect...",
				-menu => $nextMenu);
		++$kateIndx  if ($kateIndx =~ /^\d/o);
	}
}

sub getViewMenu  #ADDED 2024624 TO ALLOW CALLING PROGRAM TO INCLUDE IN THEIR OWN CUSTOM MENUS:
{
	my $cw = shift;

	return $cw->menu->entrycget('View','-menu');
}

sub Load {
	my ($cw,$filename) = @_;
	return 0  unless (defined($filename) && -r $filename);
	if (open(my $fid,"<$filename")) {
		$cw->MainWindow->Busy;
		$cw->EmptyDocument;
		$cw->insert('end',$_)  while (<$fid>);
		close($fid);

		$cw->markSet('insert' => '1.0');
		$cw->MainWindow->Unbusy;
		return 1;
	}
	return 0;
}

#NEEDED FOR CLEARING ENTIRE DOCUMENTS PROGRAMATICALLY IN READ-ONLY VIEWERS (ROText IS OK WITH THIS!):
sub EmptyDocument {
	my $cw = shift;

	my $rostatus = $cw->{READONLY};
	$cw->{READONLY} = 0;
	$cw->delete('0.0','end');
	$cw->{READONLY} = $rostatus;
	$cw->ResetUndo;
	#WARNING, DOESN'T SEEM TO EXECUTE ANYTHING AFTER THE ResetUndo?!:
}

#FUNCTIONS NOT USED IN THE READ-ONLY VERSION:

sub clipboardCut {
	my $cw = shift;
	return  if ($cw->{READONLY});

	my @ranges = $cw->tagRanges('sel');
	$cw->SUPER::clipboardCut(@_)  if (@ranges);
}

sub clipboardPaste {
	my $cw = shift;
	return  if ($cw->{READONLY});

	my @ranges = $cw->tagRanges('sel');
	if (@ranges) {
		$cw->tagRemove('sel', '1.0', 'end');
		return;
	}
	$cw->SUPER::clipboardPaste(@_);
}

sub delete {
	my $cw = shift;
	return  if ($cw->{READONLY});

	my $begin = $_[0];
	$begin = (defined $begin) ? $cw->linenumber($begin)
			: $cw->linenumber('insert');
	my $end = $_[1];
	$end = (defined $end) ? $cw->linenumber($end) : $begin;
	$cw->SUPER::delete(@_);
	$cw->highlightCheck($begin, $end);
}

sub insert {
	my $cw = shift;
	my $pos = shift;
	##NOTE:  CAN'T CHECK FOR READONLY HERE B/C FILES ARE INITIALLY LOADED USING THIS.
	#        AND $cw->{READONLY} IS *NOT* ALWAYS INITIATED YET IF USING RO*text.pl MODULES!:

	$pos = $cw->index($pos);
	my $begin = $cw->linenumber("$pos - 1 chars");
	$cw->SUPER::insert($pos, @_);
	$cw->highlightCheck($begin, $cw->linenumber('insert lineend'));
	#WE'LL GO AHEAD AND INITIALIZE IT HERE IF NOT ALREADY (WILL ALREADY BE IF CALLED FROM $cw->Load())!
	$cw->{READONLY} = $readonly  unless (defined $cw->{READONLY});
}

sub Insert {
	my $cw = shift;
	return  if ($cw->{READONLY});

	$cw->beginUndoBlock;
	$cw->SUPER::Insert(@_);
	$cw->endUndoBlock;
	$cw->see('insert');
}

sub InsertKeypress {
	my ($cw,$char) = @_;
	return  if ($cw->{READONLY});

	if ($char ne '') {
		my $index = $cw->index('insert');
		my $line = $cw->linenumber($index);
		if ($char =~ /^\S$/o and !$cw->OverstrikeMode and !$cw->tagRanges('sel')) {
			my $undo_item = $cw->getUndoAtIndex(-1);
			if (defined($undo_item) &&
					($undo_item->[0] eq 'delete') &&
					($undo_item->[2] == $index))
			{
				$cw->Tk::Text::insert($index,$char);
				$undo_item->[2] = $cw->index('insert');
				$cw->highlightCheck($line, $line);
				$cw->see('insert');  #ADDED 20060703 TO ALLOW USER TO SEE WHAT HE'S TYPING PAST END OF LINE (THIS IS BROKEN IN TEXTUNDO TOO).
				return;
			}
		}
		$cw->addGlobStart;
		$cw->Tk::Text::InsertKeypress($char);
		$cw->addGlobEnd;
	}
}

sub selectionComment {
	my $cw = shift;
	return  if ($cw->{READONLY});

	$cw->selectionModify($cw->cget('-commentchar'), 0);
}

sub selectionIndent {
	my $cw = shift;
	return  if ($cw->{READONLY});

	$cw->selectionModify($cw->cget('-indentchar'), 0);
}

sub selectionUnComment {
	my $cw = shift;
	return  if ($cw->{READONLY});

	$cw->selectionModify($cw->cget('-commentchar'), 1);
}

sub selectionUnIndent {
	my $cw = shift;
	return  if ($cw->{READONLY});

	$cw->selectionModify($cw->cget('-indentchar'), 1);
}

sub insertTab
{
	my ($w) = @_;
	return  if ($w->{READONLY});

	$w->Insert($w->cget('-indentchar'));
	$w->focus;
	$w->break;
}

sub insertTabChar
{
	my ($w) = @_;
	return  if ($w->{READONLY});

	$w->Insert("\t");
	$w->focus;
	$w->break;
}

sub Backspace {   #HANDLE THIS OURSELVES FOR CONSISTANCY AMONG TEXT-WIDGETS:
	my $w = shift;

	my $selected = '';
	eval { $selected = $w->get('sel.first', 'sel.last') };
	if ($w->{READONLY}) {
		if (length($selected) > 0) {
			$w->tagRemove('sel','0.0','end');
		} else {  #ONLY BACK UP A CHARACTER IF NO SELECTION CLEARED:
			$w->SetCursor('insert - 1c');
			$w->see('insert');
		}
 	} else {
		if (length($selected) > 0) {
			my $prev_insert = $w->index('insert');
			#DELETE SELECTION ONLY IF CURSOR IS WITHIN OR ABUTS IT, OTHERWISE CLEAR IT:
			if ($w->compare($prev_insert,'>=',$w->index('sel.first'))
					&& $w->compare($prev_insert,'<=',$w->index('sel.last'))) {
				$w->deleteSelected;
			} else {
				$w->tagRemove('sel','0.0','end');
			}
		} else {  #ONLY DELETE PREV. CHARACTER IF NO SELECTION CLEARED:
			$w->delete('insert - 1c')  if ($w->compare('insert','!=','1.0'));
			$w->see('insert');
		}
	}
	$w->break;
}

sub Space {   #HANDLE THIS OURSELVES  FOR CONSISTANCY  AMONG TEXT-WIDGETS:
	my $w = shift;

	if ($w->{READONLY}) {
		my $selected = '';
		eval { $selected = $w->get('sel.first', 'sel.last') };
		if (length($selected) > 0) {
			$w->tagRemove('sel','0.0','end');
		} else {  #ONLY ADVANCE A CHARACTER IF NO SELECTION CLEARED:
			$w->SetCursor('insert + 1c');
			$w->see('insert');
		}
	} else {
		$w->Insert(' ');
		$w->see('insert');
	}
	$w->break;
}

sub pastePrimaryAtMouse {
	my $w = shift;
	return  if ($w->{READONLY});

	my $ev = $w->XEvent;

	Tk::catch { $w->insert($ev->xy,$w->SelectionGet);}  unless ($Tk::mouseMoved);
}

sub ResetUndo
{
	shift->SUPER::resetUndo;
}

1

__END__

=pod

=head1 NAME

Tk::TextHighlight - a Tk::TextUndo/Tk::Text::SuperText widget with syntax 
highlighting capabilities, can also use Kate languages.

=head1 SYNOPSIS

=over 4

 use Tk;
 my $haveKateInstalled = 0;
 eval "use Syntax::Highlight::Engine::Kate; \$haveKateInstalled = 1; 1";

 use Tk::TextHighlight;  #-OR- use Tk::ROTextHighlight;

 my $m = new MainWindow;

 my $e = $m->Scrolled('TextHighlight', #NOTE: always "TextHighlight"!
    -syntax => 'Perl',
    -commentchar => '#',
    -scrollbars => 'se',
 )->pack(-expand => 1, -fill => 'both');

 if ($haveKateInstalled) {
    my ($sections, $kateExtensions) = $e->fetchKateInfo;
    $e->addKate2ViewMenu($sections);
 }

 $m->configure(-menu => $e->menu);
 $m->MainLoop;

=back

=head1 DESCRIPTION

Tk::TextHighlight inherits Tk::Text::SuperText, if available, or Tk::TextUndo 
and all its options and methods.  It provides an enhanced Tk Text widget that 
specializes in code-editing by additionally providing smart brace-matching / 
jumping between braces (but skipping ones in comments), language-specific text 
color-highlighting, and a "readonly" option for simply viewing text one 
doesn't want changed.  Besides syntax highlighting, methods and bindings are 
provided for commenting and uncommenting as well as reindenting and unindenting 
a selected area, and automatic intelligent indenting of new lines.  

Setting the I<-readonly> flag or creating a symlink to the TextHighlight.pm 
source file and naming it ROTextHighlight.pm, then "using" it 
("use Tk::ROTextHighlight") in the program provides all the same functionality 
in a "readonly" widget for text viewers, etc.  B<Tk::TextHighlight> also 
supports highlighting of all the many lauguages and file formats supported by  
L<Syntax::Highlight::Engine::Kate>, if that optional module is installed.  For 
Perl programmers in particular, TextHighlight can use either the module 
Syntax::Highlight::Perl, or the optional and better one:  
Syntax::Highlight::Perl::Improved.  There is also a "PerlCool" version that 
leans toward "cooler" colors (greens, blues, violets), preferred by 
the author.  One can also choose Kate's Perl highlighter:  
Syntax::Highlight::Engine::Kate::Perl, if the Kate modules are installed.

Syntax highlighting is done through a plugin approach. Adding languages 
is a matter of writing plugin modules. Theoretically this is not limited to 
programming languages.  The plugin approach could also provide the possibility 
for grammar or spell checking in spoken languages.

Currently there is built-in support for B<Bash>, B<HTML>, B<Perl>, B<Pod>, 
and B<Xresources>.  Optionally many others if 
I<Syntax::Highlight::Engine::Kate> is installed.

=head1 STANDARD OPTIONS

B<-background -borderwidth -cursor -exportselection -font -foreground 
-highlightbackground -highlightcolor -highlightthickness -insertbackground 
-insertborderwidth -insertofftime -insertontime -insertwidth -padx -pady 
-relief -selectbackground -selectborderwidth -selectforeground -setgrid 
-spacing1 -spacing2 -spacing3 -state -tabs -takefocus -xscrollcommand 
-yscrollcommand>

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<autoindent>

=item Class: B<Autoindent>

=item Switch: B<-autoindent>

Boolean, when you press the enter button, should the next line begin at the 
same position as the current line or not.  This indentation works with either 
spaces or tabs are used (See also:  I<-indentchar>).

Default:  B<false> (start each new line at column 0).

=item Name: B<commentchar>

=item Class: B<Commentchar>

=item Switch: B<-commentchar>

This is slightly misleading - it represents a string of one or more 
characters.  Normally when using the I<selectionComment()> method, 
each selected line is prepended with the commentchar string.  A Special 
exception is made if the string is "/*", "(*", or "<!--", as these normally 
represent comment braces, which must have a beginning and ending string, and 
the selectionComment() method automatically recognizes these special cases 
and instead automatically wraps the entire block of selected text with the 
specified commentchar string and it's proper terminating string.  When 
specifying the I<-syntax> parameter when creating the TextHighlight widget, 
and editing files containing C code, HTML, Pascal, etc. they should consider 
also specifying the corresponding I<-commentchar> string appropriate for 
files containing that language.  See also I<-syntaxcomments>

Default:  B<"#".>

=item Name: B<disablemenu> 

=item Class: B<Disablemenu>

=item Switch: B<-disablemenu>

Boolean, if I<true>, disables the popup menu under the right mouse button 
(ButtonPress-3).  Unlike B<-noPopupMenu> This can be configured 
programatically at run-time.  See also B<-noPopupMenu>.

Default:  B<false> (Menu will popup when right mouse button is pressed over 
the widget).

=item Name: B<highlightInBackground>

=item Class: B<HighlightInBackground>

=item Switch: B<-highlightInBackground>

Perform rehighlighting (after text changes) in a background thread (if true), 
which, in most cases this should be desirable.
	
Default:  B<false>  I<Recommended value now:  true> (modern multi-threaded 
computer processors should handle this fine now)!

=item Name: B<indentchar>

=item Class: B<Indentchar>

=item Switch: B<-indentchar>

String to be inserted when the [Tab] key is pressed or when indenting.  
Can also be set to one or more spaces.

Default:  B<"\t"> (tab character).

=item Name: B<match>

=item Class: B<Match>

=item Switch: B<-match>

string of pairs for brace/bracket/curly etc matching. If this description 
doesn't make anything clear, don't worry, the default setting will:

Default:  I<"[]{}()">

if you don't want matching to be available, simply set it to B<"">.

=item Name: B<matchoptions>

=item Class: B<Matchoptions>

=item Switch: B<-matchoptions>

Options list for the tag 'Match' (the temporary color of the matched brace 
character, if found, while the cursor is on the other matching brace.

Default:  B<[-background => 'red', -foreground => 'yellow']>

You can also specify this option as a space separated string. Might come in 
handy for your Xresource files, ie.  B<"-background red -foreground yellow">.

=item Name: Not available

=item Class: Not available

=item Switch: B<-noPlugInit>

Disables TextHighlight feature of initializing default rules when no B<.rules> 
file present.

Default:  B<false> (Enable initialing with default rules).

=item Name: noPopupMenu

=item Class: NoPopupMenu

=item Switch: B<-noPopupMenu>

Disables the right mouse button (Button-3) popup menu common on 
Tk::Text* widgets.  

NOTE:  Unlike B<-disablemenu>, this must be set in initial configuration 
and can not be changed by configure() later.  (See also B<-disablemenu>).

Default:  B<false> (Menu will be created and will popup when right mouse 
button is pressed over the widget - unless B<-disablemenu> is later configured 
to B<true>).

=item Name: Not available

=item Class: Not available

=item Switch: B<-noRulesEditMenu>

Don't show the B<Rules Editor> option in the B<View> submenu of the 
right-click menu.

Default:  B<false> (Include this option item in the B<View> submenu).

=item Name: Not available

=item Class: Not available

=item Switch: B<-noRulesMenu>

Don't show any of the TextHighlight menu items (combines B<-noSyntaxMenu>, 
B<-noRulesEditMenu>, and B<-noSaveRulesMenu> options.

Default:  B<false> (Include all three, except any blocked by the more 
specific options described above).

=item Name: Not available

=item Class: Not available

=item Switch: B<-noSaveRulesMenu>

Don't show the B<Save Rules> submenu option in the B<View> submenu of the 
right-click menu.

Default:  B<false> (Include this option item in the B<View> submenu).

=item Name: Not available

=item Class: Not available

=item Switch: B<-noSyntaxMenu>

Don't show the B<Syntax> submenu option in the B<View> submenu of the 
right-click menu.

Default:  B<false> (Include this submenu in the B<View> submenu).

=item Name:	B<readOnly>

=item Class:	B<ReadOnly>

=item Switch:	B<-readonly>

If set to a true value, causes the TextHighlight widget to be "readonly" 
(content not changeable by the user).  If false, the widget content is 
editable.  The default is 0 (false), unless a copy of or symlink to the 
TextHighlight.pm module file named I<"ROTextHighlight.pm">, and the module is 
"used" as B<"Tk::ROTextHighlight">, in which case the value is fixed 
as 1 (I<true>), regardless of this setting, and can not be changed to false.

Default:  B<false> (if "use TextHighlight"), B<true> (if "use ROTextHighlight").

=item Name: not available

=item Class: not available

=item Switch B<-rules>

Specify the color and font options for highlighting. You specify a list 
looking a bit like this.

 [
     ['Tagname1', @options1],
     ['Tagname2', @options2],
 ]

The names of the tags are depending on the syntax that is highlighted.  
See the language modules for more information about this data structure.

Default:  The rules set by whatever language plugin is in use.

=item Name: rulesdir

=item Class: Rulesdir

=item Switch B<-rulesdir>

Specify the directory where this widget stores its coloring definitions. 
Files in this directory are stored as "HTML.rules", "Perl.rules" etc.  
By default it is set to '', which means that when you switch syntax 
the highlighting rules are not loaded or stored. The hard coded defaults 
in the language modules will be used.

=item Name: not available

=item Class: not available

=item Switch B<-smartindent>

Boolean, when pressing the enter button I<and> I<-autoindent> is also true, 
the indentation is also affected by the last character on the previous line, 
ie. if "{", "(", "[", etc. is an opening bracket character, and on the 
indentation and first character of the following line, ie. "}", ")", etc., to 
be (hopefully) more convenient for programmers.

Default:  B<true> (but practically false, since I<-autoindent> 
currently defaults to false).

=item Name: B<syntax>

=item Class: B<Syntax>

=item Switch: B<-syntax>

Specifies the language for highlighting. At this moment the possible 
values are B<None>, B<HTML>, B<Perl>, B<Pod> B<Kate::>I<Language>, 
and B<Xresources>.

Default:  B<None>

If L<Syntax::Highlight::Engine::Kate> is installed, you may specify any 
language that the B<Kate> syntax highlight engine supports.

Alternatively it is possible to specify a reference to your independent plugin. 

=item Name: B<syntax>

=item Class: B<Syntax>

=item Switch: B<-syntaxcomments>

Boolean, when set to I<true>, the I<-commentchar> will be set (overridden) 
to the comment string for the specific language (I<-syntax>) for certain 
supported languages (C, C++, CSS, HTML, Modula-II, Pascal, Perl, and XML).

Default:  B<false> (use the preset string in B<-commentchar>.

=item Name: Not available

=item Class: Not available

=item Switch: B<-updatecall>

Here you can specify a callback that will be executed whenever the insert 
cursor has moved or text has been modified, so your application can keep 
track of position etc. Don't make this callback to heavy, the widget will 
get sluggish quickly!

Default:  none (B<sub {}>)

=back

=head1 METHODS

=over 4

=item B<addKate2ViewMenu(I<sections>)>

Inserts the list of B<Kate>-supported languages to the widget's Syntax.  View 
right-mousebutton popup menu along with the basic TextHight-supported choices. 
These choices can then be selected to change the current language-highlighting 
used in the text in the widget.  B<sections> is a hash-ref normally returned 
as the 1st item in the list returned by B<fetchKateInfo>.  NOTE:  No menu 
items will be added if B<Kate> is not installed or if B<-noRulesMenu> or 
B<-noSyntaxMenu> are set!

=item B<Backspace()>

Mostly for internal use - Handles user-pressing of the [backspace] key so that 
it's not passed down to the underlying *Text* widgets.  This is so we can have 
consistant behavior regardless of which one us chosen/loaded.

=item B<beginUndoBlock>

Used in application programs when wishing to group together a series of edits 
that, in the event of a call to B<Undo()> should be undone together as a 
group.  This method should be called before the first insertion or deletion.  
See also B<endUndoBlock>.

=item B<clipboardCopy>

Copies any selected text to the system's CLIPBOARD paste-buffer.

Default bindings:  B<Control-c>.

=item B<clipboardCut>

Default bindings:  B<Control-x>.

Deletes the selected text from the widget and puts it in the system's 
CLIPBOARD paste-buffer.

=item B<clipboardPaste>

Pastes the content of the system's CLIPBOARD paste-buffer at the current 
cursor position and selects it.

Default bindings:  B<Control-v>.

=item B<delete(I<index1, ?index2?>)>

Delete a range of characters from the text. If both index1 and index2 are 
specified, then delete all the characters starting with the one given by 
index1 and stopping just before index2 (i.e. the character at index2 is not 
deleted).  If index2 doesn't specify a position later in the text than index1 
then no characters are deleted. If index2 isn't specified then the single 
character at index1 is deleted. It is not allowable to delete characters in a 
way that would leave the text without a newline as the last character. The 
command returns an empty string. If more indices are given, multiple ranges of 
text will be deleted. All indices are first checked for validity before any 
deletions are made. They are sorted and the text is removed from the last 
range to the first range to deleted text does not cause a undesired index 
shifting side-effects. If multiple ranges with the same start index are given, 
then the longest range is used. If overlapping ranges are given, then they 
will be merged into spans that do not cause deletion of text outside the 
given ranges due to text shifted during deletion.

=item B<doAutoIndent(I<boolean>)>

Checks the indention of the previous line and indents the line where the 
cursor is equally deep.  If a <true> value is passed in, and I<-autoindent> 
is set to I<true>.  Otherwise, I<false> will cause no indentation to be added 
when pressing the I<Return> key.  Note if both I<-autoindent> and 
I<-smartindent> are set to I<true> values, indentation will also be affected 
by the indentation of the next line, and whether the current line ends with 
an opening brace character or the next line begins with an opening brace 
character, causing indentation to be more typical to that used in computer 
source code.  I<-smartindent> is ignored if I<-autoindent> is false.

Default bindings:  B<Return key>:  doAutoIndent(I<true>), B<Shift-Return>:  
doAutoIndent(I<false>)

=item B<EmptyDocument()>

Resets the widget to an empty state (ie. $w->delete('0.0', 'end'), except is 
actionable even if the widget is readonly!

=item B<extendSelect()>

Selects text between the insert cursor to the current mouse position when 
pressed, then adjusted again if the mouse is released in a different place 
than when pressed.  The insert cursor should remain in it's current location 
(like a pivot point).

Default bindings:  B<Shift-ButtonPress-3>, and B<ButtonPress-3> if the 
I<-noPopupMenu> option is set to I<true>.

=item B<endUndoBlock()>

Used in application programs when wishing to group together a series of edits 
that, in the event of a call to B<Undo()> should be undone together as a 
group.  This method should be called after the last insertion or deletion.  
See also B<beginUndoBlock>.

=item B<fetchKateInfo()>

Returns 3 hashrefs containing information about the installed Kate highlight 
engine (if installed).  The three hashrefs contain in order:  The first can be 
passed to the B<addkate2viewmenu()> method to add the B<Kate> languages to the 
Syntax.View menu.  the keys are "Kate::language" and the values are what's 
needed to instantiate Kate for that language.  the 2nd is a list of file-
extension pattern suitable for matching against file-names and the values are 
the reccomended Kate language for that file-extension.  It will return 
B<(undef, undef, undef)>  if B<Kate> is not installed.

=item B<get(I<index1, ?index2?>)>

Return a range of characters from the text. The return value will be all the 
characters in the text starting with the one whose index is index1 and ending 
just before the one whose index is index2 (the character at index2 will not 
be returned). If index2 is omitted then the single character at index1 is 
returned. If there are no characters in the specified range (e.g. index1 is 
past the end of the file or index2 is less than or equal to index1) then an 
empty string is returned. If the specified range contains embedded windows, no 
information about them is included in the returned string. If multiple index 
pairs are given, multiple ranges of text will be returned in a list. Invalid 
ranges will not be represented with empty strings in the list. The ranges are 
returned in the order passed to get.

=item B<getViewMenu()>

Returns the "View" submenu of the Popup menu, which the application can clone 
and include in their application's menu, particularly if they do not wish to 
use the normal mouse button-3 popup menu.  Note, this may not work (untested) 
if I<-noPopupMenu> is set to I<true>, but will if I<-disablemenu> is 
(See I<-disablemenu> and I<-noPopupMenu>).

=item B<highlight(I<begin>, I<end>)>

Does syntax highlighting on the section of text indicated by I<begin> 
and I<end>.  I<begin> and I<end> are linenumbers not indexes!

=item B<highlightCheck(I<begin>, I<end>)>

An insert or delete has taken place affecting the section of text between 
I<begin> and I<end>.  B<highlightCheck> is being called after and insert or 
delete operation.  I<begin> and I<end> (again, linenumbers, not indexes) 
indicate the section of text affected. B<highlightCheck> checks what needs to 
be highlighted again and does the highlighting.

=item B<highlightLine(I<line>)>

Does syntax highlighting on linenumber I<line>.

=item B<highlightPlug()>

Checks whether the appropriate highlight plugin has been loaded. If none or the 
wrong one is loaded, it loads the correct plugin. It returns a reference to 
the plugin loaded.  It also checks wether the rules have changed. If so, it 
restarts highlighting from the beginning of the text.

=item B<highlightPlugInit()>

Loads and initalizes a highlighting plugin. First it checks the value of the 
B<-syntax> option to see which plugin should be loaded. Then it checks wether 
a set of rules is defined to this plugin in the B<-rules> option. If not, it 
tries to obtain a set of rules from disk using B<rulesFetch>.  If this fails 
as well it will use the hardcoded rules from the syntax plugin.

=item B<highlightPurge(I<line>)>

Tells the widget that the text from linenumber $line to the end of the text is 
not to be considered highlighted any more.

=item B<highlightVisual()>

Calls B<visualEnd> to see what part of the text is visible on the display, and 
adjusts highlighting accordingly.

=item B<insert(I<index, chars, ?tagList, chars, tagList, ...?>)>

Inserts all of the chars arguments just before the character at index. If 
index refers to the end of the text (the character after the last newline) 
then the new text is inserted just before the last newline instead. If there 
is a single chars argument and no tagList, then the new text will receive any 
tags that are present on both the character before and the character after the 
insertion point; if a tag is present on only one of these characters then it 
will not be applied to the new text. If tagList is specified then it consists 
of a list of tag names; the new characters will receive all of the tags in 
this list and no others, regardless of the tags present around the insertion 
point. If multiple chars-tagList argument pairs are present, they produce the 
same effect as if a separate insert widget command had been issued for each 
pair, in order. The last tagList argument may be omitted.

=item B<Insert(string)>

Do NOT confuse this with the lower-case insert method. Insert I<string> at the 
point of the insertion cursor. If there is a selection in the text, and it 
covers the point of the insertion cursor, then it deletes the selection 
before inserting.

=item B<InsertKeypress(character)>

Inserts character at the insert mark. If in overstrike mode, it firsts deletes 
the character at the insert mark.

=item B<insertTab()>

Inserts the B<-indentchar> string (Default is I<tab> character.  
See I<-indentchar>

Default bindings:  B<Tab key>

=item B<insertTabChar()>

Inserts a I<tab> character (always).  See I<-indentchar>

Default bindings:  B<Alt-Tab>

=item B<linenumber(I<index>)>

Returns the linenumber part of an I<index>. You may also specify indexes like 
'end' or 'insert' etc.

=item B<jumpToMatchingChar(I<boolean>)>

If the cursor is sitting on a bracing character (see B<-match> option), the 
cursor will jump to the matching character.  If passed a I<true> value, then 
the two brace characters and the text between them will be selected.  There 
is no point in calling this method directly, but rather it can be bound to a 
key-sequence (Default is currently B<Control-p> (jump only), and B<Control-P> 
(jump and select eveything inbetween).

=item B<Load(I<filename>)>

Replaces the content of the widget with the content of file I<filename>.
Returns 1 (I<true>) if successful, 0 (I<false>) otherwise.  One can check 
the Perl variable B<$!> for error message on failure.

=item B<matchCheck()>

Checks wether the character that is just before the 'insert'-mark should be 
matched, and if so, should it match forwards or backwards.  
It then calls B<matchFind>.

=item B<matchFind(I<direction>, I<char>, I<match>, I<start>, I<stop>)>

Matches I<char> to I<match>, skipping nested I<char>/I<match> pairs, and 
displays the match found (if any).

=item B<pastePrimaryAtMouse()>

Paste the primary selection at the current mouse position.

Default bindings:  B<ButtonRelease-2>

=item B<PostPopupMenu()>

Pops up the menu associated with Tk::Text* widgets, including submenu items 
associated with TextHighlight, ie. the language plugins, rules editor, etc.  
Note:  both I<-noPopupMenu> and I<-disablemenu> must NOT be set to I<true>.

Default bindings:  B<ButtonPress-3> (mouse button 3), B<Control-Key-m>

=item B<readonly [ (I<boolean>) ]>

Get or set readonly status for the widget.  If a I<true> or I<false> value are 
passed in, the widget's state will be configured to either I<readonly> or 
I<normal> (editable) respectively.  This should normally be done by the 
B<configure(-readonly, I<boolean>)> function.  NOTE:  If using via 
"use ROTextHighlight" (copy or symlink), then the readonly state is fixed and 
any changes here will be ignored.

=item B<Redo()>

Reapply the last change (or block of changes) undone by the last call to 
B<Undo>.

=item B<ResetUndo()>

Reset (clear) the Undo history stack.

=item B<rulesEdit()>

Pops up a window that enables the user to set the color and font options 
for the current syntax.

=item B<rulesFetch()>

Checks whether the file:

 $text->cget('-rulesdir') . '/' . $text->cget('-syntax') . '.rules'

exists, and if so attempts to load this as a set of rules.

=item B<rulesSave()>

Saves the currently loaded rules as

 $text->cget('-rulesdir') . '/' . $text->cget('-syntax') . '.rules'

=item B<selectionComment()>

Comment currently selected text.

=item B<selectionIndent()>

Indent currently selected text.

=item B<selectionModify()>

Used by the other B<selection...> methods to do the actual work.

=item B<selectionUnComment()>

Uncomment currently selected text.

=item B<selectionUnIndent()>

Unindent currently selected text.

=item B<setRule(I<rulename, colorattribute, color>)>

Allows altering of individual rules by the programmer.

=item B<Space()>

Mostly for internal use - Handles user-pressing of the [spacebar] key so that 
it's not passed down to the underlying *Text* widgets.  This is so we can have 
consistant behavior regardless of which one us chosen/loaded.

=item B<Undo()>

Undo the last change (or block of changes) to the text (the top of the 
Undo stack).

=back

=head1 SYNTAX HIGHLIGHTING, The Gory Details

This section is a brief description of how the syntax highlighting 
process works.  Note:  Most users should not need to worry about this stuff 
when simply incorporating a Tk::TextHighlight widget into their Perl/Tk 
application, except for perhaps writing a few lines of code in their 
application to determine the value of the B<-syntax> flag (see the B<SYNOPSIS> 
section for an example) from the content or extension of a file they plan to 
edit in the widget, ie.:

 $e->configure(-syntax => 'Perl')  if (filename =~ /\.p[lm]$/);

Users will hardly ever need to change the default I<rules> for any of the 
language plugins, as Tk::TextHighlight will automatically change any highlight 
rule colors that match (clash with) the user's specified background color, 
preventing invisible text, when the plugin is initiated!

B<Initiating plugin:>

The highlighting plugin is only then initiated when it is needed. When some 
highlighting needs to be done, the widget calls B<highlightPlug> to retrieve 
a reference to the plugin. 

B<highlightPlug> checks wether a plugin is present. Next it will check whether 
the B<-rules> option has been specified or wether the B<-rules> option 
has changed.  If no rules are specified in B<-rules>, it will look for a 
pathname in the B<-rulesdir> option. If that is found it will try to load a 
file called '*.rules', where * is the value of B<-syntax>. 

If no plugin is present, or the B<-syntax> option has changed value, 
B<highlightPlug> loads the plugin. and constructs optionally giving it 
a reference to the found rules as parameter. if no rules 
are specified, the plugin will use its internal hardcoded defaults.

B<Changing the rules>

A set of rules is a list, containing lists of tagnames, followed by options.  
If you want to see what they look like, you can have a look at the constructors 
of each plugin module. Every plugin has a fixed set of tagnames it can handle.

There are two ways to change the rules.

You can invoke the B<rulesEdit> method, which is also available through the 
B<View> menu. The result is a popup in which you can specify color and font 
options for each tagname. After pressing 'Ok', the edited rules will 
be applied.  If B<-rulesdir> is specified, the rules will be saved on disk as 
I<rulesdir/syntax.rules>.

You can also use B<configure> to specify a new set of rules. In this you have 
ofcause more freedom to use all available tag options. For more details about 
those there is a nice section about tag options in the Tk::Text documentation.  
After the call to B<configure> it is wise to call B<highlightPlug>.

B<Highlighting text>

Syntax highlighting is done in a lazy manor. Only that piece of text is 
highlighted that is needed to present the user a pretty picture. This is 
done to minimize use of system resources. Highlighting is running on the 
foreground. Jumping directly to the end of a long fresh loaded textfile may 
very well take a couple of seconds.

Highlighting is done on a line by line basis. At the end of each line the
highlighting status is saved in the list in B<-colorinf>, so when highlighting
the next line, the B<highlight> method of B<TextHighlight> will know how 
to begin.

More information about those methods is available in the documentation of 
Tk::TextHighlight::None and Tk::TextHighlight::Template.

B<Inheriting Tk::TextHighlight::Template>

For many highlighting problems Tk::TextHighlight::Template 
provides a nice basis to start from. Your code could look like this:

 package Tk::TextHighlight::MySyntax;
 
 use strict;
 use base('Tk::TextHighlight::Template');
 
 sub new {
    my ($proto, $wdg, $rules) = @_;
    my $class = ref($proto) || $proto;

Next, specify the set of hardcoded rules.

    if (not defined($rules)) {
       $rules =  [
          ['Tagname1', -foreground => 'red'],
          ['Tagname1', -foreground => 'red'],
       ];
    };

Call the constructor of Tk::TextHighlight::Template and bless your object.

    my $self = $class->SUPER::new($rules);

So now we have the SUPER class avalable and we can start defining 
a couple of things.

You could add a couple of lists, usefull for keywords etc.

    $self->lists({
        'Keywords' => ['foo', 'bar'],
        'Operators' => ['and', 'or'],
    });

For every tag you have to define a corresponding callback like this.

    $self->callbacks({
        'Tagname1' => \&Callback1,
        'Tagname2' => \&Callback2,
    });

You have to define a default tagname like this:

    $self->stackPush('Tagname1');

Perhaps do a couple of other things but in the end, wrap up the new method.

    
    bless ($self, $class);
    return $self;
 }

Then you need define the callbacks that are mentioned in the B<callbacks> 
hash. When you just start writing your plugin i suggest you make them look 
like this:

 sub callback1 {
    my ($self $txt) = @_;
    return $self->parserError($txt); #for debugging your later additions
 }

Later you add matching statements inside these callback methods. For instance, 
if you want I<callback1> to parse spaces it is going to look like this:


 sub callback1 {
    my ($self $txt) = @_;
    if ($text =~ s/^(\s+)//) { #spaces
        $self->snippetParse($1, 'Tagname1'); #the tagname here is optional
        return $text;
    }
    return $self->parserError($txt); #for debugging your later additions
 }

If I<callback1> is the callback that is called by default, you have to add 
the mechanism for checking lists to it. Hnce, the code will look like this:

 sub callback1 {
    my ($self $txt) = @_;
    if ($text =~ s/^(\s+)//) { #spaces
        $self->snippetParse($1, 'Tagname1'); #the tagname here is optional
        return $text;
    }
    if ($text =~ s/^([^$separators]+)//) {	#fetching a bare part
        if ($self->tokenTest($1, 'Reserved')) {
            $self->snippetParse($1, 'Reserved');
        } elsif ($self->tokenTest($1, 'Keyword')) {
            $self->snippetParse($1, 'Keyword');
        } else { #unrecognized text
            $self->snippetParse($1);
        }
        return $text
    }
    return $self->parserError($txt); #for debugging your later additions
 }

Have a look at the code of Tk::TextHighlight::Bash. Things should clear up.  
Then, last but not least, you need a B<syntax> method.

B<Using another module as basis>

An example of this approach is the Perl syntax module.

Also with this approach you will have to meet the minimum criteria 
as set out in the B<From scratch> section.

=head1 CONTRIBUTIONS

If you have written a plugin, i will be happy to include it in the next release 
of Tk::TextHighlight. If you send it to me, please have it accompanied with the 
sample of code that you used for testing.

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>

=head1 COPYRIGHT

This module is Copyright (C) 2007-2024 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README file.

This is a derived work from Tk::CodeText, by Hans Jeuken 
(haje at toneel.demon.nl)

Thanks go to Mr. Hans Jeuken for his great work in making this and the Kate 
modules possible.  He did the hard work!

=head1 LICENSE

Copyright 2007-2024 Jim Turner.  C<< <turnerjw784 at yahoo.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 BUGS

Please report any bugs or feature requests to bug-tk-TextHighlight at 
rt.cpan.org, or through the web interface at 
https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-TextHighlight.  
I will be notified, and then you'llautomatically be notified of progress on 
your bug as I make changes.

=head1 TODO

Consider adding some of the Tk::TextUndo methods not currently provided 
by either this module Tk::Text, or Tk::Text::SuperText.

Add additional language modules. I am going to need help on this one.  
We currently support all the original B<Tk::CodeText> languages (included) plus 
all those supported by B<Syntax::Highlight::Engine::Kate>, if it's installed.

The sample files in the test suite should be set up so that conformity 
with the language specification can actually be verified.

=head1 SEE ALSO

=over 4

=item L<Tk::Text>, L<Tk::ROText>, L<Tk::TextUndo>, L<Tk::Text::SuperText>, 
L<Tk::CodeText>, L<Syntax::Highlight::Perl::Improved>, 
L<Syntax::Highlight::Engine::Kate>

=back

=cut
