#!perl -w
BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

# $Id: 06_sendkeys.t,v 1.2 2008/10/01 11:10:12 int32 Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw(:ALL);

my $debug = 1;
sub debug { warn "@_\n" if $debug }

sub cmparray
{
	my ( $a, $b) = @_;
	unless ( $#$a == $#$b) {
		debug("array1:@$a\narray2:@$b\n");
		return;
	}
	for ( my $i = 0; $i < @$a; $i++) {
		next if $a->[$i] == $b-> [$i];
		debug("$a->[$i] != $b->[$i]\narray1:@$a\narray2:@$b\n");
		return 0;
	}
	return 1;
}

sub cmpkeysets
{
	my @a = Win32::GuiTest::parse_keys(shift);
	my @b = Win32::GuiTest::parse_keys(shift);
	return cmparray(\@a,\@b);
}

sub cmpkeyset
{
	my @a = Win32::GuiTest::parse_keys(shift);
	return cmparray(\@a,\@_);
}

# string -> raw keys
ok( cmpkeyset('a', 
	ord('A'), 0, 
	ord('A'), KEYEVENTF_KEYUP,
), 'lowercase character key');
ok( cmpkeyset('B', 
	VK_SHIFT, 0, 
	ord('B'), 0, 
	ord('B'), KEYEVENTF_KEYUP,
	VK_SHIFT, KEYEVENTF_KEYUP,
), 'uppercase character key');
ok( cmpkeyset('+c', 
	VK_SHIFT, 0, 
	ord('C'), 0, 
	ord('C'), KEYEVENTF_KEYUP,
	VK_SHIFT, KEYEVENTF_KEYUP,
), 'shift+character key');
ok( cmpkeyset('^9', 
	VK_CONTROL, 0, 
	ord('9'), 0, 
	ord('9'), KEYEVENTF_KEYUP,
	VK_CONTROL, KEYEVENTF_KEYUP,
), 'control+character key');
ok( cmpkeyset('%a', 
	VK_MENU, 0, 
	ord('A'), 0, 
	ord('A'), KEYEVENTF_KEYUP,
	VK_MENU, KEYEVENTF_KEYUP,
), 'alt+character key');

# {} simple character parsing
ok( cmpkeysets('A',    '{A}')    ,        "{char} identity");
ok( cmpkeysets('a',    '{'.ord('A').'}'), "{char} charcode");
ok( cmpkeysets('',     '{A 0}')  ,        "{char} x0");
ok( cmpkeysets('A',    '{A 1}')  ,        "{char} x1");
ok( cmpkeysets('AA',   '{A 2}')  ,        "{char} x2");
ok( cmpkeysets('AAAA', '{A 4}')  ,        "{char} x4");

# modkeys () simple identity
ok( cmpkeysets('+a',    '(+a)')        ,  "grouping identity");
ok( cmpkeysets('+a',    '+(a)')        ,  "shift grouping");
ok( cmpkeysets('+a',    '+((a))')      ,  "shift double grouping");
ok( cmpkeysets('+a',    '+(((a)))')    ,  "shift triple grouping");
ok( cmpkeysets('%(+a)', '%(+(a))')     ,  "twomod identity");

# string -> virtual keys
ok( cmpkeyset('{F10}', 
	VK_F10, 0, 
	VK_F10, KEYEVENTF_KEYUP,
), 'F10');
ok( cmpkeyset('+{DELETE}', 
	VK_SHIFT,  0, 
	VK_DELETE, 0, 
	VK_DELETE, KEYEVENTF_KEYUP,
	VK_SHIFT,  KEYEVENTF_KEYUP,
), 'shift+delete');
ok( cmpkeyset('^{INSERT}', 
	VK_CONTROL,  0, 
	VK_INSERT, 0, 
	VK_INSERT, KEYEVENTF_KEYUP,
	VK_CONTROL,  KEYEVENTF_KEYUP,
), 'control+insert');
ok( cmpkeyset('%{PGDN}', 
	VK_MENU,  0, 
	VK_NEXT, 0, 
	VK_NEXT,  KEYEVENTF_KEYUP,
	VK_MENU,  KEYEVENTF_KEYUP,
), 'alt+pgdn');


# {} simple vkey parsing
ok( cmpkeysets('{TAB}',     '{TAB 1}') ,             "{vkey} identity");
ok( cmpkeysets('{TAB}',     '{' . VK_TAB    . '}') , "{vkey} one-digit numeric");
ok( cmpkeysets('{DELETE}',  '{' . VK_DELETE . '}') , "{vkey} two-digit numeric");
ok( cmpkeysets('{TAB}{TAB}','{TAB 2}') ,             "{vkey} count");
# {} and () and modkeys
ok( cmpkeysets('+{BACK}',  '+({BACK})'),              "vkey shift group 1");
ok( cmpkeysets('+{BACK}',  '(+{BACK})'),              "vkey shift group 2");

sub vkey2key
{
	my $r = VkKeyScan(ord(shift));
	my $v = '0' . ($r & 0xff); # in case of 1-digit code
	my $m = '';
	$m .= '+' if $r & 0x100;
	$m .= '^' if $r & 0x200;
	$m .= '%' if $r & 0x400;
	return "${m}{$v}";
}

# escaped keys
ok( cmpkeysets( "{{}", vkey2key('{')), 'escaped {');
ok( cmpkeysets( "{+}", vkey2key('+')), 'escaped +');
ok( cmpkeysets( "{(}", vkey2key('(')), 'escaped (');
ok( cmpkeysets( "{^}", vkey2key('^')), 'escaped ^');
ok( cmpkeysets( "{%}", vkey2key('%')), 'escaped %');
ok( cmpkeysets( "{~}", vkey2key('~')), 'escaped ~');
ok( cmpkeysets( "{{}{{}", "{{ 2}"),    'escaped {{');

# enter
ok( cmpkeyset('~', 
	VK_RETURN, 0, 
	VK_RETURN, KEYEVENTF_KEYUP,
), 'enter');
ok( cmpkeyset('+~', 
	VK_SHIFT,  0, 
	VK_RETURN, 0, 
	VK_RETURN, KEYEVENTF_KEYUP,
	VK_SHIFT,  KEYEVENTF_KEYUP, 
), 'shift+enter');

# unicode as altkeys
ok( cmpkeyset("\x{101}",
	VK_MENU,   0,
	VK_DOWN,   0,
	VK_DOWN,   KEYEVENTF_KEYUP,
	VK_CLEAR,  0,
	VK_CLEAR,  KEYEVENTF_KEYUP,
	VK_HOME,   0,
	VK_HOME,   KEYEVENTF_KEYUP,
	VK_MENU,   KEYEVENTF_KEYUP,
), 'chr(257)');

ok( cmpkeyset("+(\x{8D1})",
	VK_SHIFT,  0,
	VK_MENU,   0,
	VK_DOWN,   0,
	VK_DOWN,   KEYEVENTF_KEYUP,
	VK_DOWN,   0,
	VK_DOWN,   KEYEVENTF_KEYUP,
	VK_CLEAR,  0,
	VK_CLEAR,  KEYEVENTF_KEYUP,
	VK_HOME,   0,
	VK_HOME,   KEYEVENTF_KEYUP,
	VK_MENU,   KEYEVENTF_KEYUP,
	VK_SHIFT,  KEYEVENTF_KEYUP,
), 'shift+chr(2257)');

# unicode groups
ok( cmpkeysets("\x{100}",         "{\x{100}}"),    "{unicode} identity");
ok( cmpkeysets("\x{101}",         "{\x{101} 1}"),  "{unicode} x1");
ok( cmpkeysets("\x{102}\x{102}",  "{\x{102} 2}"),  "{unicode} x2");


1;
