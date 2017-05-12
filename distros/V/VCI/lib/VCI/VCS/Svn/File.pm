package VCI::VCS::Svn::File;
use Moose;

with 'VCI::VCS::Svn::Committable';
extends 'VCI::Abstract::File';

use File::Temp;

# XXX Must implement this.
sub _build_is_executable { undef }

sub _build_content {
    my $self = shift;
    my $project = $self->project;
    my $full_path = $project->repository->root . $project->name
                    . '/' . $self->path->stringify;
    my $ctx = $project->vci->x_client;
    my $temp = File::Temp->new;
    $ctx->cat($temp, $full_path, $self->revision);
    # For some reason, the actual file on disk contains data, but the
    # filehandle does not. So we have to re-open the file.
    close $temp; # Must close the file first or we can't read the whole thing.
    open(my $temp_read, $temp->filename);
    my $output;
    { local $/ = undef; $output = <$temp_read>; }
    close $temp_read;
    return $output;
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
