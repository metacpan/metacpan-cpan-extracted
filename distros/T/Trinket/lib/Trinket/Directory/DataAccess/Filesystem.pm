###########################################################################
### Trinket::Directory::DataAccess::Filesystem
###
### Access to directory of persistent objects.
###
### $Id: Filesystem.pm,v 1.2 2001/02/16 07:25:45 deus_x Exp $
###
### TODO:
### -- Callbacks for Object to accomdate on-demand property get/set
### -- Do something meaningful in close()
### -- Cooperate with ACLs
### -- Implement a cursor for access to search results
### -- Implement support for data types (char is only type for now)
### -- Should DESTROY() do something? (per warning)
### -- How do we handle the left over undefined storage slots left by
###      deleted objects?  (Compact the database?  Renumber everything
###      and all references to those numbers?  Use a hash instead?)
### -- Prevent serialization of any properties of type 'ref'?
### -- Minimize search leaf subs even further?
###
###########################################################################

package Trinket::Directory::DataAccess::Filesystem;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::DataAccess::Filesystem -

=head1 DESCRIPTION

TODO

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Trinket::Directory::DataAccess );
    $DESCRIPTION  = 'Filesystem-based object directory';
  }

# }}}

use Trinket::Directory::DataAccess;

use Trinket::Object;
use Trinket::Directory::FilterParser;
use Bit::Vector::Overload;
use Storable qw( thaw freeze );
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp qw( croak cluck );
use File::Path qw( mkpath rmtree );
use IO::File;
use Fcntl ':flock';

Bit::Vector->Configuration("out=bin");

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ init(): Object initializer

=item init({...})

TODO

=cut

sub init
  {
    no strict 'refs';
    my ($self, $props) = @_;

    $self->{db_home}    = $props->{db_home}    || '.';

    return 1;
  }

# }}}

# {{{ create()

=item $dir->create($params)

Create a new object directory, destroys any existing directory
associated with the given parameters.

=cut

sub create
  {
    my ($self, $name, $params) = @_;

    $self->{db_home}    = $params->{db_home}    || '.';

    my $dir_name = $self->{dir_name} = $name;
    my $dir_path = $self->{dir_path} = $self->{db_home}.'/'.$name;
    $self->{id_counter} = $self->{dir_path}.'/id-count';

    ### Create a new directory home, deleting the original if necessary
    rmtree([$dir_path], 0, 1) if -d $dir_path;
    mkpath([$dir_path], 0, 0755);

    my $id = $self->get_new_id();

    return 1;
  }

# }}}
# {{{ open()

=item $dir->open($params)

TODO

=cut

sub open
  {
    my ($self, $name, $params) = @_;

    $self->{db_home}    = $params->{db_home}    || '.';
    my $dir_name = $self->{dir_name} = $name;
    my $dir_path = $self->{dir_path} = $self->{db_home}.'/'.$name;
    $self->{id_counter} = $self->{dir_path}.'/id-count';

    return undef if (! -d $self->{dir_path});
    return undef if (! -f $self->{id_counter});

    return 1;
  }

# }}}
# {{{ close()

=item $dir->close($params)

TODO

=cut

sub close
  {
    my ($self, $params) = @_;


    return 1;
  }

# }}}

# {{{ store_object():

sub store_object
  {
    my ($self, $obj) = @_;

    my ($serialized, $dirty, $dirty_name, $dirty_vals, $dirty_old,
        $dirty_new, $id, $dir);

    ### Get the object's id
    $id  = $obj->get_id();

    ### Check if this is an attempt to store an object with the id of
    ### an object which has been previously deleted.  If so, undefine
    ### the object's id and proceed.
    if ( (defined $id) && ( $self->is_deleted_id($id) ) )
      { $obj->set_id($id = undef); }

    ### Does this object have an id?  If not, give it one.
    if (!defined $id)
      { $obj->set_id($id = $self->get_new_id()); }

    eval
      {
        ### HACK:  We don't want to serialize the directory.  Actually,
        ### there are a lot of things we don't want to serialize.  Will
        ### have to find a way to handle this cleanly
        $obj->set_directory(undef);

        ### Serialize and store the object
        my $obj_freeze = freeze($obj);

        my $obj_fh = _lock_open('>'.$self->{dir_path}."/$id"); binmode $obj_fh;
        print $obj_fh $obj_freeze;
        _lock_close($obj_fh);

        ### Update dirty indexes...
#         if ($dirty = $obj->_find_dirty_indices())
#           {
#             while (($dirty_name, $dirty_vals) = each %{$dirty})
#               {
#                 ($dirty_old, $dirty_new) =
#                   ($dirty_vals->[DIRTY_OLD_VALUE],
#                    $dirty_vals->[DIRTY_NEW_VALUE]);

#                 if ($dirty_old)
#                   { $self->delete_from_index($id, $dirty_name, $dirty_old); }
#                 $self->store_in_index($id, $dirty_name, $dirty_new);
#               }
#           }
      };

    ### Storage failure.  Recover, fire a warning, and return
    ### empty-handed.  (croaking now, should cluck.)
    if ($@)
      { croak ($@); return undef; }

    return $id;
  }

# }}}
# {{{ retrieve_object():

sub retrieve_object
  {
    my ($self, $id) = @_;

     my ($obj, $serialized);
     eval
       {
         return undef if (! -f $self->{dir_path}."/$id");
         ### Serialize and store the object
         my $obj_fh = _lock_open($self->{dir_path}."/$id") || return undef;
         binmode $obj_fh; local $/; undef $/;
         $serialized = <$obj_fh>;
         _lock_close($obj_fh);

         return undef if (! (defined $serialized));
         $obj = thaw($serialized) || die "No object ".$self->{dir_path}."/$id $serialized";

       };
     if ($@) { croak ($@); return undef; }

     return $obj;
  }

# }}}
# {{{ delete_object

sub delete_object
  {
    my ($self, $id, $obj) = @_;

    unlink $self->{dir_path}."/$id";

#    $self->{directory}->{objects}->[$id] = undef;

    ### Delete all indexes for this object's properties
#    my $name;
#    foreach $name ($obj->list_properties())
#      { $self->delete_from_index($id, $name); }

    return 1;
  }

# }}}
# {{{ search_objects

### Define a mapping of search filter LoL node names to methods
my %op_methods =
	(
 	 'AND'    => '_search_join_op',
 	 'OR'     => '_search_join_op',
 	 'NOT'    => '_search_join_op',
 	 'EQ'     => '_search_leaf_op',
 	 'APPROX' => '_search_leaf_op',
 	 'GT'     => '_search_leaf_op',
 	 'GE'     => '_search_leaf_op',
 	 'LT'     => '_search_leaf_op',
 	 'LE'     => '_search_leaf_op',
	);

sub search_objects
  {
    my ($self, $parsed) = @_;

#     my ($op, $operand) = ($parsed->[SEARCH_OP], $parsed->[SEARCH_OPERAND]);

#     my $op_method = $op_methods{$op} || die "No '$op' method!";

#     cluck('Bad filter') if ( (!defined $op) || (!defined $operand) );

#     my ($result) = $self->$op_method($op, $operand);

#     return $result->Index_List_Read();
    return undef;
  }

# }}}

# {{{ _search_join_op

my %_search_join_subs =
  (
   AND => sub
   {
     my ($result_vec, $a_vec, $sub_results) = @_;
     while(my $b_vec = shift @$sub_results)
       {
         $a_vec->Intersection($result_vec, $b_vec);
         $result_vec = $a_vec;
       }
     return $result_vec;
   },
   OR  => sub
   {
     my ($result_vec, $a_vec, $sub_results) = @_;
     while(my $b_vec = shift @$sub_results)
       {
         $a_vec->Union($result_vec, $b_vec);
         $result_vec = $a_vec;
       }
     return $result_vec;
   },
   NOT => sub
   {
     my ($result_vec, $a_vec, $sub_results) = @_;
     $a_vec->Complement($result_vec);
     $result_vec = $a_vec;
     return $result_vec;
   },
  );

sub _search_join_op
  {
    my ($self, $op, $operand) = @_;

    my $result;
    my ($i, $sub_op, $sub_operand, $sub_op_method, $sub_result);
    my @sub_results = ();

    my $id_range = $self->get_id_range();

    for (my $i=0; $i<@$operand; $i+=2)
      {
        ($sub_op, $sub_operand) =
          ($operand->[SEARCH_OP + $i], $operand->[SEARCH_OPERAND + $i]);

        $sub_op_method = $op_methods{$sub_op} ||
          die "No '$sub_op' method!";
        $sub_result = $self->$sub_op_method($sub_op, $sub_operand);

        push @sub_results, $sub_result;
      }

    my ($result_vec, $a_vec, $b_vec);
    $a_vec = new Bit::Vector($id_range);
    $result_vec = shift @sub_results;

    $result_vec = $_search_join_subs{$op}->
      ($result_vec, $a_vec, \@sub_results);

    return $result_vec;
  }

# }}}
# {{{ _search_leaf_op

my %_search_leaf_subs =
  (
 	 'EQ'     => sub
   {
     my ($index, $val) = @_;
     my @ids;

     ### Get all ids whose value is equal to the given value.
     if ($val eq '*')
       {
         foreach my $k1 (keys %{$index})
           { push @ids, keys %{$index->{$k1}}; }
       }
     else
       { @ids = keys %{$index->{$val}}; }

     return \@ids;
   },
 	 'APPROX' => sub
   {
     my ($index, $val) = @_;
     my @ids;

     return \@ids;
   },
 	 'GT'     => sub
   {
     my ($index, $val) = @_;
     my @ids;
     foreach my $k (keys %$index)
       { push @ids, keys %{$index->{$k}} if ($val < $k); }
     return \@ids;
   },
 	 'GE'     => sub
   {
     my ($index, $val) = @_;
     my @ids;
     foreach my $k (keys %$index)
       { push @ids, keys %{$index->{$k}} if ($val <= $k); }
     return \@ids;
   },
 	 'LT'     => sub
   {
     my ($index, $val) = @_;
     my @ids;
     foreach my $k (keys %$index)
       { push @ids, keys %{$index->{$k}} if ($val > $k); }
     return \@ids;
   },
 	 'LE'     => sub
   {
     my ($index, $val) = @_;
     my @ids;
     foreach my $k (keys %$index)
       { push @ids, keys %{$index->{$k}} if ($val >= $k); }
     return \@ids;
   },
  );

sub _search_leaf_op
  {
    my ($self, $op, $operand) = @_;

    my $result;

    ### Assert that this is an operation taking two string nodes
    if ( ($operand->[0] ne "STRING") || ($operand->[2] ne "STRING") )
      {
        cluck("Bad or unimplemented filter format");
        return undef;
      }

    my ($name, $val) = ($operand->[1], $operand->[3]);

    my $id_range = $self->get_id_range();
    my $result = new Bit::Vector($id_range);

    ### Grab a reference to the named index.
    my $index = $self->{directory}->{indices}->{$name};

    my $ids = $_search_leaf_subs{$op}->($index, $val);

    $result->Index_List_Store(@$ids);

    return $result;
  }

# }}}

# {{{ is_ready():

sub is_ready
  {
    my $self = shift;

    return undef if (! -d $self->{dir_path});
    return undef if (! -f $self->{id_counter});

    return 1;
  }

# }}}

# {{{ get_new_id():

sub get_new_id
  {
    my $self = shift;

    my $id = 0;
    my $fh;

    ### If the counter exists, get the value
    if (-f $self->{id_counter})
      {
        $fh = _lock_open('+<'.$self->{id_counter});
        $id = <$fh>; chomp $id;
        $fh->seek(0,0);
      }
    ### Otherwise, create the file.
    else
      { $fh = _lock_open('>'.$self->{id_counter}); }

    ### Store the incremented id value in the file.
    print $fh ($id+1)."\n";
    _lock_close($fh);

    return $id;
  }

# }}}
# {{{ is_deleted_id():

sub is_deleted_id
  {
    my ($self, $id) = @_;

    my $id = 0;
    my $fh;

    $fh = _lock_open('+<'.$self->{id_counter});
    $id = <$fh>; chomp $id;
    _lock_close($fh);

    return ( (defined $id) && (! -f $self->{dir_path}."/$id") );
  }

# }}}
# {{{ get_id_range()

sub get_id_range
  {
    my $self = shift;

    my $id = 0;
    my $fh;

    $fh = _lock_open('+<'.$self->{id_counter});
    $id = <$fh>; chomp $id;
    _lock_close($fh);

    return ($id-1);
  }

# }}}

# {{{ index_exists()

sub index_exists
  {
    my ($self, $name) = @_;

    return ( defined ( $self->{directory}->{indices}->{$name} ) );
  }

# }}}
# {{{ create_index()

sub create_index
  {
    my ($self, $name) = @_;

    $self->{directory}->{indices}->{$name} = {};

    return 1;
  }

# }}}
# {{{ delete_from_index()

sub delete_from_index
  {
    my ($self, $id, $name, $value) = @_;

    return undef if (!$self->index_exists($name));

    my $name_index = $self->{directory}->{indices}->{$name};

    if (defined $value)
      {
        delete $name_index->{$value}->{$id};
        delete $name_index->{$value}
          if (! keys(%{$name_index->{$value}}) );
      }
    else
      {
        foreach $value ( keys %{$name_index} )
          {
            delete $name_index->{$value}->{$id}
              if ($name_index->{$value}->{$id});
#            if (! keys(%{$name_index->{$value}}) )
#              {
#                delete $name_index->{$value};
#                last;
#              }
          }
      }
  }

# }}}
# {{{ store_in_index()

sub store_in_index
  {
    my ($self, $id, $name, $value) = @_;

    $self->create_index($name)
      if (!$self->index_exists($name));

    $self->{directory}->{indices}->{$name}->{$value}->{$id} = 1;
  }

# }}}

# {{{ _lock_open

sub _lock_open
  {
    my $fn = shift;

    my $fh = new IO::File($fn) || return undef;
    flock($fh, LOCK_EX);

    return $fh;
  }

# }}}
# {{{ _lock_close

sub _lock_close
  {
    my $fh = shift;

    $fh->close();
    flock($fh, LOCK_UN);
  }

# }}}

# {{{ DESTROY

sub DESTROY
  {
    ## no-op to pacify warnings
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__
