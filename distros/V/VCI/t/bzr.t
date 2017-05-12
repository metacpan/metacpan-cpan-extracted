#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Support qw(test_vcs check_requirements);
use VCI;

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    VCI
    VCI.pm
    VCI/Abstract
    VCI/Abstract/Commit.pm
    VCI/Abstract/Committable.pm
    VCI/Abstract/Directory.pm
    VCI/Abstract/File.pm
    VCI/Abstract/FileContainer.pm
    VCI/Abstract/History.pm
    VCI/Abstract/Project.pm
    VCI/Abstract/Repository.pm
    VCI/Util.pm
)];

use constant EXPECTED_COMMIT => {
    revision  => 'mkanat@es-compy-20070806041257-f16n2g248d63mf1i',
    uuid      => 'mkanat@es-compy-20070806041257-f16n2g248d63mf1i',
    revno     => 3,
    message   => "Add more documentation, re-work Committable, move"
          . " VCI::Abstract::Util to just be VCI::Util (that makes more sense,"
          . " since the Utilities aren't abstract...) and move from using"
          . " Epochs to using DateTime objects.",
    committer => 'Max Kanat-Alexander <mkanat@es-compy>',
    time      => '2007-08-05T21:12:57',
    timezone  => '-0700',
    moved     => {
        'VCI/Util.pm' => { 'VCI/Abstract/Util.pm' => 'mkanat@es-compy-20070806014341-pyxvc39osgfibp7k' },
    },
    added     => [],
    removed   => [],
    copied    => {},
    modified  => [qw(VCI/Abstract/Comittable.pm VCI/Abstract/Commit.pm
                     VCI/Abstract/Repository.pm VCI/Util.pm)],
    added_empty => {},
};

use constant EXPECTED_FILE => {
    path     => 'VCI/Abstract/Repository.pm',
    revision => 'mkanat@es-compy-20070807070743-63zfyrindwf0vov4',
    revno    => 6,
    time     => '2007-08-07T00:07:43',
    timezone => '-0700',
    size     => 2772,
    commits  => 4,
    first_revision => 'mkanat@everythingsolved.com-20070805031704-pxp4msygesk0fwi8',
    last_revision  => 'mkanat@es-compy-20070807070743-63zfyrindwf0vov4',
};

sub setup_repo {
    system("bzr init-repo -q --pack-0.92 --rich-root --no-trees t/repos/bzr");
    system("bzr branch -q -r10 http://bzr.everythingsolved.com/vci/trunk"
           . " t/repos/bzr/vci");
}

#########
# Tests #
#########

check_requirements('Bzr');

eval { setup_repo() if !-d 't/repos/bzr/.bzr'; 1; }
    || plan skip_all => "Unable to create bzr testing repo: $@";
    
plan tests => 51;

test_vcs({
    type          => 'Bzr',
    repo_dir      => 't/repos/bzr',
    project_name  => 'vci',
    mangled_name  => '/vci/',
    head_revision => 'mkanat@es-compy-20070807084314-z6d292cvjeberkww',
    num_commits   => 10,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::Abstract::Diff',
    expected_file => EXPECTED_FILE,
    revisions_global => 1,
    revisions_universal => 1,
});
