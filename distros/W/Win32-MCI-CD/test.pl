# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Win32::MCI::CD;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# Show instructions

print STDOUT "Put an audio cd in your cd-rom drive.\n";


# Get drive letter

my $drive;
while(length($drive) != 2) { print STDOUT "Your cd-rom drive letter: "; $drive = <STDIN>; }
chop($drive);
$drive = $drive . ":";


# Try to play the audio cd

print STDOUT "Trying to play the audio cd.\n";
my $cd = new Win32::MCI::CD(-aliasname => 'our_cd', -drive => $drive);
if(!$cd->cd_opendevice()) { ok(0); fast_exit($cd); }
if(!$cd->cd_mode_tmsf()) { ok(0); fast_exit($cd); }
if(!$cd->cd_play()) { ok(0); fast_exit($cd); };
print STDOUT "Now playing for five seconds...\n";
sleep(5);
print STDOUT "Stopped.\n";
$cd->cd_stop();
ok(1);


# Function fast_exit

sub fast_exit($)
{
 my $handle = shift; 
 $handle->cd_closedevice();
 exit;
}
