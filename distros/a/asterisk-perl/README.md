#Asterisk Perl Modules [![Build Status](https://travis-ci.org/asterisk-perl/asterisk-perl.svg?branch=master)](https://travis-ci.org/asterisk-perl/asterisk-perl)[![Coverage Status](https://coveralls.io/repos/github/asterisk-perl/asterisk-perl/badge.svg?branch=master)](https://coveralls.io/github/asterisk-perl/asterisk-perl?branch=master)
by James Golovich <james@gnuinter.net>


These are all modules for interfacing with the Asterisk open source pbx
system.

The main site for these files is http://asterisk.gnuinter.net, or soon
to be found at a CPAN mirror near you.

Some documentation is in the the perl modules, use perldoc to read it
(example: perldoc Asterisk::AGI)

To install these modules just do:
	perl Makefile.PL
	make all
	make install

Examples that use these modules can be found in the examples/ directory

Here is a short description of what each does:

agi-sayani.agi: AGI Script that says the callerid and dnis

agi-test.agi: Rewrite of AGI Example included with asterisk

calleridnamelookup.agi: AGI Script that uses an online reverse number databases to add a name to callerid

tts-bofh.agi: AGI script that uses Festival to give a random bofh excuse

tts-ping.agi: AGI script that pings an ip address and notifies the user if the host is up or down

tts-line.agi: AGI script that uses Festival to read a text file one line at a time

manager-test.pl: Example usage of the Asterisk::Manager module

Asterisk can be found at http://www.asterisk.org
