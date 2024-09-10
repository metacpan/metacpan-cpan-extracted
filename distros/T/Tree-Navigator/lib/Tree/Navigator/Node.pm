package Tree::Navigator::Node;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
use List::MoreUtils qw/part/;

use MooseX::Params::Validate;
use Params::Validate         qw/ARRAYREF HASHREF/;
use Scalar::Util             qw/weaken/;

#======================================================================
# attributes
#======================================================================

has 'mount_point' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
 );

has 'path' => (    # cumulated path from the mount point
  is      => 'ro',
  isa     => 'Str',
  default => '',
 );

has 'attributes' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_attributes',
 );

has 'content' => (
  # "is  => 'ro'" but don't generate the accessor, it's coded below
  isa       => 'FileHandle',
  predicate => 'has_content',
  lazy      => 1,
  builder   => '_content',
  init_arg  => undef,
 );

has 'mounted' => (
  is       => 'ro',
  isa      => 'ArrayRef',
  default  => sub { [] },
  init_arg => undef,
 );
has 'mounted_at' => (
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
  init_arg => undef,
 );



#======================================================================
# mounting a node from a different subclass
#======================================================================

# class method to check and rearrange $mount_args, before giving
# them to ->new()
sub MOUNT {
  my ($class, $mount_args) = @_;
  return;
}

sub mount {
  my $self = shift;

  # validate method arguments
  my ($path, $node_class, $node_args, $mount_args) = pos_validated_list(
    \@_,
    { regex => qr[^[^/]*$] },           # path: no '/'
    { regex => qr[.+]      },           # node class
    { type => HASHREF, default => {} }, # node_args
    { type => HASHREF, default => {} }, # $mount_args
   );

  # validate mount path
  my $mounted_at = $self->mounted_at;
  not exists $mounted_at->{$path}
    or die "mount path $path' already in use";

  # load and instantiate
  my $class = Plack::Util::load_class($node_class, 'Tree::Navigator::Node');
  $class->MOUNT($node_args); # validates and rearranges $node_args
  my $node = $class->new(path => '', %$node_args);

  # inject some info into mount point
  my $mount_point = $node->mount_point;
  $mount_point->{path}      = $self->_join_path($self->full_path, $path);
  $mount_point->{navigator} = $self->mount_point->{navigator};
  weaken $mount_point->{navigator};

  # register
  push @{$self->mounted}, $path unless $mount_args->{hidden};
  $mounted_at->{$path} = $node;
}




#======================================================================
# instance methods to be refined in subclasses
#======================================================================
sub _attributes {
  my $self = shift;
  return {};
}

sub _children {
  my $self = shift;
  return [];
}

sub child {
  my ($self, $child_name) = @_;
  my $child = $self->mounted_at->{$child_name}
            || $self->_child($child_name)
    or die "no such child: '$child_name' in " . $self->full_path;
  return $child;
}


sub _child {
  my ($self, $child_name) = @_;
  return undef;
}


sub children {
  my $self = shift;
  my $mounted  = $self->mounted;
  my $children = $self->_children;
  return @$mounted, @$children;
}


sub content {
  my $self = shift;
  if (my $fh = $self->{content}) {
    # if the filehandle is already present, rewind it to beginning of file
    $fh->seek(0, 0);
    return $fh;
  }
  else {
    return $self->_content;
  }
}



sub _content {
  my $self = shift;
  return undef;
}

sub content_text {
  my $self = shift;
  my $fh = $self->content;
  return $fh ? join("", <$fh>) : "";
}


#======================================================================
# generic methods
#======================================================================
sub descendent {
  my ($self, $path) = @_;

  # $self is its own descendent if $path is empty
  return $self if ($path // '') eq ''; # NOTE : '0' is a valid nonempty path!

  # otherwise, find the child from initial path segment, and then recurse
  my ($child_name, $subpath) = split m{/}, $path, 2;
  my $child = $self->child($child_name)
    or die "no such child: $child_name";
  return $child->descendent($subpath);
}

sub is_parent { # default implementation; may be optimised in subclasses
  my $self = shift;
  my @children = $self->children;
  return @children ? 1 : 0;
}

sub _join_path {
  my ($self, $path_ini, $path_end) = @_;
  $_ //= '' for $path_ini, $path_end;

  return $path_ini ne '' ? $path_end ne '' ? "$path_ini/$path_end"
                                           : $path_ini
                         : $path_end;
}

sub full_path {
  my $self = shift;

  return $self->_join_path($self->mount_point->{path}, $self->path);
}


sub last_path {
  my $self = shift;
  my $path = $self->full_path;
  $path =~ s[^.*/][];
  return $path;
}

sub subnodes_and_leaves {
  my $self = shift;
  my ($subnodes, $leaves)
    = part {$self->child($_)->is_parent ? 0 : 1} $self->children;
  $_ //= [] for $subnodes, $leaves;
  return ($subnodes, $leaves);
}



#======================================================================
# WORK IN PROGRESS
#======================================================================

sub navigator {
  my $self = shift;
  return $self->mount_point->{navigator};
}

sub data {
  my $self = shift;
  my %data = (attributes   => $self->attributes,
              content_text => $self->content_text);

  foreach my $child_name ($self->children) {
    my $child = $self->child($child_name);
    push @{$data{children}}, {name       => $child_name, 
                              attributes => $child->attributes};
  }

  return \%data;
}


sub view {
  my $self = shift;
  return $self->navigator->view(@_);
}


sub response {
  my ($self, $request) = @_;
  my $view = $self->view($self->choose_view($request));
  return $view->render($self, $request);
}


sub choose_view {
  my ($self, $request) = @_;
  return;
}




__PACKAGE__->meta->make_immutable;

1; # End of Tree::Navigator::Node

=encoding utf8

=head1 NAME

Tree::Navigator::Node - a node to be displayed in a Tree::Navigator

=cut

=head1 SYNOPSIS

See L<Tree::Navigator>

=head1 SPECIFICATION

=head2 Node structure

A B<node> is an object that may contain

=over

=item attributes

An B<attribute value> is either C<undef> or a Perl string.
An B<attribute name> is a non-empty Perl string.
An B<attribute list> is an ordered list of pairs (name, value).


=item content

A filehandle to some opaque content stored within the node.


=item children

A B<child> is another node stored under the current node.
A B<child name> is a non-empty Perl string.
The B<children> of a node is an ordered list of pairs (name, child).

=back


=head1 METHODS

=head2 Basic node access methods

=head3 attributes

  my $attrs = $node->attributes;

Returns a hashref of key-value pairs. Values are either C<undef> or
Perl strings (or anything that may stringify to a Perl string).

=head3 children

  my @children_names = $node->children;

Returns an ordered list of distinct, non-empty strings (the names of
B<published children>).

=head3 child

  my $child = $node->child($child_name);

Returns a reference to the node stored under name C<$child_name>
within C<$node>.  The name C<$child_name> does not necessarily belong
to the list of published children (in which case this is a B<hidden
child>).  If the node contains neither a published nor a hidden child
under C<$child_name>, an exception is raised.

C<$child_name> must be a non-empty string and must not contain any
slash (C<'/'>).

=head3 content

  my $fh = $node->content or die "this node has no content";
  while (my $content_line = <$fh>) {
    print $content_line;
  }

Returns either C<undef>, or a reference to an IO::Handle-like object
having a C<getline> method. Several successive calls to the C<content()>
method will return the same handle, but each time re-positioned at
the beginning of the file (see L<IO::Seekable>).


=head2 Derived access methods




=head3 descendent

  my $descendent_node = $node->descendent($path);

Returns the descendent node path C<$path>.



=head1 SUBCLASSING

To implement a new kind of node, you must subclass 
C<Tree::Navigator::Node> and implement the methods described
below. 

=head2 MOUNT

=head2 _children

=head2 _child

=head2 _attributes

=head2 _content

=head2 is_parent


=head1 AUTHOR, BUGS, SUPPORT, COPYRIGHT

See L<Tree::Navigator>.


=head1 TODO

  - maybe this class should be split into a Role + a Base class

  REST API
    /path/to/node
    /path/to/node?v=view_name
    /path/to/node/child_name
    /path/to/node.attributes
    /path/to/node.content
    /path/to/node.children
       ex: /path/to/file.doc
           /path/to/file.doc?v=frame
           /_toc/path/to/file.doc
           /path/to/file.doc?v=title
           /path/to/file.doc.attributes+content

     # OTHER POSSIBILITY
     /path/to/node.$view_name (handy for  .xml, .yaml, : auto MIME detection)
     /path/to/node;subitem.$view_name
     /path/to/node/@subitem.$view_name
     /path/to/node?search=query

     Q : diff between 
           /path/to/node/ : full data (attributes, children % content)
           /path/to/node 
  ?v=view
   p=part1,part2
   s=search_string



  METHODS

    my $data = $node->data(@parts);
    my $view = $node->view($name, $view_args) || $tn->view()
    my $resp = $view->render($data, $node, $tn);

    $node->retrieve($parts) # subnodes, leaves, attributes, content
    $node->render($tn, $parts, $view, $view_args);
    my $view = $node->view($name, $view_args) || $tn->view()
    $node->present($tn, $parts, $view)
    $view->present($node)

Decide
  - $node->child($wrong_path) : should die or return undef ?


  ->mount(path       => 'foo',
          node_class => 'Filesys',
          mount_point => )

=cut






