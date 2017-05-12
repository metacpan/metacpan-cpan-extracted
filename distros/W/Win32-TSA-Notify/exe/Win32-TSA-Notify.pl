# =============================================================================
# $Id: t_MyTSANotify.pl 431 2006-08-29 22:07:51Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Test program for Win32::TSA::Notify
# ==============================================================================

# -- Pragmas
use 5.008006;
use strict;
use threads;
use threads::shared;

# -- Global modules
use Thread::Semaphore;
use Time::HiRes;

# -- Support @INC for local moduls
use lib '../lib', '../../lib', '../../../lib', '../../../../lib';

# -- Local moduls
use Win32::TSA::Notify::Icon;

# -- Version for tooltip
my $VERSION = '1.00';

# -- Autoflush of STDOUT
$|++;

# -- Semaphore for print status
#    An asyn thread and the main thread show the runtime and status at the
#    same console line
my $_S_show_it = new Thread::Semaphore();

# --------------------
#
#   Start TEST

# -- Set starttime, copyright and start message
my $_pstart = Time::HiRes::time();
my $_copyright
    = q{Copyright (c) 2006 Thomas Walloschke (thw@cpan.org). All rights reserved.};
printf "Start at %s - Runtime will be approx. 80 sec\n",
    scalar localtime($_pstart);

TEST: {

    # -- Start an 'asyn' thread showing the runtime -
    #    regardless what happens to the following icon objects
    my $_asyn : shared = 1;
    my $thread = async {

        _set_now('Setup...    ');    # Current timestamp, 'Setup'

        while ($_asyn) {
            &_set_now;               # Current timestamp, no extra status
            Time::HiRes::sleep(.01);
        }

        _set_now('Thank You For Testing!');    # Current timestamp, 'Bye!'
    };

    # --------------------

    # -- Build 4 objects, load all (bound/found) icons into these objects
    #    Show the start icon and the tooltip of object 1, wait 2,5 s
    #    Show blank icons and tooltips of objects 2..4 in the TSA
    my $icon1 = Win32::TSA::Notify::Icon->new( 'app', 2500, "MyApp V$VERSION" );
    my $icon2 = Win32::TSA::Notify::Icon->new();
    my $icon3 = Win32::TSA::Notify::Icon->new();
    my $icon4 = Win32::TSA::Notify::Icon->new()->sleep(1500);

    # -- Show the icons of objects 2..4 with a little delay (300 ms)
    #    and the show the tooltips
    $icon2->change_icon( 'find',   300 )->change_text("Find V$VERSION");
    $icon3->change_icon( 'delete', 300 )->change_text("Delete V$VERSION");
    $icon4->change_icon( 'public', 300 )->change_text("Public V$VERSION");

    # --------------------

    _sleep(3);

    # -- Run 1 syn animation
    $icon1->SetIcon( [qw(public delete find public find delete public)], 500 );

    # -- Run 3 asyn animations
    $icon4->SetAnimation( 9000,  100, 'find', 'delete', 'public' );
    $icon3->SetAnimation( 60000, 200, 'find', 'delete', 'public' );
    $icon2->SetAnimation( 30000, 30,  'find', 'delete', 'public' );

    # --------------------

    _sleep(5);

    # -- Alert for 3 sec - stops asyn animatio
    $icon2->Balloon(
        'This balloon stops the animation',
        'Stop Animation [icon2]',
        'info', 3000
    );

    # --------------------

    _sleep(2);

    # -- Alert for 8 sec - can't find the icon: show blank instead
    $icon1->alert(
        "Alert [icon1]",
        "Message 1...\n"
            . " 1)\tTest 1\n"
            . " 2)\tUse 'app' icon...\n"
            . " 3)\t\'app\' icon not valid in alert\n"
            . " 4)\tSet tooltip\n"
            . " 5)\tRestore icon",
        'app',    # 'app' not valid
        "ToolTip1"
    )->sleep(8000)->clear_alert;

    # -- Alert for 8 sec - use 'warning' icon
    $icon2->alert(
        "Alert [icon2]",
        "Message 2...\n"
            . " 1)\tTest 2\n"
            . " 2)\tUse 'warning' icon...\n"
            . " 3)\tSet tooltip\n"
            . " 4)\tRestore icon",
        'warning',    # valid
        "ToolTip2"
    )->sleep(8000)->clear_alert;

    # -- Alert for 8 sec - use 'default' (='error') icon,
    #    but animation is stronger and overloads the icon
    #    Animation can only be stopped by 'Balloon' or timeout
    $icon3->alert(
        "Alert [icon3]",
        "Message 3...\n"
            . " 1)\tTest 3\n"
            . " 2)\tUse 'error' icon (default)...\n"
            . " 3)\tContinue animation\n"
            . " 4)\tAnimation overloads 'error' icon"
    )->sleep(8000)->clear_alert;

    # --------------------

    _sleep(5);

    # -- Alert for 4,5 sec - use 'info' icon
    $icon1->Balloon(
        " 1)\tUse 'info' icon\n" . " 2)\tRestore icon",
        'Balloon [icon1]',
        'info', 4500
    );

    # -- Alert for 5,8 sec - use 'none' icon - 'none' is a valid icon name
    $icon2->Balloon(
        " 1)\tUse 'none' icon\n"
            . " 2)\t'none' is a valid icon name\n"
            . " 3)\tRestore icon",
        'Balloon [icon2]', 'none', 5800
    );

    # -- Alert for 4,8 sec - use 'error' icon - stop the animation
    #    (still running)
    $icon3->Balloon(
        " 1)\tUse 'error' icon\n"
            . " 2)\tStop animation\n"
            . " 3)\tRestore icon",
        'Balloon [icon3]', 'error', 4800
    );

    # --------------------

    _sleep(5);

    # -- Alert for 3 sec - use 'help' icon and wait for another 3 sec
    $icon4->Balloon( 'Thank You For Testing!', 'Bye', 'help', 3000 )
        ->sleep(3000);

    # -- Blank the icons from left to right and wait a little (500..800 ms)
    $icon4->SetIcon('_none')->Sleep(500);
    $icon3->SetIcon('_none')->Sleep(500);
    $icon2->SetIcon('_none')->Sleep(500);
    $icon1->SetIcon('_none')->Sleep(800);

    # -- Stop the 'asyn' thread which shows the runtime
    $_asyn = 0;    # 'QnD'

    # -- Wait for 2 s ...
    sleep 2;

    # ... 'asyn' thread should have been stopped now ;-)
    print "\n$_copyright\n";

    # -- Advertising ...
    sleep 8;

}

# --------------------
#
#   Private subs

# -- Emulate 'sleep' - show the waittime every 10 ms
sub _sleep {

    my ( $_sleep, $_now ) = ( $_[0], Time::HiRes::time() );
    my ( $_start, $_stop ) = ( $_now, $_now + $_sleep );

    while ( $_stop > Time::HiRes::time() ) {
        _show_it(
            Time::HiRes::time() - $_pstart,
            Time::HiRes::time() - $_start,
            'Pause...    '
        );
        Time::HiRes::sleep(.01);
    }

    _show_it( Time::HiRes::time() - $_pstart,
        Time::HiRes::time() - $_start, 'Running...' );

}

# -- Show the runtime since start (called from asyn thread)
sub _set_now {

    $_[0]
        ? _show_it( Time::HiRes::time() - $_pstart, 0, $_[0] )
        : _show_it( Time::HiRes::time() - $_pstart );

}

# -- Thread save runtime and status display
sub _show_it {

    # -- Semaphore P operation
    $_S_show_it->down;

    my ( $runtime, $sleeptime, $status ) = @_;
    if ($status) {
        printf "\t[%0.2fs  %0.2fs]\t%s\r", $runtime, $sleeptime, $status;
    }
    else {
        printf "\t[%0.2fs\r", $runtime;
    }

    # -- Semaphore V operation
    $_S_show_it->up;

}

__END__

=head1 NAME

Win32-TSA-Notify -  Test program for Win32::TSA::Notify

=head1 SYNOPSIS

 win32: perl Win32-TSA-Notify.pl
 win32: Win32-TSA-Notify.exe

=head1 DESCRIPTION

C<Win32-TSA-Notify> tests the C<Win32::TSA::Notify> methods. Try it!

=head1 ICONS

Following icons will be used and should exist as bound files.
Ref: F<exe/Win32-TSA-Notify.perlapp>

=head2 res/icons/

    Get_Info.ico
    Win32-TSA-Notify_App.ico
    Win32-TSA-Notify_Delete.ico
    Win32-TSA-Notify_Error.ico
    Win32-TSA-Notify_Find.ico
    Win32-TSA-Notify_Help.ico
    Win32-TSA-Notify_Info.ico
    Win32-TSA-Notify_None.ico
    Win32-TSA-Notify_Public.ico
    Win32-TSA-Notify_Warning.ico

=head1 SEE ALSO

L<Win32::TSA::Notify>, L<Win32::PerlExe:Env>

=head1 COPYRIGHT

Copyright © 2005 Thomas Walloschke (thw@cpan.org). All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Last changed $Date: 2006-08-30 00:07:51 +0200 (Mi, 30 Aug 2006) $.

=cut
