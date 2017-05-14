This is the culmination of years of work (1999 - current) in building Exchange Mailboxes, but now as a module.

Some peculiarities in setting an "AccessControlEntry" may prohibit you from using and older
version of Win32::OLE (<.1502) with this code.  However, a recent build of perl isn't
truly a bad thing...

Sorry for any inconveniences.

I'd like to thank Andrew Bastien for answering numerous questions when I was an OLE newbie, for most of the
  original code (2.5~ years ago), and helping me debug some problems with it at that time.

For a complete Thank You list, please see the HTML documenmtation page.

This module uses Win32::OLE exclusively and is really just a wrapper for a lot of OLE calls.

OS Requirements: WinNT (Untested, should work,
                          Requires:
                                   -ADSI 2.5, and
                                   -ADSI SDK,
                        however, see notes in nt4readme.txt),
                 Win2K (Tested, works well),
                 WinXP (Untested, should work)

