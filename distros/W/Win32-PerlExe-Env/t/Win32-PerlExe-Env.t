# ==============================================================================
# $Id: Win32-PerlExe-Env.t 485 2006-09-08 22:54:18Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Module Basic Test of Win32::PerlExe::Env
# ==============================================================================

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-PerlExe-Env.t'

#########################
# -- Module Basic Test
#    Win32::PerlExe::Env ':all'

#use Test::More 'no_plan';
use Test::More tests => 8;

BEGIN { use_ok( 'Win32::PerlExe::Env', qw(:all) ) }

#########################
# -- Scripts always receives 'undef' - this is ok!

# -- :tmp
ok( !defined get_tmpdir(),   'get_tmpdir    undef' );
ok( !defined get_filename(), 'get_filename  undef' );

# -- :vars
ok( !defined get_build(),    'get_build     undef' );
ok( !defined get_perl5lib(), 'get_perl5lib  undef' );
ok( !defined get_runlib(),   'get_runlib    undef' );
ok( !defined get_tool(),     'get_tool      undef' );
ok( !defined get_version(),  'get_version   undef' );

#########################
