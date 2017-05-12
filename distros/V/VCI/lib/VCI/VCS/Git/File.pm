package VCI::VCS::Git::File;
use Moose;

extends 'VCI::Abstract::File';
with 'VCI::VCS::Git::Committable';

sub _build_content {
    my $self = shift;
    my $rev  = $self->revision;
    my $path = $self->path->stringify;
    return $self->project->x_do('show', ["$rev:$path"], 1);
}

__PACKAGE__->meta->make_immutable;

1;
