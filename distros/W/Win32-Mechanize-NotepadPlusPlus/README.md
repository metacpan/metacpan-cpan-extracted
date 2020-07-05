# NAME

Win32::Mechanize::NotepadPlusPlus - Automate the Windows application Notepad++

# SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus ':main';
    my $npp = notepad();    # main application

# DESCRIPTION

Automate the Windows application [Notepad++](https://notepad-plus-plus.org/).  This is inspired by the
Notepad++ plugin PythonScript, but I decided to automate the application from the outside, rather than
from inside a Notepad++ plugin.  But this module uses similar naming conventions and interface to the
PythonScript plugin.

## REQUIREMENTS

You need to have Notepad++ on your system.

This module will work if Notepad++ is in a standard install location, like `%ProgramFiles%\Notepad++\`
or `%ProgramFiles(x86)%\Notepad++\`, or if it is in your path: when it can find the executable,
it will either use the currently-running instance, or will launch a new instance if none are
currently running.  If it cannot find your executable, the will only work if Notepad++ is
already running.

The module was developed with Notepad++ v7.7 or newer in mind, though some features should still
work on older versions of Notepad++.  As Notepad++ adds new features, the minimum version for
that method will be indicated in the help.

# LIMITATIONS

This is the first public release of the module.  In general, it works.  As with all first releases,
there is room for improvement; I welcome feedback.

The first known limitation is that none of the hooks for Scintilla or Notepad++ callbacks have been
enabled.  That may come sometime in the future.

All the testing and development was done with a US-English installation of Notepad++, and all the
file encodings have been ANSI or UTF-8.
I [know](https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/2) that I need to include
better tests for encoding, and any help you can provide with that is appreciated.

Notepad++ is a Windows application, so that's the intended platform for this module.  However,
I know Notepad++ can be made to run in Wine and similar environments in Linux, so it may be
possible to make this module drive Notepad++ in such an environment.  Feedback on this process
is welcome.

# INSTALLATION

To install this module, use your favorite CPAN client.

For a manual install, type the following:

    perl Makefile.PL
    make
    make test
    make install

(On Windows machines, you may need to use "dmake" or "gmake" instead of "make", depending on your setup.)

## It didn't install

In general, if the test suite fails and it doesn't install, you will probably need to file a
[bug report](https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues).

Known possible causes include

- Bit mismatch

    Notepad++ and Perl must have the same bits -- 64bit or 32bit.  Make sure they do.
    If they don't, it will fail in test file `t\02_bits.t`.

- `-1 NOT >= 0` error

    See [issue #28](https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/28):
    if you get the message
    `SendMessage_getRawString(): -1 NOT >= 0 at C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\lib/Win32/Mechanize/NotepadPlusPlus/Notepad.pm line 755.`
    or similar in multiple of the test files, it might be because you have one or
    more really large files currently open in Notepad++, or you have too many
    files open.  Either of these can cause a race condition where the test suite
    expects Notepad++ to respond with all files loaded, but Notepad++ isn't quite
    ready yet.  In that case, **File > Save Session**, then
    **File > Close All**.  Exit and restart Notepad++.  The test suite will
    probably pass now (if not, please comment on issue#28).  Once passing and
    installed, you can **File > Load Session** to restore your previously
    active file session.

# AUTHOR

Peter C. Jones `<petercj AT cpan DOT org>`

Please report any bugs or feature requests
thru the repository's interface at [https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues](https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues),
or by emailing `<bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.org>`
or thru the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus).

<div>
    <a href="https://metacpan.org/pod/Win32::Mechanize::NotepadPlusPlus"><img src="https://img.shields.io/cpan/v/Win32-Mechanize-NotepadPlusPlus.svg?colorB=00CC00" alt="" title="metacpan"></a>
    <a href="http://matrix.cpantesters.org/?dist=Win32-Mechanize-NotepadPlusPlus"><img src="http://cpants.cpanauthors.org/dist/Win32-Mechanize-NotepadPlusPlus.png" alt="" title="cpan testers"></a>
    <a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/releases"><img src="https://img.shields.io/github/release/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="github release"></a>
    <a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues"><img src="https://img.shields.io/github/issues/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="issues"></a>
    <a href="https://ci.appveyor.com/project/pryrt/win32-mechanize-notepadplusplus"><img src="https://ci.appveyor.com/api/projects/status/6gv0lnwj1t6yaykp/branch/master?svg=true" alt="" title="test coverage"></a>
</div>

# COPYRIGHT

Copyright (C) 2019,2020 Peter C. Jones

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
