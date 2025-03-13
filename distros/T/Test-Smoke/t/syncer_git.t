#! perl -w
use strict;

use lib 't';
use TestLib;
use Test::More;

use Test::Smoke::Syncer;
use Test::Smoke::Util::Execute;
use File::Spec::Functions;
use Cwd 'abs_path';
use File::Temp 'tempdir';

my $gitbin = whereis('git');
plan skip_all => 'No gitbin found' if !$gitbin;

my $verbose = $ENV{SMOKE_DEBUG} ? 3 : $ENV{TEST_VERBOSE} ? $ENV{TEST_VERBOSE} : 0;
my $git = Test::Smoke::Util::Execute->new(command => $gitbin, verbose => $verbose);
(my $gitversion = $git->run('--version')) =~ s/\s*\z//;
$gitversion =~ s/^\s*git\s+version\s+//;

if ($gitversion =~ m/^1\.([0-5]|6\.[0-4])/) {
    $gitbin = "";
    plan skip_all => "Git version '$gitversion' is too old";
}

my $cwd = abs_path();
my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));
my $upstream = catdir($tmpdir, 'upstream');
my $working  = catdir($tmpdir, 'working');
my $playground = catdir($tmpdir, 'playground');
my $branchfile = catfile($tmpdir, 'default.gitbranch');
my $branchname = 'master'; # for compatibility with old and new git version

diag("Testing with git($gitbin) version: $gitversion");
my $diag;
SKIP: {
    pass("Git version $gitversion");

    # Set up a git repository in bare format to use for "upstream"
    $diag = $git->run(
        '-c', "init.defaultBranch=$branchname", init => '-q', '--bare', $upstream
    );
    unless (is($git->exitcode, 0, "git init $upstream")) {
        diag($diag);
        skip "git init failed!";
    }

    # Set up a working clone of upstream to add/change/remove files
    # we will push to "upstream" at the end of each "dev-cycle"
    $diag = $git->run(clone => $upstream, $working, '2>&1');
    unless (is($git->exitcode, 0, "git clone $upstream $working")) {
        diag($diag);
        skip "git clone failed!";
    }
    unless(chdir($working)) {
        diag("chdir to '$working' failed with error: $!");
        ok(0, "chdir working");
        die "chdir failed! Can't run the other tests (wrong cwd)";
    }
    unless (ok(-d catdir($working, '.git'), "Found .git directory")) {
        skip "git init failed! cannot find .git directory";
    }
    ok(mkpath(catdir($working, "Porting")), "mkdir $working/Porting");

    $git->run('config', 'user.name' => "syncer_git.t");
    is($git->exitcode, 0, "git config user.name");
    $git->run('config', 'user.email' => "syncer_git.t\@example.com");
    is($git->exitcode, 0, "git config user.email");

    put_file($gitversion => 'first.file');
    $git->run(add => q/first.file/);
    is($git->exitcode, 0, "git add first.file");

    put_file(<<"    CAT" => qw/Porting make_dot_patch.pl/);
#! $^X -w
(\@ARGV,\$/)=q/first.file/;
print <>;
    CAT
    $git->run(add => catfile('Porting', 'make_dot_patch.pl'));
    is($git->exitcode, 0, "git add Porting/make_dot_patch.pl");

    put_file(".patch" => q/.gitignore/);
    $git->run(add => '.gitignore');
    is($git->exitcode, 0, "git add .gitignore");

    $git->run(commit => '-m', "'We need a first file committed'", '2>&1');
    is($git->exitcode, 0, "git commit");

    $git->run(push => '--all', '2>&1');
    is($git->exitcode, 0, "git push --all");

    chdir(catdir(updir, updir));
    put_file("$branchname\n" => $branchfile);
    mkpath($playground);
    {
        my $syncer = Test::Smoke::Syncer->new(
            git => (
                gitbin        => $gitbin,
                gitorigin     => $upstream,
                gitdfbranch   => 'blead',
                gitbranchfile => $branchfile,
                gitdir        => catdir($playground, 'perl-from-upstream'),
                ddir          => catdir($playground, 'perl-current'),
                v             => $verbose,
            ),
        );
        isa_ok($syncer, 'Test::Smoke::Syncer::Git');
        is(
            $syncer->{gitdfbranch},
            'blead',
            "  Right defaultbranch: $syncer->{gitdfbranch}"
        );
        is(
            $syncer->get_git_branch,
            $branchname,
            "  from branchfile: chomp()ed value"
        );

        $syncer->sync();
	#ok( !$git->run( '-C', catdir($playground, 'git-perl'), 'ls-tree', '--name-only', 'master', '.patch' ),
	#    "  no .patch for gitdir");
        ok(-e catfile(catdir($playground, 'perl-current'), '.patch'), "  .patch created");

        # Update upstream/master
        chdir($working);
        put_file('any content' => q/new_file/);
        $git->run(add => 'new_file', '2>&1');
        is($git->exitcode, 0, "git add new_file");
        $git->run(commit => '-m', "'2nd commit message'", '2>&1');
        is($git->exitcode, 0, "git commit");
        $git->run(push => '--all', '2>&1');
        is($git->exitcode, 0, "git push --all");
        chdir(catdir(updir, updir));

        $syncer->sync();

        # Create upstream/smoke-me
        chdir($working);
        $git->run(checkout => '-b', 'smoke-me', '2>&1');
        is($git->exitcode, 0, "git checkout -b 'smoke-me'");
        put_file('new file in branch' => 'branch_file');
        $git->run(add => 'branch_file', '2>&1');
        is($git->exitcode, 0, "git add branch_file");
        $git->run(commit => '-m', "File in branch!", '2>&1');
        is($git->exitcode, 0, "git commit");
        $git->run(push => '--all', '2>&1');
        is($git->exitcode, 0, "git push --all");
        chdir(catdir(updir, updir));

        # Sync master.
        $syncer->sync();
	#ok(
	#    !-e catfile(catdir($playground, 'perl-current'), 'branch_file'),
	#    "branch_file doesn't exit after sync()!"
	#);

        # update a file in perl-current without commiting
        # this happens to patchlevel.h during smoke
        put_file('new content' => ($playground, qw/perl-current first.file/));

        # Change to 'branch' and sync
        put_file('smoke-me' => $branchfile);
        $syncer->sync();
        ok(
            -e catfile(catdir($playground, 'perl-current'), 'branch_file'),
            "branch_file does exit after sync()!"
        );
        {
            chdir(catdir($playground, 'perl-current'));
            my $git_out = $git->run('branch');
            is($git->exitcode, 0, "git branch");
            like($git_out, qr/\* \s+ smoke-me/x, "We're on the smoke-me branch");
            chdir(catdir(updir, updir));
        }
    }
}

done_testing();

END {
    if ($gitbin && $cwd) {
        chdir($cwd);
        note("$playground: ", rmtree($playground, $ENV{SMOKE_DEBUG}, 0));
        note("$upstream: ",   rmtree($upstream,   $ENV{SMOKE_DEBUG}, 0));
        note("$working ",     rmtree($working,    $ENV{SMOKE_DEBUG}, 0));
    }
}
