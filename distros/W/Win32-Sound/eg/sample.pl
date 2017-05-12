use strict;
use warnings;

use Win32::Sound;

my $result;

print "\nWin32::Sound version ", $Win32::Sound::VERSION, " Test Program\n";
print "by Aldo Calpini <dada\@perl.it>\n\n";

print "Playing 'welcome.wav' synchronously...";
$result = Win32::Sound::Play("samples/welcome.wav");
print (($result == 1) ? "OK\n" : "ERROR\n");

print "Playing 1 second of 'welcome.wav' asynchronously...";
$result = Win32::Sound::Play("samples/welcome.wav", 1);

# note it returns immediately
print (($result == 1) ? "OK\n" : "ERROR\n");

# let's hear one second of this music...
sleep(1);

# ...then stop it
print "Stopping sound...";
$result = Win32::Sound::Stop();
print (($result == 1) ? "OK\n" : "ERROR\n");

print "Playing system exit sound...";
$result = Win32::Sound::Play("SystemExit");
print (($result == 1) ? "OK\n" : "ERROR\n");

