package VCI::VCS::Hg::File;
use Moose;

extends 'VCI::Abstract::File';
with 'VCI::VCS::Hg::Committable';

# XXX From a Commit, we don't currently track if a file is executable or not.
sub _build_is_executable { undef }

sub _build_revision {
    my $self = shift;
    return $self->history->commits->[-1]->revision;
}

sub _build_content {
    my $self = shift;
    return $self->project->x_get(['raw-file', $self->revision, $self->path])
}

# Theoretically we could avoid this VCS interaction in situations where
# the Project history is already built and every single commit has "contents"
# populated, but that situation is rare enough that I don't think we need to
# optimize for it.
sub _build_history {
    my $self = shift;

    return $self->history_class->x_from_rss($self->path, $self->project);
}

__PACKAGE__->meta->make_immutable;

1;
