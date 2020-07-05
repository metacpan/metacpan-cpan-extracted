########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: those necessary for GUI manipulation
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers;
myTestHelpers::setChildEndDelay(6);

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;

# setStatusBar
{
    my $ret = notepad()->setStatusBar( $STATUSBAR{STATUSBAR_DOC_TYPE}, "I have ruined the status bar: sorry!" );
    ok $ret, 'setStatusBar(STATUSBAR{STATUSBAR_DOC_TYPE}): retval'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

    # need the current language type and language description to be able to revert the section
    my $langType = notepad()->getLangType();    # get language-type index for the current buffer
    ok defined($langType), 'getLangType(): retval'; note sprintf qq(\t=> "%s"\n), $langType // '<undef>';
    my $langDesc = notepad()->getLanguageDesc($langType);
    ok $langDesc, 'getLanguageDesc()'; note sprintf qq(\t=> "%s"\n), $langDesc;
    my $langName = notepad()->getLanguageName($langType);
    ok $langName, 'getLanguageName()'; note sprintf qq(\t=> "%s"\n), $langName;

    $ret = notepad()->setStatusBar( 'STATUSBAR_DOC_TYPE', $langDesc );
    ok $ret, sprintf 'setStatusBar(STATUSBAR_DOC_TYPE): reset to languageDesc';  note sprintf qq(\t=> "%s"\n), $ret // '<undef>';
}

# isTabBarHidden, hideTabBar, showTabBar
#   they return previous state; because I cannot be _certain_ of tabbar state originally,
{
    # condition unknown; check isTabBarHidden vs 0 or 1
    my $hiddenState = notepad()->isTabBarHidden();
    like $hiddenState, qr/^[01]$/, 'isTabBarHidden(): retval indicates current state (unknown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    my $keepHidden = $hiddenState;

    # force HIDE; retval (prev) should match hiddenState
    my $beforeHide = notepad()->hideTabBar();
    is $beforeHide, $hiddenState, 'hideTabBar(): retval indicates previous state (from isTabBarHidden)'; note sprintf qq(\t=> "%s"\n), $beforeHide // '<undef>';
    $beforeHide = notepad()->hideToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
    #sleep(1);

    # verify hiddenState is now HIDDEN (true)
    $hiddenState = notepad()->isTabBarHidden();
    is $hiddenState, 1, 'isTabBarHidden(): retval indicates current state (hidden)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # force SHOW; retval (prev) should match hiddenState (true)
    my $beforeShow = notepad()->showTabBar();
    is $beforeShow, $hiddenState, 'showTabBar(): retval indicates previous state (hidden)'; note sprintf qq(\t=> "%s"\n), $beforeShow // '<undef>';
    $beforeHide = notepad()->showToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
    #sleep(1);

    # verify hiddenState is now SHOWN (false)
    $hiddenState = notepad()->isTabBarHidden();
    is $hiddenState, 0, 'isTabBarHidden(): retval indicates current state (shown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';
    #sleep(1);

    # return to previous state if necessary
    notepad()->hideTabBar() if $keepHidden;
}

# isToolBarHidden, hideToolBar, showToolBar
TODO: {
    # condition unknown; check isToolBarHidden vs 0 or 1
    my $hiddenState = notepad()->isToolBarHidden();
    like $hiddenState, qr/^[01]$/, 'isToolBarHidden(): retval indicates current state (unknown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    my $keepHidden = $hiddenState;

    # force HIDE; retval (prev) should match hiddenState
local $TODO = 'bug in MESSAGE result?';
    my $beforeHide = notepad()->hideToolBar();
    is $beforeHide, $hiddenState, 'hideToolBar(): retval indicates previous state (from isToolBarHidden)'; note sprintf qq(\t=> "%s"\n), $beforeHide // '<undef>';
    $beforeHide = notepad()->hideToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
local $TODO = undef;
    #sleep(1);

    # verify hiddenState is now HIDDEN (true)
    $hiddenState = notepad()->isToolBarHidden();
    is $hiddenState, 1, 'isToolBarHidden(): retval indicates current state (hidden)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # force SHOW; retval (prev) should match hiddenState (true)
local $TODO = 'bug in MESSAGE result?';
    my $beforeShow = notepad()->showToolBar();
    is $beforeShow, $hiddenState, 'showToolBar(): retval indicates previous state (hidden)'; note sprintf qq(\t=> "%s"\n), $beforeShow // '<undef>';
    $beforeHide = notepad()->showToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
local $TODO = undef;
    #sleep(1);

    # verify hiddenState is now SHOWN (false)
    $hiddenState = notepad()->isToolBarHidden();
    is $hiddenState, 0, 'isToolBarHidden(): retval indicates current state (shown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # return to previous state if necessary
    notepad()->hideToolBar() if $keepHidden;
}

# isStatusBarHidden, hideStatusBar, showStatusBar
TODO: {
    # condition unknown; check isStatusBarHidden vs 0 or 1
    my $hiddenState = notepad()->isStatusBarHidden();
    like $hiddenState, qr/^[01]$/, 'isStatusBarHidden(): retval indicates current state (unknown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    my $keepHidden = $hiddenState;

    # force HIDE; retval (prev) should match hiddenState
local $TODO = 'bug in MESSAGE result?';
    my $beforeHide = notepad()->hideStatusBar();
    is $beforeHide, $hiddenState, 'hideStatusBar(): retval indicates previous state (from isStatusBarHidden)'; note sprintf qq(\t=> "%s"\n), $beforeHide // '<undef>';
    $beforeHide = notepad()->hideToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
local $TODO = undef;
    #sleep(1);

    # verify hiddenState is now HIDDEN (true)
    $hiddenState = notepad()->isStatusBarHidden();
    is $hiddenState, 1, 'isStatusBarHidden(): retval indicates current state (hidden)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # force SHOW; retval (prev) should match hiddenState (true)
local $TODO = 'bug in MESSAGE result?';
    my $beforeShow = notepad()->showStatusBar();
    is $beforeShow, $hiddenState, 'showStatusBar(): retval indicates previous state (hidden)'; note sprintf qq(\t=> "%s"\n), $beforeShow // '<undef>';
    $beforeHide = notepad()->showToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
local $TODO = undef;
    #sleep(1);

    # verify hiddenState is now SHOWN (false)
    $hiddenState = notepad()->isStatusBarHidden();
    is $hiddenState, 0, 'isStatusBarHidden(): retval indicates current state (shown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # return to previous state if necessary
    notepad()->hideStatusBar() if $keepHidden;
}

# isMenuHidden, hideMenu, showMenu
{
    # condition unknown; check isMenuHidden vs 0 or 1
    my $hiddenState = notepad()->isMenuHidden();
    like $hiddenState, qr/^[01]$/, 'isMenuHidden(): retval indicates current state (unknown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    my $keepHidden = $hiddenState;

    # force HIDE; retval (prev) should match hiddenState
    my $beforeHide = notepad()->hideMenu();
    is $beforeHide, $hiddenState, 'hideMenu(): retval indicates previous state (from isMenuHidden)'; note sprintf qq(\t=> "%s"\n), $beforeHide // '<undef>';
    $beforeHide = notepad()->hideToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
    #sleep(1);

    # verify hiddenState is now HIDDEN (true)
    $hiddenState = notepad()->isMenuHidden();
    is $hiddenState, 1, 'isMenuHidden(): retval indicates current state (hidden)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # force SHOW; retval (prev) should match hiddenState (true)
    my $beforeShow = notepad()->showMenu();
    is $beforeShow, $hiddenState, 'showMenu(): retval indicates previous state (hidden)'; note sprintf qq(\t=> "%s"\n), $beforeShow // '<undef>';
    $beforeHide = notepad()->showToolBar(); note sprintf qq(\t=> "%s" (second)\n), $beforeHide // '<undef>';
    #sleep(1);

    # verify hiddenState is now SHOWN (false)
    $hiddenState = notepad()->isMenuHidden();
    is $hiddenState, 0, 'isMenuHidden(): retval indicates current state (shown)'; note sprintf qq(\t=> "%s"\n), $hiddenState // '<undef>';

    # return to previous state if necessary
    notepad()->hideMenu() if $keepHidden;
}

# getPluginMenuHandle, getMainMenuHandle
{
    my $mPlugin = notepad()->getPluginMenuHandle();
    ok $mPlugin, 'getPluginMenuHandle(): retval'; note sprintf qq(\t=> "0x%08x"\n), $mPlugin // '<undef>';

    my $mMain = notepad()->getMainMenuHandle();
    ok $mMain, 'getMainMenuHandle(): retval'; note sprintf qq(\t=> "0x%08x"\n), $mMain // '<undef>';
    is $mMain, notepad()->{_menuID}, 'getMainMenuHandle(): retval == _menuID'; note sprintf qq(\t=> "0x%08x": menuID\n), notepad()->{_menuID} // '<undef>';

    isnt $mPlugin, $mMain, 'getPluginMenuHandle() different than getMainMenuHandle()';
}

# msgBox, prompt
{
    # 1:OK, 2:CANCEL, 3:ABORT, 4:RETRY, 5:IGNORE, 6:YES, 7:NO, 10:AGAIN, 11:CONTINUE
    my $ret;
    runCodeAndClickPopup( sub { $ret = notepad()->messageBox('message', 'title', 3); }, qr/^\Qtitle\E$/, 1 );   # YES, NO, CANCEL
    is $ret, 7, 'messageBox(): retval = YES'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';        # 6 means YES, 7 NO, 2 CANCEL

    # and with defaults
    runCodeAndClickPopup( sub { $ret = notepad()->messageBox(); }, qr/^\QWin32::Mechanize::NotepadPlusPlus\E$/, 0 );
    is $ret, 1, 'messageBox(): retval = OK'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

    # prompt
    runCodeAndClickPopup( sub { $ret = notepad()->prompt('prompt', 'title', 'default'); }, qr/^\Qtitle\E$/, 0 );
    is $ret, 'default', 'prompt(): retval = "default"'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

    # prompt: cancel
    runCodeAndClickPopup( sub { $ret = notepad()->prompt('prompt', 'title', 'default'); }, qr/^\Qtitle\E$/, 1 );
    is $ret, undef, 'prompt(): cancel: retval is undef'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

    # prompt: new test case to make sure that without title and default, it will use "PerlScript notepad->prompt()" and ""
    runCodeAndClickPopup( sub { $ret = notepad()->prompt('prompt'); }, qr/^\QPerlScript notepad->prompt()\E$/, 0 );
    is $ret, '', 'prompt("prompt",undef,undef): search for title="PerlScript notepad->prompt()" -> retval = ""'; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

}

# moved to npp-menucmd.t:
#   menuCommand
#   runMenuCommand
#   runPluginCommand

done_testing;
