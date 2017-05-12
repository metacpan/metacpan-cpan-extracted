##
#
#    Copyright 2001-2005, AllAfrica Global Media
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

package XML::Comma::Element;

@ISA = ( 'XML::Comma::AbstractElement' );

use strict;

use XML::Comma::Util qw( dbg trim arrayref_remove );

##
# object fields
#
# _content             : string holding element content
# _cdata               : mark this element as needing to be wrapped in
#                        a CDATA container. currently, any element that
#                        has a CDATA start tag anywhere immediately inside it
#                        will be marked this way

# no need for an init sub here (parent's does the work of initting the
# def and tag fields, this is just a reminder)
#
# sub _init {
# $self->{_content} = undef; }
# }


##
# called by parser
#
# clean up content
sub finish_initial_read {
  $_[0]->{_content} = trim ( $_[0]->{_content} );
  $_[0]->SUPER::finish_initial_read();
}
#
##

##
# called by parser and part of public api
#
# mark this element as needing a cdata wrapper
sub cdata_wrap {
  $_[0]->assert_not_read_only();
  $_[0]->{_cdata} = 1;
}
#
##


########
#
# Content Manipulation
#
########

sub get {
  my ( $self, %args ) = @_;
  my $content;
  if ( defined $self->{_content} ) {
    $content = $self->{_content};
  } else {
    $content = $self->def()->element('default')->get();
    return ''  unless  defined $content;
  }
  if ( defined $args{unescape} ) {
    if ( $args{unescape} ) {
      $content = $self->def()->{_Def_unescape_code}->($content, %args);
    }
  } else {
    if ( $self->def()->{_Def_auto_unescape} ) {
      $content = $self->def()->{_Def_unescape_code}->($content, %args);
    }
  }
  # run get hooks, passing content and args -- FIX (add get hook)
  # ...
  return $content;
}

# used by to_string()
sub get_without_default {
  return $_[0]->{_content};
}

sub set {
  my ( $self, $content, %args ) = @_;
  $self->assert_not_read_only();
  if ( defined $content ) {
    # stringify to avoid strange errors that sometimes crop up now
    # that we're overloading/decorating our Element classes
    $content = "$content";
    # trim
    $content = trim ( $content );
    # escape arg/config handling
    if ( defined $args{escape} ) {
      if ( $args{escape} ) {
        $content = $self->def()->{_Def_escape_code}->($content, %args);
      }
    } else {
      if ( $self->def()->{_Def_auto_escape} ) {
        $content = $self->def()->{_Def_escape_code}->($content, %args);
      }
    }
  }
  # validate
  $self->validate_content ( $content );
  # run set hooks, passing a reference to the content variable, and
  # args
  eval {
    foreach my $hook ( @{$self->def()->get_hooks_arrayref('set_hook')} ) {
      $hook->( $self, \$content, \%args );
    }
  }; if ( $@ ) {
    XML::Comma::Log->err
        ( 'SET_HOOK_ERROR', "in " . $self->tag_up_path() . ": $@" );
  }
  # update _content field
  $self->{_content} = $content;
  return $self->{_content};
}

sub append {
  my ( $self, $more ) = @_;
  $self->assert_not_read_only();
  $self->set ( $self->get() . $more );
}

# no validity check and no trim
sub raw_append {
  $_[0]->{_content} .= $_[1];
}

# generic validate() self implementation
#
sub validate {
  my $self = shift();
  $self->validate_content ( $self->get(unescape=>0) );
}

# all callees (validate_content_hooks) should die with a message
# string if they encounter an error
sub validate_content {
  my ( $self, $text ) = @_;
  if ( $_[0]->{_cdata} ) {
    $text = "<![CDATA[$text]]>";
  }
  # check for un-parseable content by trying to parse and catching
  # errors. then ask the def to call any of its validate_hooks
  eval {
    if ( defined $text ) {
      XML::Comma->parser()->parse ( block => "<_>$text</_>" );
    }
    $self->def()->validate ( $self, $text );
  }; if ( $@ ) {
    $text = '[undefined]'  if  ! defined $text;
    XML::Comma::Log->err
        ( 'BAD_CONTENT', "'$text' for " . $self->tag_up_path() . ": $@" );
  }
  return $text;
}


sub _get_hash_add {
  return $_[0]->to_string();
}

sub to_string {
  my $self = shift();
  my $content = $self->get_without_default();
  # don't output if empty
  return ''  unless defined $content and
                            $content ne '';
  my $str;
  $str = '<' . $self->tag() . $self->attr_string() . '>';
  $str .= '<![CDATA['  if  $self->{_cdata};
  $str .= $content;
  $str .= ']]>'  if $self->{_cdata};
  $str .= '</'. $self->tag() . '>';
  $str .= "\n";
  return $str;
}


##
# auto_dispatch -- called by AUTOLOAD, and anyone else who wants to
# mimic the shortcut syntax
#

sub auto_dispatch {
  my ( $self, $m, @args ) = @_;
  if ( my $method = $self->can($m) ) {
    $method->( $self, @args );
  }
  $self->method ( $m, @args );
}

1;
