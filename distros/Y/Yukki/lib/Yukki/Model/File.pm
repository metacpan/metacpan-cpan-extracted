package Yukki::Model::File;
{
  $Yukki::Model::File::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Model';

use Class::Load;
use Digest::SHA1 qw( sha1_hex );
use Number::Bytes::Human qw( format_bytes );
use LWP::MediaTypes qw( guess_media_type );
use Path::Class;
use Yukki::Error qw( http_throw );

# ABSTRACT: the model for loading and saving files in the wiki


has path => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
);


has filetype => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    required   => 1,
    default    => 'yukki',
);


has repository => (
    is         => 'ro',
    isa        => 'Yukki::Model::Repository',
    required   => 1,
    handles    => {
        'make_blob'           => 'make_blob',
        'make_blob_from_file' => 'make_blob_from_file',
        'find_root'           => 'find_root',
        'branch '             => 'branch',
        'show'                => 'show',
        'make_tree'           => 'make_tree',
        'commit_tree'         => 'commit_tree',
        'update_root'         => 'update_root',
        'find_path'           => 'find_path',
        'fetch_size'          => 'fetch_size',
        'repository_name'     => 'name',
        'author_name'         => 'author_name',
        'author_email'        => 'author_email',
        'log'                 => 'log',
        'diff_blobs'          => 'diff_blobs',
    },
);


sub BUILDARGS {
    my $class = shift;

    my %args;
    if (@_ == 1) { %args = %{ $_[0] }; }
    else         { %args = @_; }

    if ($args{full_path}) {
        my $full_path = delete $args{full_path};

        my ($path, $filetype) = $full_path =~ m{^(.*)(?:\.(\w+))?$};

        $args{path}     = $path;
        $args{filetype} = $filetype;
    }

    return \%args;
}


sub full_path {
    my $self = shift;

    my $full_path;
    given ($self->filetype) {
        when (defined) { $full_path = join '.', $self->path, $self->filetype }
        default        { $full_path = $self->path }
    }

    return $full_path;
}


sub file_name {
    my $self = shift;
    my $full_path = $self->full_path;
    my ($file_name) = $full_path =~ m{([^/]+)$};
    return $file_name;
}


sub file_id {
    my $self = shift;
    return sha1_hex($self->file_name);
}


sub object_id {
    my $self = shift;
    return $self->find_path($self->full_path);
}


sub title {
    my $self = shift;

    if ($self->filetype eq 'yukki') {
        LINE: for my $line ($self->fetch) {
            if ($line =~ /^#\s*(.*)$/) {
                return $1;
            }
            elsif ($line =~ /:/) {
                my ($name, $value) = split m{\s*:\s*}, $line, 2;
                return $value if lc($name) eq 'title';
            }
            else {
                last LINE;
            }
        }
    }

    my $title = $self->file_name;
    $title =~ s/\.(\w+)$//g;
    return $title;
}


sub file_size {
    my $self = shift;
    return $self->fetch_size($self->full_path);
}


sub formatted_file_size {
    my $self = shift;
    return format_bytes($self->file_size);
}


sub media_type {
    my $self = shift;
    return guess_media_type($self->full_path);
}


sub store {
    my ($self, $params) = @_;
    my $path = $self->full_path;

    my (@parts) = split m{/}, $path;
    my $blob_name = $parts[-1];

    my $object_id;
    if ($params->{content}) {
        $object_id = $self->make_blob($blob_name, $params->{content});
    }
    elsif ($params->{filename}) {
        $object_id = $self->make_blob_from_file($blob_name, $params->{filename});
    }
    http_throw("unable to create blob for $path") unless $object_id;

    my $old_tree_id = $self->find_root;
    http_throw("unable to locate original tree ID for ".$self->branch)
        unless $old_tree_id;

    my $new_tree_id = $self->make_tree($old_tree_id, \@parts, $object_id);
    http_throw("unable to create the new tree containing $path\n")
        unless $new_tree_id;

    my $commit_id = $self->commit_tree($old_tree_id, $new_tree_id, $params->{comment});
    http_throw("unable to commit the new tree containing $path\n")
        unless $commit_id;

    $self->update_root($old_tree_id, $commit_id);
}


sub rename {
    my ($self, $params) = @_;
    my $old_path = $self->full_path;

    my (@new_parts) = split m{/}, $params->{full_path};
    my (@old_parts) = split m{/}, $old_path;
    my $blob_name = $old_parts[-1];

    my $object_id = $self->object_id;

    my $old_tree_id = $self->find_root;
    http_throw("unable to locate original tree ID for ".$self->branch)
        unless $old_tree_id;

    my $new_tree_id = $self->make_tree(
        $old_tree_id, \@old_parts, \@new_parts, $object_id);
    http_throw("unable to create the new tree renaming $old_path to $params->{full_path}\n")
        unless $new_tree_id;

    my $commit_id = $self->commit_tree($old_tree_id, $new_tree_id, $params->{comment});
    http_throw("unable to commit the new tree renaming $old_path to $params->{full_path}\n")
        unless $commit_id;

    $self->update_root($old_tree_id, $commit_id);

    return Yukki::Model::File->new(
        app        => $self->app,
        repository => $self->repository,
        full_path  => $params->{full_path},
    );
}


sub remove {
    my ($self, $params) = @_;
    my $old_path = $self->full_path;

    my (@old_parts) = split m{/}, $old_path;

    my $old_tree_id = $self->find_root;
    http_throw("unable to locate original tree ID for ".$self->branch)
        unless $old_tree_id;

    my $new_tree_id = $self->make_tree($old_tree_id, \@old_parts);
    http_throw("unable to create the new tree removing $old_path\n")
        unless $new_tree_id;

    my $commit_id = $self->commit_tree($old_tree_id, $new_tree_id, $params->{comment});
    http_throw("unable to commit the new tree removing $old_path\n")
        unless $commit_id;

    $self->update_root($old_tree_id, $commit_id);
}


sub exists {
    my $self = shift;

    my $path = $self->full_path;
    return $self->find_path($path);
}


sub fetch {
    my $self = shift;

    my $path = $self->full_path;
    my $object_id = $self->find_path($path);

    return unless defined $object_id;

    return $self->show($object_id);
}


sub has_format {
    my ($self, $media_type) = @_;
    $media_type //= $self->media_type;

    my @formatters = $self->app->formatter_plugins;
    for my $formatter (@formatters) {
        return 1 if $formatter->has_format($media_type);
    }

    return '';
}


sub fetch_formatted {
    my ($self, $ctx, $position) = @_;
    $position //= 0;

    my $media_type = $self->media_type;

    my $formatter;
    for my $plugin ($self->app->formatter_plugins) {
        return $plugin->format({
            context    => $ctx,
            file       => $self,
            position   => $position,
        }) if $plugin->has_format($media_type);
    }

    return $self->fetch;
}


sub history {
    my $self = shift;
    return $self->log($self->full_path);
}


sub diff {
    my ($self, $object_id_1, $object_id_2) = @_;
    return $self->diff_blobs($self->full_path, $object_id_1, $object_id_2);
}


sub file_preview {
    my ($self, %params) = @_;

    Class::Load::load_class('Yukki::Model::FilePreview');
    return Yukki::Model::FilePreview->new(
        %params,
        app        => $self->app,
        repository => $self->repository,
        path       => $self->path,
    );
}


sub list_files {
    my ($self) = @_;
    return $self->repository->list_files($self->path);
}


sub parent {
    my $self = shift;

    my @parts = split m{/}, $self->path;
    return if @parts == 1;

    pop @parts;
    return Yukki::Model::File->new(
        app        => $self->app,
        repository => $self->repository,
        path       => join('/', @parts),
    );
}

1;

__END__

=pod

=head1 NAME

Yukki::Model::File - the model for loading and saving files in the wiki

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  my $repository = $app->model('Repository', { repository => 'main' });
  my $file = $repository->file({
      path     => 'foobar',
      filetype => 'yukki',
  });

=head1 DESCRIPTION

Tools for fetching files from the git repository and storing them there.

=head1 EXTENDS

L<Yukki::Model>

=head1 ATTRIBUTES

=head2 path

This is the path to the file in the repository, but without the file suffix.

=head2 filetype

The suffix of the file. Defaults to "yukki".

=head2 repository

This is the the L<Yukki::Model::Repository> the file will be fetched from or
stored into.

=head1 METHODS

=head2 BUILDARGS

Allows C<full_path> to be given instead of C<path> and C<filetype>.

=head2 full_path

This is the complete path to the file in the repository with the L</filetype>
tacked onto the end.

=head2 file_name

This is the base name of the file.

=head2 file_id

This is a SHA-1 of the file name in hex.

=head2 object_id

This is the git object ID of the file blob.

=head2 title

This is the title for the file. For most files this is the file name. For files with the "yukki" L</filetype>, the title metadata or first heading found in the file is used.

=head2 file_size

This is the size of the file in bytes.

=head2 formatted_file_size

This returns a human-readable version of the file size.

=head2 media_type

This is the MIME type detected for the file.

=head2 store

  $file->store({ 
      content => 'text to put in file...', 
      comment => 'comment describing the change',
  });

  # OR
  
  $file->store({
      filename => 'file.pdf',
      comment  => 'comment describing the change',
  });

This stores a new version of the file, either from the given content string or a
named local file.

=head2 rename

  my $new_file = $file->rename({
      full_path => 'renamed/to/path.yukki',
      comment   => 'renamed the file',
  });

Renames the file within the repository. When complete, this method returns a reference to the L<Yukki::Model::File> object representing the new path.

=head2 remove

  $self->remove({ comment => 'removed the file' });

Removes the file from the repostory. The file is not permanently deleted as it still exists in the version history. However, as of this writing, the API here does not provide any means for getting at a deleted file.

=head2 exists

Returns true if the file exists in the repository already.

=head2 fetch

  my $content = $self->fetch;
  my @lines   = $self->fetch;

Returns the contents of the file.

=head2 has_format

  my $yes_or_no = $self->has_format($media_type);

Returns true if the named media type has a format plugin.

=head2 fetch_formatted

  my $html_content = $self->fetch_formatted($ctx);

Returns the contents of the file. If there are any configured formatter plugins for the media type of the file, those will be used to return the file.

=head2 history

  my @revisions = $self->history;

Returns a list of revisions. Each revision is a hash with the following keys:

=over

=item object_id

The object ID of the commit.

=item author_name

The name of the commti author.

=item date

The date the commit was made.

=item time_ago

A string showing how long ago the edit took place.

=item comment

The comment the author made about the comment.

=item lines_added

Number of lines added.

=item lines_removed

Number of lines removed.

=back

=head2 diff

  my @chunks = $self->diff('a939fe...', 'b7763d...');

Given two object IDs, returns a list of chunks showing the difference between two revisions of this path. Each chunk is a two element array. The first element is the type of chunk and the second is any detail for that chunk.

The types are:

    "+"    This chunk was added to the second revision.
    "-"    This chunk was removed in the second revision.
    " "    This chunk is the same in both revisions.

=head2 file_preview

  my $file_preview = $self->file_preview(
      content => $content,
  );

Takes this file and returns a L<Yukki::Model::FilePreview> object, with the file contents "replaced" by the given content.

=head2 list_files

  my @files = $self->list_files;

List the files attached to/under this file path.

=head2 parent

  my $parent = $self->parent;

Return a L<Yukki::Model::File> representing the parent path of the current file within the current repository. For example, if the current L<path> is:

  foo/bar/baz.pdf

the parent of it will be:

  foo/bar.yukki

This returns C<undef> if the current file is at the root of the repository.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
