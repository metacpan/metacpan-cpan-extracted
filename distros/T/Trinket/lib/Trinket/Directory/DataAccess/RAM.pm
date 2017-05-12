###########################################################################
### Trinket::Directory::DataAccess::RAM
###
### Access to directory of persistent objects.
###
### $Id: RAM.pm,v 1.2 2001/02/16 07:25:45 deus_x Exp $
###
### TODO:
### -- Callbacks for Object to accomdate on-demand property get/set
### -- Do something meaningful in close()
### -- Save contents of RAM directories?  implement in open()/close()?
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

package Trinket::Directory::DataAccess::RAM;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::DataAccess::RAM -

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
use Trinket::Directory::FilterParser;
use Bit::Vector::Overload;
use Storable qw( thaw freeze );
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp qw( confess croak cluck );
use Data::Dumper qw( Dumper );

Bit::Vector->Configuration("out=bin");

### Class-global collection of directories.
our %DIRS = ();

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

    $self->{directory} = undef;

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

    $self->{dir_name} = $name;

    my $dir_name = $self->{dir_name};
    $DIRS{$dir_name} =
      {
       created => 1,
       objects => [],
       indices => {}
      };
    $self->{directory} = $DIRS{$dir_name};
    $self->{save_file} = $params->{file} if $params->{file};

    return 1;
  }

# }}}
# {{{ open()

=item $dir->open($params)

TODO

=cut

sub open
  {
    my ($self, $dir_name, $params) = @_;

    $self->{save_file} = $params->{file} if $params->{file};
    $self->{dir_name}  = $dir_name;

    ### Load save file
    if (defined $self->{save_file})
      {
        local *FIN;
        local $/; undef $/;
        open (FIN, $self->{save_file}) ||
          die "Could not open ".$self->{save_file}.": $!";
        my $serial = <FIN>;
        close (FIN);

        $DIRS{$self->{dir_name}} = thaw(decode_base64($serial));
      }

    return undef if ($DIRS{$dir_name}->{created} ne 1);

    $self->{directory} = $DIRS{$dir_name};
    $self->{cache_objects} && $self->clear_cache();

    return 1;
  }

# }}}
# {{{ close()

=item $dir->close($params)

TODO

=cut

sub close {
    my ($self, $params) = @_;

    if (defined $self->{save_file}) {
		my $serial = $self->serialize();
        local *FOUT;
        open (FOUT, "> ".$self->{save_file}) ||
          die "Could not open ".$self->{save_file}.": $!";
        print FOUT $serial;
        close (FOUT);
	}
	
    return 1;
}

# }}}
# {{{ serialize()

sub serialize {
	my ($self) = @_;
	#return Dumper($DIRS{$self->{dir_name}});
	return encode_base64(freeze($DIRS{$self->{dir_name}}));
}

# }}}
# {{{ deserialize()

sub deserialize {
	my ($self, $data) = @_;

	eval {
		#my $VAR1;
		#eval $data;
		#$DIRS{$self->{dir_name}} = $VAR1;
		$DIRS{$self->{dir_name}} = thaw(decode_base64($data));
		$self->{directory} = $DIRS{$self->{dir_name}};
	};
	if ($@) {
		return undef;
	}

	return 1;
}

# }}}

# {{{ store_object():

sub store_object {
    my ($self, $obj) = @_;

    my ($serialized, $dirty, $dirty_name, $dirty_vals, $dirty_old,
        $dirty_new, $id, $dir, $is_new);

    ### Get the object's id
    $id  = $obj->get_id();

    ### Check if this is an attempt to store an object with the id of
    ### an object which has been previously deleted.  If so, undefine
    ### the object's id and proceed.
    if ( (defined $id) && ( $self->is_deleted_id($id) ) )
      { $obj->set_id($id = undef); }

    ### Does this object have an id?  If not, give it one.
	$is_new = 0;
    if (!defined $id) {
		$obj->set_id($id = $self->get_new_id());
		$is_new = 1;
	}

	eval {
		### HACK:  We don't want to serialize the directory.  Actually,
		### there are a lot of things we don't want to serialize.  Will
		### have to find a way to handle this cleanly
		#$obj->set_directory(undef);
		
		### Serialize and store the object.
		foreach my $prop_name ($obj->list_properties()) {
			$obj->get($prop_name);
		}
		$self->{directory}->{objects}->[$id] = $obj;
		
		### Update dirty indexes...
		if ($dirty = $obj->_find_dirty_indices()) {
			while (($dirty_name, $dirty_vals) = each %{$dirty}) {
				($dirty_old, $dirty_new) =
				  ($dirty_vals->[DIRTY_OLD_VALUE],
				   $dirty_vals->[DIRTY_NEW_VALUE]);
				
				if ($dirty_old)
				  { $self->delete_from_index($id, $dirty_name, $dirty_old); }
				$self->store_in_index($id, $dirty_name, $dirty_new);
			}
		}
	};

	if ($@) {
		confess ($@);
	}
		
	if ($is_new) {
		my @parent_classes = $obj->_derive_ancestry();
		foreach my $class (@parent_classes) {
			$self->store_in_index($id, 'class', $class);
		}
	}

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
    return $self->{directory}->{objects}->[$id];
  }

# }}}
# {{{ delete_object

sub delete_object
  {
    my ($self, $id, $obj) = @_;

    $self->{directory}->{objects}->[$id] = undef;

    ### Delete all indexes for this object's properties
    #my $name;
    #foreach $name ($obj->list_properties())
    #  { $self->delete_from_index($id, $name); }

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
	   my $result_vec = shift;
	   while(@_) {
		   my $sub_vec = shift;
		   my $tmp_vec = $result_vec->Shadow();
		   $tmp_vec->Intersection($result_vec, $sub_vec);
		   $result_vec = $tmp_vec;
	   }
	   return $result_vec;
   },
   OR  => sub
   {
	   my $result_vec = shift;
	   while(@_) {
		   my $sub_vec = shift;
		   my $tmp_vec = $result_vec->Shadow();
		   $tmp_vec->Union($result_vec, $sub_vec);
		   $result_vec = $tmp_vec;
       }
	   return $result_vec;
   },
   NOT => sub
   {
	   my $result_vec = shift;
	   my $tmp_vec = $result_vec->Shadow();
	   $tmp_vec->Complement($result_vec);
	   return $tmp_vec;
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

	my $result_vec = $_search_join_subs{$op}->(@sub_results);

    return $result_vec;
  }

# }}}
# {{{ _search_leaf_op

my %_search_leaf_subs =
  (
   'EQ'     => sub {
	   my ($index, $val) = @_;
	   my @ids;

	   ### Get all ids whose value is equal to the given value.
	   if ($val eq '*') {
		   foreach my $k1 (keys %{$index})
			 { push @ids, keys %{$index->{$k1}}; }
       } else {
		   @ids = keys %{$index->{$val}};
	   }
	
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

    return undef if (!defined $self->{directory});

    return ( $self->{directory}->{created} eq 1 );
  }

# }}}

# {{{ get_new_id():

sub get_new_id
  {
    my $self = shift;

    return scalar(@{$self->{directory}->{objects}});
  }

# }}}
# {{{ is_deleted_id():

sub is_deleted_id
  {
    my ($self, $id) = @_;

    return ( exists ($self->{directory}->{objects}->[$id]) &&
             !defined ($self->{directory}->{objects}->[$id]) );
  }

# }}}
# {{{ get_id_range()

sub get_id_range
  {
    my $self = shift;

    return scalar(@{$self->{directory}->{objects}});
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

sub delete_from_index {
    my ($self, $id, $name, $value) = @_;
	
    return undef if (!$self->index_exists($name));
	
    my $name_index = $self->{directory}->{indices}->{$name};
	
    if (defined $value) {
        delete $name_index->{$value}->{$id};
        delete $name_index->{$value}
          if (! keys(%{$name_index->{$value}}) );
	} else {
        foreach $value ( keys %{$name_index} ) {
            delete $name_index->{$value}->{$id}
              if ($name_index->{$value}->{$id});
            if (! keys(%{$name_index->{$value}}) ) {
				delete $name_index->{$value};
				last;
			}
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

# {{{ DESTROY

sub DESTROY {
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
