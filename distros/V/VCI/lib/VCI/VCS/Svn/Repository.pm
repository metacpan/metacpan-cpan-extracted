package VCI::VCS::Svn::Repository;
use Moose;

use Cwd qw (abs_path);
use SVN::Ra;

use VCI::Util qw(detaint);

extends 'VCI::Abstract::Repository';

has 'x_ra' => (is => 'ro', isa => 'SVN::Ra', lazy => 1,
               default => sub { SVN::Ra->new(url => shift->x_root_noslash) });

# The SVN libraries throw an error in certain cases if the root ends with
# a slash.
has 'x_root_noslash' => (is => 'ro', isa => 'Str', lazy => 1,
    default => sub { my $root = shift->root; $root =~ s|/+\s*$||; $root });

sub BUILD {
    my $self = shift;
    # Make relative local roots into absolute roots.
    my $root = $self->root;
    if ($root =~ m|^file://|) {
        $root =~ m|^file://(localhost/)?(.*)$|;
        my $dir = abs_path($2);
        # Because of Abstract::Repository::BUILD, we know that $root is not
        # tainted. Thus turning it into an absolute path should be safe.
        # Theoretically there could be dangerous things in the absolute
        # path that aren't in the relative path, but we only use this root
        # via the SVN API, so we should be safe.
        detaint($dir);
        $self->{root} = "file://$dir";
    }
    $self->_root_always_ends_with_slash;
}

sub _build_projects {
    my $self = shift;
    my $contents = $self->root_project->root_directory->contents;
    my @projects;
    foreach my $item (@$contents) {
        next if !$item->isa('VCI::VCS::Svn::Directory');
        my $project = $self->project_class->new(
            name => $item->name, repository => $self,
            root_directory => $item);
        push(@projects, $project);
    }
    
    return \@projects;
}

sub _build_root_project { $_[0]->_root_project; }

__PACKAGE__->meta->make_immutable;

1;
