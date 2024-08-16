package YATT::Lite::LRXML::ParseEntpath;
use strict;
use warnings qw(FATAL all NONFATAL misc);

package YATT::Lite::LRXML; use YATT::Lite::LRXML;

# item ::=
#    pathItem
#  [ pathItem+ ]

# pathItem ::=
# [call  => name, item, item, ...]
# [var   => name]
# [array => item, item, ...]
# [hash  => item, item, ...]
# [aref  => item]
# [href  => item]

# Ex:
#   [aref => [var => x]]
#   [aref => [[var => i], [var => j]]

sub _parse_text_entities {
  my MY $self = shift;
  $self->_parse_text_entities_at($self->{curpos}, @_);
}
sub _parse_text_entities_at {
  my MY $self = $_[0];
  local ($self->{curpos}, $_) = @_[1,2];
  my ($curpos, $endpos) = ($self->{curpos});
  my $offset = $curpos;
  my @result;
  {

    my $total = length $_;
    while (s{^(.*?)$$self{re_entopn}}{}xs) {
      if (length $1) {
	push @result, $1;
	$self->{endln} += numLines($1);
	$curpos += length $1;
      }
      push @result, my $node = $self->mkentity($curpos, undef, $self->{endln});
      $curpos = $total - length $_;
      $node->[NODE_END] = $curpos + $offset;
    }
    $endpos = $self->{curpos};
  }
  if (@result) {
    push @result, $_ if length $_;
    \@result;
  } else {
    $_;
  }
}

# &yatt:foo:bar
#
# entpath   ::= pipeline ';'
# pipeline  ::= (pathElem | '[' <group ']'> | '{' <group '}'>)+
# pathElem  ::= ':' name ('(' <group ')'>)?
# group C   ::= term* C
# term      ::= (pipeline | expr | text) [,:]?

our (%open_head, %open_rest, %close_ch, %for_expr);
BEGIN {
  %open_head = qw| ( call   [ array { hash|;
  %open_rest = qw| ( invoke [ aref  { href|;
  %close_ch  = qw( ( ) [ ] { } );
  %for_expr = (aref => 1);
}
sub _parse_entpath {
  my MY $self = shift;
  local $self->{_original_entpath} = $_;
  my $how = shift || '_parse_pipeline';
  my $prevlen = length $_;
  my @pipe = $self->$how(@_);
  unless (s{^;}{}xs) {
    if (/^\s|^$/) {
      die $self->synerror_at($self->{startln}
			     , q{Entity has no terminator: '%s'}
			     , $self->shortened_original_entpath);

    } else {
      die $self->synerror_at($self->{startln}
			     , q{Syntax error in entity: '%s'}
			     , $self->shortened_original_entpath);
    }
  }
  $self->{curpos} += $prevlen - length $_;
  @pipe;
}
sub _parse_pipeline {
  (my MY $self) = @_;
  unless (defined $_) {
    Carp::confess "parse_pipeline for undefined \$_!";
  }
  my @pipe;
  while (s{^ : (?<var>\w+) (?<open>\()?
	 | ^ (?<open>\[)
	 | ^ (?<open>(?<hash>\{))}{}xs) {
    my $table = @pipe ? \%open_rest : \%open_head;
    my $type = $+{open} ? $table->{$+{open}}
      : @pipe ? 'prop' : 'var';
    push @pipe, do {
      # if (not @pipe and $+{hash}) {
      #   [$type, $self->_parse_hash]
      # } else {
	[$type, defined $+{var} ? $+{var} : ()
	 , $+{open}
	 ? $self->_parse_entgroup($close_ch{$+{open}}, $for_expr{$type})
	 : ()];
      # }
    };
  }
  if (wantarray) {
    @pipe
  } else {
    @pipe > 1 ? \@pipe : $pipe[0]
  }
}
sub _parse_entgroup {
  (my MY $self, my ($close, $for_expr)) = @_;
  my $prevlen = length $_;
  my $emptycnt;
  my @pipe;
  do {
    push @pipe, $self->_parse_entterm($for_expr);
    if (length $_ == $prevlen and $emptycnt++) {
      die $self->synerror_at($self->{startln}
			     , q{Syntax error in entity: '%s'}
			     , $self->shortened_original_entpath);
    }
    $prevlen = length $_;
  } until (s{^ ($$self{re_eclose})}{}xs);
  die $self->synerror_at($self->{startln}, q{Paren mismatch: expect %s got %s: str=%s}
		      , $close, $1, $_)
    unless $1 eq $close;
  @pipe;
}
sub _parse_entterm {
  (my MY $self, my ($for_expr)) = @_;
  my $text_type = $for_expr ? 'expr' : 'text';
  if (s{^ ,}{}xs) {
    return [text => ''];
  } elsif (s{^ (?=[\)\]\};])}{}xs) {
    return;
  }
  my $term = do {
    if (s{^(?: (?<text>  $$self{ch_etext} (?:$$self{ch_etext} | :)* )
	  |    $$self{re_eparen}
       )}{}xs) {
      my $text = '';
    TEXT: {
	do {
	  last TEXT if $+{close};
	  if (defined $+{text}) {
	    $text .= $+{text};
	  } elsif (defined $+{paren}) {
	    $text .= $+{paren};
	  }
	  $text .= $+{open} . $self->_parse_group_string($close_ch{$+{open}})
	    if $+{open};
	} while (s{^ (?: (?<text> (?:$$self{ch_etext} | :)+)
		   | $$self{re_eparen}
		   | $$self{re_eopen}
		   | (?= (?<close>[\)\]\};,])))}{}xs);
      }
      [($text =~ s/^=// ? 'expr' : $text_type) => $text];
    } else {
      $self->_parse_pipeline;
    }
  };
  # Suffix.
  s{^ [,:]?}{}xs;
  $term;
}

sub _parse_group_string {
  (my MY $self, my $close) = @_;
  my $oldpos = pos;
  my $text = '';
  while (s{^ ((?:$$self{ch_etext}+ | [,:])*)
	   (?: $$self{re_eopen} |  $$self{re_eclose})}{}xs) {
    # print pos($_), "\n";
    $text .= $&;
    if ($+{close}) {
      die $self->synerror_at($self->{startln}, q{Paren mismatch: expect %s got %s: str=%s}
		   , $close, $+{close}, substr($_, $oldpos, pos))
	unless $+{close} eq $close;
      last;
    }
    $text .= $self->_parse_group_string($close_ch{$+{open}}) if $+{open};
  }
  $text;
}

sub _parse_hash {
  (my MY $self) = @_;

  my ($lastlen, @hash);
  while (not defined $lastlen or length $_ < $lastlen) {
    $lastlen = length $_;
    return @hash if s/^\}//;
    s{^ ($$self{ch_etext}*) (?: [:,])}{}xs or last;
    push @hash, [text => $1];
    push @hash, $self->_parse_entterm;
    s{^,}{};
  }
  die $self->synerror_at($self->{startln}, q{Paren mismatch: expect \} got %s}
			 , $self->shortened_original_entpath);
}

use YATT::Lite::Breakpoint qw(break_load_parseentpath);
break_load_parseentpath();

1;
