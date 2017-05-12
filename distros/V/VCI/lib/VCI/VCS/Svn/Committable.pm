package VCI::VCS::Svn::Committable;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Path::Abstract::Underload;

use VCI::Abstract::Committable;

# We could make this not required and build it with $ctx->info, but I want
# it to be required right now to make sure I don't forget to add it while
# constructing objects.
has 'x_info' => (is => 'ro', isa => 'SVN_Info', lazy_build => 1);

subtype 'SVN_Info'
    => as 'Object'
    => where { $_->isa('_p_svn_dirent_t') || $_->isa('_p_svn_info_t') };

sub BUILD {
    my $self = shift;
    if (!defined $self->{x_info} && !defined $self->{revision}) {
        confess("You must define x_info if you don't define revision");
    }
}

sub _build_history {
    my ($self) = @_;
    # We only use our custom implementation if the Project's History object
    # doesn't already exist.
    if (defined $self->project->{history}) {
        return VCI::Abstract::Committable::_build_history(@_);
    }
    
    my $commits = $self->project->_x_get_commits(
        path => Path::Abstract::Underload->new($self->project->name,
                                    $self->path->stringify)->stringify);
    return $self->history_class->new(commits => $commits,
                                     project => $self->project);
}

sub _build_revision {
    my $info = shift->x_info;
    if ($info->isa('_p_svn_info_t')) {
        return $info->last_changed_rev;
    }
    return $info->created_rev;
}

# SVN Returns times in microseconds.
sub _build_time {
    my $info = shift->x_info;
    if ($info->isa('_p_svn_info_t')) {
        return $info->last_changed_date / 1000000.0;
    }
    return $info->time / 1000000.0;
}

# This is mostly used to build "time" if you don't specify it during
# construction.
sub _build_x_info {
    my $self = shift;
    my $ctx = $self->vci->x_client;
    my $info;
    # XXX Need to check return for errors.
    my $full_path = Path::Abstract::Underload->new($self->name, $self->path);
    $ctx->info($self->repository->root . $full_path->stringify,
               undef, $self->revision, sub { $info = $_[1] }, 0);
    return $info;
}

1;
