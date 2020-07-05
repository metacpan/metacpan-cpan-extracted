########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: those necessary for hidden scintilla instance
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32::GuiTest qw':FUNC !SendMessage';

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

my $sci = notepad()->createScintilla();
isa_ok $sci, "Win32::Mechanize::NotepadPlusPlus::Editor"
    or BAIL_OUT(sprintf 'invalid object:%s returned from createScintilla()', $sci//'<undef>');
    note sprintf "\tsci = %s\n", $sci//'<undef>';

note sprintf "->createScintilla() has hwnd = %s\n", $sci->hwnd() // '<undef>';
ok 0+$sci->hwnd(), 'returned hwnd is non-zero' or BAIL_OUT('invalid hwnd from createScintilla');

my $class = GetClassName($sci->hwnd());
is $class, 'Scintilla', 'class(hwnd) is Scintilla';
note sprintf "\tclass(h:%s) = '%s'\n", $sci->hwnd(), $class // '<undef>';

# destroy should return true, but disable 'deprecated' warnings
{
    no warnings 'deprecated';
    my $destroy = notepad()->destroyScintilla($sci);
    ok $destroy, '->destroyScintilla(): retval [deprecated]'; note sprintf "\tretval = %s\n", $destroy // '<undef>';
}

# and now check that the 'deprecated' warning is firing
my $warnmsg = undef;
eval {
    use warnings FATAL => 'deprecated'; # should cause the warning to be fatal
    notepad()->destroyScintilla(0);
    1;
} or do {
    $warnmsg = $@;
};
like $warnmsg, qr/\Q->destroyScintilla() method does nothing, so it does not destroy a Scintilla instance [deprecated]\E/, '->destroyScintilla(): should issue \'deprecated\' warning';
    note sprintf "\twarning message = '%s'\n", $warnmsg // '<undef>';

done_testing;