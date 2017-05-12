##
#
#    Copyright 2001-2004, AllAfrica Global Media
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

package XML::Comma::Parsing::SAXEventParser;
use strict;

use XML::Comma;
use XML::Parser::PerlSAX;
use Unicode::String;

use XML::Comma::Util qw( dbg );
use Carp;

# _parser
# _current_element
# _element_stack
# _local_tag_stack
# _last_action
# _top_level_class
# _doc
# _inside_cdata
# _from_file

sub new {
  my ( $class, %arg ) = @_; my $self = {}; bless ( $self, $class );
  $self->{_top_level_class} = $arg{top_level_class} || 'XML::Comma::Doc';
  $self->{_element_stack} = [];
  $self->{_local_tag_stack} = [];
  $self->{_inside_cdata} = 0;
  $self->{_last_action} = '';

  my $doc;

  $self->{_parser} = XML::Parser::PerlSAX->new ( Handler=>$self );

  if ( $arg{block} ) {
    $doc = $self->{_parser}->parse ( $arg{block} );
  } elsif ( $arg{filename} ) {
    $self->{_from_file} = $arg{filename};
    $doc = $self->{_parser}->parse( Source =>
                           {
                            SystemId => $arg{filename},
                            # for some reason, the following as an encoding
                            # specifier sometimes? mucks up accented stuff
                            Encoding => 'ISO-8859-1'
                           } );
  } else {
    die "need a block or a filename to parse\n";
  }

  # break circular reference and return the new doc
  $self->{_parser} = undef;
  $self->{_doc} = undef;
  return $doc;
}

sub parse {
  my ( $class, %arg ) = @_;
  my $text = $arg{block} || die "need a block to SAXEventParser::parse";
  XML::Parser::PerlSAX->new()->parse( Source =>
                                      { String => $text,
                                        Encoding => 'ISO-8859-1' } );
}


sub fatal_error {
  print "fatal error";
  die "fatal error";
}

sub error {
  print "error";
  die "error";
}

sub warning {
  print "warning";
}

sub start_element {
  my ( $self, $el ) = @_;
  if ( $self->{_current_element} ) {
    if ( ref($self->{_current_element}) eq 'XML::Comma::Bootstrap' or
             $self->{_current_element}->def()->is_nested() ) {
      my $new_el;
      eval {
        $new_el = $self->{_current_element}->add_new( $el->{Name} );
      }; if ( $@ ) {
        # can't get more debugging information from parser as
        # of version 22/Feb. 2000
        # my $line_number = $self->{_parser}->location();
        die "$@\n";
      }
      push @{$self->{_element_stack}}, $self->{_current_element};
      $self->{_current_element} = $new_el;
      $self->{_local_tag_stack} = [];
      $self->{_last_action} = 'start_element';
    } else {
      # not-nested -- leaving tags *and attributes* intact
      #dbg "appending", $el->{Name};
      my $text = $self->tag_append_string ( $el );
      $self->{_current_element}->raw_append ( $text )  if  $text;
      push @{$self->{_local_tag_stack}}, $el->{Name};
      $self->{_last_action} = 'characters';
    }
  } else {
    # make a new object, passing it the from_file the last mod time of
    # that file if there is a from_file. The constructor may or may
    # not do anything with those two pieces of information.
    $self->{_doc} = $self->{_top_level_class}->new
      ( type => $el->{Name},
        from_file => $self->{_from_file} || '',
        last_mod_time => $self->{_from_file} ?
                         (stat($self->{_from_file}))[9] : 0 );
    $self->{_current_element} = $self->{_doc};
  }
}

sub end_element {
  my ( $self, $el ) = @_;
#  dbg 'end', $self->{_current_element};
  if ( scalar @{$self->{_local_tag_stack}} == 0 ) {
    $self->{_current_element}->finish_initial_read ( $self );
    $self->{_current_element} = pop ( @{$self->{_element_stack}} );
    $self->{_last_action} = 'end_element';
  } else {
    my $text = $self->tag_append_string ( $el, 1 );
    $self->{_current_element}->raw_append ( $text )  if  $text;
    pop ( @{$self->{_local_tag_stack}} );
    $self->{_last_action} = 'characters';
  }
}

sub end_document {
  return $_[0]->{_doc};
}

sub characters {
  my ( $self, $chars ) = @_;
#  dbg "curr", $self->{_current_element} || '';
#  dbg "chars", $chars->{Data};
  if ( ! $self->{_inside_cdata} ) {
    $chars->{Data} =~ s/\&/\&amp\;/g ;
    $chars->{Data} =~ s/\</\&lt\;/g  ;
    $chars->{Data} =~ s/\>/\&gt\;/g  ;
  }
  $self->{_current_element}->raw_append 
    ( Unicode::String::utf8($chars->{Data})->latin1() );
#  $self->{_current_element}->raw_append ( $chars->{Data} );
  $self->{_last_action} = 'characters';
}

sub start_cdata {
  $_[0]->{_inside_cdata} = 1;
  $_[0]->{_current_element}->start_cdata();
}

sub end_cdata {
  $_[0]->{_inside_cdata} = 0;
}


sub tag_append_string {
  my ( $self, $el, $close ) = @_;
  if ( $close ) {
    return '</' . $el->{Name} . '>';
  } else {
    my $el_string = '<' . $el->{Name};
    foreach my $att ( keys %{$el->{Attributes}} ) {
      my $att_value = $el->{Attributes}->{$att};
      $att_value =~ s/\&/\&amp\;/g ;
      $att_value =~ s/\</\&lt\;/g  ;
      $att_value =~ s/\>/\&gt\;/g  ;
      $el_string .= " $att=\"" . $att_value . '"';
    }
    $el_string .= '>'
  }
}

sub down_tree_branch {
  my $self = shift();
  return ( @{$self->{_element_stack}}, $self->{_current_element} );
}


#  sub DESTROY {
#    print "SAX Destroy\n";
#  }


######

1;





