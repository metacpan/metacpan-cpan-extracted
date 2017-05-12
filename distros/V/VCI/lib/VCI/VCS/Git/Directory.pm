package VCI::VCS::Git::Directory;
use Moose;

extends 'VCI::Abstract::Directory';
with 'VCI::VCS::Git::Committable';

# XXX This should probably be optimized to not build a File object for
#     every file in the whole tree--it's a bit slow on the kernel sources
#     (over 20,000 files).
sub _build_contents {
    my $self = shift;
    my @path_part;
    @path_part = ('--', $self->path->stringify) unless $self->path->is_empty;
    my $files = $self->project->x_do('ls-tree',
        ['-r',  $self->revision, @path_part]);
    
    @$files = map { s/^\d+ \w+ \S+\s+//; $_ } @$files;
    
    # Get the directory names from the output
    my %dirs;
    foreach my $line (@$files) {
        # XXX This assumes the path separator is always /.
        if ($line =~ m|^(.+)/[^/]+$|) {
            $dirs{$1} = 1;
        }
    }
    
    # Make sure that every dir has a parent in the list.
    my @new_dirs;
    my @check_dirs = keys %dirs;
    my $found_parent = 1;
    while ($found_parent) {
        $found_parent = 0;
        foreach my $dir (@check_dirs) {
            # If this directory has a parent... (XXX path separator assumption)
            if ($dir =~ m|^(.+)/[^/]+$|) {
                my $parent_dir = $1;
                # And that parent isn't already in the list...
                if (!$dirs{$parent_dir}) {
                    push(@new_dirs, $parent_dir);
                    $found_parent = 1;
                }
            }
        }
    
        $dirs{$_} = 1 foreach @new_dirs;
        @check_dirs = @new_dirs;
    }
    
    $self->_set_contents_from_list([keys %dirs], $files, $self->path->stringify);
    return $self->{contents};
}

__PACKAGE__->meta->make_immutable;

1;
