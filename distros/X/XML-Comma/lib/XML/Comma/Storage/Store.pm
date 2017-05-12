##
#
#    Copyright 2001-2007, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Storage::Store;

@ISA = qw( XML::Comma::NestedElement
           XML::Comma::Configable
           XML::Comma::Hookable );
use vars '$AUTOLOAD';

use strict;
use XML::Comma::Util qw( dbg name_and_args_eval );
use XML::Comma::Storage::Util;
use XML::Comma::Storage::FileUtil;
use XML::Comma::Storage::Iterator;
use File::Path;
use File::Spec;

# _Store_file_permissions     : octal for permissions to set created files
# _Store_dir_permissions      : and for directories, manufactured from the above
# _Store_doctype
# _Store_locations
# _Store_outputs
# _Store_imported_methods     : hash holding { 'method-name', 'loc/out obj' }
# _Store_base_dir       : document_root + base

# handles locking and storage-info setting, because these two
# functions are dependent on id/location munging, so it makes sense to
# put them here, close together and close to where the munging
# happens.
sub read {
  my ( $self, $id, $read_args, $lock, $lock_no_wait, $lock_timeout ) = @_;
  my $location;
  if ( $id eq '+' ) {
    $location = $self->{_Store_locations}->[0]->last_location($self) || return;
    $id = $self->id_from_location ( $location );
  } elsif ( $id eq '-' ) {
    $location = $self->{_Store_locations}->[0]->first_location($self) || return;
    $id = $self->id_from_location ( $location );
  } else {
    $location = $self->location_from_id ( $id );
  }
  my $key = XML::Comma::Storage::Util->_concat_key
    ( $self->{_Store_doctype}, $self->name(), $id );
  my $doc;
  if ( $lock ) {
    return  if  ! XML::Comma->lock_singlet()->lock ( $key,
                                                     $lock_no_wait,
                                                     $lock_timeout );
  }
  eval {
    my $input_str = $self->{_Store_locations}->[0]->read($self, $location, $id);
    # pass through input filters
    foreach my $filter ( reverse @{$self->{_Store_outputs}} ) {
      $input_str = $filter->input ( $input_str );
    }
    # make doc unless the last filter has already returned us one
    if ( ref $input_str and ref $input_str eq 'XML::Comma::Doc' ) {
      $doc = $input_str;
    } else {
      my $validate = defined($read_args->{validate}) ? $read_args->{validate} : undef;
      delete($read_args->{validate});
      $doc = 
        XML::Comma::Doc->new ( block=>$input_str,
                               read_args => $read_args,
                               validate => $validate,
                               location=> $location,
                               id=> $id,
                               key=> $key,
                               lock=> $lock,
                               store_obj=> $self );
    }
    $doc->{_Doc_new} = 0; # blech, hack, yuck
  }; if ( $@ ) {
    my $error = $@;
    if ( $lock ) { eval { XML::Comma->lock_singlet()->unlock($key) }; }
    die "$error\n";
  }
  return $doc;
}

sub write {
  my ( $self, %arg ) = @_;
  # pre-store hooks
  unless ( $arg{no_hooks} || $arg{no_pre_store_hooks} ) {
    foreach my $sub ( @{$self->get_hooks_arrayref('pre_store_hook')} ) {
      $sub->( $arg{doc}, $self, \%arg );
    }
  }
  # validate structure
  $arg{doc}->validate();
  # do the store -- making a new id/location pair if we're called as 'anew'
  my ( $id, $location, $key );
  if ( $arg{anew} ) {
    ( $id, $location ) = $self->_make_id ( %arg );
    if ( $id eq 'COMMA_DB_SEQUENCE_SET' ) {
      $arg{doc}->set_storage_info ( undef, undef, $id );
    } else {
      $key = XML::Comma::Storage::Util->_concat_key
        ( $self->{_Store_doctype}, $self->name(), $id );
      my $locked = XML::Comma->lock_singlet()->lock ( $key );
      if ( ! $locked ) {
        XML::Comma::Log->err ( 'STORE_ERROR',
                               "fatal, could not lock new key ($key)" );
      } else {
        $arg{doc}->set_storage_info ( $self, $location, $id, $key, 1 );
        $arg{doc}->force_lock_flag_set();
      }
    }
  } else {
    $id = $arg{doc}->doc_id();
    $location = $arg{doc}->doc_location();
  }
  # pass through output filters
  my $output_str = $arg{doc}->to_string();
  foreach my $filter ( @{$self->{_Store_outputs}} ) {
    $output_str = $filter->output ( $output_str, $arg{doc} );
  }
  $self->{_Store_locations}->[0]->write ( $self,
                                          $location,
                                          $id,
                                          $output_str,
                                          $arg{doc} );
  # copy each blob from tmp filesystem into place -- blobs know
  # whether they've been updated or not, and only copy themselves if
  # needed.
  my $blobs_flag = 0;
  unless ( $arg{no_blobs} ) {
    foreach my $blob ( $arg{doc}->get_all_blobs_and_ghosts() ) {
      # print "MOVING: " . $blob->{_Blob_location} . "\n";
      $blobs_flag += $blob->store ( copy => $arg{anew} );
    }
    $arg{doc}->clear_ghosts_list();
  }
  # and now we need to store again, if we've copied some blobs,
  # because the locations will have changed. this is a bit of a hack
  # -- is there a way to handle this "second store" more elegantly?
  if ( $blobs_flag ) {
    $self->{_Store_locations}->[0]->write ( $self,
                                            $location,
                                            $id,
                                            $arg{doc}->to_string() );
  }
  # post-store hooks -- same as pre_store except we need to catch
  # errors and hold onto them, so that all hooks run and the doc gets
  # unlocked properly. we'll re-throw the first error we got after
  # we finish unlocking.
  my $post_store_error;
  unless ( $arg{no_hooks} || $arg{no_post_store_hooks} ) {
    foreach my $sub ( @{$self->get_hooks_arrayref('post_store_hook')} ) {
      #$sub->( $arg{doc}, $self, \%arg );
      eval { $sub->( $arg{doc}, $self, \%arg ); };
      $post_store_error = $@  if  ( $@ and ! $post_store_error );
    }
  }
  # unlock
  $arg{doc}->doc_unlock()  unless  $arg{keep_open};
  # throw error if necessary
  XML::Comma::Log->err ( 'POST_STORE_ERROR', $post_store_error )  if
      $post_store_error;
  return 1;
}

# id => doc id
# key => doc key
# type => doc type
# store => name of store
# no_hooks => don't run store_hooks if true
# doc_string => string block that is the new doc
# blobs_local_files => flag (1) saying that we can treat this as a move between
#              two local stores, that we'll do set_from_file for blob content,
#              rather than get it from the blobs_hash below
# blobs => { blob_location_from_doc_string => blob_content }
sub force_store {
  my ( $self, %args ) = @_;
  my $anew = ! $args{id};
  my $location = '';
  # if we're given an id, erase the doc (if it exists) and figure out
  # a storage location
  if ( $args{id} ) {
    my $doc;
    eval {
      $doc = XML::Comma::Doc->retrieve ( type => $self->{_Store_doctype},
                                         store => $self->name(),
                                         id => $args{id} )
    };
    $doc->erase()  if  $doc;
    # now, derive location
    $location = $self->location_from_id ( $args{id} );
    # call make_directory, which won't do anything if the directory
    # already exists. make a lock file, but you really should be careful
    # about force_storing and regular storing in the same directory
    my ( $volume, $directories, $file ) = File::Spec->splitpath ( $location );
    XML::Comma::Storage::FileUtil->make_directory ( $self, $directories, 1 );
  }
  # any blobs from remote need to exist before we call doc->new
#XML::Comma::Log->warn("about to set blobs");
  unless ( $args{blobs_local_files} ) {
    foreach my $blob ( keys %{$args{blobs}} ) {
      next unless $blob; #TODO: trace down why this is happening...
#XML::Comma::Log->warn("setting blob: $blob");
      open (my $fh, ">$blob") || die "TODO: proper error message: $@";
      print $fh $args{blobs}->{$blob};
      close($fh) || die "TODO: proper error message: $@";
    }
  }
#XML::Comma::Log->warn("done setting blobs");
  # make the doc
  my $doc = XML::Comma::Doc->new ( block => $args{doc_string}, no_read_hooks => 1 );
  # set storage info
  $doc->set_storage_info ( $self, $location, $args{id}, $args{key} );
  # write
  $self->write ( doc => $doc,
                 anew => $anew,
                 no_hooks => 1,
                 no_blobs => 1,
                 keep_open => 1 );
  # and walk through the blobs, clearing and resetting according to
  # either our local references or the passed list
  foreach my $blob ( $doc->get_all_blobs() ) {
    if ( $args{blobs_local_files} ) {
      my $filename = $blob->get_location;
      $blob->clear_location;
      print "resetting and copying: " . $filename . "\n";
      $blob->set_from_file ( $filename );
    } else {
#			#this should already have been done by first blob loop
#			my $send_side_filename = $blob->get_location();
#			$blob->set();
#			$blob->set ( $args{blobs}->{$send_side_filename},
#									 filename => $send_side_filename );
    }
  }
  $doc->store ( no_hooks => $args{no_hooks} );
  return $doc;
}

# takes same (but more limited) set of args as above
sub force_erase {
  my ( $self, %args ) = @_;
  my $doc;
  eval {
    $doc = XML::Comma::Doc->retrieve ( type => $self->{_Store_doctype},
                                       store => $self->name(),
                                       id => $args{id} )
  }; # if ( $@ ) { print STDERR "force erase error: $@\n"; }
  if ( $doc ) {
    $doc->erase();
    return $args{key};
  }
  return '';
}

## FIX -- remove this when the deprecated HTTP_Upload stuff finally goes away
sub put_store {
  my ( $self, %arg ) = @_;
  my $id = $arg{id};
  my $doc_string = $arg{doc_string};
  my $blobs = $arg{blobs};
  my $hash = $arg{comma_hash};
  # first, try to erase the doc, if it exists
  my $doc = eval { XML::Comma::Doc->retrieve ( type => $self->{_Store_doctype},
                                               storage => $self->name(),
                                               id => $id ); };
  $doc->erase() if $doc;
  # now, we need to try to put the file in the right place, then do
  # the retrieve again
  my $location = $self->location_from_id ( $id );
  # if necessary, do a mkpath (but don't make a lock file, the
  # principle being that you really shouldn't be put_store()ing and
  # store()ing in the same directory)
  my ( $volume, $directories, $file ) = File::Spec->splitpath ( $location );
  XML::Comma::Storage::FileUtil->make_directory ( $self, $directories, 0 );
  # do the write
  $self->{_Store_locations}->[0]->write ( $self,
                                          $location,
                                          $id,
                                          $doc_string );
  # retrieve again
  $doc = eval { XML::Comma::Doc->retrieve ( type => $self->{_Store_doctype},
                                            store => $self->name(),
                                            id => $id ); };
  if ( $@ ) { XML::Comma::Log->err ( 'PUT_STORE_ERR', $@ ); }
  # and walk through the blobs, clearing and re-setting them according
  # to the passed list.
  my @blobs = $doc->get_all_blobs();
  foreach my $blob ( @blobs ) {
    my $send_side_filename = $blob->get_location();
    $blob->set();
    $blob->set ( $arg{blobs}->{$send_side_filename} );
  }
  $doc->store();
  return $doc->comma_hash eq $hash;
}


sub erase {
  my ( $self, $doc, $location, $leave_blobs ) = @_;
  foreach my $sub ( @{$self->get_hooks_arrayref('erase_hook')} ) {
    $sub->( $doc, $self, $location );
  }
  $self->{_Store_locations}->[0]->erase ( $location, $doc );
  # erase all blob files.
  foreach my $blob ( $doc->get_all_blobs_and_ghosts() ) {
    $blob->scrub();
  }
  $doc->clear_ghosts_list();
}

sub read_blob {
  return $_[0]->{_Store_locations}->[0]->read_blob ( @_ );
}

sub write_blob {
  return $_[0]->{_Store_locations}->[0]->write_blob ( @_ );
}

sub copy_to_blob {
  return $_[0]->{_Store_locations}->[0]->copy_to_blob ( @_ );
}

sub erase_blob {
  return $_[0]->{_Store_locations}->[0]->erase_blob ( @_ );
}

sub touch {
  return $_[0]->{_Store_locations}->[0]->touch ( @_ );
}

sub last_modified {
  return $_[0]->{_Store_locations}->[0]->last_modified ( @_ );
}

sub _make_id {
  my ( $self, %arg ) = @_;
  my $i = $#{$self->{_Store_locations}};
  my @locs = ( $self->base_directory() );
  my @ids; my $loc; my $id;
  my $struct = { store       => $self,
                 doc         => $arg{doc},
                 locs        => \@locs,
                 ids         => \@ids,
                 overflow    => 0 };
  eval {
    while ( $i >= 0 ) {
      ( $id, $loc ) = $self->{_Store_locations}->[$i]->make_id ( $struct );
      if ( ! defined $loc ) {
        # overflow, drop ends off locs and ids and back up a step
        die "storage full (top level)\n" if $i == $#{$self->{_Store_locations}};
        $i++; pop @locs; pop @ids;
        $struct->{overflow} = 1;
      } else {
        # okay so far, add to locs and ids lists
        $i--; push @locs, $loc; push @ids, $id;
        $struct->{overflow} = 0;
      }
    }
  }; if ( $@ ) { die "make id error: $@"; }
  return ( $id, $loc );
}

sub location_from_id {
  my ( $self, $id ) = @_;
  my $lstring = $self->base_directory();
  foreach my $location ( reverse @{$self->{_Store_locations}} ) {
    ( $id, $lstring ) = $location->location_from_id ( $self, $id, $lstring );
  }
  return $lstring;
}

sub id_from_location {
  my ( $self, $lstring ) = @_;
  #dbg 'ls', $lstring || '', 'bd', $self->base_directory() || '';
  $lstring =~ /^${ \($self->base_directory()) }/ ||
    die "bad location '$lstring'\n";
  $lstring = File::Spec->abs2rel ( $lstring, $self->base_directory() );
  my $id = '';
  foreach my $location ( reverse @{$self->{_Store_locations}} ) {
    ( $id, $lstring ) = $location->id_from_location ( $self, $id, $lstring );
  }
  return $id;
}

sub first_id {
  return $_[0]->id_from_location
    ( $_[0]->{_Store_locations}->[0]->first_location($_[0]) );
}

sub last_id {
  return $_[0]->id_from_location
    ( $_[0]->{_Store_locations}->[0]->last_location($_[0]) );
}

sub next_id {
  my ( $self, $id, $direction ) = @_;
  # --> location
  my $location = $self->location_from_id ( $id );
  # call [0]'s next_location
  my $next = $self->{_Store_locations}->[0]->next_location ( $self,
                                                             $location,
                                                             $direction );
  # return -->id  or  undef
  return (defined $next) ? $self->id_from_location($next) : undef;
}

sub prev_id {
  $_[0]->next_id ( $_[1], -1 );
}

sub iterator {
  my $self = shift();
  XML::Comma::Storage::Iterator->new ( store => $self, @_ );
}

sub doctype {
  return $_[0]->{_Store_doctype};
}

sub base_directory {
  return $_[0]->{_Store_base_dir};
}

sub file_permissions {
  return $_[0]->{_Store_file_permissions};
}

sub dir_permissions {
  return $_[0]->{_Store_dir_permissions};
}

sub def_name {
  return $_[0]->{_Store_doctype};
}

#this just calls associated_indices for people who spell different
sub associated_indexes {
  my ($self, @args) = @_;
  $self->associated_indices(@args);
}

sub associated_indices {
  my $ios = $_[0]->{_index_on_stores};
  return (defined($ios) && @$ios ? @$ios : ());
}

sub init_and_cast {
  my ( $self, $document_type ) = @_;
  $self->{_Store_doctype} = $document_type;
  # bless this element into this class
  bless ( $self, 'XML::Comma::Storage::Store' );
  # our hooks
  $self->allow_hook_type ( 'pre_store_hook',
                           'post_store_hook',
                           'erase_hook' );
  $self->{_Store_base_dir} =
    File::Spec->catdir ( $self->element('root')->get() ||
                           XML::Comma->document_root(),
                         $self->element('base')->get() );
  # might as well set up _file_permissions stuff here -- get file
  # permissions from the appropriate element (which has a default
  # value in the bootstrap, so we can count on it. manufacture
  # directory permissions by making any writable chunk also
  # x-able.
  $self->{_Store_file_permissions} = 
    oct $self->element('file_permissions')->get();
  my $mask = $self->{_Store_file_permissions} & 0444;
  $self->{_Store_dir_permissions} =
    $self->{_Store_file_permissions} | ($mask >> 2);
  # run the config dispatcher
  $self->_config_dispatcher();
  return $self;
}

sub _config__pre_store_hook {
  my ( $self, $el ) = @_;
  $self->add_hook ( 'pre_store_hook', $el->get() );
}

sub _config__post_store_hook {
  my ( $self, $el ) = @_;
  $self->add_hook ( 'post_store_hook', $el->get() );
}

sub _config__erase_hook {
  my ( $self, $el ) = @_;
  $self->add_hook ( 'erase_hook', $el->get() );
}

sub _config__location {
  my ( $self, $el ) = @_;
  $self->{_Store_locations} ||= [];
  $self->{_Store_imported_methods} ||= {};
  eval {
    my ( $name, %args ) = name_and_args_eval( $el->get() );
    my $class = "XML::Comma::Storage::Location::$name";
    eval "use $class"; die "couldn't use location '$name': $@\n" if $@;
    # make a new location object, passing it the %args that were
    # parsed out of the element-string, and an "index" indicating its
    # position in the declared location list, to use as a
    # secondary sort criterion.
    my ( $object, @method_names ) =
      $class->new ( %args,
                    store    => $self,
                    decl_pos => scalar(@{$self->{_Store_locations}}) );
    push @{$self->{_Store_locations}}, $object;
    foreach ( @method_names ) {
      $self->{_Store_imported_methods}->{$_} = $object;
    }
  }; if ( $@ ) { chomp $@; die "problem with location section: $@\n" };
}

sub _config__output {
  my ( $self, $el ) = @_;
  $self->{_Store_outputs} ||= [];
  eval {
    my ( $name, %args ) = name_and_args_eval ( $el->get() );
    my $class = "XML::Comma::Storage::Output::$name";
    eval "use $class"; die "couldn't use class '$name': $@\n" if $@;
    my $object = $class->new ( %args, '_store' => $self );
    push @{$self->{_Store_outputs}}, $object;
  }; if ( $@ ) { chomp $@; die "problem with output section: $@\n" };
}


sub _config__DONE__ {
  my $self = shift();
  # make store_outputs an empty array reference if we don't have any
  $self->{_Store_outputs} ||= [];
  # sort location specifiers. invert the decl_pos comparison because
  # the make_id routine (which is what we think of when we think of
  # left-to-right directory ordering) will process these from back to
  # front in order to go from highest major-numbered to lowest)
  if ( ! $self->{_Store_locations} ) {
    die "must have at least one <location> section\n";
  }
  @{$self->{_Store_locations}} = sort {
    $a->MAJOR_NUMBER() <=> $b->MAJOR_NUMBER() or
      $b->decl_pos() <=> $a->decl_pos();
  } @{$self->{_Store_locations}};
  # check to make sure there is exactly one location specifier with a
  # MAJOR_NUMBER of '1'
  if ( $self->{_Store_locations}->[0]->MAJOR_NUMBER() != 1 ) {
    die "no basic location specifier found\n";
  }
  if ( scalar(@{$self->{_Store_locations}}) > 1 and
       $self->{_Store_locations}->[1]->MAJOR_NUMBER == 1 ) {
    die "more than one basic location specifier found\n";
  }
}

sub AUTOLOAD {
  my ( $self, @args ) = @_;
  # strip out local method name and stick into $m
  $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
  if ( exists ${$self->{_Store_imported_methods}}{$m} ) {
    $self->{_Store_imported_methods}->{$m}->$m ( @args );
  } else {
    $self->auto_dispatch ( $m, @args );
  }
}


1;
