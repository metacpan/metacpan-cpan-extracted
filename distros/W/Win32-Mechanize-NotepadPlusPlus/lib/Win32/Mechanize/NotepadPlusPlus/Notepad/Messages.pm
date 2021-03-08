package Win32::Mechanize::NotepadPlusPlus::Notepad::Messages;

use warnings;
use strict;
use Exporter 5.57 ('import');

our @EXPORT = qw/%NPPMSG %VIEW %MODELESS %STATUSBAR %MENUHANDLE %INTERNALVAR %LANGTYPE %LINENUMWIDTH %WINVER %WINPLATFORM %NOTIFICATION %DOCSTATUS %NPPIDM %BUFFERENCODING/;

=encoding utf8

=head1 NAME

Win32::Mechanize::NotepadPlusPlus::Notepad::Messages - Define values for using messages, notifications, and their arguments

=head1 SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    print "$_\n" for sort { $NPPMSG{$a} <=> $NPPMSG{$b} } keys %NPPMSG;             # prints all message keys in numerical order


=head1 DESCRIPTION

Notepad++'s L<Plugin Communication system|https://npp-user-manual.org/docs/plugin-communication/#notepad-messages>
defines a set of messages that applications (either plugins embedded in Notepad++, or external programs)
can use for communicating with (and thus controlling) Notepad++.

The hashes in L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages> give named access to the underlying
messages, as well as named versions of the constants used as arguments for those messages.

=head2 MESSAGES

=over

=item %NPPMSG

Most of the Notepad++ Messages are already implemented in the L<Win32::Mechanize::NotepadPlusPlus::Notepad> interface, and under normal circumstances, the end-user should never need to access this %NPPMSG hash directly.

However, if you have a reason to use L<notepad-E<gt>SendMessage|Win32::Mechanize::NotepadPlusPlus::Notepad/SendMessage> directly,
you can use the values from this hash.  Usually, this would only be done if you want a unique wrapper
around the message, or want to implement a new or unimplemented message.

As an example of using th %NPPMSG hash, this code replicates C<notepad-E<gt>getNppVersion> behavior:

    my $nppv = notepad->SendMessage( $NPPMSG{NPPM_GETNPPVERSION}, 0, 0);
    print "npp v", join('.', $v>>16, split//,($v&0xFFFF)), "\n";

=item DEPRECATED %nppm

Deprecated: This variable has been deleted.  If you used it before, please replace with %NPPMSG or the other appropriate hash.

=cut

our %NPPMSG = (
    'NPPMSG'                                                     => (1024 + 1000),
    # messages
    'NPPM_ACTIVATEDOC'                                           => ((1024 + 1000) + 28),
    'NPPM_ADDTOOLBARICON'                                        => ((1024 + 1000) + 41),
    'NPPM_ALLOCATECMDID'                                         => ((1024 + 1000) + 81),
    'NPPM_ALLOCATEMARKER'                                        => ((1024 + 1000) + 82),
    'NPPM_ALLOCATESUPPORTED'                                     => ((1024 + 1000) + 80),
    'NPPM_CREATESCINTILLAHANDLE'                                 => ((1024 + 1000) + 20),
    'NPPM_DECODESCI'                                             => ((1024 + 1000) + 27),
    'NPPM_DESTROYSCINTILLAHANDLE'                                => ((1024 + 1000) + 21),
    'NPPM_DISABLEAUTOUPDATE'                                     => ((1024 + 1000) + 95),
    'NPPM_DMMGETPLUGINHWNDBYNAME'                                => ((1024 + 1000) + 43),
    'NPPM_DMMHIDE'                                               => ((1024 + 1000) + 31),
    'NPPM_DMMREGASDCKDLG'                                        => ((1024 + 1000) + 33),
    'NPPM_DMMSHOW'                                               => ((1024 + 1000) + 30),
    'NPPM_DMMUPDATEDISPINFO'                                     => ((1024 + 1000) + 32),
    'NPPM_DMMVIEWOTHERTAB'                                       => ((1024 + 1000) + 35),
    'NPPM_DOCSWITCHERDISABLECOLUMN'                              => ((1024 + 1000) + 89),
    'NPPM_DOOPEN'                                                => ((1024 + 1000) + 77),
    'NPPM_ENCODESCI'                                             => ((1024 + 1000) + 26),
    'NPPM_GETAPPDATAPLUGINSALLOWED'                              => ((1024 + 1000) + 87),
    'NPPM_GETBUFFERENCODING'                                     => ((1024 + 1000) + 66),
    'NPPM_GETBUFFERFORMAT'                                       => ((1024 + 1000) + 68),
    'NPPM_GETBUFFERIDFROMPOS'                                    => ((1024 + 1000) + 59),
    'NPPM_GETBUFFERLANGTYPE'                                     => ((1024 + 1000) + 64),
    'NPPM_GETCURRENTBUFFERID'                                    => ((1024 + 1000) + 60),
    'NPPM_GETCURRENTCOLUMN'                                      => ((1024 + 3000) + 9),
    'NPPM_GETCURRENTDIRECTORY'                                   => ((1024 + 3000) + 2),
    'NPPM_GETCURRENTDOCINDEX'                                    => ((1024 + 1000) + 23),
    'NPPM_GETCURRENTLANGTYPE'                                    => ((1024 + 1000) + 5),
    'NPPM_GETCURRENTLINE'                                        => ((1024 + 3000) + 8),
    'NPPM_GETCURRENTNATIVELANGENCODING'                          => ((1024 + 1000) + 79),
    'NPPM_GETCURRENTSCINTILLA'                                   => ((1024 + 1000) + 4),
    'NPPM_GETCURRENTVIEW'                                        => ((1024 + 1000) + 88),
    'NPPM_GETCURRENTWORD'                                        => ((1024 + 3000) + 6),
    'NPPM_GETEDITORDEFAULTBACKGROUNDCOLOR'                       => ((1024 + 1000) + 91),
    'NPPM_GETEDITORDEFAULTFOREGROUNDCOLOR'                       => ((1024 + 1000) + 90),
    'NPPM_GETENABLETHEMETEXTUREFUNC'                             => ((1024 + 1000) + 45),
    'NPPM_GETEXTPART'                                            => ((1024 + 3000) + 5),
    'NPPM_GETFILENAME'                                           => ((1024 + 3000) + 3),
    'NPPM_GETFILENAMEATCURSOR'                                   => ((1024 + 3000) + 11),
    'NPPM_GETFULLCURRENTPATH'                                    => ((1024 + 3000) + 1),
    'NPPM_GETFULLPATHFROMBUFFERID'                               => ((1024 + 1000) + 58),
    'NPPM_GETLANGUAGEDESC'                                       => ((1024 + 1000) + 84),
    'NPPM_GETLANGUAGENAME'                                       => ((1024 + 1000) + 83),
    'NPPM_GETLINENUMBERWIDTHMODE'                                => ((1024 + 1000) + 100), # v7.9.2
    'NPPM_GETMENUHANDLE'                                         => ((1024 + 1000) + 25),
    'NPPM_GETNAMEPART'                                           => ((1024 + 3000) + 4),
    'NPPM_GETNBOPENFILES'                                        => ((1024 + 1000) + 7),
    'NPPM_GETNBSESSIONFILES'                                     => ((1024 + 1000) + 13),
    'NPPM_GETNBUSERLANG'                                         => ((1024 + 1000) + 22),
    'NPPM_GETNPPDIRECTORY'                                       => ((1024 + 3000) + 7),
    'NPPM_GETNPPFULLFILEPATH'                                    => ((1024 + 3000) + 10),
    'NPPM_GETNPPVERSION'                                         => ((1024 + 1000) + 50),
    'NPPM_GETOPENFILENAMES'                                      => ((1024 + 1000) + 8),
    'NPPM_GETOPENFILENAMESPRIMARY'                               => ((1024 + 1000) + 17),
    'NPPM_GETOPENFILENAMESSECOND'                                => ((1024 + 1000) + 18),
    'NPPM_GETPLUGINHOMEPATH'                                     => ((1024 + 1000) + 97),
    'NPPM_GETPLUGINSCONFIGDIR'                                   => ((1024 + 1000) + 46),
    'NPPM_GETPOSFROMBUFFERID'                                    => ((1024 + 1000) + 57),
    'NPPM_GETSESSIONFILES'                                       => ((1024 + 1000) + 14),
    'NPPM_GETSETTINGSONCLOUDPATH'                                => ((1024 + 1000) + 98), # v7.9.2
    'NPPM_GETSHORTCUTBYCMDID'                                    => ((1024 + 1000) + 76),
    'NPPM_GETWINDOWSVERSION'                                     => ((1024 + 1000) + 42),
    'NPPM_HIDEMENU'                                              => ((1024 + 1000) + 72),
    'NPPM_HIDESTATUSBAR'                                         => ((1024 + 1000) + 74),
    'NPPM_HIDETABBAR'                                            => ((1024 + 1000) + 51),
    'NPPM_HIDETOOLBAR'                                           => ((1024 + 1000) + 70),
    'NPPM_ISDOCSWITCHERSHOWN'                                    => ((1024 + 1000) + 86),
    'NPPM_ISMENUHIDDEN'                                          => ((1024 + 1000) + 73),
    'NPPM_ISSTATUSBARHIDDEN'                                     => ((1024 + 1000) + 75),
    'NPPM_ISTABBARHIDDEN'                                        => ((1024 + 1000) + 52),
    'NPPM_ISTOOLBARHIDDEN'                                       => ((1024 + 1000) + 71),
    'NPPM_LAUNCHFINDINFILESDLG'                                  => ((1024 + 1000) + 29),
    'NPPM_LOADSESSION'                                           => ((1024 + 1000) + 34),
    'NPPM_MAKECURRENTBUFFERDIRTY'                                => ((1024 + 1000) + 44),
    'NPPM_MENUCOMMAND'                                           => ((1024 + 1000) + 48),
    'NPPM_MODELESSDIALOG'                                        => ((1024 + 1000) + 12),
    'NPPM_MSGTOPLUGIN'                                           => ((1024 + 1000) + 47),
    'NPPM_RELOADBUFFERID'                                        => ((1024 + 1000) + 61),
    'NPPM_RELOADFILE'                                            => ((1024 + 1000) + 36),
    'NPPM_REMOVESHORTCUTBYCMDID'                                 => ((1024 + 1000) + 96),
    'NPPM_SAVEALLFILES'                                          => ((1024 + 1000) + 39),
    'NPPM_SAVECURRENTFILE'                                       => ((1024 + 1000) + 38),
    'NPPM_SAVECURRENTFILEAS'                                     => ((1024 + 1000) + 78),
    'NPPM_SAVECURRENTSESSION'                                    => ((1024 + 1000) + 16),
    'NPPM_SAVEFILE'                                              => ((1024 + 1000) + 94),
    'NPPM_SAVESESSION'                                           => ((1024 + 1000) + 15),
    'NPPM_SETBUFFERENCODING'                                     => ((1024 + 1000) + 67),
    'NPPM_SETBUFFERFORMAT'                                       => ((1024 + 1000) + 69),
    'NPPM_SETBUFFERLANGTYPE'                                     => ((1024 + 1000) + 65),
    'NPPM_SETCURRENTLANGTYPE'                                    => ((1024 + 1000) + 6),
    'NPPM_SETEDITORBORDEREDGE'                                   => ((1024 + 1000) + 93),
    'NPPM_SETLINENUMBERWIDTHMODE'                                => ((1024 + 1000) + 99), # v7.9.2
    'NPPM_SETMENUITEMCHECK'                                      => ((1024 + 1000) + 40),
    'NPPM_SETSMOOTHFONT'                                         => ((1024 + 1000) + 92),
    'NPPM_SETSTATUSBAR'                                          => ((1024 + 1000) + 24),
    'NPPM_SHOWDOCSWITCHER'                                       => ((1024 + 1000) + 85),
    'NPPM_SWITCHTOFILE'                                          => ((1024 + 1000) + 37),
    'NPPM_TRIGGERTABBARCONTEXTMENU'                              => ((1024 + 1000) + 49),

    # message offsets
    'WM_USER'                                                    => 1024,
    'RUNCOMMAND_USER'                                            => (1024 + 3000),
);

=item %VIEW

There are two groups of methods that access the views.

The first is L<getNumberOpenFiles()|Win32::Mechanize::NotepadPlusPlus::Notepad/getNumberOpenFiles>,
which uses three of the %VIEW keys to count the number of files open in the specified view.

    Key             | Value | Description
    ----------------+-------+------------------------------
    ALL_OPEN_FILES  | 0     | Total of files in both views
    PRIMARY_VIEW    | 1     | Only the files in the primary view (usually the left view: editor1)
    SECOND_VIEW     | 2     | Only the files in the second view (usually the right view: editor2)


The second group are the L<buffer-related methods|Win32::Mechanize::NotepadPlusPlus::Notepad/"Get/Change Active Buffers">.

    Key             | Value | Description
    ----------------+-------+------------------------------
    MAIN_VIEW       | 0     | Access the main view (usually the left view: editor1)
    SUB_VIEW        | 1     | Access the sub view (usually the right view: editor2)

Yes, the two groups have an off-by-one.  That's the way the underlying Notepad++ code, and thus the Plugin Interface, was designed.

=cut

our %VIEW = (
    # view params (NPPM_GETNBOPENFILES)
    'ALL_OPEN_FILES'                                             => 0,
    'PRIMARY_VIEW'                                               => 1,
    'SECOND_VIEW'                                                => 2,
    # view params (NPPM_GETCURRENTDOCINDEX)
    'MAIN_VIEW'                                                  => 0,
    'SUB_VIEW'                                                   => 1,
);

=item %MODELESS

=item TODO: L<issue #18|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/18>

These would be used by the C<$NPPMSG{NPPM_MODELESSDIALOG}> message.
However, L<registerModelessDialog()|Win32::Mechanize::NotepadPlusPlus::Notepad/registerModelessDialog>
has not yet been implemented.

    Key                     | Description
    ------------------------|------------
    MODELESSDIALOGADD       | Registers a dialog's hWnd
    MODELESSDIALOGREMOVE    | Un-registers a dialog's hWnd

=cut

our %MODELESS = (
    # NPPM_MODELESSDIALOG params
    'MODELESSDIALOGADD'                                          => 0,
    'MODELESSDIALOGREMOVE'                                       => 1,
);

=item %STATUSBAR

These are be used by the L<setStatusBar()|Win32::Mechanize::NotepadPlusPlus::Notepad/setStatusBar> method for choosing which section of the status bar to change.

    Key                     |   | Description
    ------------------------+---+-----------------
    STATUSBAR_DOC_TYPE      | 0 | Document's syntax lexer (language)
    STATUSBAR_DOC_SIZE      | 1 | File size
    STATUSBAR_CUR_POS       | 2 | Current cursor position
    STATUSBAR_EOF_FORMAT    | 3 | EOL (End-Of-Line) format
    STATUSBAR_UNICODE_TYPE  | 4 | Encoding
    STATUSBAR_TYPING_MODE   | 5 | Insert (INS) or Overwrite (OVR)

=cut

our %STATUSBAR = (
    # NPPM_SETSTATUSBAR params
    'STATUSBAR_DOC_TYPE'                                         => 0,
    'STATUSBAR_DOC_SIZE'                                         => 1,
    'STATUSBAR_CUR_POS'                                          => 2,
    'STATUSBAR_EOF_FORMAT'                                       => 3,
    'STATUSBAR_UNICODE_TYPE'                                     => 4,
    'STATUSBAR_TYPING_MODE'                                      => 5,
);

=item %MENUHANDLE

Used internally by L<getMainMenuHandle()|Win32::Mechanize::NotepadPlusPlus::Notepad/getMainMenuHandle>  and
L<getPluginMenuHandle()|Win32::Mechanize::NotepadPlusPlus::Notepad/getPluginMenuHandle> to return handles to the specified menus.

    Key             |   | Description
    ----------------+---+-----------------
    NPPMAINMENU     | 1 | Main menu (contains File, Edit, ...)
    NPPPLUGINMENU   | 0 | Plugins menu (a submenu of the Main menu)

=cut

our %MENUHANDLE = (
    # NPPM_GETMENUHANDLE params
    'NPPPLUGINMENU'                                              => 0,
    'NPPMAINMENU'                                                => 1,
);

=item %INTERNALVAR

Pass these to L<getNppDir()|Win32::Mechanize::NotepadPlusPlus::Notepad/getNppDir> to access the internal variables described L<in the Macros section of the official docs|https://npp-user-manual.org/docs/config-files/#macros>.


    Key                 | Description                               | Example
    --------------------+-------------------------------------------+----------------------------
    FULL_CURRENT_PATH   | full path to the active file              | E:\My Web\main\welcome.html
    CURRENT_DIRECTORY   | active file’s directory                   | E:\My Web\main
    FILE_NAME           | active file’s name                        | welcome.html
    NAME_PART           | filename without extension                | welcome
    EXT_PART            | extension                                 | html
    CURRENT_WORD        | active selection or word under the cursor | text
    CURRENT_LINE        | line number of cursor location            | 1
    CURRENT_COLUMN      | column number of cursor location          | 5
    NPP_DIRECTORY       | notepad++ executable's directory          | c:\Program Files\notepad++
    NPP_FULL_FILE_PATH  | full path to the notepad++.exe            | c:\Program Files\notepad++\notepad++.exe

=cut


our %INTERNALVAR = (
    'VAR_NOT_RECOGNIZED'                                         => 0,
    'FULL_CURRENT_PATH'                                          => 1,
    'CURRENT_DIRECTORY'                                          => 2,
    'FILE_NAME'                                                  => 3,
    'NAME_PART'                                                  => 4,
    'EXT_PART'                                                   => 5,
    'CURRENT_WORD'                                               => 6,
    'NPP_DIRECTORY'                                              => 7,
    'CURRENT_LINE'                                               => 8,
    'CURRENT_COLUMN'                                             => 9,
    'NPP_FULL_FILE_PATH'                                         => 10,
    'GETFILENAMEATCURSOR'                                        => 11,
);

=item %LANGTYPE

Used by L<language parser methods|Win32::Mechanize::NotepadPlusPlus::Notepad/"Get/Set Language Parser">.

    L_TEXT      : 0  | L_CSS       : 20 | L_AU3           : 40 | L_BAANC         : 60 | L_REGISTRY      : 80 |
    L_PHP       : 1  | L_PERL      : 21 | L_CAML          : 41 | L_SREC          : 61 | L_RUST          : 81 |
    L_C         : 2  | L_PYTHON    : 22 | L_ADA           : 42 | L_IHEX          : 62 | L_SPICE         : 82 |
    L_CPP       : 3  | L_LUA       : 23 | L_VERILOG       : 43 | L_TEHEX         : 63 | L_TXT2TAGS      : 83 |
    L_CS        : 4  | L_TEX       : 24 | L_MATLAB        : 44 | L_SWIFT         : 64 | L_VISUALPROLOG  : 84 |
    L_OBJC      : 5  | L_FORTRAN   : 25 | L_HASKELL       : 45 | L_ASN1          : 65 | L_EXTERNAL      : 85 |
    L_JAVA      : 6  | L_BASH      : 26 | L_INNO          : 46 | L_AVS           : 66 |                 :    |
    L_RC        : 7  | L_FLASH     : 27 | L_SEARCHRESULT  : 47 | L_BLITZBASIC    : 67 |                 :    |
    L_HTML      : 8  | L_NSIS      : 28 | L_CMAKE         : 48 | L_PUREBASIC     : 68 |                 :    |
    L_XML       : 9  | L_TCL       : 29 | L_YAML          : 49 | L_FREEBASIC     : 69 |                 :    |
    L_MAKEFILE  : 10 | L_LISP      : 30 | L_COBOL         : 50 | L_CSOUND        : 70 |                 :    |
    L_PASCAL    : 11 | L_SCHEME    : 31 | L_GUI4CLI       : 51 | L_ERLANG        : 71 |                 :    |
    L_BATCH     : 12 | L_ASM       : 32 | L_D             : 52 | L_ESCRIPT       : 72 |                 :    |
    L_INI       : 13 | L_DIFF      : 33 | L_POWERSHELL    : 53 | L_FORTH         : 73 |                 :    |
    L_ASCII     : 14 | L_PROPS     : 34 | L_R             : 54 | L_LATEX         : 74 |                 :    |
    L_USER      : 15 | L_PS        : 35 | L_JSP           : 55 | L_MMIXAL        : 75 |                 :    |
    L_ASP       : 16 | L_RUBY      : 36 | L_COFFEESCRIPT  : 56 | L_NIMROD        : 76 |                 :    |
    L_SQL       : 17 | L_SMALLTALK : 37 | L_JSON          : 57 | L_NNCRONTAB     : 77 |                 :    |
    L_VB        : 18 | L_VHDL      : 38 | L_JAVASCRIPT    : 58 | L_OSCRIPT       : 78 |                 :    |
    L_JS        : 19 | L_KIX       : 39 | L_FORTRAN_77    : 59 | L_REBOL         : 79 |                 :    |

=cut

our %LANGTYPE = (
    # enum LangType
    'L_ADA'                                                      => 42,
    'L_ASCII'                                                    => 14,
    'L_ASM'                                                      => 32,
    'L_ASN1'                                                     => 65,
    'L_ASP'                                                      => 16,
    'L_AU3'                                                      => 40,
    'L_AVS'                                                      => 66,
    'L_BAANC'                                                    => 60,
    'L_BASH'                                                     => 26,
    'L_BATCH'                                                    => 12,
    'L_BLITZBASIC'                                               => 67,
    'L_C'                                                        => 2,
    'L_CAML'                                                     => 41,
    'L_CMAKE'                                                    => 48,
    'L_COBOL'                                                    => 50,
    'L_COFFEESCRIPT'                                             => 56,
    'L_CPP'                                                      => 3,
    'L_CS'                                                       => 4,
    'L_CSOUND'                                                   => 70,
    'L_CSS'                                                      => 20,
    'L_D'                                                        => 52,
    'L_DIFF'                                                     => 33,
    'L_ERLANG'                                                   => 71,
    'L_ESCRIPT'                                                  => 72,
    'L_EXTERNAL'                                                 => 85,
    'L_FLASH'                                                    => 27,
    'L_FORTH'                                                    => 73,
    'L_FORTRAN'                                                  => 25,
    'L_FORTRAN_77'                                               => 59,
    'L_FREEBASIC'                                                => 69,
    'L_GUI4CLI'                                                  => 51,
    'L_HASKELL'                                                  => 45,
    'L_HTML'                                                     => 8,
    'L_IHEX'                                                     => 62,
    'L_INI'                                                      => 13,
    'L_INNO'                                                     => 46,
    'L_JAVA'                                                     => 6,
    'L_JAVASCRIPT'                                               => 58,
    'L_JS'                                                       => 19,
    'L_JSON'                                                     => 57,
    'L_JSP'                                                      => 55,
    'L_KIX'                                                      => 39,
    'L_LATEX'                                                    => 74,
    'L_LISP'                                                     => 30,
    'L_LUA'                                                      => 23,
    'L_MAKEFILE'                                                 => 10,
    'L_MATLAB'                                                   => 44,
    'L_MMIXAL'                                                   => 75,
    'L_NIMROD'                                                   => 76,
    'L_NNCRONTAB'                                                => 77,
    'L_NSIS'                                                     => 28,
    'L_OBJC'                                                     => 5,
    'L_OSCRIPT'                                                  => 78,
    'L_PASCAL'                                                   => 11,
    'L_PERL'                                                     => 21,
    'L_PHP '                                                     => 1,
    'L_POWERSHELL'                                               => 53,
    'L_PROPS'                                                    => 34,
    'L_PS'                                                       => 35,
    'L_PUREBASIC'                                                => 68,
    'L_PYTHON'                                                   => 22,
    'L_R'                                                        => 54,
    'L_RC'                                                       => 7,
    'L_REBOL'                                                    => 79,
    'L_REGISTRY'                                                 => 80,
    'L_RUBY'                                                     => 36,
    'L_RUST'                                                     => 81,
    'L_SCHEME'                                                   => 31,
    'L_SEARCHRESULT'                                             => 47,
    'L_SMALLTALK'                                                => 37,
    'L_SPICE'                                                    => 82,
    'L_SQL'                                                      => 17,
    'L_SREC'                                                     => 61,
    'L_SWIFT'                                                    => 64,
    'L_TCL'                                                      => 29,
    'L_TEHEX'                                                    => 63,
    'L_TEX'                                                      => 24,
    'L_TEXT'                                                     => 0,
    'L_TXT2TAGS'                                                 => 83,
    'L_USER'                                                     => 15,
    'L_VB'                                                       => 18,
    'L_VERILOG'                                                  => 43,
    'L_VHDL'                                                     => 38,
    'L_VISUALPROLOG'                                             => 84,
    'L_XML'                                                      => 9,
    'L_YAML'                                                     => 49,
);

=item %LINENUMWIDTH

Used by L<setLineNumberWidthMode|Win32::Mechanize::NotepadPlusPlus::Notepad/"setLineNumberWidthMode">
and L<getLineNumberWidthMode|Win32::Mechanize::NotepadPlusPlus::Notepad/"getLineNumberWidthMode">.

    Key                   |   | Description
    ----------------------+---+-----------------
    LINENUMWIDTH_CONSTANT | 1 | Line-number column width always wide enough for largest line number
    LINENUMWIDTH_DYNAMIC  | 0 | Line-number column width changes with number of digits in local line number

Added in v7.9.2.

=cut

our %LINENUMWIDTH = (
    # enum LineNumWidth
    'LINENUMWIDTH_CONSTANT' => 1,
    'LINENUMWIDTH_DYNAMIC'  => 0,
);

=item %WINVER

I'm not sure it's really useful, but it's still privided.

    print join "\n", map { "$_ => $WINVER{$_}" } sort keys %WINVER;

=cut

our %WINVER = (
    # enum WinVer
    'WV_95'                                                      => 2,
    'WV_98'                                                      => 3,
    'WV_ME'                                                      => 4,
    'WV_NT'                                                      => 5,
    'WV_S2003'                                                   => 8,
    'WV_UNKNOWN'                                                 => 0,
    'WV_VISTA'                                                   => 10,
    'WV_W2K'                                                     => 6,
    'WV_WIN10'                                                   => 14,
    'WV_WIN32S'                                                  => 1,
    'WV_WIN7'                                                    => 11,
    'WV_WIN8'                                                    => 12,
    'WV_WIN81'                                                   => 13,
    'WV_XP'                                                      => 7,
    'WV_XPX64'                                                   => 9,
);

=item %WINPLATFORM

I'm not sure it's really useful, but it's still privided.

    print join "\n", map { "$_ => $WINPLATFORM{$_}" } sort keys %WINPLATFORM;

=cut

our %WINPLATFORM = (
    # enum Platform
    'PF_IA64'                                                    => 3,
    'PF_UNKNOWN'                                                 => 0,
    'PF_X64'                                                     => 2,
    'PF_X86'                                                     => 1,

);

=back

=head2 NOTIFICATIONS

Not yet used, but the constants are available.

=over

=item %NOTIFICATION

If you are interested, you can find all the message keys with code like the following:

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    printf "%-39s => %d\n", $_, $NOTIFICATION{$_} for sort { $NOTIFICATION{$a} <=> $NOTIFICATION{$b} } keys %NOTIFICATION;   # prints all notification keys in numerical order

=cut


# NPP Notifications
our %NOTIFICATION = (
    'NPPN_FIRST'                                                 => 1000,
    'NPPN_BEFORESHUTDOWN'                                        => (1000 + 19),
    'NPPN_BUFFERACTIVATED'                                       => (1000 + 10),
    'NPPN_CANCELSHUTDOWN'                                        => (1000 + 20),
    'NPPN_DOCORDERCHANGED'                                       => (1000 + 17),
    'NPPN_FILEBEFORECLOSE'                                       => (1000 + 3),
    'NPPN_FILEBEFOREDELETE'                                      => (1000 + 24),
    'NPPN_FILEBEFORELOAD'                                        => (1000 + 14),
    'NPPN_FILEBEFOREOPEN'                                        => (1000 + 6),
    'NPPN_FILEBEFORERENAME'                                      => (1000 + 21),
    'NPPN_FILEBEFORESAVE'                                        => (1000 + 7),
    'NPPN_FILECLOSED'                                            => (1000 + 5),
    'NPPN_FILEDELETED'                                           => (1000 + 26),
    'NPPN_FILEDELETEFAILED'                                      => (1000 + 25),
    'NPPN_FILELOADFAILED'                                        => (1000 + 15),
    'NPPN_FILEOPENED'                                            => (1000 + 4),
    'NPPN_FILERENAMECANCEL'                                      => (1000 + 22),
    'NPPN_FILERENAMED'                                           => (1000 + 23),
    'NPPN_FILESAVED'                                             => (1000 + 8),
    'NPPN_LANGCHANGED'                                           => (1000 + 11),
    'NPPN_READONLYCHANGED'                                       => (1000 + 16),
    'NPPN_READY'                                                 => (1000 + 1),
    'NPPN_SHORTCUTREMAPPED'                                      => (1000 + 13),
    'NPPN_SHUTDOWN'                                              => (1000 + 9),
    'NPPN_SNAPSHOTDIRTYFILELOADED'                               => (1000 + 18),
    'NPPN_TBMODIFICATION'                                        => (1000 + 2),
    'NPPN_WORDSTYLESUPDATED'                                     => (1000 + 12),
);

=item %DOCSTATUS

Used by the NPPN_READONLYCHANGED notification.

    Key                     |   | Description
    ------------------------+---+-----------------
    DOCSTATUS_READONLY      | 1 | The file changed its "is readonly" status
    DOCSTATUS_BUFFERDIRTY   | 0 | The file changed its "is modified" status

=cut

our %DOCSTATUS = (
    # NPPN_READONLYCHANGED notification params
    'DOCSTATUS_READONLY'                                         => 1,
    'DOCSTATUS_BUFFERDIRTY'                                      => 2,
);

=back

=head2 MENU COMMAND ID VALUES

Underlying the Notepad++ menu system (and any other Win32-API-based application), there are individual
command IDs for each menu command.  Notepad++ gives accesss through the NPPM_MENUCOMMAND message, and
L<notepad-E<gt>menuCommand()|Win32::Mechanize::NotepadPlusPlus::Notepad/menuCommand> allows you to
activate any menu entry's command by its menu ID.

You can find out the names and values of all the messages using:

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    printf "%-40s => %s\n", $_, $NPPIDM{$_} for sort keys %NPPIDM;

=over

=item %NPPIDM

    # both of the next two are equivalent to notepad->close(), but using the command ID for File > Close
    notepad->menuCommand( $NPPIDM{IDM_FILE_CLOSE} );
    notepad->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_FILE_CLOSE} );

=item DEPRECATED %nppidm

Deprecated name for %NPPIDM.  This variable no longer exists.  If you were using it, replace
it with %NPPIDM.

=back

=cut

our %NPPIDM = (
    'WM_USER'                                                    => 1024,
    'IDM'                                                        => 40000,
    'IDM_ABOUT'                                                  => (40000  + 7000),
    'IDM_CLEAN_RECENT_FILE_LIST'                                 => ((40000 + 2000) + 41),
    'IDM_CMDLINEARGUMENTS'                                       => ((40000  + 7000)  + 10),
    'IDM_CONFUPDATERPROXY'                                       => ((40000  + 7000)  + 9),
    'IDM_DEBUGINFO'                                              => ((40000  + 7000)  + 12),
    'IDM_EDIT'                                                   => (40000 + 2000),
    'IDM_EDIT_AUTOCOMPLETE'                                      => (50000 + 0),
    'IDM_EDIT_AUTOCOMPLETE_CURRENTFILE'                          => (50000 + 1),
    'IDM_EDIT_AUTOCOMPLETE_PATH'                                 => (50000 + 6),
    'IDM_EDIT_BEGINENDSELECT'                                    => ((40000 + 2000) + 20),
    'IDM_EDIT_BLANKLINEABOVECURRENT'                             => ((40000 + 2000) + 57),
    'IDM_EDIT_BLANKLINEBELOWCURRENT'                             => ((40000 + 2000) + 58),
    'IDM_EDIT_BLOCK_COMMENT'                                     => ((40000 + 2000) + 22),
    'IDM_EDIT_BLOCK_COMMENT_SET'                                 => ((40000 + 2000) + 35),
    'IDM_EDIT_BLOCK_UNCOMMENT'                                   => ((40000 + 2000) + 36),
    'IDM_EDIT_CHANGESEARCHENGINE'                                => ((40000 + 2000) + 76),
    'IDM_EDIT_CHAR_PANEL'                                        => ((40000 + 2000) + 51),
    'IDM_EDIT_CLEARREADONLY'                                     => ((40000 + 2000) + 33),
    'IDM_EDIT_CLIPBOARDHISTORY_PANEL'                            => ((40000 + 2000) + 52),
    'IDM_EDIT_COLUMNMODE'                                        => ((40000 + 2000) + 34),
    'IDM_EDIT_COLUMNMODETIP'                                     => ((40000 + 2000) + 37),
    'IDM_EDIT_COPY'                                              => ((40000 + 2000) + 2),
    'IDM_EDIT_COPY_BINARY'                                       => ((40000 + 2000) + 48),
    'IDM_EDIT_COPY_LINK'                                         => ((40000 + 2000) + 82),  # v7.9.2
    'IDM_EDIT_CURRENTDIRTOCLIP'                                  => ((40000 + 2000) + 31),
    'IDM_EDIT_CUT'                                               => ((40000 + 2000) + 1),
    'IDM_EDIT_CUT_BINARY'                                        => ((40000 + 2000) + 49),
    'IDM_EDIT_DELETE'                                            => ((40000 + 2000) + 6),
    'IDM_EDIT_DUP_LINE'                                          => ((40000 + 2000) + 10),
    'IDM_EDIT_EOL2WS'                                            => ((40000 + 2000) + 44),
    'IDM_EDIT_FILENAMETOCLIP'                                    => ((40000 + 2000) + 30),
    'IDM_EDIT_FULLPATHTOCLIP'                                    => ((40000 + 2000) + 29),
    'IDM_EDIT_FUNCCALLTIP'                                       => (50000 + 2),
    'IDM_EDIT_INS_TAB'                                           => ((40000 + 2000) + 8),
    'IDM_EDIT_INVERTCASE'                                        => ((40000 + 2000) + 71),
    'IDM_EDIT_JOIN_LINES'                                        => ((40000 + 2000) + 13),
    'IDM_EDIT_LINE_DOWN'                                         => ((40000 + 2000) + 15),
    'IDM_EDIT_LINE_UP'                                           => ((40000 + 2000) + 14),
    'IDM_EDIT_LOWERCASE'                                         => ((40000 + 2000) + 17),
    'IDM_EDIT_LTR'                                               => ((40000 + 2000) + 27),
    'IDM_EDIT_OPENASFILE'                                        => ((40000 + 2000) + 73),
    'IDM_EDIT_OPENINFOLDER'                                      => ((40000 + 2000) + 74),
    'IDM_EDIT_PASTE'                                             => ((40000 + 2000) + 5),
    'IDM_EDIT_PASTE_AS_HTML'                                     => ((40000 + 2000) + 38),
    'IDM_EDIT_PASTE_AS_RTF'                                      => ((40000 + 2000) + 39),
    'IDM_EDIT_PASTE_BINARY'                                      => ((40000 + 2000) + 50),
    'IDM_EDIT_PROPERCASE_BLEND'                                  => ((40000 + 2000) + 68),
    'IDM_EDIT_PROPERCASE_FORCE'                                  => ((40000 + 2000) + 67),
    'IDM_EDIT_RANDOMCASE'                                        => ((40000 + 2000) + 72),
    'IDM_EDIT_REDO'                                              => ((40000 + 2000) + 4),
    'IDM_EDIT_REMOVEEMPTYLINES'                                  => ((40000 + 2000) + 55),
    'IDM_EDIT_REMOVEEMPTYLINESWITHBLANK'                         => ((40000 + 2000) + 56),
    #'IDM_EDIT_REMOVE_DUP_LINES'                                  => ((40000 + 2000) + 77), # renamed to IDM_EDIT_REMOVE_CONSECUTIVE_DUP_LINES in v7.9.1
    'IDM_EDIT_REMOVE_CONSECUTIVE_DUP_LINES'                      => ((40000 + 2000) + 77), # renamed v7.9.1
    'IDM_EDIT_REMOVE_ANY_DUP_LINES'                              => ((40000 + 2000) + 79), # added v7.9.1
    'IDM_EDIT_RMV_TAB'                                           => ((40000 + 2000) + 9),
    'IDM_EDIT_RTL'                                               => ((40000 + 2000) + 26),
    'IDM_EDIT_SEARCHONINTERNET'                                  => ((40000 + 2000) + 75),
    'IDM_EDIT_SELECTALL'                                         => ((40000 + 2000) + 7),
    'IDM_EDIT_SENTENCECASE_BLEND'                                => ((40000 + 2000) + 70),
    'IDM_EDIT_SENTENCECASE_FORCE'                                => ((40000 + 2000) + 69),
    'IDM_EDIT_SETREADONLY'                                       => ((40000 + 2000) + 28),
    'IDM_EDIT_SORTLINES_DECIMALCOMMA_ASCENDING'                  => ((40000 + 2000) + 63),
    'IDM_EDIT_SORTLINES_DECIMALCOMMA_DESCENDING'                 => ((40000 + 2000) + 64),
    'IDM_EDIT_SORTLINES_DECIMALDOT_ASCENDING'                    => ((40000 + 2000) + 65),
    'IDM_EDIT_SORTLINES_DECIMALDOT_DESCENDING'                   => ((40000 + 2000) + 66),
    'IDM_EDIT_SORTLINES_INTEGER_ASCENDING'                       => ((40000 + 2000) + 61),
    'IDM_EDIT_SORTLINES_INTEGER_DESCENDING'                      => ((40000 + 2000) + 62),
    'IDM_EDIT_SORTLINES_LEXICOGRAPHIC_ASCENDING'                 => ((40000 + 2000) + 59),
    'IDM_EDIT_SORTLINES_LEXICOGRAPHIC_DESCENDING'                => ((40000 + 2000) + 60),
    'IDM_EDIT_SORTLINES_LEXICO_CASE_INSENS_ASCENDING'            => ((40000 + 2000) + 80), # added v7.9.1
    'IDM_EDIT_SORTLINES_LEXICO_CASE_INSENS_DESCENDING'           => ((40000 + 2000) + 81), # added v7.9.1
    'IDM_EDIT_SORTLINES_RANDOMLY'                                => ((40000 + 2000) + 78), # added v7.9.1
    'IDM_EDIT_SPLIT_LINES'                                       => ((40000 + 2000) + 12),
    'IDM_EDIT_STREAM_COMMENT'                                    => ((40000 + 2000) + 23),
    'IDM_EDIT_STREAM_UNCOMMENT'                                  => ((40000 + 2000) + 47),
    'IDM_EDIT_SW2TAB_ALL'                                        => ((40000 + 2000) + 54),
    'IDM_EDIT_SW2TAB_LEADING'                                    => ((40000 + 2000) + 53),
    'IDM_EDIT_TAB2SW'                                            => ((40000 + 2000) + 46),
    'IDM_EDIT_TRANSPOSE_LINE'                                    => ((40000 + 2000) + 11),
    'IDM_EDIT_TRIMALL'                                           => ((40000 + 2000) + 45),
    'IDM_EDIT_TRIMLINEHEAD'                                      => ((40000 + 2000) + 42),
    'IDM_EDIT_TRIMTRAILING'                                      => ((40000 + 2000) + 24),
    'IDM_EDIT_TRIM_BOTH'                                         => ((40000 + 2000) + 43),
    'IDM_EDIT_UNDO'                                              => ((40000 + 2000) + 3),
    'IDM_EDIT_UPPERCASE'                                         => ((40000 + 2000) + 16),
    'IDM_EXECUTE'                                                => (40000 + 9000),
    'IDM_EXPORT_FUNC_LIST_AND_QUIT'                              => ((40000 + 4000) + 73),
    'IDM_FILE'                                                   => (40000 + 1000),
    'IDM_FILEMENU_EXISTCMDPOSITION'                              => 22,
    'IDM_FILEMENU_LASTONE'                                       => ((40000 + 1000) + 25), # updated v7.9.1
    'IDM_FILESWITCHER_FILESCLOSE'                                => ((40000 + 3500) + 1),
    'IDM_FILESWITCHER_FILESCLOSEOTHERS'                          => ((40000 + 3500) + 2),
    'IDM_FILE_CLOSE'                                             => ((40000 + 1000) + 3),
    'IDM_FILE_CLOSEALL'                                          => ((40000 + 1000) + 4),
    'IDM_FILE_CLOSEALL_BUT_CURRENT'                              => ((40000 + 1000) + 5),
    'IDM_FILE_CLOSEALL_TOLEFT'                                   => ((40000 + 1000) + 9),
    'IDM_FILE_CLOSEALL_TORIGHT'                                  => ((40000 + 1000) + 18),
    'IDM_FILE_CLOSEALL_UNCHANGED'                                => ((40000 + 1000) + 24),
    'IDM_FILE_CONTAININGFOLDERASWORKSPACE'                       => ((40000 + 1000) + 25), # added v7.9.1
    'IDM_FILE_DELETE'                                            => ((40000 + 1000) + 16),
    'IDM_FILE_EXIT'                                              => ((40000 + 1000) + 11),
    'IDM_FILE_LOADSESSION'                                       => ((40000 + 1000) + 12),
    'IDM_FILE_NEW'                                               => ((40000 + 1000) + 1),
    'IDM_FILE_OPEN'                                              => ((40000 + 1000) + 2),
    'IDM_FILE_OPENFOLDERASWORSPACE'                              => ((40000 + 1000) + 22),
    'IDM_FILE_OPEN_CMD'                                          => ((40000 + 1000) + 20),
    'IDM_FILE_OPEN_DEFAULT_VIEWER'                               => ((40000 + 1000) + 23),
    'IDM_FILE_OPEN_FOLDER'                                       => ((40000 + 1000) + 19),
    'IDM_FILE_PRINT'                                             => ((40000 + 1000) + 10),
    'IDM_FILE_PRINTNOW'                                          => 1001,
    'IDM_FILE_RELOAD'                                            => ((40000 + 1000) + 14),
    'IDM_FILE_RENAME'                                            => ((40000 + 1000) + 17),
    'IDM_FILE_RESTORELASTCLOSEDFILE'                             => ((40000 + 1000) + 21),
    'IDM_FILE_SAVE'                                              => ((40000 + 1000) + 6),
    'IDM_FILE_SAVEALL'                                           => ((40000 + 1000) + 7),
    'IDM_FILE_SAVEAS'                                            => ((40000 + 1000) + 8),
    'IDM_FILE_SAVECOPYAS'                                        => ((40000 + 1000) + 15),
    'IDM_FILE_SAVESESSION'                                       => ((40000 + 1000) + 13),
    'IDM_FOCUS_ON_FOUND_RESULTS'                                 => ((40000 + 3000) + 45),
    'IDM_FORMAT'                                                 => (40000 + 5000),
    'IDM_FORMAT_ANSI'                                            => ((40000 + 5000) + 4),
    'IDM_FORMAT_AS_UTF_8'                                        => ((40000 + 5000) + 8),
    'IDM_FORMAT_BIG5'                                            => (((40000 + 5000) + 20) + 40),
    'IDM_FORMAT_CONV2_ANSI'                                      => ((40000 + 5000) + 9),
    'IDM_FORMAT_CONV2_AS_UTF_8'                                  => ((40000 + 5000) + 10),
    'IDM_FORMAT_CONV2_UCS_2BE'                                   => ((40000 + 5000) + 12),
    'IDM_FORMAT_CONV2_UCS_2LE'                                   => ((40000 + 5000) + 13),
    'IDM_FORMAT_CONV2_UTF_8'                                     => ((40000 + 5000) + 11),
    'IDM_FORMAT_DOS_437'                                         => (((40000 + 5000) + 20) + 24),
    'IDM_FORMAT_DOS_720'                                         => (((40000 + 5000) + 20) + 25),
    'IDM_FORMAT_DOS_737'                                         => (((40000 + 5000) + 20) + 26),
    'IDM_FORMAT_DOS_775'                                         => (((40000 + 5000) + 20) + 27),
    'IDM_FORMAT_DOS_850'                                         => (((40000 + 5000) + 20) + 28),
    'IDM_FORMAT_DOS_852'                                         => (((40000 + 5000) + 20) + 29),
    'IDM_FORMAT_DOS_855'                                         => (((40000 + 5000) + 20) + 30),
    'IDM_FORMAT_DOS_857'                                         => (((40000 + 5000) + 20) + 31),
    'IDM_FORMAT_DOS_858'                                         => (((40000 + 5000) + 20) + 32),
    'IDM_FORMAT_DOS_860'                                         => (((40000 + 5000) + 20) + 33),
    'IDM_FORMAT_DOS_861'                                         => (((40000 + 5000) + 20) + 34),
    'IDM_FORMAT_DOS_862'                                         => (((40000 + 5000) + 20) + 35),
    'IDM_FORMAT_DOS_863'                                         => (((40000 + 5000) + 20) + 36),
    'IDM_FORMAT_DOS_865'                                         => (((40000 + 5000) + 20) + 37),
    'IDM_FORMAT_DOS_866'                                         => (((40000 + 5000) + 20) + 38),
    'IDM_FORMAT_DOS_869'                                         => (((40000 + 5000) + 20) + 39),
    'IDM_FORMAT_ENCODE'                                          => ((40000 + 5000) + 20),
    'IDM_FORMAT_ENCODE_END'                                      => (((40000 + 5000) + 20) + 48),
    'IDM_FORMAT_EUC_KR'                                          => (((40000 + 5000) + 20) + 44),
    'IDM_FORMAT_GB2312'                                          => (((40000 + 5000) + 20) + 41),
    'IDM_FORMAT_ISO_8859_1'                                      => (((40000 + 5000) + 20) + 9),
    'IDM_FORMAT_ISO_8859_13'                                     => (((40000 + 5000) + 20) + 20),
    'IDM_FORMAT_ISO_8859_14'                                     => (((40000 + 5000) + 20) + 21),
    'IDM_FORMAT_ISO_8859_15'                                     => (((40000 + 5000) + 20) + 22),
    'IDM_FORMAT_ISO_8859_2'                                      => (((40000 + 5000) + 20) + 10),
    'IDM_FORMAT_ISO_8859_3'                                      => (((40000 + 5000) + 20) + 11),
    'IDM_FORMAT_ISO_8859_4'                                      => (((40000 + 5000) + 20) + 12),
    'IDM_FORMAT_ISO_8859_5'                                      => (((40000 + 5000) + 20) + 13),
    'IDM_FORMAT_ISO_8859_6'                                      => (((40000 + 5000) + 20) + 14),
    'IDM_FORMAT_ISO_8859_7'                                      => (((40000 + 5000) + 20) + 15),
    'IDM_FORMAT_ISO_8859_8'                                      => (((40000 + 5000) + 20) + 16),
    'IDM_FORMAT_ISO_8859_9'                                      => (((40000 + 5000) + 20) + 17),
    'IDM_FORMAT_KOI8R_CYRILLIC'                                  => (((40000 + 5000) + 20) + 48),
    'IDM_FORMAT_KOI8U_CYRILLIC'                                  => (((40000 + 5000) + 20) + 47),
    'IDM_FORMAT_KOREAN_WIN'                                      => (((40000 + 5000) + 20) + 43),
    'IDM_FORMAT_MAC_CYRILLIC'                                    => (((40000 + 5000) + 20) + 46),
    'IDM_FORMAT_SHIFT_JIS'                                       => (((40000 + 5000) + 20) + 42),
    'IDM_FORMAT_TIS_620'                                         => (((40000 + 5000) + 20) + 45),
    'IDM_FORMAT_TODOS'                                           => ((40000 + 5000) + 1),
    'IDM_FORMAT_TOMAC'                                           => ((40000 + 5000) + 3),
    'IDM_FORMAT_TOUNIX'                                          => ((40000 + 5000) + 2),
    'IDM_FORMAT_UCS_2BE'                                         => ((40000 + 5000) + 6),
    'IDM_FORMAT_UCS_2LE'                                         => ((40000 + 5000) + 7),
    'IDM_FORMAT_UTF_8'                                           => ((40000 + 5000) + 5),
    'IDM_FORMAT_WIN_1250'                                        => (((40000 + 5000) + 20) + 0),
    'IDM_FORMAT_WIN_1251'                                        => (((40000 + 5000) + 20) + 1),
    'IDM_FORMAT_WIN_1252'                                        => (((40000 + 5000) + 20) + 2),
    'IDM_FORMAT_WIN_1253'                                        => (((40000 + 5000) + 20) + 3),
    'IDM_FORMAT_WIN_1254'                                        => (((40000 + 5000) + 20) + 4),
    'IDM_FORMAT_WIN_1255'                                        => (((40000 + 5000) + 20) + 5),
    'IDM_FORMAT_WIN_1256'                                        => (((40000 + 5000) + 20) + 6),
    'IDM_FORMAT_WIN_1257'                                        => (((40000 + 5000) + 20) + 7),
    'IDM_FORMAT_WIN_1258'                                        => (((40000 + 5000) + 20) + 8),
    'IDM_FORUM'                                                  => ((40000  + 7000)  + 4),
    'IDM_HELP'                                                   => ((40000  + 7000)  + 8),
    'IDM_HOMESWEETHOME'                                          => ((40000  + 7000)  + 1),
    'IDM_LANG'                                                   => (40000 + 6000),
    'IDM_LANGSTYLE_CONFIG_DLG'                                   => ((40000 + 6000) + 1),
    'IDM_LANG_ADA'                                               => ((40000 + 6000) + 42),
    'IDM_LANG_ASCII'                                             => ((40000 + 6000) + 15),
    'IDM_LANG_ASM'                                               => ((40000 + 6000) + 33),
    'IDM_LANG_ASN1'                                              => ((40000 + 6000) + 64),
    'IDM_LANG_ASP'                                               => ((40000 + 6000) + 9),
    'IDM_LANG_AU3'                                               => ((40000 + 6000) + 44),
    'IDM_LANG_AVS'                                               => ((40000 + 6000) + 65),
    'IDM_LANG_BAANC'                                             => ((40000 + 6000) + 59),
    'IDM_LANG_BASH'                                              => ((40000 + 6000) + 27),
    'IDM_LANG_BATCH'                                             => ((40000 + 6000) + 22),
    'IDM_LANG_BLITZBASIC'                                        => ((40000 + 6000) + 66),
    'IDM_LANG_C'                                                 => ((40000 + 6000) + 2),
    'IDM_LANG_CAML'                                              => ((40000 + 6000) + 40),
    'IDM_LANG_CMAKE'                                             => ((40000 + 6000) + 48),
    'IDM_LANG_COBOL'                                             => ((40000 + 6000) + 50),
    'IDM_LANG_COFFEESCRIPT'                                      => ((40000 + 6000) + 56),
    'IDM_LANG_CPP'                                               => ((40000 + 6000) + 3),
    'IDM_LANG_CS'                                                => ((40000 + 6000) + 23),
    'IDM_LANG_CSOUND'                                            => ((40000 + 6000) + 69),
    'IDM_LANG_CSS'                                               => ((40000 + 6000) + 10),
    'IDM_LANG_D'                                                 => ((40000 + 6000) + 51),
    'IDM_LANG_DIFF'                                              => ((40000 + 6000) + 34),
    'IDM_LANG_ERLANG'                                            => ((40000 + 6000) + 70),
    'IDM_LANG_ESCRIPT'                                           => ((40000 + 6000) + 71),
    'IDM_LANG_EXTERNAL'                                          => ((40000 + 6000) + 165),
    'IDM_LANG_EXTERNAL_LIMIT'                                    => ((40000 + 6000) + 179),
    'IDM_LANG_FLASH'                                             => ((40000 + 6000) + 28),
    'IDM_LANG_FORTH'                                             => ((40000 + 6000) + 72),
    'IDM_LANG_FORTRAN'                                           => ((40000 + 6000) + 26),
    'IDM_LANG_FORTRAN_77'                                        => ((40000 + 6000) + 58),
    'IDM_LANG_FREEBASIC'                                         => ((40000 + 6000) + 68),
    'IDM_LANG_GUI4CLI'                                           => ((40000 + 6000) + 52),
    'IDM_LANG_HASKELL'                                           => ((40000 + 6000) + 46),
    'IDM_LANG_HTML'                                              => ((40000 + 6000) + 5),
    'IDM_LANG_IHEX'                                              => ((40000 + 6000) + 61),
    'IDM_LANG_INI'                                               => ((40000 + 6000) + 19),
    'IDM_LANG_INNO'                                              => ((40000 + 6000) + 47),
    'IDM_LANG_JAVA'                                              => ((40000 + 6000) + 4),
    'IDM_LANG_JS'                                                => ((40000 + 6000) + 7),
    'IDM_LANG_JSON'                                              => ((40000 + 6000) + 57),
    'IDM_LANG_JSP'                                               => ((40000 + 6000) + 55),
    'IDM_LANG_KIX'                                               => ((40000 + 6000) + 41),
    'IDM_LANG_LATEX'                                             => ((40000 + 6000) + 73),
    'IDM_LANG_LISP'                                              => ((40000 + 6000) + 31),
    'IDM_LANG_LUA'                                               => ((40000 + 6000) + 24),
    'IDM_LANG_MAKEFILE'                                          => ((40000 + 6000) + 18),
    'IDM_LANG_MATLAB'                                            => ((40000 + 6000) + 45),
    'IDM_LANG_MMIXAL'                                            => ((40000 + 6000) + 74),
    'IDM_LANG_NIMROD'                                            => ((40000 + 6000) + 75),
    'IDM_LANG_NNCRONTAB'                                         => ((40000 + 6000) + 76),
    'IDM_LANG_NSIS'                                              => ((40000 + 6000) + 29),
    'IDM_LANG_OBJC'                                              => ((40000 + 6000) + 14),
    'IDM_LANG_OPENUDLDIR'                                        => ((40000 + 6000) + 300),
    'IDM_LANG_OSCRIPT'                                           => ((40000 + 6000) + 77),
    'IDM_LANG_PASCAL'                                            => ((40000 + 6000) + 11),
    'IDM_LANG_PERL'                                              => ((40000 + 6000) + 13),
    'IDM_LANG_PHP'                                               => ((40000 + 6000) + 8),
    'IDM_LANG_POWERSHELL'                                        => ((40000 + 6000) + 53),
    'IDM_LANG_PROPS'                                             => ((40000 + 6000) + 35),
    'IDM_LANG_PS'                                                => ((40000 + 6000) + 36),
    'IDM_LANG_PUREBASIC'                                         => ((40000 + 6000) + 67),
    'IDM_LANG_PYTHON'                                            => ((40000 + 6000) + 12),
    'IDM_LANG_R'                                                 => ((40000 + 6000) + 54),
    'IDM_LANG_RC'                                                => ((40000 + 6000) + 17),
    'IDM_LANG_REBOL'                                             => ((40000 + 6000) + 78),
    'IDM_LANG_REGISTRY'                                          => ((40000 + 6000) + 79),
    'IDM_LANG_RUBY'                                              => ((40000 + 6000) + 37),
    'IDM_LANG_RUST'                                              => ((40000 + 6000) + 80),
    'IDM_LANG_SCHEME'                                            => ((40000 + 6000) + 32),
    'IDM_LANG_SMALLTALK'                                         => ((40000 + 6000) + 38),
    'IDM_LANG_SPICE'                                             => ((40000 + 6000) + 81),
    'IDM_LANG_SQL'                                               => ((40000 + 6000) + 20),
    'IDM_LANG_SREC'                                              => ((40000 + 6000) + 60),
    'IDM_LANG_SWIFT'                                             => ((40000 + 6000) + 63),
    'IDM_LANG_TCL'                                               => ((40000 + 6000) + 30),
    'IDM_LANG_TEHEX'                                             => ((40000 + 6000) + 62),
    'IDM_LANG_TEX'                                               => ((40000 + 6000) + 25),
    'IDM_LANG_TEXT'                                              => ((40000 + 6000) + 16),
    'IDM_LANG_TXT2TAGS'                                          => ((40000 + 6000) + 82),
    'IDM_LANG_USER'                                              => ((40000 + 6000) + 180),
    'IDM_LANG_USER_DLG'                                          => ((40000 + 6000) + 250),
    'IDM_LANG_USER_LIMIT'                                        => ((40000 + 6000) + 210),
    'IDM_LANG_VB'                                                => ((40000 + 6000) + 21),
    'IDM_LANG_VERILOG'                                           => ((40000 + 6000) + 43),
    'IDM_LANG_VHDL'                                              => ((40000 + 6000) + 39),
    'IDM_LANG_VISUALPROLOG'                                      => ((40000 + 6000) + 83),
    'IDM_LANG_XML'                                               => ((40000 + 6000) + 6),
    'IDM_LANG_YAML'                                              => ((40000 + 6000) + 49),
    'IDM_MACRO_PLAYBACKRECORDEDMACRO'                            => ((40000 + 2000) + 21),
    'IDM_MACRO_RUNMULTIMACRODLG'                                 => ((40000 + 2000) + 32),
    'IDM_MACRO_SAVECURRENTMACRO'                                 => ((40000 + 2000) + 25),
    'IDM_MACRO_STARTRECORDINGMACRO'                              => ((40000 + 2000) + 18),
    'IDM_MACRO_STOPRECORDINGMACRO'                               => ((40000 + 2000) + 19),
    'IDM_MISC'                                                   => (40000 + 3500),
    'IDM_ONLINEDOCUMENT'                                         => ((40000  + 7000)  + 3),     # new name (v7.8 and newer)
    'IDM_ONLINEHELP'                                             => ((40000  + 7000)  + 3),     # old name (before v7.8)
    'IDM_ONLINESUPPORT'                                          => ((40000  + 7000)  + 11),
    'IDM_OPEN_ALL_RECENT_FILE'                                   => ((40000 + 2000) + 40),
    'IDM_PROJECTPAGE'                                            => ((40000  + 7000)  + 2),
    'IDM_SEARCH'                                                 => (40000 + 3000),
    'IDM_SEARCH_ALLSTYLESTOCLIP'                                 => ((40000 + 3000) + 60), # v7.9.1
    'IDM_SEARCH_CLEARALLMARKS'                                   => ((40000 + 3000) + 32),
    'IDM_SEARCH_CLEAR_BOOKMARKS'                                 => ((40000 + 3000) + 8),
    'IDM_SEARCH_COPYMARKEDLINES'                                 => ((40000 + 3000) + 19),
    'IDM_SEARCH_CUTMARKEDLINES'                                  => ((40000 + 3000) + 18),
    'IDM_SEARCH_DELETEMARKEDLINES'                               => ((40000 + 3000) + 21),
    'IDM_SEARCH_DELETEUNMARKEDLINES'                             => ((40000 + 3000) + 51),
    'IDM_SEARCH_FIND'                                            => ((40000 + 3000) + 1),
    'IDM_SEARCH_FINDCHARINRANGE'                                 => ((40000 + 3000) + 52),
    'IDM_SEARCH_FINDINCREMENT'                                   => ((40000 + 3000) + 11),
    'IDM_SEARCH_FINDINFILES'                                     => ((40000 + 3000) + 13),
    'IDM_SEARCH_FINDNEXT'                                        => ((40000 + 3000) + 2),
    'IDM_SEARCH_FINDPREV'                                        => ((40000 + 3000) + 10),
    'IDM_SEARCH_GONEXTMARKER1'                                   => ((40000 + 3000) + 39),
    'IDM_SEARCH_GONEXTMARKER2'                                   => ((40000 + 3000) + 40),
    'IDM_SEARCH_GONEXTMARKER3'                                   => ((40000 + 3000) + 41),
    'IDM_SEARCH_GONEXTMARKER4'                                   => ((40000 + 3000) + 42),
    'IDM_SEARCH_GONEXTMARKER5'                                   => ((40000 + 3000) + 43),
    'IDM_SEARCH_GONEXTMARKER_DEF'                                => ((40000 + 3000) + 44),
    'IDM_SEARCH_GOPREVMARKER1'                                   => ((40000 + 3000) + 33),
    'IDM_SEARCH_GOPREVMARKER2'                                   => ((40000 + 3000) + 34),
    'IDM_SEARCH_GOPREVMARKER3'                                   => ((40000 + 3000) + 35),
    'IDM_SEARCH_GOPREVMARKER4'                                   => ((40000 + 3000) + 36),
    'IDM_SEARCH_GOPREVMARKER5'                                   => ((40000 + 3000) + 37),
    'IDM_SEARCH_GOPREVMARKER_DEF'                                => ((40000 + 3000) + 38),
    'IDM_SEARCH_GOTOLINE'                                        => ((40000 + 3000) + 4),
    'IDM_SEARCH_GOTOMATCHINGBRACE'                               => ((40000 + 3000) + 9),
    'IDM_SEARCH_GOTONEXTFOUND'                                   => ((40000 + 3000) + 46),
    'IDM_SEARCH_GOTOPREVFOUND'                                   => ((40000 + 3000) + 47),
    'IDM_SEARCH_INVERSEMARKS'                                    => ((40000 + 3000) + 50),
    'IDM_SEARCH_MARK'                                            => ((40000 + 3000) + 54),
    'IDM_SEARCH_MARKALLEXT1'                                     => ((40000 + 3000) + 22),
    'IDM_SEARCH_MARKALLEXT2'                                     => ((40000 + 3000) + 24),
    'IDM_SEARCH_MARKALLEXT3'                                     => ((40000 + 3000) + 26),
    'IDM_SEARCH_MARKALLEXT4'                                     => ((40000 + 3000) + 28),
    'IDM_SEARCH_MARKALLEXT5'                                     => ((40000 + 3000) + 30),
    'IDM_SEARCH_MARKEDTOCLIP'                                    => ((40000 + 3000) + 61), # v7.9.1
    'IDM_SEARCH_NEXT_BOOKMARK'                                   => ((40000 + 3000) + 6),
    'IDM_SEARCH_PASTEMARKEDLINES'                                => ((40000 + 3000) + 20),
    'IDM_SEARCH_PREV_BOOKMARK'                                   => ((40000 + 3000) + 7),
    'IDM_SEARCH_REPLACE'                                         => ((40000 + 3000) + 3),
    'IDM_SEARCH_SELECTMATCHINGBRACES'                            => ((40000 + 3000) + 53),
    'IDM_SEARCH_SETANDFINDNEXT'                                  => ((40000 + 3000) + 48),
    'IDM_SEARCH_SETANDFINDPREV'                                  => ((40000 + 3000) + 49),
    'IDM_SEARCH_STYLE1TOCLIP'                                    => ((40000 + 3000) + 55), # v7.9.1
    'IDM_SEARCH_STYLE2TOCLIP'                                    => ((40000 + 3000) + 56), # v7.9.1
    'IDM_SEARCH_STYLE3TOCLIP'                                    => ((40000 + 3000) + 57), # v7.9.1
    'IDM_SEARCH_STYLE4TOCLIP'                                    => ((40000 + 3000) + 58), # v7.9.1
    'IDM_SEARCH_STYLE5TOCLIP'                                    => ((40000 + 3000) + 59), # v7.9.1
    'IDM_SEARCH_TOGGLE_BOOKMARK'                                 => ((40000 + 3000) + 5),
    'IDM_SEARCH_UNMARKALLEXT1'                                   => ((40000 + 3000) + 23),
    'IDM_SEARCH_UNMARKALLEXT2'                                   => ((40000 + 3000) + 25),
    'IDM_SEARCH_UNMARKALLEXT3'                                   => ((40000 + 3000) + 27),
    'IDM_SEARCH_UNMARKALLEXT4'                                   => ((40000 + 3000) + 29),
    'IDM_SEARCH_UNMARKALLEXT5'                                   => ((40000 + 3000) + 31),
    'IDM_SEARCH_VOLATILE_FINDNEXT'                               => ((40000 + 3000) + 14),
    'IDM_SEARCH_VOLATILE_FINDPREV'                               => ((40000 + 3000) + 15),
    'IDM_SETTING'                                                => (40000 + 8000),
    'IDM_SETTING_EDITCONTEXTMENU'                                => ((40000 + 8000) + 18),
    'IDM_SETTING_IMPORTPLUGIN'                                   => ((40000 + 8000) + 5),
    'IDM_SETTING_IMPORTSTYLETHEMS'                               => ((40000 + 8000) + 6),
    'IDM_SETTING_OPENPLUGINSDIR'                                 => ((40000 + 8000) + 14),
    'IDM_SETTING_PLUGINADM'                                      => ((40000 + 8000) + 15),
    'IDM_SETTING_PREFERENCE'                                     => ((40000 + 8000) + 11),
    'IDM_SETTING_REMEMBER_LAST_SESSION'                          => ((40000 + 8000) + 10),
    'IDM_SETTING_SHORTCUT_MAPPER'                                => ((40000 + 8000) + 9),
    'IDM_SETTING_SHORTCUT_MAPPER_MACRO'                          => ((40000 + 8000) + 16),
    'IDM_SETTING_SHORTCUT_MAPPER_RUN'                            => ((40000 + 8000) + 17),
    'IDM_SETTING_TRAYICON'                                       => ((40000 + 8000) + 8),
    'IDM_SYSTRAYPOPUP'                                           => (40000 + 3100),
    'IDM_SYSTRAYPOPUP_ACTIVATE'                                  => ((40000 + 3100) + 1),
    'IDM_SYSTRAYPOPUP_CLOSE'                                     => ((40000 + 3100) + 5),
    'IDM_SYSTRAYPOPUP_NEWDOC'                                    => ((40000 + 3100) + 2),
    'IDM_SYSTRAYPOPUP_NEW_AND_PASTE'                             => ((40000 + 3100) + 3),
    'IDM_SYSTRAYPOPUP_OPENFILE'                                  => ((40000 + 3100) + 4),
    'IDM_TOOL'                                                   => (40000 + 8500),
    'IDM_TOOL_MD5_GENERATE'                                      => ((40000 + 8500) + 1),
    'IDM_TOOL_MD5_GENERATEFROMFILE'                              => ((40000 + 8500) + 2),
    'IDM_TOOL_MD5_GENERATEINTOCLIPBOARD'                         => ((40000 + 8500) + 3),
    'IDM_TOOL_SHA256_GENERATE'                                   => ((40000 + 8500) + 4),
    'IDM_TOOL_SHA256_GENERATEFROMFILE'                           => ((40000 + 8500) + 5),
    'IDM_TOOL_SHA256_GENERATEINTOCLIPBOARD'                      => ((40000 + 8500) + 6),
    'IDM_UPDATE_NPP'                                             => ((40000  + 7000)  + 6),
    'IDM_VIEW'                                                   => (40000 + 4000),
    'IDM_VIEW_ALL_CHARACTERS'                                    => ((40000 + 4000) + 19),
    'IDM_VIEW_ALWAYSONTOP'                                       => ((40000 + 4000) + 34),
    'IDM_VIEW_CLONE_TO_ANOTHER_VIEW'                             => 10002,
    'IDM_VIEW_CURLINE_HILITING'                                  => ((40000 + 4000) + 21),
    'IDM_VIEW_DOCCHANGEMARGIN'                                   => ((40000 + 4000) + 45),
    'IDM_VIEW_DOC_MAP'                                           => ((40000 + 4000) + 80),
    'IDM_VIEW_DRAWTABBAR_CLOSEBOTTUN'                            => ((40000 + 4000) + 38),
    'IDM_VIEW_DRAWTABBAR_DBCLK2CLOSE'                            => ((40000 + 4000) + 39),
    'IDM_VIEW_DRAWTABBAR_INACIVETAB'                             => ((40000 + 4000) + 8),
    'IDM_VIEW_DRAWTABBAR_MULTILINE'                              => ((40000 + 4000) + 44),
    'IDM_VIEW_DRAWTABBAR_TOPBAR'                                 => ((40000 + 4000) + 7),
    'IDM_VIEW_DRAWTABBAR_VERTICAL'                               => ((40000 + 4000) + 43),
    'IDM_VIEW_EDGEBACKGROUND'                                    => ((40000 + 4000) + 28), # removed v7.9.x
    'IDM_VIEW_EDGELINE'                                          => ((40000 + 4000) + 27), # removed v7.9.x
    'IDM_VIEW_EDGENONE'                                          => ((40000 + 4000) + 37), # removed v7.9.x
    'IDM_VIEW_EOL'                                               => ((40000 + 4000) + 26),
    'IDM_VIEW_FILEBROWSER'                                       => ((40000 + 4000) + 85),
    'IDM_VIEW_FILESWITCHER_PANEL'                                => ((40000 + 4000) + 70),
    'IDM_VIEW_FOLD'                                              => ((40000 + 4000) + 50),
    'IDM_VIEW_FOLDERMAGIN'                                       => ((40000 + 4000) + 14),
    'IDM_VIEW_FOLDERMAGIN_ARROW'                                 => ((40000 + 4000) + 16),
    'IDM_VIEW_FOLDERMAGIN_BOX'                                   => ((40000 + 4000) + 18),
    'IDM_VIEW_FOLDERMAGIN_CIRCLE'                                => ((40000 + 4000) + 17),
    'IDM_VIEW_FOLDERMAGIN_SIMPLE'                                => ((40000 + 4000) + 15),
    'IDM_VIEW_FOLD_1'                                            => (((40000 + 4000) + 50) + 1),
    'IDM_VIEW_FOLD_2'                                            => (((40000 + 4000) + 50) + 2),
    'IDM_VIEW_FOLD_3'                                            => (((40000 + 4000) + 50) + 3),
    'IDM_VIEW_FOLD_4'                                            => (((40000 + 4000) + 50) + 4),
    'IDM_VIEW_FOLD_5'                                            => (((40000 + 4000) + 50) + 5),
    'IDM_VIEW_FOLD_6'                                            => (((40000 + 4000) + 50) + 6),
    'IDM_VIEW_FOLD_7'                                            => (((40000 + 4000) + 50) + 7),
    'IDM_VIEW_FOLD_8'                                            => (((40000 + 4000) + 50) + 8),
    'IDM_VIEW_FOLD_CURRENT'                                      => ((40000 + 4000) + 30),
    'IDM_VIEW_FULLSCREENTOGGLE'                                  => ((40000 + 4000) + 32),
    'IDM_VIEW_FUNC_LIST'                                         => ((40000 + 4000) + 84),
    'IDM_VIEW_GOTO_ANOTHER_VIEW'                                 => 10001,
    'IDM_VIEW_GOTO_NEW_INSTANCE'                                 => 10003,
    'IDM_VIEW_HIDELINES'                                         => ((40000 + 4000) + 42),
    'IDM_VIEW_INDENT_GUIDE'                                      => ((40000 + 4000) + 20),
    'IDM_VIEW_IN_CHROME'                                         => ((40000 + 4000) + 101),
    'IDM_VIEW_IN_EDGE'                                           => ((40000 + 4000) + 102),
    'IDM_VIEW_IN_FIREFOX'                                        => ((40000 + 4000) + 100),
    'IDM_VIEW_IN_IE'                                             => ((40000 + 4000) + 103),
    'IDM_VIEW_LINENUMBER'                                        => ((40000 + 4000) + 12),
    'IDM_VIEW_LOAD_IN_NEW_INSTANCE'                              => 10004,
    'IDM_VIEW_LOCKTABBAR'                                        => ((40000 + 4000) + 6),
    'IDM_VIEW_LWALIGN'                                           => ((40000 + 4000) + 47),
    'IDM_VIEW_LWDEF'                                             => ((40000 + 4000) + 46),
    'IDM_VIEW_LWINDENT'                                          => ((40000 + 4000) + 48),
    'IDM_VIEW_MONITORING'                                        => ((40000 + 4000) + 97),
    'IDM_VIEW_POSTIT'                                            => ((40000 + 4000) + 9),
    'IDM_VIEW_PROJECT_PANEL_1'                                   => ((40000 + 4000) + 81),
    'IDM_VIEW_PROJECT_PANEL_2'                                   => ((40000 + 4000) + 82),
    'IDM_VIEW_PROJECT_PANEL_3'                                   => ((40000 + 4000) + 83),
    'IDM_VIEW_REDUCETABBAR'                                      => ((40000 + 4000) + 5),
    'IDM_VIEW_REFRESHTABAR'                                      => ((40000 + 4000) + 40),
    'IDM_VIEW_SUMMARY'                                           => ((40000 + 4000) + 49),
    'IDM_VIEW_SWITCHTO_FILEBROWSER'                              => ((40000 + 4000) + 107), # v7.9.1
    'IDM_VIEW_SWITCHTO_FUNC_LIST'                                => ((40000 + 4000) + 108), # v7.9.1
    'IDM_VIEW_SWITCHTO_OTHER_VIEW'                               => ((40000 + 4000) + 72),
    'IDM_VIEW_SWITCHTO_PROJECT_PANEL_1'                          => ((40000 + 4000) + 104), # v7.9.1
    'IDM_VIEW_SWITCHTO_PROJECT_PANEL_2'                          => ((40000 + 4000) + 105), # v7.9.1
    'IDM_VIEW_SWITCHTO_PROJECT_PANEL_3'                          => ((40000 + 4000) + 106), # v7.9.1
    'IDM_VIEW_SYMBOLMARGIN'                                      => ((40000 + 4000) + 13),
    'IDM_VIEW_SYNSCROLLH'                                        => ((40000 + 4000) + 36),
    'IDM_VIEW_SYNSCROLLV'                                        => ((40000 + 4000) + 35),
    'IDM_VIEW_TAB1'                                              => ((40000 + 4000) + 86),
    'IDM_VIEW_TAB2'                                              => ((40000 + 4000) + 87),
    'IDM_VIEW_TAB3'                                              => ((40000 + 4000) + 88),
    'IDM_VIEW_TAB4'                                              => ((40000 + 4000) + 89),
    'IDM_VIEW_TAB5'                                              => ((40000 + 4000) + 90),
    'IDM_VIEW_TAB6'                                              => ((40000 + 4000) + 91),
    'IDM_VIEW_TAB7'                                              => ((40000 + 4000) + 92),
    'IDM_VIEW_TAB8'                                              => ((40000 + 4000) + 93),
    'IDM_VIEW_TAB9'                                              => ((40000 + 4000) + 94),
    'IDM_VIEW_TAB_MOVEBACKWARD'                                  => ((40000 + 4000) + 99),
    'IDM_VIEW_TAB_MOVEFORWARD'                                   => ((40000 + 4000) + 98),
    'IDM_VIEW_TAB_NEXT'                                          => ((40000 + 4000) + 95),
    'IDM_VIEW_TAB_PREV'                                          => ((40000 + 4000) + 96),
    'IDM_VIEW_TAB_SPACE'                                         => ((40000 + 4000) + 25),
    'IDM_VIEW_TOGGLE_FOLDALL'                                    => ((40000 + 4000) + 10),
    'IDM_VIEW_TOGGLE_UNFOLDALL'                                  => ((40000 + 4000) + 29),
    'IDM_VIEW_TOOLBAR_ENLARGE'                                   => ((40000 + 4000) + 3),
    'IDM_VIEW_TOOLBAR_REDUCE'                                    => ((40000 + 4000) + 2),
    'IDM_VIEW_TOOLBAR_STANDARD'                                  => ((40000 + 4000) + 4),
    'IDM_VIEW_UNFOLD'                                            => ((40000 + 4000) + 60),
    'IDM_VIEW_UNFOLD_1'                                          => (((40000 + 4000) + 60) + 1),
    'IDM_VIEW_UNFOLD_2'                                          => (((40000 + 4000) + 60) + 2),
    'IDM_VIEW_UNFOLD_3'                                          => (((40000 + 4000) + 60) + 3),
    'IDM_VIEW_UNFOLD_4'                                          => (((40000 + 4000) + 60) + 4),
    'IDM_VIEW_UNFOLD_5'                                          => (((40000 + 4000) + 60) + 5),
    'IDM_VIEW_UNFOLD_6'                                          => (((40000 + 4000) + 60) + 6),
    'IDM_VIEW_UNFOLD_7'                                          => (((40000 + 4000) + 60) + 7),
    'IDM_VIEW_UNFOLD_8'                                          => (((40000 + 4000) + 60) + 8),
    'IDM_VIEW_UNFOLD_CURRENT'                                    => ((40000 + 4000) + 31),
    'IDM_VIEW_WRAP'                                              => ((40000 + 4000) + 22),
    'IDM_VIEW_WRAP_SYMBOL'                                       => ((40000 + 4000) + 41),
    'IDM_VIEW_ZOOMIN'                                            => ((40000 + 4000) + 23),
    'IDM_VIEW_ZOOMOUT'                                           => ((40000 + 4000) + 24),
    'IDM_VIEW_ZOOMRESTORE'                                       => ((40000 + 4000) + 33),
    'IDM_WIKIFAQ'                                                => ((40000  + 7000)  + 7),
);

=over

=item DEPRECATED %ENCODINGKEY

Deprecated: The %ENCODINGKEY hash variable no longer exists. Use L</%BUFFERENCODING> for the correct values.

This deprecated hash incorrectly assumed there was a simple numerical offset between the values of
L<notepad-E<gt>getEncoding|Win32::Mechanize::NotepadPlusPlus::Notepad/getEncoding> and the
C<$NPPIDM{IDM_FORMAT_...}> entries in L</%NPPIDM>.

=item %BUFFERENCODING

The numerical values from this hash can be passed to
L<notepad-E<gt>setEncoding|Win32::Mechanize::NotepadPlusPlus::Notepad/setEncoding>
to change the encoding of the buffer; the numerical values returned from
L<notepad-E<gt>getEncoding|Win32::Mechanize::NotepadPlusPlus::Notepad/getEncoding>
can be passed as keys for this hash to convert the encoding number back to a string.

Keys or values ending in _BOM indicate the Unicode Byte Order Mark will be included
as the first bytes in the saved file.

    Key                     | Value         | Description
    ------------------------+---------------+-----------------
    ANSI                    | 0             | 256 codepoints
    UTF8_BOM                | 1             | UTF-8 Encoding, using Byte Order Mark (BOM) at beginning of file
    UCS2_BE_BOM             | 2             | UCS-2 Big Endian, using Byte Order Mark (BOM) at beginning of file
    UCS2_LE_BOM             | 3             | UCS-2 Little Endian, using Byte Order Mark (BOM) at beginning of file
    UTF8                    | 4             | UTF-8 Encoding, _not_ using Byte Order Mark (BOM) at beginning of file
    ------------------------+---------------+-----------------
    COOKIE                  | 4             | Alias for UTF8         (name used in PythonScript BUFFERENCODING enum)
    uni8Bit                 | 0             | Alias for ANSI         (from enum UniMode in source code)
    uniUTF8                 | 1             | Alias for UTF8_BOM     (from enum UniMode in source code)
    uni16BE                 | 2             | Alias for UCS2_BE_BOM  (from enum UniMode in source code)
    uni16LE                 | 3             | Alias for UCS2_LE_BOM  (from enum UniMode in source code)
    uniCookie               | 4             | Alias for UTF8_NO_BOM  (from enum UniMode in source code)
    ------------------------+---------------+-----------------
    0                       | ANSI          | (string)
    1                       | UTF8_BOM      | (string)
    2                       | UCS2_BE_BOM   | (string)
    3                       | UCS2_LE_BOM   | (string)
    4                       | UTF8_NO_BOM   | (string)

=back

=cut

our %BUFFERENCODING = (
    # name => number
    ANSI            => 0,
    UTF8_BOM        => 1,
    UCS2_BE_BOM     => 2,
    UCS2_LE_BOM     => 3,
    UTF8            => 4,
    COOKIE          => 4,   # pythonscript compatible

    # number => text
    0               => 'ANSI',
    1               => 'UTF8_BOM',
    2               => 'UCS2_BE_BOM',
    3               => 'UCS2_LE_BOM',
    4               => 'UTF8',

    # enum UniMode compatible strings
    uni8Bit         => 0,
    uniUTF8         => 1,
    uni16BE         => 2,
    uni16LE         => 3,
    uniCookie       => 4,
);


=head1 INSTALLATION

Installed as part of L<Win32::Mechanize::NotepadPlusPlus>

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests emailing C<E<lt>bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.orgE<gt>>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus>,
or thru the repository's interface at L<https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>.

=head1 COPYRIGHT

Copyright (C) 2019,2020 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
