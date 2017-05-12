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

package XML::Comma::AbstractElement;
use vars '$AUTOLOAD';
use strict;

use XML::Comma::Util qw( dbg trim array_includes arrayref_remove );

##
# object fields
#
# _tag                 : this tag name
# _tag_up_path         : full tag pathname (colon concatenated)
# _def                 : our Def object
# _init_index          : set by parent at add time and altered by 
#                      : group_elements()   (used only to sort elements)
#
# _attrs               : a hashref holding element attributes
#
# _read_only           : true/false if this element's content and structure
#                        cannot be changed

####
# Constructor: takes a def and a tag_up_path.
#
# This is rarely, if ever, called by an end-programmer, only from
# within the Comma classes.
#
# The def is required, althouth the _init_def routine can be (and is)
# overridden by children such as Doc, Def and Bootstrap.
#
# The tag_up_path is the full set up tags up the tree, glued together
# with single colons, for example 'Envelope:element1:sub_element'. The
# tag_up_path is required.
#
####
sub new {
  my ( $class, %arg ) = @_; my $self = {}; bless ( $self, $class );
  return $self->_init ( %arg );
}

sub _init {
  my ( $self, %arg ) = @_;
  # set tag and tag_up_path
  die "no tag_up_path to init"  unless  $arg{tag_up_path};
  $self->{_tag} = substr ( $arg{tag_up_path}, rindex($arg{tag_up_path},':')+1 );
  $self->{_tag_up_path} = $arg{tag_up_path};
  $self->{_init_index} = $arg{init_index};
  $self->_init_def ( $arg{def} );
  $self->{_attrs} = {};
  # set Doc_storage if we were passed a Doc_Storage arg
  $self->{Doc_storage} = $arg{Doc_storage}  if  $arg{Doc_storage};
  return $self;
}

sub _init_def {
  $_[0]->{_def} = $_[1] || die "no def given for element creation";
  if ( my @classes = $_[1]->get_decorators ) {
    bless ( $_[0], Class::ClassDecorator::hierarchy(ref($_[0]),@classes) );
  }
}


########
#
# Introspection
#
########

sub tag {
  #warn "XX TAG CALLER: ".join(", ", caller);
  return $_[0]->{_tag};
}

sub tag_up_path {
  #warn "XX TAG_UP_PATH CALLER: ".join(", ", caller);
  return $_[0]->{_tag_up_path}
}

sub def {
  #warn "XX DEF CALLER: ".join(", ", caller);
  return $_[0]->{_def};
}

sub def_pnotes {
  return XML::Comma::DefManager->get_pnotes ( $_[0]->{_def} );
}

sub pnotes {
  return $_[0]->{_pnotes} ||= {};
}


########
#
# HASH
#
########

sub comma_hash {
  my $self = shift();
  my $digest = XML::Comma->hash_module()->new();
  $digest->add ( $self->_get_hash_add() );
  return $digest->hexdigest();
}


########
#
# method methods -- both nested and non-nested elements allow methods
# to be defined for them.
#
########
# FIX: catch warnings (use of uninitialized value..., etc), not just errors?
sub method {
  my ( $self, $name, @args ) = @_;
  my $method = $self->{_def}->get_method ( $name );
  if ( $method ) {
    my $return; my @return;
    if ( wantarray ) {
      @return = eval { $method->( $self, @args ); };
    } else {
      $return = eval { $method->( $self, @args ); };
    }
    if ( $@ ) {
      XML::Comma::Log->err ( 'METHOD_ERROR',
                             "'$name' call threw error: $@" );
    }
    return wantarray ? @return : $return;
  } else {
    XML::Comma::Log->err ( 'NO_SUCH_METHOD',
                           "no method '$name' found in '" .
                           $self->{_tag_up_path} . "'" );
  }
}

sub method_code {
  my ( $self, $name ) = @_;
  return $self->{_def}->get_method ( $name );
}


##
# convenience pointer to def->applied_macros()
##

sub applied_macros {
  my $self = shift;
  return $self->{_def}->applied_macros ( @_ );
}


##
#
# read-only utility methods
#
##

sub set_read_only {
  my $self = shift();
  $self->{_read_only} = 1;
  # recurse if nested
  if ( $self->{_def}->is_nested() ) {
    foreach my $el ( $self->elements() ) {
      $el->set_read_only();
    }
  }
  return $self;
}

sub unset_read_only {
  my $self = shift();
  $self->{_read_only} = 0;
  # recurse if nested
  if ( $self->{_def}->is_nested() ) {
    foreach my $el ( $self->elements() ) {
      $el->unset_read_only();
    }
  }
  return $self;
}

sub get_read_only {
  return $_[0]->{_read_only};
}

sub assert_not_read_only {
  XML::Comma::Log->err ( 'READ_ONLY_ERR', 'cannot change a read_only document' )
      if $_[0]->{_read_only};
}


##
#
# Simple attribute manipulation -- simple because attribute usage is
# discouraged
#
##

# set_attr takes a list/hash of key=>value pairs and merges that into
# this elements current attr hash
sub set_attr {
  my ( $self, @rest ) = @_;
  my %hash = ( %{ $self->{_attrs} }, @rest );
  $self->{_attrs} = \%hash;
  return;
}

sub get_attr {
  my ( $self, $key ) = @_;
  return $self->{_attrs}->{$key};
}

# returns a string suitable for embedding into an open tag --
# including a leading space
sub attr_string {
  my $self = shift();
  my $string = '';
  foreach ( keys(%{$self->{_attrs}}) ) {
    $string .= " $_=\"" . $self->{_attrs}->{$_} . '"';
  }
  return $string;
}
#
##

####
# AUTOLOAD
#
#
####

sub AUTOLOAD {
  my ( $self, @args ) = @_;
  # strip out local method name and stick into $m
  $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
  $self->auto_dispatch ( $m, @args );
}


####
#
# finish_initial_read() -- called by parser so that sub-classes can do
# housekeeping and setup after being fully read in. Generally,
# sub-classes that override this method should call
# SUPER::finish_initial_read() when they're finished, so that this
# method can run any defined initial_read hooks.
#
####

sub finish_initial_read {
  unless ( $_[0]->{Doc_storage}->{read_args}->{no_read_hooks} ) {
    eval {
      foreach my $hook
        ( @{$_[0]->{_def}->get_hooks_arrayref('read_hook')} ) {
          $hook->( $_[0] );
        }
    }; if ( $@ ) {
      XML::Comma::Log->err
          ( 'READ_HOOK_ERROR', "in " . $_[0]->{_tag_up_path} . ": $@" 
);
    }
  }
  # destroy read_args ref
  #delete ${$_[0]->{Doc_storage}}{read_args};
}

####
#
# call_on_delete() -- When an element is deleted from a NestedElement,
# call this sub. Normally empty, but BlobElements, for example, need
# to erase their underlying files.
#
####

sub call_on_delete {
}

##
# Empty DESTROY: we don't want to autoload this
##
sub DESTROY {
#  print $_[0]->{_tag} . "\n";
#   print 'D: ' . $_[0] . "\n";
#    print '   index    ' . ($::index||'<undef>')."\n";
#    print '   ind def  ' . ($::index->{_def}||'<undef>')."\n";
#    print '   dmg def  ' . XML::Comma::DefManager->for_path('DocumentDefinition')->{_nested_lookup_table}->{nested_element}->[5] . "\n";


#    if ( (! defined $::index->{_def}) && (! $::index_dumped)) {
#      print "  $::index\n";
#      map { print "  $_ --> " . ($::index->{$_} || '<undef>') . "\n" } keys(%{$::index});
#      $::index_dumped++;
#    }
}

1;
