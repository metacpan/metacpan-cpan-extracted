package Win32::Mechanize::NotepadPlusPlus;
use 5.010;
use warnings;
use strict;
use Exporter 'import';
use Carp;

our $VERSION = '0.001001';  # rrr.mmmsss : rrr is major revision; mmm is minor revision; sss is sub-revision; optionally use _sss instead, for alpha sub-releases

use Win32::Mechanize::NotepadPlusPlus::Notepad ':vars';
use Win32::Mechanize::NotepadPlusPlus::Editor ':vars';

=pod

=head1 NAME

Win32::Mechanize::NotepadPlusPlus - Automate the Windows application Notepad++

=head1 SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus ':main';
    my $npp = notepad();    # main application

=head1 DESCRIPTION

Automate the Windows application L<Notepad++|https://notepad-plus-plus.org/>.  This is inspired by the
Notepad++ plugin PythonScript, but I decided to automate the application from the outside, rather than
from inside a Notepad++ plugin.  But this module uses similar naming conventions and interface to the
PythonScript plugin.

=cut

our @EXPORT = ();   # by default, export nothing
our @EXPORT_MAIN = qw/notepad editor editor1 editor2/;
our @EXPORT_VARS = qw/%nppm %nppidm %scimsg/;
our @EXPORT_OTHER = qw//;   # maybe eventually, functions to create and destroy additional NPP instances
our @EXPORT_OK = (@EXPORT_MAIN, @EXPORT_VARS, @EXPORT_OTHER);
our %EXPORT_TAGS = (
    main            => [@EXPORT_MAIN],
    other           => [@EXPORT_OTHER],
    vars            => [@EXPORT_VARS],
    all             => [@EXPORT_OK],
);

my $default;

BEGIN {
    $default = Win32::Mechanize::NotepadPlusPlus::Notepad->_new();
}

=head1 SUBCLASSES

These give you access to the Notepad++ application GUI and the Scintilla editor components inside Notepad++.
The main module exports functions that return the default instances.

=head2 Notepad

=over

=item notepad

=back

L<Win32::Mechanize::NotepadPlusPlus::Notepad> gives access to the actual Notepad++ application.

    my $npp = notepad();
    $npp->CloseAll();

=cut

sub notepad
{
    $default->notepad or croak "default Notepad++ application object not initialized";
}

=head2 Editor

=over

=item editor1

=item editor2

=item editor

=back

L<Win32::Mechanize::NotepadPlusPlus::Editor>  gives access to the underlying Scintilla component(s) used to actually edit the text files in Notepad++.

In PythonScript, the default instance is called C<editor> for the active editor window. There are two additional
instances, C<editor1> and C<editor2> for accessing the specific "left" and "right" editor panes.

    my $left_pane = editor1();
    my $right_pane = editor2();
    if( editor() == $left_pane ) { ... }    # do this only if left pane is active pane

=cut

sub editor1
{
    $default->editor1 or croak "default editor1 object not initialized";
}

sub editor2
{
    $default->editor2 or croak "default editor2 object not initialized";
}

sub editor
{
    $default->editor or croak "default editor object not initialized";
}

=head2 What About a Console Object?

The Console was a PythonScript feature, beacuse it had an embedded Python interpreter.
Since Win32::Mechanize::NotepadPlusPlus is an outside-in framework, there is no Perl
interpreter embedded in Notepad++.

=head1 LIMITATIONS

This is the first public release of the module.  In general, it works.  As with all first releases,
there is room for improvement; I welcome feedback.

The first known limitation is that none of the hooks for Scintilla or Notepad++ callbacks have been
enabled.  That may come sometime in the future.

All the testing and development was done with a US-English installation of Notepad++, and all the
file encodings have been ANSI or UTF-8.
I L<know|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/2> that I need to include
better tests for encoding, and any help you can provide with that is appreciated.

Notepad++ is a Windows application, so that's the intended platform for this module.  However,
I know Notepad++ can be made to run in Wine and similar environments in Linux, so it may be
possible to make this module drive Notepad++ in such an environment.  Feedback on this process
is welcome.

=head1 INSTALLATION

To install this module, use your favorite CPAN client.

For a manual install, type the following:

    perl Makefile.PL
    make
    make test
    make install

(On Windows machines, you may need to use "dmake" or "gmake" instead of "make", depending on your setup.)

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests
thru the repository's interface at L<https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>,
or by emailing C<E<lt>bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.orgE<gt>>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus>.

=begin html

<a href="https://metacpan.org/pod/Win32::Mechanize::NotepadPlusPlus><img src="https://img.shields.io/cpan/v/Win32-Mechanize-NotepadPlusPlus.svg?colorB=00CC00" alt="" title="metacpan"></a>
<a href="http://matrix.cpantesters.org/?dist=Win32-Mechanize-NotepadPlusPlus"><img src="http://cpants.cpanauthors.org/dist/Win32-Mechanize-NotepadPlusPlus.png" alt="" title="cpan testers"></a>
<a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/releases"><img src="https://img.shields.io/github/release/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="github release"></a>
<a href="https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues"><img src="https://img.shields.io/github/issues/pryrt/Win32-Mechanize-NotepadPlusPlus.svg" alt="" title="issues"></a>
<a href="https://ci.appveyor.com/project/pryrt/win32-mechanize-notepadplusplus"><img src="https://ci.appveyor.com/api/projects/status/6gv0lnwj1t6yaykp/branch/master?svg=true" alt="" title="test coverage"></a>

=end html

=head1 COPYRIGHT

Copyright (C) 2019,2020 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;