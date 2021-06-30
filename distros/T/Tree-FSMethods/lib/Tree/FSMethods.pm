package Tree::FSMethods;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-27'; # DATE
our $DIST = 'Tree-FSMethods'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Code::Includable::Tree::NodeMethods;
use Path::Naive;
use Scalar::Util qw(refaddr);
use Storable qw(dclone);
use String::Wildcard::Bash;

sub new {
    my ($class, %args) = (shift, @_);

    if ($args{tree}) {
        $args{_curpath} = "/";
        $args{_curnode} = $args{tree};
    }
    if ($args{tree2}) {
        $args{_curpath2} = "/";
        $args{_curnode2} = $args{tree2};
    }

    bless \%args, $class;
}

# note: only reads from _curnode & _curpath
sub _read_curdir {
    my $self = shift;

    my %entries_by_name;
    my @entries;
    my $order = 0;

  NODE:
    for my $node (
        Code::Includable::Tree::NodeMethods::_children_as_list(
            $self->{_curnode})) {
        my $name;
      ASSIGN_NAME: {
            my @methods;
            if (defined $self->{filename_method}) {
                push @methods, $self->{filename_method};
            }
            push @methods, "filename", "title";

            for my $method (@methods) {
                if (ref $method eq 'CODE') {
                    $name = $method->($node);
                } elsif ($node->can($method)) {
                    $name = $node->$method;
                }
                last if defined $name;
            }
            last if defined $name;

            $name = "$node";
        }

      HANDLE_INVALID: {
            if ($name eq '') {
                $name = "unnamed";
            } elsif ($name eq '.') {
                $name = '.(dot)';
            } elsif ($name eq '.') {
                $name = '..(dot-dot)';
            }
            $name =~ s!/!_!g;
            $name = substr($name, 0, 250) if length $name > 250;
        }

      HANDLE_DUPLICATES: {
            last unless exists $entries_by_name{$name};
            my $suffix = "2";
            while (1) {
                my $new_name = "$name.$suffix";
                do { $name = $new_name; last }
                    unless exists $entries_by_name{$new_name};
                $suffix++;
                die "_read_curdir: Too many duplicate names ($name)" if $suffix >= 9999;
            }
        }

        my $entry = {
            order => $order,
            name  => $name,
            node  => $node,
            path  => Path::Naive::concat_path($self->{_curpath}, $name),
        };
        $entries_by_name{$name} = $entry;
        push @entries, $entry;

        $order++;
    }

    @entries;
}

# returns: (path exists, @entries)
sub _traverse {
    my $self = shift;
    my ($which_obj, $path_wildcard) = @_;

    my $rootnode = $which_obj == 1 ? $self->{tree} : $self->{tree2};
    my $curnode  = $which_obj == 1 ? $self->{_curnode} : $self->{_curnode2};
    my $curpath  = $which_obj == 1 ? $self->{_curpath} : $self->{_curpath2};

    die "_traverse: No object loaded yet" unless $curnode;

    # starting point of traversal
    my $node = Path::Naive::is_abs_path($path_wildcard) ? $rootnode : $curnode;
    my $starting_path = Path::Naive::is_abs_path($path_wildcard) ? "/" : $curpath;
    my @path_elems = Path::Naive::split_path($path_wildcard);

    my @entries = ({path=>$starting_path, node=>$node});

    my $i = 0;
    my $path_exists = 1;
  PATH_ELEM:
    for my $path_elem (@path_elems) {
        $i++;
        if ($path_elem eq '.') {
            for (@entries) {
                $_->{path} = Path::Naive::concat_path($_->{path}, ".");
            }
            next PATH_ELEM;
        }
        if ($path_elem eq '..') {
            for (@entries) {
                $_->{path} = Path::Naive::concat_path($_->{path}, "..");
                # we allow ../ even on root node; it will just come back to root
                my $parent = $_->{node}->parent;
                $_->{node} = $parent if $parent;
            }
            next PATH_ELEM;
        }

        my $path_elem_contains_wildcard = String::Wildcard::Bash::contains_wildcard($path_elem);
        my $path_elem_re;
        if ($path_elem_contains_wildcard) {
            $path_elem_re = String::Wildcard::Bash::convert_wildcard_to_re($path_elem);
            $path_elem_re = qr/\A$path_elem_re\z/;
        }
        my @new_entries;
        for my $entry (@entries) {
            local $self->{_curnode} = $entry->{node};
            local $self->{_curpath} = $entry->{path};
            my @dir = $self->_read_curdir;
            if ($path_elem_contains_wildcard) {
                push @new_entries, grep { $_->{name} =~ $path_elem_re } @dir;
            } else {
                push @new_entries, grep { $_->{name} eq $path_elem    } @dir;
            }
            unless (@new_entries) {
                $path_exists = 0 if $i < @path_elems;
                @entries = ();
                last PATH_ELEM;
            }
        }
        @entries = @new_entries;
    } # for path_elem

    ($path_exists, @entries);
}

sub _cd {
    my ($self, $which_obj, $path_wildcard) = @_;
    my ($path_exists, @entries) = $self->_traverse($which_obj, $path_wildcard);
    die "cd: No such path '$path_wildcard'" unless @entries;
    die "cd: Ambiguous path '$path_wildcard'" unless @entries < 2;
    if ($which_obj == 1) {
        $self->{_curnode} = $entries[0]{node};
        $self->{_curpath} = Path::Naive::normalize_path($entries[0]{path});
    } else {
        $self->{_curnode2} = $entries[0]{node};
        $self->{_curpath2} = Path::Naive::normalize_path($entries[0]{path});
    }
    ($self->{_curnode}, $self->{_curpath});
}

sub cd {
    my ($self, $path_wildcard) = @_;
    $self->_cd(1, $path_wildcard);
}

sub cd2 {
    my ($self, $path_wildcard) = @_;
    $self->_cd(2, $path_wildcard);
}

sub _ls {
    my ($self, $which_obj, $path_wildcard) = @_;

    my $specifies_path = 1;
    unless (defined $path_wildcard) {
        $path_wildcard = '*';
        $specifies_path = 0;
    }

    my $cwd = $which_obj == 1 ? $self->{_curpath} : $self->{_curpath2};

    my ($path_exists, @entries) = $self->_traverse($which_obj, $path_wildcard);
    die "ls: No such path '$path_wildcard' (cwd=$cwd)" unless $path_exists;
    die "ls: No such path '$path_wildcard' (cwd=$cwd)" if !@entries && $specifies_path;
    @entries;
}

sub ls {
    my ($self, $path_wildcard) = @_;
    $self->_ls(1, $path_wildcard);
}

sub ls2 {
    my ($self, $path_wildcard) = @_;
    $self->_ls(2, $path_wildcard);
}

sub _showtree0 {
    require Tree::Object::Hash;

    my ($self, $path, $node) = @_;

    my @entries = $self->_read_curdir;

    my @children;
    for my $entry (@entries) {
        my $child = Tree::Object::Hash->new;
        $child->parent($entry->{node});
        $child->{filename} = $entry->{name};
        push @children, $child;
        local $self->{_curnode} = $entry->{node};
        local $self->{_curpath} = Path::Naive::concat_path($self->{_curpath}, $entry->{name});
        $self->_showtree0("$path/$entry->{name}", $child);
    }
    $node->children(\@children);
    $node;
}

sub _showtree {
    require Tree::Object::Hash;

    my $self = shift;
    my $which_obj = shift;
    my $starting_path = shift // '.';

    my $tree;
    {
        local $self->{_curnode} = $which_obj == 1 ? $self->{_curnode} : $self->{_curnode2};
        local $self->{_curpath} = $which_obj == 1 ? $self->{_curpath} : $self->{_curpath2};

        $self->cd($starting_path);

        my $node = Tree::Object::Hash->new;
        $node->{filename} = $starting_path;

        $tree = $self->_showtree0($starting_path, $node);
    }

    require Tree::To::TextLines;
    Tree::To::TextLines::render_tree_as_text({
        show_guideline => 1,
        on_show_node => sub {
            my ($node, $level, $seniority, $is_last_child, $opts) = @_;
            $node->{filename};
        },
    }, $tree);
}

sub showtree {
    my $self = shift;
    $self->_showtree(1, @_);
}

sub showtree2 {
    my $self = shift;
    $self->_showtree(2, @_);
}

sub _cwd {
    my $self = shift;
    my $which_obj = shift;
    $which_obj == 1 ? $self->{_curpath} : $self->{_curpath2};
}

sub cwd {
    my $self = shift;
    $self->_cwd(1);
}

sub cwd2 {
    my $self = shift;
    $self->_cwd(2);
}

sub _cp_or_mv {
    my $self = shift;
    my $which_cmd = shift;
    my ($src_path_wildcard, $target_path) = @_;

    length($src_path_wildcard) or die "$which_cmd: Please specify source path";
    length($target_path)       or die "$which_cmd: Please specify target path";

    # we can move/copy either to 'tree' or 'tree2'. default to 'tree2' when it
    # is defined, falls back to 'tree'.
    my $target_obj = defined $self->{_curnode2} ? 2:1;

    my ($source_path_exists, @source_entries) =
        $self->_traverse(1, $src_path_wildcard);
    die "$which_cmd: No such source path '$src_path_wildcard'"
        unless $source_path_exists;
    die "$which_cmd: No matching source files for '$src_path_wildcard'"
        unless @source_entries;

    my ($target_path_exists, @target_entries) =
        $self->_traverse($target_obj, $target_path);
    die "$which_cmd: No such target path '$target_path'"
        unless $target_path_exists;
    die "$which_cmd: No matching target files for '$target_path'"
        unless @target_entries;
    die "$which_cmd: Ambiguous target '$target_path'"
        unless @target_entries < 2;
    my $target_entry = $target_entries[0];

    if ($which_cmd eq 'cp') {
        # clone it first
        @source_entries = map { dclone($_) } @source_entries;
        if ($self->can("before_cp")) {
            $self->before_cp([map {$_->{node}} @source_entries],
                             $target_entry->{node});
        }
    } elsif ($which_cmd eq 'mv') {
        # remove the nodes from their original parents
        for my $entry (@source_entries) {
            Code::Includable::Tree::NodeMethods::remove($entry->{node});
        }
        if ($self->can("before_mv")) {
            $self->before_mv([map {$_->{node}} @source_entries],
                             $target_entry->{node});
        }
    } else {
        die "BUG: which_cmd must be cp/mv";
    }

    # put as children of the target parent
    push @{ $target_entry->{node}{children} },
        map { $_->{node} } @source_entries;

    # assign new (target) parent
    for my $entry (@source_entries) {
        $entry->{node}->parent( $target_entry->{node} );
    }
}

sub cp {
    my $self = shift;
    $self->_cp_or_mv('cp', @_);
}

sub mv {
    my $self = shift;
    $self->_cp_or_mv('mv', @_);
}

sub _rm {
    my $self = shift;
    my $which_obj = shift;
    my $path_wildcard = shift;

    my ($path_exists, @entries) =
        $self->_traverse($which_obj, $path_wildcard);
    die "rm: No such path '$path_wildcard'" unless $path_exists;
    die "rm: No matching files for '$path_wildcard'" unless @entries;

    for my $entry (@entries) {
        Code::Includable::Tree::NodeMethods::remove($entry->{node});
    }
}

sub rm {
    my $self = shift;
    $self->_rm(1, @_);
}

sub rm2 {
    my $self = shift;
    $self->_rm(2, @_);
}

sub _mkdir {
    my $self = shift;
    my $which_obj = shift;
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $path = shift;

    my $rootnode = $which_obj == 1 ? $self->{tree} : $self->{tree2};
    my $curpath  = $which_obj == 1 ? $self->{_curpath} : $self->{_curpath2};
    die "BUG: curpath '$curpath' is not absolute" unless Path::Naive::is_abs_path($curpath); # sanity check
    my @path_elems = Path::Naive::split_path(
        Path::Naive::concat_and_normalize_path($curpath, $path)
    );

    die "mkdir: / already exists" unless @path_elems;

    local $self->{_curnode} = $rootnode;
    local $self->{_curpath} = "/";

    my $made_dir;
    for my $i (0..$#path_elems) {
        my $path_elem = $path_elems[$i];
        my @entries = $self->_read_curdir;
        my $found_entry;
        for my $entry (@entries) {
            if ($entry->{name} eq $path_elem) {
                $found_entry = $entry; last;
            }
        }
        if ($found_entry) {
            $self->{_curnode} = $found_entry->{node};
            $self->{_curpath} = $found_entry->{path};
            next;
        }
        if ($opts->{parents} || $i == $#path_elems) {
            my $new_node = $self->on_mkdir($self->{_curnode}, $path_elem);
            # reread and find out the actual filename we're given
            @entries = $self->_read_curdir;
            my @new_entry = grep { refaddr($_->{node}) == refaddr($new_node) } @entries;
            die "BUG: Can't create '$path_elem' at $self->{_curpath}: node not found"
                unless @new_entry == 1;
            $self->{_curnode} = $new_node;
            $self->{_curpath} = $new_entry[0]{path};
            $made_dir++;
        } else {
            die "mkdir: No such path '".Path::Naive::concat_path($self->{_curpath}, $path_elem)."'";
        }
    }

    die "mkdir: $path already exists"
        if !$made_dir && !$opts->{parents};

    $self->{_curpath};
}

sub mkdir {
    my $self = shift;
    $self->_mkdir(1, @_);
}

sub mkdir2 {
    my $self = shift;
    $self->_mkdir(2, @_);
}

1;
# ABSTRACT: Perform filesystem-like operations on object tree(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

Tree::FSMethods - Perform filesystem-like operations on object tree(s)

=head1 VERSION

This document describes version 0.003 of Tree::FSMethods (from Perl distribution Tree-FSMethods), released on 2021-06-27.

=head1 SYNOPSIS

 use Tree::FSMethods;

 my $fs = Tree::FSMethods->new(
     tree => $tree,
     # tree2 => $other_tree,
     # filename_method => 'filename',
 );

Listing files:

 # list top-level (root)
 my %nodes = $fs->ls; # ("foo"=>{...}, "bar"=>{...}, "baz"=>{...})

 # specify path. will list all nodes under /proj.
 my %nodes = $fs->ls("/proj");

 # specify wildcard. will list all nodes under /proj which has 'perl' in their
 # names.
 my %nodes = $fs->ls("/proj/*perl*");

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Usage:

 my $fs = Tree::FSMethods->new(%args);

Arguments:

=over

=item * tree

Optional. Object. The tree node object. A tree node object is any regular Perl
object satisfying the following criteria: 1) it supports a C<parent> method
which should return a single parent node object, or undef if object is the root
node); 2) it supports a C<children> method which should return a list (or an
arrayref) of children node objects (where the list/array will be empty for a
leaf node). Note: you can use L<Role::TinyCommons::Tree::Node> to enforce this
requirement.

=item * tree2

See C<tree>.

Optional. Object. Used for some operations: L</cp>, L</mv>.

=item * filename_method

Optional. String or coderef.

By default, will call C<filename> method on tree node to get the filename of a
node. If that method is not available, will use C<title> method. If that method
is also not available, will use its "hash address" given by the stringification,
e.g. "HASH(0x56242e558740)" or "Foo=HASH(0x56242e558740)".

If C<filename_method> is specified and is a string, will use the method
specified by it.

If C<filename_method> is a coderef, will call the coderef, passing the tree node
as argument and expecting filename as the return value.

If filename is empty, will use "unnamed".

If filename is non-unique (in the same "directory"), will append ".2", ".3",
".4" (and so on) suffixes.

=back

=head2 cd

Usage:

 $fs->cd($path_wildcard);

Change working directory. Dies on failure.

=head2 cd2

Just like L</cd> but for the second tree (C<tree2>).

=head2 cwd

Usage:

 my $cwd = $fs->cwd;

Return current working directory.

=head2 cwd2

Just like L</cwd> but for the second tree (C<tree2>).

=head2 ls

Usage:

 my %res = $fs->ls( [ $path_wildcard, ... ]);

Dies on failure (e.g. can't cd to specified path).

=head2 ls2

Just like L</ls> but for the second tree (C<tree2>).

=head2 cp

Usage:

 $fs->cp($src_path_wildcard, $target_path);

Copies nodes from C<tree> to C<tree2> (or C<tree>, if C<tree2> is not loaded).
Dies on failure (e.g. can't find source or target path).

Examples:

 $fs->cp("proj/*perl*", "proj/");

This will set nodes under C<proj/> in the source tree matching wildcard
C<*perl*> to C<proj/> in the target tree.

=head2 mkdir

Usage:

 $fs->mkdir([ \%opts, ] $path);

Options:

=over

=item * parents

Boolean. Just like the same --parents (-p) option in the Unix utility. If set to
true, will create intermediate parents as necessary, and will not report error
when the directory already exists.

=back

=head2 mkdir2

Just like L</mkdir> but for the second tree (C<tree2>).

=head2 mv

Usage:

 $fs->mv($src_path, $target_path);

Moves nodes from C<tree> to C<tree2> (or C<tree>, if C<tree2> is not loaded).
Dies on failure (e.g. can't find source or target path).

=head2 rm

Usage:

 $fs->rm($path_wildcard);

=head2 rm2

Just like L</rm> but for the second tree (C<tree2>).

=head2 showtree

Usage:

 my $str = $fs->showtree([ $starting_path ]);

Like the DOS tree command, will return a visual representation of the
"filesystem", e.g.:

 file1
 file2
 |-- file3
 |-- file4
 |   |-- file5
 |   \-- file6
 \-- file7

=head2 showtree2

Just like L</showtree> but for the second tree (C<tree2>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tree-FSMethods>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tree-FSMethods>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tree-FSMethods>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
