#!perl -w

use lib 't';
use WWW'Scripter;

$w = new WWW'Scripter;
$n = $w->navigator;

use tests 12;
is $n->userAgent, $w->agent,'userAgent';
is $n->appName, 'WWW::Scripter', 'initial appName';
is $n->appName('scow'), 'WWW::Scripter', 'retval of appName when setting';
is $n->appName, 'scow', 'result of setting appName';
is $n->appCodeName, 'WWW::Scripter', 'initial appCodeName';
is $n->appCodeName('creen'), 'WWW::Scripter',
 'retval of appCodeName when setting';
is $n->appCodeName, 'creen', 'result of setting appCodeName';
is $n->appVersion, 'WWW::Scripter'->VERSION, 'initial appVersion';
is $n->appVersion('cnelp'), 'WWW::Scripter'->VERSION,
 'retval of appVersion when setting';
is $n->appVersion, 'cnelp', 'result of setting appVersion';
ok !$n->javaEnabled, 'javaEnabled';
ok !$n->taintEnabled, 'taintEnabled';

use tests 10;
$w->agent_alias('Windows IE 6');
is $n->platform, 'Win32', 'platform is Win32 when ua says Windows';
$w->agent_alias('Mac Safari');
is $n->platform, $w->agent =~ /Intel/ ? 'MacIntel' : MacPPC,
 'Mac platform based on ua';
$w->agent_alias('Linux Mozilla');
is $n->platform, 'Linux', 'Linux platform based on ua';
$w->agent('FreeBSD');
is $n->platform, 'FreeBSD', 'FreeBSD platform based on ua';
$w->agent(undef);
$^O = MSWin32;
is $n->platform, 'Win32', 'platform is Win32 based on $^O';
$^O = MacOS;
is $n->platform,'MacPPC', 'platform is MacPPC when $^O is MacOS (classic)';
$^O = 'darwin';
is $n->platform, 'Mac'.qw[Intel PPC][pack "s", 28526, eq 'on'],
 'Mac platform based on $^O and endianness';
$^O = 'freebsd';
is $n->platform, 'FreeBSD', 'platform is FreeBSD based on $^O';
$^O = 'linux';
is $n->platform, 'Linux', 'platform is Linux based on $^O';
$^O = 'trow';
is $n->platform, 'trow', 'platform is some random string based on $^O';

{
 package ghin;
 @ISA = WWW'Scripter;
}

use tests 1;
is new ghin ->navigator->appName,  'ghin',
 'appName from empty WWW::Scripter subclass';

use tests 2;
ok $n->cookieEnabled, 'cookieEnabled by default';
ok !new WWW::Scripter cookie_jar=>undef, ->navigator->cookieEnabled,
  '!cookieEnabled when cookie_jar is undef';
