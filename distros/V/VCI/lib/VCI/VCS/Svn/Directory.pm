package VCI::VCS::Svn::Directory;
use Moose;

use Path::Abstract::Underload;
use SVN::Core;

with 'VCI::VCS::Svn::Committable';
extends 'VCI::Abstract::Directory';

# There's a bug in the SVN API that causes it to segfault if you don't
# die inside an error handler. So in order to get details about an error,
# we die with a reference to the error.
sub _x_handle_svn_failure { die $_[0]; }

sub _build_contents {
    my $self = shift;
    my $project = $self->project;
    my $vci = $project->vci;
    my $ra = $project->repository->x_ra;
    my $dir_path  = Path::Abstract::Underload->new($project->name, $self->path);
    print STDERR "Getting contents for " . $dir_path->stringify
                 . " rev " . $self->revision . "\n"
        if $vci->debug;

    my @info;
    {
        local $SVN::Error::handler = \&_x_handle_svn_failure;
        eval { @info = $ra->get_dir($dir_path->stringify, $self->revision) };
    }
        
    # When a directory has been copied, and hasn't been modified since,
    # SVN says the last revision of its contents is the revision the directory
    # was copied *from*.
    # However, when you try to get the contents of the path at that
    # revision, SVN throws error 175007, meaning "path not found."
    # So, to handle that, we find the place our parent was copied from,
    # and get the contents of that, at that revision.
    if (ref($@) && $@->apr_err == 175007) {
        my $history = $self->history;
        my $parent_from;
        foreach my $commit (@{$history->commits}) {
            $parent_from = $commit->copied->{$self->parent->path->stringify};
            last if $parent_from;
        }
        SVN::Error::croak_on_error($@) if !$parent_from;
        $@->clear();
        my ($my_source) = grep ($_->name eq $self->name,
                                @{$parent_from->contents});
        if ($vci->debug) {
            print STDERR $self->path, " was copied from ", $my_source->path,
                         "\n";
        }
        return $my_source->contents;
    }
    else {
        SVN::Error::croak_on_error($@);
    }
    
    my $svn_contents = shift @info;
    my @contents;
    foreach my $name (keys %$svn_contents) {
        my $item = $svn_contents->{$name};
        my $path = Path::Abstract::Underload->new($self->path, $name);
        if ($item->kind == $SVN::Node::dir) {
            my $dir = VCI::VCS::Svn::Directory->new(
                path => $path, project => $project, parent => $self,
                x_info => $item);
            push(@contents, $dir);
        }
        elsif ($item->kind == $SVN::Node::file) {
            my $file = $self->file_class->new(
                path => $path, project => $project, parent => $self,
                x_info => $item);
            push(@contents, $file);
        }
    }
    
    return \@contents;
}

# We have to do this because ->isa File or Directory never
# returns true on a FileOrDirectory.
sub _me_from {
    my $self = shift;
    my $orig_class = blessed $self;
    bless $self, 'VCI::VCS::Svn::FileOrDirectory';
    my $ret = $self->SUPER::_me_from(@_);
    bless $self, $orig_class;
    bless $ret, $orig_class;
    return $ret;
};

__PACKAGE__->meta->make_immutable;

1;
