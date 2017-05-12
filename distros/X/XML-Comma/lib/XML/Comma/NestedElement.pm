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

package XML::Comma::NestedElement;

@ISA = ( 'XML::Comma::AbstractElement' );

use strict;

use XML::Comma::Util qw( dbg trim array_includes arrayref_remove );

##
# object fields
#
# _nested_elements     : arrayref of sub-elements in order of declaration
# _nested_lookup_table : hashref of sub-element tags, each hash value
#                        containing an arrayref to the elements of that type.
#                        lookup_table is managed by _add_elements and
#                        _delete_elements routines.
#
# _ne_blob_ghosts      : an arrayref containing blobs that have been deleted
# Doc_storage          : a storage reference passed down from the original doc
#
#

sub _init {
  my ( $self, %arg ) = @_;
  # nested elements and content holders
  $self->{_ne_blob_ghosts}  = [];
  $self->{_nested_elements} = [];
  $self->{_nested_lookup_table} = {};
  $self->SUPER::_init ( %arg );
}


##
# called by parser --
#
sub raw_append {
  if ( $_[1] =~ /\S/ ) {
    die "parse error: unexpected text found: '" . trim($_[1]) . "'\n";
  }
}


########
#
# Nested Element Manipulation
#
########

# elements of the given type as an array(ref), or all elements when
# given no arg.
sub elements {
  my ( $self, @args ) = @_;
  # no args
  if ( ! @args ) {
    return wantarray ? @{$self->{_nested_elements}} : $self->{_nested_elements};
  }
  # args
  my @list = ();
  foreach my $arg ( @args ) {
    $self->_element_defined_check ( $arg );
    push @list, @{$self->{_nested_lookup_table}->{$arg} || []};
  }
  # we need to sort into the right order, if no args or more than one arg given
  if ( scalar(@args) > 1 ) {
    @list = sort { $a->{_init_index} <=> $b->{_init_index} } @list;
  }
  return wantarray ? @list : \@list;
}

# returns the first element of the given type declared, or creates a
# new one and returns that. (or throws an error.)
sub element {
  my $self = shift();
  my $tag = shift() ||
    XML::Comma::Log->err ( 'NO_ELEMENT_REQUESTED',
                           "el->element() needs an argument" );
  if ( my $el = $self->elements($tag)->[0] ) { return $el; }
  return $self->add_element ( $tag );
}

##
# given a name, adds a default element of that name to this element's
# elements.
#
sub add_element {
  my $self = shift();
  my $tag = shift() ||
    XML::Comma::Log->err ( 'NO_ELEMENT_REQUESTED',
                           "el->add_element() needs an argument" );
  my $complete_tag_string = shift() || "";
  my $new_el;
  $self->_add_element_legality_check ( $tag );
  if ( $self->def()->def_by_name($tag)->is_nested() ) {
    $new_el = XML::Comma::NestedElement->new
      ( def            => $self->def()->def_by_name($tag),
        tag_up_path    => $self->tag_up_path() . ':' . $tag,
        Doc_storage    => $self->{Doc_storage} || {},
        init_index     => scalar(@{$self->{_nested_elements}}) );
  } elsif ( $self->def()->def_by_name($tag)->is_blob() ) {
    $new_el = XML::Comma::BlobElement->new
      ( def            => $self->def()->def_by_name($tag),
        tag_up_path    => $self->tag_up_path() . ':' . $tag,
        Doc_storage    => $self->{Doc_storage} || {},
        init_index     => scalar(@{$self->{_nested_elements}}) );
  } else {
    $new_el = XML::Comma::Element->new
      ( def            => $self->def()->def_by_name($tag),
        tag_up_path    => $self->tag_up_path() . ':' . $tag,
        Doc_storage    => $self->{Doc_storage} || {},
        init_index     => scalar(@{$self->{_nested_elements}}) );
  }
  # attributes?
  $complete_tag_string =~ m:<\w+\s*([^>]*)>:;
  if ( $1 ) {
    $new_el->set_attr ( XML::Comma::Util::attr_from_tag_string($1) );
  }
  # underlying add
  $self->_add_elements ( $new_el );
  $self->set_read_only()  if  $self->{_read_only};
  return $new_el;
}

sub _add_element_legality_check {
  $_[0]->_element_defined_check ( $_[1] );
  $_[0]->_element_plural_check ( $_[1] );
}

sub _element_defined_check {
  # dbg 'me', ref($_[0]), $_[0]->def();
  #return  if  ref($_[0]) eq 'XML::Comma::Bootstrap';
  return  if  $_[0]->isa ( 'XML::Comma::Bootstrap' );
  if ( ! $_[0]->element_is_defined($_[1]) ) {
    XML::Comma::Log->err 
        ( 'ELEMENT_NOT_DEFINED',
          "no element <$_[1]> defined for context '".
          $_[0]->tag_up_path() . "'" );
  }
}

sub _element_plural_check {
  if ( ! $_[0]->element_is_plural($_[1]) and $_[0]->elements($_[1])->[0] ) {
    XML::Comma::Log->err
        ( 'ELEMENT_ALREADY_EXISTS',
          "non-plural element <$_[1]> already exists in context '" .
          $_[0]->tag_up_path() . "'" );
  }
}


##
# _add_elements and _delete_elements push and splice elements from the
# elements array, and manage the lookup table. _add does not check
# legality at all, callers are expected to do that.
#
sub _add_elements {
  my ( $self, @elements ) = @_;
  # question, should we be allowed to add elements if a doc is
  # read_only -- if they're empty, they don't really effect the
  # document, and there's no way to use documents flexibly unless you
  # can make calls to non-there elements???
  # $self->assert_not_read_only();
  foreach my $element ( @elements ) {
    push @{$self->{_nested_lookup_table}->{$element->tag()}}, $element;
    push @{$self->{_nested_elements}}, $element;
  }
}

sub _delete_elements {
  my ( $self, @elements ) = @_;
  $self->assert_not_read_only();
  arrayref_remove ( $self->{_nested_elements}, @elements );
  foreach my $el ( @elements ) {
    $el->call_on_delete();
    arrayref_remove ( $self->{_nested_lookup_table}->{$el->tag()}, $el );
  }
  push @{$self->{_ne_blob_ghosts}},
    grep { $_->isa('XML::Comma::BlobElement') } @elements;
  push @{$self->{_ne_blob_ghosts}}, map { $_->get_all_blobs }
    grep { $_->isa('XML::Comma::NestedElement') } @elements;
}

sub call_on_delete {
  foreach my $el ( @{$_[0]->{_nested_elements}} ) {
    $el->call_on_delete;
  }
}


##
# given a name, looks up the first element so named and deletes
# it. returns the deleted element or undef, if none was found. given
# an element, deletes it, and returns it. (Doesn't complain if the
# element doesn't actually exist.)
#
sub delete_element {
  my $self = shift();
  $self->assert_not_read_only();
  my $tag_or_element = shift() || 
    XML::Comma::Log->err ( 'NO_ELEMENT_REQUESTED',
                           "el->delete_element() needs an argument" );
  my $el;
  if ( UNIVERSAL::isa($tag_or_element,'XML::Comma::AbstractElement') ) {
    $el = $tag_or_element;
  } else {
    $el = $self->elements($tag_or_element)->[-1];
  }
  if ( $el ) {
    $self->_delete_elements ( $el );
    return 1;
  } else {
    return undef;
  }
}



##
#
# Helper routines for dealing with sub-elements succinctly.
#
sub elements_group_get {
  my ( $self, $tag ) = @_;
  if ( ! $tag ) {
    my @list = map { $_->get() } @{$self->{_nested_elements} || []};
    return wantarray ? @list : \@list;
  }
  my @list = map { $_->get() } @{$self->{_nested_lookup_table}->{$tag} || []};
  return wantarray ? @list : \@list;
}

sub elements_group_add {
  my ( $self, $tag, @adds ) = @_;
  my @list;
  foreach my $add ( @adds ) {
    push @list, $self->add_element($tag)->set ( $add );
  }
  return wantarray ? @list : \@list;
}

sub elements_group_add_uniq {
  my ( $self, $tag, @adds ) = @_;
  my @list;
  foreach my $add ( @adds ) {
    if ( $self->elements_group_lists($tag, $add) ) {
      push @list, $add;
    } else {
      push @list, $self->add_element($tag)->set ( $add );
    }
  }
  return wantarray ? @list : \@list;
}

sub elements_group_delete {
  my $self = shift();
  my $tag = shift() ||
    XML::Comma::Log->err ( 'NO_ELEMENT_REQUESTED',
                           "el->elements_group_delete() needs an argument" );
  my @deletes = @_;
  my @list;
  if ( ! @deletes ) {
    my @list = $self->elements($tag);
    $self->_delete_elements ( @list );
  } else {
    foreach my $el ( $self->elements($tag) ) {
      foreach my $del ( @deletes ) {
        if ( $el->get() eq $del ) {
          push @list, $el;
          $self->_delete_elements ( $el );
        }
      }
    }
  }
  return wantarray ? @list : \@list;
}

sub elements_group_lists {
  my ( $self, $tag, $string ) = @_;
  return array_includes ( @{$self->elements_group_get($tag)}, $string );
}

#
#

sub element_is_plural {
  return $_[0]->def()->is_plural($_[1]);
  return;
}

sub element_is_defined {
  # dbg '->', $_[0];
  my $def = $_[0]->def();
  return $def && $def->def_by_name($_[1]);
}

sub element_is_nested {
  return 1  if  $_[0]->def()->def_by_name($_[1])  and
    $_[0]->def()->def_by_name($_[1])->is_nested();
  return;
}

sub element_is_blob {
  return 1  if  $_[0]->def()->def_by_name($_[1])  and
    $_[0]->def()->def_by_name($_[1])->is_blob();
  return;
}

sub element_is_required {
  return $_[0]->def()->is_required($_[1]);
}

# generic validate() self implementation. calls def's validate
# routine, then recurses down the tree calling validate() for all
# sub-elements.
#
#
sub validate {
  my $self = shift();
  eval {
    $self->def()->validate ( $self );
    foreach my $el ( $self->elements() ) {
      $el->validate();
    }
  }; if ( $@ ) {
    XML::Comma::Log->err ( 'VALIDATE_ERROR', $@ );
  }
  return '';
}

##
# DEPRECATED:
#
# calls the def's validate routine, then does the same
# for all child nested elements. all callees should die with a
# message string if they encounter an error
sub validate_structure {
  my $self = shift();
  eval {
    $self->def()->validate ( $self );
    foreach my $el ( $self->elements() ) {
      $el->validate_structure()  if  $el->def()->is_nested();
    }
  }; if ( $@ ) {
    XML::Comma::Log->err ( 'VALIDATE_ERROR', $@ );
  }
  return '';
}

##
# hashing
#
# this is like to_string, except that subclasses do slightly different
# things to mask platform-specific differences.
sub _get_hash_add {
  my $self = shift();
  return ''  if  ! @{$self->elements()};   # don't output anything if empty
  my $str;
  $str = '<' . $self->tag() . ">\n";
  foreach my $group ( map {$_->element('name')->get()}
                      $self->def()->def_sub_elements() ) {
    if ( ! $self->def()->is_ignore_for_hash($group) ) {
      foreach my $el ( $self->elements($group) ) {
        $str .= $el->_get_hash_add();
      }
    }
  }
  $str .= '</'. $self->tag() . '>';
  $str .= "\n";
  return $str;
}


##
# blob management all the way down the tree
#
sub get_all_blobs {
  my $self = shift();
  my @blobs;
  foreach my $el ( $self->elements() ) {
    # push a blob directly, recurse-push on a nested element
    if ( $el->def()->is_blob() ) {
      push @blobs, $el;
    } elsif ( $el->def()->is_nested() ) {
      push @blobs, $el->get_all_blobs();
    }
  }
  return @blobs;
}

# when a blob is delete_element'ed, it goes onto the ghosts list, so
# that its backing store can be removed when/if the doc is stored
sub get_all_blobs_and_ghosts {
  my $self = shift();
  my @blobs = @{$self->{_ne_blob_ghosts}};
  foreach my $el ( $self->elements() ) {
    # push a blob directly, recurse-push on a nested element
    if ( $el->def()->is_blob() ) {
      push @blobs, $el;
    } elsif ( $el->def()->is_nested() ) {
      push @blobs, $el->get_all_blobs_and_ghosts();
    }
  }
  return @blobs;
}

# recursively clear ghost blobs list (after store or erase, presumably)
sub clear_ghosts_list {
  my $self = shift();
  $self->{_ne_blob_ghosts} = [];
  foreach my $el ( $self->elements() ) {
    if ( $el->def()->is_nested() ) {
      $self->{_ne_blob_ghosts} = [];
    }
  }
}

# we need to do two things, here. 1) set the _init_index field of each
# element to the right sequential order number, and 2) then use that
# to re-order the {_nested_elements} ref so that elements() with no
# args can be a quick and efficient return;
sub group_elements() {
  my $self = shift();
  $self->assert_not_read_only();
  my $i = 0;
  my @new_array;
  foreach my $group
    ( map {$_->element('name')->get()} $self->def()->def_sub_elements() ) {
      foreach my $el ( $self->elements($group) ) {
        $el->{_init_index} = $i++;
        push @new_array, $el;
      }
    }
  $self->{_nested_elements} = \@new_array;
  return $self;
}

# we need to set the _init_index field of each element using the
# <sort_sub> of the first element given, or of self.
sub sort_elements() {
  my ( $self, @args ) = @_;
  # find a sort_sub to use
  my $sort_sub;
  $sort_sub = $self->def()->def_by_name($args[0])->sort_sub()
    if  $args[0];
  $sort_sub = $self->def()->sort_sub()  if  ! $sort_sub;
  XML::Comma::Log->err
      ( 'SORT_ELEMENTS_ERR',
        "no sort_sub findable for '" . $self->tag() . "'" )
        if  ! $sort_sub;
  # get an array of elements, and construct an array of _init_indexes
  my @els = $self->elements ( @args );
  my @inits = map { $_->{_init_index} } @els;
  # sort and then re-assign init indexes
  eval { @els = sort $sort_sub @els; };
  if ( $@ ) {
    XML::Comma::Log->err ( 'SORT_ELEMENTS_ERR', $@ );
  }
  foreach my $el ( @els ) {
    $el->{_init_index} = shift @inits;
  }
  # rearrange the storage layouts in the _nested_elements and
  # _nested_lookup_table arrays
  my @all_elements = sort { $a->{_init_index} <=> $b->{_init_index} }
    @{$self->{_nested_elements}};
  $self->{_nested_elements} = \@all_elements;
  foreach my $arg ( @args ) {
    my @group_els = sort { $a->{_init_index} <=> $b->{_init_index} }
      @{$self->{_nested_lookup_table}->{$arg}};
    $self->{_nested_lookup_table}->{$arg} = \@group_els;
  }
  # finally, return the @els array or a reference to it
  return wantarray ? @els : \@els;
}

sub to_string {
  my $self = shift();
  my $str = '';
  foreach my $el ( $self->elements() ) {
    $str .= $el->to_string();
  }
  return ''  unless  $str;
  return '<' . $self->tag() . $self->attr_string() . ">\n" .
    $str . '</'. $self->tag() . '>' . "\n";
}
  
#  ##
#  # stringification -- FIX: break apart into open-content-close
#  #
#  sub to_string {
#    my $self = shift();
#    return ''  if  ! @{$self->elements()};   # don't output anything if empty
#    my $str;
#    $str = '<' . $self->tag() . ">\n";
#    foreach my $group
#      ( map {$_->element('name')->get()} $self->def()->def_sub_elements() ) {
#      foreach my $el ( $self->elements($group) ) {
#        $str .= $el->to_string();
#      }
#    }
#    $str .= '</'. $self->tag() . '>';
#    $str .= "\n";
#    return $str;
#  }


####
# auto_dispatch -- called by AUTOLOAD, and anyone else who wants to
# mimic the shortcut syntax
#
#
# $element->foo(@args) becomes:
#
# $element->method('foo', @args)    if there is a method named foo
#
# -- for nested or blob foo:
#
# $element->elements('foo')            if foo is plural
# $element->elements('foo')->[0]       if foo is singular
#
# -- for non-nested foo:
#
# $element->element('foo')->get()               if foo is singular and no args
# $element->element('foo')->set(@args)          if foo is singular and args
# $element->elements_group_get('foo')           if foo is plural and no args
# $element->elements_group_add('foo',@args)     if foo is plural and args
####

sub auto_dispatch {
  my ( $self, $m, @args ) = @_;
  if ( my $method = $self->can($m) || $self->method_code($m) ) {
    $method->( $self, @args );
  } elsif ( $self->element_is_defined($m) ) {
    $self->_auto_element_dispatch ( $m, @args );
  } else {
    XML::Comma::Log->err ( 'UNKNOWN_ACTION',
                           "no method or element '$m' found in '" .
                           $self->tag_up_path . "'" );
  }
}

sub _auto_element_dispatch {
  my ( $self, $el, @args ) = @_;
  if ( $self->element_is_nested($el) or $self->element_is_blob($el) ) {
    if ( $self->element_is_plural($el) ) {
      # nested/plural
      return $self->elements($el);
    } else {
      # nested/singular
      return $self->element($el);
    }
  } else {
    if ( $self->element_is_plural($el) ) {
      if ( @args ) {
        # non-nested/plural/args
        return $self->elements_group_add ( $el, @args );
      } else {
        # non-nested/plural/no-args
        return $self->elements_group_get ( $el );
      }
    } else {
      if ( @args ) {
        # non-nested/singular/args
        return $self->element($el)->set(@args);
      } else {
        # non-nested/singular/no-args
        return $self->element($el)->get(@args);
      }
    }
  }
}

1;

