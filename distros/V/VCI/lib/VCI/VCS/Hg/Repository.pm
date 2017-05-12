package VCI::VCS::Hg::Repository;
use Moose;
use MooseX::Method;

use VCI::Util;

extends 'VCI::Abstract::Repository';

sub BUILD { shift->_root_always_ends_with_slash }

# XXX Probably need to make Repository::Web and Repository::Local.

# Mostly uses hgweb, right now.
method 'x_get' => positional (
     { isa => 'VCI::Type::Path', coerce => 1, required => 1 },
) => sub {
    my ($self, $path) = @_;
    my $full_path = $self->root . $path->stringify;
    if ($self->vci->debug) {
        print STDERR "Getting $full_path\n";
    }
    my $result = $self->vci->x_ua->get($full_path);
    if (!$result->is_success) {
        confess("Error getting $full_path: " . $result->status_line);
    }
    return $result->content;
};

sub _build_projects {
    my $self = shift;
    my $list = $self->x_get('?style=raw');
    my @lines = split("\n", $list);
    # Get the root so that we can trim the directory part from project names.
    my $root = $self->root;
    $root =~ s|^http://[^/]+||;
    my @projects;
    foreach my $dir (@lines) {
        next if $dir eq '';
        $dir =~ s|^\Q$root\E||;
        push(@projects, $self->project_class->new(name => $dir,
                                                  repository => $self));
    }
    return \@projects;
}

__PACKAGE__->meta->make_immutable;

1;
