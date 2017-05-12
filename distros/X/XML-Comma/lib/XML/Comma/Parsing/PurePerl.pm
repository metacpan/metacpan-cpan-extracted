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

package XML::Comma::Parsing::PurePerl;
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
  my ( $class, %arg ) = @_; my $self = {}; bless ( $self, $class );
  $self->{_top_level_class} = $arg{top_level_class} || 'XML::Comma::Doc';
  $self->{_pos} = $self->{_wpos} = 0;
  $self->{_el_stack} = [];

  if ( $arg{block} ) {
    $self->{_string} = $arg{block};
  } elsif ( $arg{file} ) {
    $self->{_from_file} = $arg{file};
    open ( my $fh, "${ \( $arg{file} )}" ) ||
      die "can't open file '${ \( $arg{file} )}': $!\n";
    local $/ = undef;
    $self->{_string} = <$fh>;
    close ( $fh );
  } else {
    die "no block or filename to parse";
  }

  return $self->handle_document ( $arg{read_args} );
}

# create a closure to process include directives :
#
# handle_args -- bundle of arguments to pass directly to handle_element
#
# args to pass to the closure, when executed:
#
# name        -- name of include for DefManager to find
# args_string -- extra arguments provided to a dynamic include
# [or]   block       -- chunk of text to directly include

sub includes_parser {
  my ( $parent, $handle_element_args ) = @_;
  my $self = {}; bless ( $self, ref($parent) );
  $self->{_pos} = $self->{_wpos} = 0;
  $self->{_el_stack} = [];
  $self->{_in_include} = 1;
  return sub {
    my %arg = @_;
    if ( $arg{block} ) {
      $self->{_string} = $arg{block};
      $self->{_from_file} = '';
    } else {
      ( $self->{_string}, $self->{_from_file} ) =
        XML::Comma::DefManager->include_string ( $arg{name},$arg{args_string} );
    }
    # dbg 'str', $self->{_string};
    eval {
      $self->handle_element ( @{$handle_element_args} );
    }; if ( $@ ) {
      my $context = join '/', map { $_->tag() } $self->down_tree_branch();
      $context = ($self->{_from_file}.':'.$context) if $self->{_from_file};
      $self->{_el_stack} = undef;
      XML::Comma::Log->err
          ( 'PARSE_ERR', $@, undef,
            "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
    }
    $self->{_el_stack} = undef;
  }
}



sub parse {
  my ( $class, %arg ) = @_; my $self = {}; bless ( $self, $class );
  $self->{_pos} = $self->{_wpos} = 0;
  $self->{_el_stack} = [];
  $self->{_string} = $arg{block} || die "need a block to PurePerl::parse";
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
    $self->{_el_stack} = undef;
    XML::Comma::Log->err 
        ( 'PARSE_ERR', $@, undef,
          "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
  }
  $self->{_el_stack} = undef;
}


sub raw_append {}
sub cdata_wrap {}

####
# document parsing
####

sub handle_document {
  my ( $self, $read_args ) = @_;
  my $doc;
  eval {
    # prolog and outermost envelope
    my ( $type, $string, $tag ) = $self->skip_prolog();
    # create document
    $doc = $self->{_top_level_class}
      ->new ( type => $tag,
              from_file => $self->{_from_file},
              last_mod_time => 
                $self->{_from_file} ? (stat($self->{_from_file}))[9] : 0,
              read_args => $read_args );
    push @{$self->{_el_stack}}, $doc;
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
    $context = ($self->{_from_file}.':'.$context) if $self->{_from_file};
    $self->{_el_stack} = undef;
    XML::Comma::Log->err 
        ( 'PARSE_ERR', $@, undef,
          "(in '$context' at " . $self->pos_line_and_column() . ")\n" );
  }
  $self->{_el_stack} = undef;
  return $doc;
}

sub down_tree_branch {
  my $self = shift();
  return @{$self->{_el_stack}};
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
        push @{$self->{_el_stack}}, $new;
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
          pop @{$self->{_el_stack}};
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
      unless ( $self->{_in_include} ) {
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
  pos ( $self->{_string} ) = 0;
  while ( $self->{_string} =~ /(\r\n)|(\r)|(\n)/g ) {
    last  if  pos($self->{_string}) > $self->{_pos};
    $line++;
    $pos = pos ( $self->{_string} );
  }
  $col = $self->{_pos} - $pos;
  return "line $line, column $col";
}


####
# token-level routines
####

sub eat_whitespace {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    last  if  ! ( $c eq ' ' or
                  $c eq "\n" or
                  $c eq "\r" or
                  $c eq "\t" );
  }
  $self->pushback_c()  if  defined $c;
  $self->{_pos} = $self->{_wpos};
}

sub next_token {
  my $self = shift();
  my $c = $self->get_c();
  # dbg 'c',$c,1;
  if ( ! defined $c ) {
    return ( $DONE, undef, undef );
  } elsif ( $c eq '<' ) {
    return $self->b_token();
  } else {
    return $self->text();
  }
}

sub b_token {
  my $self = shift();
  my $c = $self->get_c();
  if ( $c eq '/' ) {
    return $self->close_tag();
  } elsif ( $c eq '?' ) {
    return $self->processing_instruction();
  } elsif ( $c eq '!' ) {
    return $self->bang_instruction();
  } else {
    return $self->open_tag();
  }
}

sub open_tag {
  my $self = shift();
  my $tag_name;
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    if ( ($c eq ' ' or $c eq "\t" or $c eq "\n" or $c eq "\r" or $c eq "/") and
         (! $tag_name) ) {
      $tag_name = substr $self->{_string}, $self->{_pos}+1,
        $self->{_wpos} - $self->{_pos} - 2;
      if ( $tag_name !~ /^[a-zA-Z_][a-zA-Z_:0-9]*$/ ) {
        die "illegally named tag '$tag_name'\n";
      }
    } elsif ( $c eq '>' ) {
      if ( ! $tag_name ) {
        $tag_name = substr $self->{_string}, $self->{_pos}+1, 
          $self->{_wpos} - $self->{_pos} - 2;
        if ( $tag_name !~ /^[a-zA-Z_][a-zA-Z_0-9]*$/ ) {
          die "illegally named tag '$tag_name'";
        }
      }
      my $token_string = substr $self->{_string}, $self->{_pos},
        $self->{_wpos} - $self->{_pos};
      $self->{_pos} = $self->{_wpos};
      if ( $token_string =~ m:/>$: ) {
        return ( $EMPTY_ELEMENT, $token_string, $tag_name );
      } else {
        return ( $OPEN_TAG, $token_string, $tag_name );
      }
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside open tag...\n";
}

sub close_tag {
  my $self = shift();
  my $tag_name;
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    if ( $c eq '>' ) {
      $tag_name = substr $self->{_string}, $self->{_pos}+2,
        $self->{_wpos} - $self->{_pos} - 3;
      my $token_string = substr $self->{_string}, $self->{_pos},
        $self->{_wpos} - $self->{_pos};
      $self->{_pos} = $self->{_wpos};
      return ( $CLOSE_TAG, $token_string, $tag_name );
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside close tag\n";
}

sub processing_instruction {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    if ( $c eq '?' and $self->get_c() eq '>') {
      my $token_string = substr $self->{_string}, $self->{_pos},
        $self->{_wpos} - $self->{_pos};
      $self->{_pos} = $self->{_wpos};
      return ( $PROCESSING_INSTRUCTION, $token_string, undef );
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside <?...\n";
}

sub bang_instruction {
  my $self = shift();
  my $next = $self->get_chars(2);
  if ( $next eq '--' ) {
    return $self->comment()
  } elsif ( $next eq 'DO' and $self->get_chars(5) eq 'CTYPE' ) {
    return $self->doctype();
  } elsif ( $next eq '[C' and $self->get_chars(5) eq 'DATA[' ) {
    return $self->cdata();
  } else {
    die "unrecognized tag, '<!$next'";
  }
}

sub doctype {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    if ( $c eq '>' ) {
      my $token_string = substr $self->{_string}, $self->{_pos},
        $self->{_wpos} - $self->{_pos};
      $self->{_pos} = $self->{_wpos};
      return ( $DOCTYPE, $token_string, undef );
    } elsif ( $c eq '[' ) {
      die "parser doesn't handle in-line doctype declarations\n";
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside <!DOCTYPE...\n";
}

sub comment {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c(1)) ) {
    if ( $c eq '-' and $self->get_c(1) eq '-' ) {
      if ( $self->get_c(1) eq '>' ) {
        my $token_string = substr $self->{_string}, $self->{_pos},
          $self->{_wpos} - $self->{_pos};
        $self->{_pos} = $self->{_wpos};
        return ( $COMMENT, $token_string, undef );
      } else {
        die "string '--' not allowed inside comments\n";
      }
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside a comment\n";
}

sub cdata {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c(1)) ) {
    if ( $c eq ']' ) {
      my $point = $self->{_wpos};
      if ( $self->get_c(1) eq ']' and $self->get_c(1) eq '>' ) {
        my $token_string = substr $self->{_string}, $self->{_pos},
          $self->{_wpos} - $self->{_pos};
        my $contents_string = substr $token_string, 9, length($token_string)-12;
        $self->{_pos} = $self->{_wpos};
        return ( $CDATA, $token_string, $contents_string );
      } else {
        $self->{_wpos} = $point;
      }
    }
  }
  # if we get here, we've exited the while loop by overrunning the
  # end of our string
  die "reached end of document while inside <![CDATA...\n";
}

sub text {
  my $self = shift();
  my $c;
  while ( defined ($c = $self->get_c()) ) {
    if ( $c eq '<' ) {
      $self->pushback_c();
      my $token_string = substr $self->{_string}, $self->{_pos},
        $self->{_wpos} - $self->{_pos};
      $self->{_pos} = $self->{_wpos};
      return ( $TEXT, $token_string, undef );
    }
  }
  # if we get here, we've exited the while loop by overrunning the end
  # of our string. but we need to let someone higher up handle this
  # problem, so just return what we've gotten up to this point...
  return ( $TEXT, substr($self->{_string}, $self->{_pos},
                         $self->{_wpos} - $self->{_pos}), undef );
}

# gets the next character. unless $ignore_amps is set, skips over
# entities (returns the ';'), and dies if a non-entitieizing & is
# found
sub get_c {
  my ( $self, $ignore_amps ) = @_;
  if ( $self->{_wpos} >= length $self->{_string} ) {
    return undef;
  }
  my $c = substr $self->{_string}, $self->{_wpos}++, 1;
  if ( $c eq '&' and ! $ignore_amps ) {
    while ( defined ($c = $self->get_c()) ) {
      if ( $c eq ';' ) {
        return $c;
      } elsif ( $c !~ /[a-zA-Z_0-9#]/ ) {
        $self->{_pos} = $self->{_wpos};
        die "& found that isn't part of an entity reference\n";
      }
    }
    # if we get here, we've exited the while loop by overrunning the
    # end of our string
    die "reached end of document while trying to parse an entity\n";
  }
  return $c;
}

sub get_chars {
  my ( $self, $num ) = @_;
  my $str = '';
  for ( 1..$num ) {
    my $c = $self->get_c();
    if ( defined($c) ) {
      $str .= $c;
    } else {
      die "reached end of document unexpectedly\n";
    }
  }
  return $str;
}

sub pushback_c {
  $_[0]->{_wpos}--;
}


1;

