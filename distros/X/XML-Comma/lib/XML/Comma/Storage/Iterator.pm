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

package XML::Comma::Storage::Iterator;

use vars '$AUTOLOAD';

use strict;
use File::Find;
use XML::Comma::Util qw( dbg  );

# _Iterator_Store
# _Iterator_cached_list
# _Iterator_index
# _Iterator_direction
# _Iterator_last_doc
# _Iterator_newly_refreshed

###
### code to match iterator semantics
###

use overload bool => \&_iterator_has_stuff,
  '""' => sub { return $_[0] },
  '++' => \&_it_next,
  '--' => \&_it_prev,
  '=' => sub { return $_[0] };
# boy it'd sure be nice if we could do: while (my $doc = $it++) ...
#  '=' => sub { return $_[0]->read_doc };
# but it doesn't work, at least the way I tried it...

#these are only called by the overloading goo...
sub _it_next { return $_[0]->_it_advance(1);  }
sub _it_prev { return $_[0]->_it_advance(-1); }
sub _it_advance {
  my ($self, $amt) = @_;
  if($self->{_Iterator_newly_refreshed}) {
    $self->{_Iterator_newly_refreshed} = 0;
    # return true if there is anything in the iterator ("fake $it")
    return scalar @{$self->{_Iterator_cached_list}};
  }
  
  #the rest of this function is a lot like read_next (and next_id), except
  #it does a few things differently so we don't loop forever...
  $amt = -$amt if($self->{_Iterator_direction} eq '+');
  if($amt > 0) {
    $self->inc($amt) unless($self->{_Iterator_index} > $#{$self->{_Iterator_cached_list}}+1);
  } else {
    # -- is generally not useful, but $it-- shouldn't go below -1...
    $self->inc($amt) unless($self->{_Iterator_index} < 0);
  }
#  print "index: ", $self->{_Iterator_index}, "bla: ",
#    $#{$self->{_Iterator_cached_list}}, "\n";
  #if the index is greater than the size of the cached_list, return false
  return undef if ( $self->{_Iterator_index} > $#{$self->{_Iterator_cached_list}} );
  #this should never happen - see if($self->{_Iterator_newly_refreshed}) @ top of _it_advance
  # as well as _iterator_has_stuff
  die "congratulations, you found a bug in XML::Comma. Please report it: empty iterator?!?" unless(@{$self->{_Iterator_cached_list}});

  my $id = $self->{_Iterator_Store}->id_from_location
    ( $self->{_Iterator_cached_list}->[$self->{_Iterator_index}] );

  return $self->{_Iterator_last_doc} = XML::Comma::Doc->read
    ( type => $self->{_Iterator_Store}->doctype(),
      store => $self->{_Iterator_Store}->element('name')->get(),
      id => $id );
}


# this function is a bit of a lie... it is just here to provide "while(++$it)"
# it might not work with {prev|next}_read semantics, due to boundary condition
sub _iterator_has_stuff {
  my $self = $_[0];
  #return false if _Iterator_cached_list is empty
  return undef unless scalar @{$self->{_Iterator_cached_list}};
  return ( $self->{_Iterator_direction} eq '-' ) ? 
    ( $self->{_Iterator_index} <= $#{$self->{_Iterator_cached_list}} ) :
    ( $self->{_Iterator_index} >= 0 );
}

sub read_doc {
  my ($self, %args) = @_;
  return $self->{_Iterator_last_doc} || (( $self->{_Iterator_direction} eq '-' ) ?
    $self->next_read(%args) : $self->prev_read(%args)); 
}

sub retrieve_doc {
  my $self = shift;
  my $doc = $self->read_doc(@_);
  $doc->get_lock();
  return $doc; 
}

# alias doc_(read && retrieve) to (read && retrieve)_doc 
# for API consistancy

*doc_retrieve = \&retrieve_doc;
*doc_read     = \&read_doc;

###
### /code to match iterator semantics
###

# store=>, size=>, pos=>
sub new {
  my ( $class, %arg ) = @_;
  my $self = {};
  # which store
  my $store = $self->{_Iterator_Store} = $arg{store} ||
    die "Storage Iterator needs a store to iterate across\n";
  my $extension = $store->extension() ||
    die "Storage Iterator requires a Store that provides an extension\n";
  # where do we start and how much do we want?
  my $size = $arg{size} || 0xffffffff;
  my $pos = $self->{_Iterator_direction} = $arg{pos} || '+';
  # build the cached list of locations -- we post-sort the results in
  # chunks again because find's preprocess block doesn't actually sort
  # the file contents of a directory;
  my $temp_by_dir = {};
  my $total_pushed = 0;
#  warn "pos: $pos, size: $size\n";
  find ( { preprocess => sub { 
#             warn "PREPROCESS SORT: @_ WILL BECOME: ", join(" ",
#               ($pos eq '+') ? sort @_ : reverse sort @_), "\n";
             return () if $total_pushed > $size;
             return ($pos eq '-') ? sort @_ : reverse sort @_;
           },
           wanted => sub {
             push ( @{$temp_by_dir->{$File::Find::dir}}, $File::Find::name )
               if  m|$extension$|;
           },
           postprocess => sub {
             $total_pushed += scalar ( @{$temp_by_dir->{$File::Find::dir}} )
               if  defined $temp_by_dir->{$File::Find::dir};
           }
         }, $store->base_directory()
       );

# useful in debugging sort order problems above
#  foreach my $k (sort keys %$temp_by_dir) {
#    warn "hmm: $k -> ", @{$temp_by_dir->{$k}}, "\n";
#  }

  # post-sort and set where we're starting from and our actual length
  if ( $pos eq '-' ) {
    map { push @{$self->{_Iterator_cached_list}}, @{$temp_by_dir->{$_}} }
      sort keys %{$temp_by_dir};
    $#{$self->{_Iterator_cached_list}} = $size-1  if
      ($size-1) < $#{$self->{_Iterator_cached_list}};
    $self->{_Iterator_index} = -1;
  } else {
    map { push @{$self->{_Iterator_cached_list}}, @{$temp_by_dir->{$_}} }
      reverse sort keys %{$temp_by_dir};
    if ( ($size-1) < $#{$self->{_Iterator_cached_list}} ) {
      $#{$self->{_Iterator_cached_list}} = $size-1;
    }
    @{$self->{_Iterator_cached_list}} =
      reverse @{$self->{_Iterator_cached_list}};
    $self->{_Iterator_index} = $#{$self->{_Iterator_cached_list}} + 1;
  }
#  foreach my $i (@{$self->{_Iterator_cached_list}}) {
#    warn "- $i\n";
#  }
  $self->{_Iterator_newly_refreshed} = 1; #for overloading
  # bless and return
  bless ( $self, $class );
  return $self;
}

sub length {
  return $#{$_[0]->{_Iterator_cached_list}} + 1;
}

sub index {
  return $_[0]->{_Iterator_index};
}

sub inc {
  return $_[0]->{_Iterator_index} += $_[1] || 1;
}

sub set {
  return $_[0]->{_Iterator_index} = $_[1];
}

sub next_id {
  my $self = shift();
  return if ( $self->{_Iterator_index} >= $#{$self->{_Iterator_cached_list}} );
  $self->inc();
  return $self->{_Iterator_Store}->id_from_location
    ( $self->{_Iterator_cached_list}->[$self->{_Iterator_index}] );
}

sub prev_id {
  my $self = shift();
  return  if ( $self->{_Iterator_index} <= 0 );
  $self->inc(-1);
  return $self->{_Iterator_Store}->id_from_location
    ( $self->{_Iterator_cached_list}->[$self->{_Iterator_index}] );
}

sub next_retrieve {
  my $id = $_[0]->next_id() || return;
  return $_[0]->{_Iterator_last_doc} = XML::Comma::Doc->retrieve 
    ( type => $_[0]->{_Iterator_Store}->doctype(),
      store => $_[0]->{_Iterator_Store}->element('name')->get(),
      id => $id );
}

sub prev_retrieve {
  my $id = $_[0]->prev_id() || return;
  return $_[0]->{_Iterator_last_doc} = XML::Comma::Doc->retrieve 
    ( type => $_[0]->{_Iterator_Store}->doctype(),
      store => $_[0]->{_Iterator_Store}->element('name')->get(),
      id => $id );
}

sub next_read {
  my ($self, %args) = @_;
  my $id = $self->next_id() || return;
  return $self->{_Iterator_last_doc} = XML::Comma::Doc->read 
    ( type => $self->{_Iterator_Store}->doctype(),
      store => $self->{_Iterator_Store}->element('name')->get(),
      id => $id, %args );
}

sub prev_read {
  my ($self, %args) = @_;
  my $id = $self->prev_id() || return;
  return $self->{_Iterator_last_doc} = XML::Comma::Doc->read
    ( type => $self->{_Iterator_Store}->doctype(),
      store => $self->{_Iterator_Store}->element('name')->get(),
      id => $id, %args );
}

sub doc_id {
  my $location = $_[0]->{_Iterator_cached_list}->[$_[0]->{_Iterator_index}];
  return $location ?
    $_[0]->{_Iterator_Store}->id_from_location($location) : 
    #the below is slow, but we only do it once per iteration. it's
    #needed in particular for storage iterator dispatch stuff
    $_[0]->read_doc->doc_id;
}

sub to_array {
  my ( $self, %args ) = @_; 
  my @docs = ();
  while($self++) {
    push @docs, $self->read_doc;
    #push @docs, XML::Comma::VirtualDoc->new($self); 
  }
  return @docs;
} 

####
# AUTOLOAD
#
#
####

sub AUTOLOAD {
  my ( $self, @args ) = @_;
  # strip out local method name and stick into $m
  $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
  return $self->iterator_dispatch ( $m, @args );
}

#note this is NOT slow, because read_doc does caching.
sub iterator_dispatch {
  my ( $self, $m, @args ) = @_;
  # if we're here, make sure next call to ++$it really does
  # advance
  $self->{_Iterator_newly_refreshed} = 0;

#warn "m: $m, args: ".join(" ", @args)."\n";
#warn "self: $self\n";
  my $doc = $self->read_doc();
#warn "doc: $doc\n";
  return $doc->$m(@args);
}

sub DESTROY { }


1;

