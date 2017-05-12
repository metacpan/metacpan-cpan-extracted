###########################################################################
### Trinket::Directory::DataAccess::BerkeleyDB
###
### Access to directory of persistent objects.
###
### $Id: BerkeleyDB.pm,v 1.2 2001/02/16 07:25:18 deus_x Exp $
###
### TODO:
### -- Callbacks for Object to accomdate on-demand property get/set
### -- Do something meaningful in close()
### -- Save contents of BerkeleyDB directories?  implement in open()/close()?
### -- Cooperate with ACLs
### -- Implement a cursor for access to search results
### -- Implement support for data types (char is only type for now)
### -- Should DESTROY() do something? (per warning)
### -- How do we handle the left over undefined storage slots left by
###      deleted objects?  (Compact the database?  Renumber everything
###      and all references to those numbers?  Use a hash instead?)
### -- Prevent serialization of any properties of type 'ref'?
### -- Minimize search leaf subs even further?
### -- Problem with deletions renumbering the record numbers, using
###      'DELETED' now.  Need to fix that.
###
###########################################################################

package Trinket::Directory::DataAccess::BerkeleyDB;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::DataAccess::BerkeleyDB -

=head1 DESCRIPTION

TODO

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Trinket::Directory::DataAccess );
    $DESCRIPTION  = 'Base object directory';
  }

# }}}

use Trinket::Directory::DataAccess;

use Trinket::Object;
use Trinket::Directory;
use Trinket::Directory::FilterParser;
use Bit::Vector::Overload;
use Storable qw( thaw freeze );
use Carp qw( croak cluck );
use File::Path qw( mkpath rmtree );
use BerkeleyDB;

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

    $self->{directory}    = undef;
    $self->{db_home}      = $props->{db_home} || '.';
    $self->{object_store} = undef;
    $self->{indices}      = {};

    return
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

    my $dir_name = $self->{dir_name} = $name;
    my $home = $self->{db_home}.'/'.$name;

    ### Create a new DB home, deleting the original if necessary
    rmtree([$home], 0, 1) if -d $home;
    mkpath([$home], 0, 0755);

    ### Create a DB environment
    my $env  = $self->{env} = new BerkeleyDB::Env
      (
       -Home       => $home,
       -Flags      => DB_CREATE|DB_INIT_TXN|DB_INIT_MPOOL|
                      DB_INIT_LOCK|DB_INIT_LOG,
       -LockDetect => DB_LOCK_OLDEST
      );
    if (! defined $env )
      {
        warn "Could not create environment at $home: $!";
        return undef;
      }

    ### Attempt to create the object store
    my $objs = $self->{object_store} = new BerkeleyDB::Recno
      (
       -Filename  => 'object-store',
       -Property  => DB_RENUMBER,
       -Env       => $env,
       -Flags     => DB_CREATE,
       -Mode      => 0644
      );
    if (! defined $objs )
      {
        warn "Could not create object store at $home/object-store: $!";
        return undef;
      }

    $self->{is_ready} = 1;

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

    my $dir_name = $self->{dir_name} = $name;
    my $home = $self->{db_home}.'/'.$name;

    ### Fail if the db home doesn't exist.
    return undef if ! -d $home;

    ### Create a DB environment
    my $env  = $self->{env} = new BerkeleyDB::Env
      (
       -Home       => $home,
       -Flags      => DB_INIT_TXN|DB_INIT_MPOOL|
                      DB_INIT_LOCK|DB_INIT_LOG,
       -LockDetect => DB_LOCK_OLDEST
      );
    if (! defined $env )
      {
        warn "Could not create environment at $home: $!";
        return undef;
      }

    ### Attempt to create the object store
    my $objs = $self->{object_store} = new BerkeleyDB::Recno
      (
       -Filename  => 'object-store',
       -Property  => DB_RENUMBER,
       -Env       => $env,
       -Mode      => 0644
      );
    if (! defined $objs )
      {
        warn "Could not create object store at $home/object_store: $!";
        return undef;
      }

    $self->{is_ready} = 1;

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
        $dirty_new, $id, $dir, $value);

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
        $self->{object_store}->db_put($id, freeze($obj));

        ### Update dirty indexes...
        if ($dirty = $obj->_find_dirty_indices())
          {
            while (($dirty_name, $dirty_vals) = each %{$dirty})
              {
                ($dirty_old, $dirty_new) =
                  ($dirty_vals->[DIRTY_OLD_VALUE],
                   $dirty_vals->[DIRTY_NEW_VALUE]);

                if ($dirty_old)
                  { $self->delete_from_index($id, $dirty_name, $dirty_old); }
                $self->store_in_index($id, $dirty_name, $dirty_new);
              }
          }
      };

    ### Storage failure.  Recover, fire a warning, and return
    ### empty-handed.  (croaking now, should cluck.)
#    if ($@)
#      { croak ($@); return undef; }

    return $id;
  }

# }}}
# {{{ retrieve_object():

sub retrieve_object
  {
    my ($self, $id) = @_;

    return undef if (!defined $id);
    return undef if ($self->is_deleted_id($id));

    my ($obj, $serialized);
    $self->{object_store}->db_get($id, $serialized) && return undef;
    eval
      {
        return undef if (! (defined $serialized));
        $obj = thaw($serialized);
      };
    if ($@) { croak ($@); return undef; }

    return $obj;
  }

# }}}
# {{{ delete_object

sub delete_object
  {
    my ($self, $id, $obj) = @_;

    my $status = $self->{object_store}->db_put($id, "DELETED");
    return undef if ($status);
#    $self->{object_store}->db_del($id) || return undef;

    ### Delete all indexes for this object's properties
    my ($name, $value , $prop_method);
    foreach $name ($obj->list_indices())
      {
        $value = $obj->_get($name);
        $self->delete_from_index($id, $name, $value)
          if $value;
      }

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

    my ($op, $operand) = ($parsed->[SEARCH_OP], $parsed->[SEARCH_OPERAND]);

    my $op_method = $op_methods{$op} || die "No '$op' method!";

    cluck('Bad filter') if ( (!defined $op) || (!defined $operand) );

    my ($result) = $self->$op_method($op, $operand);

    return $result->Index_List_Read();
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
     my ($set, $cursor, $key) = @_;
     my ($status, $value, @ids);

     ### Get all ids whose value is equal to the given value.
     if ($key eq '*')
       {
         for ( $status = $cursor->c_get($key, $value, DB_FIRST);
               $status == 0;
               $status = $cursor->c_get($key, $value, DB_NEXT) )
           { $set->Bit_On($value); }
       }
     else
       {
         for ( $status = $cursor->c_get($key, $value, DB_SET);
               $status == 0;
               $status = $cursor->c_get($key, $value, DB_NEXT_DUP) )
           { $set->Bit_On($value); }
       }
   },
 	 'APPROX' => sub
   {
     my ($set, $cursor, $key) = @_;
     my ($status, $value);

   },
 	 'GT'     => sub
   {
     my ($set, $cursor, $key) = @_;
     my ($status, $value);

     $cursor->c_get($key, $value, DB_SET_RANGE);
     for ( $status = $cursor->c_get($key, $value, DB_NEXT);
           $status == 0;
           $status = $cursor->c_get($key, $value, DB_NEXT) )
       { $set->Bit_On($value); }
   },
 	 'GE'     => sub
   {
     my ($set, $cursor, $key) = @_;
     my ($status, $value);

     for ( $status = $cursor->c_get($key, $value, DB_SET_RANGE);
           $status == 0;
           $status = $cursor->c_get($key, $value, DB_NEXT) )
       { $set->Bit_On($value); }
   },
 	 'LT'     => sub
   {
     my ($set, $cursor, $key) = @_;
     my ($status, $value);

     $cursor->c_get($key, $value, DB_SET_RANGE);
     for ( $status = $cursor->c_get($key, $value, DB_PREV);
           $status == 0;
           $status = $cursor->c_get($key, $value, DB_PREV) )
       { $set->Bit_On($value); }
   },
 	 'LE'     => sub
   {
     my ($set, $cursor, $key) = @_;
     my ($status, $value);

     for ( $status = $cursor->c_get($key, $value, DB_SET_RANGE);
           $status == 0;
           $status = $cursor->c_get($key, $value, DB_PREV) )
       { $set->Bit_On($value); }
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
    my $set      = new Bit::Vector($id_range);
    my $index    = $self->get_index($name);
    my $cursor   = $index->db_cursor();

    $_search_leaf_subs{$op}->($set, $cursor, $val);

#    $result->Index_List_Store(@$ids);

    return $set;
  }

# }}}

# {{{ is_ready():

sub is_ready
  {
    my $self = shift;

    return undef if(!defined $self->{env});
    return undef if(!defined $self->{object_store});

    return $self->{is_ready};
  }

# }}}

# {{{ get_new_id():

sub get_new_id
  {
    my $self = shift;

    my $cursor = $self->{object_store}->db_cursor();
    my $value;
    my $last = 0;
    $cursor->c_get($last, $value, DB_LAST);

    return ($last + 1);
  }

# }}}
# {{{ is_deleted_id():

sub is_deleted_id
  {
    my ($self, $id) = @_;

    my $value;
    my $status = $self->{object_store}->db_get($id, $value);

    return ($value eq 'DELETED');
#    return ($status == DB_KEYEMPTY );
  }

# }}}
# {{{ get_id_range()

sub get_id_range
  {
    my $self = shift;

    my $cursor = $self->{object_store}->db_cursor();
    my $value;
    my $last = 0;
    $cursor->c_get($last, $value, DB_LAST);

    return ($last+1);
  }

# }}}

# {{{ get_index()

sub get_index
  {
    my ($self, $name) = @_;

    my $env   = $self->{env};
    my $index = $self->{indices}->{$name};
    if (!defined $index)
      {
        $index = $self->{indices}->{$name} = new BerkeleyDB::Btree
          (
           -Filename  => "index-$name",
           -Env       => $env,
           -Property  => DB_DUP|DB_DUPSORT,
           -Flags     => DB_CREATE,
           -Mode      => 0644
          );
      }

    return $index;
  }

# }}}
# {{{ delete_from_index()

sub delete_from_index
  {
    my ($self, $id, $name, $value) = @_;

    ### FIXFIXFIX - We need to iterate through values?!
    my $index  = $self->get_index($name);
    my $cursor = $index->db_cursor();
    $cursor->c_get($value, $id, DB_GET_BOTH) && return undef;
    $cursor->c_del() && return undef;

    return 1;
  }

# }}}
# {{{ store_in_index()

sub store_in_index
  {
    my ($self, $id, $name, $value) = @_;

    my $index = $self->get_index($name);
    my $status = $index->db_put($value, $id);

    croak($status) if $status;
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
