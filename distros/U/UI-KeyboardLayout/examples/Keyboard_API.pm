use strict;

#  http://msdn.microsoft.com/en-us/goglobal/bb688121.aspx#eaaac		- is relevant?  locales
#  http://gilesey.wordpress.com/2012/12/30/initailizing-mfccrt-for-consumption-of-regional-settings-internationalizationc/

# !!! http://stackoverflow.com/questions/8289492/find-out-when-keyboard-layout-is-changed
# If we could find the HWND of our console...  GetKeyboardLayout(GetWindowThreadProcessId(GetForegroundWindow(), NULL))
# http://support.microsoft.com/kb/124103
# HWND WINAPI GetConsoleWindow(void);
# Win32::Console has GetConsoleHWND() but only in C!!!

# SetConsoleFlags() reports failure when succeeding (we worked around this)
# ReadConsoleW() has buffer overflows and returns junk on reads more than 1 char when more than 1 char is available
# We got stuck into the default input locale; how to get out and be sensitive to input settings changes?

# Win32::API has problems with: arguments void, return type short, arguments of type long long are considered as long...
# Apparently, return type of "int" is interpreted as "unsigned int" (on 64-bit OS???, any build)

{ my $f;
sub GetKeyboardState (;$) {	# Argument: nothing, undef (will auto-vivify) or 256-byte string (byte! use pack 'C', not chr)
  require Win32::API;	# should be short!:
  $f ||= Win32::API->new(q(user32), qq[int GetKeyboardState(char *s)]) or die "Import failed: $!"; 
  my($s) = (@_ ? \shift : \my $tmp);
  defined $$s or $$s = ' ' x 256;
  256 == length $$s or die "GetKeyboardState(): wrong size of output buffer";
  $f->Call($$s) or die "GetKeyboardState() failed: $^E";
  $$s
}}

{ my $f;
sub GetKeyState ($) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), qq[int GetKeyState(int n)]) or die "Import failed: $!"; 
  my($k) = shift;
  $f->Call($k);	# or die "GetKeyState($k) failed: $^E";
}}

my %pointer_ints  = qw(4 int 8 __int64);
my %pointer_types = qw(4 L   8 Q);
my $HANDLE_t =  $pointer_ints{length pack 'p', ''} or die "Cannot work with this pointer size";
my $HANDLE_p = $pointer_types{length pack 'p', ''} or die "Cannot work with this pointer type";

{ my $f;
sub GetKeyboardLayout (;$) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), qq[$HANDLE_t GetKeyboardLayout(long tId)]) or die "Import failed: $!"; 
  my $tId = (shift || 0);
  $f->Call($tId)
}}

{ my $f;
sub ActivateKeyboardLayout ($;$) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), qq[$HANDLE_t ActivateKeyboardLayout($HANDLE_t new, unsigned long flags)]) or die "Import failed: $!"; 
  my($hkl, $fl) = (shift, shift || 0);
  $f->Call($hkl, $fl)
}}
 

{ my $f;
sub GetKeyboardLayoutList () {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), qq[int GetKeyboardLayoutList(int n, char *s)]) or die "Import failed: $!"; 
  my $n = $f->Call(0, undef) or die "Unexpected: no keyboard layout found";
  my $s = '_' x ($n*(length pack 'p', ''));
  my $nn = $f->Call($n, $s) or die "No keyboard layout returned (out of $n)";
  ($n == $nn) or die "Only $nn keyborad layouts (out of $n) returned";
  unpack "$HANDLE_p*", $s;
}}

{ my $f;
sub ToUnicode ($;$$$) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), 
     qq[int ToUnicode(unsigned int wVirtKey, unsigned int wScanCode, char *lpKeyState, char* pwszBuff, int cchBuff, unsigned int wFlags)]) or die "Import failed: $!"; 
  my($vk, $sc, $kst, $menu) = (shift, shift, shift, shift);
  $kst = "\0" x 256 unless defined $kst;
  256 == length $kst or die "keystate buffer of unexpected length)";
  $sc = 0 unless defined $sc;
  my $buf = '_' x (2*5);		# 4 shorts and (not delivered) 0 trailing short
  my $rc = $f->Call($vk, $sc, $kst, $buf, length($buf)/2, $menu||0);	# or die "ToUnicode() failed: $^E";
  warn "\t\tToUnicode() ==> $rc\n";
  return unless $rc;		# Not a in-char-sequence event
  return undef if $rc < 0 or $rc >= 0x80000000;	# dead key (bug with forced `unsigned´ in Win32::API???
  substr $buf, 2*$rc, 1000, '';	# Truncate
  # $buf =~ s/^((..)*)(?=\0\0)/$1/s
  require Encode;
  Encode::decode('UTF-16LE', $buf);
}}

{ my $f;
sub ToUnicodeEx ($;$$$$) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), 
     qq[int ToUnicodeEx(unsigned int wVirtKey, unsigned int wScanCode, char *lpKeyState, char* pwszBuff, int cchBuff, unsigned int wFlags, $HANDLE_t kbd)]) or die "Import failed: $!"; 
  my($vk, $sc, $kst, $kbd, $menu) = (shift, shift, shift, shift, shift);
  $kst = "\0" x 256 unless defined $kst;
  256 == length $kst or die "keystate buffer of unexpected length)";
  $sc = 0 unless defined $sc;
  $kbd = GetKeyboardLayout unless defined $kbd;
  my $buf = '_' x (2*5);		# 4 shorts and (not actually delivered) 0 trailing short
  my $rc = $f->Call($vk, $sc, $kst, $buf, length($buf)/2, $menu || 0, $kbd);	# or die "ToUnicode() failed: $^E";
  warn sprintf "\t\tToUnicodeEx() ==> %d;\tkbd = %#x\n", $rc, $kbd;
  return unless $rc;		# Not a in-char-sequence event
  return undef if $rc < 0 or $rc >= 0x80000000;	# dead key (bug with forced `unsigned´ in Win32::API???
  require Encode;
  Encode::decode('UTF-16LE', substr $buf, 0, 2*$rc);
}}

my $struct_len = 0;
my %event_types = qw( 1 lsssSx![L]L	2 ssx![L]LLL	4 ss	8 L	16 L );
my $L;		# Alignment???
$struct_len < ($L = length pack "s x![L] $_ x![L]", (1) x (1+length)) and $struct_len = $L for values %event_types;
# warn "estimate_str_len=$struct_len";

{ my $f;
sub ReadConsoleEvents (;$$) {
  require Win32::API;
  $f ||= Win32::API->new(q(kernel32), qq[int ReadConsoleInputW($HANDLE_t h, char *s, long c, char *cc)]); 
  my($fh, $c) = (shift, shift || 1);
  $fh = \*STDIN unless defined $fh;
  ref $fh and ($fh = GetOsFHandle $fh or die "fh($fh) has no Win32 handle");
  my $i = q(1) x ($struct_len * $c);
  my $o = q(1111);
  $f->Call($fh, $i, $c, $o) or die "ReadConsoleInputW() failed: $^E";
  $o = unpack 'l', $o or die "ReadConsoleInputW() returned 0 entries";
  my @T = map { unpack 's', substr $i, $_*$struct_len, $struct_len } 0..$o-1;
  map { [unpack "s x![L] $event_types{$T[$_]}", substr $i, $_*$struct_len, $struct_len] } 0..$o-1;
}}

sub __ConsoleMode ($) {
  require Win32::Console;
  my $fh = shift;
  ref $fh and ($fh = GetOsFHandle $fh or die "fh($fh) has no Win32 handle");
  $^E = 0;
  Win32::Console::_GetConsoleMode($fh) or not $^E;
}

sub ConsoleFlag_s ($$;$) {
  my($fh, $f, $on) = (shift, shift, shift);
  $on = 1 unless defined $on;
  require Win32::Console;
  ref $fh and ($fh = GetOsFHandle $fh or die "fh($fh) has no Win32 handle");
  local $^E = 0;
  my $omode = my $mode = Win32::Console::_GetConsoleMode($fh) or not $^E or die "not a Console";
  $on ? $mode |= $f : $mode &= ~$f;
  unless (Win32::Console::_SetConsoleMode($fh, $mode)) {   # XXX _SetConsoleMode always reports failure??? (invalid parameter)
    my $o_E = $^E;
    my $nmode = Win32::Console::_GetConsoleMode($fh); 
    my $what = "setting a mode (from $omode to $mode; res=$nmode): $o_E";
    ($nmode or not $^E) or ($nmode == $mode) or die "error $what";
    warn "warning: SetConsoleMode() buggy: $what";
  }
  $omode
}

{ my $f;
sub WriteConsole ($;$) {
  require Win32::API;
  $f ||= Win32::API->new(q(kernel32), qq[int WriteConsoleW($HANDLE_t h, char *s, long c, char *cc, $HANDLE_t reserved)]); 
  my($s, $fh, $l) = (shift, shift);
  1 & ($l = length $s) and die "Must get an even number of bytes";
  $l >>= 1 or return 1;
  $fh = \*STDOUT unless defined $fh;
  ref $fh and ($fh = GetOsFHandle $fh or die "fh($fh) has no Win32 handle");
  my $o = q(1111);
  $f->Call($fh, $s, $l, $o, 0) or die "WriteConsoleW() failed: $^E";
  $o = unpack 'l', $o;
  $o == $l or die "WriteConsoleW() wrote only $o chars out of $l";
  1
}}

{ my $f;
sub __ReadConsole ($;$) {
  require Win32::API;
  $f ||= Win32::API->new(q(kernel32), qq[int ReadConsoleW($HANDLE_t h, char *s, long c, char *cc, $HANDLE_t control)]); 
  my($l, $fh) = (shift, shift);
  my $s = '_' x (2*$l + 4) or return '';	# Apparently, we get \x65 appended???  To protect, allocate 4 > 1 bytes
  $fh = \*STDIN unless defined $fh;
  ref $fh and ($fh = GetOsFHandle $fh or die "fh($fh) has no Win32 handle");
  my $o = q(1111);
  $f->Call($fh, $s, $l, $o, 0) or die "ReadConsoleW() failed: $^E";
  $o = unpack 'l', $o;
warn "got <", (join ' ', map sprintf("%#02x", ord), split //, $s), "> $o of $l read\n";
  my($overrun) = ((substr $s, 2*$o) =~ /^([^_]*)/);
warn "overrun <", (join ' ', map sprintf("%#02x", ord), split //, $overrun), ">\n" if length $overrun;
  substr $s, 2*$o, (length $s) - 2*$o, '';
  $s
}}
sub readConsole ($;$) {
  my($l, $fh, $s) = (shift, shift);
  $fh = \*STDIN unless defined $fh;
  (read $fh, $s, $l), return $s unless -t $fh and try_checkConsole $fh;	# -t is very successful, but just in case...
  require Encode;
  my $prev = '';
  ($s = __ReadConsole($l, $fh)) =~ /.[\xd8-\xdb]\z/s and $s .= __ReadConsole(1, $fh);	# LittleEndian Surrogates
  Encode::decode('UTF-16LE', $s);
}

{ my $f;
sub GetConsoleWindow () {
  require Win32::API;
  $f ||= Win32::API->new(q(kernel32), qq[$HANDLE_t GetConsoleWindow()]) or die "Import failed: $!"; 
  $f->Call();
}}

{ my $f;
sub GetWindowThreadProcessId ($) {
  require Win32::API;
  $f ||= Win32::API->new(q(user32), qq[long GetWindowThreadProcessId($HANDLE_t hwnd, char *s)]) or die "Import failed: $!";
  my($hwnd, $s) = shift;
  if (my $needPID = wantarray) {
    $s = '_' x 4;
  }
  my $o = $f->Call($hwnd, $s);
  return $o unless wantarray;
  ($o, unpack 'L', $s);
}}

1;
