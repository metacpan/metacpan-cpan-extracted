#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    Changes-NewName
    MANIFEST
    MANIFEST2
    MANIFEST3
    META.yml
    Makefile.PL2
    NewFile
    NewFile2
    README
    lib/Catalyst/Plugin/Static/TT.pm
    t/00-load.t
    t/basic.t
    t/pod-coverage.t
    t/root/static/1.txt
    t/root/static/1.txt.tt
    t/root/static/subdir/2.txt
    t/root/static/subdir/2.txt.tt
    lib
    lib/Catalyst
    lib/Catalyst/Plugin
    lib/Catalyst/Plugin/Static
    t
    t/root
    t/root/static
    t/root/static/subdir
)];

use constant EXPECTED_COMMIT => {
    revision  => '0e15f67ea2b4388eb6663678404c23919a054f0c',
    revno     => '0e15f67ea2b4388eb6663678404c23919a054f0c',
    uuid      => '0e15f67ea2b4388eb6663678404c23919a054f0c',
    message   => "Commit with all types of files.\nAnd a second line of text.",
    committer => 'Max Kanat-Alexander <mkanat@es-compy.(none)>',
    time      => '2007-09-01T22:53:38',
    timezone  => '-0700',
    modified  => [qw(Changes-NewName MANIFEST README t/00-load.t)],
    added     => [qw(NewFile NewFile2 MANIFEST2 MANIFEST3)],
    removed   => ['t/pod.t'],
    moved     => { 'Changes-NewName' => { 'Changes'     => 'f64932b56175d711a007a4ef933a1b32de6ae9a8' },
                   'Makefile.PL2'    => { 'Makefile.PL' => 'f64932b56175d711a007a4ef933a1b32de6ae9a8' },
                 },
    copied    => { 'MANIFEST2' => { 'MANIFEST' => 'f64932b56175d711a007a4ef933a1b32de6ae9a8' },
                   'MANIFEST3' => { 'MANIFEST' => 'f64932b56175d711a007a4ef933a1b32de6ae9a8' },
                 },
    added_empty => {'NewFile' => 1, 'NewFile2' => 1},
};

use constant EXPECTED_FILE => {
    path     => 'lib/Catalyst/Plugin/Static/TT.pm',
    revision => '1c94abbdfd2a29c637789324de87d16a97bf7cb8',
    revno    => '1c94abbdfd2a29c637789324de87d16a97bf7cb8',
    time     => '2007-09-01T16:31:03',
    timezone => '-0700',
    size     => 5090,
    commits  => 4,
    # XXX Git is a little strange--it doesn't show the latest merge commit
    # in rev-list, but it does show up in our History object.
    last_revision  => 'f64932b56175d711a007a4ef933a1b32de6ae9a8',
    first_revision => 'ab08fceac97a75e811f94c2e73b5bece03c9d8d7',
};

sub setup_repo {
    require Git;
    Git::command_noisy('clone', '--bare', '-q',
        'http://vci.everythingsolved.com/repos/git/test-2007-09-01.git',
        't/repos/git/test.git');
}

#########
# Tests #
#########

plan skip_all => "git requirements not installed" if !feature_enabled('git');

eval { setup_repo() if !-d 't/repos/git/test.git'; 1; }
    || plan skip_all => "Unable to create git testing repo: $@";

plan tests => 51;

test_vcs({
    type          => 'Git',
    repo_dir      => 't/repos/git',
    project_name  => 'test.git',
    mangled_name  => '/test.git/',
    head_revision => '0e15f67ea2b4388eb6663678404c23919a054f0c',
    num_commits   => 10,
    commits_rec   => 9,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::VCS::Git::Diff',
    expected_file => EXPECTED_FILE,
    revisions_global => 1,
    revisions_universal => 1,
});
