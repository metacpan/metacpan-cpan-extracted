##
#
#    Copyright 2004-2006, AllAfrica Global Media
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

package XML::Comma::Bootstrap;

use XML::Comma::Util qw( dbg trim );

@ISA = ( 'XML::Comma::Def' );
use vars '$AUTOLOAD';

use strict;

##
# All elements in the bootstrapping document definition are defined as
# Bootstrap elements. A Bootstrap element has no def, and because of
# this there is some hard-coding to determine, for example, whether a
# Bootstrap element is nested or not. The basic assumption, here, is
# that there are no mistakes (and so no need to validate or
# differentiate much between elements of) the bootstrap_block.
#
# Because bootstrap elements can either have content or be nested, the
# Bootstrap class is a hybrid, of sorts. It inherits NestedElement
# methods via Def, but also provides its own simple content get and
# set methods.

# block  ||  tag_up_path
sub new {
  my ( $class, %arg ) = @_;
  if ( $arg{block} ) {
    my $bootstrap = eval {
      XML::Comma->parser()->new ( block => $arg{block},
                                  top_level_class => $class );
    }; if ( $@ ) {
      die "Error while defining bootstrap definition: $@";
    }
    return $bootstrap;
  }
  my $self = {}; bless ( $self, $class );
  $self->_init ( def => '',
                 tag_up_path => $arg{tag_up_path} || 'DocumentDefinition',
                 init_index => $arg{init_index} );
  return $self;
}

sub finish_initial_read {
  my ( $self, $in_progress_parser ) = @_;
  # only add_def for top-level and element blocks, and only set and
  # trim the content for the rest (a little cheating is okay in a
  # bootstrap module, right?)
  my $tag = $self->tag();
  if ( $tag eq 'DocumentDefinition' or
       $tag eq 'element' or
       $tag eq 'nested_element' ) {
    $self->_Def_init_name_up_path ( $in_progress_parser );
    XML::Comma::DefManager->add_def ( $self );
    $self->_config_dispatcher();
  } else {
    $self->{_Bootstrap_content} = trim ( $self->{_Bootstrap_content} );
  }
}


# bootstrap is a hybrid -- it's a def/nested-element, but it also has
# basic raw_append and get.
sub raw_append {
  $_[0]->{_Bootstrap_content} .= $_[1];
}
sub get {
  return $_[0]->{_Bootstrap_content} || '';
}


# override the standard Def::add_element to not do a defined check, and to
# instantiate all children as Bootstraps, too.
sub add_element {
  my ( $self, $tag ) = @_;
  my $element = ref($self)->new
    ( tag_up_path  => $self->tag_up_path() . ':' . $tag,
      init_index   => scalar(@{$self->{_nested_elements}}) );
  $self->_add_elements ( $element );
  return $element;
}


# override the standard Element::_init_def to not do anything about defs
sub _init_def {
}

# a little hard-coding to handle whether we are defining a nested
# element or not. getting these wrong breaks everything else,
# sometimes in non-intuitive ways.
sub is_nested {
  my $tag = $_[0]->tag();
  return 1  if  ( $tag eq 'DocumentDefinition' or
                  $tag eq 'nested_element' or
                  $tag eq 'method'
                );
  return 0; # this must be return 0 (not bare return). looks like
            # something in parser->handle_element gets mis-aligned or
            # something if this is 'return', but I can't find
            # it. (blech. yuck. how could you write such bad code?)
}


sub validate_content {
  return;
}


####
# AUTOLOAD
#
#
####

sub AUTOLOAD {
  $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
  die "Bootstrap should never autoload -- '$m'\n";
}

sub bootstrap_block {
  return <<'END';
<DocumentDefinition>
  <name>DocumentDefinition</name>

  <element><name>name</name></element>
  <element><name>ignore_for_hash</name></element>
  <element><name>include_for_hash</name></element>
  <element><name>plural</name></element>
  <element><name>required</name></element>
  <nested_element>
    <name>properties</name>
    <element><name>ignore_for_hash</name></element>
    <element><name>include_for_hash</name></element>
    <element><name>plural</name></element>
    <element><name>required</name></element>
    <element><name>nested</name></element>
    <element><name>blob</name></element>
    <element><name>enum</name></element>
    <element><name>boolean</name></element>
    <element><name>range</name></element>
    <element><name>timestamp</name></element>
    <element><name>timestamp_created</name></element>
    <element><name>timestamp_last_modified</name></element>
    <element><name>doc_key</name></element>
    <element><name>single_line</name></element>
  </nested_element>
  <nested_element>
    <name>class</name>
    <element><name>module</name></element>
    <element><name>config</name></element>
  </nested_element>

  <element><name>macro</name></element>

  <element><name>read_hook</name></element>
  <element><name>validate_hook</name></element>
  <element><name>document_write_hook</name></element>
  <element><name>def_hook</name></element>
  <element><name>sort_sub</name></element>

  <nested_element>
    <name>method</name>
    <element><name>name</name></element>
    <element><name>code</name></element>
    <required>'name','code'</required>
  </nested_element>

  <nested_element>
    <name>element</name>
    <element><name>name</name></element>
    <element><name>ignore_for_hash</name></element>
    <element><name>include_for_hash</name></element>
    <nested_element>
      <name>class</name>
      <defname>DocumentDefinition:class</defname>
    </nested_element>
    <nested_element>
      <name>method</name>
      <defname>DocumentDefinition:method</defname>
    </nested_element>
    <element><name>def_hook</name></element>
    <element><name>read_hook</name></element>
    <element><name>validate_hook</name></element>
    <element><name>set_hook</name></element>
    <element><name>default</name></element>
    <element><name>macro</name></element>
    <element><name>defname</name></element>
    <element><name>sort_sub</name></element>
    <nested_element>
      <name>escapes</name>
      <element><name>escape_code</name></element>
      <element><name>unescape_code</name></element>
      <element><name>auto</name></element>
    </nested_element>
    <plural>'class',
            'def_hook',
            'read_hook',
            'method',
            'validate_hook',
            'set_hook',
            'macro'</plural>
    <required>'name'</required>
  </nested_element>

  <nested_element>
    <name>blob_element</name>
    <element><name>name</name></element>
    <element><name>ignore_for_hash</name></element>
    <element><name>include_for_hash</name></element>
    <nested_element>
      <name>class</name>
      <defname>DocumentDefinition:class</defname>
    </nested_element>
    <nested_element>
      <name>method</name>
      <defname>DocumentDefinition:method</defname>
    </nested_element>
    <element><name>extension</name></element>
    <element><name>def_hook</name></element>
    <element><name>validate_hook</name></element>
    <element><name>macro</name></element>
    <element><name>read_hook</name></element>
    <element><name>set_hook</name></element>
    <element><name>set_from_file_hook</name></element>
    <element><name>defname</name></element>
    <plural>'class',
            'def_hook',
            'validate_hook',
            'read_hook',
            'method',
            'macro',
            'set_hook',
            'set_from_file_hook'</plural>
    <required>'name'</required>
  </nested_element>

  <nested_element>
    <name>nested_element</name>
    <element><name>name</name></element>
    <element><name>defname</name></element>
    <element><name>ignore_for_hash</name></element>
    <element><name>include_for_hash</name></element>
    <nested_element>
      <name>class</name>
      <defname>DocumentDefinition:class</defname>
    </nested_element>
    <element><name>def_hook</name></element>
    <element><name>read_hook</name></element>
    <element><name>macro</name></element>
    <element><name>plural</name></element>
    <element><name>required</name></element>
    <element><name>validate_hook</name></element>
    <element><name>sort_sub</name></element>

    <nested_element>
      <name>element</name>
      <defname>DocumentDefinition:element</defname>
    </nested_element>

    <nested_element>
      <name>blob_element</name>
      <defname>DocumentDefinition:blob_element</defname>
    </nested_element>

    <nested_element>
      <name>nested_element</name>
      <defname>DocumentDefinition:nested_element</defname>
    </nested_element>

    <nested_element>
      <name>method</name>
      <defname>DocumentDefinition:method</defname>
    </nested_element>

    <plural>
      'class',
      'def_hook',
      'read_hook',
      'macro',
      'plural',
      'required',
      'validate_hook',
      'element',
      'blob_element',
      'nested_element',
      'method',
    </plural>
    <required>'name'</required>
  </nested_element>

  <nested_element>
    <name>store</name>
    <element><name>name</name></element>
    <element><name>location</name></element>
    <element><name>output</name></element>
    <element><name>root</name></element>
    <element><name>base</name></element>
    <element>
      <name>file_permissions</name>
      <default>664</default>
    </element>
    <element><name>pre_store_hook</name></element>
    <element><name>post_store_hook</name></element>
    <element><name>erase_hook</name></element>
    <element><name>index_on_store</name></element>
    <plural>qw( location           output
                pre_store_hook     post_store_hook
                erase_hook
                index_on_store  )</plural>
    <required>'name','base','location'</required>
  </nested_element>

  <nested_element>
    <name>index</name>
    <element><name>name</name></element>
    <element><name>store</name></element>
    <element><name>index_from_store</name></element>
    <!-- doc_id_sql_type SHOULD NOT BE CHANGED without completely
         dropping and recreating a given index's database (or otherwise
         altering the database structure outside of Comma). ** there is
         no automatic change of this to match a def ** -->
    <element>
      <name>doc_id_sql_type</name>
      <default>VARCHAR(255)</default>
    </element>
    <nested_element>
      <name>field</name>
      <element><name>name</name></element>
      <element><name>code</name></element>
      <element>
        <name>sql_type</name>
        <default>VARCHAR(255)</default>
      </element>
      <required>'name'</required>
    </nested_element>

    <nested_element>
      <name>collection</name>
      <element><name>name</name></element>
      <element><name>code</name></element>
      <element>
        <name>type</name>
        <default>binary table</default>
      </element>
      <element>
        <name>sql_type</name>
        <default>VARCHAR(245)</default>
      </element>
      <nested_element>
        <name>field</name>
        <element><name>name</name></element>
        <element>
          <name>sql_type</name>
          <default>VARCHAR(245)</default>
        </element>
      </nested_element>
      <nested_element>
        <name>clean</name>
        <element><name>to_size</name></element>
        <element><name>order_by</name></element>
        <element><name>size_trigger</name></element>
        <element><name>erase_where_clause</name></element>
      </nested_element>
      <required>'name'</required>
    </nested_element>

    <!-- for backwards compatibility, we'll define <sort> elements
    that are just like <collection> elements except for their <type>
    default -->
    <nested_element>
      <name>sort</name>
      <element><name>name</name></element>
      <element><name>code</name></element>
      <element>
        <name>type</name>
        <default>many tables</default>
      </element>
      <nested_element>
        <name>clean</name>
        <defname>DocumentDefinition:index:collection:clean</defname>
      </nested_element>
      <required>'name'</required>
    </nested_element>

    <nested_element>
      <name>textsearch</name>
      <element><name>name</name></element>
      <element>
        <name>which_preprocessor</name>
        <default>
          sub { return 'XML::Comma::Pkg::Textsearch::Preprocessor_En'; }
        </default>
      </element>
      <element><name>defer_on_update</name></element>
      <required>'name'</required>
    </nested_element>
    <nested_element>
      <name>sql_index</name>
      <element><name>name</name></element>
      <element><name>unique</name></element>
      <element><name>fields</name></element>
      <required>'name','fields'</required>
    </nested_element>
    <element>
      <name>default_order_by</name>
      <default>doc_id</default>
    </element>
    <nested_element>
      <name>order_by_expression</name>
      <element><name>name</name></element>
      <element><name>expression</name></element>
      <required>'name','expression'</required>
    </nested_element>
    <nested_element>
      <name>clean</name>
      <element><name>to_size</name></element>
      <element><name>order_by</name></element>
      <element><name>size_trigger</name></element>
      <element><name>erase_where_clause</name></element>
    </nested_element>
    <element><name>index_hook</name></element>
    <element><name>stop_rebuild_hook</name></element>
    <nested_element>
      <name>method</name>
      <defname>DocumentDefinition:method</defname>
    </nested_element>
    <plural>qw( index_from_store
                field
                collection
                bcollection
                sort
                textsearch
                sql_index
                order_by_expression
                index_hook
                stop_rebuild_hook
                method )</plural>
    <required>'name'</required>
  </nested_element>

  <plural>
            'element',
            'nested_element',
            'blob_element',
            'method',
            'macro',
            'class',
            'store',
            'index',
            'read_hook',
            'document_write_hook',
            'plural',
            'required',
            'validate_hook',
  </plural>

</DocumentDefinition>
END
}

1;
