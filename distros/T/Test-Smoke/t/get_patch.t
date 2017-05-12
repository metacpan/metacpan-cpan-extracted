#! perl -w
use strict;

# $Id$

use File::Spec;
use File::Copy;

use Test::More tests => 8;
BEGIN { use_ok( 'Test::Smoke::Util' ); }

chdir 't' or die "chdir: $!" if -d 't';
my $snap_level = 17888;

SKIP: {
    # better safe; try and unlink '.patch'
    1 while unlink '.patch';
    -f '.patch' and skip "Can't unlink '.patch'", 1;

    local *PL;
    open PL, '> patchlevel.h' or skip "Couldn't crate patchlevel.h: $!", 1;
    printf PL <<'EO_PATCHLEVEL', $snap_level;
#if !defined(PERL_PATCHLEVEL_H_IMPLICIT) && !defined(LOCAL_PATCH_COUNT)
static  char    *local_patches[] = {
        NULL
        ,"DEVEL%d"
        ,NULL
};
EO_PATCHLEVEL
    close PL or skip 1, "Couldn't close patchlevel.h: $!";

    my $get_patch = get_patch();

    is $get_patch->[0], "$snap_level(+)",
       "Found snaplevel: $get_patch->[0]";
}

SKIP: {
    1 while unlink '.patch';
    -f '.patch' and skip "Can't unlink '.patch'", 1;
    ( my $get_patch = get_patch()->[0] ) =~ tr/0-9//cd;
    is $get_patch, $snap_level, "Found snaplevel(2): $get_patch";
}

SKIP: { # Check for Release Candidates
    # better safe; try and unlink '.patch'
    1 while unlink '.patch';
    -f '.patch' and skip "Can't unlink '.patch'", 1;

    my $rc = '3';
    local *PL;
    open PL, '> patchlevel.h' or skip "Couldn't crate patchlevel.h: $!", 1;
    printf PL <<'EO_PATCHLEVEL', $rc;
/* Some C comments go here */
#define PERL_REVISION   5               /* age */
#define PERL_VERSION    9               /* epoch */
#define PERL_SUBVERSION 0               /* generation */

#if !defined(PERL_PATCHLEVEL_H_IMPLICIT) && !defined(LOCAL_PATCH_COUNT)
static  char    *local_patches[] = {
        NULL
        ,"RC%d"
        ,NULL
};
EO_PATCHLEVEL
    close PL or skip 1, "Couldn't close patchlevel.h: $!";

    my $get_patch = get_patch();

    is $get_patch->[0], "5.9.0-RC$rc",
       "Found Release Candidate: $get_patch->[0]";
}

SKIP: {
    my $src = File::Spec->catfile( 'ftppub', 'pl_with_pn.h' );
    copy $src, 'patchlevel.h' or skip 1, "Cannot copy patchlevel.h: $!";

    my $get_patch = get_patch;
    is $get_patch->[0], 25000, "PATCH_NUM $get_patch->[0]";
}

SKIP: {
    my $pl = 'blead 2008-12-20.10:38:02 ' .
             '2af192eebde5f7a93e229dfc3196f62ee4cbcd2e ' .
             'GitLive-blead-45-g2af192ee';
    my ($branch, $date, $patch, $descr) = split ' ',  $pl;
    $descr =~ s/^GitLive-//;
    local *PL;
    open( PL, '> .patch') or skip "Couldn't create .patch: $!", 1;
    print PL $pl;
    close PL or skip "Couldn't close .patch: $!", 1;

    my $get_patch = get_patch();
    is $get_patch->[0], $patch, "Found patchlevel: $patch";
    is $get_patch->[1], $descr, "Found short description: $descr";
    is $get_patch->[2], $branch, "Found branch: $branch";

    1 while unlink '.patch';
}

END { 
    1 while unlink 'patchlevel.h';
    chdir File::Spec->updir
        if -d File::Spec->catdir( File::Spec->updir, 't' );
}
