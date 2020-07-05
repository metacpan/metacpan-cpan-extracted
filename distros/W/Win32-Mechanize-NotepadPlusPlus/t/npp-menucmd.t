########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: those necessary for menuCommands
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;
use Win32::GuiTest 1.64 qw':FUNC !SendMessage';

use FindBin;
use lib $FindBin::Bin;
use myTestHelpers;
myTestHelpers::setChildEndDelay(6);

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus qw/:main :vars/;


# menuCommand
{
    my $ret = notepad()->menuCommand('IDM_VIEW_CLONE_TO_ANOTHER_VIEW');
    ok $ret, 'menuCommand("IDM_VIEW_CLONE_TO_ANOTHER_VIEW"): retval from string-param'; note sprintf qq(\t=> "0x%08x"\n), $ret // '<undef>';

    # close the cloned window, which also tests value-based menuCommand...
    $ret = notepad()->menuCommand($NPPIDM{IDM_FILE_CLOSE});
    ok $ret, 'menuCommand(NPPIDM{IDM_FILE_CLOSE}): retval from value-param'; note sprintf qq(\t=> "0x%08x"\n), $ret // '<undef>';
}

# runMenuCommand
{
    # for runMenuCommand, I am going to SHA-256 on active selection; which means I need a selection, and need to know what it is.
    my $expected = 'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e';
    my $algorithm = 'SHA-256';

    # 1. create new file
    notepad()->newFile();
    select undef,undef,undef,0.25;

    # 2. add known text
    editor()->{_hwobj}->SendMessage_sendRawString( $SCIMSG{SCI_SETTEXT}, 0, "Hello World" );
    select undef,undef,undef,0.25;

    # 3. select that text
    notepad()->menuCommand('IDM_EDIT_SELECTALL');
    select undef,undef,undef,0.25;

    # 4. run the menu command
    my $ret = notepad()->runMenuCommand( "Tools | $algorithm", 'Generate from selection into clipboard');
    unless(defined $ret) {
        $algorithm = 'MD5';
        $expected = 'b10a8db164e0754105b7a99be72e3fe5';
        $ret = notepad()->runMenuCommand( "Tools | $algorithm", 'Generate from selection into clipboard');
    }
    ok $ret, "runMenuCommand(Tools | $algorithm | Generate from selection into clipboard): retval"; note sprintf qq(\t=> "%s"\n), $ret // '<undef>';

    # 5. paste the resulting text
    notepad()->menuCommand('IDM_EDIT_PASTE');

    # 6. get the resulting textlength and text
    my $len = editor()->{_hwobj}->SendMessage( $SCIMSG{SCI_GETTEXTLENGTH} );    note sprintf qq(\t=> "%s"\n), $len // '<undef>';
    {
        my $txt;
        eval {
            $txt = editor()->{_hwobj}->SendMessage_getRawString( $SCIMSG{SCI_GETTEXT}, $len+1, { trim => 'wparam' } );
        } or do {
            diag "eval(getRawString) = '$@'";
            $txt = '';
        };
        $txt =~ s/[\0\s]+$//;   # remove trailing spaces and nulls
        is $txt, $expected, "runMenuCommand(): resulting $algorithm text"; note sprintf qq(\t%s => "%s"\n), $algorithm, $txt // '<undef>';
    }

    # 7. clear the editor, so I can close without a dialog
    editor()->{_hwobj}->SendMessage_sendRawString( $SCIMSG{SCI_SETTEXT}, 0, "\0" );

    # 8. close
    notepad()->close();
}

# runPluginCommand
#   2020-Apr-03: per issue#30, need to rework the test suite, to make sure caching is working right, etc
#   new outline:
#       * compare ->{_menuID} to getMainMenuHandle
#       * verify Plugins menu exists in main menu
#           * if not, exit
#       * ok ->getPluginMenuHandle()
# new:
SKIP: {
    # won't actually skip until partway through, but by wrapping the whole sequence in
    # the SKIP: block, I can jump out at one or more spots without having to manually control that
    # the only thing i have to do is keep the number of skipped tests correct
    local $TODO;
    my $remaining = 6;

    # make sure main menu ID matches
    my $str = "Main Menu Handle";
    my $exp = notepad->{_menuID};
    my $got = notepad->getMainMenuHandle();
    is $got, $exp, sprintf '%s: from message vs GetMenu(hwnd)', $str;
    note sprintf "\t%s: expected = GetMenu() = %s\n", $str, $exp;
    note sprintf "\t%s: got = getMainMenuHandle() = %s\n", $str, $got;
    --$remaining;

    # plugin menu handle
    $str = "Plugin Menu Handle";
    my $pluginID = notepad->getPluginMenuHandle();
    ok defined $got, sprintf '%s: defined handle returned', $str;
    note sprintf "\t%s: got = getMainMenuHandle() = %s\n", $str, $got;
    --$remaining;
    skip "No $str found", $remaining unless $got;
    ok $got, sprintf '%s: reasonable handle value', $str;

    # plugins menu contents
    $str = "Plugin Menu Contents";
    my $count = GetMenuItemCount( $pluginID );
    note sprintf "\t%s: got %s items\n", $str, $count//'<undef>';

    my %plugin_entries;
    for my $idx ( 0 .. $count-1 ) {
        my %h = GetMenuItemInfo( $pluginID, $idx );
        if( $h{type} eq 'string' ) {
            (my $cleanText = $h{text}) =~ s/(\&|\t.*)//;
            note sprintf "\t\t%-20s | %s\n", $h{text}, $cleanText;
            $plugin_entries{$cleanText} = GetSubMenu($pluginID, $idx);
        }
    }

    myTestHelpers->setDebugInfo(1);
    TODO: for my $arr (
        ["Plugins Admin...", "Plugins Admin", 4],
        ["Converter", "About", "Converter Plugin", 0],
    ) {
        $str = $arr->[0];
        my $btn_num = pop @$arr;
        my $title = pop @$arr;
        my $t_extra = 1;    # 1s extra delay
        local $TODO = "couldn't find '$str'" unless exists $plugin_entries{ $str };
        my $re = qr/^\Q$title\E$/;
        for(1..2) {
            my $ret;
            runCodeAndClickPopup( sub { $ret = notepad()->runPluginCommand( @$arr ) }, $re, $btn_num, $t_extra );
            ok $ret//'<undef>', sprintf "%s [#%s]: ret=%s", $str, $_, $ret//'<undef>';
            --$remaining;
            sleep( $t_extra );
        }
    }
    myTestHelpers->setDebugInfo(0);

    skip "NEED TO FIX initial \$remaining value", $remaining if $remaining>0;
}

done_testing(11);
