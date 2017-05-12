package VCI::VCS::Bzr::Directory;
use Moose;

extends 'VCI::VCS::Bzr::Committable', 'VCI::Abstract::Directory';

# XXX Currently always returns HEAD contents.
sub _build_contents {
    my $self = shift;
    my $root = $self->repository->root . $self->project->name;
    my $path = $root . "/" . $self->path->stringify; 
    # XXX We don't support symlinks yet.
    my $dir_names = $self->vci->x_do(
        args => ['ls', '--kind=directory', $path]);
    # Remove trailing slashes from the directory names, as required
    # by VCI::Type::Path.
    my @dirs = map { $_ =~ s{/$}{}; $_ } split("\n", $dir_names);
    my $file_names = $self->vci->x_do(
        args => ['ls', '--kind=file', $path]);
    $self->_set_contents_from_list(\@dirs, [split("\n", $file_names)], $root);
    return $self->{contents};
}

__PACKAGE__->meta->make_immutable;

1;
