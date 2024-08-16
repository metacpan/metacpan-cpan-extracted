package YATT::Lite::LRXML::ParseBody; # dummy package, for lint.
use strict;
use warnings qw(FATAL all NONFATAL misc);

package YATT::Lite::LRXML; use YATT::Lite::LRXML;

sub _parse_body {
  (my MY $self, my Widget $widget, my ($sink, $close, $parent, $par_ln)) = @_;
  # $sink は最初、外側の $body 配列。
  # <:option /> が出現した所から先は、 その option element の body が新しい $sink になる

  # XXX: 使い方の指針を解説せよ
  # curpos, startln, endln

  my $has_nonspace; # 非空白文字が出現したか。 <:opt>HEAD</:opt> と BODY の間に
  my $is_closed; # tag が閉じたか。

  my $last_foot; # last foot 

  while (s{^(.*?)$$self{re_body}}{}xs or my $retry = $self->_get_chunk($sink)) {
    next if $retry;

    my $startPos = $self->{curpos} + length($1);

    $self->accept_leading_text($sink, $parent, $par_ln, \$has_nonspace);

    if ($+{lcmsg}) {
      if ($+{msgopn}) {
	push @$sink, $self->_parse_lcmsg
	  ($+{entity}, $parent, $par_ln, \$has_nonspace);
      } else {
	die $self->synerror_at
	  ($self->{startln}, q{Mismatched l10n msg});
      }
    } elsif ($+{entity} or $+{special}) {
      # &yatt(?=:) までマッチしてる。
      # XXX: space 許容モードも足すか。
      $self->accept_entity($sink, $parent, $par_ln, \$has_nonspace);

    } elsif (my $path = $+{elem}) {
      my $formal_path = ($+{opt} // '') . $+{elem};
      if ($+{clo}) {
        if ($last_foot) {
          $last_foot->[NODE_END] = $startPos;
        }
	$parent->[NODE_BODY_END] = $self->{startpos};
	if (defined $parent->[NODE_BODY_BEGIN]
	    and $self->{template}->node_body_source($parent) =~ /(\r?\n)\Z/) {
	  $parent->[NODE_BODY_END] -= length $1;
	}
	$self->verify_tag($formal_path, $close);
	if (@$sink and not ref $sink->[-1] and $sink->[-1] =~ s/(\r?\n)\Z//) {
	  push @$sink, "\n";
	}
	# $self->add_lineinfo($sink);
	$is_closed++;
	last;
      }
      # /? > まで、その後、not ee なら clo まで。
      my $is_opt = $+{opt};
      my $elem = [];
      $elem->[NODE_TYPE] = $is_opt ? TYPE_ATT_NESTED : TYPE_ELEMENT;
      $elem->[NODE_BEGIN] = $self->{startpos};
      $elem->[NODE_LNO] = $self->{endln};
      $elem->[NODE_SYM_END] = $self->{curpos};
      $elem->[NODE_PATH] = [split /:/, $path];
      $elem->[NODE_BODY] = undef;

      if (my @atts = $self->parse_attlist(\$_)) {
	$elem->[NODE_ATTLIST] = \@atts;
      }

      # タグの直後の改行は、独立したトークンにしておく
      s{^(?<empty_elem>/)? >(\r?\n)?}{}xs or do {
        my $diag = m{^\S*\s*?/?>}
          ? "Garbage before CLO(>)"
          : "Missing CLO(>)";
        die $self->synerror_at($self->{startln}
                                 , q{%s for: <%s, rest: '%s'}
                                 , $diag, $path, trimmed($_));
      };

      ++$self->{startln} if defined $2;

      # body slot の初期化
      # $is_opt の時に、更に body を attribute として保存するのは冗長だし、後の処理も手間なので
      my $body = [];
      if (not $+{empty_elem} or $is_opt) {
        $elem->[NODE_BODY] = $is_opt ? $body : do {
          my $att_node = [];
          $att_node->[NODE_TYPE] = TYPE_ATTRIBUTE;
          $att_node->[NODE_PATH] = $self->{cf_body_argument};
          $att_node->[NODE_BODY] = $body;
          $att_node;
        };
      }

      my $bodyStartRef; $bodyStartRef = \ $elem->[NODE_BODY][NODE_LNO]
	if not $is_opt and $elem->[NODE_BODY];

      $self->{curpos} += 1 + ($1 ? length($1) : 0); # $& じゃないので注意。
      $elem->[NODE_END] = $self->{curpos} if $+{empty_elem};
      $self->{curpos} += length $2 if $2; # XXX: swap with below
      $elem->[NODE_BODY_BEGIN] = $self->{curpos}; # XXX

      $self->_verify_token($self->{curpos}, $_) if $self->{cf_debug};

      if ($is_opt and not $+{empty_elem}) {
	drop_leading_ws($sink);
      }

      if (not $is_opt) {
	push @$sink, $elem;
      } elsif ($+{empty_elem}) {
	# <:opt/> の時は $parent->[foot] へ
	push @{$parent->[NODE_AELEM_FOOT] ||= []}, $elem;
      } else {
	# <:opt> の時は, $parent->[head] へ
	push @{$parent->[NODE_AELEM_HEAD] ||= []}, $elem
      }

      my $bodystartln = $self->{endln};
      # <TAG>\n タグ直後の改行について。
      # <foo />\n だけは, 現在の $sink へ、それ以外は、今作る $elem の $body へ改行を足す
      $self->{endln}++, push @{!$is_opt && $+{empty_elem} ? $sink : $body}, "\n"
	if $2;

      unless ($is_opt) {
	$$par_ln = $self->{startln} if not $has_nonspace++ and $parent;
      } elsif (not $+{empty_elem}) {
	# XXX: もし $is_opt かつ not ee だったら、
	# $sink (親の $body) が空かどうかを調べる必要が有る。
#	die $self->synerror_at(q{element option '%s' must precede body!}, $path)
#	  if $has_nonspace;
      }
      if (not $+{empty_elem}) {
	# call <yatt:call> ...  or complex option <:yatt:opt>
	# expects </yatt:call> or </:yatt:opt>
	# $self->{startln} = $self->{endln}; # No!
	$self->_parse_body($widget, $body
			   , $+{empty_elem} ? $close : $formal_path
			   , $elem, $bodyStartRef);
        #
        # x substr($widget->{cf_folder}->{cf_string}, $elem->[NODE_BEGIN], $self->{curpos} - $elem->[NODE_BEGIN])
        # x $widget->{cf_folder}->source_region($elem->[NODE_BEGIN], $self->{curpos})
        # x $self->{template}->...

        #
        $elem->[NODE_END] = $self->{curpos};
	$$bodyStartRef //= $bodystartln;
      } elsif ($is_opt) {
	# ee style option.
	# <:yatt:foo/>bar 出現後は、以後の要素を att に加える。
	$sink = $body;
        if ($last_foot) {
          $last_foot->[NODE_END] = $startPos;
        }
        $last_foot = $elem;
      } else {
      } # simple call.
      $self->_verify_token($self->{curpos}, $_) if $self->{cf_debug};
      $self->add_lineinfo($sink);

    } elsif ($path = $+{pi}) {
      $$par_ln = $self->{startln} if not $has_nonspace++ and $parent;
      # ?> まで
      unless (s{^(.*?)\?>(\r?\n)?}{}s) {
	die $self->synerror_at($self->{startln}, q{Unbalanced pi});
      }
      my $end = $self->{curpos} += 2 + length($1);
      my $nl = "\n" if $2;
      # XXX: parse_text の前なので、本当は良くない
      $self->{curpos} += length $2 if $2;
      $self->{endln} += numLines($1);
      push @$sink, do {
        my $node = [];
        $node->[NODE_TYPE] = TYPE_PI;
        $node->[NODE_BEGIN] = $self->{startpos};
        $node->[NODE_END] = $end;
        $node->[NODE_LNO] = $self->{endln};
        $node->[NODE_PATH] = [split /:/, $path];
        splice @$node, NODE_BODY, 0, lexpand($self->_parse_text_entities($1));
        $node;
      };
      if ($nl) {
	push @$sink, $nl;
	$self->{startln} = ++$self->{endln};
      }
      $self->add_lineinfo($sink);
    } else {
      die join("", "Can't parse: ", nonmatched($_));
    }
  } continue {
    $self->{startln} = $self->{endln};
    $self->{startpos} = $self->{curpos};
    $self->_verify_token($self->{startpos}, $_) if $self->{cf_debug};
  }

  if ($close and not $is_closed) {
    die $self->synerror_at($self->{startln}, q{Missing close tag '%s'}, $close);
  }

  # if ($last_foot) {
  #   die "??really??" if not defined $last_foot->[NODE_END];
  #   $last_foot->[NODE_END] //= $self->{curpos};
  # }

  # To make body-less element easily detected.
  if ($parent and $parent->[NODE_BODY]) {
    _undef_if_empty($self->node_body_slot($parent));
  }
}

sub accept_leading_text {
  (my MY $self, my ($sink, $parent, $par_ln, $rhas_nonspace)) = @_;
  $self->{endln} += numLines($&);
  if ($self->add_posinfo(length($1), 1)) {
    push @$sink, splitline($1);
    $$par_ln = $self->{startln}
      if nonspace($1) and not $$rhas_nonspace++ and $parent;
    $self->{startln} += numLines($1);
  }
  $self->{curpos} += length($&) - length($1);
  $self->_verify_token($self->{curpos}, $_) if $self->{cf_debug};
}

sub accept_entity {
  (my MY $self, my ($sink, $parent, $par_ln, $rhas_nonspace)) = @_;
  push @$sink, my $node = $self->mkentity
    ($self->{startpos}, undef, $self->{endln});
  # ; まで
  $node->[NODE_END] = $self->{curpos};
  $self->_verify_token($self->{curpos}, $_) if $self->{cf_debug};
  $self->add_lineinfo($sink);
  $$par_ln = $self->{startln}
    if nonspace($1) and not $$rhas_nonspace++ and $parent;
}

sub verify_tag {
  (my MY $self, my ($path, $close)) = @_;
  # XXX: デバッグ時、この段階での sink の様子を見たくなる。
  unless (s{^>}{}xs) {
    die $self->synerror_at($self->{endln}, q{Missing CLO(>) for: <%s}, $path);
  }
  $self->{curpos} += 1;
  unless (defined $close) {
    die $self->synerror_at($self->{endln}, q{TAG close without open! got </%s>}, $path);
  } elsif ($path ne $close) {
    die $self->synerror_at($self->{endln}, q{TAG Mismatch! <%s> closed by </%s>}
			, $close, $path);
  }
}

# $_ から &yatt]]; までを削って $node を返す

sub _parse_lcmsg {
  (my MY $self, my ($ns, $parent, $par_ln, $rhas_nonspace)) = @_;

  my $path = [$ns];
  if (s/^(?:\#(\w+))?\[{2,};//) {
    push @$path, $1 if $1;
  } else {
    die $self->synerror_at
      ($self->{startln}
       , q{parse_lcmsg is called from invalid context: %s }, $_);
  }


  my $node = [];
  $node->[NODE_TYPE] = TYPE_LCMSG;
  $node->[NODE_BEGIN] = $self->{startpos};
  $node->[NODE_LNO] = $self->{endln};
  $node->[NODE_PATH] = $path;
  $node->[NODE_BODY] = my $body = [my $sink = []];

  $self->{curpos} += length $&;

  while (length $_ and s{^(.*?)$$self{re_entopn}}{}s) {
    $self->accept_leading_text($sink, $parent, $par_ln, $rhas_nonspace);
    if ($+{msgopn}) {
      die $self->synerror_at
	($self->{startln}, q{nesting of l10n msg is not allowed});
    } elsif ($+{msgsep}) {
      s/^\|{2,};//;
      $self->{curpos} += length $&;
      # switch to next sink.
      push @$body, $sink = [];

    } elsif ($+{msgclo}) {
      s/^\]{2,};//;
      $self->{curpos} += length $&;
      $node->[NODE_END] = $self->{curpos};
      return $node;

    } elsif ($+{entity} or $+{special}) {
      $self->accept_entity($sink, $parent, $par_ln, $rhas_nonspace);
    } else {
      die $self->synerror_at
	($self->{startln}, q{Unknown input: %s}, $_);
    }
  }

  die $self->synerror_at
    ($self->{startln}
     , q{parse_lcmsg is not closed: %s}, $_);
}

sub _undef_if_empty {
  return unless defined $_[0] and ref $_[0] eq 'ARRAY';
  unless (@{$_[0]}) {
    undef $_[0];
  }
}

sub trimmed {
  my ($str) = @_;
  $str =~ s/\n.*\z//s;
  $str;
}

use YATT::Lite::Breakpoint qw(break_load_parsebody);
break_load_parsebody();

1;
