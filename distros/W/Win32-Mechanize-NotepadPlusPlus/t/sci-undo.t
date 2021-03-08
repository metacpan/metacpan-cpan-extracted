########################################################################
# Verifies Scintilla undo-group begin/end
#   Probably not needed for coverage-sake; desired for debug/verification,
#   and shouldn't hurt to keep it.
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
BEGIN { my $f = $FindBin::Bin . '/nppPath.inc'; require $f if -f $f; }

use lib $FindBin::Bin;
use myTestHelpers qw/:all/;

use Path::Tiny 0.018;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

BEGIN { select STDERR; $|=1; select STDOUT; $|=1; } # make STDOUT and STDERR both autoflush (hopefully then interleave better)

#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.
my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

BEGIN { notepad()->closeAll(); }

# beginUndoAction
my $eval_failed;
eval {
    editor()->beginUndoAction();
    1;
} or do {
    $eval_failed = 1;
    diag sprintf "__%04d__: beginUndoAction() crashed with: '%s'\n", __LINE__, $@//"<undef>";
};
ok !$eval_failed, 'beginUndoAction()';
note sprintf "__%04d__: beginUndoAction() error = '%s'\n", __LINE__, $eval_failed//"didn't fail";

# do something (that will be undone)
my $expect = "Hello World";
editor()->setText($expect);
my $got = editor()->getText();
$got =~ s/\0+$//;
is $got, $expect, 'verify got the expected text';
note sprintf "__%04d__: got '%s' vs expect '%s'\n", __LINE__, $got, $expect;

# endUndoAction
undef $eval_failed;
eval {
    editor()->endUndoAction();
    1;
} or do {
    $eval_failed = 1;
    diag sprintf "__%04d__: endUndoAction crashed with: '%s'\n", __LINE__, $@//"<undef>";
};
ok !$eval_failed, 'endUndoAction()';
note sprintf "__%04d__: beginUndoAction() error = '%s'\n", __LINE__, $eval_failed//"didn't fail";

# undo
undef $eval_failed;
eval {
    editor()->undo();
    1;
} or do {
    $eval_failed = 1;
    diag sprintf "__%04d__: undo crashed with: '%s'\n", __LINE__, $@//"<undef>";
};
ok !$eval_failed, 'undo()';
note sprintf "__%04d__: undo() error = '%s'\n", __LINE__, $eval_failed//"didn't fail";

# verify undo worked
$got = editor()->getText();
$got =~ s/\0+$//;
is $got, '', 'verify got the expected (empty) text';
note sprintf "__%04d__: got '%s' vs expect '%s'\n", __LINE__, $got, '';

# done
ok 1, "done";
done_testing;
