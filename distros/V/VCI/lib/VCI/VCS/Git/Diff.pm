package VCI::VCS::Git::Diff;
use Moose;

extends 'VCI::Abstract::Diff';

sub _transform_filename {
    my ($self, $name) = @_;
    $name =~ s|^[ab]/||;
    return $name;
}

__PACKAGE__->meta->make_immutable;

1;
