package VCI::VCS::Git::Repository;
use Moose;

extends 'VCI::Abstract::Repository';

sub BUILD { shift->_root_always_ends_with_slash }

sub _build_projects {
    my $self = shift;
    my $root = $self->root;
    my @dirs = glob "$root*/.git";
    # XXX Path Separator assumption
    @dirs = map { s|/.git$||; s|^\Q$root\E||; $_ } @dirs;
    my @bare_dirs = glob "$root/*/objects/pack/*.idx";
    @bare_dirs = map { s|^\Q$root\E||; s|/objects/pack/.*idx$||; $_ } @bare_dirs;
    return [map { $self->project_class->new(name => $_, repository => $self) }
                (@dirs, @bare_dirs)];
}

__PACKAGE__->meta->make_immutable;

1;
