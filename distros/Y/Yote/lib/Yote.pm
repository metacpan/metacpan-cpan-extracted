package Yote;

use strict;
use warnings;
no  warnings 'uninitialized';

use vars qw($VERSION);

$VERSION = '2.0';

=head1 NAME

Yote - Persistant Perl container objects in a directed graph of lazilly loaded nodes.

=head1 DESCRIPTION

This is for anyone who wants to store arbitrary structured state data and doesn't have
the time or inclination to write a schema or configure some framework. This can be used
orthagonally to any other storage system.

Yote only loads data as it needs too. It does not load all stored containers at once.
Data is stored in a data directory and is stored using the Data::RecordStore module. A Yote
container is a key/value store where the values can be strings, numbers, arrays, hashes
or other Yote containers.

The entry point for all Yote data stores is the root node. All objects in the store are
unreachable if they cannot trace a reference path back to this node. If they cannot, running
compress_store will remove them.

There are lots of potential uses for Yote, and a few come to mind :

 * configuration data
 * data modeling
 * user preference data
 * user account data
 * game data
 * shopping carts
 * product information

=head1 SYNOPSIS

 use Yote;

 my $store = Yote::open_store( '/path/to/data-directory' );

 my $root_node = $store->fetch_root;

 $root_node->add_to_myList( $store->newobj( {
    someval  => 123.53,
    somehash => { A => 1 },
    someobj  => $store->newobj( { foo => "Bar" },
                'Optional-Yote-Subclass-Package' );
 } );

 # the root node now has a list 'myList' attached to it with the single
 # value of a yote object that yote object has two fields,
 # one of which is an other yote object.

 $root_node->add_to_myList( 42 );

 #
 # New Yote container objects are created with $store->newobj. Note that
 # they must find a reference path to the root to be protected from
 # being deleted from the record store upon compression.
 #
 my $newObj = $store->newobj;

 $root_node->set_field( "Value" );

 my $val = $root_node->get_value( "default" );
 # $val eq 'default'

 $val = $root_node->get_value( "Somethign Else" );
 # $val eq 'default' (old value not overridden by a new default value)


 my $otherval = $root_node->get( 'ot3rv@l', 'other default' );
 # $otherval eq 'other default'

 $root_node->set( 'ot3rv@l', 'newy valuye' );
 $otherval2 = $root_node->get( 'ot3rv@l', 'yet other default' );
 # $otherval2 eq 'newy valuye'

 $root_node->set_value( "Something Else" );

 my $val = $root_node->get_value( "default" );
 # $val eq 'Something Else'

 my $myList = $root_node->get_myList;

 for my $example (@$myList) {
    print ">$example\n";
 }

 #
 # Each object gets a unique ID which can be used to fetch that
 # object directly from the store.
 #
 my $someid = $root_node->get_someobj->{ID};

 my $someref = $store->fetch( $someid );

 #
 # Even hashes and array have unique yote IDS. These can be
 # determined by calling the _get_id method of the store.
 #
 my $hash = $root_node->set_ahash( { zoo => "Zar" } );
 my $hash_id = $store->_get_id( $hash );
 my $other_ref_to_hash = $store->fetch( $hash_id );

 #
 # Anything that cannot trace a reference path to the root
 # is eligable for being removed upon compression.
 #

=head1 PUBLIC METHODS

=cut


=head2 open_store( '/path/to/directory' )

Starts up a persistance engine and returns it.

=cut

sub open_store {
    my $path = pop;
    my $store = Yote::ObjStore->_new( { store => $path } );
    $store->_init;
    $store;
}

# ---------------------------------------------------------------------------------------------------------------------

package Yote::ObjStore;

use strict;
use warnings;
no warnings 'numeric';
no warnings 'uninitialized';
no warnings 'recursion';

use File::Copy;
use File::Path qw(make_path remove_tree);
use Scalar::Util qw(weaken);

use Module::Loaded;

=head1 NAME

 Yote::ObjStore - manages Yote::Obj objects in a graph.

=head1 DESCRIPTION

The Yote::ObjStore does the following things :

 * fetches the root object
 * creates new objects
 * fetches existing objects by id
 * saves all new or changed objects
 * finds objects that cannot connect to the root node and removes them

=cut

# ------------------------------------------------------------------------------------------
#      * PUBLIC CLASS METHODS *
# ------------------------------------------------------------------------------------------

=head2 fetch_root

 Returns the root node of the graph. All things that can be
trace a reference path back to the root node are considered active
and are not removed when the object store is compressed.

=cut
sub fetch_root {
    my $self = shift;
    die "fetch_root must be called on Yote store object" unless ref( $self );
    my $root = $self->fetch( $self->_first_id );
    unless( $root ) {
        $root = $self->_newroot;
        $root->{ID} = $self->_first_id;
        $self->_stow( $root );
    }
    $root;
} #fetch_root

=head2 newobj( { ... data .... }, optionalClass )

 Creates a container object initialized with the
 incoming hash ref data. The class of the object must be either
 Yote::Obj or a subclass of it. Yote::Obj is the default.

 Once created, the object will be saved in the data store when
 $store->stow_all has been called.  If the object is not attached
 to the root or an object that can be reached by the root, it will be
 remove when Yote::ObjStore::Compress is called.

=cut
sub newobj {
    my( $self, $data, $class ) = @_;
    $class ||= 'Yote::Obj';
    $class->_new( $self, $data );
}

sub _newroot {
    my $self = shift;
    Yote::Obj->_new( $self, {}, $self->_first_id );
}


=head2 fetch( $id )

 Returns the object with the given id.

=cut
sub fetch {
    my( $self, $id ) = @_;
    return undef unless $id;
    #
    # Return the object if we have a reference to its dirty state.
    #
    my $ref = $self->{_DIRTY}{$id};
    if( defined $ref ) {
        return $ref;
    } else {
        $ref = $self->{_WEAK_REFS}{$id};
        if( $ref ) {
            return $ref;
        }
        undef $ref;
    }
    my $obj_arry = $self->{_DATASTORE}->_fetch( $id );

    if( $obj_arry ) {
        my( $id, $class, $data ) = @$obj_arry;
        if( $class eq 'ARRAY' ) {
            my( @arry );
            tie @arry, 'Yote::Array', $self, $id, @$data;
            $self->_store_weak( $id, \@arry );
            return \@arry;
        }
        elsif( $class eq 'HASH' ) {
            my( %hash );
            tie %hash, 'Yote::Hash', $self, $id, map { $_ => $data->{$_} } keys %$data;
            $self->_store_weak( $id, \%hash );
            return \%hash;
        }
        else {
            my $obj;
            eval {
                my $path = $class;
                unless( $INC{ $class } ) {
                    eval("use $class");
                }
                $obj = $self->{_WEAK_REFS}{$id} || $class->_instantiate( $id, $self );
            };
            die $@ if $@;
            $obj->{DATA} = $data;
            $obj->{ID} = $id;
            $self->_store_weak( $id, $obj );
            $obj->_load();
            return $obj;
        }
    }
    return undef;
} #fetch

=head2 run_purger

=cut
sub run_purger {
    my( $self, $make_tally, $copy_only ) = @_;
    $self->stow_all();

    my $keep_db = $self->{_DATASTORE}->_generate_keep_db();

    # analyze to see what percentage would be kept
    my $total = $keep_db->entry_count;
    my $keep = 0;
    for my $tid (1..$total) {
        my( $has_keep ) = $keep_db->get_record( $tid )->[0];
        $keep++ if $has_keep;
    }

    #
    # If there are more things to keep than not, do a db purge,
    # otherwise, rebuild the db.
    #
    my $do_purge = $keep > ( $total/2 ) && ! $copy_only;
    my $purged;
    if( $do_purge ) {
        $purged = $self->{_DATASTORE}->_purge_objects( $keep_db, $make_tally );
    } else {
        $purged = $self->_copy_active_ids( $keep_db, $make_tally );
    }

    $self->{_DATASTORE}->_update_recycle_ids( $keep_db );

    # commenting out for a test
    $keep_db->unlink_store;

    $purged;
} #run_purger

sub _copy_active_ids {
    my( $self, $copy_db ) = @_;
    $self->stow_all();

    my $original_dir = $self->{args}{store};
    my $backdir = $original_dir . '_COMPRESS_BACK_RECENT';
    my $newdir  = $original_dir . '_NEW_RECYC';

    if( -e $backdir ) {
        my $oldback = $original_dir . '_COMPRESS_BACK_OLD';
        if( -d $oldback ) {
            warn "Removing old compression backup directory";
            remove_tree( $oldback );
        }
        move( $backdir, $oldback ) or die $!;
    }

    if( -x $newdir ) {
        die "Unable to run compress store, temp directory '$newdir' already exists.";
    }
    my $newstore = Yote::ObjStore->_new( { store => $newdir } );

    my( @purges );
    for my $keep_id ( 1..$copy_db->entry_count ) {

        my( $has_keep ) = $copy_db->get_record( $keep_id )->[0];
        if( $has_keep ) {
            my $obj = $self->fetch( $keep_id );

            $newstore->{_DATASTORE}{DATA_STORE}->ensure_entry_count( $keep_id - 1 );
            $newstore->_dirty( $obj, $keep_id );
            $newstore->_stow( $obj, $keep_id );
        } elsif( $self->{_DATASTORE}{DATA_STORE}->has_id( $keep_id ) ) {
            push @purges, $keep_id;
        }
    } #each entry id

    move( $original_dir, $backdir ) or die $!;
    move( $newdir, $original_dir ) or die $!;

    \@purges;

} #_copy_active_ids

=head2 has_id

 Returns true if there is a valid reference linked to the id

=cut
sub has_id {
    my( $self, $id ) = @_;
    return $self->{_DATASTORE}{DATA_STORE}->has_id( $id );
}

=head2 stow_all

 Saves all newly created or dirty objects.

=cut
sub stow_all {
    my $self = shift;
    my @odata;
    for my $obj (values %{$self->{_DIRTY}} ) {
        my $cls;
        my $ref = ref( $obj );
        if( $ref eq 'ARRAY' || $ref eq 'Yote::Array' ) {
            $cls = 'ARRAY';
        } elsif( $ref eq 'HASH' || $ref eq 'Yote::Hash' ) {
            $cls = 'HASH';
        } else {
            $cls = $ref;
        }
        my( $text_rep ) = $self->_raw_data( $obj );
        push( @odata, [ $self->_get_id( $obj ), $cls, $text_rep ] );
    }
    $self->{_DATASTORE}->_stow_all( \@odata );
    $self->{_DIRTY} = {};
} #stow_all


=head2 stow( $obj )

 Saves that object to the database

=cut
sub stow {
    my( $self, $obj ) = @_;
    my $cls;
    my $ref = ref( $obj );
    if( $ref eq 'ARRAY' || $ref eq 'Yote::Array' ) {
        $cls = 'ARRAY';
    } elsif( $ref eq 'HASH' || $ref eq 'Yote::Hash' ) {
        $cls = 'HASH';
    } else {
        $cls = $ref;
    }
    my $id = $self->_get_id( $obj );
    my( $text_rep ) = $self->_raw_data( $obj );
    $self->{_DATASTORE}->_stow( $id, $cls, $text_rep );
    delete $self->{_DIRTY}{$id};
} #stow



# -------------------------------
#      * PRIVATE METHODS *
# -------------------------------
sub _new { #Yote::ObjStore
    my( $pkg, $args ) = @_;
    my $self = bless {
        _DIRTY     => {},
        _WEAK_REFS => {},
        args       => $args,
    }, $pkg;
    $self->{_DATASTORE} = Yote::YoteDB->open( $self, $args );
    $self;
} #_new

sub _init {
    my $self = shift;
    for my $pkg ( qw( Yote::Obj Yote::Array Yote::Hash ) ) {
        $INC{ $pkg } or eval("use $pkg");
    }
    $self->fetch_root;
    $self->stow_all;
    $self;
}


sub dirty_count {
    my $self = shift;
    return scalar( keys %{$self->{_DIRTY}} );
}

#
# Markes given object as dirty.
#
sub _dirty {
    # ( $self, $ref, $id
    $_[0]->{_DIRTY}->{$_[2]} = $_[1];
} #_dirty

#
# Returns the first ID that is associated with the root Root object
#
sub _first_id {
    shift->{_DATASTORE}->_first_id();
} #_first_id

sub _get_id {
    # for debugging I think?
    shift->__get_id( shift );
}

sub __get_id {
    my( $self, $ref ) = @_;

    my $class = ref( $ref );
    die "__get_id requires reference. got '$ref'" unless $class;

    if( $class eq 'Yote::Array') {
        return $ref->[0];
    }
    elsif( $class eq 'ARRAY' ) {
        my $tied = tied @$ref;
        if( $tied ) {
            $tied->[0] ||= $self->{_DATASTORE}->_get_id( "ARRAY" );
            return $tied->[0];
        }
        my( @data ) = @$ref;
        my $id = $self->{_DATASTORE}->_get_id( $class );
        tie @$ref, 'Yote::Array', $self, $id;
        push( @$ref, @data );
        $self->_dirty( $ref, $id );
        $self->_store_weak( $id, $ref );
        return $id;
    }
    elsif( $class eq 'Yote::Hash' ) {
        my $wref = $ref;
        return $ref->[0];
    }
    elsif( $class eq 'HASH' ) {
        my $tied = tied %$ref;
        if( $tied ) {
            $tied->[0] ||= $self->{_DATASTORE}->_get_id( "HASH" );
            return $tied->[0];
        }
        my $id = $self->{_DATASTORE}->_get_id( $class );

        my( %vals ) = %$ref;

        tie %$ref, 'Yote::Hash', $self, $id;
        for my $key (keys %vals) {
            $ref->{$key} = $vals{$key};
        }
        $self->_dirty( $ref, $id );
        $self->_store_weak( $id, $ref );
        return $id;
    }
    else {
        return $ref->{ID} if $ref->{ID};
        if( $class eq 'Yote::Root' ) {
            $ref->{ID} = $self->{_DATASTORE}->_first_id( $class );
        } else {
            $ref->{ID} ||= $self->{_DATASTORE}->_get_id( $class );
        }

        return $ref->{ID};
    }

} #_get_id

sub _stow {
    my( $self, $obj, $id ) = @_;

    my $class = ref( $obj );
    return unless $class;
    $id //= $self->_get_id( $obj );
    die unless $id;

    my( $text_rep, $data ) = $self->_raw_data( $obj );

    if( $class eq 'ARRAY' ) {
        $self->{_DATASTORE}->_stow( $id,'ARRAY', $text_rep );
        $self->_clean( $id );
    }
    elsif( $class eq 'HASH' ) {
        $self->{_DATASTORE}->_stow( $id,'HASH',$text_rep );
        $self->_clean( $id );
    }
    elsif( $class eq 'Yote::Array' ) {
        if( $self->_is_dirty( $id ) ) {
            $self->{_DATASTORE}->_stow( $id,'ARRAY',$text_rep );
            $self->_clean( $id );
        }
        for my $child (@$data) {
            if( $child =~ /^[0-9]/ && $self->{_DIRTY}->{$child} ) {
                $self->_stow( $child, $self->{_DIRTY}->{$child} );
            }
        }
    }
    elsif( $class eq 'Yote::Hash' ) {
        if( $self->_is_dirty( $id ) ) {
            $self->{_DATASTORE}->_stow( $id, 'HASH', $text_rep );
        }
        $self->_clean( $id );
        for my $child (values %$data) {
            if( $child =~ /^[0-9]/ && $self->{_DIRTY}->{$child} ) {
                $self->_stow( $child, $self->{_DIRTY}->{$child} );
            }
        }
    }
    else {
        if( $self->_is_dirty( $id ) ) {
            $self->{_DATASTORE}->_stow( $id, $class, $text_rep );
            $self->_clean( $id );
        }
        for my $val (values %$data) {
            if( $val =~ /^[0-9]/ && $self->{_DIRTY}->{$val} ) {
                $self->_stow( $val, $self->{_DIRTY}->{$val} );
            }
        }
    }
    $id;
} #_stow

sub _xform_in {
    my( $self, $val ) = @_;
    if( ref( $val ) ) {
        return $self->_get_id( $val );
    }
    return defined $val ? "v$val" : undef;
}

sub _xform_out {
    my( $self, $val ) = @_;
    return undef unless defined( $val );
    if( index($val,'v') == 0 ) {
        return substr( $val, 1 );
    }
    return $self->fetch( $val );
}

sub _clean {
    my( $self, $id ) = @_;
    delete $self->{_DIRTY}{$id};
} #_clean

sub _is_dirty {
    my( $self, $obj ) = @_;
    my $id = ref($obj) ? _get_id($obj) : $obj;
    my $ans = $self->{_DIRTY}{$id};
    $ans;
} #_is_dirty

#
# Returns data structure representing object. References are integers. Values start with 'v'.
#
sub _raw_data {
    my( $self, $obj ) = @_;
    my $class = ref( $obj );
    return unless $class;
    my $id = $self->_get_id( $obj );
    die unless $id;
    my( $r, $is_array );
    if( $class eq 'ARRAY' ) {
        my $tied = tied @$obj;
        if( $tied ) {
            $r = $tied->[1];
            $is_array = 1;
        } else {
            die;
        }
    }
    elsif( $class eq 'HASH' ) {
        my $tied = tied %$obj;
        if( $tied ) {
            $r = $tied->[1];
        } else {
            die;
        }
    }
    elsif( $class eq 'Yote::Array' ) {
        $r = $obj->[1];
        $is_array = 1;
    }
    elsif( $class eq 'Yote::Hash' ) {
        $r = $obj->[1];
    }
    else {
        $r = $obj->{DATA};
    }

    if( $is_array ) {
        return join( "`", map { if( defined($_) ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } $_ } @$r ), $r;
    }
    return join( "`", map { if( defined($_) ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } $_ } %$r ), $r;

} #_raw_data


sub _store_weak {
    my( $self, $id, $ref ) = @_;
    die unless $ref;
    $self->{_WEAK_REFS}{$id} = $ref;

    weaken( $self->{_WEAK_REFS}{$id} );
} #_store_weak

# ---------------------------------------------------------------------------------------------------------------------

=head1 NAME

 Yote::Obj - Generic container object for graph.

=head1 DESCRIPTION

A Yote::Obj is a container class that as a specific idiom for getters
and setters. This idiom is set up to avoid confusion and collision
with any method names.

 # sets the 'foo' field to the given value.
 $obj->set_foo( { value => $store->newobj } );

 # returns the value for bar, and if none, sets it to 'default'
 my $bar = $obj->get_bar( "default" );

 $obj->add_to_somelist( "Freddish" );
 my $list = $obj->get_somelist;
 $list->[ 0 ] == "Freddish";


 $obj->remove_from_somelist( "Freddish" );

=cut
package Yote::Obj;

use strict;
use warnings;
no  warnings 'uninitialized';

#
# The string version of the yote object is simply its id. This allows
# objet ids to easily be stored as hash keys.
#
use overload
    '""' => sub { shift->{ID} }, # for hash keys
    eq   => sub { ref($_[1]) && $_[1]->{ID} == $_[0]->{ID} },
    ne   => sub { ! ref($_[1]) || $_[1]->{ID} != $_[0]->{ID} },
    '=='   => sub { ref($_[1]) && $_[1]->{ID} == $_[0]->{ID} },
    '!='   => sub { ! ref($_[1]) || $_[1]->{ID} != $_[0]->{ID} },
    fallback => 1;

=head2 absorb( hashref )

    pulls the hash data into this object.

=cut
sub absorb {
    my( $self, $data ) = @_;
    my $obj_store = $self->{STORE};
    for my $key ( sort keys %$data ) {
        my $item = $data->{ $key };
        $self->{DATA}{$key} = $obj_store->_xform_in( $item );
    }
    $obj_store->_dirty( $self, $self->{ID} );

} #absorb

sub id {
    shift->{ID};
}

=head2 set( $field, $value )

    Assigns the given value to the field in this object and returns the
    assigned value.

=cut
sub set {
    my( $self, $fld, $val ) = @_;

    my $inval = $self->{STORE}->_xform_in( $val );
    if( $self->{DATA}{$fld} ne $inval ) {
        $self->{STORE}->_dirty( $self, $self->{ID} );
    }

    unless( defined $inval ) {
        delete $self->{DATA}{$fld};
        return;
    }
    $self->{DATA}{$fld} = $inval;
    return $self->{STORE}->_xform_out( $self->{DATA}{$fld} );
} #set


=head2 get( $field, $default-value )

    Returns the value assigned to the field, assinging the default
    value to it if the value is currently not defined.

=cut
sub get {
    my( $self, $fld, $default ) = @_;
    my $cur = $self->{DATA}{$fld};
    if( ! defined( $cur ) && defined( $default ) ) {
        if( ref( $default ) ) {
            # this must be done to make sure the reference is saved for cases where the reference has not yet made it to the store of things to save
            $self->{STORE}->_dirty( $default->{STORE}->_get_id( $default ) );
        }
        $self->{STORE}->_dirty( $self, $self->{ID} );
        $self->{DATA}{$fld} = $self->{STORE}->_xform_in( $default );
    }
    return $self->{STORE}->_xform_out( $self->{DATA}{$fld} );
} #get


# -----------------------
#
#     Public Methods
# -----------------------
#
# Defines get_foo, set_foo, add_to_list, remove_from_list
#
sub AUTOLOAD {
    my( $s, $arg ) = @_;
    my $func = our $AUTOLOAD;

    if( $func =~/:add_to_(.*)/ ) {
        my( $fld ) = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            push( @$arry, @vals );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    } #add_to
    elsif( $func =~/:add_once_to_(.*)/ ) {
        my( $fld ) = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            for my $val ( @vals ) {
                unless( grep { $val eq $_ } @$arry ) {
                    push @$arry, $val;
                }
            }
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    } #add_once_to
    elsif( $func =~ /:remove_from_(.*)/ ) { #removes the first instance of the target thing from the list
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            for my $val (@vals ) {
                for my $i (0..$#$arry) {
                    if( $arry->[$i] eq $val ) {
                        splice @$arry, $i, 1;
                        last;
                    }
                }
            }
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif( $func =~ /:remove_all_from_(.*)/ ) { #removes the first instance of the target thing from the list
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, @vals ) = @_;
            my $get = "get_$fld";
            my $arry = $self->$get([]); # init array if need be
            for my $val (@vals) {
                my $count = grep { $_ eq $val } @$arry;
                while( $count ) {
                    for my $i (0..$#$arry) {
                        if( $arry->[$i] eq $val ) {
                            --$count;
                            splice @$arry, $i, 1;
                            last unless $count;
                        }
                    }
                }
            }
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif ( $func =~ /:set_(.*)/ ) {
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, $val ) = @_;
            my $inval = $self->{STORE}->_xform_in( $val );
            $self->{STORE}->_dirty( $self, $self->{ID} ) if $self->{DATA}{$fld} ne $inval;
            unless( defined $inval ) {
                delete $self->{DATA}{$fld};
                return;
            }
            $self->{DATA}{$fld} = $inval;
            return $self->{STORE}->_xform_out( $self->{DATA}{$fld} );
        };
        goto &$AUTOLOAD;
    }
    elsif( $func =~ /:get_(.*)/ ) {
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, $init_val ) = @_;
            if( ! defined( $self->{DATA}{$fld} ) && defined($init_val) ) {
                if( ref( $init_val ) ) {
                    # this must be done to make sure the reference is saved for cases where the reference has not yet made it to the store of things to save
                    $self->{STORE}->_dirty( $init_val, $self->{STORE}->_get_id( $init_val ) );
                }
                $self->{STORE}->_dirty( $self, $self->{ID} );
                $self->{DATA}{$fld} = $self->{STORE}->_xform_in( $init_val );
            }
            return $self->{STORE}->_xform_out( $self->{DATA}{$fld} );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    else {
        die "Unknown Yote::Obj function '$func'";
    }

} #AUTOLOAD

# -----------------------
#
#     Overridable Methods
# -----------------------

=head2 _init

    This is called the first time an object is created. It is not
    called when the object is loaded from storage. This can be used
    to set up defaults. This is meant to be overridden.

=cut
sub _init {}

=head2 _init

    This is called each time the object is loaded from the data store.
    This is meant to be overridden.

=cut
sub _load {}



# -----------------------
#
#     Private Methods
#
# -----------------------


sub _new { #new Yote::Obj
    my( $pkg, $obj_store, $data, $_id ) = @_;

    my $class = ref($pkg) || $pkg;
    my $obj = bless {
        DATA     => {},
        STORE    => $obj_store,
    }, $class;
    $obj->{ID} = $_id || $obj_store->_get_id( $obj );
    $obj_store->_dirty( $obj, $obj->{ID} );
    $obj->_init(); #called the first time the object is created.

    if( ref( $data ) eq 'HASH' ) {
        $obj->absorb( $data );
    } elsif( $data ) {
        die "Yote::Obj::new must be called with hash or undef. Was called with '". ref( $data ) . "'";
    }
    return $obj;
} #_new

sub _store {
    return shift->{STORE};
}

#
# Called by the object provider; returns a Yote::Obj the object
# provider will stuff data into. Takes the class and id as arguments.
#
sub _instantiate {
    bless { ID => $_[1], DATA => {}, STORE => $_[2] }, $_[0];
} #_instantiate

sub DESTROY {
    my $self = shift;
    delete $self->{STORE}{_WEAK_REFS}{$self->{ID}};
}


# ---------------------------------------------------------------------------------------------------------------------

package Yote::Array;

############################################################################################################
# This module is used transparently by Yote to link arrays into its graph structure. This is not meant to  #
# be called explicitly or modified.									   #
############################################################################################################

use strict;
use warnings;

no warnings 'uninitialized';
use Tie::Array;

sub TIEARRAY {
    my( $class, $obj_store, $id, @list ) = @_;
    my $storage = [];

    # once the array is tied, an additional data field will be added
    # so obj will be [ $id, $storage, $obj_store ]
    my $obj = bless [$id,$storage,$obj_store], $class;
    for my $item (@list) {
        push( @$storage, $item );
    }
    return $obj;
}

sub FETCH {
    my( $self, $idx ) = @_;
    return $self->[2]->_xform_out ( $self->[1][$idx] );
}

sub FETCHSIZE {
    my $self = shift;
    return scalar(@{$self->[1]});
}

sub STORE {
    my( $self, $idx, $val ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    $self->[1][$idx] = $self->[2]->_xform_in( $val );
}
sub STORESIZE {}  #stub for array

sub EXISTS {
    my( $self, $idx ) = @_;
    return defined( $self->[1][$idx] );
}
sub DELETE {
    my( $self, $idx ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    delete $self->[1][$idx];
}

sub CLEAR {
    my $self = shift;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    @{$self->[1]} = ();
}
sub PUSH {
    my( $self, @vals ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    push( @{$self->[1]}, map { $self->[2]->_xform_in($_) } @vals );
}
sub POP {
    my $self = shift;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    return $self->[2]->_xform_out( pop @{$self->[1]} );
}
sub SHIFT {
    my( $self ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    my $val = splice @{$self->[1]}, 0, 1;
    return $self->[2]->_xform_out( $val );
}
sub UNSHIFT {
    my( $self, @vals ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    unshift @{$self->[1]}, map {$self->[2]->_xform_in($_)} @vals;
}
sub SPLICE {
    my( $self, $offset, $length, @vals ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    return map { $self->[2]->_xform_out($_) } splice @{$self->[1]}, $offset, $length, map {$self->[2]->_xform_in($_)} @vals;
}
sub EXTEND {}

sub DESTROY {
    my $self = shift;
    delete $self->[2]->{_WEAK_REFS}{$self->[0]};
}

# ---------------------------------------------------------------------------------------

package Yote::Hash;

######################################################################################
# This module is used transparently by Yote to link hashes into its graph structure. #
# This is not meant to  be called explicitly or modified.                            #
######################################################################################

use strict;
use warnings;

no warnings 'uninitialized';

use Tie::Hash;

sub TIEHASH {
    my( $class, $obj_store, $id, %hash ) = @_;
    my $storage = {};
    # after $obj_store is a list reference of
    #                 id, data, store
    my $obj = bless [ $id, $storage,$obj_store ], $class;
    for my $key (keys %hash) {
        $storage->{$key} = $hash{$key};
    }
    return $obj;
}

sub STORE {
    my( $self, $key, $val ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    $self->[1]{$key} = $self->[2]->_xform_in( $val );
}

sub FIRSTKEY {
    my $self = shift;
    my $a = scalar keys %{$self->[1]};
    my( $k, $val ) = each %{$self->[1]};
    return wantarray ? ( $k => $val ) : $k;
}
sub NEXTKEY  {
    my $self = shift;
    my( $k, $val ) = each %{$self->[1]};
    return wantarray ? ( $k => $val ) : $k;
}

sub FETCH {
    my( $self, $key ) = @_;
    return $self->[2]->_xform_out( $self->[1]{$key} );
}

sub EXISTS {
    my( $self, $key ) = @_;
    return defined( $self->[1]{$key} );
}
sub DELETE {
    my( $self, $key ) = @_;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    return delete $self->[1]{$key};
}
sub CLEAR {
    my $self = shift;
    $self->[2]->_dirty( $self->[2]{_WEAK_REFS}{$self->[0]}, $self->[0] );
    %{$self->[1]} = ();
}

sub DESTROY {
    my $self = shift;
    delete $self->[2]->{_WEAK_REFS}{$self->[0]};
}

# ---------------------------------------------------------------------------------------

package Yote::YoteDB;

use strict;
use warnings;

no warnings 'uninitialized';

use Data::RecordStore;

use File::Path qw(make_path);

use constant {
  DATA => 2,
};

#
# This the main index and stores in which table and position
# in that table that this object lives.
#
sub open {
  my( $pkg, $obj_store, $args ) = @_;
  my $class = ref( $pkg ) || $pkg;

  my $DATA_STORE;
  eval {
      $DATA_STORE = Data::RecordStore->open( $args->{ store } );
      
  };
  if( $@ ) {
      if( $@ =~ /old format/ ) {
          die "This yote store is of an older format. It can be converted using the yote_explorer";
      }
      die $@;
  }
  my $self = bless {
      args       => $args,
      OBJ_STORE  => $obj_store,
      DATA_STORE => $DATA_STORE,
  }, $class;
  $self->{DATA_STORE}->ensure_entry_count( 1 );
  $self;
} #open

#
# Return a list reference containing [ id, class, data ] that
# corresponds to the $id argument. This is used by Yote::ObjStore
# to build the yote object.
#
sub _fetch {
  my( $self, $id ) = @_;
  my $data = $self->{DATA_STORE}->fetch( $id );

  return undef unless $data;

  my $pos = index( $data, ' ' ); #there is a always a space after the class.
  $pos = ( length( $data ) ) if $pos == -1;
  die "Malformed record '$data'" if $pos == -1;
  my $class = substr $data, 0, $pos;
  my $val   = substr $data, $pos + 1;
  my $ret = [$id,$class,$val];

  # so foo` or foo\\` but not foo\\\`
  # also this will never start with a `
  my $parts = [ split /\`/, $val, -1 ];

  # check to see if any of the parts were split on escapes
  if( 0 < grep { /\\$/ } @$parts ) {
      my $newparts = [];
      my $shim = '';
      for my $part (@$parts) {
          if( $part =~ /(^|[^\\]((\\\\)+)?)$/ ) {
              my $newpart = $shim ? "$shim\`$part" : $part;
              $newpart =~ s/\\`/`/gs;
              $newpart =~ s/\\\\/\\/gs;
              push @$newparts, $newpart;
              $shim = '';
          } else {
              $shim = $shim ? "$shim\`$part" : $part;
          }
      }
      if( $shim ) {
          $shim =~ s/\\`/`/gs;
          $shim =~ s/\\\\/\\/gs;
          push @$newparts, $shim;
      }
      $parts = $newparts;
  }

  if( $class eq 'ARRAY' ) {
      $ret->[DATA] = $parts;
  } else {
      $ret->[DATA] = { @$parts };
  }

  $ret;
} #_fetch

#
# The first object in a yote data store can trace a reference to
# all active objects.
#
sub _first_id {
  return 1;
} #_first_id

#
# Create a new object id and return it.
#
sub _get_id {
  my $self = shift;
  $self->{DATA_STORE}->next_id;
} #_get_id


# used for debugging and testing
sub _max_id {
  shift->{DATA_STORE}->entry_count;
}

sub _generate_keep_db {
    my $self = shift;
    my $mark_to_keep_store = Data::RecordStore::FixedStore->open( "I", $self->{args}{store} . '/PURGE_KEEP' );

    $mark_to_keep_store->empty();
    $mark_to_keep_store->ensure_entry_count( $self->{DATA_STORE}->entry_count );

    my $check_store = Data::RecordStore::FixedStore->open( "L", $self->{args}{store} . '/CHECK' );
    $check_store->empty();

    $mark_to_keep_store->put_record( 1, [ 1 ] );

    my( %seen );
    my( @checks ) = ( 1 );

    for my $referenced_id ( grep { defined($self->{OBJ_STORE}{_WEAK_REFS}{$_}) } keys %{ $self->{OBJ_STORE}{_WEAK_REFS} } ) {
        push @checks, $referenced_id;
    }


    #
    # While there are items to check, check them.
    #
    while( @checks || $check_store->entry_count > 0 ) {
        my $check_id = shift( @checks ) || $check_store->pop->[0];
        $mark_to_keep_store->put_record( $check_id, [ 1 ] );

        my $item = $self->_fetch( $check_id );
        $seen{$check_id} = 1;
        my( @additions );
        if ( ref( $item->[DATA] ) eq 'ARRAY' ) {
            ( @additions ) = grep { /^[^v]/ && ! $seen{$_}++ } @{$item->[DATA]};
        } else {
            ( @additions ) = grep { /^[^v]/ && ! $seen{$_}++ } values %{$item->[DATA]};
        }
        if( @checks > 1_000_000 ) {
            for my $cid (@checks) {
                my( $has_keep ) = $mark_to_keep_store->get_record( $cid )->[0];
                unless( $has_keep ) {
                    $check_store->push( [ $cid ] );
                }
            }
            splice @checks;
        }
        if( scalar( keys(%seen) ) > 1_000_000 ) {
            %seen = ();
        }
        push @checks, @additions;
    }
    $check_store->unlink_store;

    $mark_to_keep_store;

} #_generate_keep_db

#
# Checks to see if the last entries of the stores can be popped off, making the purging quicker
#
sub _truncate_dbs {
    my( $self, $mark_to_keep_store, $keep_tally ) = @_;
    #loop through each database
    my $stores = $self->{DATA_STORE}->all_stores;
    my( @purged );
    for my $store (@$stores) {
        my $fn = $store->{FILENAME}; $fn =~ s!/[^/]+$!!;
        my $keep;
        while( ! $keep && $store->entry_count ) {
            my( $check_id ) = @{ $store->get_record($store->entry_count) };
            ( $keep ) = $mark_to_keep_store->get_record( $check_id )->[0];
            if( ! $keep ) {
                if( $self->{DATA_STORE}->delete( $check_id ) ) {
                    if( $keep_tally ) {
                        push @purged, $check_id;
                    }
                    $mark_to_keep_store->put_record( $check_id, [ 2 ] ); #mark as already removed by truncate
                }
            }
        }
    }
    \@purged;
}


sub _update_recycle_ids {
    my( $self, $mark_to_keep_store ) = @_;

    return unless $mark_to_keep_store->entry_count > 0;

    my $store = $self->{DATA_STORE};


    # find the higest still existing ID and cap the index to this
    my $highest_keep_id;
    for my $cand (reverse ( 1..$mark_to_keep_store->entry_count )) {
        my( $keep ) = $mark_to_keep_store->get_record( $cand )->[0];
        if( $keep ) {
            $store->set_entry_count( $cand );
            $highest_keep_id = $cand;
            last;
        }
    }

    $store->empty_recycler;

    # iterate each id in the entire object store and add those
    # not marked for keeping into the recycling
    for my $cand (reverse( 1.. $highest_keep_id) ) {
        my( $keep ) = $mark_to_keep_store->get_record( $cand )->[0];
        unless( $keep ) {
            $store->recycle( $cand );
        }
    }
} #_update_recycle_ids


sub _purge_objects {
  my( $self, $mark_to_keep_store, $keep_tally ) = @_;

  my $purged = $self->_truncate_dbs( $mark_to_keep_store );

  for my $cand ( 1..$mark_to_keep_store->entry_count) { #iterate each id in the entire object store
    my( $keep ) = $mark_to_keep_store->get_record( $cand )->[0];

    die "Tried to purge root entry" if $cand == 1 && ! $keep;
    if ( ! $keep ) {
        if( $self->{DATA_STORE}->delete( $cand ) ) {
            $mark_to_keep_store->put_record( $cand, [ 3 ] ); #mark as already removed by purge
            if( $keep_tally ) {
                push @$purged, $cand;
            }
        }
    }
  }

  $purged;

} #_purge_objects


#
# Saves the object data for object $id to the data store.
#
sub _stow { #Yote::YoteDB::_stow
  my( $self, $id, $class, $data ) = @_;
  my $save_data = "$class $data";
  $self->{DATA_STORE}->stow( $save_data, $id );
} #_stow

#
# Takes a list of object data references and stows them all in the datastore.
# returns how many are stowed.
#
sub _stow_all {
  my( $self, $objs ) = @_;
  my $count = 0;
  for my $o ( @$objs ) {
    $count += $self->_stow( @$o );
  }
  return $count;
} #_stow_all

1;

__END__

=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2016 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 2.0  (Nov 23, 2016))

=cut
