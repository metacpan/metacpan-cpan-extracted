########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: those necessary for file and session open/close
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers qw/runCodeAndClickPopup :userSession/;

use Path::Tiny 0.058 qw/path tempfile/;     # 0.018 needed for rootdir and cwd; 0.058 needed for sibling

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

# need to choose forked (normal clicker) vs unforked (Devel::Cover cannot handle windows[fork->thread] )

# outline:
#   if any unsaved buffers, HALT test and prompt user to save any critical
#       files, then re-run test suite.

my $EmergencySessionHash;
BEGIN { $EmergencySessionHash = saveUserSession(); }
END { restoreUserSession( $EmergencySessionHash ); }

#   prepopulate any tempfile locations
our $fnew1 = tempfile( TEMPLATE => 'nppNewFile_XXXXXXXX', SUFFIX => '.txt'); note $fnew1->canonpath();
our $fnew2 = tempfile( TEMPLATE => 'nppDupFile_XXXXXXXX', SUFFIX => '.txt'); note $fnew2->canonpath();
our $knownSession = tempfile( TEMPLATE => 'nppKnownSession_XXXXXXXX', SUFFIX => '.xml'); note $knownSession->canonpath();

#   ->saveCurrentSession($saveUserSession)
#       => this also avoids messing up the user's current Notepad++ instance.
#           STOP IMMEDIATELY IF THIS FAILS
#       => attempt to reload that session on exit (END block),
#           and if there's a problem with reload, point user
#           to where the session file is.
{
    # saveCurrentSession was actuall run during the BEGIN block;
    #   this just verifies the file is there and has non-zero size
    my $size = $EmergencySessionHash->{session}->is_file ? $EmergencySessionHash->{session}->stat()->size : 0;
    ok $size, sprintf 'saveCurrentSession(): size(file) = %d', $size;
}

#   ->closeAll()
#       => gives a blank slate to work with.
{
    my $ret = notepad()->closeAll();
    ok $ret, sprintf 'closeAll(): retval = %d', $ret;

    my $nOpen = notepad()->getNumberOpenFiles(0);
    is $nOpen, 1, sprintf 'closeAll(): getNumberOpenFiles(0) = %d', $nOpen;

    my $fName = notepad()->getCurrentFilename();
    like $fName, qr/^new \d/i, sprintf 'closeAll(): getCurrentFilename() = "%s"', $fName;
}

#   ->loadSession()
#       => gets us to a known state with a prebuilt session
{
    # generate the session file on the fly, because it needs absolute directories, which I cannot have until the test suite runs
    my @src = qw/00-load.t 10-defaults.t/;
    $knownSession->append(qq{<NotepadPlus><Session activeView="0"><mainView activeIndex="0">\n});
    $knownSession->append(sprintf qq{<File firstVisibleLine="0" xOffset="0" filename="%s" />\n}, $_)
        for map { path($0)->sibling($_)->absolute->canonpath() } @src;
    $knownSession->append(qq{</mainView><subView activeIndex="0" /></Session></NotepadPlus>\n});
    #note $knownSession->slurp();

    my $ret = notepad()->loadSession( $knownSession->absolute->canonpath );
    ok $ret, sprintf 'loadSession("%s"): retval = %d', $knownSession->absolute->canonpath, $ret;

    my $nOpen = notepad()->getNumberOpenFiles(0);
    is $nOpen, 2, sprintf 'loadSession(): getNumberOpenFiles(0) = %d', $nOpen;

    my @files = map { $_->[0] } @{ notepad()->getFiles() };
    for my $i (0,1) {
        like $files[$i], qr/\b\Q$src[$i]\E\b/i, sprintf 'loadSession(): getFiles()->[%d][0] = "%s"', $i, $files[$i];
    }
}

#   ->newFile()
#       => create a blank, editable document
{
    my $ret = notepad()->newFile();
    ok $ret, sprintf 'newFile(): retval = %d', $ret;

    my $fName = notepad()->getCurrentFilename();
    like $fName, qr/^new \d/i, sprintf 'newFile(): getCurrentFilename() = "%s"', $fName;
}

#   ->saveAs( $fnew1 )
#       => give it a name
{
    my $text = sprintf 'saveAs("%s")', $fnew1->basename();
    editor()->{_hwobj}->SendMessage_sendRawString( $scimsg{SCI_SETTEXT}, 0, $text );

    my $ret = notepad()->saveAs( $fnew1->absolute->canonpath() );
    ok $ret, sprintf 'saveAs(): retval = %d', $ret;

    my $fName = path( notepad()->getCurrentFilename() )->basename();
    is $fName, $fnew1->basename(), sprintf 'saveAs(): getCurrentFilename() = "%s"', $fName;
}

#   ->saveAsCopy( $fnew2 )
#       => give it a second name (but ->getCurrentFilename() should remain the same)
{
    my $ret = notepad()->saveAsCopy( $fnew2->absolute->canonpath() );
    ok $ret, sprintf 'saveAsCopy(): retval = %d', $ret;

    my $fName = path( notepad()->getCurrentFilename() )->basename();
    isnt $fName, $fnew2->basename(), sprintf 'saveAsCopy(): getCurrentFilename() = "%s"', $fName;
    is $fName, $fnew1->basename(), sprintf 'saveAsCopy(): getCurrentFilename() = "%s"', $fName;
}

#   ->open( $fnew2 )
#       => bring it in and edit it
{
    my $ret = notepad()->open( $fnew2->absolute->canonpath() );
    ok $ret, sprintf 'open("%s"): retval = %d', $fnew2->absolute->canonpath(), $ret;

    my $fName = path( notepad()->getCurrentFilename() )->basename();
    is $fName, $fnew2->basename(), sprintf 'open(): getCurrentFilename() = "%s"', $fName;
}

#   ->save()
#       => edit it, and make sure that it changes on disk
{
    my $origFileSize = $fnew2->stat()->size();
    ok $origFileSize, sprintf 'save(): original size before edit and save: %d', $origFileSize;

    my $text = "this is new text";
    my $expect = length($text);
    editor()->{_hwobj}->SendMessage_sendRawString( $scimsg{SCI_SETTEXT}, 0, $text );

    my $ret = notepad()->save();
    ok $ret, sprintf 'save(): retval = %d', $ret;

    my $newFileSize = $fnew2->stat()->size();
    is $newFileSize, $expect, sprintf 'save(): new size after edit and save: %d', $newFileSize;
}

#   ->saveSession( $knownSession, @fileNameList )
#       => include a subset of files; see whether they all have to be open or not
#   ->getSessionFiles()
#       => test to make sure it includes all the files I passed to ->saveSession
#   (grouped two tests together, because the second will use the list from the first as the comparison)
{
    my @fileNameList = map { $_->absolute->canonpath() } $fnew1, $fnew2;
    my $ret = notepad()->saveSession( $knownSession, @fileNameList );
    ok $ret, sprintf 'saveSession(%s): ret = %d', $knownSession->basename(), $ret;
    #note $knownSession->slurp();

    my @ret = notepad()->getSessionFiles($knownSession);
    ok scalar @ret, sprintf 'getSessionFiles(%s): found %d sessions', $knownSession->basename(), scalar @ret;
    is_deeply \@ret, \@fileNameList, sprintf 'getSessionFiles(): files all match the session-generator list';
}

#   ->saveAllFiles()
#       => _after_ editing both open files
#       => need to make sure that it changes on disk
{
    my $nView0 = notepad()->getNumberOpenFiles(0);
    is $nView0, 4, sprintf 'saveAllFiles(): first make sure expected number are open: %d', $nView0;

    # last modified when?
    my ($tmod1, $tmod2) = map { $_->stat()->mtime() } $fnew1, $fnew2;
    ok $tmod1, sprintf 'saveAllFiles(): "%s" previously modified at %s', $fnew1->basename(), scalar localtime $tmod1;
    ok $tmod2, sprintf 'saveAllFiles(): "%s" previously modified at %s', $fnew2->basename(), scalar localtime $tmod2;

    # edit both files
    for my $di ( $nView0-1,$nView0-2 ) {
        notepad()->activateIndex(0,$di);
        my $text = sprintf qq(editing "%s"\r\n%s\r\n), notepad->getCurrentFilename(), scalar localtime;
        editor()->{_hwobj}->SendMessage_sendRawString( $scimsg{SCI_SETTEXT}, 0, $text );
        sleep(1);
    }

    # now save them
    my $ret = notepad->saveAllFiles();
    ok $ret, sprintf 'saveAllFiles(): ret = %d', $ret;

    # should be more-recently modified
    my ($tmod1x, $tmod2x) = map { $_->stat()->mtime() } $fnew1, $fnew2;
    ok $tmod1x-$tmod1, sprintf 'saveAllFiles(): "%s" modified at %s; delta = %d', $fnew1->basename(), scalar localtime $tmod1x, $tmod1x-$tmod1;
    ok $tmod2x-$tmod2, sprintf 'saveAllFiles(): "%s" modified at %s; delta = %d', $fnew2->basename(), scalar localtime $tmod2x, $tmod2x-$tmod2;
}

#   ->closeAllButCurrent()
#       => only one file should be there
{
    my $ret = notepad()->closeAllButCurrent();
    ok $ret, sprintf 'closeAllButCurrent(): ret = %d', $ret;

    my $num = notepad()->getNumberOpenFiles(0);
    is $num, 1, sprintf 'closeAllButCurrent(): %d file%s open', $num, $num==1?'':'s';
}

#   ->close()
#       => all that remains should be the "new 1" empty buffer
{
    my $oldname = notepad()->getCurrentFilename();

    my $ret = notepad()->close();
    ok $ret, sprintf 'close(): ret = %d', $ret;

    my $name = notepad()->getCurrentFilename();
    like $name, qr/^new \d/i, sprintf 'close(): filename should be /new #/: "%s"', $name;
    isnt $name, $oldname, sprintf 'close(): filename should not match old name ("%s")', $oldname;
}

done_testing;
