##
#
#    Copyright 2001, AllAfrica Global Media
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

package XML::Comma::Hookable;
use XML::Comma::Util qw( dbg );

use strict;

##
#
# add hook
#
sub add_hook {
  my ( $self, $hook_type, $hook, $hook_order ) = @_;
  # does this hook_type exist for this context?
  my $hooks_arrayref = $self->_raw_get_hooks_arrayref ( $hook_type );
  die "no hook type '$hook_type' is legal for " . $self->tag_up_path() . "\n"
    if ! $hooks_arrayref;
  # if we weren't passed a "hook_order" we need to make one
  unless ( $hook_order ) {
    $hook_order = scalar @{$hooks_arrayref};
  }
  # is this a string to be evaled, or a code ref?
  if ( ref($hook) eq 'CODE' ) {
    push @{$hooks_arrayref}, { code => $hook, order => $hook_order };
#    push @{$hooks_arrayref}, $hook;
  } else {
    my $code_ref = eval $hook;
    if ( $@ ) {
      print "\n--\n$hook\n--\n";
      die "error while defining '$hook_type': $@\n";
    }
    push @{$hooks_arrayref}, { code => $code_ref, order => $hook_order };
#    push @{$hooks_arrayref}, $code_ref;
  }
  # re-sort so our ordering is correct
  @{$hooks_arrayref} = sort { $a->{order} <=> $b->{order} } @{$hooks_arrayref};
  return $hook;
}


# takes a hook type and returns the array-ref of the code blocks of
# these hooks. illegal hooktypes return false.
sub get_hooks_arrayref {
  my ( $self, $hook_type ) = @_;
  my $ref = $self->_raw_get_hooks_arrayref ( $hook_type );
  return  unless  $ref;
  my @list = map { $_->{code} } @{$ref};
  return \@list;
}

sub _raw_get_hooks_arrayref {
  my ( $self, $hook_type ) = @_;
  return $_[0]->{'_Hookable_' . $_[1] . 's'};
}

sub allow_hook_type {
  my ( $self, @hook_types ) = @_;
  foreach ( @hook_types ) {
    $self->{'_Hookable_' . $_ . 's'} ||= [];
  }
}

1;


