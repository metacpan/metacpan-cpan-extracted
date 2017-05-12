package Tk::Text::SuperText;

use Exporter ();
use Tk qw(800 Ev);
use Tk::Text;
use Tk::Derived;


#+20010117 JWT TextANSIColor support
my $ansicolor = 0;
eval 'use Term::ANSIColor; 1' or $ansicolor = -1;
#+

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT);

@EXPORT = qw(
	mouseSetInsert mouseSelect mouseSelectWord mouseSelectLine mouseSelectAdd mouseSelectChar
	mouseSelectAddWord mouseSelectAddLine mouseSelectAutoScan mouseSelectAutoScanStop 
	mouseMoveInsert mouseRectSelection mouseMovePageTo mouseMovePage mousePasteSelection 
	moveLeft selectLeft selectRectLeft moveLeftWord selectLeftWord 
	moveRight selectRight selectRectRight moveRightWord selectRightWord moveUp selectUp 
	selectRectUp moveUpParagraph selectUpParagraph moveDown selectDown selectRectDown 
	moveDownParagraph selectDownParagraph moveLineStart selectToLineStart moveTextStart 
	selectToTextStart moveLineEnd selectToLineEnd moveTextEnd selectToTextEnd movePageUp 
	selectToPageUp movePageLeft movePageDown selectToPageDown movePageRight 
	setSelectionMark selectToMark selectAll selectionShiftLeft selectionShiftLeftTab 
	selectionShiftRight selectionShiftRightTab ins enter autoIndentEnter 
	noAutoIndentEnter del backSpace deleteToWordStart deleteToWordEnd deleteToLineStart 
	deleteToLineEnd deleteWord deleteLine insertControlCode focusNext focusPrev 
	flashMatchingChar removeMatch findMatchingChar jumpToMatchingChar escape tab 
	leftTab copy cut paste inlinePaste undo redo destroy keyPress menuSelect noOP
);

$VERSION = '0.11';
@ISA = qw(Tk::Derived Tk::Text Exporter);

use base qw(Tk::Text);

Construct Tk::Widget 'SuperText';

my (%fgcolors, %bgcolors, $clear, $code_bold, $code_uline, @colors);

#+20010117 JWT TextANSIColor support
unless ($ansicolor == -1)
{
	$clear = color('clear');  # Code to reset control codes
	$code_bold = color('bold');
	$code_uline= color('underline');
	@colors = qw/black red green yellow blue magenta cyan white/;
	for (@colors)
	{
		my $fg = color($_);
		my $bg = color("on_$_");
		
		$fgcolors{$fg} = "ANSIfg$_";
		$bgcolors{$bg} = "ANSIbg$_";
	}
}
#+

# returns an hash with the default events and key binds
sub DefaultEvents {
	my (%events);
	
	%events = (
		'MouseSetInsert'			=>	['<1>'],
		'MouseSelect'				=>	['<B1-Motion>'],
		'MouseSelectWord'			=>	['<Double-1>'],
		'MouseSelectLine'			=>	['<Triple-1>'],
		'MouseSelectChar'			=>	['<ButtonRelease-3>'],    #ADDED 1999/07 by JWT TO CAUSE RIGHT BUTTON TO EXTEND SELECT!
		'MouseSelectAdd'			=>	['<Shift-1>'],
		'MouseSelectAddWord'		=>	['<Double-Shift-1>'],
		'MouseSelectAddLine'		=>	['<Triple-Shift-1>'],
		'MouseSelectAutoScan'		=>	['<B1-Leave>'],
		'MouseSelectAutoScanStop'	=>	['<B1-Enter>','<ButtonRelease-1>'],
		'MouseMoveInsert'			=>	['<Alt-1>'],
		'MouseRectSelection'		=>	['<Control-B1-Motion>'],
		'MouseMovePageTo'			=>	['<2>'],
		'MouseMovePage'			=>	['<B2-Motion>'],
		'MousePasteSelection'		=>	['<ButtonRelease-2>'],
		
		'MoveLeft'					=>	['<Left>'],
		'SelectLeft'				=>	['<Shift-Left>'],
		'SelectRectLeft'			=>	['<Shift-Alt-Left>'],
		'MoveLeftWord'				=>	['<Control-Left>'],
		'SelectLeftWord'			=>	['<Shift-Control-Left>'],
		'MoveRight'				=>	['<Right>'],
		'SelectRight'				=>	['<Shift-Right>'],
		'SelectRectRight'			=>	['<Shift-Alt-Right>'],
		'MoveRightWord'			=>	['<Control-Right>'],
		'SelectRightWord'			=>	['<Shift-Control-Right>'],
		'MoveUp'					=>	['<Up>'],
		'SelectUp'					=>	['<Shift-Up>'],
		'SelectRectUp'				=>	['<Shift-Alt-Up>'],
		'MoveUpParagraph'			=>	['<Control-Up>'],
		'SelectUpParagraph'		=>	['<Shift-Control-Up>'],
		'MoveDown'					=>	['<Down>'],
		'SelectDown'				=>	['<Shift-Down>'],
		'SelectRectDown'			=>	['<Shift-Alt-Down>'],
		'MoveDownParagraph'		=>	['<Control-Down>'],
		'SelectDownParagraph'		=>	['<Shift-Control-Down>'],
		'MoveLineStart'			=>	['<Home>'],
		'SelectToLineStart'		=>	['<Shift-Home>'],
		'MoveTextStart'			=>	['<Control-Home>'],
		'SelectToTextStart'		=>	['<Shift-Control-Home>'],
		'MoveLineEnd'				=>	['<End>'],
		'SelectToLineEnd'			=>	['<Shift-End>'],
		'MoveTextEnd'				=>	['<Control-End>'],
		'SelectToTextEnd'			=>	['<Shift-Control-End>'],
		'MovePageUp'				=>	['<Prior>'],
		'SelectToPageUp'			=>	['<Shift-Prior>'],
		'MovePageLeft'				=>	['<Control-Prior>'],
		'MovePageDown'				=>	['<Next>'],
		'SelectToPageDown'			=>	['<Shift-Next>'],
		'MovePageRight'			=>	['<Control-Next>'],
		'SetSelectionMark'			=>	['<Control-space>','<Select>'],
		'SelectToMark'				=>	['<Shift-Control-space>','<Shift-Select>'],
#=20010117 JWT selection extensions
#		'SelectAll'				=>	['<Control-a>'],
		'SelectAll'				=>	['<Triple-1><Button-1>','<Control-a>','<Control-slash>'],
#=
		'SelectionShiftLeft'		=>	['<Control-comma>'],
		'SelectionShiftLeftTab'	=>	['<Control-Alt-comma>'],
		'SelectionShiftRight'		=>	['<Control-period>'],
		'SelectionShiftRightTab'	=>	['<Control-Alt-period>'],
		
		'Ins'						=>	['<Insert>'],
		'Enter'					=>	['<Return>'],
		'AutoIndentEnter'			=>	['<Control-Return>'],
		'NoAutoIndentEnter'		=>	['<Shift-Return>'],
		'Del'						=>	['<Delete>'],
#-1999/07/11 alexiob@dlevel.com - Fixed win32 BackSpace bug thanks to Jim Turner
#		'BackSpace'				=>	['<BackSpace>'],
		'DeleteToWordStart'		=>	['<Shift-BackSpace>'],
		'DeleteToWordEnd'			=>	['<Shift-Delete>'],
		'DeleteToLineStart'		=>	['<Alt-BackSpace>'],
		'DeleteToLineEnd'			=>	['<Alt-Delete>'],
		'DeleteWord'				=>	['<Control-BackSpace>'],
		'DeleteLine'				=>	['<Control-Delete>'],
		
		'InsertControlCode'		=>	['<Control-Escape>'],
		
		'FocusNext'				=>	['<Control-Tab>'],
		'FocusPrev'				=>	['<Shift-Control-Tab>'],
		
		'FlashMatchingChar'		=>	['<Control-b>'],
		'RemoveMatch'				=>	['<Control-B>'],
		'FindMatchingChar'			=>	['<Control-j>'],
		'JumpToMatchingChar'		=>	['<Control-J>'],
#+20010117 JWT fix
		'JumpToMatchingChar'		=>	['<Control-p>'],
#+		
		'Escape'					=>	['<Escape>'],
		'Tab' 						=>	['<Tab>'],
		'LeftTab' 					=>	['<Shift-Tab>'],
		'Copy' 					=>	['<Control-c>'],
		'Cut' 						=>	['<Control-x>'],
		'Paste' 					=>	['<Control-v>'],
		'InlinePaste'				=>	['<Control-V>'],
		'Undo' 					=>	['<Control-z>'],
		'Redo' 					=>	['<Control-Z>'],
		
		'Destroy'					=>	['<Destroy>'],

		'KeyPress'					=>	['<KeyPress>'],
		'MenuSelect'				=>	['<Alt-KeyPress>'],
		
		'NoOP'						=>	['<Control-KeyPress>']
	);
	
	return \%events;	
} # /DefaultEvents

sub ClassInit
{
	my ($class,$w) = @_;
	
	$class->SUPER::ClassInit($w);
	
	# reset default Tk::Text binds
	$class->RemoveTextBinds($w);
	
	return $class;
}

sub Populate
{
#+20010117 JWT TextANSIColor support
	my	($w,$args) = @_;
	
	$w->{ansicolor} = 0;
	$w->{ansicolor} = delete ($args->{-ansicolor})  if (defined($args->{-ansicolor}));
#+

	$w->SUPER::Populate($args);

	# and set configuration parameters defaults
	$w->ConfigSpecs(
		'-indentmode'		=> ['PASSIVE','indentMode','IndentMode','auto'],
#+20010117 JWT TextANSIColor support
		'-ansicolor'		=> ['PASSIVE','ansicolor','ansicolor',undef],
#+
		'-undodepth'	 	=> ['PASSIVE','undoDepth','UndoDepth',undef],
		'-redodepth' 		=> ['PASSIVE','redoDepth','RedoDepth',undef],
		'-showmatching' 	=> ['PASSIVE','showMatching','ShowMatching',1],
		'-matchhighlighttime' 	=> ['PASSIVE','matchHighlightTime','MatchHighlightTime',1400],
		'-matchforeground'	=> ['METHOD','matchForeground','MatchForeground','white'],
		'-matchbackground'	=> ['METHOD','matchBackground','MatchBackground','blue'],
		'-matchingcouples'	=> ['METHOD','matchingCouples','MatchingCouples',"//[]{}()<>\\\\''``\"\""],
		'-insertmode'		=> ['METHOD','insertMode','InsertMode','insert'],
		'-foreground'		=> ['SELF','foreground','Foreground',$w->cget('-foreground')],
	);
	# set default key binds and events
	$w->bindDefault;
	# set undo block flag
	$w->{UNDOBLOCK}=0;

#+20010117 JWT TextANSIColor support
	if ($w->{ansicolor})
	{
		# Setup tags
		# colors
		for (@colors)
		{
			$w->tagConfigure("ANSIfg$_", -foreground => $_);
			$w->tagConfigure("ANSIbg$_", -background => $_);
		}
		# Underline
		$w->tagConfigure("ANSIul", -underline => 1);
		$w->tagConfigure("ANSIbd", -font => [-weight => "bold" ]);
	}
#+
}

# callbacks for options management

sub matchforeground
{
	my ($w,$val) = @_;
	
	if(!defined $val) {return $w->tagConfigure('match','-foreground');}
	$w->tagConfigure('match','-foreground' => $val);
}

sub matchbackground
{
	my ($w,$val) = @_;
	
	if(!defined $val) {return $w->tagConfigure('match','-background');}
	$w->tagConfigure('match','-background' => $val);
}

sub matchingcouples
{
	my ($w,$val) = @_;
	my ($i,$dir);
	

	if(!defined $val) {return $w->{MATCHINGCOUPLES_STRING};}
	$w->{MATCHINGCOUPLES_STRING}=$val;

	$w->{MATCHINGCOUPLES}={} unless exists $w->{MATCHINGCOUPLES};
	for($i=0;$i<length($val);$i++) {
		$dir=($i % 2 ? -1 : 1);
		if($dir == -1 && (substr($val,$i,1) eq substr($val,$i+$dir,1))) {next;}
		$w->{MATCHINGCOUPLES}->{substr($val,$i,1)}=[substr($val,$i+$dir,1),$dir];
	}
}

sub insertmode
{
	my ($w,$val) = @_;
	
	if(!defined $val) {return $w->{INSERTMODE};}
	$w->{INSERTMODE}=$val;
}

# insertion and deletion functions intereptors

sub insert
{
	my ($w,$index,$str,@tags) = @_;
	my $s = $w->index($index);
	my $i;

	# for line start hack
	$w->{LINESTART}=0;
	
	$w->markSet('undopos' => $s);
	# insert ascii code
	if((exists $w->{ASCIICODE}) && $w->{ASCIICODE} == 1) {
		if(($str ge ' ') && ($str le '?')) {$i=-0x20;}
		else {$i=0x7f-0x40;}
		$str=sprintf('%c',ord($str) + $i);
		$w->{ASCIICODE} = 0;
	}
	# manage overwrite mode,NOT optimal for undo,but... hey who uses overwrite mode???
	if($w->{INSERTMODE} eq 'overwrite') {
		$w->_BeginUndoBlock;
		if($w->compare($s,'<',$w->index("$s lineend"))) {$w->delete($s);}
	}

#-20010117 JWT TextANSIColor support
#	$w->SUPER::insert($s,$str,@tags);
#-
#+20010117 JWT TextANSIColor support
	if ($w->{ansicolor})
	{
		#$w->SUPER::insert($s,$str,@tags);  #JWT:01042001: REPL. W/NEXT LINES FOR TEXTANSICOLOR!
		my (@userstuff) = ($str,@tags);
		my ($pos) = $s;
		
		# This is the array containing text and tags pairs
		# We pass this to SUPER::insert 
		# as (POS, string, [tags], string, [tags]....)
		# insert_array contains string,[tags] pairs
		my @insert_array = ();
		
		# Need to loop over @userstuff
		# extracting out the text string and any user supplied tags.
		# note that multiple sets of text strings and tags can be supplied
		# as arguments to the insert() method, and we have to process
		# each set in turn.
		# Use an old-fashioned for since we have to extract two items at 
		# a time
		
		for (my $i=0; $i <= $#userstuff; $i += 2)
		{
			
			my $text = $userstuff[$i];
			my $utags = $userstuff[$i+1];
			
			# Store the usertags in an array, expanding the
			# array ref if required
			my @taglist = ();
			if (ref($utags) eq 'ARRAY')
			{
				@taglist = @{$utags};
			}
			else
			{
				@taglist = ($utags);
			}
			
			# Split the string on control codes
			# returning the codes as well as the strings between
			# the codes
			# Note that this pattern also checks for the case when
			# multiple escape codes are embedded together separated
			# by semi-colons.
			my @split = split /(\e\[(?:\d{1,2};?)+m)/, $text;
			# Array containing the tags to use with the insertion
			# Note that this routine *always* assumes the colors are reset
			# after the last insertion. ie it does not allow the colors to be 
			# remembered between calls to insert(). 
			my @ansitags = ();
			
			# Current text string
			my $cur_text = undef;
			
			# Now loop over the split strings
			for my $part (@split)
			{
				
				# If we have a plain string, just store it
				if ($part !~ /^\e/)
				{
					$cur_text = $part;
				}
				else
				{
					# We have an escape sequence
					# Need to store the current string with required tags
					# Include the ansi tags and the user-supplied tag list
					push(@insert_array, $cur_text, [@taglist, @ansitags])
					if defined $cur_text;
					
					# There is no longer a 'current string'
					$cur_text = undef;
					
					# The escape sequence can have semi-colon separated bits
					# in it. Need to strip off the \e[ and the m. Split on
					# semi-colon and then reconstruct before comparing
					# We know it matches \e[....m so use substr
					
					# Only bother if we have a semi-colon
					
					my @escs = ($part);
					if ($part =~ /;/)
					{
						my $strip = substr($part, 2, length($part) - 3);
						
						# Split on ; (overwriting @escs)
						@escs = split(/;/,$strip);
						
						# Now attach the correct escape sequence
					foreach (@escs) { $_ = "\e[${_}m" }
					}
					
					# Loop over all the escape sequences
					for my $esc (@escs)
					{
						
						# Check what type of escape
						if ($esc eq $clear)
						{
							# Clear all escape sequences
							@ansitags = ();
						}
						elsif (exists $fgcolors{$esc})
						{
							# A foreground color has been specified
							push(@ansitags, $fgcolors{$esc});
						}
						elsif (exists $bgcolors{$esc})
						{
							# A background color
							push(@ansitags, $bgcolors{$esc});
						}
						elsif ($esc eq $code_bold)
						{
							# Boldify
							push(@ansitags, "ANSIbd");
						}
						elsif ($esc eq $code_uline)
						{
							# underline
							push(@ansitags, "ANSIul");
						}
						else
						{
							print "Unrecognised control code - ignoring\n";
							foreach (split //, $esc)
							{
								print ord($_) . ": $_\n";
							}
						}			
					}
				}
			}
			# If we still have a current string, push that onto the array
			push(@insert_array, $cur_text, [@taglist, @ansitags])
					if defined $cur_text;
		}
		# Finally, insert  the string
		$w->SUPER::insert($pos, @insert_array)
		if $#insert_array > 0;		
	}
	else
	{
		$w->SUPER::insert($s,$str,@tags);  #JWT:01042001: REPL. W/NEXT LINES FOR TEXTANSICOLOR!
	}
#+

	# match coupled chars
	if((!defined $w->tag('ranges','sel')) && $w->cget('-showmatching') == 1) {
		if(exists $w->{MATCHINGCOUPLES}->{$str}) {
			# calculate visible zone and search only in this one
			my ($l,$c) = split('\.',$w->index('end'));
			my ($slimit,$elimit) = $w->yview;
			
			$slimit=int($l*$slimit)+1;
			$slimit="$slimit.0";
			$elimit=int($l*$elimit);
			$elimit="$elimit.0";
			my $i=$w->_FindMatchingChar($str,$s,$slimit,$elimit);
			if(defined $i) {
				my $sel = Tk::catch {$w->tag('nextrange','match','1.0','end');};
				if(defined $sel) {$w->tag('remove','match','match.first');}
				$w->tag('add','match',$i,$w->index("$i + 1 c"));
				my $t=$w->cget('-matchhighlighttime');
				if($t != 0) {$w->after($t,[\&removeMatch,$w,$i]);}
			}
		}
	}

	# combine 'trivial ' inserts into clumps
	if((length($str) == 1) && ($str ne "\n")) {
		my $t = $w->_TopUndo;
		if($t && $t->[0] =~ /delete$/ && $w->compare($t->[2],'==',$s)) {
			$t->[2] = $w->index('undopos');
			return;
		}
	}
	$w->_AddUndo('delete',$s,$w->index('undopos'));
	# for undo blocks
	if($w->{INSERTMODE} eq 'overwrite') {
		$w->_EndUndoBlock;
	}
}

sub delete
{
	my $w = shift;
	my $str = $w->get(@_);
	my $s = $w->index(shift);
	
	$w->{LINESTART}=0;
	$w->SUPER::delete($s,@_);
	$w->_AddUndo('insert',$s,$str);
}


# used for removing match tag after some time
# here so Tk::After doesn't complain
sub removeMatch
{
	my ($w,$i) = @_;
	
	if(defined $i) {$w->tag('remove','match',$i);}
	else {$w->tag('remove','match','1.0','end');}
}


#+20010117 JWT TextANSIColor support
#sub get
#{
#	my $self= shift;  # The widget reference
#	return $self->SUPER::get(@_);
#}

sub getansi
{
	my $self= shift;  # The widget reference
	my (@args) = @_;
	return $self->get(@args)  unless ($self->{ansicolor});

	my $i;
	my (@xdump);
	my $tagflag = 0;
	my $res = '';

	@xdump = $self->dump(@args);
	for ($i=0;$i<=$#xdump;$i+=3)
	{
		if ($xdump[$i] eq 'tagon')
		{
			if ($xdump[$i+1] =~ /^ANSIfg(\w+)/)
			{
				$res .= color($1);
				$tagflag = 1;
			}
			elsif ($xdump[$i+1] =~ /^ANSIbg(\w+)/)
			{
				$res .= color("on_$1");
				$tagflag = 1;
			}
			elsif ($xdump[$i+1] =~ /^ANSIbd/)
			{
				$res .= color('bold');
				$tagflag = 1;
			}
			elsif ($xdump[$i+1] =~ /^ANSIul/)
			{
				$res .= color('underline');
				$tagflag = 1;
			}
			#$res .= $xdump[$i+4]  if ($xdump[$i+3] eq 'text');
		}
		if ($tagflag && $xdump[$i] eq 'tagoff')
		{
			$res .= color('reset');
			$tagflag = 0;
		}
		if ($xdump[$i] eq 'text')
		{
			$res .= $xdump[$i+1];
		}
	};
	return $res;
}
#+

# clipboard methods that must be overriden for rectangular selections

sub deleteSelected
{
	my $w = shift;
	
	if(!defined $Tk::selectionType || ($Tk::selectionType eq 'normal')) {
		$w->SUPER::deleteSelected;
	} elsif ($Tk::selectionType eq 'rect') {
		my ($sl,$sc) = split('\.',$w->index('sel.first'));
		my ($el,$ec) = split('\.',$w->index('sel.last'));
		my ($i,$x);
		
		# delete only text in the rectangular selection range
		$w->_BeginUndoBlock;
		for($i=$sl;$i<=$el;$i++) {
			my ($l,$c) = split('\.',$w->index("$i.end"));
			# check if selection is too right (??) for this line
			if($sc > $c) {next;}
			# and clip selection
			if($ec <= $c) {$x=$ec;}
			else { $x=$c;}
			
			$w->delete($w->index("$i.$sc"),$w->index("$i.$x"));
		}
		$w->_EndUndoBlock;
	}
}

sub getSelected
{
	my $w = shift;
	
	if(!defined $Tk::selectionType || ($Tk::selectionType eq 'normal')) {
		return $w->SUPER::getSelected;
	} elsif ($Tk::selectionType eq 'rect') {
		my ($sl,$sc) = split('\.',$w->index('sel.first'));
		my ($el,$ec) = split('\.',$w->index('sel.last'));
		my ($i,$x);
		my ($sel,$str);
		
		$sel="";
		
		# walk throught all the selected lines and add a sel tag
		for($i=$sl;$i<=$el;$i++) {
			my ($l,$c) = split('\.',$w->index("$i.end"));
			# check if  selection is too much to the right
			if($sc > $c) {next;}
			# or clif if too wide
			if($ec <= $c) {$x=$ec;}
			else { $x=$c;}
			$str=$w->get($w->index("$i.$sc"),$w->index("$i.$x"));
			# add a new line if not the last line
			if(substr($str,-1,1) ne "\n") {
				$str=$str."\n";
			}
			$sel=$sel.$str;
		}
		return $sel;
	}
}

# redefine SetCursor for parentheses highlight
sub SetCursor
{
	my $w = shift;
	my $str;
	
	$w->SUPER::SetCursor(@_);
	
	if((!defined $w->tag('ranges','sel')) && $w->cget('-showmatching') == 1) {
		if(exists $w->{MATCHINGCOUPLES}->{$str=$w->get('insert','insert + 1c')}) {
			# calculate visible zone and search only in this one
			my ($l,$c) = split('\.',$w->index('end'));
			my ($slimit,$elimit) = $w->yview;
			
			$slimit=int($l*$slimit)+1;
			$slimit="$slimit.0";
			$elimit=int($l*$elimit);
			$elimit="$elimit.0";
			my $i=$w->_FindMatchingChar($str,'insert',$slimit,$elimit);
			if(defined $i) {
				my $sel = Tk::catch {$w->tag('nextrange','match','1.0','end');};
				if(defined $sel) {$w->tag('remove','match','match.first');}
				$w->tag('add','match',$i,$w->index("$i + 1c"));
				my $t=$w->cget('-matchhighlighttime');
				if($t != 0) {$w->after($t,[\&removeMatch,$w,$i]);}
			}
		}
	}
}	

# redefine Button1for parentheses highlight
sub Button1
{
	my $w = shift;
	my $str;
	
	$w->SUPER::Button1(@_);
	
	if((!defined $w->tag('ranges','sel')) && $w->cget('-showmatching') == 1) {
		if(exists $w->{MATCHINGCOUPLES}->{$str=$w->get('insert','insert + 1c')}) {
			# calculate visible zone and search only in this one
			my ($l,$c) = split('\.',$w->index('end'));
			my ($slimit,$elimit) = $w->yview;
			
			$slimit=int($l*$slimit)+1;
			$slimit="$slimit.0";
			$elimit=int($l*$elimit);
			$elimit="$elimit.0";
			my $i=$w->_FindMatchingChar($str,'insert',$slimit,$elimit);
			if(defined $i) {
				my $sel = Tk::catch {$w->tag('nextrange','match','1.0','end');};
				if(defined $sel) {$w->tag('remove','match','match.first');}
				$w->tag('add','match',$i,$w->index("$i + 1c"));
				my $t=$w->cget('-matchhighlighttime');
				if($t != 0) {$w->after($t,[\&removeMatch,$w,$i]);}
			}
		}
	}
}	

# remove default Tk::Text key binds
sub RemoveTextBinds
{
	my ($class,$w) = @_;
	my (@binds) = $w->bind($class);
	
	foreach $b (@binds) {
#=1999/07/11 alexiob@dlevel.com - Fixed win32 BackSpace bug thanks to Jim Turner
#		$w->bind($class,$b,"");
		$w->bind($class,$b,"") unless ($b =~ /Key-BackSpace/);
	}	
}

# bind default keys with default events 
sub bindDefault
{
	my $w = shift;
	my $events = $w->DefaultEvents;
	
	foreach my $e (keys %$events) {
		$w->eventAdd("<<$e>>",@{$$events{$e}});
		$w->bind($w,"<<$e>>",lcfirst($e));
	}
#+1999/07/11 alexiob@dlevel.com - Fixed win32 BackSpace bug thanks to Jim Turner
	$w->bind("<Key-BackSpace>", sub {Tk->break;});
}

# delete all event binds,specified event bind
sub bindDelete
{
	my ($w,$event,@triggers) = @_;
	
	if(!$event) {
		# delete all events binds
		my ($e);
		
		foreach $e (%{$w->DefaultEvents}) {
			$w->eventDelete($e);
		}
		return;
	}
	$w->eventDelete($event,@triggers);
}

# Key binding Events subs

sub _BeginUndoBlock
{
	my $w = shift;

	$w->_AddUndo('#_BlockEnd_#');
}

sub _EndUndoBlock
{
	my $w = shift;

	$w->_AddUndo('#_BlockBegin_#');
}

# resets undo and redo buffers
sub resetUndo
{
	my $w = shift;
	
	delete $w->{UNDO};
	delete $w->{REDO};
}

# undo last operation
sub undo
{
	my ($w) = @_;
	my $s;
	my $op;
	my @args;
	my $block = 0;
	
	if(exists $w->{UNDO}) {
		if(@{$w->{UNDO}}) {
			# undo loop
			while(1) {
				# retrive undo command
				my ($op,@args) = Tk::catch{@{pop(@{$w->{UNDO}})};};

				if($op eq '#_BlockBegin_#') {
					$w->_AddRedo('#_BlockEnd_#');
					$block=1;
					next;
				} elsif($op eq '#_BlockEnd_#') {
					$w->_AddRedo('#_BlockBegin_#');
					return 1;
				}
				# convert for redo
				if($op =~ /insert$/) {
					# get current insert position
					$s = $w->index($args[0]);
					# mark for getting the with of the insertion
					$w->markSet('redopos' => $s);
				} elsif ($op =~ /delete$/) {
					# save text and position
					my $str = $w->get(@args);
					$s = $w->index($args[0]);
					
					$w->_AddRedo('insert',$s,$str);
				}
				# execute undo command
				$w->$op(@args);
				$w->SetCursor($args[0]);
				# insert redo command
				if($op =~ /insert$/) {
					$w->_AddRedo('delete',$s,$w->index('redopos'));
				}
				if($block == 0) {return 1;}
			}
		}
	}
	$w->bell;
	return 0;
}

# redo last undone operation
sub redo
{
	my ($w) = @_;
	my $block = 0;
	
	if(exists $w->{REDO}) {
		if(@{$w->{REDO}}) {
			while(1) {
				my ($op,@args) = Tk::catch{@{pop(@{$w->{REDO}})};};

				if($op eq '#_BlockBegin_#') {
					$w->_AddUndo('#_BlockEnd_#');
					$block=1;
					next;
				} elsif($op eq '#_BlockEnd_#') {
					$w->_AddUndo('#_BlockBegin_#');
					return 1;
				}
				$op =~ s/^SUPER:://;
				$w->$op(@args);
				$w->SetCursor($args[0]);
				if($block == 0) {return 1;}
			}
		}
	}
	$w->bell;
	return 0;
}

# add an undo command to the undo stack
sub _AddUndo
{
	my ($w,$op,@args) = @_;
	my ($usize,$udepth);
	
	$w->{UNDO} = [] unless(exists $w->{UNDO});
	# check for undo depth limit
	$usize = @{$w->{UNDO}} + 1;
	$udepth = $w->cget('-undodepth');
	
	if(defined $udepth) {
		if($udepth == 0) {return;}
		if($usize >= $udepth) {
			# free oldest undo sequence
			$udepth=$usize - $udepth + 1;
			splice(@{$w->{UNDO}},0,$udepth);
		}
	}
	if($op =~ /^#_/) {push(@{$w->{UNDO}},[$op]);}
	else {push(@{$w->{UNDO}},['SUPER::'.$op,@args]);}
}

# return the last added undo command
sub _TopUndo
{
	my ($w) = @_;
	
	return undef unless (exists $w->{UNDO});
	return $w->{UNDO}[-1];
}

# add a new redo command to the redo stack
sub _AddRedo
{
	my ($w,$op,@args) = @_;
	my ($rsize,$rdepth);
	
	$w->{REDO} = [] unless(exists $w->{REDO});
	
	# check for undo depth limit
	$rsize = @{$w->{REDO}} + 1;
	$rdepth = $w->cget('-undodepth');
	
	if(defined $rdepth) {
		if($rdepth == 0) {return;}
		if($rsize >= $rdepth) {
			# free oldest undo sequence
			$rdepth=$rsize - $rdepth + 1;
			splice(@{$w->{REDO}},0,$rdepth);
		}
	}
	if($op =~ /^#_/) {push(@{$w->{REDO}},[$op]);}
	else {push(@{$w->{REDO}},['SUPER::'.$op,@args]);}
}

# manage mouse normal and rectangular selections  for char,word or line mode
# overrides standard Tk::Text->SelectTo method
sub SelectTo
{
	my $w = shift;
	my $index = shift;
	$Tk::selectMode = shift if (@_);
	my $cur = $w->index($index);
	my $anchor = Tk::catch{$w->index('anchor')};

	# check for mouse movement
	if(!defined $anchor) {
		$w->markSet('anchor',$anchor=$cur);
		$Tk::mouseMoved=0;
	} elsif($w->compare($cur,"!=",$anchor)) {
		$Tk::mouseMoved=1;
	}
	$Tk::selectMode='char' unless(defined $Tk::selectMode);

	my $mode = $Tk::selectMode;
 	my ($first,$last);

	# get new selection limits
	if($mode eq 'char') {
		if($w->compare($cur,"<",'anchor')) {
			$first=$cur;
			$last='anchor';
		} else {
			$first='anchor';
			$last=$cur;
		}
	} elsif($mode eq 'word') {
		if($w->compare($cur,"<",'anchor')) {
			$first = $w->index("$cur wordstart");
			$last = $w->index("anchor - 1c wordend");
		} else {
			$first=$w->index("anchor wordstart");
			$last=$w->index("$cur wordend");
		}
	} elsif($mode eq 'line') {
		if($w->compare($cur,"<",'anchor')) {
			$first=$w->index("$cur linestart");
			$last=$w->index("anchor - 1c lineend + 1c");
		} else {
			$first=$w->index("anchor linestart");
			$last=$w->index("$cur lineend + 1c");
		}
	}
	# update selection
	if($Tk::mouseMoved || $Tk::selectMode ne 'char') {
		if((!defined $Tk::selectionType) || ($Tk::selectionType eq 'normal')) {
			# simple normal selection
			$w->tag('remove','sel','1.0',$first);
			$w->tag('add','sel',$first,$last);
			$w->tag('remove','sel',$last,'end');
			$w->idletasks;
		} elsif($Tk::selectionType eq 'rect') {
			my ($sl,$sc) = split('\.',$w->index($first));
			my ($el,$ec) = split('\.',$w->index($last));
			my $i;
			
			# swap min,max x,y coords
			if($sl >= $el) {($sl,$el)=($el,$sl);}
			if($sc >= $ec) {($sc,$ec)=($ec,$sc);}

			$w->tag('remove','sel','1.0','end');
			# add a selection tag to all the selected lines
			# FIXME: the selection's right limit is the line lenght of the line where mouse is on.BAD!!! 
			for($i=$sl;$i<=$el;$i++) {
				$w->tag('add','sel',"$i.$sc","$i.$ec");
			}
			$w->idletasks;
		}
	} 
}

sub mouseSetInsert
{	
	my $w = shift;
	my $ev = $w->XEvent;

	$w->{LINESTART}=0;
	$w->Button1($ev->x,$ev->y);
}

sub mouseSelect
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$Tk::x=$ev->x;
	$Tk::y=$ev->y;
	$w->SelectTo($ev->xy);
}

sub mouseSelectWord
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->SelectTo($ev->xy,'word');
	Tk::catch {$w->markSet('insert',"sel.first")};
}

sub mouseSelectLine
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->SelectTo($ev->xy,'line');
	Tk::catch {$w->markSet('insert',"sel.first")};
}

#+20010117 JWT cause right button to extend select
sub mouseSelectChar    
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->SelectTo($ev->xy,'char');
	Tk::catch {$w->markSet('insert',"sel.first")};
}
#+

sub mouseSelectAdd
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->ResetAnchor($ev->xy);	
	$w->SelectTo($ev->xy,'char');
}

sub mouseSelectAddWord
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->SelectTo($ev->xy,'word');
}

sub mouseSelectAddLine
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->SelectTo($ev->xy,'line');
}

sub mouseSelectAutoScan
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$Tk::x=$ev->x;
	$Tk::y=$ev->y;
	$w->AutoScan;
}

sub mouseSelectAutoScanStop
{
	my $w = shift;

	$w->CancelRepeat;
}

sub mouseMoveInsert
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='normal';
	$w->markSet('insert',$ev->xy);
}

sub mouseRectSelection
{
	my $w = shift;
	my $ev = $w->XEvent;

	$Tk::selectionType='rect';
	$Tk::x=$ev->x;
	$Tk::y=$ev->y;
	$w->SelectTo($ev->xy);
}

sub mouseMovePageTo
{
	my $w = shift;
	my $ev = $w->XEvent;

	$w->Button2($ev->x,$ev->y);
}

sub mouseMovePage
{
	my $w = shift;
	my $ev = $w->XEvent;

	$w->Motion2($ev->x,$ev->y);
}
    
sub mousePasteSelection
{
	my $w = shift;
	my $ev = $w->XEvent;

	if(!$Tk::mouseMoved) {
		Tk::catch { $w->insert($ev->xy,$w->SelectionGet);};
	}
}

sub KeySelect
{
	my $w = shift;
	my $new = shift;
	my ($first,$last);
	if(!defined $w->tag('ranges','sel')) {
		# No selection yet
		$w->markSet('anchor','insert');
		if($w->compare($new,"<",'insert')) {
			$w->tag('add','sel',$new,'insert');
		} else {
			$w->tag('add','sel','insert',$new);
		}
	} else {
		# Selection exists
		if($w->compare($new,"<",'anchor')) {
			$first=$new;
			$last='anchor';
		} else {
			$first='anchor';
			$last=$new;
		}
		if((!defined $Tk::selectionType) || ($Tk::selectionType eq 'normal')) {
			$w->tag('remove','sel','1.0',$first);
			$w->tag('add','sel',$first,$last);
			$w->tag('remove','sel',$last,'end');
		} elsif($Tk::selectionType eq 'rect') {
			my ($sl,$sc) = split('\.',$w->index($first));
			my ($el,$ec) = split('\.',$w->index($last));
			my $i;
			
			# swap min,max x,y coords
			if($sl >= $el) {($sl,$el)=($el,$sl);}
			if($sc >= $ec) {($sc,$ec)=($ec,$sc);}

			$w->tag('remove','sel','1.0','end');
			# add a selection tag to all the selected lines
			# FIXME: the selection's right limit is the line lenght of the line where mouse is on.BAD!!! 
			for($i=$sl;$i<=$el;$i++) {
				$w->tag('add','sel',"$i.$sc","$i.$ec");
			}
		}
	}
	$w->markSet('insert',$new);
	$w->see('insert');
	$w->idletasks;
}

sub moveLeft
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->index("insert - 1c"));
}

sub selectLeft
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->index("insert - 1c"));
}

sub selectRectLeft
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='rect';
	$w->KeySelect($w->index("insert - 1c"));
}

sub moveLeftWord
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->index("insert - 1c wordstart"));
}

sub selectLeftWord
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->index("insert - 1c wordstart"));
}

sub moveRight
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->index("insert + 1c"));
}

sub selectRight
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->index("insert + 1c"));
}

sub selectRectRight
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='rect';
	$w->KeySelect($w->index("insert + 1c"));
}

sub moveRightWord
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->index("insert + 1c wordend"));
}

sub selectRightWord
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->index("insert wordend"));
}

sub moveUp
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->UpDownLine(-1));
}

sub selectUp
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->UpDownLine(-1));
}

sub selectRectUp
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='rect';
	$w->KeySelect($w->UpDownLine(-1));
}

sub moveUpParagraph
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->PrevPara('insert'));
}

sub selectUpParagraph
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->PrevPara('insert'));
}

sub moveDown
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->UpDownLine(1));
}

sub selectDown
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->UpDownLine(1));
}

sub selectRectDown
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='rect';
	$w->KeySelect($w->UpDownLine(1));
}

sub moveDownParagraph
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->NextPara('insert'));
}

sub selectDownParagraph
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->NextPara('insert'));
}

sub moveLineStart
{
	my $w = shift;
	
	if(exists $w->{LINESTART} && $w->{LINESTART} == 1) {
		$w->SetCursor('insert linestart');
		$w->{LINESTART}=0;
	} else {
		$w->{LINESTART}=1;
		my $str = $w->get('insert linestart','insert lineend');
		my $i=0;
	
		if($str =~ /^(\s+)(\S*)/) {
			if($2) {$i=length($1);}
			else {$i=0};
		}
		$w->SetCursor("insert linestart + $i c");
	}
}

sub selectToLineStart
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect('insert linestart');
}

sub moveTextStart
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor('1.0');
}

sub selectToTextStart
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect('1.0');
}

sub moveLineEnd
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor('insert lineend');
}

sub selectToLineEnd
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect('insert lineend');
}

sub moveTextEnd
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor('end - 1c');
}

sub selectToTextEnd
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect('end - 1c');
}

sub ScrollPages
{
	my ($w,$count) = @_;
	my ($l,$c) = $w->index('end');
	my ($slimit,$elimit) = $w->yview;
	# get current page top and bottom line coords
	$slimit=int($l*$slimit)+1;
	$slimit="$slimit.0";
	$elimit=int($l*$elimit);
	$elimit="$elimit.0";
	# position insert cursor at text begin/end if the text is scrolled to begin/end
	if($count < 0 && $w->compare($slimit,'<=','1.0')) {return('1.0');}
	elsif($count >= 0 && $w->compare($elimit,'>=','end')) {return($w->index('end'));}
	else {return $w->SUPER::ScrollPages($count);}
}
	
sub movePageUp
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->ScrollPages(-1));
}

sub selectToPageUp
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->ScrollPages(-1));
}

sub movePageLeft
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->xview('scroll',-1,'page');
}

sub movePageDown
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->SetCursor($w->ScrollPages(1));
}

sub selectToPageDown
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->KeySelect($w->ScrollPages(1));
}

sub movePageRight
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->xview('scroll',1,'page');
}

sub setSelectionMark
{
	my $w = shift;

	$w->{LINESTART}=0;
	$w->markSet('anchor','insert');
}

sub selectToMark
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->SelectTo('insert','char');
}

sub selectAll
{
	my $w = shift;

	$w->{LINESTART}=0;
	$Tk::selectionType='normal';
	$w->tag('add','sel','1.0','end');
}

sub selectionShiftLeft
{
	my $w = shift;
	
	$w->{LINESTART}=0;
	$w->_SelectionShift(" ","left");
}

sub selectionShiftLeftTab
{
	my $w = shift;
	
	$w->{LINESTART}=0;
	$w->_SelectionShift("\t","left");
}

sub selectionShiftRight
{
	my $w = shift;
	
	$w->{LINESTART}=0;
	$w->_SelectionShift(" ","right");
}

sub selectionShiftRightTab
{
	my $w = shift;
	
	$w->{LINESTART}=0;
	$w->_SelectionShift("\t","right");
}

sub _SelectionShift
{
	my ($w,$type,$dir) = @_;
	
	if((!defined $type) || (!defined $dir)) {return;}
	if(!defined $w->tag('ranges','sel')) {return;}
	
	my ($sline,$scol) = split('\.',$w->index('sel.first'));
	my ($eline,$ecol) = split('\.',$w->index('sel.last'));
	
	my $col;
	if($Tk::selectionType eq 'rect') {$col=$scol;}
	else {$col=0;}
	
	if($ecol == 0) {$eline--;}
	
	my $s;
	$w->_BeginUndoBlock;
	if($dir eq "left") {
		if($scol != 0) {$scol--;}
		$w->delete("$sline.$scol");
		for(my $i=$sline+1;$i <= $eline;$i++) {
			$s="$i.$scol";
			if($w->compare($s,'==',$w->index("$s lineend"))) {next;}
			$w->delete("$i.$scol");
			$w->idletasks;
		}
	} elsif($dir eq "right") {
		$w->insert("$sline.$scol",$type);
		for(my $i=$sline+1;$i <= $eline;$i++) {
#			$w->insert("$i.$scol",$type);
			$s="$i.$scol";
			$w->markSet('undopos' => $s);
			$w->SUPER::insert($s,$type);
			$w->_AddUndo('delete',$s,$w->index('undopos'));
			$w->idletasks;
		}
	}
	$w->_EndUndoBlock;
}

sub ins
{
	my $w = shift;

	$w->{LINESTART}=0;
	if($w->{INSERTMODE} eq 'insert') {$w->{INSERTMODE}='overwrite';}
	elsif($w->{INSERTMODE} eq 'overwrite') {$w->{INSERTMODE}='insert';}
}

sub enter
{
	my $w = shift;

	$w->_BeginUndoBlock;
	Tk::catch {$w->Insert("\n")};
	if($w->cget('-indentmode') eq 'auto') {
		$w->_AutoIndent;
	}
	$w->_EndUndoBlock;
}

sub autoIndentEnter
{
	my $w = shift;

	$w->_BeginUndoBlock;
	Tk::catch {$w->Insert("\n")};
	$w->_AutoIndent;
	$w->_EndUndoBlock;
}

sub noAutoIndentEnter
{
	my $w = shift;

	Tk::catch {$w->Insert("\n")};
}

sub _AutoIndent
{
	my $w = shift;
	my ($line,$col) = split('\.',$w->index('insert'));

	# no autoindent for first line
	if($line == 1) {return;}
	$line--;
	my $s=$w->get("$line.0","$line.end");
	if($s =~ /^(\s+)(\S*)/) {$s=$1;}
	else {$s='';}
	if($2) {
		$w->insert('insert linestart',$s);
	}
}

sub del
{
	my $w = shift;

	$w->Delete;
}

# overrides Tk::Text->Delete method
sub Delete
{
	my $w = shift;
	my $sel = Tk::catch {$w->tag('nextrange','sel','1.0','end');};
	
	if(defined $sel) {
		$w->deleteSelected;
	} else {
		$w->delete('insert');
		$w->see('insert');
	}
}

sub backSpace
{
	my $w = shift;

	$w->Backspace;
}

# overrides Tk::Text->Backspace method
sub Backspace
{
	my $w = shift;
	my $sel = Tk::catch {$w->tag('nextrange','sel','1.0','end');};
	
	if(defined $sel) {
		$w->deleteSelected;
	} elsif($w->compare('insert',"!=",'1.0')) {
		$w->delete('insert - 1c');
		$w->see('insert');
	}	
}

sub deleteToWordStart
{
	my $w = shift;
	
	if($w->compare('insert','==','insert wordstart')) {
		$w->delete('insert - 1c');
	} else {
		$w->delete('insert wordstart','insert');
	}
}

sub deleteToWordEnd
{
	my $w = shift;
	
	if($w->compare('insert','==','insert wordend')) {
		$w->delete('insert');
	} else {
		$w->delete('insert','insert wordend');
	}
}

sub deleteToLineStart
{
	my $w = shift;

	if($w->compare('insert','==','1.0')) {return;}
	if($w->compare('insert','==','insert linestart')) {
		$w->delete('insert - 1c');
	} else {
		$w->delete('insert linestart','insert');
	}
}

sub deleteToLineEnd
{
	my $w = shift;
	
	if($w->compare('insert','==','insert lineend')) {
		$w->delete('insert');
	} else {
		$w->delete('insert','insert lineend');
	}
}

sub deleteWord
{
	my $w = shift;

	$w->delete('insert wordstart','insert wordend');
}

sub deleteLine
{
	my $w = shift;

	$w->delete('insert linestart','insert lineend + 1c');
	$w->markSet('insert','insert linestart');
}

sub insertControlCode
{
	my $w = shift;
	
	$w->{LINESTART}=0;
	$w->{ASCIICODE} = 1;
}

#sub focusNext
#{
#	my $w = shift;
#
#	$w->focusNext;
#}
#
#sub focusPrev
#{
#	my $w = shift;
#
#	$w->focusPrev;
#}

# find a matching char for the given one
sub _FindMatchingChar
{
	my ($w,$sc,$pos,$slimit,$elimit) = @_;
	my $mc = ${$w->{MATCHINGCOUPLES}->{$sc}}[0];	# char to search
	
	if(!defined $mc) {return undef;}
	
	my $dir = ${$w->{MATCHINGCOUPLES}->{$sc}}[1];	# forward or backward search
	my $spos=($dir == 1 ? $w->index("$pos + $dir c") : $w->index($pos));
	my $d=1;
	my ($p,$c);
	my $match;

	if($dir == 1) {	# forward search
		$match="[\\$mc|\\$sc]+";
		for($p=$spos;$w->compare($p,'<',$elimit);$p=$w->index("$p + 1c")) {
			$p=$w->SUPER::search('-forwards','-regex','--',$match,$p,$elimit);
			if(!defined $p) {return undef;}
			$c=$w->get($p);
			if($c eq $mc) {
				$d--;
				if($d == 0) {
					return $p;
				}
			} elsif($c eq $sc) {
				$d++;
			}
			Tk::DoOneEvent(Tk::DONT_WAIT);
		}
	} else {	# backward search
		$match="[\\$sc|\\$mc]+";
		for($p=$spos;$w->compare($p,'>=',$slimit);) {
			$p=$w->SUPER::search('-backwards','-regex','--',$match,$p,$slimit);
			if(!defined $p) {return undef;}
			$c=$w->get($p);
			if($c eq $mc) {
				$d--;
				if($d == 0) {
					return $p;
				}
			} elsif($c eq $sc) {
				$d++;
			}
			if($w->compare($p,'==','1.0')) {return undef;}
			Tk::DoOneEvent(Tk::DONT_WAIT);
		}
	}
	return undef;
}

sub flashMatchingChar
{
	my $w = shift;
	my $s = $w->index('insert');
	my $str = $w->get('insert');
	
	if(exists $w->{MATCHINGCOUPLES}->{$str}) {
		my $i=$w->_FindMatchingChar($str,$s,"1.0","end");
		if(defined $i) {
			my $sel = Tk::catch {$w->tag('nextrange','match','1.0','end');};
			if(defined $sel) {$w->tag('remove','match','match.first');}
			$w->tag('add','match',$i,$w->index("$i + 1c"));
			my $t=$w->cget('-matchhighlighttime');
			if($t != 0) {$w->after($t,[\&removeMatch,$w,$i]);}
			return $i;
		}
	}
	return undef;
}

sub findMatchingChar
{
	my $w = shift;
	my $i = $w->flashMatchingChar;
	
	if(defined $i) {$w->see($i);}
}

sub jumpToMatchingChar
{
	my $w = shift;
	my $i = $w->flashMatchingChar;
	
	if(defined $i) {$w->SetCursor($i);}
}


sub escape
{
	my $w = shift;
	$w->tag('remove','sel','1.0','end');
}

sub tab
{
	my $w = shift;

	$w->Insert("\t");
	$w->focus;
	$w->break;
}

sub leftTab
{
}

sub copy
{
	my $w = shift;

	Tk::catch{$w->clipboardCopy;};
}

sub cut
{
	my $w = shift;

	Tk::catch{$w->clipboardCut;};
	$w->see('insert');
}

sub paste
{
	my $w = shift;

	Tk::catch{$w->clipboardPaste;};
	$w->see('insert');
}

sub inlinePaste
{
	my $w = shift;
	my ($l,$c) = split('\.',$w->index('insert'));
	my $str;
	my $f=0;
	Tk::catch{$str=$w->clipboardGet;};
	
	if($str eq "") {return;}
	$w->_BeginUndoBlock;
	while($str =~ /(.*)\n+/g) {
		$w->insert("$l.$c",$1);
		if($f == 0) {
			my ($el,$ec) = split('\.',$w->index('end'));
			if($l == $el) {
				$w->insert('end',"\n");
				$f=1;
			}
		} else {$w->insert('end',"\n");}
		$l++;
		$w->idletasks;
	}
	$w->_EndUndoBlock;
	$w->see('insert');
}

sub destroy
{
	my $w = shift;

	$w->Destroy;
}

sub keyPress
{
	my $w = shift;
	my $ev = $w->XEvent;

	$w->Insert($ev->A);
}

sub menuSelect
{
	my $w = shift;
	#NOTE: (JWT) ALSO FIXED IN auto/Tk/Text/SuperText/menuSelect.al!!!!!

#+20010117 JWT don't do these 2 lines in windows
	unless ($^O =~ /Win/)
	{
		my $ev = $w->XEvent;
	
		$w->TraverseToMenu($ev->K);
	}
#+
}

sub noOP
{
	my $w = shift;
	$w->NoOp;
}

1;
__END__

=pod

=head1 NAME

Tk::Text::SuperText - An improved text widget for Perl/Tk

=head1 SYNOPSIS

I<$super_text> = I<$paren>-E<gt>B<SuperText>(?I<options>?);

=head1 STANDARD OPTIONS

B<-background>	B<-highlightbackground>	B<-insertontime>	B<-selectborderwidth>
B<-borderwidth>	B<-highlightcolor>	B<-insertwidth>	B<-selectforeground>
B<-cursor>	B<-highlightthickness>	B<-padx>	B<-setgrid>
B<-exportselection>	B<-insertbackground>	B<-pady>	B<-takefocus>
B<-font>	B<-insertborderwidth>	B<-relief>	B<-xscrollcommand>
B<-foreground>	B<-insertofftime>	B<-selectbackground>	B<-yscrollcommand>
B<-ansicolor>

See L<Tk::options> for details of the standard options.

B<-height>	B<-spacing1>	B<-spacing2>	B<-spacing3>
B<-state>	B<-tabs>	B<-width>	B<-wrap>

See L<Tk::Text> for details of theis options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:	B<indentMode>

=item Class:	B<IndentMode>

=item Switch:	B<-indentmode>

Specifies how to indent when a new line is inserted in the text.
The possible modes are B<none> for no indent at all or B<auto> for positioning
the insertion cursor right below the first non-white space character of the previous line.

=item Name:	B<undoDepth>

=item Class:	B<UndoDepth>

=item Switch:	B<-undodepth>

Sets the maximum depth for the undo buffer:a number specifies the numbers of 
insert or delete operations that can be stored in the buffer before the oldest one is
poped out and forgotten;B<0> stops the undo feature,B<undef> sets unlimited
depth.

=item Name:	B<redoDepth>

=item Class:	B<RedoDepth>

=item Switch:	B<-redodepth>

Sets the maximum depth for the redo buffer:a number specifies the numbers of 
undo operations that can be stored in the buffer before the oldest one is poped
out and forgotten;B<0> stops the redo feature,B<undef> sets unlimited depth.

=item Name:	B<showMatching>

=item Class:	B<ShowMatching>

=item Switch:	B<-showmatching>

With a value of B<1> activates the matching parentheses feature.B<0> deactivates it.

=item Name:	B<matchHighlightTime>

=item Class:	B<MatchHighlightTime>

=item Switch:	B<-matchhighlighttime>

Sets the number of milliseconds the match highlight stays visible; with a value of B<0> the highlight stays on till next match.

=item Name:	B<matchForeground>

=item Class:	B<MatchForeground>

=item Switch:	B<-matchforeground>

Set the foreground color for the char hilighted by the match-parentheses command.

=item Name:	B<matchBackground>

=item Class:	B<MatchBackground>

=item Switch:	B<-matchbackground>

Set the background color for the char hilighted by the match-parentheses command.

=item Name:	B<matchingCouples>

=item Class:	B<MatchingCouples>

=item Switch:	B<-matchingcouples>

Sets the chars that are searched for a matching counterpart.
The format is a simple string with matching chars coupled in left-right order;
here's an example: I<{}[]()""> .
For double couples (I<"">) the match is done only on the forwarding chars.

=item Name:	B<insertMode>

=item Class:	B<InsertMode>

=item Switch:	B<-insertmode>

Sets the default insert mode: B<insert> or B<overwrite> .

=item Name:	B<ansiColor>

=item Class:	B<AnsiColor>

=item Switch:	B<-ansicolor>

Enables or disables use of Tk-TextANSIColor module (by Tim Jenness <t.jenness@jach.hawaii.edu>).
This option was implemented by Jim Turner <turnerjw2@netscape.net> (THANKS for the support!)

=back

=head1 DESCRIPTION

B<Tk::Text::SuperText> implements many new features over the 
standard L<Tk::Text> widget while supporting all it's standard 
features.Its used simply as the L<Tk::Text> widget.
New Features:

=over 4

=item * Unlimited undo/redo.

So you can undo and redo whatever you deleted/inserted whenever you want.
To reset the undo and redo buffers call this method:
I<$w>-E<gt>B<resetUndo>;

=item * Rectangular selections.

Rectangular text zones can be selected, copied, deleted, shifted with the mouse
or with the keyboard.

=item * Selection right/left char and tab shift.

Text selections can be shifted left/right of  one or more chars or a tabs.

=item * Normal and 'inline' selection paste.

The 'normal' paste is the normal text paste you know :

=over 4

=item Paste Buffer:

line x

line y

=back

=over 4

=item Text Buffer:

line 1

line2

=back


=over 4

=item Normal paste at line 1:

I<line x>

I<line y>

line 1

line 2

=back

=over 4

=item The 'inline' paste work as this:

=item Inline paste at line 1:

I<line x> line 1

I<line y> line 2

=back

=item * Parentheses matching.

To help you inspect nested parentheses, brackets and other characters, B<SuperText>
has both an automatic parenthesis matching mode, and a find matching command.
Automatic parenthesis matching is activated when you type or when you move the
insertion cursor after a parenthesis.
It momentarily highlightsthe matching character if that character is visible in the window.
To find a matching character anywhere in the file, position the cursor after the it,
and call the find matching command.

=item * Autoindenting.

When you press the Return or Enter key, spaces and tabs are inserted to line up the
insert point under the start of the previous line.

=item * Control codes insertion.

You can directly insert a non printable control character in the text.

=item * Commands are managed via virtual events.

Every B<SuperText> command is binded to a virtual event,so to call it or to bind it
to a key sequence use the L<Tk::event> functions.
I used this format for key bind so there's no direct key-to-command bind, and this
give me more flexibility; however you can use normal binds.

Example: I<$w>-E<gt>B<eventAdd>(I<'Tk::Text::SuperText','E<lt>E<lt>SelectAllE<gt>E<gt>','E<lt>Control-aE<gt>'>);

To set default events bindigs use this methos:
I<$w>-E<gt>B<bindDefault>;

=item * Default key bindings are redefined (not really a feature :).

Every virtual event has an associated public method with the same name of the event but with the firts
char in lower case (eg: B<E<lt>E<lt>MouseSelectE<gt>E<gt>> event has a corresponding  I<$super_text>-E<gt>B<mouseSelect> method).

Virtual Event/Command		Default Key Binding

B<MouseSetInsert>			B<E<lt>Button1E<gt>>
B<MouseSelect>			B<E<lt>B1-MotionE<gt>>
B<MouseSelectWord>		B<E<lt>Double-1E<gt>>
B<MouseSelectLine>		B<E<lt>Triple-1E<gt>>
B<MouseSelectAdd>			B<E<lt>Shift-1E<gt>>
B<MouseSelectAddWord>		B<E<lt>Double-Shift-1E<gt>>
B<MouseSelectAddLine>		B<E<lt>Triple-Shift-1E<gt>>
B<MouseSelectAutoScan>		B<E<lt>B1-LeaveE<gt>>
B<MouseSelectAutoScanStop>	B<E<lt>B1-EnterE<gt>>,B<E<lt>ButtonRelease-1E<gt>>
B<MouseMoveInsert>		B<E<lt>Alt-1E<gt>>
B<MouseRectSelection>		B<E<lt>Control-B1-MotionE<gt>>
B<MouseMovePageTo>		B<E<lt>2E<gt>>
B<MouseMovePage>			B<E<lt>B2-MotionE<gt>>
B<MousePasteSelection>		B<E<lt>ButtonRelease-2E<gt>>

B<MoveLeft>				B<E<lt>LeftE<gt>>
B<SelectLeft>			B<E<lt>Shift-LeftE<gt>>
B<SelectRectLeft>			B<E<lt>Shift-Alt-LeftE<gt>>
B<MoveLeftWord>			B<E<lt>Control-LeftE<gt>>
B<SelectLeftWord>			B<E<lt>Shift-Control-LeftE<gt>>
B<MoveRight>				B<E<lt>RightE<gt>>
B<SelectRight>			B<E<lt>Shift-RightE<gt>>
B<SelectRectRight>		B<E<lt>Shift-Alt-RightE<gt>>
B<MoveRightWord>			B<E<lt>Control-RightE<gt>>
B<SelectRightWord>		B<E<lt>Shift-Control-RightE<gt>>
B<MoveUp>				B<E<lt>UpE<gt>>
B<SelectUp>				B<E<lt>Shift-UpE<gt>>
B<SelectRectUp>			B<E<lt>Shift-Alt-UpE<gt>>
B<MoveUpParagraph>		B<E<lt>Control-UpE<gt>>
B<SelectUpParagraph>		B<E<lt>Shift-Control-UpE<gt>>
B<MoveDown>				B<E<lt>DownE<gt>>
B<SelectDown>			B<E<lt>Shift-DownE<gt>>
B<SelectRectDown>			B<E<lt>Shift-Alt-DownE<gt>>
B<MoveDownParagraph>		B<E<lt>Control-DownE<gt>>
B<SelectDownParagraph>		B<E<lt>Shift-Control-DownE<gt>>
B<MoveLineStart>			B<E<lt>HomeE<gt>>
B<SelectToLineStart>		B<E<lt>Shift-HomeE<gt>>
B<MoveTextStart>			B<E<lt>Control-HomeE<gt>>
B<SelectToTextStart>		B<E<lt>Shift-Control-HomeE<gt>>
B<MoveLineEnd>			B<E<lt>EndE<gt>>
B<SelectToLineEnd>		B<E<lt>Shift-EndE<gt>>
B<MoveTextEnd>			B<E<lt>Control-EndE<gt>>
B<SelectToTextEnd>		B<E<lt>Shift-Control-EndE<gt>>
B<MovePageUp>			B<E<lt>PriorE<gt>>
B<SelectToPageUp>			B<E<lt>Shift-PriorE<gt>>
B<MovePageLeft>			B<E<lt>Control-PriorE<gt>>
B<MovePageDown>			B<E<lt>NextE<gt>>
B<SelectToPageDown>		B<E<lt>Shift-NextE<gt>>
B<MovePageRight>			B<E<lt>Control-NextE<gt>>
B<SetSelectionMark>		B<E<lt>Control-spaceE<gt>>,B<E<lt>SelectE<gt>>
B<SelectToMark>			B<E<lt>Shift-Control-spaceE<gt>>,B<E<lt>Shift-SelectE<gt>>

B<SelectAll>				B<E<lt>Control-aE<gt>>
B<SelectionShiftLeft>		B<E<lt>Control-commaE<gt>>
B<SelectionShiftLeftTab>	B<E<lt>Control-Alt-commaE<gt>>
B<SelectionShiftRight>		B<E<lt>Control-periodE<gt>>
B<SelectionShiftRightTab>	B<E<lt>Control-Alt-periodE<gt>>

B<Ins>					B<E<lt>InsertE<gt>>
B<Enter>				B<E<lt>ReturnE<gt>>
B<AutoIndentEnter>		B<E<lt>Control-ReturnE<gt>>
B<NoAutoindentEnter>		B<E<lt>Shift-ReturnE<gt>>
B<Del>					B<E<lt>DeleteE<gt>>
B<BackSpace>				B<E<lt>BackSpaceE<gt>>
B<DeleteToWordStart>		B<E<lt>Shift-BackSpaceE<gt>>
B<DeleteToWordEnd>		B<E<lt>Shift-DeleteE<gt>>
B<DeleteToLineStart>		B<E<lt>Alt-BackSpaceE<gt>>
B<DeleteToLineEnd>		B<E<lt>Alt-DeleteE<gt>>
B<DeleteWord>			B<E<lt>Control-BackSpaceE<gt>>
B<DeleteLine>			B<E<lt>Control-DeleteE<gt>>

B<InsertControlCode>		B<E<lt>Control-EscapeE<gt>>

B<FocusNext>				B<E<lt>Control-TabE<gt>>
B<FocusPrev>				B<E<lt>Shift-Control-TabE<gt>>

B<FlashMatchingChar>		B<E<lt>Control-bE<gt>>
B<RemoveMatch>			B<E<lt>Control-BE<gt>>
B<FindMatchingChar>		B<E<lt>Control-jE<gt>>
B<JumpToMatchingChar>		B<E<lt>Control-JE<gt>>

B<Escape>				B<E<lt>EscapeE<gt>>

B<Tab> 					B<E<lt>TabE<gt>>

B<LeftTab> 				B<E<lt>Shift-TabE<gt>>

B<Copy> 				B<E<lt>Control-cE<gt>>

B<Cut> 					B<E<lt>Control-xE<gt>>

B<Paste> 				B<E<lt>Control-vE<gt>>

B<InlinePaste> 			B<E<lt>Control-VE<gt>>

B<Undo> 				B<E<lt>Control-zE<gt>>

B<Redo>					B<E<lt>Control-ZE<gt>>

B<Destroy>				B<E<lt>DestroyE<gt>>

B<MenuSelect>			B<E<lt>Alt-KeyPressE<gt>>

=item * Public methods.

I<$widget>-E<gt>B<mouseSetInsert>

I<$widget>-E<gt>B<museSelect>			

I<$widget>-E<gt>B<mouseSelectWord>		

I<$widget>-E<gt>B<mouseSelectLine>		

I<$widget>-E<gt>B<mouseSelectAdd>	

I<$widget>-E<gt>B<mouseSelectAddWord>	

I<$widget>-E<gt>B<mouseSelectAddLine>

I<$widget>-E<gt>B<mouseSelectAutoScan>

I<$widget>-E<gt>B<mouseSelectAutoScanStop>

I<$widget>-E<gt>B<mouseMoveInsert>

I<$widget>-E<gt>B<mouseRectSelection>	

I<$widget>-E<gt>B<mouseMovePageTo>

I<$widget>-E<gt>B<mouseMovePage>

I<$widget>-E<gt>B<mousePasteSelection>	

I<$widget>-E<gt>B<moveLeft>

I<$widget>-E<gt>B<selectLeft>	

I<$widget>-E<gt>B<selectRectLeft>		

I<$widget>-E<gt>B<moveLeftWord>	

I<$widget>-E<gt>B<selectLeftWord>

I<$widget>-E<gt>B<moveRight>

I<$widget>-E<gt>B<selectRight>

I<$widget>-E<gt>B<selectRectRight>	

I<$widget>-E<gt>B<moveRightWord>

I<$widget>-E<gt>B<selectRightWord>

I<$widget>-E<gt>B<moveUp>	

I<$widget>-E<gt>B<selectUp>			

I<$widget>-E<gt>B<selectRectUp>			

I<$widget>-E<gt>B<moveUpParagraph>

I<$widget>-E<gt>B<selectUpParagraph>

I<$widget>-E<gt>B<moveDown>

I<$widget>-E<gt>B<selectDown>		

I<$widget>-E<gt>B<selectRectDown>		

I<$widget>-E<gt>B<moveDownParagraph>

I<$widget>-E<gt>B<selectDownParagraph>

I<$widget>-E<gt>B<moveLineStart>

I<$widget>-E<gt>B<selectToLineStart>	

I<$widget>-E<gt>B<moveTextStart>	

I<$widget>-E<gt>B<selectToTextStart>	

I<$widget>-E<gt>B<moveLineEnd>	

I<$widget>-E<gt>B<selectToLineEnd>	

I<$widget>-E<gt>B<moveTextEnd>	

I<$widget>-E<gt>B<selectToTextEnd>	

I<$widget>-E<gt>B<movePageUp>	

I<$widget>-E<gt>B<selectToPageUp>		

I<$widget>-E<gt>B<movePageLeft>	

I<$widget>-E<gt>B<movePageDown>

I<$widget>-E<gt>B<selectToPageDown>	

I<$widget>-E<gt>B<movePageRight>	

I<$widget>-E<gt>B<setSelectionMark>	

I<$widget>-E<gt>B<selectToMark>	

I<$widget>-E<gt>B<selectAll>

I<$widget>-E<gt>B<selectionShiftLeft>

I<$widget>-E<gt>B<selectionShiftLeftTab>

I<$widget>-E<gt>B<selectionShiftRight>

I<$widget>-E<gt>B<selectionShiftRightTab>	

I<$widget>-E<gt>B<ins>

I<$widget>-E<gt>B<enter>			

I<$widget>-E<gt>B<autoIndentEnter>

I<$widget>-E<gt> B<noAutoindentEnter>	

I<$widget>-E<gt>B<del>

I<$widget>-E<gt>B<backSpace>

I<$widget>-E<gt>B<deleteToWordStart>

I<$widget>-E<gt>B<deleteToWordEnd>	

I<$widget>-E<gt>B<deleteToLineStart>	

I<$widget>-E<gt>B<deleteToLineEnd>	

I<$widget>-E<gt>B<deleteWord>	

I<$widget>-E<gt>B<deleteLine>	

I<$widget>-E<gt>B<insertControlCode>

I<$widget>-E<gt>B<focusNext>

I<$widget>-E<gt>B<focusPrev>		

I<$widget>-E<gt>B<flashMatchingChar>

I<$widget>-E<gt>B<removeMatch>

I<$widget>-E<gt>B<findMatchingChar>		

I<$widget>-E<gt>B<jumpToMatchingChar>

I<$widget>-E<gt>B<escape>

I<$widget>-E<gt>B<tab>

I<$widget>-E<gt>B<leftTab>

I<$widget>-E<gt>B<copy>

I<$widget>-E<gt>B<cut>

I<$widget>-E<gt>B<paste>

I<$widget>-E<gt>B<inlinePaste>

I<$widget>-E<gt>B<undo>

I<$widget>-E<gt>B<redo>

I<$widget>-E<gt>B<destroy>

I<$widget>-E<gt>B<menuSelect>

=back

=head1 AUTHOR

Current maintainer is Alexander Becker, L<c a p f a n -at- g m x %dot% d e>.

Originally written by Alessandro Iob.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 SEE ALSO

L<Tk::Text|Tk::Text>
L<Tk::ROText|Tk::ROText>
L<Tk::TextUndo|Tk::TextUndo>

=head1 KEYWORDS

text, widget

=cut
