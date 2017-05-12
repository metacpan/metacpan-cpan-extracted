# ==============================================================================
# $Id: Win32-TSA-Notify.t 459 2006-08-31 17:46:51Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Test Win32::TSA::Notify
# ==============================================================================

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-TSA-Notify.t'

#########################

#use Test::More tests => 1;
use Test::More 'no_plan';
BEGIN { use_ok('Win32::TSA::Notify') }

#########################

ok( ref Win32::TSA::Notify->new, 'new' );

my $icon = Win32::TSA::Notify->new;

ok( $icon->change_icon(q{ }), 'change_icon' );
ok( $icon->change_text(q{ }), 'change_text' );
ok( $icon->alert( q{ }, q{ } ), 'alert' );
ok( $icon->sleep(0),      'sleep' );

ok( $icon->restore_icon(q{ }), 'restore_icon' );

ok( $icon->Sleep(0),      'Sleep' );
ok( $icon->SetIcon(q{ }), 'SetIcon' );
ok( $icon->SetAnimation( 0, 0, q{ } ), 'SetAnimation' );
ok( $icon->Balloon( q{ }, q{ }, q{ }, 0 ), 'Balloon' );

#########################
