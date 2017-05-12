package VCI::VCS::Bzr::Project;
use Moose;

use Path::Abstract::Underload;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

sub _build_history {
    my $self = shift;
    my $full_path = $self->repository->root . $self->name;
    my $xml_string = $self->vci->x_do(
        args => [qw(log --show-ids --xml), $full_path]);
    return $self->history_class->x_from_xml($xml_string, $self);
}

__PACKAGE__->meta->make_immutable;

1;
