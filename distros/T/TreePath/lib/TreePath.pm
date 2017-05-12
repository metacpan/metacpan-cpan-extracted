package TreePath;
$TreePath::VERSION = '0.22';
use utf8;
use Moose;
with 'MooseX::Object::Pluggable';

use Moose::Util::TypeConstraints;
use Config::JFDI;
use Carp qw/croak/;
use Data::Dumper;

subtype MyConf => as 'HashRef';
coerce 'MyConf'
  => from 'Str' => via {
    my $conf = shift;
    my ($jfdi_h, $jfdi) = Config::JFDI->open($conf)
      or croak "Error (conf: $conf) : $!\n";
    return $jfdi->get;
  };

has conf => ( is => 'rw',
              isa => 'MyConf',
              coerce => 1,
              trigger  => sub {
                  my $self = shift;
                  my $args = shift;

                  # if args exist
                  if ( defined $args->{$self->configword} ) {
                      croak "Error: Can not find " . $self->configword . " in your conf !"
                          if ( ! $args->{$self->configword});

                      $self->config($args->{$self->configword});

                      $self->debug($self->config->{'debug'})
                          if ( ! defined $self->debug && defined $self->config->{'debug'} );

                      my $backend = $self->config->{'backend'}->{name};
                      $self->backend($backend);
                  }
              }
            );



has datas => ( is => 'rw',
              isa => 'ArrayRef',
          );

has config => (
               isa      => "HashRef",
               is       => "rw",
);

has 'configword' => (
                is       => 'rw',
                default => sub { __PACKAGE__ },
               );

has 'debug' => (
                is       => 'rw',
               );

has 'backend' => (
                is       => 'rw',
                isa      => 'Str',
                trigger  => sub {
                    my $self    = shift;
                    my $backend = shift;

                    $self->_log("Loading $backend backend ...");
                    $self->load_plugin( $backend );
                    }
               );

has _plugin_ns => (
                is       => 'rw',
                required => 1,
                isa      => 'Str',
                default  => sub{ 'Backend' },
                  );

has tree => (
                isa      => "HashRef",
                is       => "rw",
                default  => sub {{}},
            );


has root => (
                isa      => "HashRef",
                is       => "rw",
);



sub _log{
  my ($self, $msg ) = @_;

  return if ! $self->debug;

  say STDERR "[debug] $msg";
}

# this method is overridden if a backend is loaded
sub _load{
    my $self  = shift;

    return $self->datas;
}


sub load{
    my $self  = shift;

    my $nodes = $self->_load;

    $nodes = $self->_load_order($nodes);
    foreach my $node (@$nodes) {
        $self->add($node);
    }
}

sub _load_order{
    my $self  = shift;
    my $nodes = shift;

    my @nodes_ordered;
    if ( defined $self->config && defined $self->config->{backend} && defined $self->config->{backend}->{args}) {
        my $load_order = $self->config->{backend}->{args}->{load_order};
        if ( defined $load_order) {
            foreach my $source ( @$load_order ) {
                foreach my $node ( @$nodes ) {
                    if ( $node->{$self->_get_key_name('source', $node)} eq $source) {
                        push(@nodes_ordered, $node);
                    }
                }
            }
            return \@nodes_ordered;
        }
    }

    return $nodes;
}


# removes the child's father
sub _remove_child_father{
    my $self = shift;
    my $node = shift;

    my $father = $node->{$self->_get_key_name('parent', $node)};
    my $key_children = $self->_key_children($node, $father);
    my $id = 0;
    foreach my $child ( @{$father->{$key_children}}) {
        if ( $child->{$self->_get_key_name('search', $child)} eq $node->{$self->_get_key_name('search', $node)} &&
                 $child->{$self->_get_key_name('parent', $child)} eq $node->{$self->_get_key_name('parent', $node)} ){
            return splice ( @{$father->{$key_children}},$id,1);
        }
        $id++;
    }
}


sub _obj_key {
  my $self = shift;
  my $node = shift;

  return $node->{$self->_get_key_name('source', $node)} . '_' . $node->{$self->_get_key_name('primary', $node)};
}


# return key name of children parent
sub _key_children {
    my ($self, $node, $parent) = @_;

    my $key_children;
    my $node_source_key   = $self->_get_key_name('source', $node);
    my $parent_source_key = $self->_get_key_name('source', $parent);

    # if node and parent have the same source
    if ( $node->{$node_source_key} eq $parent->{$parent_source_key} ) {
        $key_children = 'children';
    }
    else {
        $key_children = 'children_' . $node->{$node_source_key};
    }
    return $key_children;
}


sub search {
  my ( $self, $args ) = @_;

  my $results = [];
  my $tree = $self->tree;
  foreach my $id  ( sort {$a cmp $b} keys %$tree ) {

      my $found = 1;


      foreach my $key ( keys %$args ) {
          my $current;
          if ( $key =~ m/(.*)\.(.*)/) {
              # ex: parent.name
              if ( defined $tree->{$id}->{$1} && ref($tree->{$id}->{$1})) {
                  $current = $tree->{$id}->{$1}->{$2};
              }
              else { next }
          }
          else {
              if ( defined $tree->{$id}->{$key} ){
                  $current = $tree->{$id}->{$key};
              }
              else {
                  #print "the '$key' key is unknown [node obj_key:$id]\n";
                  $found = 0;
                  next;
              }
          }
          my $value = $args->{$key};
          if ( $current ne $value ) {
              $found = 0;
              last;
          }
      }

      if ( $found ){
          if ( wantarray) {
              push(@$results, $tree->{$id});
          }
          # if found and scalar context
          else {
              return $tree->{$id};
          }
      }
  }

  return 0 if (  ! wantarray && ! $$results[0] );

  # wantarray
  return @$results;
}


# ex : search_path(/A/B/C')
#      or search_path(/A/B/C, { by => 'name', source => 'Page'} )
sub search_path {
  my ( $self, $source, $path ) = @_;

  croak "path must be start by '/' !: $!\n" if ( $path !~ m|^/| );

  my $search_key = $self->_get_key_name('search', { source => $source});

  my $nodes = [ split m%/%, $path ];
  $$nodes[0] = '/';

  my $not_found = 0;
  my (@found, @not_found);
  foreach my $node ( @$nodes ) {

    my $result = $self->search({ $search_key => $node, source => $source } );

    if ( ! $not_found && $result ) {
        push(@found, $result);
    }
    else {
        $not_found = 1;
        push(@not_found, $node);
    }
  }

  if ( wantarray ) {
    return ( \@found, \@not_found );
  }
  else {
    if ( $not_found[-1] ) {
      return '';
    }
    else {
      return $found[-1];
    }
  }
}


sub count {
  my $self = shift;

  return scalar keys %{$self->tree};
}

sub dump {
  my $self = shift;
  my $var  = shift;

  $var = $self->tree if ! defined $var;
  $Data::Dumper::Maxdepth = 3;
  $Data::Dumper::Sortkeys = 1;
  $Data::Dumper::Terse = 1;
  return Dumper($var);
}

sub traverse {
  my ($self, $node, $funcref, $args) = @_;

  return 0 if ( ! $node );
  $args ||= {};
  $args->{_count} = 1 if ! defined ($args->{_count});

  my $hasfunc = 0;
  if ( ! $funcref ) {
    $hasfunc = 1;
    $funcref = sub {    my ($node, $args) = @_;
                        $args->{_each_nodes} = []
                          if ( ! defined $args->{_each_nodes});
                        if(defined($node)) {
                          push(@{$args->{_each_nodes}}, $node);
                          return 1;
                        }
                      }
  }
  # if first node
  if ( $args->{_count} == 1 ) {
    return 0 if ( ! &$funcref( $node, $args ) )
  }



  foreach my $field ( keys %$node) {
      if ( ref($node->{$field}) eq 'ARRAY') {
        foreach my $child ( @{$node->{$field}} ) {
          return 0 if ( ! &$funcref( $child, $args ) );
          $args->{_count}++;
          $self->traverse( $child, $funcref, $args );
        }
      }
  }

  return $args->{_each_nodes} if $hasfunc;
  return 1;
}


sub del {
  my ($self, @nodes) = @_;

  my @deleted;
  foreach my $node ( @nodes ) {

      $self->_remove_child_father($node);

      my $key_children = $self->_key_children($node, $node->{parent});

      # traverse child branches and delete it
      my $Nodes = $self->traverse($node);

      push(@deleted,map { delete $self->tree->{$self->_obj_key($_)} } @$Nodes);
  }
  return @deleted;
}



sub _get_key_name {
  my ($self, $key, $node) = @_;

  my $values = {
      source => 'source',
      primary => 'id',
      parent => 'parent',
      search => 'name',
  };

  die "the key '$key' is unknown in _get_key_name !"
      if ! defined $values->{$key};

  if ( defined $self->config && defined $node->{source} ) {
      my $key_name = $self->config->{backend}->{args}->{sources_name}->{$node->{source}}->{"${key}_key"};
      return $key_name || $values->{$key};
  }
  return $values->{$key};
  };


# checks that the necessary keys are set
sub _normalize_node {
  my ($self, $node, $parent) = @_;

  # check parent key
  my $primary_key =  $self->_get_key_name('primary', $node);
  die "primary key $primary_key is not set in node " . $self->_obj_key($node) ." !\nAdd 'id' to config args/" . $node->{$self->_get_key_name('source',$node) } . "/columns"
      if ! defined $node->{$primary_key};

  my $parent_key = $self->_get_key_name('parent', $node);

  # transform obj_id to object reference
  foreach my $col ( keys %$node ) {

      # hash = belongs_to
      if ( ref($node->{$col}) eq 'HASH') {

          my @values = keys %{$node->{$col}};
          # hasref is not already transformed
          if ( ! defined $values[1] ) {
              my $value = $values[0];
              if ( $value =~ m/^\w*_\d*$/ ) {
                  $node->{$col} = $self->tree->{$value};
              }
              else {
                  die "Error: Relationship belongs_to is not well formatted : '$value', use Obj_ID as form"
              }
          }
      }
      # array = has_may
      elsif ( ref($node->{$col}) eq 'ARRAY') {
          my $newarray = [];
          foreach my $child (@{$node->{$col}}) {
              if ( $child =~ m/^\w*_\d*$/ ) {
                  push(@$newarray, $self->tree->{$child});
              }
              elsif ( ref($child) eq 'HASH') {
                  # push(@$newarray, $child);
                  my @values = keys %{$child};
                  # hasref is not already transformed
                  if ( ! defined $values[1] ) {

                      die "tree->{$values[0]} doesn't exist, can not load " . $self->_obj_key($node) . " !\n"
                          if ( ! exists $self->tree->{$values[0]} );

                      push(@$newarray, $self->tree->{$values[0]});
                  }
              }
              else {
                  die "Error : has_many relationship $col (=$child) is not formatted, ex: 'Page_3'\n";
              }
          }
          $node->{$col} = $newarray;
      }
  }

}


# Inserts a node beneath the parent
sub add {
  my ($self, $node, $parent) = @_;

  $self->_log("Add node ". $self->_obj_key($node));

  my $parent_key = $self->_get_key_name('parent', $node);

  if ( $parent ) {
      $node->{$parent_key} = $parent;
  }

  $self->_normalize_node($node, $parent);

  if ( exists $node->{$parent_key} ){
      if ( $node->{$parent_key} ) {
          #print "parent is defined and not null\n";
          my $key_children = $self->_key_children($node, $node->{$parent_key});
          push(@{$node->{$parent_key}->{$key_children}}, $node);
      }
      else {
          #print "it's root\n";
          if ( $self->root) {
              die "root already exist [ node: " .$node->{$self->_get_key_name('source', $node)}. '_' . $node->{$self->_get_key_name('primary', $node)} . " ]!";
          }
          $self->root($node);
      }
  }
  else {
      #print "parent is not defined, node is an orphan\n";
  }

  # save ref node in tree
  $self->tree->{$self->_obj_key($node)} = $node;

  return $node;
}

sub update {
  my ($self, $node, $datas) = @_;

  $self->_log("Update node ". $self->_obj_key($node));
  $self->_normalize_node($node);

  foreach my $k ( sort keys %$datas ) {

      if ( ! defined $node->{$k} ){
              #$self->_log("update: can not update, node->{$k} is not defined");
              #next;
              $self->_log("node->{$k} is not defined, continue ...");
      }
      elsif ( $node->{$k} eq $datas->{$k} ){next}

      my $previous = $node->{$k};
      my $parent   = $node->{$self->_get_key_name('parent', $node)};
      my $key_children = $self->_key_children($node, $parent);
      my $children = $parent->{$key_children};


      if ( $k eq $self->_get_key_name('parent', $node)) {

          my $old = $self->_remove_child_father($node);
          my $new_parent = $datas->{$k};
          push(@{$new_parent->{$key_children}}, $old);

          $node->{$self->_get_key_name('parent', $node)} = $new_parent;
      }
      else {
          $node->{$k} = $datas->{$k};
      }
  }
  return $node;
}


sub move {
    my ($self, $node, $parent) = @_;

    $self->_normalize_node($node);
    return $self->update($node, { $self->_get_key_name('parent', $node) => $parent });
}

=head1 NAME

TreePath - Simple Tree Path!

This module is at EXPERIMENTAL stage, so use with caution.

=head1 VERSION


=head1 SYNOPSIS

 use TreePath;

 my $tp = TreePath->new(  conf  => $conf  );

 # load datas from backend
 $tp->load;

 my $tree = $tp->tree;

 # All nodes are hash
 # The first is called 'root'
 my $root = $tp->root;

 # a node can have children
 my $children = $root->{children};

 # or children from another source (if Source has a parent key)
 my $children = $root->{children_Comment};

 # also can has_many relationship. it's the same but without parent key
 my files = $root->{files};

=head1 SUBROUTINES/METHODS

=head2 new($method => $value)

 # for now there are two backends : DBIX and File
 $tp = TreePath->new( conf => 't/conf/treefromdbix.yml')
 # $tp = TreePath->new( conf => 't/conf/treefromfile.yml')

 # see t/conf/treepath.yml for hash structure
 $tp = TreePath->new( datas => $datas);

 also see t/01-tpath.t

=cut

=head2 load

 # The data load is not automatic
 $tp->load;

=cut

=head2 tree

 $tree = $tp->tree;

=cut

=head2 nodes

 $root = $tp->root;

 This is the root node ( a simple hashref )
 it has no parent.

               {
                'id' => '1',
                'name' => '/',
                'parent' => '0' # or ''
                'source' => 'Page'
              }

  All keys can be a relation to another source, as belong_to with DBIx like this :
               {
                'id' => '15',
                'name' => '/',
                'parent' => { 'Page_10' }
                'source' => 'Comment'
              }

  where 'Page' is the source of relationship and '10' the id. So Comment_15 is linked with Page_10.

  See the dump of a node example :


          {
            'id' => 2,
            'name' => 'A',
            'source' => 'Page'
            'parent' => {
                          'children' => [
                                          $VAR1
                                        ],
                          'children_Comment' => [
                                                  'HASH(0x52b6df8)',
                                                  'HASH(0x52aab28)',
                                                  'HASH(0x527daf8)'
                                                ],
                          'files' => [
                                       'HASH(0x43de208)',
                                       'HASH(0x52d8c80)'
                                     ],
                          'id' => 1,
                          'name' => '/',
                          'parent' => undef,
                          'source' => 'Page'
                        },
            'children' => [
                            {
                              'children' => 'ARRAY(0x52cbd70)',
                              'files' => 'ARRAY(0x52dbc30)',
                              'id' => 3,
                              'name' => 'B',
                              'parent' => $VAR1,
                              'source' => 'Page'
                            },
                            {
                              'children' => 'ARRAY(0x52dbb58)',
                              'children_Comment' => 'ARRAY(0x528ba38)',
                              'files' => 'ARRAY(0x52e45d8)',
                              'id' => 7,
                              'name' => "\x{2665}",
                              'parent' => $VAR1,
                              'source' => 'Page'
                            }
                          ],
            'children_Comment' => [
                                    {
                                      'id' => 3,
                                      'page' => $VAR1,
                                      'source' => 'Comment'
                                    },
                                    {
                                      'id' => 4,
                                      'page' => $VAR1,
                                      'source' => 'Comment'
                                    }
                                  ],
            'files' => [],
          }


    => 'parent' is a reference to root node and 'children' is an array containing 2 Pages, children_Comment has 2 Comments

=cut

=head2 search (hashref)

 # in scalar context return the first result
 my $E = $tp->search( { name => 'E', source => 'Page' } );

 # return all result in array context
 my @allE = $tp->search( { name => 'E', source => 'Page' } );

 # It is also possible to specify a particular field of a hash
 my $B = $tp->search( { name => 'B', source => 'Page', 'parent.name' => 'A'} );

=cut

=head2 search_path (SOURCE, PATH)

 # Search a path in a tree
 # in scalar context return last node (last page in this example)
 my $c = $tp->search_path('Page', '/A/B/C');

 # in array context return found and not_found nodes
 my ($found, $not_found) = $tp->search_path('Page', '/A/B/X/D/E');

=cut

=head2 dump

 # dump whole tree
 print $tp->dump;

 # dump a node
 print $tp->dump($c);;

=cut

=head2 count

 # return the number of nodes
 print $tp->count;

=cut

=head2 traverse ($node, [\&function], [$args])

 # return an arrayref of nodes
 my $nodes = $tp->traverse($node);

 # or use a function on each nodes
 $tp->traverse($node, \&function, $args);

=cut

=head2 del ($node)

 # delete recursively all children and node
 $deleted = $tp->del($node);

 # delete several nodes at once
 @del = $tp->del($n1, $n2, ...);

=cut

=head2 add ($node, [ $parent ])

 # add the root
 $root = $tp->add({ name => '/', source => 'Node', id => 123 });

 # add a node beneath the parent.
 $Z = $tp->add({ name => 'Z', source => 'Node' }, $parent);

=cut

=head2 update ($node, $datas)

 # update node with somes datas
 $Z = $tp->update($node, { name => 'new_name' });


=cut


=head2 move ($node, $parent)

 # move a node as child of given parent
 $Z = $tp->move($Z, $X);

=cut


=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tpath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TreePath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TreePath


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TreePath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TreePath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TreePath>

=item * Search CPAN

L<http://search.cpan.org/dist/TreePath/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Daniel Brosseau.

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

1; # End of TreePath
