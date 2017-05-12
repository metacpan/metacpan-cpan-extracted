package VCI::VCS::Cvs::Directory;
use Moose;
extends 'VCI::Abstract::Directory';

use File::Path qw(mkpath);
use List::Util qw(maxstr);
use Path::Abstract::Underload;

has 'x_cvs_dir' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_revision { 'HEAD' }
sub _build_revno { shift->revision }

# XXX This should be optimized.
sub _build_time {
    my $self = shift;
    my @files = grep($_->isa('VCI::Abstract::File'), @{$self->contents});
    my @times = map { $_->time } @files;
    return maxstr(@times) || 0;
}

# XXX Currently this may not return things with the proper revision.
sub _build_contents {
    my $self = shift;
    my $output = $self->vci->x_do(
        args    => ['-n', 'update', '-d'],
        fromdir => $self->x_cvs_dir);
    my @lines = split("\n", $output);
    my @contents;
    foreach my $line (@lines) {
        next if  $line =~ /^cvs update: Updating \.$/;
        if ($line =~ /^U (.*)$/) {
            my $path = Path::Abstract::Underload->new($self->path, $1);
            push(@contents, $self->file_class->new(
                path => $path, project => $self->project,
                parent => $self));
        }
        elsif ($line =~  /New directory .(.+). -- ignored$/) {
            my $path = Path::Abstract::Underload->new($self->path, $1);
            push(@contents, $self->directory_class->new(
                path => $path, project => $self->project,
                parent => $self));
        }
        else {
            warn "Unparseable line during contents: $line";
        }
    }
    return \@contents;
}

# CVS doesn't really support listing files and directories from a remote
# connection. However, we can trick it into doing so with fake "CVS" dirs.
sub _build_x_cvs_dir {
    my $self = shift;
    my $dir = Path::Abstract::Underload->new($self->project->x_tmp, $self->path);
    my $cvsdir = Path::Abstract::Underload->new($dir, 'CVS')->stringify;
    if (!-d $cvsdir) {
        mkpath($cvsdir);
    
        open(my $root, ">$cvsdir/Root")
            || confess "Failed to open $cvsdir/Root: $!";
        print $root $self->repository->root;
        close($root);
        
        my $repo_name = $self->project->name . '/' . $self->path->stringify;
        # For local repos, you have to specify the full absolute path.
        if ($self->repository->x_is_local) {
            $repo_name = $self->repository->x_dir_part . '/' . $repo_name;
        }
        open(my $repository, ">$cvsdir/Repository")
            || confess "Failed to open $cvsdir/Repository: $!";
        print $repository $repo_name;
        close($repository);
        
        # Create a blank Entries file, or CVS complains.
        open(my $entries, ">$cvsdir/Entries")
            || confess "Failed to create $cvsdir/Entries: $!";;
        close($entries);
    }
    return $dir->stringify;
}

sub DEMOLISH {
    my $self = shift;
    File::Path::rmtree($self->x_cvs_dir) if defined $self->{x_cvs_dir};
}

__PACKAGE__->meta->make_immutable;

1;
