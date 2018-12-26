package Text::Template::Simple::Tokenizer;
$Text::Template::Simple::Tokenizer::VERSION = '0.91';
use strict;
use warnings;

use constant CMD_CHAR             => 0;
use constant CMD_ID               => 1;
use constant CMD_CALLBACK         => 2;

use constant ID_DS                => 0;
use constant ID_DE                => 1;
use constant ID_PRE_CHOMP         => 2;
use constant ID_POST_CHOMP        => 3;

use constant SUBSTR_OFFSET_FIRST  => 0;
use constant SUBSTR_OFFSET_SECOND => 1;
use constant SUBSTR_LENGTH        => 1;

use Text::Template::Simple::Util      qw( LOG DEBUG fatal );
use Text::Template::Simple::Constants qw( :all );

my @COMMANDS = ( # default command list
   # command        id
   [ DIR_CAPTURE  , T_CAPTURE   ],
   [ DIR_DYNAMIC  , T_DYNAMIC,  ],
   [ DIR_STATIC   , T_STATIC,   ],
   [ DIR_NOTADELIM, T_NOTADELIM ],
   [ DIR_COMMENT  , T_COMMENT   ],
   [ DIR_COMMAND  , T_COMMAND   ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS]         = shift || fatal('tts.tokenizer.new.ds');
   $self->[ID_DE]         = shift || fatal('tts.tokenizer.new.de');
   $self->[ID_PRE_CHOMP]  = shift || CHOMP_NONE;
   $self->[ID_POST_CHOMP] = shift || CHOMP_NONE;
   return $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my($self, $tmp, $map_keys) = @_;

   return $self->_empty_token( $tmp ) if ! $tmp;

   my($ds,  $de)  = @{ $self }[ ID_DS, ID_DE ];
   my($qds, $qde) = map { quotemeta $_ } $ds, $de;

   my(@tokens, $inside);

   OUT_TOKEN: foreach my $i ( split /($qds)/xms, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ $i, T_DELIMSTART, [], undef ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach my $j ( split /($qde)/xms, $i ) {
         if ( $j eq $de ) {
            my $last_token = $tokens[LAST_TOKEN];
            if ( T_NOTADELIM == $last_token->[TOKEN_ID] ) {
               $last_token->[TOKEN_STR] = $self->tilde(
                                             $last_token->[TOKEN_STR] . $de
                                          );
            }
            else {
               push @tokens, [ $j, T_DELIMEND, [], undef ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   $self->_debug_tokens( \@tokens ) if $self->can('DEBUG_TOKENS');

   return \@tokens;
}

sub tilde {
   my(undef, @args) = @_;
   return Text::Template::Simple::Util::escape( q{~} => @args );
}

sub quote {
   my(undef, @args) = @_;
   return Text::Template::Simple::Util::escape( q{"} => @args );
}

sub _empty_token {
   my $self = shift;
   my $tmp  = shift;
   fatal('tts.tokenizer.tokenize.tmp') if ! defined $tmp;
   # empty string or zero
   return [
         [ $self->[ID_DS], T_DELIMSTART, [], undef ],
         [ $tmp          , T_RAW       , [], undef ],
         [ $self->[ID_DE], T_DELIMEND  , [], undef ],
   ]
}

sub _get_command_chars {
   my($self, $str) = @_;
   return
      $str ne EMPTY_STRING # left
         ? substr $str, SUBSTR_OFFSET_FIRST , SUBSTR_LENGTH : EMPTY_STRING,
      $str ne EMPTY_STRING # extra
         ? substr $str, SUBSTR_OFFSET_SECOND, SUBSTR_LENGTH : EMPTY_STRING,
      $str ne EMPTY_STRING # right
         ? substr $str, length($str) - 1    , SUBSTR_LENGTH : EMPTY_STRING,
   ;
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub _token_for_command {
   my($self, $tree, $map_keys, $str, $last_cmd, $second_cmd, $cmd, $inside) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $second_cmd, $last_cmd );
   my $len  = length $str;
   my $cb   = $map_keys ? 'quote' : $cmd->[CMD_CALLBACK];
   my $soff = $copen ? 2 : 1;
   my $slen = $len - ($cclose ? $soff+1 : 1);
   my $buf  = substr $str, $soff, $slen;

   if ( T_NOTADELIM == $cmd->[CMD_ID] ) {
      $buf = $self->[ID_DS] . $buf;
      $tree->[LAST_TOKEN][TOKEN_ID] = T_DISCARD;
   }

   my $needs_chomp = defined $ctoken;
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   my $id  = $map_keys ? T_RAW              : $cmd->[CMD_ID];
   my $val = $cb       ? $self->$cb( $buf ) : $buf;

   return [
            $val,
            $id,
            [ (CHOMP_NONE) x 2 ],
            $needs_chomp ? $ctoken : undef # trigger
          ];
}

sub _token_for_code {
   my($self, $tree, $map_keys, $str, $last_cmd, $first_cmd) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $first_cmd, $last_cmd );
   my $len  = length $str;
   my $soff = $copen ? 1 : 0;
   my $slen = $len - ( $cclose ? $soff+1 : 0 );

   my $needs_chomp = defined $ctoken;
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   return   [
               substr($str, $soff, $slen),
               $map_keys ? T_MAPKEY : T_CODE,
               [ (CHOMP_NONE) x 2 ],
               $needs_chomp ? $ctoken : undef # trigger
            ];
}

sub _token_code {
   my($self, $str, $inside, $map_keys, $tree) = @_;
   my($first_cmd, $second_cmd, $last_cmd) = $self->_get_command_chars( $str );

   if ( $inside ) {
      my @common = ($tree, $map_keys, $str, $last_cmd);
      foreach my $cmd ( @COMMANDS, $self->_user_commands ) {
         next if $first_cmd ne $cmd->[CMD_CHAR];
         return $self->_token_for_command( @common, $second_cmd, $cmd, $inside );
      }
      return $self->_token_for_code( @common, $first_cmd );
   }

   my $prev = $tree->[PREVIOUS_TOKEN];

   return [
            $self->tilde( $str ),
            T_RAW,
            [ $prev ? $prev->[TOKEN_TRIGGER] : undef, CHOMP_NONE ],
            undef # trigger
         ];
}

sub _chomp_token {
   my($self, $open_tok, $close_tok) = @_;
   my($pre, $post) = ( $self->[ID_PRE_CHOMP], $self->[ID_POST_CHOMP] );
   my $c      = CHOMP_NONE;

   my $copen  = $open_tok  eq DIR_CHOMP_NONE ? RESET_FIELD
              : $open_tok  eq DIR_COLLAPSE   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre       &  COLLAPSE_ALL   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre       &  CHOMP_ALL      ? do { $c |=     CHOMP_LEFT; 1 }
              : $open_tok  eq DIR_CHOMP      ? do { $c |=     CHOMP_LEFT; 1 }
              :                                0
              ;

   my $cclose = $close_tok eq DIR_CHOMP_NONE ? RESET_FIELD
              : $close_tok eq DIR_COLLAPSE   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post      &  COLLAPSE_ALL   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post      &  CHOMP_ALL      ? do { $c |=    CHOMP_RIGHT; 1 }
              : $close_tok eq DIR_CHOMP      ? do { $c |=    CHOMP_RIGHT; 1 }
              :                                0
              ;

   my $cboth  = $copen > 0 && $cclose > 0;

   $c |= COLLAPSE_ALL if ( ( $c & COLLAPSE_LEFT ) && ( $c & COLLAPSE_RIGHT ) );
   $c |= CHOMP_ALL    if ( ( $c & CHOMP_LEFT    ) && ( $c & CHOMP_RIGHT    ) );

   return $copen, $cclose, $c || CHOMP_NONE;
}

sub _chomp_prev {
   my($self, $tree, $ctoken) = @_;
   my $prev = $tree->[PREVIOUS_TOKEN] || return; # no previous if this is first
   return if T_RAW != $prev->[TOKEN_ID]; # only RAWs can be chomped

   my $tc_prev = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_PREV];
   my $tc_next = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT];

   $prev->[TOKEN_CHOMP] = [
                           $tc_next ? $tc_next           : CHOMP_NONE,
                           $tc_prev ? $tc_prev | $ctoken : $ctoken
                           ];
   return;
}

sub _get_symbols {
   # fetch the related constants
   my $self  = shift;
   my $regex = shift || fatal('tts.tokenizer._get_symbols.regex');
   no strict qw( refs );
   return grep { $_ =~ $regex } keys %{ ref($self) . q{::} };
}

sub _visualize_chomp {
   my $self  = shift;
   my $param = shift;
   return 'undef' if ! defined $param;

   my @test = map  { $_->[0]             }
              grep { $param & $_->[1]    }
              map  { [ $_, $self->$_() ] }
              $self->_get_symbols( qr{ \A (?: CHOMP|COLLAPSE ) }xms );

   return @test ? join( q{,}, @test ) : 'undef';
}

sub _visualize_tid {
   my $self = shift;
   my $id   = shift;
   my @ids  = (
      undef,
      sort { $self->$a() <=> $self->$b() }
      grep { $_ ne 'T_MAXID' }
      $self->_get_symbols( qr{ \A (?: T_ ) }xms )
   );

   my $rv = $ids[ $id ] || ( defined $id ? $id : 'undef' );
   return $rv;
}

sub _debug_tokens {
   my $self   = shift;
   my $tokens = shift;
   my $buf    = $self->_debug_tokens_head;

   foreach my $t ( @{ $tokens } ) {
      $buf .=  $self->_debug_tokens_row(
                  $self->_visualize_tid( $t->[TOKEN_ID]  ),
                  Text::Template::Simple::Util::visualize_whitespace(
                     $t->[TOKEN_STR]
                  ),
                  map { $_ eq 'undef' ? EMPTY_STRING : $_ }
                  map { $self->_visualize_chomp( $_ )     }
                  $t->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT],
                  $t->[TOKEN_CHOMP][TOKEN_CHOMP_PREV],
                  $t->[TOKEN_TRIGGER]
               );
   }
   Text::Template::Simple::Util::LOG( DEBUG => $buf );
   return;
}

sub _debug_tokens_head {
   my $self = shift;
   return <<'HEAD';

---------------------------
       TOKEN DUMP
---------------------------
HEAD
}

sub _debug_tokens_row {
   my($self, @params) = @_;
   return sprintf <<'DUMP', @params;
ID        : %s
STRING    : %s
CHOMP_NEXT: %s
CHOMP_PREV: %s
TRIGGER   : %s
---------------------------
DUMP
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Tokenizer

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Text::Template::Simple::Constants qw( :token );
   use Text::Template::Simple::Tokenizer;
   my $t = Text::Template::Simple::Tokenizer->new( $start_delim, $end_delim );
   foreach my $token ( @{ $t->tokenize( $raw_data ) } ) {
      printf "Token type: %s\n", $token->[TOKEN_ID];
      printf "Token data: %s\n", $token->[TOKEN_STR];
   }

=head1 DESCRIPTION

Splits the input into tokens with the defined delimiter pair.

=head1 NAME

Text::Template::Simple::Tokenizer - C<Tokenizer>

=head1 METHODS

=head2 new

The object constructor. Accepts two parameters in this order:
C<start_delimiter> and C<end_delimiter>.

=head2 C<tokenize>

Splits the input into tokens with the supplied delimiter pair. Accepts a single
parameter: the raw template string.

=head2 ESCAPE METHODS

=head2 tilde

Escapes the tilde character.

=head3 quote

Escapes double quotes.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
