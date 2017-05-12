package Support;
use strict;
use Class::MOP;
use File::Spec;
use Test::More;
use Test::Exception;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test_vcs all_modules feature_enabled check_requirements);

use constant FEATURES => {
    git => { module => 'Git' },
    svn => { module => 'SVN::Core', version => '1.2.0' },
};

sub test_vcs {
    my $params = shift;
    
    my $type              = $params->{type};
    my $repo_dir          = $params->{repo_dir};
    my $num_projects      = $params->{num_projects} || 1;
    my $has_root_proj     = $params->{has_root_proj};
    my $project_name      = $params->{project_name};
    my $mangled_name      = $params->{mangled_name};
    my $head_revision     = $params->{head_revision};
    my $num_commits       = $params->{num_commits};
    my $commits_rec       = $params->{commits_rec} || $params->{num_commits};
    my $expected_contents = $params->{expected_contents};
    my $expected_commit   = $params->{expected_commit};
    my $diff_type         = $params->{diff_type};
    my $copy_in_diff      = $params->{copy_in_diff};
    my $expected_file     = $params->{expected_file};
    
    my $class = "VCI::VCS::$type";
    # Connecting
    my $repo;
    isa_ok($repo = VCI->connect(repo => $repo_dir, type => $type,
            debug => $ENV{VCI_TEST_DEBUG}),
           "${class}::Repository", 'Repository');
    
    # revisions_are_*
    is($repo->vci->revisions_are_global, $params->{revisions_global},
       'revisions_are_global');
    is($repo->vci->revisions_are_universal, $params->{revisions_universal},
       'revisions_are_universal');
    
    # Repository
    my $project;
    isa_ok($project = $repo->get_project(name => $project_name),
           "${class}::Project", $project_name);
    # Get a second copy of the Project with a strange name and make sure that
    # the name is still the same.
    my $project2;
    isa_ok($project2 = $repo->get_project(name => $mangled_name),
           "${class}::Project", "$mangled_name");
    is($project2->name, $project->name, '$project->name eq $project2->name');

    # Make sure that ->projects works correctly on this test repo.
    my $projects;
    isa_ok($projects = $repo->projects, 'ARRAY', '$repo->projects');
    SKIP: {
        skip 'incorrect projects returned', 1
            unless cmp_ok(scalar(@$projects), '==', $num_projects,
                          "Only $num_projects project returned");
        is($project->name, $projects->[0]->name,
           '$repo->projects returns same Project');
    }
    if ($has_root_proj) {
        isa_ok($repo->root_project, "${class}::Project", '$repo->root_project');
    }
    else {
        ok(!defined $repo->root_project, '$repo->root_project is undef');
    }
        
    # Project
    # We check head_revision first so that for drivers that optimize it,
    # $project->history hasn't already been set.
    is($project->head_revision, $head_revision, 'Head revision correct');
    my $history;
    lives_and { isa_ok($history = $project->history, "${class}::History") }
           '$project->history';
    cmp_ok(scalar @{ $history->commits }, '==', $num_commits,
           "History has $num_commits commits");
    is($history->commits->[-1]->revision, $head_revision,
       'Last commit has head revision');

    # Directory    
    my $root_dir;
    isa_ok($root_dir = $project->root_directory, "${class}::Directory",
           '$project->root_directory');
    my @paths;
    lives_ok { @paths = _get_all_paths($root_dir) }
             'Getting all paths from $root_dir';
    is_deeply([sort @paths], [sort @$expected_contents],
              'Correct paths returned');
    my $history_rec;
    isa_ok($history_rec = $root_dir->contents_history_recursive,
           "${class}::History", '$root_dir->contents_history_recursive');
    cmp_ok(scalar @{ $history_rec->commits }, '==', $commits_rec,
           "Recursive History has $commits_rec commits.");
    
    # History and Commits
    my $commit;
    my $expected_rev = $expected_commit->{revision};
    isa_ok($commit = $project->get_commit(revision => $expected_rev),
           "${class}::Commit",
           '$project->get_commit(revision => ' . "$expected_rev)");
    is($commit->revno, $expected_commit->{revno},'Commit revno');
    is($commit->message, $expected_commit->{message}, 'Commit message');
    is($commit->committer, $expected_commit->{committer}, 'Commit committer');
    is($commit->time->iso8601, $expected_commit->{time}, 'Commit time');
    is($commit->time->strftime('%z'), $expected_commit->{timezone},
       'Commit timezone');
    is($commit->uuid, $expected_commit->{uuid}, 'Commit uuid');
    my $commit_at;
    isa_ok($commit_at = $project->get_commit(time => $commit->time),
           "${class}::Commit",
           '$project->get_commit(time => ' . $commit->time . ')');
    is($commit_at->revision, $commit->revision,
       "'time' and 'revision' return the same Commit");
    my $right_after = $commit->time->clone->add(seconds => 1);
    my $commit_aob;
    isa_ok($commit_aob = $project->get_commit(at_or_before => $right_after),
           "${class}::Commit",
           '$project->get_commit(at_or_before => ' . "$right_after)");
    is($commit_aob->revision, $commit->revision,
       "'at_or_before' and 'revision' return the same Commit");
    
    is_deeply([sort map { $_->path->stringify } @{ $commit->modified }],
              [sort @{$expected_commit->{modified}}], 'Commit modified');
    is_deeply([sort map { $_->path->stringify } @{ $commit->added }],
              [sort @{$expected_commit->{added}}], 'Commit added');
    is_deeply([sort map { $_->path->stringify } @{ $commit->removed }],
              [sort @{$expected_commit->{removed}}], 'Commit removed');
    
    my $moved = $commit->moved;
    my %moved_hash = map { $_ => { $moved->{$_}->path->stringify =>
                                   $moved->{$_}->revision } }
                          keys(%$moved);
    is_deeply(\%moved_hash, $expected_commit->{moved}, 'Commit moved');
    
    my $copied = $commit->copied;
    my %copied_hash = map { $_ => { $copied->{$_}->path->stringify =>
                                    $copied->{$_}->revision } }
                          keys(%$copied);
    is_deeply(\%copied_hash, $expected_commit->{copied}, 'Commit copied');
    
    # Diffs
    my $diff;
    isa_ok($diff = $commit->as_diff, $diff_type, '$commit->as_diff');
    my @expected_files = (
        @{ $expected_commit->{modified} },
        @{ $expected_commit->{removed} });
    # Added files should only be in the diff if they weren't copied.
    foreach my $path (@{ $expected_commit->{added} }) {
        push(@expected_files, $path)
            unless ((exists $expected_commit->{copied}->{$path} && !$copy_in_diff)
                    || exists $expected_commit->{added_empty}->{$path});
    }
#    push(@expected_files, values %{ $expected_commit->{moved} });
    # If a file is in "moved" but not in "modified", it won't show up unless
    # we do this.
#    foreach my $new_name (keys %{ $expected_commit->{moved} }) {
#        push(@expected_files, $new_name)
#            unless grep { $_ eq $new_name } @expected_files;
#    }
    is_deeply([sort map { $_->path } @{ $diff->files }], [sort @expected_files],
              'Diff files are correct');
    
    # Committable/File
    my $contents_file;
    isa_ok($contents_file = $project->get_file(path => $expected_file->{path}),
           "${class}::File", $expected_file->{path});
    is($contents_file->revision, $expected_file->{revision},
       '$contents_file revision');
    is($contents_file->revno, $expected_file->{revno}, '$contents_file revno');
    is($contents_file->time->iso8601, $expected_file->{time},
       '$contents_file time');
    is($contents_file->time->strftime('%z'), $expected_file->{timezone},
       '$contents_file timezone');
    is(length($contents_file->content), $expected_file->{size},
       '$expected_file->content size');
    my $rev_file;
    isa_ok($rev_file = $project->get_file(path => $expected_file->{path},
                                          revision => $expected_file->{revision}),
           "${class}::File", '$project->get_file(path, revision)');
    is($rev_file->time, $contents_file->time, 'Files have the same time');
    
    # Committable History
    my $item_history;
    isa_ok($item_history = $contents_file->history, "${class}::History",
           '$contents_file->history');
    is(scalar @{$item_history->commits}, $expected_file->{commits},
       "Item History has " .$expected_file->{commits} . " commits");
    my $last_revision;
    isa_ok($last_revision = $contents_file->last_revision,
           "${class}::File", '$contents_file->last_revision');
    is($last_revision->revision, $expected_file->{last_revision},
       "Last revision ID correct");
    my $first_revision;
    isa_ok($first_revision = $contents_file->first_revision, "${class}::File",
           '$contents_file->first_revision');
    is($first_revision->revision, $expected_file->{first_revision},
       "First revision ID correct");

    if ($params->{other_tests}) {
        $params->{other_tests}->({
            project => $project, file => $contents_file });
    }
}

sub _get_all_paths {
    my $dir = shift;
    my $contents = $dir->contents;
    my @paths = map { $_->path->stringify } @$contents;
    foreach my $inner_dir (grep {$_->isa('VCI::Abstract::Directory')} @$contents) {
        push(@paths, _get_all_paths($inner_dir));
    }
    return @paths;
}

sub feature_enabled {
    my $feature = shift;
    my $module = FEATURES->{$feature}->{module};
    my $version = FEATURES->{$feature}->{version};
    my $loaded = eval { Class::MOP::load_class($module, -version => $version) };
    return $loaded ? 1 : 0;
}

sub check_requirements {
    my ($type) = @_;
    my $class = "VCI::VCS::$type";
    Class::MOP::load_class($class);
    my @need = $class->missing_requirements;
    if (@need) {
        plan skip_all => "missing: " . join(', ', @need);
    }
}

# Stolen from Test::Pod::Coverage
sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @modules;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" && $_ ne '.bzr' }
                             @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir( $file );
            shift @parts if @parts && exists $starters{$parts[0]};
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for ( @parts ) {
                if ( /^([a-zA-Z0-9_\.\-]+)$/ && ($_ eq $1) ) {
                    $_ = $1;  # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", @parts );
            push( @modules, $module );
        }
    } # while

    return @modules;
}
