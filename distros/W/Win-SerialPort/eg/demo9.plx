#! perl -w

use lib './lib','../lib';
use Win::SerialPort 0.19;

use strict;

my $ob = Win::SerialPort->new ("COM1");
die "could not open port $^E\n" unless ($ob);

Win::SerialPort::debug(1);
$ob->close;
undef $ob;
