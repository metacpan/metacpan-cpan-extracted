package Yote;

use strict;
use warnings;
no  warnings 'uninitialized';

use vars qw($VERSION);

$VERSION = '3.0';
$Yote::DB_VERSION = 3;

sub open_store {
    my $path = pop;
    my $store = Yote::ObjStore->open_store( $path );
    $store;
}

# --------------------------------------------------------------------------------

package Yote::ObjStore;

use strict;
use warnings;
no warnings 'numeric';
no warnings 'uninitialized';
no warnings 'recursion';

use Data::RecordStore;
use File::Copy;
use File::Path qw(make_path remove_tree);
use Scalar::Util qw(weaken);

use constant {
    RECORD_STORE => 0,
    DIRTY        => 1,
    WEAK         => 2,
    PATH         => 3,
    STOREINFO    => 4,

    ID           => 0,
    DATA         => 1,
    LEVEL        => 3,
};

#
# Fetches the user facing root node. This node is
# off of the store info node as 'root'
#
sub fetch_root {
    my $self = shift;
    my $info_node = $self->_fetch_store_info_node;
    my $root = $info_node->get_root;
    unless( $root ) {
        $root = $self->newobj;
        $info_node->set_root( $root );
        $self->stow_all;
    }
    $root;
} #fetch_root

sub _fetch_store_info_node {
    my $self = shift;
    my $node = $self->_fetch( 1 );
    unless( $node ) {
        my $first_id = $self->_new_id;
        die "Fetch STORE INFO NODE must have ID of 1, got '$first_id'" unless $first_id == 1;
        my $now = time;
        $node = bless [ 1, {}, $self ], 'Yote::Obj';
        $node->set_db_version( $Yote::DB_VERSION );
        $node->set_yote_version( $Yote::VERSION );
        $node->set_created_time( $now );
        $node->set_last_update_time( $now );
        $self->stow_all;
    }

    # check to make sure that the db version is compatable with this.
    if( $node->get_db_version < $Yote::DB_VERSION ) {
        die "Unable to opening earlier database version ".($node->get_db_version || 'unknown').". Please run 'yote_db_convert $self->[PATH]'";
    }
    if( $node->get_db_version > $Yote::DB_VERSION ) {
        die "Unable to open more advance database version ".($node->get_db_version || 'unknown').". Upgrade yote to open";
    }

    $node;
} #_fetch_store_info_node

#
# Returns a hash of the info set for this store
#
sub info {
    my $node = shift->[STOREINFO];
    my $info = {
        map { $_ => $node->get($_)  }
        qw( db_version yote_version created_time last_update_time )
    };
    $info;
} #info

sub open_store {
    my( $cls, $base_path ) = @_;

    #
    # Yote subpackages are not normally in %INC and should always be loaded.
    #
    for my $pkg ( qw( Yote::Obj Yote::Array Yote::Hash ) ) {
        $INC{ $pkg } or eval("use $pkg");
    }

    my $store = bless [
        Data::RecordStore->open( "$base_path/RECORDSTORE" ),
        {}, #DIRTY CACHE
        {},  #WEAK CACHE
        $base_path
        ], $cls;

    $store->[STOREINFO] = $store->_fetch_store_info_node;

    $store;

} #open_store

sub newobj {
    # works with newobj( { my data } ) or newobj( 'myclass', { my data } )
    my $self = shift;
    my $data = pop;
    my $class = pop || 'Yote::Obj';

    my $id = $self->_new_id;
    my $obj = bless [ $id,
                      { map { $_ => $self->_xform_in( $data->{$_} ) } keys %$data},
                      $self ], $class;
    $self->_dirty( $obj, $id );
    $self->_store_weak( $id, $obj );
    $obj->_init(); #called the first time the object is created.
    $obj;
} #newobj

#
# Recycles and compacts store. IDs that were not found in the store
# are marked for reuse.
#
sub run_recycler {
    my $self = shift;
    $self->stow_all;
    my $base_path = $self->[PATH];
    my $recycle_tally = Data::RecordStore->open( "$base_path/RECYCLE" );

    # empty because this may have run recently
    $self->[RECORD_STORE]->empty_recycler;
    $recycle_tally->empty;

    $recycle_tally->stow( "1", 1 );
    $recycle_tally->stow( "0", $self->[RECORD_STORE]->entry_count );

    my $item = $self->fetch_root;

    # add the ids from the weak references
    my( @keep_ids ) = ( $item->id, keys %{$self->[WEAK]} );


    while( @keep_ids ) {
        my $id = shift @keep_ids;

        $item = $self->_fetch( $id );
        $recycle_tally->stow( 1, $id );
        my $ref = ref($item);
        if( $item eq 'Yote::Array' ) {
            my $tied = tied( @$item );
            my $data = $tied->[DATA];
            push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } @$data;
        }
        elsif( $item eq 'Yote::Hash' ) {
            my $tied = tied( %$item );
            my $data = $tied->[DATA];
            if( $tied->[LEVEL] == 0 ) {
                push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } values %$data;
            } else {
                push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } @$data;
            }
        }
        elsif( $ref eq 'ARRAY' ) {
            my $tied = tied( @$item );
            if( $tied ) {
                my $data = $tied->[DATA];
                push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } @$data;
            } else {
                push @keep_ids, grep { $recycle_tally->fetch($_) != 1 } map { $self->_get_id($_) } grep { ref( $_ ) } @$item;
            }
        }
        elsif( $ref eq 'HASH' ) {
            my $tied = tied( %$item );
            if( $tied ) {
                my $data = $tied->[DATA];
                if( $tied->[LEVEL] == 0 ) {
                    push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } values %$data;
                } else {
                    push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch( $_ ) != 1 } @$data;
                }
            } else {
                push @keep_ids, grep { $recycle_tally->fetch($_) != 1 } map { $self->_get_id($_) } grep { ref( $_ ) } values %$item;
            }
        }
        else {
            push @keep_ids, grep { $_ > 1 && $recycle_tally->fetch($_) != 1 } values %{$item->[DATA]};
        }
    } #going through all keep_ids
    undef $item;

    my $record_store = $self->[RECORD_STORE];
    my $count = $record_store->entry_count;
    for( my $i=1; $i<=$count; $i++ ) {
        if( $recycle_tally->fetch($i) != 1 ) {
            $record_store->recycle_id( $i );
        }
    }
    # empty to save space
    $recycle_tally->empty;
} #run_recycler

sub stow_all {
    my $self = shift;
    for my $id ( keys %{$self->[DIRTY]} ) {
        my $obj = $self->[DIRTY]{$id};
        next unless $obj;
        my $cls = ref( $obj );

        my $thingy = $cls eq 'HASH' ? tied( %$obj ) : $cls eq 'ARRAY' ?  tied( @$obj ) : $obj;
        my $text_rep = $thingy->_freezedry;
        my $class = ref( $thingy );


        $self->[RECORD_STORE]->stow( "$class $text_rep", $id );
    }
    $self->[DIRTY] = {};

} #stow_all

sub _fetch {
    my( $self, $id ) = @_;
    return undef unless $id && $id ne 'u';

    my $ref = $self->[DIRTY]{$id} //$self->[WEAK]{$id};
    return $ref if $ref;

    my $stowed = $self->[RECORD_STORE]->fetch( $id );

    return undef unless $stowed;

    my $pos = index( $stowed, ' ' );
    die "Malformed record '$stowed'" if $pos == -1;

    my $class    = substr $stowed, 0, $pos;
    my $dryfroze = substr $stowed, $pos + 1;

    unless( $INC{ $class } ) {
        eval("use $class");
    }

    # so foo` or foo\\` but not foo\\\`
    # also this will never start with a `
    my $pieces = [ split /\`/, $dryfroze, -1 ];

    # check to see if any of the parts were split on escapes
    # like  mypart`foo`oo (should be translated to mypart\`foo\`oo
    if ( 0 < grep { /\\$/ } @$pieces ) {
        my $newparts = [];

        my $is_hanging = 0;
        my $working_part = '';

        for my $part (@$pieces) {

            # if the part ends in a hanging escape
            if ( $part =~ /(^|[^\\])((\\\\)+)?[\\]$/ ) {
                if ( $is_hanging ) {
                    $working_part .= "`$part";
                } else {
                    $working_part = $part;
                }
                $is_hanging = 1;
            } elsif ( $is_hanging ) {
                my $newpart = "$working_part`$part";
                $newpart =~ s/\\`/`/gs;
                $newpart =~ s/\\\\/\\/gs;
                push @$newparts, $newpart;
                $is_hanging = 0;
            } else {
                # normal part
                push @$newparts, $part;
            }
        }
        if ( $is_hanging ) {
            die "Error in parsing parts\n";
        }
        $pieces = $newparts;
    } #if there were escaped ` characters

    my $ret = $class->_reconstitute( $self, $id, $pieces );
    $self->_store_weak( $id, $ret );
    return $ret;
} #_fetch

sub _xform_in {
    my( $self, $val ) = @_;
    if( ref( $val ) ) {
        return $self->_get_id( $val );
    }
    return defined $val ? "v$val" : 'u';
}

sub _xform_out {
    my( $self, $val ) = @_;
    return undef unless defined( $val ) && $val ne 'u';
    if( index($val,'v') == 0 ) {
        return substr( $val, 1 );
    }
    return $self->_fetch( $val );
}

sub _store_weak {
    my( $self, $id, $ref ) = @_;
    die "Store weak called without ref" unless $ref;
    $self->[WEAK]{$id} = $ref;

    weaken( $self->[WEAK]{$id} );
} #_store_weak

sub _dirty {
    return unless $_[1];
    $_[0]->[DIRTY]->{$_[2]} = $_[1];
} #_dirty


sub _new_id {
    my( $self ) = @_;
    $self->[RECORD_STORE]->next_id;
} #_new_id

sub _get_id {
    my( $self, $ref ) = @_;

    my $class = ref( $ref );

    die "_get_id requires reference. got '$ref'" unless $class;

    if( $class eq 'ARRAY' ) {
        my $thingy = tied @$ref;
        if( ! $thingy ) {
            my $id = $self->_new_id;
            tie @$ref, 'Yote::Array', $self, $id, 0, $Yote::Array::MAX_BLOCKS, scalar(@$ref), 0, map { $self->_xform_in($_) } @$ref;
            $self->_store_weak( $id, $ref );
            $self->_dirty( $self->[WEAK]{$id}, $id );
            return $id;
        }
        $ref = $thingy;
        $class = ref( $ref );
    }
    elsif( $class eq 'HASH' ) {
        my $thingy = tied %$ref;
        if( ! $thingy ) {
            my $id = $self->_new_id;
            my( @keys ) = keys %$ref;
            tie %$ref, 'Yote::Hash', $self, $id, undef, undef, scalar(@keys), map { $_ => $self->_xform_in($ref->{$_}) } @keys;
            $self->_store_weak( $id, $ref );
            $self->_dirty( $self->[WEAK]{$id}, $id );
            return $id;
        }
        $ref = $thingy;
        $class = ref( $ref );
    }
    die "Cannot injest object that is not a hash, array or yote obj" unless ( $class eq 'Yote::Hash' || $class eq 'Yote::Array' || $ref->isa( 'Yote::Obj' ) );
    $ref->[ID] ||= $self->_new_id;
    return $ref->[ID];

} #_get_id

# --------------------------------------------------------------------------------

package Yote::Array;


##################################################################################
# This module is used transparently by Yote to link arrays into its graph        #
# structure. This is not meant to be called explicitly or modified.              #
##################################################################################

use strict;
use warnings;
use warnings FATAL => 'all';
no  warnings 'numeric';
no  warnings 'uninitialized';
#no  warnings 'recursion';

use Tie::Array;

$Yote::Array::MAX_BLOCKS = 1_000_000;

use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
    LEVEL       => 3,
    BLOCK_COUNT => 4,
    BLOCK_SIZE  => 5,
    ITEM_COUNT  => 6,
    UNDERNEATH  => 7,

    WEAK         => 2,
};

sub _freezedry {
    my $self = shift;
    my @items;
    my $stuff_count = $self->[BLOCK_COUNT] > $self->[ITEM_COUNT] ? $self->[ITEM_COUNT] : $self->[BLOCK_COUNT];
    if( $stuff_count > 0 ) {
        @items = map { if( defined($_) && $_=~ /[\\\`]/ ) { $_ =~ s/[\\]/\\\\/gs; s/`/\\`/gs; } defined($_) ? $_ : 'u' } map { $self->[DATA][$_] } (0..($stuff_count-1));
    }

    join( "`",
          $self->[LEVEL] || 0,
          $self->[BLOCK_COUNT] || 0,
          $self->[ITEM_COUNT] || 0,
          $self->[UNDERNEATH] || 0,
          @items,
        );
}

sub _reconstitute {
    my( $cls, $store, $id, $data ) = @_;
    my $arry = [];
    tie @$arry, $cls, $store, $id, @$data;

    return $arry;
}

sub TIEARRAY {
    my( $class, $obj_store, $id, $level, $block_count, $item_count, $underneath, @list ) = @_;

    my $block_size  = $block_count ** $level;

    die "DSFSOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO" if $block_size == 1&&$level > 0;
    die "NOO" if $block_count < 1;

    my $use_push = @list > $block_count;

    my $blocks = $use_push ? [] : [@list];
    $#$blocks = $block_count - 1;

    # once the array is tied, an additional data field will be added
    # so obj will be [ $id, $storage, $obj_store ]
    my $obj = bless [
        $id,
        $blocks,
        $obj_store,
        $level,
        $block_count,
        $block_size,
        $item_count,
        $underneath,
    ], $class;

    if( $use_push ) {
        $obj->[ITEM_COUNT] = 0;
        $obj->PUSH( map { $obj_store->_xform_out($_) } @list );
    }

    return $obj;
} #TIEARRAY

sub FETCH {
    my( $self, $idx ) = @_;

    if( $idx >= $self->[ITEM_COUNT] ) {
        return undef;
    }

    if( $self->[LEVEL] == 0 ) {
        return $self->[DSTORE]->_xform_out( $self->[DATA][$idx] );
    }

    my $block = $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) );
    if( $block ) {
        return $block->FETCH( $idx % $self->[BLOCK_SIZE] );
    }

    return undef;
} #FETCH

sub FETCHSIZE {
    shift->[ITEM_COUNT];
}

sub _embiggen {
    my( $self, $size ) = @_;
    my $store = $self->[DSTORE];
    while( $size > $self->[BLOCK_SIZE] * $self->[BLOCK_COUNT] ) {
        die "UNDERNATH $size > $self->[BLOCK_SIZE] * $self->[BLOCK_COUNT]" if $self->[UNDERNEATH];
        #
        # need to tie a new block, not use _getblock
        # becaues we do squirrely things with its tied guts
        #
        my $newblock = [];
        my $newid = $store->_new_id;
        tie @$newblock, 'Yote::Array', $store, $newid, $self->[LEVEL], $self->[BLOCK_COUNT], $self->[ITEM_COUNT], 1;
        $store->_store_weak( $newid, $newblock );
        $store->_dirty( $store->[WEAK]{$newid}, $newid );

        my $tied = tied @$newblock;
        $tied->[DATA] = [@{$self->[DATA]}];


        $self->[DATA] = [ $newid ];

        $self->[BLOCK_SIZE] *= $self->[BLOCK_COUNT];
        $self->[LEVEL]++;
        $store->_dirty( $store->[WEAK]{$self->[ID]}, $self->[ID] );
    }
} #_embiggen

#
# get a block at the given block index. Returns undef
# if there isn't one ther, or creates and returns
# one if passed do create
#
sub _getblock {
    my( $self, $block_idx ) = @_;

    my $block_id = $self->[DATA][$block_idx];
    my $store = $self->[DSTORE];

    if( $block_id > 0 ) {
        my $block = $store->_fetch( $block_id );
        return tied(@$block)||$block;
        return wantarray ? ($block, tied( @$block )) : tied( @$block );
    }

    $block_id = $store->_new_id;
    my $block = [];
    my $level = $self->[LEVEL] - 1;
    tie @$block, 'Yote::Array', $store, $block_id, $level, $self->[BLOCK_COUNT];

    my $tied = tied( @$block );
    $tied->[UNDERNEATH] = 1;
    if( $block_idx >= ($self->[BLOCK_COUNT] - 1 ) ) {
        $tied->[ITEM_COUNT] = $self->[BLOCK_SIZE];
    }

    $store->_store_weak( $block_id, $block );
    $store->_dirty( $store->[WEAK]{$block_id}, $block_id );
    $store->_dirty( $store->[WEAK]{$self->[ID]}, $self->[ID] );
    $self->[DATA][$block_idx] = $block_id;
    return $tied;
    return wantarray ? ($block, $tied) : $tied;

} #_getblock

sub STORE {
    my( $self, $idx, $val ) = @_;

    if( $idx >= $self->[BLOCK_COUNT]*$self->[BLOCK_SIZE] ) {
        $self->_embiggen( $idx + 1 );
        $self->STORE( $idx, $val );
        return;
    }

    if( $idx >= $self->[ITEM_COUNT] ) {
        $self->_storesize( $idx + 1 );
        my $store = $self->[DSTORE];
        $store->_dirty( $store->[WEAK]{$self->[ID]}, $self->[ID] );
    }

    if( $self->[LEVEL] == 0 ) {
        $self->[DATA][$idx] = $self->[DSTORE]->_xform_in( $val );
        my $store = $self->[DSTORE];
        $store->_dirty( $store->[WEAK]{$self->[ID]}, $self->[ID] );
        return;
    }

    my $block = $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) );
    $block->STORE( $idx % $self->[BLOCK_SIZE], $val );

} #STORE

sub _storesize {
    my( $self, $size ) = @_;
    die "BADSET in ID $self->[ID] $size > $self->[BLOCK_COUNT] * $self->[BLOCK_SIZE] " if $size > $self->[BLOCK_COUNT] * $self->[BLOCK_SIZE];
    $self->[ITEM_COUNT] = $size;
}

sub STORESIZE {
    my( $self, $size ) = @_;

    $size = 0 if $size < 0;


    # fixes the size of the array if the array were to shrink
    my $current_oversize = $self->[ITEM_COUNT] - $size;
    if( $current_oversize > 0 ) {
        $self->SPLICE( $size, $current_oversize );
    } #if the array shrinks

    $self->_storesize( $size );

} #STORESIZE

sub EXISTS {
    my( $self, $idx ) = @_;
    if( $idx >= $self->[ITEM_COUNT] ) {
        return 0;
    }
    if( $self->[LEVEL] == 0 ) {
        return exists $self->[DATA][$idx] && $self->[DATA][$idx] ne 'u';
    }
    return $self->_getblock( int( $idx / $self->[BLOCK_SIZE] ) )->EXISTS( $idx % $self->[BLOCK_SIZE] );

} #EXISTS

sub DELETE {
    my( $self, $idx ) = @_;

    # if the last one was removed, shrink until there is a
    # defined value
    if( $idx < 0 ) {
        $idx = $self->[ITEM_COUNT] + $idx;
    }
    my $del = $self->FETCH( $idx );
    $self->STORE( $idx, undef );
    if( $idx == $self->[ITEM_COUNT] - 1 ) {
        $self->[ITEM_COUNT]--;
        while( $self->[ITEM_COUNT] > 0 && ! defined( $self->FETCH( $self->[ITEM_COUNT] - 1 ) ) ) {
            $self->[ITEM_COUNT]--;
        }

    }
    $self->[DSTORE]->_dirty( $self->[DSTORE]->[WEAK]{$self->[ID]}, $self->[ID] );

    return $del;

} #DELETE

sub CLEAR {
    my $self = shift;
    if( $self->[ITEM_COUNT] > 0 ) {
        $self->[ITEM_COUNT] = 0;
        $self->[DATA] = [];
        $self->[DSTORE]->_dirty( $self->[DSTORE]->[WEAK]{$self->[ID]}, $self->[ID] );
    }
}
sub PUSH {
    my( $self, @vals ) = @_;
    return unless @vals;
    $self->SPLICE( $self->[ITEM_COUNT], 0, @vals );
}
sub POP {
    my $self = shift;
    my $idx = $self->[ITEM_COUNT] - 1;
    my $pop = $self->FETCH( $idx );
    $self->STORE( $idx, undef );
    $self->[ITEM_COUNT]--;
    return $pop;
}
sub SHIFT {
    my( $self ) = @_;
    return undef unless $self->[ITEM_COUNT];
    my( $ret ) =  $self->SPLICE( 0, 1 );
    $ret;
}

sub UNSHIFT {
    my( $self, @vals ) = @_;
    return unless @vals;
    return $self->SPLICE( 0, 0, @vals );
}

sub SPLICE {
    my( $self, $offset, $remove_length, @vals ) = @_;

    # if negative, the offset is from the end
    if( $offset < 0 ) {
        $offset = $self->[ITEM_COUNT] + $offset;
    }

    # if negative, remove everything except the abs($remove_length) at
    # the end of the list
    if( $remove_length < 0 ) {
        $remove_length = ($self->[ITEM_COUNT] - $offset) + $remove_length;
    }

    return undef unless $remove_length || @vals;

    # check for removal past end
    if( $offset > ($self->[ITEM_COUNT] - 1) ) {
        $remove_length = 0;
        $offset = $self->[ITEM_COUNT];
    }
    if( $remove_length > ($self->[ITEM_COUNT] - $offset) ) {
        $remove_length = $self->[ITEM_COUNT] - $offset;
    }

    #
    # embiggen to delta size if this would grow. Also use the
    # calculated size as a check for correctness.
    #
    my $new_size = $self->[ITEM_COUNT];
    $new_size -= $remove_length;
    if( $new_size < 0 ) {
        $new_size = 0;
    }
    $new_size += @vals;

    if( $new_size > $self->[BLOCK_SIZE] * $self->[BLOCK_COUNT] ) {
        $self->_embiggen( $new_size );
    }

    my $BLOCK_COUNT = $self->[BLOCK_COUNT];
    my $store       = $self->[DSTORE];
    my $BLOCK_SIZE  = $self->[BLOCK_SIZE]; # embiggen may have changed this, so dont set this before the embiggen call

    if( $self->[LEVEL] == 0 ) {
        # lowest level, must fit in the size. The end recursion and easy case.
        my $blocks = $self->[DATA];
        my @raw_return = splice @$blocks, $offset, $remove_length, map { $store->_xform_in($_) } @vals;
        my @ret = map { $store->_xform_out($_) } @raw_return;
        $self->_storesize( $new_size );
        $store->_dirty( $store->[WEAK]{$self->[ID]}, $self->[ID] );
        return @ret;
    }

    my( @removed );
    while( @vals && $remove_length ) {
        #
        # harmony case. doesn't change the size. eats up vals and remove length
        # until one is zero
        #
        push @removed, $self->FETCH( $offset );
        $self->STORE( $offset++, shift @vals );
        $remove_length--;
    }

    if( $remove_length ) {
        my $last_idx = $self->[ITEM_COUNT] - 1;

        for( my $idx=$offset; $idx<($offset+$remove_length); $idx++ ) {
            push @removed, $self->FETCH( $idx );
        }

        my $things_to_move = $self->[ITEM_COUNT] - ($offset+$remove_length);
        my $to_idx = $offset;
        my $from_idx = $to_idx + $remove_length;
        for( 1..$things_to_move ) {
            $self->STORE( $to_idx, $self->FETCH( $from_idx ) );
            $to_idx++;
            $from_idx++;
        }
    } # has things to remove

    if( @vals ) {
        #
        # while there are any in the insert list, grab all the items in the next block if any
        #    and append to the insert list, then splice in the insert list to the beginning of
        #    the block. There still may be items in the insert list, so repeat until it is done
        #

        my $block_idx = int( $offset / $BLOCK_SIZE );
        my $block_off = $offset % $BLOCK_SIZE;

        while( @vals && ($self->[ITEM_COUNT] > $block_idx*$BLOCK_SIZE+$block_off) ) {
            my $block = $self->_getblock( $block_idx );
            my $bubble_size = $block->FETCHSIZE - $block_off;
            if( $bubble_size > 0 ) {
                my @bubble = $block->SPLICE( $block_off, $bubble_size );
                push @vals, @bubble;
            }
            my $can_insert = @vals > ($BLOCK_SIZE-$block_off) ? ($BLOCK_SIZE-$block_off) : @vals;
            if( $can_insert > 0 ) {
                $block->SPLICE( $block_off, 0, splice( @vals, 0, $can_insert ) );
            }
            $block_idx++;
            $block_off = 0;
        }
        while( @vals ) {
            my $block = $self->_getblock( $block_idx );
            my $remmy = $BLOCK_SIZE - $block_off;
            if( $remmy > @vals ) { $remmy = @vals; }

            $block->SPLICE( $block_off, $block->[ITEM_COUNT], splice( @vals, 0, $remmy) );
            $block_idx++;
            $block_off = 0;
        }

    } # has vals

    $self->_storesize( $new_size );

    return @removed;

} #SPLICE

sub EXTEND {
}

sub DESTROY {
    my $self = shift;
    delete $self->[DSTORE]->[WEAK]{$self->[ID]};
}

# --------------------------------------------------------------------------------

package Yote::Hash;

##################################################################################
# This module is used transparently by Yote to link hashes into its              #
# graph structure. This is not meant to  be called explicitly or modified.       #
##################################################################################

use strict;
use warnings;

no warnings 'uninitialized';
no warnings 'numeric';

use Tie::Hash;

$Yote::Hash::SIZE = 977;

use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
    LEVEL       => 3,
    BUCKETS     => 4,
    SIZE        => 5,
    NEXT        => 6,
};
sub _freezedry {
    my $self = shift;
    my $r = $self->[DATA];
    join( "`",
          $self->[LEVEL],
          $self->[BUCKETS],
          $self->[SIZE],
          map { if( defined($_) ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } defined($_) ? $_ : 'u' } $self->[LEVEL] ? @$r : %$r
      );
}

sub _reconstitute {
    my( $cls, $store, $id, $data ) = @_;
    my $hash = {};
    tie %$hash, $cls, $store, $id, @$data;
    return $hash;
}

sub TIEHASH {
    my( $class, $obj_store, $id, $level, $buckets, $size, @fetch_buckets ) = @_;
    $level ||= 0;
    $size  ||= 0;
    $buckets ||= $Yote::Hash::SIZE;
    my $hash;
    if( $level == 0 && $size > $buckets ) {
        # this case is where a hash is initialized the first time with more items than buckets.
        $hash = bless [ $id, {}, $obj_store, 0, $buckets, 0, [undef,undef] ], $class;
        while( @fetch_buckets ) {
            my $k = shift @fetch_buckets;
            my $v = shift @fetch_buckets;
            $hash->STORE( $k, $obj_store->_xform_out($v) );
        }
    }
    else {
        $hash = bless [ $id, $level ? [@fetch_buckets] : {@fetch_buckets}, $obj_store, $level, $buckets, $size, [undef,undef] ], $class;
    }

    $hash;
}

sub CLEAR {
    my $self = shift;
    if( $self->[SIZE] > 0 ) {
        $self->[SIZE] = 0;
        my $store = $self->[DSTORE];
        $store->_dirty( $store->[Yote::ObjStore::WEAK]{$self->[ID]}, $self->[ID] );
        %{$self->[DATA]} = ();
    }
}

sub DELETE {
    my( $self, $key ) = @_;

    return undef unless $self->EXISTS( $key );

    $self->[SIZE]--;

    my $data = $self->[DATA];
    my $store = $self->[DSTORE];

    if( $self->[LEVEL] == 0 ) {
        $store->_dirty( $store->[Yote::ObjStore::WEAK]{$self->[ID]}, $self->[ID] );
        return $store->_xform_out( delete $data->{$key} );
    } else {
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        return $self->[DSTORE]->_fetch( $data->[$hval] )->DELETE( $key );
    }
    return undef;
} #DELETE


sub EXISTS {
    my( $self, $key ) = @_;

    if( $self->[LEVEL] == 0 ) {
        return exists $self->[DATA]{$key} && $self->[DATA]{$key} ne 'u';
    } else {
        my $data = $self->[DATA];
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash_id = $data->[$hval];
        if( $hash_id > 0 ) {
            my $hash = $self->[DSTORE]->_fetch( $hash_id );
            my $tied = tied %$hash;
            return $tied->EXISTS( $key );
        }

    }
    return 0;
} #EXISTS

sub FETCH {
    my( $self, $key ) = @_;
    my $data = $self->[DATA];

    if( $self->[LEVEL] == 0 ) {
        return $self->[DSTORE]->_xform_out( $data->{$key} );
    } else {
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash_id = $data->[$hval];
        if( $hash_id > 0 ) {
            my $hash = $self->[DSTORE]->_fetch( $hash_id );
            my $tied = tied %$hash;
            return $tied->FETCH( $key );
        }
    }
    return undef;
} #FETCH

sub _SHOW {
    my( $self, $lvl ) = @_;
    if( $self->[LEVEL] == 0 ) {
        print STDERR (" " x $lvl ) . "($self->[ID]) : BASE SHOW : " . join( ',', keys %{$self->[DATA]} ) . "\n";
    } else {
        my( @ids ) = @{$self->[DATA]};
        print STDERR (" " x $lvl ) . "($self->[ID]) : subhashes : " . join( ',', map { "($_)" } @ids ) . "\n";
        for my $id (grep { $_ ne 'u' } @ids) {
            my $h = $self->[DSTORE]->_fetch( $id );
            tied( %$h )->SHOW( $lvl + 1 );;
        }
    }
}

sub STORE {
    my( $self, $key, $val ) = @_;

    my $data = $self->[DATA];

    #
    # EMBIGGEN TEST
    #
    my $newkey = ! $self->EXISTS( $key );
    if( $newkey ) {
        $self->[SIZE]++;
    }

    if( $self->[LEVEL] == 0 ) {
        $data->{$key} = $self->[DSTORE]->_xform_in( $val );

        if( $self->[SIZE] > $self->[BUCKETS] ) {

            # do the thing converting this to a deeper level
            $self->[LEVEL] = 1;
            my $store = $self->[DSTORE];
            my( @newhash, @newids );

            for my $key (keys %$data) {
                my $hval = 0;
                foreach (split //,$key) {
                    $hval = $hval*33 - ord($_);
                }
                $hval = $hval % $self->[BUCKETS];

                my $hash = $newhash[$hval];
                if( $hash ) {
                    my $tied = tied %$hash;
                    $tied->STORE( $key, $store->_xform_out($data->{$key}) );
                } else {
                    $hash = {};
                    my $hash_id = $store->_new_id;
                    tie %$hash, 'Yote::Hash', $store, $hash_id, 0, $self->[BUCKETS]+1, 1, $key, $data->{$key};
                    $store->_store_weak( $hash_id, $hash );
                    $store->_dirty( $store->[Yote::ObjStore::WEAK]{$hash_id}, $hash_id );

                    $newhash[$hval] = $hash;
                    $newids[$hval] = $hash_id;
                }

            }
            $self->[DATA] = \@newids;
            $data = $self->[DATA];
            # here is the problem. this isnt in weak yet!
            # this is a weak reference problem and the problem is at NEXTKEY with
            # LEVEL 0 hashes that are loaded from LEVEL 1 hashes that are loaded from
            # LEVEL 2 hashes. The level 1 hash is loaded and dumped as needed, not keeping
            # the ephermal info (or is that sort of chained..hmm)
            $store->_dirty( $store->[Yote::ObjStore::WEAK]{$self->[ID]}, $self->[ID] );

        } # EMBIGGEN CHECK

    } else {
        my $store = $self->[DSTORE];
        my $hval = 0;
        foreach (split //,$key) {
            $hval = $hval*33 - ord($_);
        }
        $hval = $hval % $self->[BUCKETS];
        my $hash_id = $data->[$hval];
        my $hash;
        if( $hash_id > 0 ) {
            $hash = $store->_fetch( $hash_id );
            my $tied = tied %$hash;
            $tied->STORE( $key, $val );
        } else {
            $hash = {};
            $hash_id = $store->_new_id;
            tie %$hash, 'Yote::Hash', $store, $hash_id, 0, $self->[BUCKETS]+1, 1, $key, $store->_xform_in( $val );
            $store->_store_weak( $hash_id, $hash );
            $store->_dirty( $store->[Yote::ObjStore::WEAK]{$hash_id}, $hash_id );
            $data->[$hval] = $hash_id;
        }
    }

} #STORE

sub FIRSTKEY {
    my $self = shift;

    my $data = $self->[DATA];
    if( $self->[LEVEL] == 0 ) {
        my $a = scalar keys %$data; #reset
        my( $k, $val ) = each %$data;
        return wantarray ? ( $k => $self->[DSTORE]->_xform_out( $val ) ) : $k;
    }
    $self->[NEXT] = [undef,undef];
    return $self->NEXTKEY;
}

sub NEXTKEY  {
    my $self = shift;
    my $data = $self->[DATA];
    my $lvl = $self->[LEVEL];
    if( $lvl == 0 ) {
        my( $k, $val ) = each %$data;
        return wantarray ? ( $k => $self->[DSTORE]->_xform_out($val) ) : $k;
    }
    else {
        my $store = $self->[DSTORE];

        my $at_start = ! defined( $self->[NEXT][0] );

        if( $at_start ) {
            $self->[NEXT][0] = 0;
            $self->[NEXT][1] = undef;
        }

        my $hash = $self->[NEXT][1];
        $at_start ||= ! $hash;
        unless( $hash ) {
            my $hash_id = $data->[$self->[NEXT][0]];
            $hash = $store->_fetch( $hash_id ) if $hash_id > 1;
        }

        if( $hash ) {
            my $tied = tied( %$hash );
            my( $k, $v ) = $at_start ? $tied->FIRSTKEY : $tied->NEXTKEY;
            if( defined( $k ) ) {
                $self->[NEXT][1] = $hash; #to keep the weak reference
                return wantarray ? ( $k => $v ) : $k;
            }
        }

        $self->[NEXT][1] = undef;
        $self->[NEXT][0]++;

        if( $self->[NEXT][0] > $#$data ) {
            $self->[NEXT][0] = undef;
            return undef;
        }
        # recursion case, the next bucket has been incremented
        return $self->NEXTKEY;
    }

    # really should be impossible to reach this case.
    die "Impossible case";
    $self->[NEXT] = [undef,undef];
    return undef;

} #NEXTKEY

sub DESTROY {
    my $self = shift;

    #remove all WEAK_REFS to the buckets
    undef $self->[DATA];

    delete $self->[DSTORE]->[Yote::ObjStore::WEAK]{$self->[ID]};
}

# --------------------------------------------------------------------------------

package Yote::Obj;

use strict;
use warnings;
no  warnings 'uninitialized';
no  warnings 'numeric';

use constant {
    ID          => 0,
    DATA        => 1,
    DSTORE      => 2,
};

#
# The string version of the yote object is simply its id. This allows
# object ids to easily be stored as hash keys.
#
use overload
    '""' => sub { shift->[ID] }, # for hash keys
    eq   => sub { ref($_[1]) && $_[1]->[ID] == $_[0]->[ID] },
    ne   => sub { ! ref($_[1]) || $_[1]->[ID] != $_[0]->[ID] },
    '=='   => sub { ref($_[1]) && $_[1]->[ID] == $_[0]->[ID] },
    '!='   => sub { ! ref($_[1]) || $_[1]->[ID] != $_[0]->[ID] },
    fallback => 1;

sub id {
    shift->[ID];
}

sub set {
    my( $self, $fld, $val ) = @_;

    my $inval = $self->[DSTORE]->_xform_in( $val );
    if( $self->[DATA]{$fld} ne $inval ) {
        $self->[DSTORE]->_dirty( $self, $self->[ID] );
    }

    unless( defined $inval ) {
        delete $self->[DATA]{$fld};
        return;
    }
    $self->[DATA]{$fld} = $inval;
    return $self->[DSTORE]->_xform_out( $self->[DATA]{$fld} );
} #set


sub get {
    my( $self, $fld, $default ) = @_;

    my $cur = $self->[DATA]{$fld};
    my $store = $self->[DSTORE];
    if( ( ! defined( $cur ) || $cur eq 'u' ) && defined( $default ) ) {
        if( ref( $default ) ) {
            # this must be done to make sure the reference is saved
            # for cases where the reference has not yet made it to the store of things to save
            $store->_dirty( $store->_get_id( $default ) );
        }
        $store->_dirty( $self, $self->[ID] );
        $self->[DATA]{$fld} = $store->_xform_in( $default );
    }
    return $store->_xform_out( $self->[DATA]{$fld} );
} #get


sub store {
    return shift->[DSTORE];
}

# -----------------------
#
#     Public Methods
# -----------------------
#
# Defines get_foo, set_foo, add_to_foolist, remove_from_foolist
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
            my $store = $self->[DSTORE];
            my $inval = $store->_xform_in( $val );
            $store->_dirty( $self, $self->[ID] ) if $self->[DATA]{$fld} ne $inval;
            unless( defined $inval ) {
                delete $self->[DATA]{$fld};
                return;
            }
            $self->[DATA]{$fld} = $inval;
            return $store->_xform_out( $self->[DATA]{$fld} );
        };
        use strict 'refs';
        goto &$AUTOLOAD;
    }
    elsif( $func =~ /:get_(.*)/ ) {
        my $fld = $1;
        no strict 'refs';
        *$AUTOLOAD = sub {
            my( $self, $init_val ) = @_;
            my $store = $self->[DSTORE];
            if( ( ! defined( $self->[DATA]{$fld} ) || $self->[DATA]{$fld} eq 'u' ) && defined($init_val) ) {
                if( ref( $init_val ) ) {
                    # this must be done to make sure the reference is saved for cases where the reference has not yet made it to the store of things to save
                    my $ref_id = $store->_get_id( $init_val );
                    $store->_dirty( $init_val, $ref_id );
                }
                $store->_dirty( $self, $self->[ID] );
                $self->[DATA]{$fld} = $store->_xform_in( $init_val );
            }
            return $store->_xform_out( $self->[DATA]{$fld} );
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
sub _freezedry {
    my $self = shift;
    join( "`", map { if( defined($_) ) { s/[\\]/\\\\/gs; s/`/\\`/gs; } defined($_) ? $_ : 'u' } %{$self->[DATA]} );
}

sub _reconstitute {
    my( $cls, $store, $id, $data ) = @_;
    my $obj = [$id,{@$data},$store];
    bless $obj, $cls;
    $obj->_load;
    $obj;
}

sub DESTROY {
    my $self = shift;

    delete $self->[DSTORE][Yote::ObjStore::WEAK]{$self->[ID]};
}

1;

__END__

=head1 NAME

Yote - Persistant Perl container objects in a directed graph of lazilly
loaded nodes.

=head1 DESCRIPTION

This is for anyone who wants to store arbitrary structured state data and
doesn't have the time or inclination to write a schema or configure some
framework. This can be used orthagonally to any other storage system.

Yote only loads data as it needs too. It does not load all stored containers
at once. Data is stored in a data directory and is stored using the Data::RecordStore module. A Yote container is a key/value store where the values can be
strings, numbers, arrays, hashes or other Yote containers.

The entry point for all Yote data stores is the root node.
All objects in the store are unreachable if they cannot trace a reference
path back to this node. If they cannot, running compress_store will remove them.

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
    someobj  => $store->newobj( { foo => "Bar" }, 'yote - class' );
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

=head2 open_store( '/path/to/directory' )

Starts up a persistance engine and returns it.

=head1 NAME

 Yote::ObjStore - manages Yote::Obj objects in a graph.

=head1 DESCRIPTION

The Yote::ObjStore does the following things :

 * fetches the root object
 * creates new objects
 * fetches existing objects by id
 * saves all new or changed objects
 * finds objects that cannot connect to the root node and removes them

=head2 fetch_root

 Returns the root node of the graph. All things that can be
trace a reference path back to the root node are considered active
and are not removed when the object store is compressed.

=cut

=head2 newobj( { ... data .... }, optionalClass )

 Creates a container object initialized with the
 incoming hash ref data. The class of the object must be either
 Yote::Obj or a subclass of it. Yote::Obj is the default.

 Once created, the object will be saved in the data store when
 $store->stow_all has been called.  If the object is not attached
 to the root or an object that can be reached by the root, it will be
 remove when Yote::ObjStore::Compress is called.

=head2 copy_from_remote_store( $obj )

 This takes an object that belongs to a seperate store and makes
 a deep copy of it.

=head2 cache_all()

 This turns on caching for the store. Any objects loaded will
 remain cached until clear_cache is called. Normally, they
 would be DESTROYed once their last reference was removed unless
 they are in a state that needs stowing.

=head2 uncache( obj )

  This removes the object from the cache if it was in the cache

=head2 pause_cache()

 When called, no new objects will be added to the cache until
 cache_all is called.

=head2 clear_cache()

 When called, this dumps the object cache. Objects that
 references or have changes that need to be stowed will
 not be cleared.

=cut
=head2 fetch( $id )

 Returns the object with the given id.

=cut


=head1 AUTHOR
       Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

       Copyright (c) 2017 Eric Wolf. All rights reserved.  This program is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=head1 VERSION
       Version 3.00  (Mar, 2018))

=cut
