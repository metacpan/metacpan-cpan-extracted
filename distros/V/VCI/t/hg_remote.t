#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use VCI;
use lib 't/lib';
use Support qw(test_vcs);

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
Argh-Spec.txt  EmptyFile  Makefile  newdir   README
COPYING2       examples   New       NewFile  tests
.hgignore .hgtags

examples/2dec.agh examples/cat2.agh examples/EmptyFile examples/revert2.agh
examples/tricky1.agh examples/beer.agh  examples/cat2dec.agh
examples/hello.agh examples/revert.agh examples/cat1.agh examples/cat3.agh
examples/NewFile examples/tenhello.agh

newdir/EmptyFile  newdir/NewFile

tests/aargh-height-good.agh tests/argh-height-good.agh tests/jump.agh
tests/width-bad.agh tests/argh-height-bad.agh tests/conditional.agh
tests/run-tests.sh tests/width-good.agh
)];

use constant EXPECTED_COMMIT => {
    # XXX At some point we should actually properly support revno,
    #     and "revision" should become the full revision id.
    revision  => 'b56a898fdf90',
    revno     => 'b56a898fdf90',
    uuid      => 'b56a898fdf90',
    message   => "This is the commit for testing VCI.\n"
                 . "And it has a two-line message.",
    committer => 'root@12.d1.5446.static.theplanet.com',
    time      => '2007-09-07T02:11:54',
    timezone  => '-0500',
    added     => [qw(Argh-Spec2.txt COPYING2 Moved NewFile README-COPIED
                     examples/NewFile newdir/NewFile)],
    removed   => [qw(argh-mode.el argh.c argh.lisp)],
    modified  => [qw(Argh-Spec.txt)],
    moved     => {},
    copied    => {},
    added_empty => {},
};

use constant EXPECTED_FILE => {
    path     => 'Makefile',
    revision => '626207473726',
    revno    => '626207473726',
    time     => '2007-02-01T09:59:44',
    timezone => '+0100',
    size     => 865,
    commits  => 4,
    first_revision => 'd3f1ae8a1444',
    last_revision  => '626207473726',
};

#########
# Tests #
#########

plan skip_all => 'VCI_REMOTE_TESTS environment variable not set to 1'
    if !$ENV{VCI_REMOTE_TESTS};

plan tests => 51;

test_vcs({
    type         => 'Hg',
    repo_dir     => 'http://hg-test.vci.everythingsolved.com/2007-09-07/',
    project_name => 'test-repo',          
    mangled_name  => '/test-repo/',
    head_revision => 'e34b54e34f30',
    num_commits   => 23,
    commits_rec   => 14,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::VCS::Hg::Diff',
    copy_in_diff  => 1,
    expected_file => EXPECTED_FILE,
    revisions_global => 1,
    revisions_universal => 1,
});