package VCI::VCS::Bzr::File;
use Moose;

extends 'VCI::VCS::Bzr::Committable', 'VCI::Abstract::File';

sub _build_content {
    my $self = shift;
    my $vci = $self->vci;
    my $rev = $self->revision;
    my $path = $self->repository->root . $self->project->name . '/'
               . $self->path->stringify;
    return $vci->x_do(args => [qw(cat --name-from-revision),
                               "--revision=revid:$rev", $path]);
}

__PACKAGE__->meta->make_immutable;

1;
