#!/usr/bin/perl -w
#perl -C31 -we "
use strict;
use Win32API::File 'GetOsFHandle';
use utf8;

my $flag_use_for_keyup = 0x0100;		# The documented value is 0x8000; but it does not produce what CONSOLE sees
   $flag_use_for_keyup = 0x8000;		# 0x100 works to sync us with TTY, but it duplicates prefix keys

$Win32::API::DEBUG = 1;				# XXXX Too early now, when we load-when-needed
my %pointer_ints = qw(4 int 8 __int64);
my $HANDLE_t = $pointer_ints{length pack 'p', ''} or die "Cannot deduce pointer size";

use Keyboard_API;

sub ReadConsoleEvent () { @{(ReadConsoleEvents)[0]} }

sub checkConsole ($) {  __ConsoleMode shift or not $^E  }		# returns success if cannot load
sub try_checkConsole ($) {		# returns success if cannot load
  my $o;
  return 1 unless eval {$o = checkConsole shift; 1};	# Fake success if cannot do better
  return $o;
}

sub printConsole ($;$) {
  my($s, $fh) = (shift, shift);
  $fh = \*STDOUT unless defined $fh;
  (print $fh $s), return unless -t $fh and try_checkConsole $fh;	# -t is very successful, but just in case...
  require Encode;
  WriteConsole(Encode::encode('UTF-16LE', $s), $fh);
}


#print $f->Call($stdin_h, $i, 10, $o), q( ), unpack 'l', $o for 1..3;
#exit;

# http://msdn.microsoft.com/en-us/library/ms927178.aspx
my %_VK = qw(
VK_SHIFT 	10 
VK_CONTROL 	11
VK_MENU 	12
VK_PAUSE 	13
VK_CAPITAL 	14

VK_SPACE 	20
VK_OEM_COMMA	0xBC
VK_NUMPAD3 	63
VK_NEXT 	22
VK_APPS 	5D
VK_OEM_AX	0xE1

VK_NUMLOCK 	90
VK_SCROLL 	91
VK_LSHIFT	0xA0
VK_RSHIFT	0xA1
VK_LCONTROL	0xA2
VK_RCONTROL	0xA3
VK_LMENU	0xA4
VK_RMENU	0xA5	);
my %VK;
while (my ($f,$t) = each %_VK) {
  (my $ff = $f) =~ s/^VK_// or die;
  $VK{$ff} = hex $t;
}

{ my $high_surrogate;
sub c($;$) { 
  my $i = shift; 
  my $buffer = (@_ ? \shift : \$high_surrogate);
  return q() if $i<32 or $i==0x7f; 
  (defined $$buffer and warn("Doubled high surrogate (function called multiple times per event?)") and return $$buffer), 
    $$buffer = $i, return q() if $i<0xDC00 and $i >= 0xD800; 
  $i += ($$buffer - 0xD800)*0x400 - 0xDC00 + 0x10000, undef $$buffer if $i>=0xDC00 and $i < 0xE000;
  warn("Loner high surrogate") and return if defined $$buffer;
  chr $i
}}

sub mode2s ($) {
  my $in = shift; 
  my @o; 
  $in & (1<<$_) and push @o, (qw(rAlt lAlt rCtrl lCtrl Shft NumL ScrL CapL Enh ? ??))[$_] for 0..10; 
  qq(@o)
} 

#use Win32::Console;
#my $c = Win32::Console->new( STD_INPUT_HANDLE); 

my @k = qw(T down rep vkey vscan ch ctrl);
sub format_ConsoleEvent ($) {
  my @in = @{shift()};
  join '; ', (map { "$k[$_]=" . ($in[$_] < 0 ? $in[$_] + 256 : $in[$_]) } 0..$#in),
    (@in ? mode2s($in[-1]) . ' [' . (c $in[-2]) . ']' : 'empty'); 
}

my $no_mods = "\0" x 256;
sub reset_ToUnicode_via_vk ($$;$$) {
  my ($vk, $cnt, $s, $scan) = (shift, shift, shift || $no_mods, shift || 0);
  while ($cnt-- > 0) {
    my ($c) = ToUnicodeEx($vk, $scan, $s) or next;	# returns empty on non-character
    defined $c or next;					# returns undef on prefix key
    return 1						# either character, or non-a-defined sequence
  }
  return						# could not finish a prefix sequence
}

sub reset_ToUnicode (;$$$) {
  my ($vk, $s, $scan) = (shift, shift || $no_mods, shift || 0);
  return 1 if reset_ToUnicode_via_vk hex $_VK{VK_SPACE}, 5			# Try a few spaces
		or $vk and reset_ToUnicode_via_vk $vk, 5, $s, $scan & 0xFF;	# Try a few repetitions of the prefix
  for my $c ('A'..'Z', '0' .. '9') {
    return 1 if reset_ToUnicode_via_vk ord $c, 5;	# Try a few alphanumerics without modifiers
  }
  return	# could not finish a prefix sequence (do not try too hard: there may be no way to finish!)
}
sub restore_ToUnicode ($;@) {
  my($state, $ret, $cnt) = (shift);
  for my $ev ( @{ $state->{history} }, @_ ) {
    $cnt = (($ret) = &ToUnicodeEx(@$ev));		# ignore prototype
  }
  return unless $cnt;
  $ret
}

sub reset_state ($) { %{shift()} = (buf => '') }
my %is_alt = map { ($_VK{"VK_${_}MENU"}, 1) } '', qw(L R);
sub ToUnicode_with_state ($$$$$;$$$$) {	# Assume that $state->{buf} is always defined.  Assume that ToUnicode() was already called
  my($really, $state, $force_up, $char, $vk, $sc, $kst, $kbd, $menu) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
  $sc |= $flag_use_for_keyup if $sc and $force_up;
  my ($up, $not_char) = ($force_up or ($sc || 0) & 0x8000);
  # Console returns result of its ToUnicode in $char; defined if processed in context of console
  if ($char and (not $up or $is_alt{$vk})) {	# Entering Unicode numerically reports on keyup of Alt
    my $ss = ($state->{buf} .= chr $char);
    return if defined $sc and not $sc;	# It >1 16-bit char is delivered, all but the last one are reported with scancode=0
    reset_state($state), return $ss;
  }
  # Here either we are not processing console events, or console returns char=0, which is not-decisive:
  # it may be either non-char event, or a prefix key
  reset_ToUnicode($vk, $kst, $sc) or return;	# Erase the state stored in the keyboard driver
  my($ret) = restore_ToUnicode($state, [$vk, $sc, $kst, $kbd, $menu]) or $not_char++;
  if (defined $ret) {
    reset_state($state);
    printConsole "!!! Mismatch: caller sends $char, my logic gives «$ret».\n" unless defined $char and $ret eq chr $char;
    return $ret;
  }
  if ($not_char) {
    printConsole "!!! Mismatch: caller sends $char, my logic gives no-char.\n" if $char;
    return;	# No need to update state
  }
  printConsole "+++ Prefix key\n";
  push @{ $state->{history} }, [$vk, $sc, $kst, $kbd, $menu];
  return undef;
}

sub ToUnicode_with_mods ($$;$$$) {
  my($mods, $vk, $sc, $kbd, $menu) = (shift, shift, shift, shift, shift);
  my $kst = "\0" x 256;				# All variants work
  substr $kst, $_, 1, "\x80" for @$mods;
  ToUnicodeEx $vk, $sc, $kst, $kbd, $menu;
}

if ("@ARGV" eq 'cooked') {	# Control-letter are read as is (except C-Enter??? and C-c), Alt-letters as letters
  my $omode;
  eval {$omode = ConsoleFlag_s \*STDIN, 0x2, 0; 1} or warn "unset ENABLE_LINE_INPUT on STDIN: $@";
  for (1..5) {
    printConsole "$_: I see «" . readConsole(10) . "»\n";
  }
  defined $omode and ConsoleFlag_s \*STDIN, $omode;	# OR with the old value
  exit;
}

my($use_kbd, $do_ToUnicode);
($use_kbd, $do_ToUnicode) = ($1, shift) if ($ARGV[0] || '') =~ /^U(\d+)?$/;

my %vk_short = qw(CAPITAL CapsL NUMLOCK NumL SCROLL ScrL SHIFT Shft CONTROL Ctrl MENU Alt);
sub __mods($$@) { 
  my ($s, $k) = (shift,shift);
  my $kk = $vk_short{$k} || $k;
  $kk . (join '/', @_) . '=' . join '/', map sprintf('%x', ord substr $s, $VK{$_.$k}), @_
}
#sub modsLR($$) { my ($s, $k) = @_; '$k/L/R=' . join '/', map sprintf('%#x', ord substr $s, $VK{$_.$k}), '','L','R' }
sub mod1($$)    { __mods shift, shift, '' }
sub modsLR($$)  { __mods shift, shift, '', 'L', 'R' }

my $fh = \*STDIN;
warn "STDIN is not from a console" unless -t $fh and try_checkConsole $fh;	# -t is very successful, but just in case...
my $in_dead;
if ($do_ToUnicode) {
  my ($c_tid, $c_pid) = GetWindowThreadProcessId(my $c_w = GetConsoleWindow);
  my @l = GetKeyboardLayoutList;
  printConsole "My PID=$$, console's PID=$c_pid, console's TID=$c_tid.\n";
  printConsole(sprintf("\t\tConsoleWin: %#x of thread %#x with kbd %#x", $c_w, $c_tid, GetKeyboardLayout($c_tid))
          .",\n\t\tKeyboard layouts: <" . (join ', ', map {sprintf '%#x', $_ } @l) . ">\n\t\t\tChoose one of them using one of options U0 ... U$#l\n");
  ActivateKeyboardLayout($l[$use_kbd]) if defined $use_kbd;
}
reset_state(my $state_ToUnicode = {});
for (1..shift||20) {
  my @in = ReadConsoleEvents $fh, 8; #$c->Input;
  for (0..$#in) {
    my $s;
    printConsole "$_: " . (format_ConsoleEvent $in[$_]) . "\n";
    next unless $do_ToUnicode or $in[$_][0] != 1;			# Keyup/down events
    GetKeyState(0);		# Voodoo to enable GKbS in non-message queue context???  (Works in Win7 SP1; must call every time)
    GetKeyboardState($s);	#    see http://msdn.microsoft.com/en-us/library/windows/desktop/ms646299%28v=vs.85%29.aspx
    printConsole "\t".join(', ', (map mod1($s, $_), qw(CAPITAL NUMLOCK SCROLL)), (map modsLR($s, $_), qw(SHIFT CONTROL MENU))) . "\n";
    next unless $in[$_]->[0] == 1;	# keyboard event
#    my ($c) = ToUnicodeEx($in[$_][3], $in[$_][4], $s) or next;
    my ($c) = ToUnicode_with_state('really', $state_ToUnicode, !$in[$_][1], $in[$_][-2], $in[$_][3], $in[$_][4], $s) or next;
    $in_dead = 1, printConsole("\tprefix key, expecting more input...\n"), next unless defined $c;
    if ($in_dead) {
      if (1 < length $c) {
        warn "I'm puzzled: more than 2 chars arrived after a prefix key: «$c»\n" if 2 < length $c;
        my ($p, $r) = split //, $c, 2;
        printConsole "\tprefix key = «$p» was followed by unrecognized suffix «$r»...\n";
      } else {
        printConsole "\tkey sequence results in «$c».\n";
      }
      $in_dead = 0;
    } else {
      my $s = (1 < length $c) && 's';
      printConsole sprintf "\t==> char$s «%s»; keyboard layout %#x.\n", $c, GetKeyboardLayout;
    }
  }
}

if (0) {
  my $with_SPACE = "\0" x 256;				# All variants work
  printConsole "VK_SPACE=$_VK{VK_SPACE} gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39, $with_SPACE)."»\n" for 1..3;
  printConsole "VK_SPACE=$_VK{VK_SPACE} gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, undef, $with_SPACE)."»\n" for 1..3;
  substr $with_SPACE, hex $_VK{VK_SPACE}, 1, "\x80";
  printConsole "VK_SPACE=$_VK{VK_SPACE} gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39, $with_SPACE)."»\n" for 1..3;
  printConsole "VK_SPACE=$_VK{VK_SPACE} gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, undef, $with_SPACE)."»\n" for 1..3;
}
if (0) {
  my(@merge);
  for my $flag (0..0xFF, 0x8000..0x80ff, 0x800000..0x8000ff) {
    my ($o) = ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39 | ($flag << 8)) or next;
    push @merge, [$flag] and next unless @merge and $merge[-1][-1] == $flag-1;
    push @{ $merge[-1] }, $flag;
  }
  my @res = map {@$_ <= 2 ? (map sprintf('%#04x',$_), @$_) :  sprintf('%#04x-%#04x',$_->[0],$_->[-1])} @merge;
  printConsole "The following flags (with top words 0, 0x80, 0x8000) do not prohibit recognizing SPACE: " . join(', ', @res)."\n"
}
if (0) {
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(CONTROL LCONTROL MENU RMENU);
  for my $flag (map +($_<<8)..(($_<<8)+0xff), 0, map 1<<$_, 0..15) {	#
    reset_ToUnicode;
    my ($o) = ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33) or next;
    defined $o and next;
#    ($o) =    ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33 | ($flag << 8)) or next;
    ($o) =    ToUnicode_with_mods(\@mods_agr, (hex $_VK{VK_OEM_COMMA}) | ($flag << 8), 0x33 | (0x80 << 8));# or next;
    #defined $o and $o eq '̧' or next;
    ($o) = ToUnicodeEx(ord 'C') or next;
    defined $o and $o eq 'ç' or next;
    push @merge, [$flag] and next unless @merge and $merge[-1][-1] == $flag-1;
    push @{ $merge[-1] }, $flag;
  }
  my @res = map {@$_ <= 2 ? (map sprintf('%#04x',$_), @$_) :  sprintf('%#04x-%#04x',$_->[0],$_->[-1])} @merge;
  printConsole "The following flags (with ≤1-bit top words) do not prohibit recognizing AltGr-, c: " . join(', ', @res)."\n";
  reset_ToUnicode;
}
if (0) {	# OK with izKeys 0.60: all flags work
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(CONTROL LCONTROL MENU RMENU);
  for my $flag (map(1<<$_, 0..15), 0xffff, 0..0xFF) {	#
    reset_ToUnicode;
    my ($o) = ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33) or next;
    defined $o and next;
#    ($o) =    ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33 | ($flag << 8)) or next;
    ($o) =    ToUnicode_with_mods(\@mods_agr, (hex $_VK{VK_OEM_COMMA}), 0x33 | (0x80 << 8), undef, $flag);# or next;
    #defined $o and $o eq '̧' or next;
    ($o) = ToUnicodeEx(ord 'C') or next;
    defined $o and $o eq 'ç' or next;
    push @merge, [$flag] and next unless @merge and $merge[-1][-1] == $flag-1;
    push @{ $merge[-1] }, $flag;
  }
  my @res = map {@$_ <= 2 ? (map sprintf('%#04x',$_), @$_) :  sprintf('%#04x-%#04x',$_->[0],$_->[-1])} @merge;
  printConsole "The following flags (≤1-bit top, or 0..0xFF, or OxFFFF) do not prohibit recognizing AltGr-, c: " . join(', ', @res)."\n";
  reset_ToUnicode;
}
if (0) {	# with izKeys 0.60: one must have (flag & 0x02) TRUE
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(CONTROL LCONTROL MENU RMENU);
  for my $flag (map(1<<$_, 0..15), 0xffff, 0..0xFF) {	#
    reset_ToUnicode;
    my ($o) = ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33) or next;
    defined $o and next;
#    ($o) =    ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33 | ($flag << 8)) or next;
    ($o) =    ToUnicode_with_mods(\@mods_agr, (hex $_VK{VK_OEM_COMMA}), 0x33 | (0x80 << 8), undef, $flag);# or next;
    #defined $o and $o eq '̧' or next;
#    my ($o1) = ToUnicodeEx(ord 'C') or next;
    defined $o and $o eq "\x{327}" or next;
    push @merge, [$flag] and next unless @merge and $merge[-1][-1] == $flag-1;
    push @{ $merge[-1] }, $flag;
  }
  my @res = map {@$_ <= 2 ? (map sprintf('%#04x',$_), @$_) :  sprintf('%#04x-%#04x',$_->[0],$_->[-1])} @merge;
  printConsole "The following flags (≤1-bit top, or 0..0xFF, or OxFFFF) work with AltGr-, similar to console: " . join(', ', @res)."\n";
  reset_ToUnicode;
}
if (0) {{	# OK with izKeys 0.60
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(CONTROL LCONTROL MENU RMENU);
#  for my $flag (0) {	#
    reset_ToUnicode;
    my ($o) = ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33) or warn("AltGr-comma is not a deadkey"), next;
    defined $o and warn "AltGr-comma generates $o";
#    ($o) =    ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33 | ($flag << 8)) or next;
    ($o) =    ToUnicode_with_mods(\@mods_agr, (hex $_VK{VK_OEM_COMMA}), 0x33 | (0x80 << 8))
       and warn "AltGr-comma Up reports a character or deadkey";# or next;
    defined $o and warn "AltGr-comma Up generates $o";
    #defined $o and $o eq '̧' or next;
    ($o) = ToUnicodeEx(ord 'C') or warn "AltGr-comma C does not generate a character";
    defined $o and $o eq 'ç' or warn("AltGr-comma C generates $o"), next;
#  }
  printConsole "Checked AltGr-, c: Down=>deadkey, Up=>IGNORE, Down=>ç\n";
  reset_ToUnicode;
}}
if (0) {{	# OK with izKeys 0.60
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(OEM_AX);
  reset_ToUnicode;
  my ($o) = ToUnicode_with_mods(\@mods_agr, ord 'C', 0x2e) or warn("Mnu-c is ignored"), next;
  defined $o and $o eq 'ц' or warn "Mnu-c generates $o, expecting ц";
  printConsole "Checked Menu-c=>ц\n";
  reset_ToUnicode;
}}
if (1) {{	# OK with izKeys 0.60 (but what for-menu is doing???)
  my(@mods_agr, @merge) = map hex $_VK{"VK_$_"}, qw(OEM_AX MENU LMENU);	# if MENU removed: the same
  reset_ToUnicode;
  my ($o) = ToUnicode_with_mods(\@mods_agr, ord 'C', 0x2e) or warn("Alt-Mnu-c is ignored"), next;
  defined $o and $o eq 'ц' or warn "Alt-Mnu-c generates $o, expecting ц, not 𝚌";
  my ($ou) = ToUnicode_with_mods(\@mods_agr, ord 'C', 0x2e | 0x8000, undef, 0x02) or warn("Alt-Mnu-c UP console-style is ignored"), next;
  defined $ou and $ou eq '𝚌' or warn "Alt-Mnu-c UP console-style generates $ou, expecting 𝚌, not ц";
  
  my ($o1) = ToUnicode_with_mods(\@mods_agr, ord 'C', 0x2e, undef, 1) or warn("Alt-Mnu-c is ignored for-menu"), next;
  defined $o1 and $o1 eq 'ц' or warn "Alt-Mnu-c for-menu generates $o1, expecting ц, not 𝚌";
  my ($ou1) = ToUnicode_with_mods(\@mods_agr, ord 'C', 0x2e | 0x8000, undef, 0x03) or warn("Alt-Mnu-c UP console-style is not ignored for-menu"), next;
  defined $ou1 and $ou1 eq '𝚌' or warn "Alt-Mnu-c generates $ou1, expecting 𝚌/ц";
  printConsole "Checked Alt-Menu-c => ц 𝚌 ц 𝚌 (got $o $ou $o1 $ou1)\n";
  reset_ToUnicode;
}}
if (0) {		# OK: gives M
  my(@mods_alt, @merge) = map hex $_VK{"VK_$_"}, qw(MENU LMENU NUMLOCK);
    reset_ToUnicode;
    my ($o) = ToUnicode_with_mods(\@mods_alt, hex $_VK{VK_MENU}, 0x38) and warn 1;
#    ($o) =    ToUnicode_with_mods(\@mods_agr, hex $_VK{VK_OEM_COMMA}, 0x33 | ($flag << 8)) or next;
    for (1,2,3) {
      ($o) =    ToUnicode_with_mods(\@mods_alt, (hex $_VK{VK_NUMPAD3}), 0x51) and warn("2, $_, ", ord $o) and printConsole "\t«$o»\n";	# 0x63
      ($o) =    ToUnicode_with_mods(\@mods_alt, (hex $_VK{VK_NUMPAD3}), 0x51|0x8000) and warn("-2, $_, ", ord $o) and printConsole "\t«$o»\n";	# 0x63
#    ($o) =    ToUnicode_with_mods(\@mods_alt, (hex $_VK{VK_NEXT})) and warn(2, $_, ord $o) and printConsole "\t«$o»\n" for 1,2,3;	# 0x63
    }
    ($o) =    ToUnicode_with_mods([], (hex $_VK{VK_MENU}), 0x38 | 0x8000) or warn 3;
  printConsole "Alt-333 gives «$o»=" . ord($o) . "\n";
}
if (0) {
  my $with_SPACE = "\0" x 256;
  printConsole "VK_SPACE=$_VK{VK_SPACE} up gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39 | 0x0100, $with_SPACE)."»\n";
  printConsole "VK_SPACE=$_VK{VK_SPACE}    gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39, $with_SPACE)."»\n";
  printConsole "VK_SPACE=$_VK{VK_SPACE} up gives «".ToUnicodeEx(hex $_VK{VK_SPACE}, 0x39 | 0x0100, $with_SPACE)."»\n";
}
# http://www.winprog.org/tutorial/start.html	(simple window)  saved to ===> winprog-org-tutorial-source.zip
# gcc -s -Os -mno-cygwin -o <outputfilename> <inputfilename>
# gcc -s -Os -mwindows -mno-cygwin -o <outputfilename> <inputfilename> -lopengl32 -lwinmm
# for command-line programs and windows programs
