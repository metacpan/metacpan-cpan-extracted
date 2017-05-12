
package Tree::Simple::Manager;

use strict;
use warnings;

use Scalar::Util qw(blessed);

our $VERSION = '0.07';

use Tree::Simple::Manager::Index;
use Tree::Simple::Manager::Exceptions;

use Tree::Parser;

use Tree::Simple;
use Tree::Simple::View::DHTML;

use File::stat;

use Storable ();
    
sub new {
    my ($_class, @tree_configs) = @_;
    (@tree_configs && scalar(@tree_configs) >= 2) 
        || throw Tree::Simple::Manager::InsufficientArguments "You must supply at least one tree valid config";
    my $class = ref($_class) || $_class;
    my $tree_manager = {};
    bless($tree_manager, $class);
    $tree_manager->_init(\@tree_configs);
    return $tree_manager;
}

sub _init {
    my ($self, $tree_configs) = @_;
    $self->{trees} = {};
    while (@{$tree_configs}) {
        my ($tree_name, $config) = splice @{$tree_configs}, 0, 2;
        
        (exists $config->{tree_root})
            || throw Tree::Simple::Manager::InsufficientArguments "missing the required keys for '$tree_name' config";
        
        (!exists $self->{trees}->{$tree_name})
            || throw Tree::Simple::Manager::DuplicateName "The tree '$tree_name' already exists";

        $self->{trees}->{$tree_name} = {};
    
        my $root_tree = $config->{tree_root};
        (blessed($root_tree) && $root_tree->isa('Tree::Simple'))
            || throw Tree::Simple::Manager::IncorrectObjectType "The 'root_tree' must be a Tree::Simple instance (or a subclass of it)";    

        # load from the file or something
        my $tree = $self->_loadTree($tree_name => $config);    
        
        # by default we use our Index module
        
        my $tree_index_module;
        if (exists $config->{tree_index}) {
            ($config->{tree_index}->isa('Tree::Simple::Manager::Index')) 
                || throw Tree::Simple::Manager::IncorrectObjectType "the 'tree_index' must be a subclass of Tree::Simple::Manager::Index";
            $tree_index_module = $config->{tree_index};
        }
        else {
            $tree_index_module = "Tree::Simple::Manager::Index";
        }
        
        $self->{trees}->{$tree_name}->{index} = $tree_index_module->new($tree);
        
        if (exists $config->{tree_meta_data}) {
            (ref $config->{tree_meta_data} eq 'HASH')
                || throw Tree::Simple::Manager::IncorrectObjectType "the 'tree_meta_data' option must be a HASH";        
            foreach my $tree_id (keys %{$config->{tree_meta_data}}) {                
                my $tree = $self->{trees}->{$tree_name}->{index}->getTreeByID($tree_id);
                ($tree->isa('Tree::Simple::WithMetaData'))
                    || throw Tree::Simple::Manager::IncorrectObjectType "the 'tree_meta_data' node for ($tree_name) id($tree_id) must be a Tree::Simple::WithMetaData instance";                    
                $tree->addMetaData(%{$config->{tree_meta_data}->{$tree_id}});
            }
        }
        
        my $tree_view;
        if (exists $config->{tree_view}) {
            ($config->{tree_view}->isa('Tree::Simple::View')) 
                || throw Tree::Simple::Manager::IncorrectObjectType "the 'tree_view' must be a subclass of Tree::Simple::View";        
            $tree_view = $config->{tree_view};
        }
        else {
            $tree_view = "Tree::Simple::View::DHTML" 
        }
            
        $self->{trees}->{$tree_name}->{view} = $tree_view;
    }
}

sub _loadTree {
    my ($self, $tree_name, $config) = @_;

    (exists $config->{tree_file_path})
        || throw Tree::Simple::Manager::InsufficientArguments "missing the required keys for '$tree_name' config";

    if (exists $config->{tree_cache_path}) {
        my $cache_stat = stat $config->{tree_cache_path};
        my $file_stat = stat $config->{tree_file_path};

        if ( $file_stat and $cache_stat and $cache_stat->mtime >= $file_stat->mtime ) {
            my $tree;
            eval {
                $tree = Storable::retrieve($config->{tree_cache_path});
            };
            if ($@) {
                warn "Unable to load tree cache, removing cache tree";
                unlink $config->{tree_cache_path};
                warn "Attempting to load tree with parser";
            }    
            else {
                $self->{trees_loaded_from_cache}->{$tree_name}++;
                return $tree;        
            }
        }
    }

    my $tree;
    eval {
        my $tp = Tree::Parser->new($config->{tree_root});
        
        $tp->setFileEncoding($config->{tree_file_encoding}) 
            if exists $config->{tree_file_encoding};
            
        $tp->setInput($config->{tree_file_path});
        
        if (exists $config->{tree_parse_filter}) {
            (ref($config->{tree_parse_filter}) eq 'CODE')
                || throw Tree::Simple::Manager::IncorrectObjectType "a 'tree_parse_filter' must be a code ref";
            $tp->setParseFilter(
                $self->_parseFilterWrapper(
                    ref($config->{tree_root}), 
                    $config->{tree_parse_filter}
                )
            );
        }
        else {
            $tp->setParseFilter(
                $self->_getDefaultParseFilter(
                    ref($config->{tree_root})
                )
            );
        }
        $tp->parse();
        $tree = $tp->getTree();
    };

    if ($@) {
        throw Tree::Simple::Manager::OperationFailed "unable to parse tree file '" . $config->{tree_file_path}. "'" => $@;
    }    
    
    if (exists $config->{tree_cache_path}) {
        eval {
            Storable::store($tree, $config->{tree_cache_path});
        };
        if ($@) {
            warn "Unable to store tree cache ... sorry";
        }    
    }    
    
    return $tree;
}

sub _parseFilterWrapper {
    my ($self, $tree_type, $filter) = @_;
    return sub {
        my $i = shift;
        my ($depth, $tree) = $filter->($i, $tree_type);
        (blessed($tree) && $tree->isa('Tree::Simple'))
            || throw Tree::Simple::Manager::IncorrectObjectType "Custom Parse filters must return Tree::Simple objects";
        return ($depth, $tree);
    };
}

sub _getDefaultParseFilter {
    my (undef, $tree_type) = @_;
    return sub {
        my ($line_iterator) = @_;
        my $line = $line_iterator->next();
        my ($id, $tabs, $node) = ($line =~ /(\d+)\t(\t+)?(.*)/);
        my $depth = 0;
        $depth = length $tabs if $tabs;
        my $tree = $tree_type->new($node);
        $tree->setUID($id);
        return ($depth, $tree);        
    };
}

sub getTreeList {
    my ($self) = @_;
    return wantarray ? keys %{$self->{trees}} : [ keys %{$self->{trees}} ];                
}

sub getRootTree {
    my ($self, $tree_name) = @_;
    (defined($tree_name)) 
        || throw Tree::Simple::Manager::InsufficientArguments "Tree name not specified";
    (exists $self->{trees}->{$tree_name}) 
        || throw Tree::Simple::Manager::KeyDoesNotExist "tree ($tree_name) does not exist"; 
    return $self->{trees}->{$tree_name}->{index}->getRootTree();             
}

sub getTreeIndex {
    my ($self, $tree_name) = @_;
    (defined($tree_name)) 
        || throw Tree::Simple::Manager::InsufficientArguments "Tree name not specified";
    (exists $self->{trees}->{$tree_name}) 
        || throw Tree::Simple::Manager::KeyDoesNotExist "tree ($tree_name) does not exist";
    return $self->{trees}->{$tree_name}->{index};             
}

sub getTreeByID {
    my ($self, $tree_name, $tree_id) = @_;
    return $self->getTreeIndex($tree_name)->getTreeByID($tree_id);
}

sub getTreeViewClass {
    my ($self, $tree_name) = @_;
    (defined($tree_name)) 
        || throw Tree::Simple::Manager::InsufficientArguments "Tree name not specified";
    (exists $self->{trees}->{$tree_name}) 
        || throw Tree::Simple::Manager::KeyDoesNotExist "tree ($tree_name) does not exist";
    return $self->{trees}->{$tree_name}->{view}; 
}

sub getNewTreeView {
    my ($self, $tree_name, @view_args) = @_;
    my $tree_view_class = $self->getTreeViewClass($tree_name);
    return $tree_view_class->new($self->getRootTree($tree_name), @view_args);
}

sub isTreeLoadedFromCache {
    my ($self, $tree_name) = @_;
    exists $self->{trees_loaded_from_cache}->{$tree_name} && 
           $self->{trees_loaded_from_cache}->{$tree_name};
}

1;

__END__

=pod

=head1 NAME

Tree::Simple::Manager - A class for managing multiple Tree::Simple hierarchies

=head1 SYNOPSIS

  use Tree::Simple::Manager;
  
  # use the default index and default views
  my $tree_manager = Tree::Simple::Manager->new(
        "Organizational Level" => {
            tree_file_path => "data/organization_level.tree",        
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
        }
  );    

  # specify your own index class and your own view class
  my $tree_manager = Tree::Simple::Manager->new(
        "Organizational Level" => {
            tree_file_path => "data/organization_level.tree",        
            tree_root      => Tree::Simple->new(Tree::Simple->ROOT),
            tree_index     => "My::Tree::Indexing::Class",
            tree_view      => "My::Tree::Simple::View::Class",            
        }
  );   

=head1 DESCRIPTION

This is a class for managing multiple Tree::Simple hierarchies at a 
time. It integrates several Tree::Simple classes together to attempt 
to make things easier to manage. This is the third release of this 
module. It is currently tailored to my current needs, and will likely 
get more flexible later on. If you want to use it, and need it to 
work differently, let me know and I can try to help, or you can 
submit a patch.

The basic idea of this module is that you can load and store 
Tree::Simple hierarchies by name. You use L<Tree::Parser> to load 
the hierarchy from disk, the tree is then indexed for fast node 
retrieval by L<Tree::Simple::Manager::Index>. If you need a 
L<Tree::Simple::View> of the tree, you can create one with this 
class, or get the L<Tree::Simple::View> subclass which is 
associated with this tree.

=head1 METHODS

=over 4

=item B<new (%tree_configs)>

This will load all the tree heirachies from disk, index them. 
The config format is show above in L<SYNOPSIS>, and described 
in detail below: 

B<Required Fields>

=over 4

=item I<tree_root> 

This must be a Tree::Simple object (or a subclass of Tree::Simple) 
it will serve as the root of this particular tree. 

=item I<tree_file_path> 

This must be a valid path to a tree file which L<Tree::Parser> 
will understand.

=back

B<Optional Fields>

=over 4

=item I<tree_index>

This must be a package name for a L<Tree::Simple::Manager::Index> 
subclass. The default is L<Tree::Simple::Manager::Index>.

=item I<tree_view>

This must be a package name for a L<Tree::Simple::View> subclass. 
The default is L<Tree::Simple::View::DHTML>.

=item I<tree_parse_filter>

This must be a subroutine reference which is compatible 
with L<Tree::Parser>'s parse filters. It's first argument 
is an L<Array::Iterator> object which has all the lines in the 
tree file. It's second argument is the tree class name as 
specified in the C<tree_root> field. Here is an example 
custom parse filter:

  # this will parse tree files formated like this:
  # uid:node
  #     uid:node
  #	        uid:node
  #     uid:node
  tree_parse_filter => sub {
      my ($line_iterator, $tree_type) = @_;
      my $line = $line_iterator->next();
      my ($tabs, $id, $node) = ($line =~ /(\t+)?(\d+)\:(.*)/);
      my $depth = 0;
      $depth = length $tabs if $tabs;
      my $tree = $tree_type->new($node);
      $tree->setUID($id);
      return ($depth, $tree);                  
  }
        
The default parse filter will parse tree files which look like this:

  uid    node
  uid        node
  uid            node
  uid        node

Where the UID is first, followed by a tab, then either the node value 
or more tabs to indicate the tree depth.

=item I<tree_cache_path>

This must be a valid file path, and can be used to cache a parsed 
tree. It serializes the tree using Storable and then if a valid cache 
file is present, it will us that instead of re-parsing. This can 
potentially save a B<lot> of time during startup for large trees.

=item I<tree_meta_data>

This is a HASH ref whose keys are tree ids (fetchable through 
Tree::Simple::Manager::Index) and then accompanying metadata (which 
can pretty much be anything actually). 

=item I<tree_file_encoding>

This will pass on the encoding type to be used when reading in the 
file with Tree::Parser.

=back

=item B<getTreeList>

This will return a list of names of the tree hierarchies currently 
being managed.

=item B<getRootTree ($tree_name)>

This will return the root of the tree found at C<$tree_name>.

=item B<getTreeIndex ($tree_name)>

This will return the Tree::Simple::Manager::Index object found 
at C<$tree_name>.

=item B<getTreeByID ($tree_name, $tree_id)>

This will ask the tree index (found at C<$tree_name>) for the 
tree whose id is C<$tree_id>.

=item B<getTreeViewClass ($tree_name)>

This will return the Tree::Simple::View class associated with 
C<$tree_name>.

=item B<getNewTreeView ($tree_name, @view_args)>

This will return an instance of the Tree::Simple::View class 
associated with C<$tree_name>, passing in the C<@view_args> 
to the view constructor.

=item B<isTreeLoadedFromCache ($tree_name)>

This will return true if the tree has been loaded from cache with 
the tree_cache_path option.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, 
and I will be sure to fix it. 

=head1 SEE ALSO

=over 4

=item L<Tree::Parser>

=item L<Tree::Simple>

=item L<Tree::Simple::WithMetaData>

=item L<Tree::Simple::View::DHTML>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

