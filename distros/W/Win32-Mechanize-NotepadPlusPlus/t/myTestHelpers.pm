package myTestHelpers;
use Win32::GuiTest qw/:FUNC/;
use Exporter 5.57 qw/import/;
use Test::More;
use POSIX ":sys_wait_h";

use Path::Tiny 0.058 qw/path tempfile/; # 0.018 needed for rootdir and cwd; 0.058 needed for sibling

use Win32::Mechanize::NotepadPlusPlus qw/:main/;  # for %scimsg
use Win32::Mechanize::NotepadPlusPlus::__sci_msgs;  # for %scimsg

use 5.010;
use strict;
use warnings;

=head1 NAME

myTestHelpers

=head1 DESCRIPTION

These functions help with my test suite.

Items starting with C<:> are import tags.
Items starting with C<myTestHelpers::> cannot be exported, and must always be called
fully qualified.

=over

=item runCodeAndClickPopup( sub{...}, $regex, $n )

The C<sub{...}> contains the code that will spawn a dialog box.

The C<$regex> needs to match the title of the dialog, like C<qr/^MyTitle$/>.

The C<$n> indicates which button needs to be pressed (0 means the first button).

    runCodeAndClickPopup( sub { fakeMessageBox(title=>'MyTitle') }, qr/^MyTitle$/, 0 );

=back

=cut

BEGIN {
    if(exists $ENV{HARNESS_PERL_SWITCHES} ){
        *runCodeAndClickPopup = \&__devel_cover__runCodeAndClickPopup;
    } else {
        *runCodeAndClickPopup = \&__runCodeAndClickPopup;
    }
}

=over

=item   myTestHelpers::setChildEndDelay($sec)

Some tests, when using C<runCodeAndClickPopup>, need an extra delay
before closing the child process (some sort of race condition which
I haven't figured out); you can use this function to set a delay
for child processes that goes into an END block (to avoid ending the
child too early).

=back

=cut

my $_END_DELAY = 0;
sub setChildEndDelay($) {
    $_END_DELAY = shift;
}

# the child process created in runCodeAndClickPopup() is exiting too quickly,
# causing a race condition; add a delay at END if it's not the master process
my $_savePID;
BEGIN { $_savePID = $$; }
END   { sleep($_END_DELAY) if $_savePID and $$ != $_savePID; }

our @EXPORT_OK = qw/runCodeAndClickPopup saveUserSession restoreUserSession/;
our @EXPORT = qw/runCodeAndClickPopup/;
our %EXPORT_TAGS = (
    userSession => [qw/saveUserSession restoreUserSession/],
    all => [@EXPORT_OK],
);
my $IAMCHILDDONOTRESTORE;

my $DEBUG_INFO = 0;

=over

=item   myTestHelpers::setDebugInfo($flag)

If $flag is true, myTestHelpers will print additional debug information.

=back

=cut

sub setDebugInfo { shift if $_[0] eq __PACKAGE__; $DEBUG_INFO = shift; }

# have to fork to be able to respond to the popup, because $cref->() holds until the dialog goes away
#   unfortunately, Devel::Cover doesn't work if threads are involved.
#   The BEGIN block above figures out how to detect that we're running under Devel::Cover, and take an alternate test-flow
sub __runCodeAndClickPopup {
    my ($cref, $re, $n, $xtraDelay) = @_;
    $xtraDelay ||= 0;

    my $pid = fork();
    if(!defined $pid) { # failed
        die "fork failed: $!";
    } elsif(!$pid) {    # child: pid==0
        my $f = WaitWindowLike(0, $re, undef, undef, 3, 10);
        my $p = GetParent($f);
        if($DEBUG_INFO) {
            note "runCodeAndClickPopup(..., $re, $n, $xtraDelay):\n";
            note sprintf qq|\tfound: %d t:"%s" c:"%s"\n\tparent: %d t:"%s" c:"%s"\n|,
                $f, GetWindowText($f), GetClassName($f),
                $p, GetWindowText($p), GetClassName($p),
                ;
        }
        # Because localization, cannot assume YES button will match qr/\&Yes/
        #   instead, assume $n-th child of spawned dialog is always the one that you want
        my @buttons = FindWindowLike( $f, undef, qr/^Button$/, undef, 2);
        if($DEBUG_INFO) {
            note sprintf "\tbutton:\t%d t:'%s' c:'%s' id=%d vis:%d grey:%d chkd:%d\n", $_,
                    GetWindowText($_), GetClassName($_), GetWindowID($_),
                    IsWindowVisible($_), IsGrayedButton($_), IsCheckedButton($_)
                for grep { $_ } @buttons;
        }
        if($n>$#buttons) {
            diag sprintf "You asked to click button #%d, but there are only %d buttons.\n", $n, scalar @buttons;
            diag sprintf "clicking the first (#0) instead.  Good luck with that.\n";
            $n = 0;
            for my $i (0..30) {
                my @c = map { $_//'' } caller($i);
                last unless @c;
                print "caller($i): ", join(', ', @c), $/;
            }
        }
        my $h = $buttons[$n];
        my $id = GetWindowID($h);
        if($DEBUG_INFO) { note sprintf "\tCHOSEN:\t%d t:'%s' c:'%s' id=%d\n", $h, GetWindowText($h), GetClassName($h), $id; }
        sleep($xtraDelay) if $xtraDelay;

        # first push to select, second push to click
        PushChildButton( $f, $id, 0.5 ) for 1..2;
        if($DEBUG_INFO) { sleep 1; }
        $IAMCHILDDONOTRESTORE = 1;
        exit;   # terminate the child process once I've clicked
    } else {            # parent
        undef $IAMCHILDDONOTRESTORE;
        $cref->();
        my $t0 = time;
        while(waitpid(-1, WNOHANG) > 0) {
            last if time()-$t0 > 30;        # no more than 30sec waiting for end
        }
    }
}

sub __devel_cover__runCodeAndClickPopup {
    my ($cref, $re, $n) = @_;
    diag "Running in coverage / Devel::Cover mode\n";
    diag "\n\nYou need to click the ${n}th button in the dialog which should appear soon\n\n";
    diag "caller(0): ", join ';', map {$_//'<undef>'} caller(0);
    $cref->();
}

=over

=item   :userSession

=item   saveUserSession()

=item   restoreUserSession()

    BEGIN { $EmergencySessionHash = saveUserSession(); }
    END { restoreUserSession( $EmergencySessionHash ); }

This pair of functions can be used in BEGIN/END blocks to ensure that
the user session is properly saved at the start of test, and restored
when test is over, so that the user doesn't notice a change in his
session.

=back

=cut

sub saveUserSession {
    my ($saveUserFileList, $saveUserSession);
    my $unsaved = 0;
    for my $view (0, 1) {
        my $nb = notepad()->getNumberOpenFiles($view);
        for my $idoc ( 0 .. $nb-1 ) {
            notepad()->activateIndex($view,$idoc);
            $unsaved++ if editor()->{_hwobj}->SendMessage( $scimsg{SCI_GETMODIFY} );
            push @$saveUserFileList, notepad()->getCurrentFilename();
        }
    }

    if($unsaved) {
        my $err = "\n"x4;
        $err .= sprintf "%s\n", '!'x80;
        $err .= sprintf "You have %d unsaved file%s in Notepad++!\n", $unsaved, ($unsaved>1)?'s':'';
        $err .= sprintf "Please save or close %s, then re-run the module test or installation.\n", ($unsaved>1)?'them':'it';
        $err .= sprintf "%s\n", '!'x80;
        $err .= "\n"x4;
        diag($err);
        BAIL_OUT('Unsaved Files: Please read the message between the !!!-lines.');
    }

    $saveUserSession = tempfile('XXXXXXXX')->sibling('EmergencyNppSession.xml');

    my $ret = notepad()->saveCurrentSession( $saveUserSession->canonpath() );
    note sprintf 'saveCurrentSession("%s"): retval = %d', $saveUserSession->canonpath(), $ret;
    my $size = $saveUserSession->is_file ? $saveUserSession->stat()->size : 0;
    note sprintf sprintf 'saveCurrentSession(): size(file) = %d', $size;
    if(!$size) {
        my $err = "\n"x4;
        $err .= sprintf "%s\n", '!'x80;
        $err .= sprintf "I could not save your session for you!\n";
        $err .= sprintf "Because of this, I am not willing to continue running the test suite,.\n";
        $err .= sprintf "as I may not be able to restore your files.\n";
        $err .= sprintf "\n";
        $err .= sprintf "Please close all your files, and try to re-run the module test or installation\n";
        $err .= sprintf "%s\n", '!'x80;
        $err .= "\n"x4;
        diag($err);
        BAIL_OUT('Could not save session.  Please read the message between the !!!-lines.');
    };

    note "saveUserSession: ", $saveUserSession->canonpath(); # don't want to delete the session

    return { session => $saveUserSession, list => $saveUserFileList };

}

sub restoreUserSession {
    my $h = shift;
    my $saveUserSession = $h->{session};
    my $saveUserFileList = $h->{list};

    # don't restore from child process
    return if $IAMCHILDDONOTRESTORE;

    # in case any are left open, close them
    notepad()->closeAll;

    # should load just the user's files
    notepad()->loadSession($saveUserSession->absolute->canonpath);

    # check for any missing files
    my $missing = 0;
    for my $f ( @$saveUserFileList ) {
        ++$missing unless notepad()->activateFile($f) or $f =~ /^new \d/;
    }
    if($missing) {
        my $err = "\n"x4;
        $err .= sprintf "%s\n", '!'x80;
        $err .= sprintf "I could not restore your session for you!\n";
        $err .= sprintf "It should be saved in \"%s\".\n", $saveUserSession->absolute->canonpath;
        $err .= sprintf "Feel free to try to File > Load Session... for that file\n";
        $err .= sprintf "\n";
        $err .= sprintf "Sorry for any inconvenience.  I tried.\n";
        $err .= sprintf "%s\n", '!'x80;
        $err .= "\n"x4;
        diag $err;
        BAIL_OUT(sprintf 'File > Load Session... > "%s"', $saveUserSession->absolute->canonpath);
    }

    # only delete the file if the session has been successfully loaded.
    $saveUserSession->remove();
    note "\n\nrestoreUserSession(): Verified user session files re-loaded.\n\n";
}

1;