package Yukki::Model::Repository;
{
  $Yukki::Model::Repository::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Model';

use Yukki::Error qw( http_throw );
use Yukki::Model::File;

use DateTime::Format::Mail;
use Git::Repository v1.18;
use MooseX::Types::Path::Class;

# ABSTRACT: model for accessing objects in a git repository


has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has repository_settings => (
    is          => 'ro',
    isa         => 'Yukki::Settings::Repository',
    required    => 1,
    lazy        => 1,
    default     => sub { 
        my $self = shift;
        $self->app->settings->repositories->{$self->name};
    },
    handles     => {
        'title'  => 'name',
        'branch' => 'site_branch',
    },
);


has repository_path => (
    is          => 'ro',
    isa         => 'Path::Class::Dir',
    coerce      => 1,
    required    => 1,
    lazy_build  => 1,
);

sub _build_repository_path {
    my $self = shift;
    
    my $repo_settings = $self->repository_settings;
    return $self->locate_dir('repository_path', $repo_settings->repository);
}


has git => (
    is          => 'ro',
    isa         => 'Git::Repository',
    required    => 1,
    lazy_build  => 1,
);

sub _build_git {
    my $self = shift;
    return Git::Repository->new( git_dir => $self->repository_path );
}


sub author_name { shift->app->settings->anonymous->author_name }


sub author_email { shift->app->settings->anonymous->author_email }


sub make_tree {
    my $self = shift;
    my $base = shift;
    my $path = shift;

    my (@new_path, @old_path, $blob);

    # This is a rename
    if (ref $_[0]) {
        my $new_path = shift;
        $blob        = shift;
        @new_path    = @$new_path;
        @old_path    = @$path;
    }

    # Otherwise it's a store or delete
    else {
        $blob = shift;

        # Defined $blob -> Store
        if (defined $blob) {
            @new_path = @$path;
        }

        # Undefined $blob -> delete
        else {
            @old_path = @$path;
        }
    }

    my ($new_mode, $new_type, $new_name, $old_name, $remove_here);

    # Parts to add or update
    if (@new_path) {
        $new_name = shift @new_path;

        # Create the file here? 
        if (@new_path == 0) {
            $new_mode = '100644';
            $new_type = 'blob';
        }

        # Or we're still hunting down the tree
        else {
            $new_mode = '040000';
            $new_type = 'tree';
        }
    }

    # Parts to remove
    if (@old_path) {
        $old_name    = shift @old_path;
        $remove_here = (@old_path == 0);
    }

    my $git = $self->git;

    my $overwrite;
    my @new_tree;
    if (defined $base) {
        my @old_tree = $git->run('ls-tree', $base);
        for my $line (@old_tree) {
            my ($old_mode, $old_type, $old_object_id, $old_file) = split /\s+/, $line, 4;

            if (defined $new_name and $old_file eq $new_name) {

                # The file already exists, we are doing an update
                $overwrite++;

                # Cannot overwrite a file with a dir or a dir with a file
                http_throw("cannot replace $old_type $new_name with $new_type")
                    if $old_type ne $new_type;


                # Add the updated file to the tree
                if ($new_type eq 'blob') {
                    push @new_tree, "$new_mode $new_type $blob\t$new_name";
                }

                # The child tree contains both sides of the rename
                elsif ($old_name eq $new_name) {
                    my $tree_id = $self->make_tree($old_object_id, \@old_path, \@new_path, $blob);
                    push @new_tree, "$new_mode $new_type $tree_id\t$new_name";
                }

                # Add the updated tree contains only the rename/add
                else {
                    my $tree_id = $self->make_tree($old_object_id, \@new_path, $blob);
                    push @new_tree, "$new_mode $new_type $tree_id\t$new_name";
                }
            }

            # If $old_name != $new_name and it matches this file
            elsif (defined $old_name and $old_file eq $old_name) {

                # if ($remove_here) { ... do nothing ... }. The file will be
                # omitted. \o/

                # Not yet removed, but we need to hunt it down and remove it
                unless ($remove_here) {
                    my $tree_id = $self->make_tree($old_object_id, \@old_path);
                    push @new_tree, "040000 tree $tree_id\t$old_name";
                }
            }

            # It's something else, leave it be.
            else {
                push @new_tree, $line;
            }
        }
    }
    
    # If the file or tree we want to create was never encountered, add it
    if ($new_name and not $overwrite) {

        # ...as a file
        if ($new_type eq 'blob') {
            push @new_tree, "$new_mode $new_type $blob\t$new_name";
        }

        # ...as a tree
        else {
            my $tree_id = $self->make_tree(undef, \@new_path, $blob);
            push @new_tree, "$new_mode $new_type $tree_id\t$new_name";
        }
    }

    # Now, build this new tree from the input we've generated
    return $git->run('mktree', { input => join "\n", @new_tree });
}


sub make_blob {
    my ($self, $name, $content) = @_;

    return $self->git->run('hash-object', '-t', 'blob', '-w', '--stdin', '--path', $name, 
        { input => $content });
}


sub make_blob_from_file {
    my ($self, $name, $filename) = @_;

    return $self->git->run('hash-object', '-t', 'blob', '-w', '--path', $name, $filename);
}


sub find_root {
    my ($self) = @_;

    my $old_tree_id;
    my @ref_info = $self->git->run('show-ref', $self->branch);
    REF: for my $line (@ref_info) {
        my ($object_id, $name) = split /\s+/, $line, 2;

        if ($name eq $self->branch) {
            $old_tree_id = $object_id;
            last REF;
        }
    }

    return $old_tree_id;
}


sub commit_tree {
    my ($self, $old_tree_id, $new_tree_id, $comment) = @_;

    return $self->git->run(
        'commit-tree', $new_tree_id, '-p', $old_tree_id, { 
            input => $comment,
            env   => {
                GIT_AUTHOR_NAME  => $self->author_name,
                GIT_AUTHOR_EMAIL => $self->author_email,
            },
        },
    );
}


sub update_root {
    my ($self, $old_commit_id, $new_commit_id) = @_;
    $self->git->command('update-ref', $self->branch, $new_commit_id, $old_commit_id);
}


sub find_path {
    my ($self, $path) = @_;

    my $object_id;
    my @files = $self->git->run('ls-tree', $self->branch, $path);
    FILE: for my $line (@files) {
        my ($mode, $type, $id, $name) = split /\s+/, $line, 4;

        if ($name eq $path) {
            $object_id = $id;
            last FILE;
        }
    }

    return $object_id;
}


sub show {
    my ($self, $object_id) = @_;
    return $self->git->run('show', $object_id);
}


sub fetch_size {
    my ($self, $path) = @_;

    my @files = $self->git->run('ls-tree', '-l', $self->branch, $path);
    FILE: for my $line (@files) {
        my ($mode, $type, $id, $size, $name) = split /\s+/, $line, 5;
        return $size if $name eq $path;
    }

    return;
}


sub list_files {
    my ($self, $path) = @_;
    my @files;

    my @tree_files = $self->git->run('ls-tree', $self->branch, $path . '/');
    FILE: for my $line (@tree_files) {
        my ($mode, $type, $id, $name) = split /\s+/, $line, 4;

        next unless $type eq 'blob';

        my $filetype;
        if ($name =~ s/\.(?<filetype>[a-z0-9]+)$//) {
            $filetype = $+{filetype};
        }

        push @files, $self->file({ path => $name, filetype => $filetype });
    }

    return @files;
}


sub file {
    my ($self, $params) = @_;

    Yukki::Model::File->new(
        %$params,
        app        => $self->app,
        repository => $self,
    );
}


sub default_file {
    my $self = shift;

    return Yukki::Model::File->new(
        full_path  => $self->repository_settings->default_page,
        app        => $self->app,
        repository => $self,
    );
}


sub log {
    my ($self, $full_path) = @_;

    my @lines = $self->git->run(
        'log', $self->branch, '--pretty=format:%H~%an~%aD~%ar~%s', '--numstat', 
        '--', $full_path
    );

    my @revisions;
    my $current_revision;

    my $mode = 'log';
    for my $line (@lines) {
        given ($mode) {
            
            # First line is the log line
            when ('log') {
                $current_revision = {};

                @{ $current_revision }{qw( object_id author_name date time_ago comment )}
                    = split /~/, $line, 5;

                $current_revision->{date} = DateTime::Format::Mail->parse_datetime(
                    $current_revision->{date}
                );

                $mode = 'stat';
            }

            # Remaining lines are the numstat
            when ('stat') {
                my ($added, $removed, $path) = split /\s+/, $line, 3;
                if ($path eq $full_path) {
                    $current_revision->{lines_added}   = $added;
                    $current_revision->{lines_removed} = $removed;
                }

                $mode = 'skip';
            }

            # Once we know the numstat, search for the blank and start over
            when ('skip') {
                push @revisions, $current_revision;
                $mode = 'log' if $line !~ /\S/;
            }

            default {
                http_throw("invalid parse mode '$mode'");
            }
        }
    }

    return @revisions;
}


sub diff_blobs {
    my ($self, $path, $object_id_1, $object_id_2) = @_;

    my @lines = $self->git->run(
        'diff', '--word-diff=porcelain', '--unified=10000000', '--patience',
        $object_id_1, $object_id_2, '--', $path,
    );

    my @chunks;
    my $last_chunk_type = '';

    my $i = 0;
    LINE: for my $line (@lines) {
        next if $i++ < 5;

        my ($type, $detail) = $line =~ /^(.)(.*)$/;
        given ($type) {
            when ([ '~', ' ', '+', '-' ]) { 
                if ($last_chunk_type eq $type) {
                    $chunks[-1][1] .= $detail;
                }
                elsif ($type eq '~') {
                    $chunks[-1][1] .= "\n";
                }
                else {
                    push @chunks, [ $type, $detail ];
                    $last_chunk_type = $type;
                }
            }

            when ('\\') { }
            default { warn "unknown diff line type $type" }
        }
    }

    return @chunks;
}

1;

__END__

=pod

=head1 NAME

Yukki::Model::Repository - model for accessing objects in a git repository

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  my $repository = $app->model('Repository', { name => 'main' });
  my $file = $repository->file({ path => 'foo.yukki' });

=head1 DESCRIPTION

This model contains methods for performing all the individual operations
required to store files into and fetch files from the git repository. It
includes tools for building trees, commiting, creating blobs, fetching file
lists, etc.

=head1 EXTENDS

L<Yukki::Model>

=head1 ATTRIBUTES

=head2 name

This is the name of the repository. This is used to lookup the configuration for
the repository from the F<yukki.conf>.

=head2 repository_settings

These are the settings telling this model where to find the git repository and
how to access it. It is loaded automatically using the L</name> to look up
information in the F<yukki.conf>.

=head2 repository_path

This is the path to the repository. It is located using the C<repository_path>
and C<repository> keys in the configuration.

=head2 git

This is a L<Git::Repository> object which helps us do the real work.

=head1 METHODS

=head2 author_name

This is the author name to use when making changes to the repository.

This is taken from the C<author_name> of the C<anonymous> key in the
configuration or defaults to "Anonymous".

=head2 author_email

This is the author email to use when making changes to the repository.

This is taken from teh C<author_email> of the C<anonymous> key in the
configuration or defaults to "anonymous@localhost".

=head2 make_tree

  my $tree_id = $repository->make_tree($old_tree_id, \@parts, $object_id);
  my $tree_id = $repository->make_tree($old_tree_id, \@parts);
  my $tree_id = $repository->make_tree(
      $old_tree_id, \@old_parts, \@new_parts, $object_id); 

In any case described here, the method returns the object ID of the top level
tree created.

=head3 Insert/Update

When C<$object_id> is given, this will construct one or more trees in the git
repository to place the C<$object_id> into the deepest tree. This starts by
reading the tree found using the object ID in C<$old_tree_id>. The first path
part in C<@parts> is shifted off. If an existing path is found there, that
path will be replaced. If not, a new path will be added. A tree object will be
constructed for all byt he final path part in C<@parts>.

When the final part is reached, that path will be placed into the final tree
as a blob using the given C<$object_id>.

This method will fail if it runs into a situation where a blob would be
replaced by a tree or a tree would be replaced by a blob. 

=head3 Remove

When C<$object_id> is not passed or C<undef>, this will cause the final tree or blob found to be removed. This works essentially the same as the case for storing a blob, but when it gets to the last tree or blob found, it will elide that name from the final tree constructed.

This method will fail if you attempt to remove something that does not exist.

=head3 Rename

When a second array reference is passed with the C<$object_id>, this method will perform a rename. In this case, the method will remove the path named in the L<@old_parts> and add the path named in <@new_parts> using the given C<$object_id> at that new location.

This method will fail if a failure condition that would occur during either the insert/update or remove operation that is being performed simultaneously.

=head2 make_blob

  my $object_id = $repository->make_blob($name, $content);

This creates a new file blob in the git repository with the given name and the
file contents.

=head2 make_blob_from_file

  my $object_id = $repository->make_blob_from_file($name, $filename);

This is identical to L</make_blob>, except that the contents are read from the
given filename on the local disk.

=head2 find_root

  my $tree_id = $repository->find_root;

This returns the object ID for the tree at the root of the L</branch>.

=head2 commit_tree

  my $commit_id = $self->commit_tree($old_tree_id, $new_tree_id, $comment);

This takes an existing tree commit (generally found with L</find_root>), a new
tree to replace it (generally constructed by L</make_tree>) and creates a
commit using the given comment.

The object ID of the committed ID is returned.

=head2 update_root

  $self->update_root($old_tree_id, $new_tree_id);

Given a old commit ID and a new commit ID, this moves the HEAD of the L</branch>
so that it points to the new commit. This is called after L</commit_tree> has
setup the commit.

=head2 find_path

  my $object_id = $self->find_path($path);

Given a path within the repository, this will find the object ID of that tree or
blob at that path for the L</branch>.

=head2 show

  my $content = $repository->show($object_id);

Returns the contents of the blob for the given object ID.

=head2 fetch_size

  my $bytes = $repository->fetch_size($path);

Returns the size, in bites, of the blob at the given path.

=head2 list_files

  my @files = $repository->list_files($path);

Returns a list of L<Yukki::Model::File> objects for all the files found at
C<$path> in the repository.

=head2 file

  my $file = $repository->file({ path => 'foo', filetype => 'yukki' });

Returns a single L<Yukki::Model::File> object for the given path and filetype.

=head2 default_file

  my $file = $repository->default_file;

Return the default L<Yukki::Model::File> configured for this repository.

=head2 log

  my @log = $repository->log( full_path => 'foo.yukk' );

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

=head2 diff_blobs

  my @chunks = $self->diff_blobs('file.yukki', 'a939fe...', 'b7763d...');

Given a file path and two object IDs, returns a list of chunks showing the difference between to revisions of that path. Each chunk is a two element array. The first element is the type of chunk and the second is any detail for that chunk.

The types are:

    "+"    This chunk was added to the second revision.
    "-"    This chunk was removed in the second revision.
    " "    This chunk is the same in both revisions.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
