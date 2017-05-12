package VCI::VCS::Bzr::Repository;
use Moose;
use MooseX::Method;

extends 'VCI::Abstract::Repository';

sub BUILD { shift->_root_always_ends_with_slash }

# Note that "projects" won't work for some remote repositories, because of
# limitations of "bzr branches".
sub _build_projects {
    my $self = shift;
    my $branch_names = $self->vci->x_do(args => ['branches', $self->root]);
    my @projects;
    foreach my $branch (split("\n", $branch_names)) {
        push(@projects, $self->project_class->new(name => $branch,
                                                  repository => $self));
    }
    return \@projects;
}

__PACKAGE__->meta->make_immutable;

1;
