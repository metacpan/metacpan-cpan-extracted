#!/usr/bin/env perl
use warnings;
use strict;
use Win32::Mechanize::NotepadPlusPlus qw/:main/;
use Win32::GuiTest qw/:FUNC !SendMessage/;

sub WM_MOVE() { 0x0003 };       # https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-move

print my $f = notepad()->{_hwnd};

for ( FindWindowLike( 0, qr/Find result/, undef, undef, undef) ) {
    warn sprintf "\twindow:\t%d txt:'%s' cls:'%s' id=%d vis:%d grey:%d chkd:%d\n", $_,
                    GetWindowText($_), GetClassName($_), GetWindowID($_),
                    IsWindowVisible($_), IsGrayedButton($_), IsCheckedButton($_),
    ;
    my $prev = $_;
    while($prev and my $p = GetParent($prev)) {
        warn sprintf "\t\t->parent:%d, txt:'%s', cls:'%s' id=%d vis:%d grey:%d chkd:%d | '%s'\n", $p,
                    GetWindowText($p), GetClassName($p), GetWindowID($p),
                    IsWindowVisible($p), IsGrayedButton($p), IsCheckedButton($p),
                    $p==$f ? 'NPP MAIN' : '';
        last if $p == 0 or $p==$f;
        $prev = $p;
    }
    warn sprintf "\t\tGetWindowRect:[%d,%d,%d,%d]\n", GetWindowRect($_);

    # need a way to determine if it's docked or not
    1;

    # now try to move it to 100,100
    warn sprintf "\t\tWM_MOVE retval = %d\n", Win32::GuiTest::SendMessage( $_, WM_MOVE, 0, (100<<8 | 100) );
    warn sprintf "\t\tGetWindowRect:[%d,%d,%d,%d] after WM_MOVE\n", GetWindowRect($_);

}

__END__
undocked:
        window: 2430100 txt:'Find result' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:4265268, txt:'', cls:'Static' id=1028 vis:1 grey:0 chkd:0 | ''
                ->parent:4329406, txt:' Console ', cls:'#32770' id=0 vis:1 grey:0 chkd:0 | ''
                ->parent:2364540, txt:'*C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[79,420,808,562]
        window: 7279776 txt:'Find result - 84 hits' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:2364540, txt:'*C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[830,465,1351,722]
        window: 3609472 txt:'Find result - 84 hits' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:2364540, txt:'*C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[218,396,739,653]
2364540

docked:
        window: 7279776 txt:'Find result - 84 hits' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:2364540, txt:'C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[830,465,1351,722]
        window: 3609472 txt:'Find result - 84 hits' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:2364540, txt:'C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[218,396,739,653]
        window: 2430100 txt:'Find result' cls:'#32770' id=0 vis:0 grey:0 chkd:0
                ->parent:11211762, txt:'', cls:'Static' id=1028 vis:1 grey:0 chkd:0 | ''
                ->parent:5443380, txt:'Selected Tab', cls:'#32770' id=0 vis:1 grey:0 chkd:0 | ''
                ->parent:2364540, txt:'C:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\examples\moveFindResultsWindow.pl - Notepad++', cls:'Notepad++' id=332666007 vis:1 grey:0 chkd:0 | 'NPP MAIN'
                GetWindowRect:[0,786,1672,947]
2364540