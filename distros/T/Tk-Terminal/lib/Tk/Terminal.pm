package Tk::Terminal;

=head1 NAME

Tk::Terminal - Running system commands in a Tk::Text widget.

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.01';

use Cwd;
use Fcntl;
use File::Basename;
use POSIX ":sys_wait_h";
use IPC::Open3;
use IO::Handle;
#use IO::Pty;
use Term::ANSIColor;
use Tk;
require Tk::Clipboard;

#boilerplating
my $sep = '/';
my $qsep = quotemeta($sep);
my $root = qr/^\//;

use base qw(Tk::Derived Tk::TextANSIColor);
Construct Tk::Widget 'Terminal';

=head1 SYNOPSIS

 require Tk::Terminal;
 my $text= $window->Terminal(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::TextANSIColor>.

This module works as a modest command shell. You can enter a command and go into dialog with
the program you are running, if the program does not buffer it's output.

It is in no way a replacement for the standard command shell on your system. It handles ANSI 
colored output, but only colours.

This module will install but not work on Windows.

=head1 OPTIONS

If you change any of the color options while running, you should call B<configureTags> to see the changes.

=over 4

=item Switch B<-buffering>

Default value: 1 (boolean flag)

Used when a process is running.

If buffering is set you have the opportunity to edit your response line
before sending it to the process with return. If buffering is not set every 
key stroke will be sent to the process immediately.

=item Switch B<-dircall>

Callback, called when you change directory.

=item Name B<errorbg>

=item Class B<Errorbg>

=item Switch B<-errorbg>

Default value: #FF0000 (red)

Background color for text tagged as 'error'.

=item Name B<errorfg>

=item Class B<Errorfg>

=item Switch B<-errorfg>

Default value: #FFFF00 (yellow)

Foreground color for text tagged as 'error'.

=item Switch B<-historyfile>

File where the hisory commands given is stored. If you specify this
option the file will be loaded at startup and kept up to date.

=item Switch B<-historymax>

Default value: 64

Maximum size of the command history. If it is full, the oldest entry
is removed when one is added.

=item Name B<linkbg>

=item Class B<Linkbg>

=item Switch B<-linkbg>

Default value: undef

Background color for text tagged as 'link'.

=item Switch B<-linkcall>

Callback to execute when the user clicks a link. It gets the link text as parameter.

=item Name B<linkfg>

=item Class B<Linkfg>

=item Switch B<-linkfg>

Default value: #0000FF (blue)

Foreground color for text tagged as 'link'.

=item Switch B<-linkreg>

Default value: undef

Regular expression used to search for links in the text.
Searching for links is done every time a process finishes.

=item Name B<messagebg>

=item Class B<Messagebg>

=item Switch B<-messagebg>

Default value: undef

Background color for text tagged as 'message'.

=item Name B<messagefg>

=item Class B<Messagefg>

=item Switch B<-messagefg>

Default value: #FFFF00 (blue)

Foreground color for text tagged as 'message'.

=item Name B<tbackground>

=item Class B<Tbackground>

=item Switch B<-tbackground>

Default value: #143B57 (some deep marine blue with a touch of spinache)

Background color for the Tk::Terminal widget.

=item Name B<tfont>

=item Class B<Tfont>

=item Switch B<-tfont>

Default value: Mono 12

Font for the Tk::Terminal widget.

=item Name B<tforeground>

=item Class B<Tforeground>

=item Switch B<-tforeground>

Default value: #F0F0F0 (almost white)

Background color for the Tk::Terminal widget.

=item Switch B<-usercommands>

User defined commands. You can specify a hash with keys that are the commands and
standard Tk callbacks as their value. 

 $term->configure(-usercommands => {
    exit => ['destroy', $app],
 });

=item Switch B<-workdir>

Default value: current working directory.

Acting working directory for commands launched.
Shows up in the prompt.

=back

=head1 KEYBOARD BINDINGS

Most of the keyboard bindings you expect with a command shell apply.
Besides that we have:

=over 4

=item B<CTRL+U>

Toggles buffering.

=item B<CTRL+W>

Performs a clear.

=item B<CTRL+Z>

Kills the currently running process.

=back

=head1 INTERNAL COMMANDS

Commands that are handled internally and not launched as a process:

=over 4

=item B<cd>

Change your working directory. The B<-dircall> callback is called when
you use this command.

=item B<clear>

Performs a clear.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self, $args) = @_;
	
#	$args->{'-cursor'} = 'arrow';
	$args->{'-insertwidth'} = 0;
	$args->{'-wrap'} = 'char';

	$self->SUPER::Populate($args);
	$self->{CURRENT} = undef;
	$self->{ERR} = undef;
	$self->{HISTORY} = [];
	$self->{HISTPOINTER} = undef;
	$self->{IN} = undef;
	$self->{OUT} = undef;
	$self->{PID} = undef;
	$self->{SCANNED} = 1;
	$self->{START} = '1.0';
	$self->{WORKDIR} = cwd;
	$self->insert('end', ' ');
	$self->point('1.0');

	$self->ConfigSpecs(
		-buffering => ['PASSIVE', undef, undef, 1],
		-dircall => ['CALLBACK', undef, undef, sub {}],
		-errorbg => ['PASSIVE', 'errorbg', 'Errorbg', '#FF0000'], #red
		-errorfg => ['PASSIVE', 'errorfg', 'Errorfg', '#FFFF00'], #yellow
		-historyfile => ['PASSIVE'],
		-historymax => ['PASSIVE', undef, undef, 64],
		-linkbg => ['PASSIVE', 'linkbg', 'Linkbg', undef],
		-linkcall => ['CALLBACK', undef, undef, sub {}],
		-linkfg => ['PASSIVE', 'linkfg', 'Linkfg', '#0000FF'], #blue
		-linkreg => ['PASSIVE'],
		-messagebg => ['PASSIVE', 'messagebg', 'Messagebg', undef],
		-messagefg => ['PASSIVE', 'messagefg', 'Messagefg', '#FFFF00'], #yellow
		-tbackground => ['PASSIVE', 'tbackground', 'Tbackground', '#143B57'], #some deep marine blue with a touch of spinache
		-tfont => ['PASSIVE', 'tfont', 'Tfont', 'Mono 12'],
		-tforeground => ['PASSIVE', 'tforeground', 'Tforeground', '#F0F0F0'], #almost white
		-uc => ['CALLBACK'],
		-usercommands => ['PASSIVE', undef, undef, {}],
		-workdir => ['METHOD'],
		DEFAULT => [$self],
	);
	$self->after(1, ['postConfig', $self]);
	return $self
}

sub bindRdOnly {
	my ($class, $mw) = @_;

	# Standard Motif bindings:
	$mw->bind($class,'<Meta-B1-Motion>','NoOp');
	$mw->bind($class,'<Meta-1>','NoOp');
	$mw->bind($class,'<Alt-KeyPress>','NoOp');
	$mw->bind($class,'<Meta-KeyPress>','NoOp');
	$mw->bind($class,'<Control-KeyPress>','NoOp');
	$mw->bind($class,'<Escape>','unselectAll');
 
	$mw->bind($class,'<1>',['Button1',Ev('x'),Ev('y')]);
	$mw->bind($class,'<B1-Motion>','B1_Motion' ) ;
	$mw->bind($class,'<B1-Leave>','B1_Leave' ) ;
	$mw->bind($class,'<B1-Enter>','CancelRepeat');
	$mw->bind($class,'<ButtonRelease-1>','CancelRepeat');
	$mw->bind($class,'<Control-1>',['markSet','insert',Ev('@')]);
 
	$mw->bind($class,'<Double-1>','selectWord' ) ;
	$mw->bind($class,'<Triple-1>','selectLine' ) ;
	$mw->bind($class,'<Shift-1>','adjustSelect' ) ;
	$mw->bind($class,'<Double-Shift-1>',['SelectTo',Ev('@'),'word']);
	$mw->bind($class,'<Triple-Shift-1>',['SelectTo',Ev('@'),'line']);
 
	$mw->bind($class,'<Left>',['keyLeft']);
	$mw->bind($class,'<Shift-Left>',['KeySelect',Ev('index','insert-1c')]);
	$mw->bind($class,'<Control-Left>',['SetCursor',Ev('index','insert-1c wordstart')]);
	$mw->bind($class,'<Shift-Control-Left>',['KeySelect',Ev('index','insert-1c wordstart')]);

	$mw->bind($class,'<Right>',['keyRight']);
	$mw->bind($class,'<Shift-Right>',['KeySelect',Ev('index','insert+1c')]);
	$mw->bind($class,'<Control-Right>',['SetCursor',Ev('index','insert+1c wordend')]);
	$mw->bind($class,'<Shift-Control-Right>',['KeySelect',Ev('index','insert wordend')]);
 
	$mw->bind($class,'<Up>',['historyUp']);
	$mw->bind($class,'<Shift-Up>',['KeySelect',Ev('UpDownLine',-1)]);
	$mw->bind($class,'<Control-Up>',['SetCursor',Ev('PrevPara','insert')]);
	$mw->bind($class,'<Shift-Control-Up>',['KeySelect',Ev('PrevPara','insert')]);
 
	$mw->bind($class,'<Down>',['historyDown']);
	$mw->bind($class,'<Shift-Down>',['KeySelect',Ev('UpDownLine',1)]);
	$mw->bind($class,'<Control-Down>',['SetCursor',Ev('NextPara','insert')]);
	$mw->bind($class,'<Shift-Control-Down>',['KeySelect',Ev('NextPara','insert')]);

	$mw->bind($class,'<Home>',['keyHome']);
	$mw->bind($class,'<Shift-Home>',['KeySelect','insert linestart']);
	$mw->bind($class,'<Control-Home>',['SetCursor','1.0']);
	$mw->bind($class,'<Control-Shift-Home>',['KeySelect','1.0']);

	$mw->bind($class,'<End>',['keyEnd']);
	$mw->bind($class,'<Shift-End>',['KeySelect','insert lineend']);
	$mw->bind($class,'<Control-End>',['SetCursor','end-1char']);
	$mw->bind($class,'<Control-Shift-End>',['KeySelect','end-1char']);

	$mw->bind($class,'<Prior>',['SetCursor',Ev('ScrollPages',-1)]);
	$mw->bind($class,'<Shift-Prior>',['KeySelect',Ev('ScrollPages',-1)]);
	$mw->bind($class,'<Control-Prior>',['xview','scroll',-1,'page']);

	$mw->bind($class,'<Next>',['SetCursor',Ev('ScrollPages',1)]);
	$mw->bind($class,'<Shift-Next>',['KeySelect',Ev('ScrollPages',1)]);
	$mw->bind($class,'<Control-Next>',['xview','scroll',1,'page']);

	$mw->bind($class,'<Shift-Tab>', 'NoOp');
	$mw->bind($class,'<Control-Tab>','focusNext');
	$mw->bind($class,'<Control-Shift-Tab>','focusPrev');

	$mw->bind($class,'<Control-space>',['markSet','anchor','insert']);
	$mw->bind($class,'<Select>',['markSet','anchor','insert']);
	$mw->bind($class,'<Control-Shift-space>',['SelectTo','insert','char']);
	$mw->bind($class,'<Shift-Select>',['SelectTo','insert','char']);
	$mw->bind($class,'<Control-slash>','selectAll');
	$mw->bind($class,'<Control-backslash>','unselectAll');

	$mw->bind($class,'<Control-z>','processKill');
	$mw->bind($class,'<Control-u>','bufferToggle');
	$mw->bind($class,'<Control-w>','clear');

	$mw->bind($class,'<Destroy>','Destroy');
#	$mw->bind($class, '<3>', ['PostPopupMenu', Ev('X'), Ev('Y')]  );
	$mw->YMouseWheelBind($class);
	$mw->XMouseWheelBind($class);

	$mw->MouseWheelBind($class);
 
	return $class;
}

sub bufferToggle {
	my $self = shift;
	my $flag = $self->cget('-buffering');
	my $val;
	if ($flag) {
		$self->configure(-buffering => 0);
		$val = 'off';
	} else {
		$self->configure(-buffering => 1);
		$val = 'on';
	}
	$self->condNewline;
	$self->writeMessage("buffering $val\n");
	$self->prompt unless $self->processRuns;
}

=item B<clear>

Kills the current process if one is running and deletes all text.

=cut

sub clear {
	my $self = shift;
	$self->processKill;
	$self->delete('1.0', 'end - 2c');
	$self->linkScanned(1);
	$self->prompt;
}

sub clipboardCut { #Disabling clipboard cut
}

sub clipboardPaste { #clipboard paste now pastes as if typed
	my $self = shift;
	my $text = $self->clipboardGet;
	while ($text =~ s/(.)//) {
		$self->Insert($1); 
	}
}

sub commandGet {
	my $self = shift;
	my $command = $self->get($self->start, $self->start . ' lineend - 1c');
	return $command
}

sub commandSet {
	my ($self, $command) = @_;
	my $start = $self->start;

	#remove current entry
	my $cur = $self->commandGet;
	my $l = length $cur;
	$self->delete($start, "$start + $l c") if $l > 0;

	#insert the new one
	$self->insert('point', $command);
}

=item B<configureTags>

Configures all tags for this package.
Call this if you make changes to any of them.

=cut

# This code was blatantly copied from Tk::TextANSIColor
# It does not generate tags when you inherit it.
my (%fgcolors, %bgcolors);
my $clear = color('clear');  # Code to reset control codes

my $code_bold = color('bold');
my $code_uline= color('underline');
my @colors = qw/black red green yellow blue magenta cyan white/;
for (@colors) {
  my $fg = color($_);
  my $bg = color("on_$_");

  $fgcolors{$fg} = "ANSIfg$_";
  $bgcolors{$bg} = "ANSIbg$_";
}
#end of blatantly copied code

sub condNewline {
	my $self = shift;
	my $point = $self->point;
	my $text = $self->get("$point linestart", $point);
	$self->insert('point', "\n") unless $text eq '';
}

sub configureTags {
	my $self = shift;
	
	# This code was blatantly copied from Tk::TextANSIColor
	# It does not generate tags when you inherit it.
	for (@colors) {
		$self->tagConfigure("ANSIfg$_", -foreground => $_);
		$self->tagConfigure("ANSIbg$_", -background => $_);
	}
	# Underline
	$self->tagConfigure("ANSIul", -underline => 1);
	$self->tagConfigure("ANSIbd", 
		-font => $self->Font(weight => "bold") );
	#end of blatantly copied code

	$self->tagConfigure('prompt', 
		-background => $self->cget(-tforeground),
		-foreground => $self->cget(-tbackground),
	);

	for ('error', 'link', 'message') {
		my $base = $_;
		my @opt = ();
		my $bg = $self->cget("-$base" . 'bg');
		push @opt, -background => $bg if defined $bg;
		my $fg = $self->cget("-$base" . 'fg');
		push @opt, -foreground => $fg if defined $fg;
		$self->tagConfigure($base, @opt);
	}
}

sub cur {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub cycleCancel {
	my $self = shift;
	my $cid = $self->{'check_id'};
	$self->afterCancel($cid) if defined $cid;
}

sub deleteBefore {
	my $self = shift;
	if ($self->compare('point','!=', $self->start)) {
		$self->delete('point - 1c');
		$self->see('point')
	}
}
 
sub Delete {
	my $self = shift;
	return if $self->point eq $self->index($self->start . ' lineend - 1c');
	$self->delete('point');
	$self->pointShow;
	$self->see('point')
}

sub directory {
	my ($self, $dir) = @_;
	my $current = $self->cget('-workdir');
	my $path = '';
	while ($dir ne '') {
		if ($dir eq '.') { #same dir
			$path = $current;
			$dir = '';
		} elsif ($dir eq '..') { #parent dir
			$path = dirname($current);
			$dir = '';
		} elsif ($dir eq '~') { #parent dir
			$path = $ENV{'HOME'};
			$dir = '';
		} elsif ($dir =~ s/^\~$qsep(.+)//) { #home directory involved
			$path = $ENV{'HOME'} . "$sep$1";
			$dir = '';
		} elsif ($dir =~ /$root/) { #full path
			$path = $dir;
			$dir = '';
		} elsif ($dir =~ s/^\.\.$qsep//) { #incremental parent dir
			$path = dirname($current);
			$current = $path;
		} else {
			$path = $current . $sep . $dir;
			$dir = '';
		}
	}
	unless (-e $path) {
		$self->writeError("'$path' does not exist\n");
		return
	}
	unless (-d $path) {
		$self->writeError("'$path' is not a directory\n");
		return
	}
	$self->workdir($path);
	$self->Callback('-dircall', $path);
}

sub err {
	my $self = shift;
	$self->{ERR} = shift if @_;
	return $self->{ERR}
}

sub hist {
	my $self = shift;
	$self->{HISTORY} = shift if @_;
	return $self->{HISTORY}
}

sub historyAdd {
	my ($self, $item) = @_;
	return if $item eq '';
	$self->historyRemove($item);
	my $hist = $self->hist;
	unshift @$hist, $item;

	my $max = $self->cget('-historymax');
	pop @$hist if @$hist > $max;

	$self->historySave;
}

sub historyDown {
	my $self = shift;
	my $hist = $self->hist;
	return unless @$hist;
	my $hp = $self->hp;
	return unless defined $hp;
	if ($hp eq 0) {
		$self->commandSet($self->{'hist_save'});
		$self->hp(undef);
	} else {
		$hp --;
		$self->commandSet($hist->[$hp]);
		$self->hp($hp);
	}
}

sub historyLoad {
	my $self = shift;
	my $file = $self->cget('-historyfile');
	if ((defined $file) and (-e $file)) {
		if (open(INPUT, '<', $file)) {
			my $hist = $self->hist;
			$hist = [];
			while (<INPUT>) {
				my $item = $_;
				chomp $item;
				push @$hist, $item;
			}
			close INPUT;
			$self->hist($hist);
		}
	}
}

sub historyRemove {
	my ($self, $item) = @_;
	my $hist = $self->hist;
	my $pos = 0;
	my $found = 0;
	for (@$hist) {
		if ($item eq $_) {
			$found = 1;
			last;
		} else {
			$pos ++
		}
	}
	if ($found) {
		splice @$hist, $pos, 1
	}
}

sub historySave {
	my $self = shift;
	my $file = $self->cget('-historyfile');
	if (defined $file) {
		if (open(OUTPUT, '>', $file)) {
			my $hist = $self->hist;
			for (@$hist) { print OUTPUT $_, "\n" }
			close OUTPUT;
		}
	}
}

sub historyUp {
	my $self = shift;
	my $hist = $self->hist;
	return unless @$hist;
	my $hp = $self->hp;
	unless (defined $hp) {
		$self->{'hist_save'} = $self->commandGet;
		$hp = 0;
	} else {
		return if $hp eq @$hist - 1;
		$hp ++
	}
	$self->commandSet($hist->[$hp]);
	$self->hp($hp);
}

sub hp {
	my $self = shift;
	$self->{HISTPOINTER} = shift if @_;
	return $self->{HISTPOINTER}
}

sub in {
	my $self = shift;
	$self->{IN} = shift if @_;
	return $self->{IN}
}

sub Insert {
	my ($self, $string) = @_;
	return unless (defined $string && $string ne '');
	my $buffering = $self->cget('-buffering');
 	$self->send($string) unless $buffering;
 	if ($string eq "\n") {
 		if ($self->processRuns) {
 			if ($buffering) {
 				$self->send($self->commandGet . "\n");
				$self->point($self->point . ' lineend - 1c');
 			}
			$self->insert('point', $string);
 		} else {
			my $command = $self->commandGet;
			$self->point($self->point . ' lineend - 1c');
			$self->insert('point', $string);
			$self->processLaunch($command);
		}
 	} else {
		$self->insert('point',$string);
		$self->see('point');
	}
}

sub InsertKeyPress {
	my ($self, $char) = @_;
 	return unless length($char);
	if ($self->OverstrikeMode) {
		my $pos = $self->point;
		my $current = $self->get($pos);
		$self->delete($pos) unless ($current eq "\n");
	}
 	$self->Insert($char);
}

sub keyEnd {
	my $self = shift;
	$self->point($self->start . ' lineend - 1c');
}

sub keyHome {
	my $self = shift;
	$self->point($self->start);
}

sub keyLeft {
	my $self = shift;
	$self->point($self->point . ' - 1c') if $self->compare($self->point, '>', $self->start)
}

sub keyRight {
	my $self = shift;
	$self->point($self->point . ' + 1c') if $self->compare($self->point, '<', $self->start . ' lineend - 1c')
}

=item B<launch>I<($command)>

Launches a process with $command as command string.

=cut

sub launch {
	my ($self, $command) = @_;
	$self->commandSet($command);
	$self->Insert("\n");
}

sub linkClick {
	my ($self, $x, $y) = @_;
	my $link;

	#find the link
	my $pos = $self->index('@' ."$x,$y");
	my @ranges = $self->tagRanges('link');
	while (@ranges) {
		my $begin = shift @ranges;
		my $end = shift @ranges;
		if (($self->compare($begin, '<=', $pos)) and ($self->compare($begin, '<=', $pos))) {
			$link = $self->get($begin, $end);
		}
	}

	#invoke the callback
	$self->Callback('-linkcall', $link) if defined $link;
}

sub linkScan {
	my $self = shift;
	my $reg = $self->cget('-linkreg');
	return unless defined $reg;
	my $scanned = $self->linkScanned;

	my $end = $self->index('end - 1c');
	$end =~ /^(\d+)/;
	my $lastline = $1;
	return if $lastline eq $scanned;

	while ($scanned <= $lastline) {
		my $text = $self->get("$scanned.0", "$scanned.0 lineend");
		my $pos = 0;
		while ($text ne '') {
			if ($text =~ s/^($reg)//) {
				my $result = $1;
				my $end = $pos + length($result);
				$self->tagAdd('link', "$scanned.$pos", "$scanned.$end");
				$pos = $end;
			} else {
				$pos ++;
				$text =~ s/^.//; #remove first character
			}
		}
		$scanned ++;
	}

	$self->linkScanned($scanned);
}

sub linkScanned {
	my $self = shift;
	$self->{SCANNED} = shift if @_;
	return $self->{SCANNED}
}

sub out {
	my $self = shift;
	$self->{OUT} = shift if @_;
	return $self->{OUT}
}

sub pid {
	my $self = shift;
	$self->{PID} = shift if @_;
	return $self->{PID}
}

sub point {
	my ($self, $index) = @_;
	if (defined $index) {
		$index = $self->index($index);
		$self->markSet('point', $index);
		$self->pointShow;
	}
	return $self->index('point');
}

sub pointShow {
	my $self = shift;
	$self->tagRemove('prompt', '1.0', 'end');
	$self->tagAdd('prompt', $self->point);
	$self->tagRaise('prompt');
}

sub postConfig {
	my $self = shift;
	$self->configure(-background => $self->cget('-tbackground'));
	$self->configure(-foreground => $self->cget('-tforeground'));
	$self->configure(-font => $self->cget('-tfont'));
	$self->configureTags;
	$self->tagBind('link', '<ButtonRelease-1>', [$self, 'linkClick', Ev('x'), Ev('y')]);
	$self->tagBind('link', '<Enter>', sub { $self->configure(-cursor => 'hand1') });
	$self->tagBind('link', '<Leave>', sub { $self->configure(-cursor => 'xterm') });
	$self->historyLoad;
	$self->prompt;
}

sub processCheck {
	my $self = shift;
	delete $self->{'check_id'};
	my $out = $self->out;
	my $err = $self->err;
	my $buffer;
	if (defined sysread($out, $buffer, 8192)) {
		$self->write($buffer);
	}
	if (defined sysread($err, $buffer, 8192)) {
		$self->writeError($buffer);
	}
	my $pid = $self->pid;
	my $kid = waitpid($pid, WNOHANG);
	if ($kid eq $pid) {
		$self->processFinish
	} else {
		$self->{'check_id'} = $self->after(5, ['processCheck', $self]);
	}
}

sub processFinish {
	my $self = shift;
	$self->pid(undef);
	$self->cur(undef);
	$self->linkScan;
	$self->prompt;
}

=item B<processKill>

Kills the currently running process.
Does nothing if no process runs.

=cut

sub processKill {
	my $self = shift;
	return unless $self->processRuns;
	my $pid = $self->pid;
	kill $pid;
	$self->condNewline;
	my $cmd = $self->cur;
	$self->writeMessage("process $pid, '$cmd' killed\n");
	$self->cycleCancel;
	$self->processFinish;
}

sub processLaunch {
	my ($self, $command) = @_;
	return if $self->processRuns;
	return unless defined $command;
	
	#capture cd command
	if ($command =~ /^cd\s+(.+)/) {
		my $dir = $1;
		$self->historyAdd($command);
		$self->directory($dir);
		$command = '';
	}

	#capture clear command
	if ($command eq 'clear') {
		$self->historyAdd('clear');
		$self->clear;
		return
	}

	#capture user defined commands
	my $uc;
	my @opt = ();
	my $usercmds = $self->cget('-usercommands');
	my $copy = $command;
	while ($copy =~ s/^([^\s]+)\s*//) {
#		print "command $copy\n";
		if (defined $uc) {
		 	push @opt, $1
		} else {
			$uc = $1;
		}
	}
	if (defined $uc) {
		if (my $cmd = $usercmds->{$uc}) {
			$self->historyAdd($command);
			$self->configure(-uc => $cmd);
			$self->Callback('-uc', @opt);
			$command = '';
		}
	}

	my $dir = $self->workdir;
	my $cmdstring  = "cd $dir; $command";

	my $in = new IO::Handle;
	my $out = new IO::Handle;
	my $err = new IO::Handle;
	
	my $pid = open3($in, $out, $err, $cmdstring);
	
	#make out and err non blocking;
	for ($out, $err) {
		my $flags = 0;
		fcntl($_, F_GETFL, $flags)	or die "Couldn't get flags for HANDLE : $!\n";
		$flags |= O_NONBLOCK;
		fcntl($_, F_SETFL, $flags)	or die "Couldn't set flags for HANDLE: $!\n";
	}

	if (defined $pid) {
		$self->pid($pid);
		$self->cur($command);

		$self->historyAdd($command);
		$self->hp(undef);

		$self->in($in);
		$self->out($out);
		$self->err($err);

		$self->after(5, ['processCheck', $self]);
	} else {
		$self->writeError("cannot launch '$command'\n");
	}
}

sub processRuns {
	my $self = shift;
	return defined $self->pid
}

sub prompt {
	my $self = shift;
	$self->condNewline;
	my $dir = $self->workdir;
	$self->writeMessage("$dir: ");
	$self->start('end - 2c');
	$self->point('end - 2c');
}

=item B<send>I<($message)>

Sends $message to the input of the process.
Does nothing if no process is running.

=cut

sub send {
	my ($self, $message) = @_;
	return unless $self->processRuns;
	my $in = $self->in;
	print $in $message;
}

sub start {
	my $self = shift;
	$self->{START} = $self->index(shift) if @_;
	return $self->{START}
}

sub workdir {
	my $self = shift;
	if (@_) {
		my $dir = shift;
		unless (-e $dir) {
			warn "'$dir' does not exist";
			return
		} 
		unless (-d $dir) {
			warn "'$dir' is not a directory";
			return
		} 
		$self->{WORKDIR} = $dir;
	}
	return $self->{WORKDIR}
}

=item B<write>I<($text)>

Appends $text to the end.

=cut

sub write {
	my ($self, $message) = @_;
	$self->insert($self->point, $message);
	$self->start($self->point);
	$self->see('end');
}

=item B<writeError>I<($text)>

Appends $text to the end and tags it as error.

=cut

sub writeError {
	my ($self, $message) = @_;
	$self->writeTagged('error', $message);
}

=item B<writeMessage>I<($text)>

Appends $text to the end and tags it as message.

=cut

sub writeMessage {
	my ($self, $message) = @_;
	$self->writeTagged('message', $message);
}

sub writeTagged {
	my ($self, $tag, $message) = @_;
	my $end = $self->index($self->point);
	$self->insert($end, $message);
	my $l = length ($message);
	$self->tagAdd($tag, $end, "$end + $l c");
	$self->start($self->point);
	$self->see('end');
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=cut

1;
__END__


