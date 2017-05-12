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

##
#
# This parser and the PurePerl parser share very similar top_level
# code (all the stuff in perl, here). The main difference are 1) this
# module needs to do special _c_new stuff to create an object, and 2)
# the resulting objects aren't hashrefs and use accessor methods where
# the PurePerl version sometimes uses private hash slots. 
#
# It would be nice to refactor the code so that both of these inherit
# from a common abstract parent. On the other hand, it's probably not
# worth doing all that refactoring unless the architecture needs to
# change substantially, as the code here is stable and well-tested.
#
##

package XML::Comma::Parsing::SimpleC;
use strict;

use XML::Comma;
use XML::Comma::Util qw( dbg trim );

my $OPEN_TAG               = 1;
my $CLOSE_TAG              = 2;
my $COMMENT                = 3;
my $CDATA                  = 4;
my $PROCESSING_INSTRUCTION = 5;
my $DOCTYPE                = 6;
my $TEXT                   = 7;
my $DONE                   = 8;
my $EMPTY_ELEMENT          = 9;

# _top_level_class
# _from_file
# _string
# _pos
# _wpos
# _el_stack : [] for reporting context

sub new {
  my ( $class, %arg ) = @_; 
  my $string;
  my $file;

  if ( $arg{block} ) {
    $string = $arg{block};
  } elsif ( $arg{file} ) {
    $file = $arg{file};
    open ( my $fh, "${ \( $arg{file} )}" ) ||
      die "can't open file '${ \( $arg{file} )}': $!\n";
    local $/ = undef;
    $string = <$fh>;
    close ( $fh );
  } else {
    die "no block or filename to parse";
  }

  my $self = _c_new ( 'XML::Comma::Parsing::SimpleC',
                      $string,
                      $file || '',
                      $arg{top_level_class} || 'XML::Comma::Doc',
                      0 );
  return $self->handle_document ( $arg{read_args} );
}


sub includes_parser {
  my ( $parent, $handle_element_args ) = @_; 
  return sub {
    my %arg = @_;
    my $string; my $file;
    if ( $arg{block} ) {
      $string = $arg{block}; $file = '';
    } else {
      ( $string, $file ) =
        XML::Comma::DefManager->include_string ( $arg{name},$arg{args_string} );
    }
    my $self = _c_new ( 'XML::Comma::Parsing::SimpleC',
                        $string,
                        $file,
                        $parent->top_level_class(),
                        1 );
    eval {
      $self->handle_element ( @{$handle_element_args} );
    }; if ( $@ ) {
      # otherwise, we should construct a pretty error string
      my $context = join '/', map { $_->tag() } $self->down_tree_branch();
      $context = ( $file . ':' . $context) if  $file;
      XML::Comma::Log->err 
          ( 'PARSE_ERR', $@, undef,
            "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
    }
  }
}



sub parse {
  my ( $class, %arg ) = @_;

  my $string = $arg{block} || die "need a block to SimpleC::parse";
  my $self = _c_new ( 'XML::Comma::Parsing::SimpleC', $string, '', '', 0 );

  eval {
    # prolog
    my ( $type, $string, $tag ) = $self->skip_prolog();
    # root element
    $self->handle_element ( $self, $tag, 0, 0 );
    # nothing else
    $self->eat_whitespace();
    ( $type, $string, $tag ) = $self->next_token();
    while ( $type != $DONE ) {
      if ( $string            and
           $type != $COMMENT  and  $type != $PROCESSING_INSTRUCTION ) {
        die "more content found after root element: '$string'\n";
      }
      $self->eat_whitespace();
    ( $type, $string, $tag ) = $self->next_token();
    }
  }; if ( $@ ) {
    my $context = join '/', map { $_->tag() } $self->down_tree_branch();
    undef @{$self->_el_stack()};
    XML::Comma::Log->err 
        ( 'PARSE_ERR', $@, undef, 
          "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
  }
}


sub raw_append {}
sub cdata_wrap {}

####
# document parsing
####

sub handle_document {
  my ( $self, $read_args ) = @_;
  my $doc;
  my $file = $self->from_file();
  eval {
    # prolog and outermost envelope
    my ( $type, $string, $tag ) = $self->skip_prolog();
    # create document
    $doc = $self->top_level_class()
      ->new ( type => $tag,
              from_file => $file,
              last_mod_time => ($file ? (stat($file))[9] : 0),
              read_args => $read_args );
    push @{$self->_el_stack()}, $doc;
    # recursively handle elements
    $self->handle_element ( $doc, $tag, 1, 1 );
    # nothing else except comments and whitespace
    $self->eat_whitespace();
    ( $type, $string, $tag ) = $self->next_token();
    while ( $type != $DONE ) {
      if ( $type != $COMMENT and $type != $PROCESSING_INSTRUCTION ) {
        die "more content found after root element: '$string'\n";
      }
      $self->eat_whitespace();
    ( $type, $string, $tag ) = $self->next_token();
    }
  }; if ( $@ ) {
    my $context = join '/', map { $_->tag() } $self->down_tree_branch();
    $context = ($file . ':' . $context) if $file;
    XML::Comma::Log->err 
        ( 'PARSE_ERR', $@, undef,
          "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
  }
  return $doc;
}

sub down_tree_branch {
  my $self = shift();
  return @{$self->_el_stack()};
}

sub skip_prolog {
  my $self = shift();
  # let's be overly forgiving and accept docs with leading whitespace
  $self->eat_whitespace();
  my ( $type, $string, $special ) = $self->next_token();
  while ( $type != $OPEN_TAG ) {
    if ( $type == $CDATA ) {
      die "unexpected CDATA\n";
    } elsif ( $type == $TEXT ) {
      die "text outside of root element\n";
    } elsif ( $type == $DONE ) {
      die "no document content\n";
    }
    $self->eat_whitespace();
    ( $type, $string, $special ) = $self->next_token();
  }
  return ( $type, $string, $special );
}

sub handle_element {
  my ( $self, $el, $tag, $nested, $comma_level ) = @_;
  while ( 1 ) {
    my ( $type, $string, $special ) = $self->next_token();
    if ( $type == $TEXT ) {
      # text -- append (let el do its own checking)
      $el->raw_append ( $string );
    } elsif ( $type == $OPEN_TAG ) {
      # open tag -- recurse
      if ( $nested ) {
        my $new = $el->add_element ( $special, $string );
        push @{$self->_el_stack()}, $new;
        $self->handle_element
          ( $new,
            $special,
            ($new->def() ? $new->def()->is_nested() : 1),
            1 );
      } else {
        $el->raw_append ( $string );
        $self->handle_element ( $el, $special, 0, 0 );
      }
    } elsif ( $type == $EMPTY_ELEMENT ) {
      if ( $nested ) {
        $el->add_element ( $special );
      } else {
        $el->raw_append ( $string );
      }
    } elsif ( $type == $CLOSE_TAG ) {
      # close tag -- check for match and return
      if ( $special eq $tag ) {
        if ( $comma_level ) {
          $el->finish_initial_read ( $self );
          pop @{$self->_el_stack()};
        } else {
          $el->raw_append ( $string );
        }
        return; # ok
      } else {
        die "mismatched tag: '$tag', '$special'\n";
      }
    } elsif ( $type == $CDATA ) {
      # cdata -- extract and append
      if ( $nested ) {
        die "cdata content '$string' found for nested element '$tag'\n";
      } else {
        $el->cdata_wrap();
        $el->raw_append ( $special );
      }
    } elsif ( $type == $DOCTYPE ) {
      # doctype -- throw an error
      die "doctype after prolog\n";
    } elsif ( $type == $DONE ) {
      unless ( $self->_in_include() ) {
        # finished prematurely
        die "reached end of document unexpectedly\n";
      }
      return; # putatively ok
    } elsif ( $type == $PROCESSING_INSTRUCTION ) {
      my $content = trim ( substr $string, 2, length($string) - 4 );
      my ( $directive, $first_word, $rest ) = split ( /\s+/, $content, 3 );
      if ( $directive  and  $directive eq '#include' ) {
        die "#include directive with no include name given\n"
          unless $first_word;
        $self->includes_parser ( [ $el, $tag, $nested, $comma_level ] )
          ->( name        => $first_word,
              args_string => $rest );
      }
      ## ignore other processing instructions
    }
    ## ignore comments
  }
}

sub pos_line_and_column {
  my $self = shift();
  my $line = 1;
  my $pos = 0;
  my $col = 0;
  my $string = $self->string();
  while ( $string =~ /(\r\n)|(\r)|(\n)/g ) {
    last  if  pos($string) > $self->pos();
    $line++;
    $pos = pos ( $string );
  }
  $col = $self->pos() - $pos;
  return "line $line, column $col";
}


# ------------------------------------------------------------------------------
# C code follows
# ------------------------------------------------------------------------------

my $code;
BEGIN {
  $code = <<'END';

#include <string.h>

typedef struct {
  char* pos;
  char* wpos;
  char* string;
  char* from_file;
  char* doc_class;
  AV*   el_stack;
  int  in_include;
} Cobj;

SV* _c_new ( char* class, char* string, char* from_file, char* doc_class, int in_include );
void DESTROY ( SV* self );

char* from_file ( SV* obj );
char* top_level_class ( SV* obj );
int pos ( SV* obj );
int _in_include ( SV* obj );
char* string ( SV* obj );
AV* _el_stack ( SV* obj );

void eat_whitespace ( SV* self );
void next_token ( SV* self );
void done_return ( void );
void b_token ( Cobj* cobj );
void open_tag ( Cobj* cobj );
void close_tag ( Cobj* cobj );
void processing_instruction ( Cobj* cobj );
void bang_instruction ( Cobj* cobj );
void doctype ( Cobj* cobj );
void comment ( Cobj* cobj );
void cdata ( Cobj* cobj );
void text ( Cobj* cobj );
char t_get_c ( Cobj* cobj );

//----------------------------------------

SV* _c_new ( char* class, char* string, char* from_file, char* doc_class, int in_include ) {
  Cobj*   cobj = malloc ( sizeof(Cobj) );
  SV*     obj_ref = newSViv(0);
  SV*     obj = newSVrv ( obj_ref, class );

  cobj->string = strdup ( string );
  cobj->pos = cobj->string;
  cobj->wpos = cobj->string;
  cobj->from_file = strdup ( from_file );
  cobj->doc_class = strdup ( doc_class );
  cobj->el_stack = newAV();
  cobj->in_include = in_include;

  sv_setiv ( obj, (IV)cobj );
  SvREADONLY_on ( obj );
  return obj_ref;
}

void DESTROY ( SV* self ) {
  Cobj* cobj = (Cobj*)SvIV(SvRV(self));
  free ( cobj->string );
  free ( cobj->from_file );
  free ( cobj->doc_class );
  av_undef ( cobj->el_stack );
  sv_2mortal ( (SV*)cobj->el_stack );
  free ( cobj );
}

//----------------------------------------

char* from_file ( SV* obj ) {
  return ((Cobj*)SvIV(SvRV(obj)))->from_file;
}

char* top_level_class ( SV* obj ) {
  return ((Cobj*)SvIV(SvRV(obj)))->doc_class;
}

// get position, relative to start of string
int pos ( SV* obj ) {
  return (((Cobj*)SvIV(SvRV(obj)))->pos) - (((Cobj*)SvIV(SvRV(obj)))->string);
}

// get boolean indicating whether we're processing an include file or not
int _in_include ( SV* obj ) {
  return (((Cobj*)SvIV(SvRV(obj)))->in_include);
}


char* string ( SV* obj ) {
  return ((Cobj*)SvIV(SvRV(obj)))->string;
}

AV* _el_stack ( SV* obj ) {
  return ((Cobj*)SvIV(SvRV(obj)))->el_stack;
}

void eat_whitespace ( SV* self ) {
  Cobj* cobj = (Cobj*)SvIV(SvRV(self));
  cobj->pos += strspn ( cobj->pos, " \t\n\r" );
  cobj->wpos = cobj->pos;
}

//----------------------------------------

void next_token ( SV* self ) {
  Cobj* cobj = (Cobj*)SvIV(SvRV(self));
  char c = t_get_c(cobj);
  if ( c == '\0' ) {
    return done_return();
  } else if ( c == '<' ) {
    return b_token(cobj);
  } else {
    return text(cobj);
  }
}

void done_return() {
  Inline_Stack_Vars;
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(8))); //DONE
  Inline_Stack_Done;
  Inline_Stack_Return ( 1 );
}

void b_token ( Cobj* cobj ) {
  char c = t_get_c(cobj);
  if ( c == '/' ) {
    return close_tag(cobj);
  } else if ( c == '?' ) {
    return processing_instruction(cobj);
  } else if ( c == '!' ) {
    return bang_instruction(cobj);
  } else {
    return open_tag(cobj);
  }
}

void open_tag ( Cobj* cobj ) {
  char c;
  char* i;
  char* tag_name_end;
  Inline_Stack_Vars;

  cobj->wpos = strchr ( cobj->pos, '>' );
  if ( cobj->wpos == NULL ) {
    croak ( "reached end of document while inside open tag...\n" );
  }
  tag_name_end = strpbrk ( cobj->pos, "/ \t\n\r>" );
  cobj->wpos++;

  // check tag name
  for ( i=(cobj->pos)+1; i < tag_name_end; i++ ) {
    c = *i;
    if ( ! (((c >= 'a') && (c <= 'z')) ||
            ((c >= 'A') && (c <= 'Z')) ||
            ((c >= '0') && (c <= '9')) ||
             (c == '_')                ||
             (c == ':')) ) {
      croak ( "illegal tag name\n" );
    }
  }

  // check entity legality inside tag
  check_entities ( cobj, cobj->pos, cobj->wpos );

  Inline_Stack_Reset;
  if ( *(cobj->wpos - 2) == '/' ) {
    Inline_Stack_Push(sv_2mortal(newSViv(9))); //EMPTY_ELEMENT
  } else {
    Inline_Stack_Push(sv_2mortal(newSViv(1))); //OPEN_TAG
  }
  // complete token string
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos, cobj->wpos - cobj->pos)));
  // tag name string
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos + 1,
                                        tag_name_end - (cobj->pos + 1))));
  cobj->pos = cobj->wpos;
  Inline_Stack_Done;
  Inline_Stack_Return ( 3 );
}

void close_tag ( Cobj* cobj ) {
  char c;
  Inline_Stack_Vars;
  cobj->wpos = strchr ( cobj->pos, '>' );

  if ( cobj->wpos == NULL ) {
    croak ( "reached end of document while inside close tag\n" );
  }

  cobj->wpos++;
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(2))); //CLOSE_TAG
  // complete token string
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos - cobj->pos)));
  // tag name string
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos + 2,
                                        cobj->wpos - cobj->pos - 3)));
//      printf ( "tag name: %s\n", SvPV(tagname,PL_na) );
  Inline_Stack_Done;
  cobj->pos = cobj->wpos;;
  Inline_Stack_Return ( 3 );
}

void processing_instruction ( Cobj* cobj ) {
  char c;
  Inline_Stack_Vars;

  cobj->wpos = strstr ( cobj->pos, "?>" );

  if ( cobj->wpos == NULL ) {
    croak ( "reached end of ducument while inside <?...\n" );
  }

  cobj->wpos += 2;
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(5))); //PROCESSING_INSTRUCTION
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos - cobj->pos)));
  Inline_Stack_Done;
  cobj->pos = cobj->wpos;
  Inline_Stack_Return ( 2 );
}

void bang_instruction ( Cobj* cobj ) {
  char c,d;
  c = *(cobj->wpos++); d = *(cobj->wpos++);
  if ( (c == '-') && (d == '-') ) {
    return comment(cobj);
  } else if ( (c == 'D') && (d == 'O') &&
              (*(cobj->wpos++) == 'C') && (*(cobj->wpos++) == 'T') &&
              (*(cobj->wpos++) == 'Y') && (*(cobj->wpos++) == 'P') &&
              (*(cobj->wpos++) == 'E') ) {
    return doctype(cobj);
  } else if ( (c == '[') && (d == 'C') &&
              (*(cobj->wpos++) == 'D') && (*(cobj->wpos++) == 'A') &&
              (*(cobj->wpos++) == 'T') && (*(cobj->wpos++) == 'A') &&
              (*(cobj->wpos++) == '[') ) {
    return cdata(cobj);
  } else {
    croak ( "bad <! tag\n" );
  }
}

void doctype ( Cobj* cobj ) {
  char c;
  Inline_Stack_Vars;
  while ( (c = t_get_c(cobj)) != '\0' ) {
    if ( c == '>' ) {
      Inline_Stack_Reset;
      Inline_Stack_Push(sv_2mortal(newSViv(6)));
      Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos - cobj->pos)));
      Inline_Stack_Done;
      cobj->pos = cobj->wpos;
      Inline_Stack_Return ( 2 );
    } else if ( c == '[' ) {
      croak ( "parser doesn't handle in-line doctype declarations\n" );
    }
  }
  croak ( "reached end of document while inside <!DOCTYPE...\n" );
}

void comment ( Cobj* cobj ) {
  char c;
  Inline_Stack_Vars;
  cobj->wpos = strstr ( cobj->pos+4, "--" );

  if ( cobj->wpos == NULL ) {
    croak ( "reached end of document while inside a comment\n" );
  }

  cobj->wpos += 2;
  if ( t_get_c(cobj) == '>' ) {
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(3))); //COMMENT
    Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos-cobj->pos)));
    Inline_Stack_Done;
    cobj->pos = cobj->wpos;
    Inline_Stack_Return ( 2 );
  } else {
    croak ( "string '--' not allowed inside comments\n" );
  }
}

void cdata ( Cobj* cobj ) {
  char c;
  Inline_Stack_Vars;
  cobj->wpos = strstr ( cobj->pos, "]]>" );

  if ( cobj->wpos == NULL ) {
    croak ( "reached end of document while inside <![CDATA...\n" );
  }

  cobj->wpos += 3;
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(4))); //CDATA
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos-cobj->pos)));
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos+9,
                                        cobj->wpos - cobj->pos - 12)));
  Inline_Stack_Done;
  cobj->pos = cobj->wpos;
  Inline_Stack_Return ( 3 );
}


void text ( Cobj* cobj ) {
  char c;
  //char* index;
  Inline_Stack_Vars;
  cobj->wpos = strchr ( cobj->pos, '<' );

  // make sure we haven't overrun our document end. if we have, return
  // what we've got so far and let someone higher up the stack worry
  // about it
  if ( cobj->wpos == NULL ) {
    cobj->wpos = index ( cobj->pos, '\0' );
  }
  // make sure all the entities in this text chunk look legal
  check_entities ( cobj, cobj->pos, cobj->wpos );

  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSViv(7))); //TEXT
  Inline_Stack_Push(sv_2mortal(newSVpvn(cobj->pos,cobj->wpos - cobj->pos)));
  Inline_Stack_Done;
  cobj->pos = cobj->wpos;
  Inline_Stack_Return ( 2 );
}

void check_entities ( Cobj* cobj, char* start, char* end ) {
  char c;
  char* pos = strchr ( start, '&' );
  while ( (pos < end) && (pos != NULL) ) {
    // each char until ; must be a-zA-Z0-9
    while ( (c = *(++pos)) != ';' ) {
      if ( (pos >= end) || ! (((c >= 'a') && (c <= 'z')) ||
                              ((c >= 'A') && (c <= 'Z')) ||
                              ((c >= '0') && (c <= '9')) ||
                                              (c == '_') || (c == '#')) ) {
        // not ok, set pos so perl error reporting will give the right pos
        cobj->pos = pos;
        croak ( "& found that isn't part of an entity reference" );
      }
    }
    pos = strchr ( pos, '&' );
  }
}

char t_get_c ( Cobj* cobj ) {
  // return undef if we've overreached the end of the string
  if ( ((cobj->wpos) - (cobj->string)) >= strlen(cobj->string) ) {
    return '\0';
  }
  return *(cobj->wpos)++;
}

END
}

use Inline C => $code,
  DIRECTORY => XML::Comma->sys_directory();

1;
