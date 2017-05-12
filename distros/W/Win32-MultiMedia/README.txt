Win32-MultiMedia-0.01  pre-alpha

Win32::MultiMedia::Joystick
Win32::MultiMedia::Mci

Access to the Joystick and Mci portion of the Win32 MultiMedia 
system.

Needs perl 5.6+

For source:
   perl Makefile.PL
   nmake
   nmake test
   nmake install

For binary:
   Manual install: Move the contents of "site-lib" 
   to the perl directory\site\lib

No ppd yet.

This is a "pre-alpha" release, which means anything can change
(but not likely, since I'm lazy).  If anyone is interested in 
in this, let me know at tomk@informix.com.

I want to eventually make the full set of interfaces for 
mmsystem.h which includes: 
   Auxiliary,  MCIWnd,  MidiIn,  MidiOut,  Mixer,  WaveIn, and WaveOut

Mci is a good stating place because it can play anything and record 
in Wave format.

If anyone is interested in working on any of those let me know.

The documentation is far from complete for Mci. Basically,
once a device is open you can call any of the MCI commands 
via $mci->command  where 'command' is one of the standard MCI 
commands as defined in the platform SDK documentation:
http://msdn.microsoft.com/library/default.asp?URL=/library/psdk/multimed/mci_04dv.htm

or you can use the SendString(cmd) function directly.

Enjoy,
-Tom
