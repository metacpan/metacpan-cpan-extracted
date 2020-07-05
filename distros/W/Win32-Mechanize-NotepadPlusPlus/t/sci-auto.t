########################################################################
# Verifies Editor object's AUTOLOAD facility is working correctly
#   (unfortunately, didn't commit the version I had working yesterday
#   at home, so either re-develop or )
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers qw/:userSession/;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.
my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

BEGIN {
    notepad()->closeAll();
    notepad()->open( path($0)->absolute->canonpath() );
}

# DoesNotExist doesn't autovivify
{
    my $err;
    eval { editor()->DoesNotExist; 1; } or do { chomp($err = $@) };
    like $err, qr/\QUndefined subroutine DoesNotExist called at\E/, "autoload: verify error on unknown method";
    note sprintf qq|\tautoload: editor()->DoesNotExist\n\t\t=> err:"%s"\n|, explain $err//'<undef>';
}

# method (getText) does autovivify, or bail out
{
    my $err;
    eval { editor()->getText; 1; } or do { chomp($err = $@) };
    isnt defined($err), "autoload: verify works with known method";
    note sprintf qq|\tautoload: editor()->getText\n\t\t=> err:"%s"\n|, explain $err//'<undef>';

    # after the eval to vivify it, the object should pass can_ok test
    can_ok editor(), qw/getText/
        or BAIL_OUT 'cannot getText even after AUTOLOAD';
}

# method(no-args) -> str        # use getText()
{
    my $txt = editor()->getText();
    ok defined($txt), 'method(): return string';
    my $l = length($txt);
    substr($txt,77) = '...' if $l > 80;
    $txt =~ s/[\r\n]/ /g;
    note sprintf "\teditor()->getText => qq|%s| [%d]\n", $txt, $l;
}

# method(no-args) -> message(no-args) -> most return types
#                               # use clearAll() and undo() as examples
{
    my $ret = editor()->clearAll();
    ok defined $ret, 'method(no-args):message(no-args): return value';
    note "\t", 'editor()->clearAll(): retval = ', $ret//'<undef>';

    (my $txt = editor()->getText()) =~ s/\0*$//;
    my $l = length( $txt );
    is $l, 0, 'method(no-args):message(no-args): return value';
    note "\t", 'editor()->clearAll(): getText() shows zero length = ', $l, "\n";

    sleep(1);
    $ret = editor()->undo();
    ok defined $ret, 'method(no-args):message(no-args): return value';
    note "\t", 'editor()->undo(): retval = ', $ret//'<undef>';

    ($txt = editor()->getText()) =~ s/\0*$//;
    $l = length( $txt );
    ok $l, 'method(no-args):message(no-args): verify previous method had correct effect, not just correct retval';
    note "\t", 'editor()->getText() shows valid length after undo: ', $l, "\n";

}

# method(one-arg__w) -> str        # use getLine(1)
{
    # grab expected value from manual SCI_GETLINE
    my $expect = editor()->{_hwobj}->SendMessage_getRawString( $SCIMSG{SCI_GETLINE}, 1, { trim => 'retval' } );

    # compare to auto-generated method result
    my $line = editor()->getLine(1);
    $line =~ s/\0*$//;
    is $line, $expect, "method(integer): return string";
    $line =~ s/[\r\n]*$//;
    note sprintf qq|\teditor()->getLine(1) => "%s"\n|, $line//'<undef>';
}

# method(wparam=const char*) -> str # use encodedFromUTF8(str)
#   in PythonScript, editor.encodedFromUTF8(u"START\x80") yields 'START\xc2\x80'
{
    my $str = "ThisString";
    my $got = editor()->encodedFromUTF8($str);
    is $got, $str, 'method(string): return string';
    note sprintf qq|\teditor()->encodedFromUTF8("%s") => "%s"\n|, $str//'<undef>', $got//'<undef>';
}

# method(str) -> message(<unused>, lparam=const char*) -> *     # use setText(str)
{
    my $str = "method(unused, lparam=const char*)";
    my $ret = editor()->setText($str);
    ok defined($ret), 'method(string):message(<unused>, string): return value';
    note sprintf qq|\teditor->setText("%s"): retval = %s\n|, $str, $ret//'<undef>';
    my $got = editor()->getText();
    $got =~ s/[\r\n]*\0*$//;    # remove trailing newlines and nulls
    is $got, $str, 'method(string):message(<unused>, string): verify action';
    note sprintf qq|\teditor->getText() after setText(): text = "%s"\n|, $got//'<undef>';

    # undo changes (avoid ask-for-save during exit)
    editor()->undo();
}

# method(str,str) -> message(const str, const str) -> no return
# method(str) -> message(const str, output str) -> string
# method(str) -> message(const str, no lparam) -> int
#   use setRepresentation/getRepresentation/clearRepresentation group
#       editor.getRepresentation("A") => ''
{
    my $rep = editor()->getRepresentation("A");
    is $rep, '', 'method(string):message(<unused>, string): return empty string';
    note sprintf qq|\teditor->getRepresentation("A"): got:"%s" vs exp:""\n|, $rep//'<undef>';

    # now try changing it
    my $ret = eval { editor()->setRepresentation("A", "LETTER:A"); 1; } or do {
        note sprintf qq|\teditor->setRepresentation() had error: "%s"\n|, $@ // '<undef>';
    };

    # to verify it worked, read the representation again
    $rep = editor()->getRepresentation("A");
    is $rep, "LETTER:A", 'method(string,string):message(string, string): returned nothing, so checking a readback instead';
    note sprintf qq|\teditor->getRepresentation("A"): got:"%s" vs exp:"LETTER:A" after ->setRepresentation(...)\n|, $rep//'<undef>';

    # try to clearRepresentation, which will bring it back to empty-string default
    $ret = eval { editor()->clearRepresentation("A"); 1; } or do {
        note sprintf qq|\teditor->clearRepresentation() had error: "%s"\n|, $@ // '<undef>';
    };
    sleep(1);
    $rep = editor()->getRepresentation("A");
    is $rep, "", 'method(string,string):message(string, string): returned empty nothing, so checking a readback instead';
    note sprintf qq|\teditor->getRepresentation("A"): got:"%s" vs exp:"" after ->clearRepresentation()\n|, $rep//'<undef>';
}

# message(arg, string)
#       use styleGetFont(style):str to verify styleSetFont(style, fontName)
{
    # grab default get-value
    my $fontName = editor()->styleGetFont(0);
    ok $fontName, 'method(arg,string):grab default string value before changing it';
    note sprintf qq|\teditor->styleGetFont(0): got:"%s"\n|, $fontName//'<undef>';

    # test using set/get pair
    my $ret = editor()->styleSetFont(0, "Times New Roman");
    my $newFont = editor()->styleGetFont(0);
    is $newFont, "Times New Roman", 'method(arg,string):grab modified string value after changing it';
    note sprintf qq|\teditor->styleGetFont(0): got:"%s"\n|, $newFont//'<undef>';

    # return to default
    editor()->styleSetFont(0, $fontName);
}

# method(arg) -> msg(<unused>,arg)
#   use setMarginLeft/getMarginLeft pair
{
    # grab default get-value
    my $origMargin = editor->getMarginLeft();
    ok defined($origMargin), 'method(arg):message(<unused>,arg): grab default value';
    note sprintf qq|\teditor->getMarginLeft(): got:"%s"\n|, $origMargin//'<undef>';

    # test using set/get pair
    my $ret = editor()->setMarginLeft(17);
    my $newMargin = editor->getMarginLeft();
    is $newMargin, 17, 'method(arg):message(<unused>,arg): grab updated value';
    note sprintf qq|\teditor->getMarginLeft(): got:"%s"\n|, $newMargin//'<undef>';

    # return to default
    editor()->setMarginLeft($origMargin);
}

# method(arg,arg) -> msg(arg,arg):
#   use findColumn(line, col):col   -- which doesn't actually find the column; it finds how many characters from (0,0) to the (line,col)
#   call findColumn twice on adjacent lines, first column; it should then be the line length, plus EOL size
#       since it's using this test file, I can guarantee that __LINE__ from the previous line will give the position of _this_ line's first character,
#       do that twice, and subtract; should be more than 0 characters
{
    my $l0 = __LINE__;
    my $p0 = editor()->findColumn($l0,0);     # character-number for first character on this line
    ok defined($p0), 'method(arg,arg):message(arg,arg): grab first value';
    note sprintf qq|\teditor->findColumn(%d,0): got:"%s"\n|, $l0, $p0//'<undef>';

    my $l1 = __LINE__;
    my $p1 = editor()->findColumn($l1,0);     # character-number for first character on this line
    ok defined($p1), 'method(arg,arg):message(arg,arg): grab second value';
    note sprintf qq|\teditor->findColumn(%d,0): got:"%s"\n|, $l1, $p1//'<undef>';

    cmp_ok $p1-$p0, '>', 0, 'method(arg,arg):message(arg,arg): verify meaningful values';
    note sprintf qq|\teditor->findColumn() delta: got:"%s"; should be at least one character between those lines\n|, ($p1-$p0)//'<undef>';
}

# method(arg)->msg(arg)
#   use styleSetFore(style,fore)/styleGetFore(style) pair
{
    my $f = editor()->styleGetFore($SC_STYLE{STYLE_DEFAULT});
    ok defined($f), 'method(arg):message(arg): grab initial value';
    note sprintf qq|\teditor->styleGetFore(%d): got:"%s"\n|, $SC_STYLE{STYLE_DEFAULT}, $f//'<undef>';

    # change the color
    my $reverse = (~$f) & 0xFFFFFF;     # invert the color
    editor()->styleSetFore($SC_STYLE{STYLE_DEFAULT}, $reverse);

    my $r = editor()->styleGetFore($SC_STYLE{STYLE_DEFAULT});
    ok defined($r), 'method(arg):message(arg): grab initial value';
    note sprintf qq|\teditor->styleGetFore(%d): got:"%s"\n|, $SC_STYLE{STYLE_DEFAULT}, $r//'<undef>';

    is $r, $reverse, 'method(arg):message(arg): check for meaningful results';
    note sprintf qq|\teditor->styleGetFore(): "%s" vs "%s"\n|, $r//'<undef>', $reverse//'<undef>';

    # return to original foreground
    editor()->styleSetFore($SC_STYLE{STYLE_DEFAULT}, $f);
}

# method(arg)->msg(length,const char *)
#   use editor->searchInTarget() and editor->replaceTargetRE() to verify
#   other similar methods include addText() and related
#       see also https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/41 => replaceTargetRE
#       see also https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues/42 => searchInTarget
{
    my $src =<<EOT;
This is a not selected line !!!
This is line one !!!
Today is a beautiful day !!!
This is line three !!!
This is a not selected line !!!
EOT
    (my $exp = $src) =~ s/beautiful/great/;

    editor->setText($src);
    myTestHelpers::_mysleep_ms(50);

    # set and verify the initial range
    editor->setTargetRange(32,105);
        # diag sprintf "range = (%s,%s)\n", editor->getTargetStart(), editor->getTargetEnd();
        # diag sprintf "%s\n", do { (my $tmp = editor->getTargetText()) =~ s/^/\t/gm; $tmp };

    # set the option
    editor->setSearchFlags($SC_FIND{SCFIND_REGEXP});
        # diag sprintf "SCFIND_REGEXP = '0x%08x'\n", $SC_FIND{SCFIND_REGEXP};
        # diag sprintf "getSearchFlags() => '0x%08x' \n", editor->getSearchFlags();

    # do the search and check retval
    my $searchret = editor->searchInTarget('beautiful');
        # diag sprintf "searchInTarget('beautiful')=%s\n", $searchret//'<undef>';
    is $searchret, 64, "searchInTarget('beautiful') found the correct location";

    # do the replacement
    editor->replaceTargetRE('great');
        # diag sprintf "range = (%s,%s)\n", editor->getTargetStart(), editor->getTargetEnd();
        # diag sprintf "%s\n", do { (my $tmp = editor->getTargetText()) =~ s/^/\t/gm; $tmp };

    # get the final whole text
    my $got = editor->getText(); # the whole document
        # diag sprintf "range = (%s,%s)\n", editor->getTargetStart(), editor->getTargetEnd();
        # diag sprintf "%s\n", do { (my $tmp = editor->getTargetText()) =~ s/^/\t/gm; $tmp };
    is $got, $exp, 'searchInTarget/replaceTargetRE() s/beautiful/great/ equivalent'
        or diag sprintf "\t=> '%s'\n", dumper $got;

    # cleanup
    editor->setSavePoint();
    notepad->closeAll();
}



done_testing;
