package Text::Todo;

# $AFresh1: Todo.pm,v 1.26 2010/02/14 06:08:07 andrew Exp $

use warnings;
use strict;
use Carp;

use Class::Std::Utils;
use Text::Todo::Entry;
use File::Spec;

use version; our $VERSION = qv('0.2.2');

{

    my @attr_refs = \(
        my %path_of,

        my %list_of,
        my %loaded_of,
        my %known_tags_of,
    );

    sub new {
        my ( $class, $options ) = @_;

        my $self = bless anon_scalar(), $class;
        my $ident = ident($self);

        $path_of{$ident} = {
            todo_dir  => undef,
            todo_file => 'todo.txt',
            done_file => undef,
        };

        my %tags = (
            context => q{@},
            project => q{+},
        );

        if ($options) {
            if ( ref $options eq 'HASH' ) {
                foreach my $opt ( keys %{$options} ) {
                    if ( exists $path_of{$ident}{$opt} ) {
                        $self->_path_to( $opt, $options->{$opt} );
                    }
                    elsif ( $opt eq 'tags'
                        && ref $options->{$opt} eq 'HASH' )
                    {
                        %tags = ( %tags, %{ $options->{$opt} } );
                    }
                    else {

                        #carp "Invalid option [$opt]";
                    }
                }
            }
            else {
                if ( -d $options ) {
                    $self->_path_to( 'todo_dir', $options );
                }
                elsif ( $options =~ /\.txt$/ixms ) {
                    $self->_path_to( 'todo_file', $options );
                }
                else {
                    carp "Unknown options [$options]";
                }
            }
        }

        $known_tags_of{$ident} = \%tags;

        my $file = $self->_path_to('todo_file');
        if ( defined $file && -e $file ) {
            $self->load();
        }

        return $self;
    }

    sub _path_to {
        my ( $self, $type, $path ) = @_;
        my $ident = ident($self);

        if ( $type eq 'todo_dir' ) {
            if ($path) {
                $path_of{$ident}{$type} = $path;
            }
            return $path_of{$ident}{$type};
        }

        if ($path) {
            my ( $volume, $directories, $file )
                = File::Spec->splitpath($path);
            $path_of{$ident}{$type} = $file;

            if ($volume) {
                $directories = File::Spec->catdir( $volume, $directories );
            }

            # XXX Should we save complete paths to each file, mebbe only if
            # the dirs are different?
            if ($directories) {
                $path_of{$ident}{todo_dir} = $directories;
            }
        }

        if ( $type =~ /(todo|done|report)_file/xms ) {
            if ( my ( $pre, $post )
                = $path_of{$ident}{$type} =~ /^(.*)$1(.*)\.txt$/ixms )
            {
                foreach my $f (qw( todo done report )) {
                    if ( !defined $path_of{$ident}{ $f . '_file' } ) {
                        $path_of{$ident}{ $f . '_file' }
                            = $pre . $f . $post . '.txt';
                    }
                }
            }
        }

        if ( defined $path_of{$ident}{todo_dir} ) {
            return File::Spec->catfile( $path_of{$ident}{todo_dir},
                $path_of{$ident}{$type} );
        }

        return;
    }

    sub file {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        if ( defined $file && exists $path_of{$ident}{$file} ) {
            $file = $self->_path_to($file);
        }
        else {
            $file = $self->_path_to( 'todo_file', $file );
        }

        return $file;
    }

    sub load {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        $loaded_of{$ident} = undef;

        $file = $self->file($file);

        if ( $list_of{$ident} = $self->listfile($file) ) {
            $self->known_tags;
            $loaded_of{$ident} = $file;
            return 1;
        }

        return;
    }

    sub listfile {
        my ( $self, $file ) = @_;

        $file = $self->file($file);

        if ( !defined $file ) {
            carp q{file can't be found};
            return;
        }

        if ( !-e $file ) {
            carp "file [$file] does not exist";
            return;
        }

        my @list;
        open my $fh, '<', $file or croak "Couldn't open [$file]: $!";
        while (<$fh>) {
            s/\r?\n$//xms;
            push @list, Text::Todo::Entry->new($_);
        }
        close $fh or croak "Couldn't close [$file]: $!";

        return wantarray ? @list : \@list;
    }

    sub save {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        $file = $self->file($file);
        if ( !defined $file ) {
            croak q{todo file can't be found};
        }

        open my $fh, '>', $file or croak "Couldn't open [$file]: $!";
        foreach my $e ( @{ $list_of{$ident} } ) {
            print {$fh} $e->text . "\n"
                or croak "Couldn't print to [$file]: $!";
        }
        close $fh or croak "Couldn't close [$file]: $!";

        $loaded_of{$ident} = $file;

        return 1;
    }

    sub list {
        my ($self) = @_;
        my $ident = ident($self);

        return if !$list_of{$ident};
        return wantarray ? @{ $list_of{$ident} } : $list_of{$ident};
    }

    sub listpri {
        my ( $self, $pri ) = @_;

        my @list;
        if ($pri) {
            $pri = uc $pri;
            if ( $pri !~ /^[A-Z]$/xms ) {
                croak 'PRIORITY must a single letter from A to Z.';
            }
            @list = grep { defined $_->priority && $_->priority eq $pri }
                $self->list;
        }
        else {
            @list = grep { $_->priority } $self->list;
        }

        return wantarray ? @list : \@list;
    }

    sub add {
        my ( $self, $entry ) = @_;
        my $ident = ident($self);

        if ( !ref $entry ) {
            $entry = Text::Todo::Entry->new(
                {   text => $entry,
                    tags => $known_tags_of{$ident},
                }
            );
        }
        elsif ( ref $entry ne 'Text::Todo::Entry' ) {
            croak(
                'entry is a ' . ref($entry) . ' not a Text::Todo::Entry!' );
        }

        push @{ $list_of{$ident} }, $entry;

        $self->known_tags;

        return $entry;
    }

    sub del {
        my ( $self, $src ) = @_;
        my $ident = ident($self);

        my $id = $self->_find_entry_id($src);

        my @list = $self->list;
        my $entry = splice @list, $id, 1;
        $list_of{$ident} = \@list;

        return $entry;
    }

    sub move {
        my ( $self, $entry, $dst ) = @_;
        my $ident = ident($self);

        my $src  = $self->_find_entry_id($entry);
        my @list = $self->list;

        splice @list, $dst, 0, splice @list, $src, 1;

        $list_of{$ident} = \@list;

        return 1;
    }

    sub listproj {
        my ($self) = @_;
        return $self->listtag('project');
    }

    sub listcon {
        my ($self) = @_;
        return $self->listtag('context');
    }

    sub listtag {
        my ( $self, $tag ) = @_;
        my $ident = ident($self);

        my $accessor = $tag . 's';

        my %available;
        foreach my $e ( $self->list ) {
            foreach my $p ( $e->$accessor ) {
                $available{$p} = 1;
            }
        }

        my @tags = sort keys %available;

        return wantarray ? @tags : \@tags;
    }

    sub learn_tag {
        my ( $self, $tag, $sigal ) = @_;

        $known_tags_of{ ident $self}{$tag} = $sigal;
        $self->known_tags;

        return 1;
    }

    sub known_tags {
        my ($self) = @_;
        my $ident = ident($self);

        my @list = $self->list;
        my %tags = %{ $known_tags_of{$ident} };

        foreach my $e (@list) {
            my $kt = $e->known_tags;
            foreach my $t ( keys %{$kt} ) {
                if ( !exists $tags{$t} ) {
                    $tags{$t} = $kt->{$t};
                }
            }
        }

        foreach my $e (@list) {
            my $kt = $e->known_tags;
            foreach my $t ( keys %tags ) {
                if ( !exists $kt->{$t} || $tags{$t} ne $kt->{$t} ) {
                    $e->learn_tag( $t, $tags{$t} );
                }
            }
        }

        $known_tags_of{$ident} = \%tags;

        return $known_tags_of{$ident};
    }

    sub archive {
        my ($self) = @_;
        my $ident = ident($self);

        if ( !defined $loaded_of{$ident}
            || $loaded_of{$ident} ne $self->file('todo_file') )
        {
            carp 'todo_file not loaded';
            return;
        }

        my $changed = 0;
    ENTRY: foreach my $e ( $self->list ) {
            if ( $e->done ) {
                if ( $self->addto( 'done_file', $e ) && $self->del($e) ) {
                    $changed++;
                }
                else {
                    carp q{Couldn't archive entry [} . $e->text . ']';
                    last ENTRY;
                }
            }
            elsif ( $e->text eq q{} ) {
                if ( $self->del($e) ) {
                    $changed++;
                }
                else {
                    carp q{Couldn't delete blank entry};
                    last ENTRY;
                }
            }
        }

        if ($changed) {
            $self->save;
        }

        return $changed;
    }

    sub addto {
        my ( $self, $file, $entry ) = @_;
        my $ident = ident($self);

        $file = $self->file($file);
        if ( !defined $file ) {
            croak q{file can't be found};
        }

        if ( ref $entry ) {
            if ( ref $entry eq 'Text::Todo::Entry' ) {
                $entry = $entry->text;
            }
            else {
                carp 'Unknown ref [' . ref($entry) . ']';
                return;
            }
        }

        open my $fh, '>>', $file or croak "Couldn't open [$file]: $!";
        print {$fh} $entry, "\n"
            or croak "Couldn't print to [$file]: $!";
        close $fh or croak "Couldn't close [$file]: $!";

        if ( defined $loaded_of{$ident} && $file eq $loaded_of{$ident} ) {
            return $self->load($file);
        }

        return 1;
    }

    sub _find_entry_id {
        my ( $self, $entry ) = @_;
        my $ident = ident($self);

        if ( ref $entry ) {
            if ( ref $entry ne 'Text::Todo::Entry' ) {
                croak(    'entry is a '
                        . ref($entry)
                        . ' not a Text::Todo::Entry!' );
            }

            my @list = $self->list;
            foreach my $id ( 0 .. $#list ) {
                if ( $list[$id] eq $entry ) {
                    return $id;
                }
            }
        }
        elsif ( $entry =~ /^\d+$/xms ) {
            return $entry;
        }

        croak "Invalid entry [$entry]!";
    }

    sub DESTROY {
        my ($self) = @_;
        my $ident = ident $self;

        foreach my $attr_ref (@attr_refs) {
            delete $attr_ref->{$ident};
        }

        return;
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Todo - Perl interface to todotxt files


=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: Todo.pm,v 1.27 2010/02/16 01:13:12 andrew Exp $

=head1 SYNOPSIS

    use Text::Todo;
    
    my $todo = Text::Todo->new('todo/todo.txt');

    foreach my $e (sort { lc($_->text) cmp lc($e->text)} $todo->list) {
        print $e->text, "\n";
    }


=head1 DESCRIPTION

This module is a basic interface to the todo.txt files as described by
Lifehacker and extended by members of their community.

For more information see L<http://todotxt.com>

This module supports the 3 axes of an effective todo list. 
Priority, Project and Context.

It does not support other notations or many of the more advanced features of
the todo.sh like plugins.

It should be extensible, but and hopefully will be before a 1.0 release.


=head1 INTERFACE 

=head2 new

    new({ 
        [ todo_dir    => 'directory', ]
        [ todo_file   => 'filename in todo_dir', ]
        [ done_file   => 'filename in todo_dir', ]
        [ report_file => 'filename in todo_dir', ]
        });

Allows you to set each item individually.  todo_file defaults to todo.txt.

    new('path/to/todo.txt');

Automatically sets todo_dir to 'path/to', todo_file to 'todo.txt' 

    new('path/to')

If you pass an existing directory to new, it will set todo_dir. 


If you what you set matches (.*)todo(.*).txt it will automatically set 
done_file to $1done$2.txt
and
report_file to $1report$2.txt.

For example, new('todo/todo.shopping.txt') will set 
todo_dir to 'todo',
todo_file to 'todo.shopping.txt',
done_file to 'done.shopping.txt',
and
report_file to 'report.shopping.txt'.

=head2 file

Allows you to read the paths to the files in use. 
If as in the SYNOPSIS above you used $todo = new('todo/todo.txt').

    $todo_file = $todo->file('todo_file');

then, $todo_file eq 'todo/todo.txt'

=head2 load
- Reads a list from a file into the current object.

Allows you to load a different file into the object.

    $todo->load('done_file');

This effects the other functions that act on the list.

=head2 save
- Writes the list to disk.

    $todo->save(['new/path/to/todo']);

Either writes the current working file or the passed in argument
that can be recognized by file(). 

If you specify a filename it will save to that file and update the paths.  
Additional changes to the object work on that file.

=head2 list
- get the curently loaded list

    my @todo_list = $todo->list;

In list context returns a list, it scalar context returns an array reference to the list.

=head2 listpri
- get the list items that are marked priority

Like list, but only returns entries that have priority set.

    my @priority_list = $todo->listpri;

Since this is so easy to write as:

    my @priority_list = grep { $_->priority } $todo->list;

I think it may become depreciated unless there is demand.

=head2 known_tags

Returns a reference to a hash of the tags known to the list.

=head2 learn_tag($tag, $sigal)

Let the entire list learn a new tag.  
If you are working with a list you should use this instead of 
$entry->learn_tag because it will update all entries.

=head2 listtag($tag)

Returns tags found in the list sorted by name.  

If there were projects +GarageSale and +Shopping then

    my @projects = $todo->listtag('project');

is the same as

    @projects = ( 'GarageSale', 'Shopping' );

=head2 listcon
- Shortcut to listtag('context')

=head2 listproj
- Shortcut to listtag('project')

=head2 add

Adds a new entry to the list. 
Can either be a Text::Todo::Entry object or plain text.

    $todo->add('new todo entry');

It then becomes $todo->list->[-1];

=head2 del

Remove an entry from the list, either the reference or by number.

    $removed_entry = $todo->del($entry);

$entry can either be an Text::Todo::Entry in the list or the index of the
entry to delete.

Note that entries are 0 indexed (as expected in perl) not starting at line 1.

=head2 move

    $todo->move($entry, $new_pos);

$entry can either be the number of the entry or the actual entry.
$new_pos is the new position to put it. 

Note that entries are 0 indexed (as expected in perl) not starting at line 1.

=head2 archive

    $todo->archive

Iterates over the list and for each done entry, 
addto('done_file') 
and
del($entry).
If any were archived it will then 
save() 
and 
load().

=head2 addto

    $todo->addto($file, $entry);

Appends text to the file. 
$file can be anyting recognized by file().
$entry can either be a Text::Todo::Entry or plain text.

=head2 listfile

    @list = $todo->listfile($file);

Read a file and returns a list like $todo->list but does not update the
internal list that is being worked with.
$file can be anyting recognized by file().


=head1 DIAGNOSTICS

Most methods return undef on failure.  

Some more important methods are fatal.


=head1 CONFIGURATION AND ENVIRONMENT

Text::Todo requires no configuration files or environment variables.

Someday it should be able to read and use the todo.sh config file.  This may
possibly be better done in a client that would use this module.


=head1 DEPENDENCIES

Class::Std::Utils
File::Spec
version


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Limitations:

Currently there isn't an easy way to print out line numbers with the entry. 

Please report any bugs or feature requests to
C<bug-text-todo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
