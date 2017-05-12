package VCI::VCS::Svn::Commit;
use Moose;

use File::Temp;

use VCI::VCS::Svn::FileOrDirectory;

extends 'VCI::Abstract::Commit';

sub x_from_log {
    my ($class, $project, $paths, $revno, $who, $when, $message) = @_;
    my (%copied, %moved);
    my %actions = ('A' => [], 'D' => [], 'M' => []);
    
    my $project_path = $project->name;
    foreach my $name (keys %$paths) {
        my $item = $paths->{$name};
        
        # Get just the "path" part of the path, without the Project path.
        # We do this directly with a regex instead of with Path::Abstract,
        # because Path::Abstract was a major performance bottleneck in tests
        # here.
        # XXX Can probably move back, now that we have 
        # Path::Abstract::Underload.
        my $path = $name;
        # We don't track changes to other Projects.
        ($path =~ s|^/\Q$project_path\E/||) || next;
        
        my $from_path = $item->copyfrom_path;
        if ($from_path) {
            # We were either copied from this project or a different one.
            my ($project_from, $from_file);

            my $orig_from_path = $from_path;
            if ($from_path =~ s|^/\Q$project_path\E/||) {
                $from_file = Path::Abstract::Underload->new($from_path);
                $project_from = $project;
            }
            else {
                # We just use the very first directory as the name of the
                # project we copied from. There's no way to know what part
                # of the path represents the branch.
                my $full_path = Path::Abstract::Underload->new($from_path);
                my $proj_from_name = ($full_path->list)[0];
                $project_from =
                    $project->repository->get_project(name => $proj_from_name);
                $from_file = Path::Abstract::Underload->new(($full_path->list)[1..-1]);
            }
            
            # XXX We don't currently track moves, because we can't reliably
            #     tell if the file was modified or not!
            # If the copyfrom_path was deleted in this rev, then this is
            # a move.
            #if (exists $paths->{$orig_from_path}
            #    && $paths->{$orig_from_path}->action eq 'D')
            #{
            #    $moved{$path} = $from_file->stringify;
                # Don't tag it as deleted, just as moved.
            #    delete $paths->{$orig_from_path};
            #    $actions{'D'} = [grep { $_ ne $from_file->stringify }
            #                          @{$actions{'D'}}];
            #}
            # Otherwise it's a copy.
            #else {
                my $copied_from = VCI::VCS::Svn::FileOrDirectory->new(
                    path => $from_file, project => $project_from,
                    revision => $item->copyfrom_rev);
                $copied{$path} = $copied_from;
            #}
        }
        
        my $obj = VCI::VCS::Svn::FileOrDirectory->new(
            path => $path, project => $project,
            revision => $revno, time => $when);
        my $action = $paths->{$name}->action;
        if ($action eq 'R') {
            push(@{ $actions{'M'} }, $obj);
        }
        else {
            push(@{$actions{$action}}, $obj);
        }
    }
        
    chomp($message);
    return $class->new(
        revision  => $revno,
        time      => $when,
        committer => $who,
        message   => $message,
        added     => $actions{'A'},
        removed   => $actions{'D'},
        modified  => $actions{'M'},
        #moved     => \%moved,
        copied    => \%copied,
        project   => $project,
    );
}

sub _build_as_diff {
    my $self = shift;
    my $path = $self->repository->root . $self->project->name;
    my $rev = $self->revision;
    my $previous_rev = $self->revision - 1;
    my $ctx = $self->vci->x_client;
    # Diff doesn't work unless these have filenames, for some reason.
    my $out = File::Temp->new;
    my $err = File::Temp->new;
    if ($self->vci->debug) {
        print STDERR "Getting diff for '$path' from $previous_rev to $rev\n";
    }
    $ctx->diff([], $path, int($previous_rev), $path, int($rev), 1, 0, 0,
               $out->filename, $err->filename);
    { local $/ = undef; $err = <$err>; $out = <$out> }
    confess($err) if $err;
    return $self->diff_class->new(raw => $out, project => $self->project);
}

__PACKAGE__->meta->make_immutable;

1;
