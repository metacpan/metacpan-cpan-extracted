package Tree::Walker;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;
use base qw(Exporter);
use Data::Dumper;

our @EXPORT = qw( walkdir mapdir );

=head1 NAME

Tree::Walker - Iterate along hierarchical structures

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

C<Tree::Walker> provides an iterator framework for hierarchical things, starting with but not limited to the filesystem.
It returns its results in the form of a L<Data::Table::Lazy>, so there are plenty of handy tools available.
It can be subclassed for things other than the filesystem, or you can tell it to use another class - either way.

=head1 UNIVERSAL METHODS

These methods constitute the API for C<Tree::Walker> and are written in a universal fashion.

=head2 new

The C<new> method sets up a walk.  [possibly a walk method just to set one up and run it?]

The components of a walk are:
=over
=item The starting point (for the filesystem, a string representing the directory to start walking in)
=item Restrictions on the walk (for the filesystem, extensions to be looked for or a pattern to match)
=item A general set of handlers to be taken if some specific item is matched
=item What information to be returned for each node (for the filesystem, the name, type, full path, timestamp, and size of each file/directory)
=back

The walker is designed to be subclassed for walking different hierarchical structures; see L<Tree::Walker::Subclass> for
information about how that works.

=cut

sub new {
    my $class = shift;
    my $self = bless ({
                         filters => [],
                      }, $class);
    $self->{select} = [$self->data_available()] unless defined $self->{select};
    $self->interpret_parameters (@_);

    $self;
}

=head2 walk, walk_all, walk_all_simple

C<walk> returns an iterator that will return one item from the walk each time it's called.  The returns
are in the form of an arrayref of fields as specified in the walker query.

C<walk_all> runs that iterator until it's done, returning the list of results.

C<walk_all_simple> is a walk_all that only returns the list of first result elements (probably the tag, you see; good for quick filtering)

=cut

sub walk {
    my $self = shift;
    my @stack;   # Yeah, isn't that cool?  We can't go recursive because I want an iterator.
    if (ref ($self->{start}) eq 'ARRAY') {
        push @stack, { tag=> '-', list => $self->{start} };
    } else {
        push @stack, { tag => $self->{start}, list => [$self->{start}] };
    }
    $self->walk_init;
    
    my $current_iterator = undef;
    
    return sub {
        NEXT:
        if (defined $current_iterator) {
            my $potential = $current_iterator->();
            return $potential if defined $potential;
            $current_iterator = undef;
        }
        return undef unless @stack;
        
        my $curframe = $stack[-1];           # Current frame is last on stack.
        while (!@{$curframe->{list}}) {      # Pop frames as long as the last one is empty.
            pop @stack;
            return undef unless @stack;      # If we're out of frames, we're done with the walk.
            $curframe = $stack[-1];
        }
        
        my $current = shift @{$curframe->{list}};
        return $current->() if ref $current eq 'CODE';  # This lets us represent the parent as a node easily.
        if (ref $current and $current->can('walk')) {
            $current_iterator = $current->walk;
            goto NEXT;
        }
        
        my $type = $self->type ($current, @stack);  # The type can be undef - a leaf - or anything else - expandable.
        if (not defined $type) {
            goto NEXT if $self->{suppress_leaves};
            my $data = $self->get_data($current, undef, @stack);   # Context frame is undef for a leaf
            foreach my $test (@{$self->{filters}}) {
                my ($code, @args) = @$test;
                goto NEXT unless $code->(_access_hash($data, @args));
            }
            return [_access_hash ($data, @{$self->headers})];
        }
        
        # We have an expandable node.  Let's build a new frame!  (Unless this node is pruned, anyway.)
        if ($self->{prune}) {
            foreach my $p (@{$self->{prune}}) {
                goto NEXT if $p eq $current;
            }
        }
        my $this_frame;
        $this_frame = { tag=> $current,
                        list => [$self->get_left ($type, $current, @stack),
                                 $self->{suppress_nodes} ? () : $self->_wrap_current ($current, \$this_frame, @stack),     # Context frame is this frame for a node.
                                 $self->get_right ($type, $current, @stack)]
                      };
        push @stack, $this_frame;
        goto NEXT;  # And then continue the walk.
    }
}
sub _access_hash {
    my $hash = shift;
    map {$hash->{$_}} @_;
}
sub _wrap_current {
    my $self = shift;
    my $current = shift;
    my $context_frame = shift;
    my @stack = @_;
    return sub {
        my $data = $self->get_data($current, $$context_frame, @stack);
        return [_access_hash ($data, @{$self->headers})];
    }
}

sub walk_all {
    my $self = shift;
    my $iterator = $self->walk(@_);
    my @return = ();
    while (my $r = $iterator->()) {
        push @return, $r;
    }
    @return;
}
sub walk_all_simple {
    my $self = shift;
    my $iterator = $self->walk(@_);
    my @return = ();
    while (my $r = $iterator->()) {
        push @return, $r->[0];
    }
    @return;
}

=head2 walk_table

Returns a L<Data::Table::Lazy> table encapsulating a walk iterator.  Only works if that module
is installed; otherwise croaks.

=cut

sub walk_table {
    my $self = shift;
    eval { require Data::Table::Lazy; };
    croak "walk_table requires Data::Table::Lazy - not installed" if $@;
    Data::Table::Lazy->new ($self->walk, $self->headers);
}

=head2 walkdir (start, parameters, action)

Called with a string, an arrayref, and a subroutine, this function will build and call a walker, then
run the iteration by repeated calls to the subroutine, like this:

   use Tree::Walker;
   
   my @file_list;
   walkdir '.', [suppress_nodes => 1], sub {
       push @file_list, $_[2];
   }

=cut

sub walkdir ($$;&) {
    my $directory = shift;
    my $parameters = shift;
    my $action;
    if (ref $parameters eq 'CODE') {
        $action = $parameters;
        $parameters = {};
    } else {
        $action = shift;
    }
    if (ref $parameters eq 'ARRAY') {
        my %p = @$parameters;
        $parameters = \%p;
    }
    
    my $walker = Tree::Walker->new ($directory, $parameters);

    my $iterator = $walker->walk;
    while (my $result = $iterator->()) {
        $action->(@$result);
    }
}

=head2 mapdir

Another little quickie, this one allows even briefer syntax if your subroutine is small.

    use Tree::Walker;
    
    my @pm_list = mapdir { $_[2] } '.', '.pm';

=cut

sub mapdir (&;$$) {
    my $action = shift;
    my $directory = shift || '.';
    my $parameters = shift || {};
    if (ref $parameters eq 'ARRAY') {
        my %p = @$parameters;
        $parameters = \%p;
    }
    
    my @results = ();
    my $walker = Tree::Walker->new ($directory, $parameters);
    
    my $iterator = $walker->walk;
    while (my $result = $iterator->()) {
        push @results, $action->(@$result);
    }
    return @results;
}

=head2 interpret_parameters

The C<interpret_parameters> method sets up the parameters for the walk. Most of the work is done by C<interpret_parameters_class>, which can be overridden, but
the basic behavior is provided by the base class.

=head1 OVERRIDABLE OR PARTLY OVERRIDABLE METHODS

These methods work with the filesystem in the unadorned C<Tree::Walker> but are overridden
in subclasses (for example see L<Net::FTP::Walker>).

=head2 interpret_parameters

The C<interpret_parameters> methods interprets the parameters passed to ->new and sets up the walk environment.

The base class provides three different modes:
=over
=item Directory walking is the core functionality; you provide a start directory as the first parameter.
=item Explicit file check; the first parameter is a string that points to a file, not a directory. This filespec can be
a full relative path; it doesn't just have to be a name.
=item List walk; the first parameter is an arrayref of either strings or arrayrefs. If the latter,
then the first member of each child arrayref is the type tag for the rest, and the rest are interpreted
recursively as subwalks.
=back

The base class provides list (composite) walking, 

The rest of the parameters mostly just apply to directory walks, which can be restricted in a number of different ways.
There are four types of parameters: walk parameters, filter parameters, additional fields, and field selection. Field
selection obviously applies to all types of walk, not just directory walks, as it determines what fields are actually
returned by the call.  Let's look at the four types separately.

There is actually only one walk parameter, C<postfix>.  If this is false, then it is a prefixed walk, and each node
will appear in the results list before its children.  If it's true, then nodes follow their children (this is necessary
if you want a total-size number for each directory).

Parameters for filtering the results of filesystem walking are as follows, for filters applied
to filenames (not directory names):
=over
=item ext             - an extension that files must match to be returned
=item ext_list        - a list (arrayref) of extensions, one of which must be matched by a file to be returned
=item pattern         - a regexp that filenames must match for the file to be returned
=item exists          - return only existing files or non-existing files, for any files that have been specified explicitly
=item filter          - if all else fails, you can write your own filters here
=back

The C<filter> parameter contains either a coderef that will be passed the entire list of headers below and returns
a boolean (false = don't return this row, true = return this row) or an arrayref C<[<coderef>, field, field, field...]>
that specifies which fields the coderef wants to see I<or> an arrayref of such arrayrefs, e.g.
C<[[<coderef>, field, ...], [<coderef>, field, ...], ...]>

In the end, all the other filters go into the same filter structure anyway, so this part is very easy to subclass.

To select whether or not to return directories, or files, use:
=over
=item suppress_leaves - (at the abstract level) if set, non-expandable nodes will not be returned
=item suppress_nodes  - (at the abstract level) if set, expandable nodes will not be returned - doesn't affect the walk
=item prune           - a name or list of names that, if encountered, will not be walked at all
=back

There's a shortcut for filesystem queries (or rather, a set of shortcuts). If the second parameter is not a hashref but
rather a string, then:
=over
=item If it starts with a period but doesn't have a vertical bar | it will be understood as C<ext>.
=item If it starts with a period but does have at least one vertical bar | it will be C<ext_list>.
=item Otherwise, it will be taken as a pattern, which is a crippled regexp but quick and easy.
=back

If one of these options is taken, C<suppress_nodes> is also set because the idea is fast, easy ways to get data,
and you probably just want file information.  And of course you're locked into the defaults for everything else.

To add fields to the list of result fields, you can pass in a C<fields> parameter that consists of an arrayref:
C<[[<coderef>, field, field, ...], ...]>.  After the normal fields are generated, each of these field generators is called
in sequence, and each returns a list of values to be named according to the list following the coderef.

Finally, to restrict the list of fields actually returned on each call to the generator, simply pass in a list
of names under C<select => ['name1', 'name2'...]>.

=cut

sub _interpret_sub {
    my $self = shift;
    my $sub = shift;
    
    if (ref $sub eq 'ARRAY') {
        my ($role, @rest) = @$sub;
        return Tree::Walker->new(@rest, {role=>$role}, @_);
    }
    Tree::Walker->new($sub, @_);
}

sub _interp_one {
    my $p = shift;
    return unless defined $p;
    return $p if ref $p;
    _interp_one_class($p);    # Class-specific ways of dealing with string parameters
}
sub _interp_one_class {
    my $p = shift;
    my $r = { suppress_nodes => 1 };
    if ($p =~ /^\./) {
       if ($p =~ /\|/) {
          $r->{ext_list} = [split / *\| */, $p];
       } else {
          $r->{ext} = $p;
       }
    } else {
       $r->{pattern} = $p;
    }
    return $r;
}
    
sub interpret_parameters {
    my $self = shift;
    $self->{start} = shift;
    my @rest = @_;
    $self->{filters} = [];
    $self->{added_fields} = [];
    
    if (ref ($self->{start}) eq 'ARRAY') {
        my @subs = map { $self->_interpret_sub($_, @rest) } @{$self->{start}};
        $self->{start} = \@subs;
        return;
    }

    while (my $p = _interp_one(shift)) {
       return unless defined $p;
       if (ref $p eq 'HASH') {
           while (my ($k,$v) = each %$p) {
               if ($k eq 'filter') {
                   push @{$self->{filters}}, $v;
               } elsif ($k eq 'field') {
                   push @{$self->{added_fields}}, $v;
               } else {
                   $self->{$k} = $v;
               }
           }
       } else {
           croak "full parameters for walker must be string or hashref";
       }
    }
    if ($self->{prune}) {
        $self->{prune} = [$self->{prune}] unless ref $self->{prune};
    }
    
    $self->interpret_parameters_class;
}

sub _total_size_callee {
    my $tag = shift;
    my $values = shift;
    my $context_frame = shift;
    my @stack = @_;
    my $size = $values->{size} + (defined $context_frame ? ($context_frame->{total_size} || 0) : 0);
    $stack[-1]->{total_size} += $size;
    return $size;
}

sub interpret_parameters_class {
    my $self = shift;
    
    if ($self->{ext}) {
        my $ext = $self->{ext};
        $ext =~ s/\./\\./g;
        push @{$self->{filters}}, [sub { shift =~ /$ext$/; }, 'name'];
    }
    if ($self->{ext_list}) {
        my @list = (@{$self->{ext_list}});
        foreach (@list) {
            s/\./\\./g;
        }
        my $pat = join ('$|', @list);
        push @{$self->{filters}}, [sub { shift =~ /$pat$/; }, 'name'];
    }
    if ($self->{pattern}) {
        push @{$self->{filters}}, [sub { shift =~ /$self->{pattern}/; }, 'name'];
    }
    $self->{postfix} = 0 unless defined $self->{postfix};
    if (defined $self->{exists}) {
        if ($self->{exists}) {
            push @{$self->{filters}}, [sub { shift ne '!' }, 'type'];
        } else {
            push @{$self->{filters}}, [sub { shift eq '!' }, 'type'];
        }
    }
    
    if (grep { $_ eq 'total_size' } @{$self->{select}}) {
        push @{$self->{added_fields}}, [\&_total_size_callee, 'total_size'];
        $self->{postfix} = 1;
    }
}

=head2 walk_init ()

Initializes a walk. Doesn't do anything in the filesystem.

=cut

sub walk_init {}

=head2 qualify (tag, stack)

Given the tag for a node and the stack above it, fully qualify the tag as a locator.

=cut

sub qualify {
    my $shift = shift;
    my $tag = shift;
    require File::Spec;
    my @parents = map {$_->{tag}} @_[1..$#_];
    File::Spec->catdir (@parents, $tag);
}

=head2 type (tag, stack)

Given the tag for a node, visits it (does initial retrieval) and tells us its type.

=cut

sub type {
    my $self = shift;
    return 'd' if -d $self->qualify (@_);
    return undef;
}

=head2 data_available

Returns a list of the fields the walker can return (i.e. the fields the driver knows about) and the default
order in which they'll be returned.

For the filesystem, these are:
=over
=item name    - the name of the file or directory
=item role    - the role of the node (specified at the outset)
=item indent  - the indentation level
=item path    - the path of the file or directory, built for the host OS using File::Spec
=item dev     - device number of the filesystem (this and the next 12 are the standard perl 'stat' fields)
=item ino     - inode number
=item mode    - file mode as integer
=item nlink   - number of (hard) links to the file
=item uid     - numeric user ID of owner
=item gid     - numeric group ID of owner
=item rdev    - device identifier for special files
=item size    - total size of file in bytes
=item atime   - last access time
=item mtime   - last modify time
=item ctime   - inode change time (these three all in seconds since 00:00 January 1, 1970 GMT)
=item blksize - block size of filesystem
=item blocks  - actual number of blocks allocated to the file
=item modestr - file mode as interpreted Unix-style mode string
=item type    - the first character of the modestr (for convenience)
=back


=cut

sub data_available {
    qw(name role indent path dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks modestr type);
}

=head2 get_data, get_data_class

Given the context and a node, gets the configured data for that node.  Again, class-specific fields are handled
in the C<get_data_class> function.

=cut

sub get_data {
    my $self = shift;
    my $tag = shift;
    my $context_frame = shift;
    my @stack = @_;
    my $values = {};
    $values->{name} = $tag;
    $values->{role} = $self->{role} || '';
    $values->{indent} = scalar @_ - 1;
    my $path = $self->qualify($tag, @_);
    
    $self->get_data_class ($tag, $path, $values, $context_frame, @stack);
    
    foreach my $added_field (@{$self->{added_fields}}) {
        my ($code, @rest) = @$added_field;
        #print STDERR Dumper (\@stack);
        my @values = $code->($tag, $values, $context_frame, @stack);
        foreach my $field (@rest) {
           $values->{$field} = shift @values;
        }
    }

    $values;
}
    
sub get_data_class {
    my $self = shift;
    my $tag = shift;
    my $path = shift;
    my $values = shift;
    
    $values->{path} = $path;
    
    my @stat = stat($path);
    if (not @stat) {
        $values->{type} = '!';
        $values->{modestr} = '!---------';
        foreach my $statfield (qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks)) {
            $values->{$statfield} = 0;
        }
        return $values;
    }
        
    foreach my $statfield (qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks)) {
        $values->{$statfield} = shift @stat;
    }
    
    # This bit is shamelessly stolen from Stat::lsMode because I don't want all its overhead.
    # Not to mention it was written in 1998 and doesn't pass smoke on Windows.
    my $mode = $values->{mode};
    my $setids = ($mode & 07000)>>9;
    my @permstrs = qw(--- --x -w- -wx r-- r-x rw- rwx)[($mode&0700)>>6, ($mode&0070)>>3, $mode&0007];
    my $ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?)[($mode & 0170000)>>12];
    $values->{type} = $ftype;
    if ($setids) {
       if ($setids & 01) {		# Sticky bit
          $permstrs[2] =~ s/([-x])$/$1 eq 'x' ? 't' : 'T'/e;
       }
       if ($setids & 04) {		# Setuid bit
          $permstrs[0] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
       }
       if ($setids & 02) {		# Setgid bit
          $permstrs[1] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
       }
    }
    $values->{modestr} = join ('', $ftype, @permstrs);
}

=head2 headers

Returns names for the fields in each returned line.

=cut

sub headers { shift->{select} }

=head2 get_children, get_left, get_right

The C<get_children> method, called on a node, returns a list of its children (to be interpreted in turn by C<qualify>
and C<type>).  The C<get_left> and C<get_right> functions take that list and divide it according to the walk type.

=cut

sub get_left  { return $_[0]->{postfix} ? get_children(@_) : (); }
sub get_right { return $_[0]->{postfix} ? () : get_children(@_); }
sub get_children {
    my $self = shift;
    my $type = shift;
    opendir D, $self->qualify (@_);
    require File::Spec;
    my @children = File::Spec->no_upwards(readdir(D));
    closedir D;
    @children;
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-walker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Walker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Walker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Walker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Walker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Walker>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Walker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Tree::Walker
