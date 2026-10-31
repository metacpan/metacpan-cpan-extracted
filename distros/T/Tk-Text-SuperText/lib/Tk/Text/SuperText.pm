package Tk::Text::SuperText;

use Exporter ();
use Tk 804.030 qw(Ev);
use Tk::Text;
use Tk::Derived;


#+20010117 JWT TextANSIColor support
my $ansicolor = 0;
eval 'use Term::ANSIColor; 1' or $ansicolor = -1;
#+

use Carp;
use strict;
use warnings;
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

$VERSION = '0.13';
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
		'-readonly'           => ['METHOD','readOnly','ReadOnly',0],
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

# Read-only affects editing commands, not application insert/delete calls.
sub readonly
{
	my ($w,$val) = @_;
	return $w->{READONLY} || 0 unless @_ > 1;
	$w->{READONLY} = $val ? 1 : 0;
	delete $w->{ASCIICODE} if $w->{READONLY};
	return $w->{READONLY};
}

# Tk::Text uses Insert for interactive insertion (including replacement of sel).
sub Insert
{
	my $w = shift;
	return if $w->cget('-readonly');
	return $w->SUPER::Insert(@_);
}

# Also protect the inherited edit menu and search/replace dialog.
sub ReplaceSelectionsWith
{
	my $w = shift;
	return if $w->cget('-readonly');
	return $w->SUPER::ReplaceSelectionsWith(@_);
}

sub clipboardCut
{
	my $w = shift;
	return if $w->cget('-readonly');
	return $w->SUPER::clipboardCut(@_);
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
	return if $w->cget('-readonly');
	
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
    
	$w->SUPER::Button1(@_);
	
	if((!defined $w->tag('ranges','sel')) && $w->cget('-showmatching') == 1) {
        my $str = $w->get('insert', 'insert + 1c');
		if(defined $str && exists $w->{MATCHINGCOUPLES}->{$str}) {
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
	return 0 if $w->cget('-readonly');
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
	return 0 if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
	
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
	return if $w->cget('-readonly');

	$w->{LINESTART}=0;
	if($w->{INSERTMODE} eq 'insert') {$w->{INSERTMODE}='overwrite';}
	elsif($w->{INSERTMODE} eq 'overwrite') {$w->{INSERTMODE}='insert';}
}

sub enter
{
	my $w = shift;
	return if $w->cget('-readonly');

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
	return if $w->cget('-readonly');

	$w->_BeginUndoBlock;
	Tk::catch {$w->Insert("\n")};
	$w->_AutoIndent;
	$w->_EndUndoBlock;
}

sub noAutoIndentEnter
{
	my $w = shift;
	return if $w->cget('-readonly');

	Tk::catch {$w->Insert("\n")};
}

sub _AutoIndent
{
	my $w = shift;
	return if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
	
	if($w->compare('insert','==','insert wordstart')) {
		$w->delete('insert - 1c');
	} else {
		$w->delete('insert wordstart','insert');
	}
}

sub deleteToWordEnd
{
	my $w = shift;
	return if $w->cget('-readonly');
	
	if($w->compare('insert','==','insert wordend')) {
		$w->delete('insert');
	} else {
		$w->delete('insert','insert wordend');
	}
}

sub deleteToLineStart
{
	my $w = shift;
	return if $w->cget('-readonly');

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
	return if $w->cget('-readonly');
	
	if($w->compare('insert','==','insert lineend')) {
		$w->delete('insert');
	} else {
		$w->delete('insert','insert lineend');
	}
}

sub deleteWord
{
	my $w = shift;
	return if $w->cget('-readonly');

	$w->delete('insert wordstart','insert wordend');
}

sub deleteLine
{
	my $w = shift;
	return if $w->cget('-readonly');

	$w->delete('insert linestart','insert lineend + 1c');
	$w->markSet('insert','insert linestart');
}

sub insertControlCode
{
	my $w = shift;
	return if $w->cget('-readonly');
	
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
	return if $w->cget('-readonly');

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
	return if $w->cget('-readonly');

	Tk::catch{$w->clipboardCut;};
	$w->see('insert');
}

sub paste
{
	my $w = shift;
	return if $w->cget('-readonly');

	Tk::catch{$w->clipboardPaste;};
	$w->see('insert');
}

sub inlinePaste
{
	my $w = shift;
	return if $w->cget('-readonly');
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
	return if $w->cget('-readonly');
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

    use Tk;
    use Tk::Text::SuperText;

    my $mw = MainWindow->new;
    my $super_text = $mw->SuperText(
        -wrap       => 'none',
        -indentmode => 'auto',
        -readonly   => 0,
    )->pack(-fill => 'both', -expand => 1);

    MainLoop;

=head1 STANDARD OPTIONS

B<-background>	B<-highlightbackground>	B<-insertontime>	B<-selectborderwidth>
B<-borderwidth>	B<-highlightcolor>	B<-insertwidth>	B<-selectforeground>
B<-cursor>	B<-highlightthickness>	B<-padx>	B<-setgrid>
B<-exportselection>	B<-insertbackground>	B<-pady>	B<-takefocus>
B<-font>	B<-insertborderwidth>	B<-relief>	B<-xscrollcommand>
B<-foreground>	B<-insertofftime>	B<-selectbackground>	B<-yscrollcommand>

See L<Tk::options> for details of the standard options.

B<-height>	B<-spacing1>	B<-spacing2>	B<-spacing3>
B<-state>	B<-tabs>	B<-width>	B<-wrap>

See L<Tk::Text> for details of these options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<readOnly>

=item Class: B<ReadOnly>

=item Switch: B<-readonly>

Defaults to B<0>. When true, prevents interactive edits, including cut, paste,
rectangular selection shifts, and undo/redo. Navigation, selection, copying,
and matching-pair commands remain available. The option can be changed at
runtime with C<$w-E<gt>configure(-readonly =E<gt> 1)> or the
C<$w-E<gt>readonly(1)> method; C<$w-E<gt>readonly> returns the current value.

Application calls to C<insert> and C<delete> remain available, allowing the
displayed content to be updated while read-only. Unlike C<-state =E<gt> 'disabled'>,
this option only blocks editing commands. Toggling it does not clear the content,
selection, or undo/redo history. Programmatic edits retain normal undo behavior;
call C<resetUndo> after replacing content if its old history is no longer needed.

=item Name:	B<indentMode>

=item Class:	B<IndentMode>

=item Switch:	B<-indentmode>

Specifies how to indent when a new line is inserted in the text.
The possible modes are B<none> for no indentation or B<auto> for positioning
the insertion cursor directly below the first non-whitespace character of the
previous line.

=item Name:	B<undoDepth>

=item Class:	B<UndoDepth>

=item Switch:	B<-undodepth>

Sets the maximum depth of the undo buffer. A positive number specifies how many
insert or delete operations can be stored before the oldest one is discarded.
B<0> disables undo; C<undef> allows unlimited depth.

=item Name:	B<redoDepth>

=item Class:	B<RedoDepth>

=item Switch:	B<-redodepth>

Sets the maximum depth of the redo buffer. A positive number specifies how many
undo operations can be stored before the oldest one is discarded.
B<0> disables redo; C<undef> allows unlimited depth.

=item Name:	B<showMatching>

=item Class:	B<ShowMatching>

=item Switch:	B<-showmatching>

A value of B<1> enables automatic matching-pair highlighting; B<0> disables it.

=item Name:	B<matchHighlightTime>

=item Class:	B<MatchHighlightTime>

=item Switch:	B<-matchhighlighttime>

Sets the number of milliseconds that a matching character remains highlighted.
With a value of B<0>, the highlight remains until it is cleared or replaced by
another match.

=item Name:	B<matchForeground>

=item Class:	B<MatchForeground>

=item Switch:	B<-matchforeground>

Sets the foreground color of the character highlighted by a matching-pair command.

=item Name:	B<matchBackground>

=item Class:	B<MatchBackground>

=item Switch:	B<-matchbackground>

Sets the background color of the character highlighted by a matching-pair command.

=item Name:	B<matchingCouples>

=item Class:	B<MatchingCouples>

=item Switch:	B<-matchingcouples>

Specifies the characters for which matching counterparts are searched.
The value is a string of character pairs, with each pair in opening-closing
order, for example C<{}[]()"">.
When both characters in a pair are identical, as in C<"">, matching searches
only forward.

=item Name:	B<insertMode>

=item Class:	B<InsertMode>

=item Switch:	B<-insertmode>

Sets the insertion mode to B<insert> or B<overwrite>.

=item Name:	B<ansiColor>

=item Class:	B<AnsiColor>

=item Switch:	B<-ansicolor>

Enables or disables interpretation of ANSI color codes in inserted text.
This feature requires L<Term::ANSIColor> and was adapted from
L<Tk::TextANSIColor> by Jim Turner. Thank you for the contribution!

=back

=head1 DESCRIPTION

B<Tk::Text::SuperText> extends the standard L<Tk::Text> widget with additional
editing features. It can be used in the same way as L<Tk::Text>.
Its additional features include:

=over 4

=item * Unlimited undo/redo.

Insertions and deletions can be undone and redone. The history is unlimited
unless C<-undodepth> or C<-redodepth> sets a limit.
To clear both history buffers, call:

    $w->resetUndo;

=item * Rectangular selections.

Rectangular text regions can be selected with the mouse or keyboard, then
copied, deleted, or shifted.

=item * Shifting selections left or right.

Text selections can be shifted left or right by a character or a tab.

=item * Normal and inline paste.

For example, suppose the clipboard contains these two lines, each ending with
a newline:

    line x
    line y

The text buffer contains:

    line 1
    line 2

Normal paste at the start of line 1 inserts the clipboard contents together:

    line x
    line y
    line 1
    line 2

Inline paste inserts each clipboard line at the same column on successive
lines of the text buffer. At the start of line 1, the result is:

    line xline 1
    line yline 2

Include trailing spaces in the clipboard text if a separator is needed.

=item * Parentheses matching.

To help you inspect nested parentheses, brackets, and other characters, B<SuperText>
provides both automatic matching-pair highlighting and explicit matching commands.
Automatic parenthesis matching is activated when you type or when you move the
insertion cursor onto a parenthesis.
It momentarily highlights the matching character if that character is visible in the window.
To find a matching character anywhere in the buffer, position the cursor on a
delimiter and call C<findMatchingChar>. Use C<jumpToMatchingChar> to move the
cursor to its counterpart.

=item * Auto-indenting.

When you press the Return or Enter key, spaces and tabs are inserted to line up the
insertion point with the first non-whitespace character of the previous line.

=item * Inserting control codes.

You can directly insert a non-printable control character in the text.

=item * Commands are managed via virtual events.

Editing and navigation commands are bound to virtual events. Use the
L<Tk::event> methods to generate these events or associate them with key
sequences. Ordinary bindings can also be used.

For example:

    $w->eventAdd('<<SelectAll>>', '<Control-a>');
    $w->eventGenerate('<<SelectAll>>');

To restore the default event bindings, call:

    $w->bindDefault;

=item * Redefined default key bindings.

Each virtual event has an associated public method with the same name, but
with its first character in lowercase. For example, C<<< <<MouseSelect>> >>>
corresponds to C<$super_text-E<gt>mouseSelect>.

    Virtual Event/Command     Default Key Binding

    MouseSetInsert            <Button-1>
    MouseSelect               <B1-Motion>
    MouseSelectWord           <Double-1>
    MouseSelectLine           <Triple-1>
    MouseSelectAdd            <Shift-1>
    MouseSelectAddWord        <Double-Shift-1>
    MouseSelectAddLine        <Triple-Shift-1>
    MouseSelectAutoScan       <B1-Leave>
    MouseSelectAutoScanStop   <B1-Enter>,<ButtonRelease-1>
    MouseMoveInsert           <Alt-1>
    MouseRectSelection        <Control-B1-Motion>
    MouseMovePageTo           <2>
    MouseMovePage             <B2-Motion>
    MousePasteSelection       <ButtonRelease-2>

    MoveLeft                  <Left>
    SelectLeft                <Shift-Left>
    SelectRectLeft            <Shift-Alt-Left>
    MoveLeftWord              <Control-Left>
    SelectLeftWord            <Shift-Control-Left>
    MoveRight                 <Right>
    SelectRight               <Shift-Right>
    SelectRectRight           <Shift-Alt-Right>
    MoveRightWord             <Control-Right>
    SelectRightWord           <Shift-Control-Right>
    MoveUp                    <Up>
    SelectUp                  <Shift-Up>
    SelectRectUp              <Shift-Alt-Up>
    MoveUpParagraph           <Control-Up>
    SelectUpParagraph         <Shift-Control-Up>
    MoveDown                  <Down>
    SelectDown                <Shift-Down>
    SelectRectDown            <Shift-Alt-Down>
    MoveDownParagraph         <Control-Down>
    SelectDownParagraph       <Shift-Control-Down>
    MoveLineStart             <Home>
    SelectToLineStart         <Shift-Home>
    MoveTextStart             <Control-Home>
    SelectToTextStart         <Shift-Control-Home>
    MoveLineEnd               <End>
    SelectToLineEnd           <Shift-End>
    MoveTextEnd               <Control-End>
    SelectToTextEnd           <Shift-Control-End>
    MovePageUp                <Prior>
    SelectToPageUp            <Shift-Prior>
    MovePageLeft              <Control-Prior>
    MovePageDown              <Next>
    SelectToPageDown          <Shift-Next>
    MovePageRight             <Control-Next>
    SetSelectionMark          <Control-space>,<Select>
    SelectToMark              <Shift-Control-space>,<Shift-Select>

    SelectAll                 <Control-a>
    SelectionShiftLeft        <Control-comma>
    SelectionShiftLeftTab     <Control-Alt-comma>
    SelectionShiftRight       <Control-period>
    SelectionShiftRightTab    <Control-Alt-period>

    Ins                       <Insert>
    Enter                     <Return>
    AutoIndentEnter           <Control-Return>
    NoAutoIndentEnter         <Shift-Return>
    Del                       <Delete>
    Backspace                 <BackSpace>
    DeleteToWordStart         <Shift-BackSpace>
    DeleteToWordEnd           <Shift-Delete>
    DeleteToLineStart         <Alt-BackSpace>
    DeleteToLineEnd           <Alt-Delete>
    DeleteWord                <Control-BackSpace>
    DeleteLine                <Control-Delete>

    InsertControlCode         <Control-Escape>

    FocusNext                 <Control-Tab>
    FocusPrev                 <Shift-Control-Tab>

    FlashMatchingChar         <Control-b>
    RemoveMatch               <Control-B>
    FindMatchingChar          <Control-j>
    JumpToMatchingChar        <Control-p>

    Escape                    <Escape>

    Tab                       <Tab>

    LeftTab                   <Shift-Tab>

    Copy                      <Control-c>

    Cut                       <Control-x>

    Paste                     <Control-v>

    InlinePaste               <Control-V>

    Undo                      <Control-z>

    Redo                      <Control-Z>

    Destroy                   <Destroy>

    MenuSelect                <Alt-KeyPress>

=back

=head1 METHODS

The following editing and navigation methods correspond to the virtual events
listed above:

    $widget->mouseSetInsert;
    $widget->mouseSelect;
    $widget->mouseSelectWord;
    $widget->mouseSelectLine;
    $widget->mouseSelectAdd;
    $widget->mouseSelectAddWord;
    $widget->mouseSelectAddLine;
    $widget->mouseSelectAutoScan;
    $widget->mouseSelectAutoScanStop;
    $widget->mouseMoveInsert;
    $widget->mouseRectSelection;
    $widget->mouseMovePageTo;
    $widget->mouseMovePage;
    $widget->mousePasteSelection;
    $widget->moveLeft;
    $widget->selectLeft;
    $widget->selectRectLeft;
    $widget->moveLeftWord;
    $widget->selectLeftWord;
    $widget->moveRight;
    $widget->selectRight;
    $widget->selectRectRight;
    $widget->moveRightWord;
    $widget->selectRightWord;
    $widget->moveUp;
    $widget->selectUp;
    $widget->selectRectUp;
    $widget->moveUpParagraph;
    $widget->selectUpParagraph;
    $widget->moveDown;
    $widget->selectDown;
    $widget->selectRectDown;
    $widget->moveDownParagraph;
    $widget->selectDownParagraph;
    $widget->moveLineStart;
    $widget->selectToLineStart;
    $widget->moveTextStart;
    $widget->selectToTextStart;
    $widget->moveLineEnd;
    $widget->selectToLineEnd;
    $widget->moveTextEnd;
    $widget->selectToTextEnd;
    $widget->movePageUp;
    $widget->selectToPageUp;
    $widget->movePageLeft;
    $widget->movePageDown;
    $widget->selectToPageDown;
    $widget->movePageRight;
    $widget->setSelectionMark;
    $widget->selectToMark;
    $widget->selectAll;
    $widget->selectionShiftLeft;
    $widget->selectionShiftLeftTab;
    $widget->selectionShiftRight;
    $widget->selectionShiftRightTab;
    $widget->ins;
    $widget->enter;
    $widget->autoIndentEnter;
    $widget->noAutoIndentEnter;
    $widget->del;
    $widget->backSpace;
    $widget->deleteToWordStart;
    $widget->deleteToWordEnd;
    $widget->deleteToLineStart;
    $widget->deleteToLineEnd;
    $widget->deleteWord;
    $widget->deleteLine;
    $widget->insertControlCode;
    $widget->focusNext;
    $widget->focusPrev;
    $widget->flashMatchingChar;
    $widget->removeMatch;
    $widget->findMatchingChar;
    $widget->jumpToMatchingChar;
    $widget->escape;
    $widget->tab;
    $widget->leftTab;
    $widget->copy;
    $widget->cut;
    $widget->paste;
    $widget->inlinePaste;
    $widget->undo;
    $widget->redo;
    $widget->destroy;
    $widget->menuSelect;

=head2 readonly

C<$widget-E<gt>readonly> returns whether interactive editing is blocked.
C<$widget-E<gt>readonly($boolean)> sets the mode, just like configuring
C<-readonly>, and returns the new value. Each widget has its own mode.

=head2 paste

C<$widget-E<gt>paste> inserts the clipboard contents at the insertion cursor
using normal paste behavior. Use C<inlinePaste> to insert successive clipboard
lines at the same column on successive buffer lines. Both commands are blocked
when C<-readonly> is true.

=head2 tab

C<$widget-E<gt>tab> inserts a tab at the insertion cursor and keeps keyboard
focus in the widget. This command is blocked when C<-readonly> is true.

=head1 AUTHOR

The current maintainer is Alexander Becker, L<asb@cpan.org|mailto:asb@cpan.org>.

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
