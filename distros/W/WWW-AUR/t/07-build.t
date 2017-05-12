#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More;

BEGIN {
    eval { require IPC::Cmd; 1 }
        or plan 'skip_all' => 'Test needs IPC::Cmd installed';
    IPC::Cmd::can_run( 'makepkg' )
        or plan 'skip_all' => 'Test needs makepkg utility';

    plan 'tests' => 3;
    use_ok 'WWW::AUR::Package';
}

# Recursive check building ourself from the AUR. Crazy? Maybe.
my $pkgname = 'perl-www-aur';
my $pkg = WWW::AUR::Package->new( $pkgname, 'basepath' => 't/tmp' );
diag "Test building $pkgname";

# Avoid our tests because we are already doing them.
my $builtpath = $pkg->build( 'args' => '--nocheck' );
ok $builtpath;
is $builtpath, $pkg->bin_pkg_path;

done_testing;
