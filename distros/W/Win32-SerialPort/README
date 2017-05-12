Win32::SerialPort and Win32API::CommPort
VERSION=0.22, 10 June 2010 (eg/elec_meter.pl and test improvements)

Hello Serial Port users:

If you are not running Windows, you want the Device::SerialPort module
instead of this one. It has a compatible user interface and runs on
Operating Systems that fully support POSIX.pm. Available from your
favorite CPAN site. Since someone asked, MS-DOS does NOT support POSIX.pm.
But OSX does.

It has been over 10 years since the last major release. No functions are
considered "experimental" anymore.  There is now a module
Test::Device::SerialPort on CPAN that emulates these modules (and their
POSIX cousins) for testing application code without hardware. While the
modules themselves have supported USB ports, COM10 and above, VirtualBox,
and embedded ports, the tests did not up to now.

These modules are intended for Win32 ports of Perl without requiring
a compiler or using XS. In every case, compatibility has been selected
over performance. Since everything is (convoluted but still pure) perl,
you can fix flaws and change limits if required. But please file a bug
report if you do. I have tested with the ActiveState (5.6.x, 5.8.x, 5.10.x)
and Strawberry (5.8.x and 5.10.x) distributions. But these modules should
work on any Win32 version that supports Aldo Calpini's Win32::API.
While the modules have worked on earlier perl versions, I no longer have
any way to test them for compatibility.

All planned features are now implemented. If you see any place where the
code does not match the documentation, consider it a bug and please report it.

FILES:

    Changes		- for history lovers
    Makefile.PL		- the "starting point" for traditional reasons
    MANIFEST		- file list
    README.txt		- this file (CRLF)
    README    		- same file with CPAN-friendly name (LF only)
    eg/any_os.plx	- cross-platform use and init
    eg/demo1.plx	- talks to a "really dumb" terminal
    eg/demo2.plx	- "poor man's" readline and chat
    eg/demo3.plx	- looks like a setup menu - but only looks :-(
    eg/demo4.plx	- simplest setup: "new", "required param", "restart"
    eg/demo5.plx	- "waitfor" and "nextline" using lookfor
    eg/demo6.plx	- basic tied FileHandle operations, record separators
    eg/demo7.plx	- a Perl/Tk based terminal, event loop and callbacks
    eg/demo8.plx	- command line terminal emulator with Term::Readkey
    eg/demo9.plx	- using debug on a close()
    eg/elec_meter.pl	- (new) synchronizing with a continuous stream
    eg/options.plx	- post-install test that prints available options
    eg/stty.plx		- first try at Unix lookalike

    lib				- install directory
    lib/Win32			- install directory
    lib/Win32/SerialPort.pm	- the reason you're reading this
    lib/Win32API		- install directory
    lib/Win32API/CommPort.pm	- the raw API calls and other internals

    html			- install directory
    html/Win32			- install directory
    html/Win32/SerialPort.html	- documentation
    html/Win32API		- install directory
    html/Win32API/CommPort.html	- documentation

    t			- test directory
    t/Altport.pm	- stub for inheritance test
    t/test1.t		- RUN ME FIRST, tests and creates configuration
    t/test2.t		- tests restarting_a_configuration and timeouts
    t/test3.t		- Inheritance and export version of test1.t
    t/test4.t		- Inheritance version of test2.t and "restart"
    t/test5.t		- tests to optional exports from CommPort
    t/test6.t		- stty tests
    t/test7.t		- tied FileHandle tests

PRE-INSTALL and TEST:

Run 'perl Makefile.PL' first with nothing connected to "COM1". You can
specify a diferent port to test with 'perl Makefile.PL TESTPORT=PORT'.
I recommend you use a "traditional" hard-wired port for testing if
available. Several tests are skipped for USB and other specialized ports.

For those with make (e.g. Strawberry Perl), the normal mantra applies:
	perl Makefile.PL TESTPORT=port
	make
	make test
	make install

Makefile.PL also generates two scripts for those who don't have a version
of 'make' (e.g. nmake, dmake):
	perl nomake_test
	perl nomake_install

Test::More and related routines are used to generate reports. The test
suite covers most of the module methods and leaves the port set for 9600
baud, 1 stop, 8 data, no parity, no handshaking, and other defaults. At
various points in the testing, it expects unconnected CTS and DTR lines.
The final configuration is saved by test1.t as port_test.cfg in the
current directory (e.g COM1_test.cfg).

The pod2html output is stored in the html directory. Some perl versions
support automatically installing html and others do not.

Tests may also be run individually by typing:
	'perl test?.t [COMx]'

All tests are expected to pass - I would be very interested in hearing
about failures ("not ok"). These tests should be run from a command
line (DOS box).

DEMO PROGRAMS:

Connect a dumb terminal (or a PC that acts like one) to COM1 and setup
the equivalent configuration. Starting demo1.plx should print a three
line message on both the terminal and the Win32 command line. The
terminal keyboard (only) now accepts characters which it prints to both
screens until a CONTROL-Z is typed. Also included is demo2.plx - a truly
minimal chat program. Bi-directional communication without an event loop,
sockets, pipes (or much utility ;-) This one uses CAPITAL-Q from the
active keyboard to quit since <STDIN> doesn't like CONTROL-Z. And each
command shell acts a little differently (Cygnus "bash", COMMAND.COM).
Try running the terminal at 4800 baud to get errors (or 300 to get
"breaks").

AltPort.pm and test3.t implement the "basic Inheritance test" discussed
in perltoot and other documentation. It also imports the :STAT constants.
It's otherwise only slightly modified from test1.t (you'll get a different
"alias" if you run test2.t or demo3.plx after test3.t). There are some
subtle functional changes between test2.t and test4.t. But test4.t also
calls CommPort methods directly rather than through SerialPort and adds
tests for lookfor and stty_xxx methods.

You can read (many of the important) settings with demo3.plx. If you
give it a (valid) configuration file on the command line, it will open
the port with those parameters (and "initialized" set - so you can test
simple changes: see the parity example at the end of demo3.plx).

Run options.plx to see the available choices for various parameters
along with the current values. If you have trouble, I will probably
ask you to save the output of options.plx in a file and send it to me.
You can specify a port name for options.plx on the command line
(e.g. 'perl options.plx COM2').

Demo4.plx is a "minimum" script showing just the basics needed to get
started.

Demo5.plx demonstrates various uses of the lookfor routine including
setups for "waitfor" and a primitive "readline". Try them out. The
default "stty" settings work with a VT-100 style terminal. You may
have to set the options by hand. Use any editor. Let me know if the
descriptions in the documentation are useable. And if any more options
are necessary.

Demo6.plx demonstrates tied FileHandles. Perl 5.005 is recommended.
It "requires" 5.004. It implements timeouts on all user inputs - so
you can run it "hands-off" to see what happens.

Demo7.plx uses Tk to create a terminal emulator. Its included to show
polling and callbacks using an event loop.

Demo8.plx is a simple command-line terminal emulator contributed by
Andrej Mikus.

Elec_meter.pl is user-supplied code to monitor a read-only data stream
produced by a household electric meter (in France).

Stty.plx is a wrapper around the stty method that implements a clone
of the Unix/POSIX function of the same name. It's line noise unless
you know Unix.

The Perl Journal #13 included an article on Controlling a Modem with
Win32::SerialPort. Perl Journal #16 showed how to work with the X10
series of home automation modules (ControlX10::).

Please tell me what does and what doesn't work. The module has proven
to be pretty robust. But I can't test all possible configurations.
Don't trust it for anything important without complete testing.

Available on CPAN under Author BBIRTH or on gitHub:

	http://github.com/wbirthisel/win32-serialport

Thanks,

-bill

Copyright (C) 2010, Bill Birthisel. All rights reserved. This module is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
