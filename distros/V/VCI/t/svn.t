#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Cwd qw(cwd abs_path);
use Digest::MD5 qw(md5_hex);
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    EmptyFile
    GQProtocol_BattleField2.inc.php
    GQProtocol_BattleField2142.inc.php
    GQProtocol_HalfLife.inc.php
    GQProtocol_SourceEngine.inc.php
    GQTemplate_BF2142_compact.inc.php
    GQTemplate_BF2_compact.inc.php
    GQTemplate_CSS_compact.inc.php
    GQTemplate_Dump.inc.php
    GQTemplate_FEAR_compact.inc.php
    License.txt
    License.txt2
    Moved
    NewFile
    emptydir
    newdir
    newdir/EmptyFile
    newdir/NewFile
)];

use constant EXPECTED_COMMIT => {
    revision  => 12,
    revno     => 12,
    uuid      => md5_hex('file://' . abs_path('t/repos/svn') . '/', 12),
    message   => "This is the commit for testing VCI.\n"
                 . "And it has a two-line message.",
    committer => 'mkanat',
    time      => '2007-09-03T06:46:21',
    timezone  => '+0000',
    modified  => [qw(GQProtocol_BattleField2.inc.php
                     GQProtocol_BattleField2142.inc.php)],
    added     => [qw(EmptyFile NewFile newdir/NewFile newdir/EmptyFile
                     emptydir License.txt2 Moved newdir)],
    removed   => [qw(GQProtocol_GameSpy.inc.php GQProtocol_GameSpy2.inc.php
                     GameQuery.php)],
    moved     => {},
    copied    => { 'License.txt2' => { 'License.txt' => 11   },
                   'Moved'        => { 'GameQuery.php' => 11 },
                 },
    added_empty => { EmptyFile => 1, 'newdir/EmptyFile' => 1, emptydir => 1,
                     newdir => 1 },
};

use constant EXPECTED_FILE => {
    path     => 'GQProtocol_SourceEngine.inc.php',
    revision => 11,
    revno    => 11,
    time     => '2007-08-13T04:54:44',
    timezone => '+0000',
    size     => 11819,
    commits  => 3,
    last_revision  => '11',
    first_revision => '4',
};

sub setup_repo {
    eval { require LWP::UserAgent } || die "LWP::Useragent not installed";
    my $ua = LWP::UserAgent->new(timeout => 10,
                                 agent => 'vci-test/' . VCI->VERSION);

    my $response =
        $ua->mirror("http://vci.everythingsolved.com/repos/svn/svn-test-2007-09-02.tar.bz2",
                    'svn-test.tar.bz2');
    if (!$response->is_success) {
        die $response->status_line;
    }
    
    system('bunzip2 ./svn-test.tar.bz2') && die 'Failed to bunzip';
    system('tar -x -f ./svn-test.tar') && die 'Failed to untar';
    unlink 'svn-test.tar';
}

#########
# Tests #
#########

my $repo_success = eval {
    my $cwd = cwd();
    chdir 't/repos/svn/' || die $!;
    setup_repo() if !-d 't/repos/svn/db';
    chdir $cwd || die "$cwd: $!"; 
};
$repo_success || plan skip_all => "Unable to create svn testing repo: $@";

plan skip_all => "svn requirements not installed" if !feature_enabled('svn');

plan tests => 54;

test_vcs({
    type          => 'Svn',
    repo_dir      => 'file://t/repos/svn',
    num_projects  => 3,
    has_root_proj => 1,
    project_name  => 'trunk',
    mangled_name  => '/trunk/',
    head_revision => 12,
    num_commits   => 8,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::Abstract::Diff',
    copy_in_diff  => 1,
    expected_file => EXPECTED_FILE,
    other_tests   => \&other_tests,
    revisions_global => 1,
    revisions_universal => 0,
});

sub other_tests {
    my $params = shift;

    my $project = $params->{project};
    my $file = $params->{file};

    # Svn has an optimization for get_commit(revision =>) that has
    # to be tested on a project without a {history}.
    delete $project->{history};
    my $expected_rev = EXPECTED_COMMIT->{revision};
    isa_ok($project->get_commit(revision => $expected_rev),
           "VCI::VCS::Svn::Commit", '$project->get_commit(revision => ' 
                                    . "$expected_rev) without History");

   # Svn has an optimization for history() when the parent Project
   # doesn't have a History.
   delete $file->project->{history};
   my $history;
   isa_ok($history = $file->history, "VCI::VCS::Svn::History",
          '$file->history without Project history');
   # And we do this just as a sanity check.
   is(scalar @{$history->commits}, EXPECTED_FILE->{commits},
      "File above has " . EXPECTED_FILE->{commits} . " commits");
}
