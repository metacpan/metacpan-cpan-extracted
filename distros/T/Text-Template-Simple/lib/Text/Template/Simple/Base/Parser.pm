## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Parser;
$Text::Template::Simple::Base::Parser::VERSION = '0.91';
use strict;
use warnings;

use Text::Template::Simple::Util      qw(:all);
use Text::Template::Simple::Constants qw(:all);
use constant MAPKEY_NUM => 5;

my %INTERNAL = __PACKAGE__->_set_internal_templates;

sub _needs_object {
   my $self = shift;
   $self->[NEEDS_OBJECT]++;
   return $self;
}

sub _internal {
   my $self = shift;
   my $id   = shift            || fatal('tts.base.parser._internal.id');
   my $rv   = $INTERNAL{ $id } || fatal('tts.base.parser._internal.id');
   LOG( INTERNAL => "TEMPLATE: $id" ) if DEBUG;
   return $rv;
}

sub _parse {
   my($self, $raw, $opt) = @_;

   # $opt->
   #      map_keys: code sections are hash keys
   #      as_is   : i.e.: do not parse -> static include

   #$self->[NEEDS_OBJECT] = 0; # reset

   my($ds, $de) = @{ $self->[DELIMITERS] };
   my $faker    = $self->[INSIDE_INCLUDE] ? $self->_output_buffer_var
                                          : $self->[FAKER]
                                          ;
   my $buf_hash = $self->[FAKER_HASH];
   my($mko, $mkc) = $self->_parse_mapkeys( $opt->{map_keys}, $faker, $buf_hash );

   LOG( RAW => $raw ) if DEBUG > DEBUG_LEVEL_INSANE;

   my $h = {
      raw     => sub { ";$faker .= q~$_[0]~;" },
      capture => sub { ";$faker .= sub {" . $_[0] . '}->();'; },
      code    => sub { $_[0] . q{;} },
   };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $opt->{as_is};

   my($code, $inside) = $self->_walk( $raw, $opt, $h, $mko, $mkc );

   $self->[FILENAME] ||= '<ANON>';

   fatal(
      'tts.base.parser._parse.unbalanced',
         abs($inside),
         ($inside > 0 ? 'opening' : 'closing'),
         $self->[FILENAME]
   ) if $inside;

   return $self->_wrapper( $code, $opt->{cache_id}, $faker, $opt->{map_keys}, $h );
}

sub _walk {
   my($self, $raw, $opt, $h, $mko, $mkc) = @_;
   my $uth    = $self->[USER_THANDLER];
   my $code   = EMPTY_STRING;
   my $inside = 0;
   my $toke   = $self->connector('Tokenizer')->new(
                  @{ $self->[DELIMITERS] },
                  $self->[PRE_CHOMP],
                  $self->[POST_CHOMP]
               );

   my $is_raw = sub { my($id) = @_; T_RAW     == $id || T_NOTADELIM == $id };
   my $is_inc = sub { my($id) = @_; T_DYNAMIC == $id || T_STATIC    == $id };

   # fetch and walk the tree
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $opt->{map_keys} ) } ) {
      my($str, $id, $chomp, undef) = @{ $token };

      LOG( TOKEN => $toke->_visualize_tid($id) . " => $str" )
         if DEBUG >= DEBUG_LEVEL_VERBOSE;

      next PARSER if T_DISCARD == $id || T_COMMENT == $id;

      if ( T_DELIMSTART == $id ) { $inside++; next PARSER; }
      if ( T_DELIMEND   == $id ) { $inside--; next PARSER; }

      $code .= $is_raw->($id)   ? $h->{raw    }->( $self->_chomp( $str, $chomp ) )
             : T_COMMAND == $id ? $h->{raw    }->( $self->_parse_command( $str ) )
             : T_CODE    == $id ? $h->{code   }->( $str                          )
             : T_CAPTURE == $id ? $h->{capture}->( $str                          )
             : $is_inc->($id)   ? $h->{capture}->( $self->_walk_inc( $opt, $id, $str) )
             : T_MAPKEY  == $id ? $self->_walk_mapkey(  $mko, $mkc, $str         )
             :                    $self->_walk_unknown( $h, $uth, $id, $str      )
             ;
   }
   return $code, $inside;
}

sub _walk_mapkey {
   my($self, $mko, $mkc, $str) = @_;
   return sprintf $mko, $mkc ? ( ($str) x MAPKEY_NUM ) : $str;
}

sub _walk_inc {
   my($self, $opt, $id, $str) = @_;
   return $self->_needs_object->include($id, $str, $opt);
}

sub _walk_unknown {
   my($self, $h, $uth, $id, $str) = @_;
   if ( DEBUG ) {
      LOG(
         $uth  ? ( USER_THANDLER => "$id" )
               : ( UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)" )
      );
   }

   return $uth ? $uth->( $self, $id ,$str, $h ) : $h->{raw}->( $str );
}

sub _parse_command {
   my $self = shift;
   my $str  = shift;
   my($head, $raw_block) = split m{;}xms, $str, 2;
   my @buf  = split RE_PIPE_SPLIT, q{|} . trim($head);
   shift @buf;
   my %com  = map { trim $_ } @buf;

   if ( DEBUG >= DEBUG_LEVEL_INSANE ) {
      require Data::Dumper;
      LOG(
         PARSE_COMMAND => Data::Dumper::Dumper(
                           {
                              string  => $str,
                              header  => $head,
                              raw     => $raw_block,
                              command => \%com,
                           }
                        )
      );
   }

   if ( $com{FILTER} ) {
      # embed into the template & NEEDS_OBJECT++ ???
      my $old = $self->[FILENAME];
      $self->[FILENAME] = '<ANON BLOCK>';
      $self->_call_filters( \$raw_block, split RE_FILTER_SPLIT, $com{FILTER} );
      $self->[FILENAME] = $old;
   }

   return $raw_block;
}

sub _chomp {
   # remove the unnecessary white space
   my($self, $str, $chomp) = @_;

   # NEXT: discard: left;  right -> left
   # PREV: discard: right; left  -> right
   my($next, $prev) = @{ $chomp };
   $next ||= CHOMP_NONE;
   $prev ||= CHOMP_NONE;

   my $left_collapse  = ( $next & COLLAPSE_ALL ) || ( $next & COLLAPSE_RIGHT);
   my $left_chomp     = ( $next & CHOMP_ALL    ) || ( $next & CHOMP_RIGHT   );

   my $right_collapse = ( $prev & COLLAPSE_ALL ) || ( $prev & COLLAPSE_LEFT );
   my $right_chomp    = ( $prev & CHOMP_ALL    ) || ( $prev & CHOMP_LEFT    );

   $str = $left_collapse  ? ltrim($str, q{ })
        : $left_chomp     ? ltrim($str)
        :                   $str
        ;

   $str = $right_collapse ? rtrim($str, q{ })
        : $right_chomp    ? rtrim($str)
        :                   $str
        ;

   return $str;
}

sub _wrapper {
   # this'll be tricky to re-implement around a template
   my($self, $code, $cache_id, $faker, $map_keys, $h) = @_;
   my $buf_hash   = $self->[FAKER_HASH];
   my $wrapper    = EMPTY_STRING;
   my $inside_inc = $self->[INSIDE_INCLUDE] != RESET_FIELD ? 1 : 0;

   # build the anonymous sub
   if ( ! $inside_inc ) {
      # don't duplicate these if we're including something
      $wrapper .= 'package ' . DUMMY_CLASS . q{;};
      $wrapper .= 'use strict;' if $self->[STRICT];
   }
   $wrapper .= 'sub { ';
   $wrapper .= sprintf q~local $0 = '%s';~, escape( q{'} => $self->[FILENAME] );
   if ( $self->[NEEDS_OBJECT] ) {
      --$self->[NEEDS_OBJECT];
      $wrapper .= 'my ' . $self->[FAKER_SELF] . ' = shift;';
   }
   $wrapper .= $self->[HEADER].q{;}            if $self->[HEADER];
   $wrapper .= "my $faker = '';";
   $wrapper .= $self->_add_stack( $cache_id )  if $self->[STACK];
   $wrapper .= "my $buf_hash = {\@_};"         if $map_keys;
   $wrapper .= $self->_add_sigwarn if $self->[CAPTURE_WARNINGS];
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . q{;};
   $wrapper .= $self->_dump_sigwarn($h) if $self->[CAPTURE_WARNINGS];
   $wrapper .= "return $faker;";
   $wrapper .= '}';
   # make this a capture sub if we're including
   $wrapper .= '->()' if $inside_inc;

   LOG( COMPILED =>  $self->_mini_compiler(
                        $self->_internal('fragment'),
                        { FRAGMENT => $self->_tidy($wrapper) }
                     )
   ) if DEBUG >= DEBUG_LEVEL_VERBOSE;
   #LOG( OUTPUT => $wrapper );
   # reset
   $self->[DEEP_RECURSION] = 0; # reset
   return $wrapper;
}

sub _parse_mapkeys {
   my($self, $map_keys, $faker, $buf_hash) = @_;
   return( undef, undef ) if ! $map_keys;

   my $mkc = $map_keys eq 'check';
   my $mki = $map_keys eq 'init';
   my $t   = $mki ? 'map_keys_init'
           : $mkc ? 'map_keys_check'
           :        'map_keys_default'
           ;
   my $mko = $self->_mini_compiler(
               $self->_internal( $t ) => {
                  BUF  => $faker,
                  HASH => $buf_hash,
                  KEY  => '%s',
               } => {
                  flatten => 1,
               }
            );
   return $mko, $mkc;
}

sub _add_sigwarn {
   my $self = shift;
   $self->[FAKER_WARN] = $self->_output_buffer_var('array');
   my $rv = $self->_mini_compiler(
               $self->_internal('add_sigwarn'),
               { BUF     => $self->[FAKER_WARN] },
               { flatten => 1                   }
            );
   return $rv;
}

sub _dump_sigwarn {
   my $self = shift;
   my $h    = shift;
   my $rv = $h->{capture}->(
               $self->_mini_compiler(
                  $self->_internal('dump_sigwarn'),
                  { BUF     => $self->[FAKER_WARN] },
                  { flatten => 1                   }
               )
            );
   return $rv;
}

sub _add_stack {
   my $self    = shift;
   my $cs_name = shift || '<ANON TEMPLATE>';
   my $stack   = $self->[STACK] || EMPTY_STRING;

   return if lc($stack) eq 'off';

   my $check   = ($stack eq '1' || $stack eq 'yes' || $stack eq 'on')
               ? 'string'
               : $stack
               ;

   my($type, $channel) = split m{:}xms, $check;
   $channel = ! $channel             ? 'warn'
            :   $channel eq 'buffer' ? $self->[FAKER] . ' .= '
            :                          'warn'
            ;

   foreach my $e ( $cs_name, $type, $channel ) {
      $e =~ s{'}{\\'}xmsg;
   }

   return "$channel stack( { type => '$type', name => '$cs_name' } );";
}

sub _set_internal_templates {
   return
   # we need string eval in this template to catch syntax errors
   sub_include => <<'TEMPLATE_CONSTANT',
      <%OBJECT%>->_compile(
         do {
            local $@;
            my $file = eval '<%INCLUDE%>';
            my $rv;
            if ( my $e = $@ ) {
               chomp $e;
               $file ||= '<%INCLUDE%>';
               my $m = "The parameter ($file) is not a file. "
                     . "Error from sub-include ($file): $e";
               $rv = [ ERROR => '<%ERROR_TITLE%> ' . $m ]
            }
            else {
               $rv = $file;
            }
            $rv;
         },
         <%PARAMS%>,
         {
            _sub_inc => '<%TYPE%>',
            _filter  => '<%FILTER%>',
            _share   => [<%SHARE%>],
         }
      )
TEMPLATE_CONSTANT

   no_monolith => <<'TEMPLATE_CONSTANT',
      <%OBJECT%>->compile(
         q~<%FILE%>~,
         undef,
         {
            chkmt    => 1,
            _sub_inc => q~<%TYPE%>~,
         }
      );
TEMPLATE_CONSTANT

   # see _parse()
   map_keys_check => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= exists <%HASH%>->{"<%KEY%>"}
               ? (
                  defined <%HASH%>->{"<%KEY%>"}
                  ? <%HASH%>->{"<%KEY%>"}
                  : "[ERROR] Key not defined: <%KEY%>"
                  )
               : "[ERROR] Invalid key: <%KEY%>"
               ;
TEMPLATE_CONSTANT

   map_keys_init => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= <%HASH%>->{"<%KEY%>"} || '';
TEMPLATE_CONSTANT

   map_keys_default => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= <%HASH%>->{"<%KEY%>"};
TEMPLATE_CONSTANT

   add_sigwarn => <<'TEMPLATE_CONSTANT',
      my <%BUF%>;
      local $SIG{__WARN__} = sub {
         push @{ <%BUF%> }, $_[0];
      };
TEMPLATE_CONSTANT

   dump_sigwarn => <<'TEMPLATE_CONSTANT',
      join("\n",
            map {
               s{ \A \s+    }{}xms;
               s{    \s+ \z }{}xms;
               "[warning] $_\n"
            } @{ <%BUF%> }
         );
TEMPLATE_CONSTANT

   compile_error => <<'TEMPLATE_CONSTANT',
Error compiling code fragment (cache id: <%CID%>):

<%ERROR%>
-------------------------------
PARSED CODE (VERBATIM):
-------------------------------

<%PARSED%>

-------------------------------
PARSED CODE    (tidied):
-------------------------------

<%TIDIED%>
TEMPLATE_CONSTANT

   fragment => <<'TEMPLATE_CONSTANT',

# BEGIN TIDIED FRAGMENT

<%FRAGMENT%>

# END TIDIED FRAGMENT
TEMPLATE_CONSTANT

   disk_cache_comment => <<'TEMPLATE_CONSTANT',
# !!!   W A R N I N G      W A R N I N G      W A R N I N G   !!!
# This file was automatically generated by <%NAME%> on <%DATE%>.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
TEMPLATE_CONSTANT
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Base::Parser

=head1 VERSION

version 0.91

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Text::Template::Simple::Base::Parser - Base class for Text::Template::Simple

=begin CHOMPING

The tokenizer uses a cursor to mark the chomping around a RAW token. Only RAW
tokens can be chomped. Basically, a RAW token can be imagined like this:

    _________
   |N|     |P|
   |E| STR |R|
   |X|     |E|
   |T|     |V|
    ---------

It'll have two labels on sides and the content in the center. When a chomp
directive is placed to the left delimiter, this affects the previous RAW token
and when it is placed to the right delimiter, it'll affect the next RAW token.
If the previous or next is not raw, nothing will happen. You need to swap sides
when handling the chomping. i.e.: left chomping affects the right side of the
RAW, and right chomping affects the left side of the RAW. _chomp() method in
the parser swaps sides to handle chomping. See Text::Template::Simple::Tokenizer
to have an idea on how pre-parsing happens.

=end CHOMPING

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
