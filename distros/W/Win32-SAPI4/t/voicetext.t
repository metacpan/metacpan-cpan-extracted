#!/usr/bin/perl -w

BEGIN { print "1..4\n" }

use Win32::SAPI4;

print "ok 1\n" if my $vt = Win32::SAPI4::VoiceText->new();
print "ok 2\n" if $vt->CountEngines;
print $vt->CountEngines, " engines found \n";
$vt->Select(1);
print "ok 3\n";
$vt->Speak('Hello World');
print "ok 4\n";
sleep(5);