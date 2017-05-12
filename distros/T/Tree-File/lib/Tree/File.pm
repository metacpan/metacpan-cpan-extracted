package Tree::File;

use warnings;
use strict;

use Carp qw(croak);
use File::Path ();

=head1 NAME

Tree::File - (DEPRECATED) store a data structure in a file tree

=head1 VERSION

version 0.112

=cut

our $VERSION = '0.112';

=head1 SYNOPSIS

 use Tree::File::Subclass;

 my $tree = Tree::File::Subclass->new($treerot);

 die "death mandated" if $tree->get("/master/die")

 print "Hello, ", $tree->get("/login/user/name");

 $tree->set("/login/user/lastlogin", time);
 $tree->write;

=head1 DESCRIPTION

This module stores configuration in a series of files spread across a directory
tree, and provides uniform access to the data structure.

It can load a single file or a directory tree containing files as leaves.  The
tree's branches can be returned as data structures, and the tree can be
modified and rewritten.  Directory-based branches can be collapsed back into
files and file-based branches can be exploded into directories.

=head1 METHODS

=head2 C<< Tree::File->new($treeroot, \%arg) >>

This loads the tree at the named root, which may be a file or a directory.  The
C<%arg> hash is optional, the following options are recognized:

  readonly  - if true, set and delete methods croak (default: false)
  preload   - the number of levels of directories to preload (default: none)
              pass -1 to preload as deep as required
  found     - a closure called when a node or value is found; it is passed the
              Tree::File object, the id requested, and the data retrieved; it
              should apply any transformations and return the 'real' value desired.
  not_found - a closure called if a node cannot be found; it is passed the id
              requested and the root of the last node reached; by default,
              Tree::File will return undef in this situation

=cut

sub new {
  my ($class, $root, $arg) = @_;

  $arg->{lock_mgr} = bless { root => $root } => "Tree::File::LockManager";

  my $self = $class->_load(q{}, $arg->{preload}, {%$arg, basedir => $root});

  return $self;
}

sub _as_arg {
  my $self = shift;
  return {
    map { $_ => $self->{$_} } qw(basedir lock_mgr readonly found not_found)
  };
}

sub _new_node {
  my ($self, $root, $data, $arg) = @_;
  my $class = ref $self ? ref $self : $self;

  if (ref $self and not $arg) {
    $arg = $self->_as_arg;
  }

  return $data if ref $data ne 'HASH';

  my $processed_data = {
    map { $_ => $self->_new_node("$root/$_", $data->{$_}, $arg) }
    keys %$data
  };

  bless {
    root => $root,
    data => $processed_data,
    %$arg
  } => $class;
}

=head2 C<< $tree->load_file($filename) >>

This method is used internally by Tree::File subclasses, which must implement
it.  Given the name of a file on disk, this method returns the data structure
contained in the file.

=cut

sub load_file { croak "load_file method unimplemented" }

sub _load {
  my ($self, $root, $preload, $arg) = @_;
  my $lock_mgr = $arg->{lock_mgr};

  eval { $lock_mgr->lock() };
  if ($@) {
    if ($@ =~ /couldn.t open lockfile/i) {
      $arg->{readonly}++;
      $lock_mgr->no_op;
    } else {
      die; ## no critic Carping
    }
  }

  my $file = $root ? "$arg->{basedir}/$root" : $arg->{basedir};

  if (-f $file) {
    my $data = $self->load_file($file);
    $lock_mgr->unlock();
    return $self->_new_node($root, $data, \%$arg);
  }

  elsif (-d $file) {
    my $dir;
    opendir $dir, $file or croak "can't open branch directory $dir: $!";

    my $tree = {};
    for my $twig (grep { $_ !~ /\A\./ && ! -l "$file/$_" && $_ ne 'CVS' } readdir $dir) {
      $tree->{$twig} = $preload
                       ? $self->_load("$root/$twig", $preload-1, { %$arg, preload => $preload-1})
                       : sub { $self->_load("$root/$twig", 0, { %$arg, preload => 0 }) };
    }
    $lock_mgr->unlock();
    return $self->_new_node($root, $tree, { %$arg, type => 'dir' });
  }

  else {
    $lock_mgr->unlock();
    croak "$file doesn't exist or isn't a normal file or directory";
  }
}

=head2 C<< $tree->get($id) >>

This returns the branch with the given name.  If the name contains slashes,
they indicate recursive fetches, so that these two calls are identical:

  $tree->get("foo")->get("bar")->get("baz");

  $tree->get("foo/bar/baz");

Leading slashes are ignored.

If a second, true argument is passed to C<get>, any missing data structures
will be autovivified as needed to get to the leaf.

=cut

sub _not_found {
  my ($self) = shift;
  if ($self->{not_found}) { return $self->{not_found}->(@_) }
  return;
}

sub _found {
  my ($self) = shift;
  return $self->{found} ? $self->{found}->($self, @_) : $_[1];
}

sub get {
  my ($self, $id, $autovivify) = @_;

  $id && $id =~ s|\A/+||;
  my $rest;

  croak "get called on $self without property identifier" unless defined $id;

  ($id, $rest) = split m|/|, $id, 2;
  if ($rest) {
    my $head = $self->get($id, $autovivify);
    return $self->_not_found($id, $self->{root}) unless $head;
    return $head->get($rest, $autovivify);
  }

  if (exists $self->{data}{$id}) {
    if (ref $self->{data}{$id} eq 'CODE') {
      $self->{data}{$id} = $self->{data}{$id}->();
    }
    return $self->_found($id, $self->{data}{$id});
  }

  if ($autovivify) {
    return $self->{data}{$id} =
      $self->_new_node("$self->{root}/$id", {});
  }

  return $self->_not_found($id, $self->{root});
}

=head2 C<< $tree->set($id, $value) >>

This sets the identified branch's value to the given value.  Hash references
are automatically expanded into trees.

=cut

sub set { ## no critic Ambiguous
  my ($self, $id, $value, $root) = @_;

  $value = $value->data if eval { $value->isa("Tree::File") };

  croak "set called on readonly tree" if $self->{readonly};

  $id && $id =~ s|\A/+||;
  $root = $id unless $root;
  my $rest;

  croak "set called on $self without property identifier" unless defined $id;

  ($id, $rest) = split m|/|, $id, 2;
  if ($rest) { return $self->get($id, 1)->set($rest, $value, $root); }

  return $self->{data}{$id} =
    $self->_new_node($root, $value);
}

=head2 C<< $tree->delete($id) >>

This method deletes the identified branch (and returns the deleted value).

=cut

sub delete { ## no critic Homonym
  my ($self, $id) = @_;

  croak "delete called on readonly tree" if $self->{readonly};

  $id && $id =~ s|\A/+||;
  my $rest;

  croak "delete called on $self without property identifier" unless defined $id;

  ($id, $rest) = split m|/|, $id, 2;
  if ($rest) { return $self->get($id)->delete($rest); }

  return delete $self->{data}{$id};
}

=head2 C<< $tree->move($old_id, $new_id) >>

This method deletes the value at the old id and places it at the new id.

=cut

sub move {
  my ($self, $old_id, $new_id) = @_;

  $self->set($new_id, $self->delete($old_id));
}

=head2 C<< $tree->path() >>

This method returns the path to this node from the root.

=cut

sub path {
  my ($self) = @_;
  return $self->{root};
}

=head2 C<< $tree->basename() >>

This method retuns the base name of the node.  (If, for example, the path to
the node is "/things/good/all" then its base name is "all".)

=cut

sub basename {
  my ($self) = @_;
  my @parts = split m{/}, $self->path();
  return $parts[-1];
}

sub _handoff {
  my $self = shift;
  my $method = (caller(1))[3];
  $method =~ s/.*:://;
  my $node = $self->get(@_);
  unless ($node) {
    return $self->_not_found(@_);
  }
  #warn "handing off $method to " . $node->path . "\n";
  $node->$method;
}

=head2 C<< $tree->node_names() >>

This method returns the names of all the nodes beneath this branch.

=cut

sub node_names {
  my $self = shift;
  return $self->_handoff(@_) if @_;
  return sort keys %{$self->{data}};
}

=head2 C<< $tree->nodes() >>

This method returns each node beneath this branch.

=cut

sub nodes {
  my $self = shift;
  return $self->_handoff(@_) if @_;
  return map { $self->get($_) } $self->node_names();
}

=head2 C<< $tree->branch_names >>

=cut

sub branch_names {
  my $self = shift;
  return $self->_handoff(@_) if @_;
  return grep { eval { $self->get($_)->isa("Tree::File") } } $self->node_names;
}

=head2 C<< $tree->branches >>

This method returns all the nodes on this branch which are also branches (that
is, are also Tree::File objects).

=cut

sub branches {
  my $self = shift;
  return $self->_handoff(@_) if @_;
  return map { $self->get($_) } $self->branch_names();
}

=head2 C<< $tree->data() >>

This method returns the entire tree of data as an unblessed Perl data
structure.

=cut

sub data {
  my ($self) = @_;
  my %data;

  for ($self->node_names) {
    my $datum = $self->get($_);

    $data{$_} = eval { $datum->isa("Tree::File") } ? $datum->data
                                                   : $datum;
  }

  return \%data;
}

=head2 C<< $tree->write($basedir) >>

This method forces the object to write itself out to disk.  It will write out
branches to directories if a directory for the branch already exists, or if it
was orginally loaded as a directory.

=cut

sub write { ## no critic Homonym
  my $self    = shift;
  my $basedir = shift || $self->{basedir};
  my $root    = $basedir ? "$basedir/$self->{root}" : $self->{root};
  my $lock_mgr = $self->{lock_mgr};

  $self->data; # force load of all data now

  my $type = $self->type
          || (-d $root && 'dir')
          || 'file';

  $lock_mgr->lock();

  if ($type eq 'dir') {
    File::Path::rmtree($root) if -d $root;
    File::Path::mkpath($root);
    for ($self->node_names) {
      my $datum = $self->get($_);
      if (eval { $datum->isa("Tree::File") }) { $datum->write($basedir) }
      else { $self->write_file("$root/$_", $datum) }
    }
  } else {
    File::Path::rmtree($root) if -d $root;
    $self->write_file($root, $self->data);
  }

  $lock_mgr->unlock();

  1;
}

=head2 C<< $tree->write_file($filename) >>

This method is used by Tree::File's C<write> method.  It must be implement in
subclasses of Tree::File.  Given the name of a file on disk and a data
structure, this method writes the data structure to the file.

=cut

sub write_file { croak "write_file method unimplemented" }

=head2 C<< $tree->type($type) >>

This method returns the branch type for the given branch.  If C<$type> is
defined and one of "dir" or "file" it will set the type and return the new
value.

=cut

sub type {
  my $self = shift;
  return $self->{type} unless @_;

  my $type = shift;
  return $self->{type} = undef unless defined $type;

  croak "invalid branch type: $type" unless $type =~ /\A(?:dir|file)\Z/;

  $self->{type} = $type;
}

=head2 C<< $tree->explode()  >>

=head2 C<< $tree->collapse() >>

These methods set the type of the branch to "dir" and "file" respectively.

=cut

sub explode  { (shift)->type("dir")  }
sub collapse { (shift)->type("file") }

package Tree::File::LockManager;

use Carp ();
use Fcntl qw(:DEFAULT :flock);
use File::Basename ();

sub lock {
  my ($self, $tree) = @_;
  return if $self->{_no_op};

  unless ($self->{_lockfile}) {
    my $lockfile = File::Basename::dirname($self->{root}) . "/.lock";
    unless (-e $lockfile) {
      open(my $lock, '>', $lockfile)
        or Carp::croak("couldn't create lockfile $lockfile");
      print $lock time, "\n";
      close $lock;
    }
    $self->{_locks} = 0;
    open($self->{_lockfile}, "+<", $lockfile)
      or Carp::croak("couldn't open lockfile $lockfile");
  }
  flock($self->{_lockfile}, LOCK_EX);
  ++$self->{_locks};
}

sub unlock {
  my ($self, $tree) = @_;
  return if $self->{_no_op};
  return unless $self->{_lockfile};
  flock($self->{_lockfile}, LOCK_UN) if (--$self->{_locks} == 0);
  return $self->{_locks};
}

sub no_op {
  my $self = shift;
  $self->{_no_op}++;
}

=head1 TODO

=over

=item * symlinks and references

=item * serialization through delegation, not inheritance

=item * make locking methods pluggable

=item * callback for determining which files to skip

=back

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-file@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
