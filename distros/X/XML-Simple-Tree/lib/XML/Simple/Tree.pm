package XML::Simple::Tree;
## Aaron Dancygier
## $Id: Tree.pm,v 1.17 2005/11/09 01:21:53 aaron Exp $

use strict;

use Carp;
use XML::Simple;
use Storable qw(dclone);
use Class::MethodMaker [ 
  scalar => [ 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'pos',
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'level', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'rnode', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'pnode', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'cnode', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'wnode', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'node_key', 
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'target_key',
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'file',
    { '*_get' => 'get_*', '*_set' => '_set_*', }, 'string'
  ] 
] ;

our ($VERSION);

$VERSION = '0.03';

sub new {
  my ($class, %data) = @_;

  my $self = \%data;

  bless $self, $class;

  ($self->file_isset() && -e $self->get_file()) ||
    ($self->string_isset()) ||
      croak "file or string field must be set\n";

  $self->_set_rnode(
    XMLin(
      ($self->file_isset()) ? $self->get_file() : $self->get_string(), 
      forcearray => 1
    ) ||
      croak "can't create XML::Tree::Simple object\n"
  );

  ($self->node_key_isset()) ||
    croak "must specify node key\n";

  ($self->target_key_isset()) ||
    croak "must specify target key\n";

  $self->_set_cnode($self->get_rnode());

  return $self;
}

sub find_node {
  my ($self, $name) = @_;

  my $cnode = $self->get_cnode();
  my $target_key = $self->get_target_key(); # ex name
  my $node_key = $self->get_node_key(); ## ex gallery
  return undef unless(exists ($cnode->{$node_key}));

  foreach ($self->children()) {
    if ($_->{$target_key}[0] eq $name) {
      # set parent node of wanted  node
      $self->_set_pnode($cnode);
      $self->_set_wnode($_);
      last;
    }
    
    unless (exists($_->{$node_key})) {
      next;
    }
   
    $self->_set_cnode($_);

    # recurse the next level
    $self->find_node($name);
  }

  ## reset current node to root
  $self->_set_cnode($self->get_rnode());

  return $self->get_wnode() || undef;
}

sub children {
  my ($self) = @_;

  my $cnode = $self->get_cnode();
  my $node_key = $self->get_node_key(); ## ex gallery

  return undef unless (exists($cnode->{$node_key}));

  return @{$cnode->{$node_key}};
}

sub siblings {
  my ($self) = @_;

  my $pnode = $self->get_pnode();
  my $node_key = $self->get_node_key();

  return undef unless (exists($pnode->{$node_key}));

  return @{$pnode->{$node_key}};
}

sub cut_node {
  my ($self, $name) = @_;

  $self->find_node($name) || return undef; 
  my $pnode = $self->get_pnode();

  my $index = 0;
  my $found = 0;
 
  my $target_key = $self->get_target_key();
  my $node_key = $self->get_node_key();

  foreach ($self->siblings()) {
    if ($_->{$target_key}[0] eq $name) {
      $found = 1;
      last;
    } 
    $index ++;
  }
  splice(@{$pnode->{$node_key}}, $index, 1) if ($found);
}

sub move_node {
  my ($self, $name, $direction) = @_;

  $self->find_node($name) || return undef; 
  my $pnode = $self->get_pnode();

  my $index = 0;
  my $found = 0;
 
  my $target_key = $self->get_target_key();
  my $node_key = $self->get_node_key();

  foreach ($self->siblings()) {
    if ($_->{$target_key}[0] eq $name) {
      $found = 1;
      last;
    } 
    $index ++;
  }

  my $new_index = 0;

  if ($direction eq 'up') {
    $new_index = $index - 1;
  } elsif ($direction eq 'down') {
    $new_index = 
      ($index == $#{$pnode->{$node_key}}) 
	? 0 
	: $index + 1
    ;
  }

  my $cloned_node = dclone($pnode->{$node_key}[$new_index]); 

  $pnode->{$node_key}[$new_index] = $pnode->{$node_key}[$index];
  $pnode->{$node_key}[$index] = $cloned_node; 
}

sub copy_node {
  my ($self, $name) = @_;

  return dclone($self->find_node($name)); 
}

sub paste_node {
  my ($self, $want, $paste_node) = @_;
  my $target_node = $self->find_node($want) || $self->get_rnode();

  my $node_key = $self->get_node_key();
  push (@{$target_node->{$node_key}}, $paste_node);
}

sub traverse {
  my ($self, $level) = @_;
  # depth-first pre order traversal

  $level ||= 0;
  my $i = 0;
  my $cnode = $self->get_cnode();
  my $node_key = $self->get_node_key();

  return undef unless(exists ($cnode->{$node_key}));

  foreach ($self->children()) {
    $self->_set_cnode($_);
    $self->_set_pnode($cnode);
    $self->_set_pos($i++);

    $self->_set_level($level);
    $self->do_node();

    if ($self->is_leaf()) {
      # if last child or outmost level
      $self->do_leaf();
      next;
    }

    $self->traverse($level + 1);
  }
}

sub post_traversal {
  my ($self, $level) = @_;
  # depth-first post order traversal

  $level ||= 0;
  my $i = 0;
  my $cnode = $self->get_cnode();
  my $node_key = $self->get_node_key();

  return undef unless(exists ($cnode->{$node_key}));

  foreach ($self->children()) {
    $self->_set_level($level);
    $i++;
    $self->_set_cnode($_);
    $self->post_traversal($self->get_level() + 1);
    $self->_set_cnode($_);
    $self->_set_pnode($cnode);
    $self->_set_pos($i - 1);
    $self->do_node();

    if ($self->is_leaf()) {
      # if last child or outmost level
      $self->do_leaf();
    }
    $self->_set_level($self->get_level() - 1);
  }
}

sub set_do_node {
  my ($self, $do_node) = @_;

  $self->{do_node} = $do_node;

  {
    local $^W = 0;
    no strict;
    *{ ref($self) . '::' . 'do_node' } = $self->{do_node};
  };
}

sub set_do_leaf {
  my ($self, $do_leaf) = @_;

  $self->{do_leaf} = $do_leaf;
  {
    local $^W = 0;
    no strict;
    *{ ref($self) . '::' . 'do_leaf' } = $self->{do_leaf};
  };
}

sub is_leaf {
  my $self = shift;

  my $cnode = $self->get_cnode();
  my $node_key = $self->get_node_key();

  return +( ! exists($cnode->{$node_key}) ) ? 1 : 0
}

## wrapper function for XMLout.
sub toXML {
  my $self = shift;

  my $rnode = $self->get_rnode();
  my $target_key = $self->get_target_key(); 

  my $xml;

  if (ref($_[0]) eq 'HASH') {
    if (exists($_[0]->{$target_key})) {
      $xml = XMLout(@_);
    }
  } else {
    $xml = XMLout($rnode, @_);
  }

  return $xml;  
}

1;

__END__

=head1 NAME

XML::Simple::Tree - Tree object extension for XML::Simple data structures

=head1 SYNOPSIS

  ## script 1 
  ## create XML::Simple::Tree object and do a preorder traversal

  ## create XML::Simple::Tree object from an xml document ($xml_file) 
  my $xml_obj = XML::Simple::Tree->new(file => 'directory.xml',
				       node_key => 'dir',
				       target_key => 'name');

  ## sub set_do_node() method takes subroutine reference to be executed at current node
  $xml_obj->set_do_node(
    sub {
      my $self = $xml_obj;

      my $cnode = $self->get_cnode();
      my $level = $self->get_level();
      my $padding = '* ' x ($level + 1); 

      print "$padding$cnode->{name}[0]\n";
    }
  );

  ## sub set_do_leaf() method takes subroutine reference to be executed at leaf node
  $xml_obj->set_do_leaf(
      sub {
	my $self = $xml_obj;

	print "\n";
      }
    );

  ## Tree pre order traversal method that executes do_node() at each node and do_leaf() at each leaf
  $xml_obj->traverse();


  ## script 2
  ## find a node and retrieve a parameter.

  my $xml_obj = 
    XML::Simple::Tree->new( 
      file => $xml_file,
      node_key => 'directory',
      target_key => 'name'
    );

  my $want_node = $xmlObj->find_node($target_directory);
  my $mtime = $want_node->{mtime}[0];

  ## script 3 
  ## find a node and cut (remove) it from tree.

  my $cut_name = 'bin'; 

  my $mainXml =
    XML::Simple::Tree->new( file => $xml_file,
                            node_key => 'directory',
                            target_key => 'name');

  $mainXml->cut_node($cut_name);

  ## script 4 
  ## take XML::Simple::Tree object and paste it into a target node of another
  ## convert it back to xml

  my $target_dir = 'xxx';

  my $cut_tree = 
     XML::Simple::Tree->new(file => $cut_xml_file,
                            node_key => 'directory',
                            target_key => 'name');

  $config_tree->paste_node($target_dir, $cut_tree->get_cnode()->{directory}[0]);

  ## convert to xml
  my $xml = $config_tree->toXML();

  ## Additional examples can be found in the included tests.

=head1 DESCRIPTION

This module extends XML::Simple by taking the data structure returned by XML::Simple::XMLin($xml_file, forcearray => 1)  
and putting it in a class complete with tree manipulation and traversal methods.  Important to know is that XMLin is called with the option ForceArray => 1.  This option forces nested elements to be represented as arrays even when there is only one.

=head1 METHODS

=head2 new([file=>$xml_file | string => $xml_string], node_key=>$node_key, target_key=>$target_key);
constructor returns an object of type XML::Simple::Tree with one of its data members being a reference to a XML::Simple datastructure.

required parameters

=head2 Either 'file' or 'string' must be supplied with 'file' taking precedence if both are provided.

=over

=item * file - xml document filename

=item * string - xml document in string form

=item * node_key - xml element name which defines a node.

=item * target_key - name of xml element used as identifier field in find() operations.  

=back

=head2 find_node($name)

finds and returns node where $name matches 'target_node'

=head2 children( )

returns list of child node[s] of current node. Current node is defined in paramater 'cnode'

=head2 siblings( )

returns list of sibling nodes relative to current node ('cnode').  List includes current node.  Once again current node is stored in 'cnode'.  Simply iterates through children of 'pnode', parent node of cnode.!

=head2 cut_node($name)

finds and splices away specified node

=head2 move_node($name, $direction)

finds node specified by $name and swaps adjacent node (up -> -1, down -> +1)
useful for reordering children

=head2 copy_node($name)

finds copies( dclone() ) and returns wanted node

=head2 paste_node($destination, $paste_node)

finds destination node and pastes (push()) paste_node in place

=head2 traverse( )

pre-order traversal which
walks tree executing do_node() and do_leaf where appropriate

=head2 post_traversal( )

post-order traversal which
walks tree executing do_node() and do_leaf where appropriate

=head2 set_do_node($sub_ref)

sets subroutine reference executed at each node

=head2 set_do_leaf($sub_ref)

sets subroutine reference executed at each leaf

=head2 is_leaf( )

returns true if current node has no children, and false otherwise.

=head2 toXML([$node_ref])

Returns XML representation of object instance tree.  By default it returns XML for the root node (rnode).  The default behavior can be overridden by supplying another node reference as an argument.  This method is implemented as a wrapper method for XML::Simple::XMLout(), so any options for that subroutine should carry over.  See XML::Simple documentation for more information.

=head1 Autoloaded accessors/mutators via Class::MethodMaker

=head2 Private methods

=over

=item * _set_pnode($node_ref)

sets parent node field

=item * _set_wnode($node_ref)

sets wanted node field

=item * _set_cnode($node_ref)

sets current node field

=item * _set_level($level)

sets current level field

=item * _set_pos($pos)

sets position of node in pnode 

=back

=head2 Public methods

=over

=item * get_cnode( )

gets current node field

=item * get_target_key

gets target_key field

=item * get_node_key( )

gets node_key field

=item * get_pnode( )

gets parent node field

=item * get_rnode( )

gets root node field

=item * get_level( )

returns level field

=item * get_pos( )

returns node position in pnode 

=item * get_file( )

returns xml filename.  Field 'file' is set only if passed to new as new(file => $xmlfile)

=item * get_string( )

returns xml in string form.  Field 'string' is set only if passed to new as new(string => $xmlstr)

=back

=head1 AUTHOR

Aaron Dancygier, E<lt>aaron@dancygier.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Aaron Dancygier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

