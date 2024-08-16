#!/usr/bin/env perl
package YATT::Lite::LanguageServer::SpecParser;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base;
use utf8;
use open qw/:std :locale/;

use MOP4Import::Types
  (Annotated => [[fields => qw/comment body deprecated/]
                 , [subtypes =>
                    Decl => [[fields => qw/kind name exported/]
                             , [subtypes =>
                                Interface => [[fields => qw/extends/]]
                              ]]
                  ]]
 );

# SpecParser.pm extract_codeblock typescript specification.md|
# SpecParser.pm cli_xargs_json extract_statement_list|
# grep -v 'interface ParameterInformation'|
# SpecParser.pm cli_xargs_json --single tokenize_statement_list|
# SpecParser.pm cli_xargs_json --single parse_statement_list |
# jq --slurp .

sub parse_files :method {
  (my MY $self, my @files) = @_;
  $self->parse_statement_list(
    [$self->tokenize_statement_list(
      [$self->extract_statement_list(
        [$self->extract_codeblock(typescript => @files)]
      )]
    )]
  );
}

sub parse_statement_list :method {
  (my MY $self, my $statementTokList) = @_;
  map {
    my ($declarator, $comment, $bodyTokList) = @$_;
    #
    my Decl $decl = $self->parse_declarator($declarator);
    $self->parse_comment_into_decl($decl, $comment);

    if (my $sub = $self->can("parse_$decl->{kind}_declbody")) {
      $decl->{body} = \ my @body;
      while (@$bodyTokList) {
        push @body, $sub->($self, $decl, $bodyTokList);
      }
      if (@$bodyTokList) {
        $self->tokerror(["Invalid trailing token(s) for declbody of ", $decl]
                        , $bodyTokList);
      }
    } else {
      print STDERR "# Not yet supported: "
        . MOP4Import::Util::terse_dump($_), "\n"
        unless $self->{quiet};
    }

    $decl;

  } @$statementTokList;
}

sub tokerror {
  (my MY $self, my $diag, my $bodyTokList) = @_;
  Carp::croak MOP4Import::Util::terse_dump($diag)
    . ": " . MOP4Import::Util::terse_dump($bodyTokList);
}

sub parse_comment_into_decl :method {
  (my MY $self, my Decl $decl, my $comment) = @_;
  return unless defined $comment;
  if ($comment =~ s/\@deprecated(?:\s+(?<by>\S[^\n]*))?//) {
    $decl->{deprecated} = $+{by};
  }
  $decl->{comment} = $comment;
}

sub parse_type_declbody :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;
  $self->parse_typeunion($decl, $bodyTokList);
}

sub parse_namespace_declbody :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;
  $self->parse_declbody(
    $decl, $bodyTokList, [], sub {
      (my $origTok, my Annotated $ast) = @_;
      my $tok = $origTok;
      # Currently only something like `export const Error = 1;` are supported.
      $tok =~ s{^export\s+const\s+(\w+)\s*}{}x or do {
        $self->tokerror(["Unsupported namespace statement: ", $tok
                         , decl => $decl], $bodyTokList);
      };
      my $name = $1;

      my ($type, $value);
      if ($tok =~ m{= \s* (\S+)\z}x) {
        $value = $1;
      } elsif ($self->eat_token(':', $bodyTokList)) {
        ($type, $value) = $self->re_match_token(qr{([^\s=]+) (?: \s* = \s* (\S+))?}xs, $bodyTokList);
      } else {
          $self->tokerror(["Unsupported namespace statement: ", $origTok
                           , decl => $decl], $bodyTokList);
      }

      # , $type, $value

                    # (?: : \s* ([^\s=]+) \s*)?
                    # (?: = \s* (\S+))?

      #        and $self->eat_token(':', $bodyTokList))
      $ast->{body} = my Decl $const = {};
      # enum assignment.
      $const->{kind} = 'const';
      $const->{name} = $name;
      my $expr = $self->unquote_string($value);
      $const->{body} = (defined $type ? [$type => $expr] : $expr);
      $self->eat_token(';', $bodyTokList);
      return defined $ast->{comment} ? $ast : $ast->{body};
    }
  );
}

sub unquote_string :method {
  (my MY $self, my $str) = @_;
  $str =~ s/^'([^']*)'\z/$1/ or
    $str =~ s/^"([^"]*)"\z/$1/;
  $str;
}

sub parse_enum_declbody :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;
  $self->parse_declbody(
    $decl, $bodyTokList, [], sub {
      (my $tok, my Annotated $ast) = @_;
      $tok =~ s{^(?<ident>\w+)\s*=\s*}{}x
        or return;
      # enum assignment.
      $ast->{body} = [$+{ident}, $tok];
      # ',' may not exist
      $self->eat_token(',', $bodyTokList);
      return defined $ast->{comment} ? $ast : $ast->{body};
    }
  );
}

sub parse_class_declbody :method {
  shift->parse_interface_declbody(@_);
}

sub parse_interface_declbody :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;

  # I'm not sure why this requires ',' too.
  # Found after TextDocumentClientCapabilities.completion.completionItemKind

  $self->parse_declbody(
    $decl, $bodyTokList, [';', ','], sub {
      (my $tok, my Annotated $ast) = @_;
      ($tok =~ s{^(?:(?<ro>readonly)\s+)?
                (?<slotName>(?:\w+ |\[[^]]+\]) \??)}{}x
       and $self->eat_token(':', $bodyTokList))
        or return;
      # Drop 'readonly' for now.
      # slot
      $ast->{body} = my $slotDef = [$+{slotName}];
      unshift @$bodyTokList, $tok if $tok =~ /\S/;
      push @$slotDef, $self->parse_typeunion($decl, $bodyTokList);
      return defined $ast->{comment} ? $ast : $ast->{body};
    }
  );
}

# https://github.com/microsoft/TypeScript/blob/master/doc/spec.md#A

sub parse_declbody :method {
  (my MY $self, my Decl $decl, my ($bodyTokList, $terminators, $elemParser)) = @_;
  my @result;
  unless ($self->eat_token('{', $bodyTokList)) {
    $self->tokerror(["Invalid leading token for declbody of ", $decl], $bodyTokList);
  }
  my Annotated $ast = +{};
  while (@$bodyTokList and $bodyTokList->[0] ne '}') {
    my $tok = shift @$bodyTokList;
    if ($tok eq '{') {
      $ast->{body} = [$self->parse_declbody($decl, $bodyTokList, $terminators, $elemParser)];
    } elsif ($tok eq '[') {
      # Index Signatures. 3.9.4
      unless (@$bodyTokList >= 4
              and $bodyTokList->[0] =~ /^\w+\z/
              and $bodyTokList->[1] eq ':') {
        Carp::croak "Invalid Index Signature after '[':"
          . MOP4Import::Util::terse_dump($bodyTokList);
      }
      (my $name, undef, my $ixType, undef) = splice @$bodyTokList, 0, 4;
      $ast->{body} = my $slotDef = [$name];
      if ($self->eat_token(':', $bodyTokList)) {
        push @$slotDef, $self->parse_typeunion($decl, $bodyTokList);
      }
      push @result, $ast;
      $ast = +{};
    } elsif ($tok =~ m{^/\*\*}) {
      $self->parse_comment_into_decl($ast, $self->tokenize_comment_block($tok));
    } elsif ($tok =~ m{^//}) {
      # Just ignored.
    } elsif (my $elem = $elemParser->($tok, $ast)) {
      push @result, $elem;
      $ast = +{};
    } else {
      die "HOEHOE? tok='$tok': "
        .MOP4Import::Util::terse_dump($bodyTokList, [decl => $decl]);
    }
  }
  unless ($self->eat_token('}', $bodyTokList)) {
    $self->tokerror(["Invalid closing token for declbody of ", $decl], $bodyTokList);
  }

  # trailing terminators after '}' is eaten here.
  $self->eat_token($_, $bodyTokList) for @$terminators;

  if (%$ast) {
    $self->tokerror(["Something went wrong for declbody of ", $decl], $bodyTokList);
  }
  @result;
}

# I call here UnionOrIntersectionOrPrimaryType as typeunion
# and IntersectionOrPrimaryType as typeconj

# typeunion -> typeconj -> typeunion

sub parse_typeunion :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;
  my @union;
  while (@$bodyTokList and $bodyTokList->[0] ne ';') {
    if ($bodyTokList->[0] eq '{') {
      push @union, $self->parse_interface_declbody($decl, $bodyTokList);
    } else {
      push @union, $self->parse_typeconj($decl, $bodyTokList);
      if ($self->eat_token(';', $bodyTokList)) {
        last;
      }
    }
    if (not $self->eat_token('|', $bodyTokList)) {
      last;
    }
  }
  @union;
}

#
# parse conjunctive? type expression. (IntersectionOrPrimaryType)
#
sub parse_typeconj :method {
  (my MY $self, my Decl $decl, my $bodyTokList) = @_;
  if (my ($ident, $bracket) = $bodyTokList->[0] =~ /^(\w+(?:<[^>]+>)?)(\[\])?\z/) {
    shift @$bodyTokList;
    return defined $bracket ? [$ident, $bracket] : $ident;
  } elsif (my ($string) = $bodyTokList->[0] =~ /^('[^']*' | "[^"]*" )\z/x) {
    shift @$bodyTokList;
    return [constant => $string];
  } elsif ($self->eat_token('(', $bodyTokList)) {
    my $expr = [\ my @union];
    until ($self->eat_token(')', $bodyTokList)) {
      do {
        my $e = $self->parse_typeconj($decl, $bodyTokList);
        if ($self->eat_token('&', $bodyTokList)) {
          $e = ['&', $e];
          do {
            push @$e, $self->parse_typeconj($decl, $bodyTokList);
          } while ($self->eat_token('&', $bodyTokList));
        }
        push @union, $e;
      } while ($self->eat_token('|', $bodyTokList));
    }
    # For ()[] <-- this.
    if (my $bracket = $self->eat_token('[]', $bodyTokList)) {
      push @$expr, $bracket;
    }
    return $expr;
  } elsif ($self->eat_token('[', $bodyTokList)) {
    my $expr = [\ my @tuple]; # XXX
    unless ($self->eat_token(']', $bodyTokList)) {
      do {
        push @tuple, my $e = $self->parse_typeconj($decl, $bodyTokList);
      } while ($self->eat_token(',', $bodyTokList));
    }
    unless ($self->eat_token(']', $bodyTokList)) {
      $self->tokerror(["Tuple not closed for declbody of ", $decl], $bodyTokList);
    }
    return $expr;
  } else {
    die "Really? ".MOP4Import::Util::terse_dump($bodyTokList, [decl => $decl]);
  }
}

sub parse_declarator :method {
  (my MY $self, my $declTokIn) = @_;
  my $declTok = [@$declTokIn];
  my Decl $decl = {};
  if ($self->eat_token(export => $declTok)) {
    $decl->{exported} = 1;
  }
  $decl->{kind} = shift @$declTok;
  $decl->{name} = shift @$declTok;
  if ($decl->{kind} eq 'interface') {
    if ($self->eat_token(extends => $declTok)) {
      my Interface $if = $decl;
      $if->{extends} = shift @$declTok;
    }
  }
  $decl;
}

sub eat_token :method {
  (my MY $self, my ($tokString, $tokList)) = @_;
  if (@$tokList and $tokList->[0] eq $tokString) {
    shift @$tokList;
  }
}

sub re_match_token :method {
  (my MY $self, my ($pattern, $tokList)) = @_;
  if (@$tokList and my @match = ($tokList->[0] =~ $pattern)) {
    shift @$tokList;
    return @match;
  }
  return ();
}

#----------------------------------------

sub tokenize_statement_list :method {
  (my MY $self, my $statementList) = @_;
  map {
    my ($declarator, $comment, $body) = @$_;
    [$self->tokenize_declarator($declarator)
     , $self->tokenize_comment_block($comment)
     , $self->tokenize_declbody($body)];
  } @$statementList;
}

sub tokenize_declbody :method {
  (my MY $self, my $declString) = @_;
  [map {s/\s*\z//; $_}
   grep {/\S/}
   split m{(; | [{}(),\|&:]
           | \[ (?=[^]]) | (?<!\[) \]
           | /\*\*\n(?:.*?)\*/ | //[^\n]*\n) \s*}xs, $declString];
}

sub tokenize_comment_block :method {
  (my MY $self, my $commentString) = @_;
  return undef unless defined $commentString;
  unless ($commentString =~ s,^\s*/\*\*\n,,s) {
    Carp::croak "Comment doesn't start with /**\\n: "
      . MOP4Import::Util::terse_dump($commentString);
  }
  unless ($commentString =~ s,\*/\n?\z,,s) {
    Carp::croak "Comment doesn't end with */: "
      . MOP4Import::Util::terse_dump($commentString);
  }
  $commentString =~ s/^\s+\*\ //mg;
  $commentString =~ s/\s+\z//;
  $commentString;
}

sub tokenize_declarator :method {
  (my MY $self, my $declString) = @_;
  [split " ", $declString];
}

sub extract_statement_list :method {
  (my MY $self, my ($codeList)) = @_;
  local $_;
  my $wordRe = qr{[^\s{}=\|]+};
  my $commentRe = qr{/\*\*\n(?:.*?)\*/\n?}sx;
  my $groupRe = qr{( \{ (?: (?> [^{}/]+) | $commentRe | /[^\*] | (?-1) )* \} )}x;
  my $typeElemRe = qr{$wordRe | $groupRe}sx;
  my @result;
  foreach (@$codeList) {
    while (m{
              \G
              \s*
              (?<comment>$commentRe)?
              (?<decl>(?:$wordRe\s+)+)
              (?: (?<body> $groupRe )
                | = \s* (?<type>
                    $typeElemRe \s*(?: \| \s*$typeElemRe)*
                  )
                  \s*;
              )
          }sgx) {
      push @result, [$+{decl}, $+{comment}, $+{body} // $+{type}];
    }
  }
  @result;
}

# Lite/LanguageServer/SpecParser.pm --flatten --output=raw extract_codeblock typescript specification.md
sub extract_codeblock :method {
  (my MY $self, my $langId, local @ARGV) = @_;
  local $_;
  my ($chunk, @result);
  while (defined($_ = $self->cli_compat_diamond)) {
    my $line = s{^```$langId\b}{} .. s{^```}{}
      or next;
    my $end = $line =~ /E0/;
    s/\r//;
    $chunk .= $_ if $line >= 2 and not $end;
    if ($end) {
      push @result, $chunk;
      $chunk = "";
    }
  }
  @result;
}

MY->run(\@ARGV) unless caller;
1;
