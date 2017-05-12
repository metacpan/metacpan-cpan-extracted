package VCI::VCS::Bzr::Committable;
use Moose;

# When pulling moved files or directories out of logs, for the old file name,
# we know only the path of the old file and the revision where it was moved.
# So if the caller needs any other data, we will have to get it using this
# info.
has 'x_before' => (is => 'ro', isa => 'Str', predicate => 'has_x_before');

sub _build_time {
    my $self = shift;
    my $commit = $self->_x_this_commit;
    # Since we've got it now, set the revision if it's not set.
    if (!defined $self->{revision}) {
        $self->{revision} = $commit->revision;
    }
    return $commit->time;
}

sub _build_revision {
    my $self = shift;
    my $commit = $self->_x_this_commit;
    # Since we've got it now, set the time if it's not set.
    if (!defined $self->{_time}) {
        $self->{time} = $commit->time;
    }
    return $commit->revision;
}

sub _build_history {
    my $self = shift;
    my $full_path = $self->repository->root . $self->project->name
                    . '/' . $self->path->stringify;
    my $xml_string = $self->vci->x_do(
        args => [qw(log --show-ids --xml), $full_path]);
    return $self->history_class->x_from_xml($xml_string, $self->project);    
}

sub _x_this_commit {
    my $self = shift;

    if ($self->_has_revision) {
        # XXX To optimize, could check ->history before going to bzr.
        #     However, I'm not aware of any situation where we already have
        #     a history but don't have a time/revision.

        my $vci = $self->vci;
        my $obj_path = Path::Abstract::Underload->new($self->project->name, $self->path);
        my $full_path = $self->repository->root . $obj_path->stringify;
        my $rev = $self->revision;
        my $log = $vci->x_do(args => [qw(log --xml --show-ids),
                                      "--revision=revid:$rev", $full_path]);
        my $hist = $self->history_class->x_from_xml($log, $self->project);
        return $hist->commits->[0];
    }

    if ($self->has_x_before) {
        my @commits = @{ $self->history->commits };
        # We want to get the revision in this file's history right
        # before x_before.
        while (my $commit = shift @commits) {
            return $commit if $commits[0]->revision eq $self->x_before;
        }
    }
    
    return $self->last_revision;
}

__PACKAGE__->meta->make_immutable;

1;
