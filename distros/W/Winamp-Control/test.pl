# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 2 };

use Winamp::Control;

ok(1); # If we made it this far, we're ok.

print <<ENDE;

You will need the winamp-plugin "httpQ" (Written by Kosta Arvanitis) installed on the machine playing
the music via winamp/shoutcast. You may find it at:

	http://www.kostaa.com/winamp/

or otherwise search the plugin-section at

	http://www.winamp.com

After installation you have to activate httpQ through the winamp preferences dialog. In the
"Plug-ins/General Purpose" section, select httpQ and press the configure button at the bottom.

Install and run it before the this test, otherwise it will fail (not important).

ENDE

		print 'Enter the host:port:password where winamp is installed and httpQ is running [localhost:4800]: ';

		chomp( my $input = <STDIN> );

		my ( $host, $port, $passwd ) = split ':', $input;

		my $winamp = Winamp::Control->new( host => $host || '127.0.0.1', port => $port || 4800, passwd => $passwd );

		if( my $ver = $winamp->getversion )
		{
			printf "\nConnected to Winamp (Ver: %s)\n", $ver;

			print "Current playlist:\n", join "\n\t", $winamp->getplaylisttitle();

			printf "\n\nCurrently playing: %s (%s)\n", $winamp->getcurrenttitle(), $winamp->getplaylistfile( a => $winamp->getlistpos ) if $winamp->isplaying();
		}
		else
		{

print <<ENDE;

TEST FAILED !

You should verify:

	1) Winamp was started.
	2) The httpQ-plugin was started (explicitly started httpQ with the 'start'-button or automatic).
	3) You have entered the correct host and port.

ENDE
		}

ok(2);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

