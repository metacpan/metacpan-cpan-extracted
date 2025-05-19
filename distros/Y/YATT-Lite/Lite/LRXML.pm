#========================================
# Parsing and Building. part の型を確定させる所まで請け負うことに。
package YATT::Lite::LRXML; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.010; no if $] >= 5.017011, warnings => "experimental";

use base qw(YATT::Lite::VarMaker);
use fields qw/re_decl
	      re_body
	      re_entopn
	      re_att
	      re_name
	      re_evar ch_etext
	      re_eparen
	      re_eopen re_eclose

	      template
	      chunklist
	      startln endln
	      startpos curpos
	      cf_namespace
	      cf_vfs
	      cf_default_part
	      cf_base cf_scheme cf_path cf_encoding cf_debug
	      cf_all
	      cf_special_entities
              cf_body_argument
              cf_body_argument_type

	      subroutes
	      rootroute

              cf_match_argsroute_first

	      _original_entpath
	    /;

use YATT::Lite::Core qw(Part Widget Page Action Data Entity Template ArgMacro);
use YATT::Lite::VarTypes;
use YATT::Lite::Constants;
use YATT::Lite::Util qw(numLines default untaint_unless_tainted lexpand);

use YATT::Lite::RegexpNames;

require Scalar::Util;
require Encode;
use Carp;

#========================================
sub default_public_part {'page'}
sub default_private_part {'widget'}
sub default_body_argument { 'body' }

sub default_part_for {
  (my MY $self, my Template $tmpl) = @_;
  $tmpl->{cf_public}
    ? $self->default_public_part
      : $self->default_private_part;
}

#========================================
sub after_new {
  my MY $self = shift;
  $self->SUPER::after_new;
  Scalar::Util::weaken($self->{cf_vfs}) if $self->{cf_vfs};

  $self->{cf_body_argument} //= $self->default_body_argument;

  $self->{cf_namespace} ||= [qw(yatt perl)];
  my $nspat = qr!@{[join "|", $self->namespace]}!;
  $self->{re_name} ||= $self->re_name;
  $self->{re_decl} ||= qr{<!(?:(?<declname>$nspat(?::\w++)+)
			  |(?:--\#(?<comment>$nspat(?::\w++)*)))\b}xs;
  my $entOpen = do {
    # qq なので注意
    my $entbase = qq{(?<entity>$nspat)};
    $entbase .= sprintf(q{(?=%s)}, join "|"
			, ':'
			, sprintf(q{(?<lcmsg>%s)}, join "|"
				  , q{(?<msgopn>(?:\#\w+)?\[{2,})}
				  , q{(?<msgsep>\|{2,})}
				  , q{(?<msgclo>\]{2,})}));
    my @entPat = $entbase;
    # special の場合は entgroup を呼びたいので、 先に open ( を削っておく。
    push @entPat, sprintf q{(?<special>(?:%s))\(}
      , join "|", lexpand($self->{cf_special_entities})
	if $self->{cf_special_entities};
    sprintf q{&(?:%s)}, join "|", @entPat;
  };
  $self->{re_att}
    ||= qr{(?<ws>\s++)
	 | (?<comment>--+.*?--+)
	 | (?<macro>%(?:[\w\:\.]+(?:[\w:\.\-=\[\]\{\}\(,\)]+)?);)
	 |
	   (?:'(?<sq>[^\']*+)'
	   |"(?<dq>[^\"]*+)"
	   |(?<nest>\[) | (?<nestclo>\])
	   |$entOpen
	   |(?<bare>[^\s\'\"<>\[\]/=;]++)
	   )
           (?<equal>\s*=\s*+)?+
	}xs;
  $self->{re_body} ||= qr{$entOpen
			|<(?:(?<clo>/?)(?<opt>:?)(?<elem>$nspat(?::\w++)+)
			  |\?(?<pi>$nspat(?::\w++)*))\b
		       }xs;
  # For entities.
  $self->{re_entopn} = qr{$entOpen}xs;
  $self->{re_eopen}  ||= qr{(?<open>  [\(\{\[])}xs;
  $self->{re_eclose} ||= qr{(?<close> [\)\}\]])}xs;
  $self->{re_evar}   ||= qr{: (?<var>\w+)}xs;
  $self->{ch_etext}  ||= qr{(?: [^\ \t\n,;:()\[\]{}])}xs;
  $self->{re_eparen} ||= qr{(\( (?<paren> (?: (?> [^()]+) | (?-2) )*) \) )}xs;
  $self;
}

use YATT::Lite::Types
  ([EntMatch => fields => [qw/
                               entity
                               lcmsg
                               msgopn msgsep msgclo
                               special
                             /]
    , [AttMatch => fields => [qw/ws comment
                                 macro
                                 sq dq bare
                                 nest nestclo
                                 equal
                                /]]
  ]
 );

#========================================

# Debugging aid.
# YATT::Lite::LRXML->load_from(string => '...template...')
#
sub load_from {
  my ($pack, $loadSpec, $tmplSpec, @moreLoadArgs) = @_;

  my ($loadType, @loadArgs) = ref $loadSpec ? @$loadSpec : $loadSpec;
  unless (defined $loadType) {
    croak "Undefined source type";
  }
  my $sub = $pack->can("load_${loadType}_into")
    or croak "Unknown source type: $loadType";

  my ($tmplFrom, @tmplArgs) = ref $tmplSpec ? @$tmplSpec : $tmplSpec;
  my Template $tmpl = $pack->Template->new(@tmplArgs);

  # デフォルトでは body もパースする.
  # XXX: オプション名 all だと分かりにくい。公式にする前に、改名すべき。
  $sub->($pack, $tmpl, $tmplFrom, all => 1, @loadArgs, @moreLoadArgs);
}

sub load_file_into {
  my ($pack, $tmpl, $fn) = splice @_, 0, 3;
  croak "Template argument is missing!
YATT::Lite::Parser->from_file(filename, templateObject)"
    unless defined $tmpl and UNIVERSAL::isa($tmpl, $pack->Template);
  unless (defined $fn) {
    croak "filename is undef!";
  }
  my MY $self = ref $pack ? $pack->configure(@_) : $pack->new(@_);
  open my $fh, '<', $fn or die "Can't open $fn: $!";
  binmode $fh, ":encoding($$self{cf_encoding})" if $$self{cf_encoding};
  $self->{cf_path} = $fn;
  $self->{cf_scheme} = 'file';
  my $string = do {
    local $/;
    untaint_unless_tainted($fn, scalar <$fh>);
  };
  $self->load_string_into($tmpl, $string);
}

sub load_string_into {
  (my $pack, my Template $tmpl) = splice @_, 0, 2;
  $tmpl->reset;
  my MY $self = ref $pack ? $pack->configure(@_[1 .. $#_])
    : $pack->new(@_[1 .. $#_]);
  unless (defined $_[0]) {
    croak "template string is undef!";
  }
  $self->parse_decl($tmpl, $_[0]);
  $self->parse_body($tmpl) if $self->{cf_all};
  wantarray ? ($tmpl, $self) : $tmpl;
}

sub parse_body {
  (my MY $self, my Template $tmpl) = @_;
  return if $tmpl->{parse_ok};
  $self->{template} = $tmpl;
  $self->parse_widget($_) for $tmpl->list_parts($self->Widget);
  $tmpl->{parse_ok} = 1;
}

#
# parse_decllist_entities updates all decllists in given template.
# This method is for inspector and not used from normal code generation pass.
#
sub parse_decllist_entities {
  (my MY $self, my Template $tmpl) = @_;
  foreach my Part $part ($tmpl->list_parts) {
    # $self->{startln} = $self->{endln} = $part->{cf_bodyln};
    # ($self->{startpos}, $self->{curpos}) = ($part->{cf_startpos}) x 2;
    my $decllist = $part->{decllist} or next;
    foreach my $node (@$decllist) {
      $node->[NODE_TYPE] == TYPE_ATT_TEXT
        or next;
      $self->{endln} = $node->[NODE_LNO];
      my ($type, $dflag, $default)
        = $self->parse_type_dflag_default($node->[NODE_BODY]);
      if (ref $node->[NODE_PATH]) {
        ...
      }
      $node->[NODE_BODY] = [
        $type, $dflag,
        (defined $default
         ? lexpand($self->_parse_text_entities_at($node->[NODE_BODY_BEGIN], $default))
         : ())];
    }
  }
}

sub posinfo {
  (my MY $self) = shift;
  ($self->{startpos}, $self->{curpos});
}

sub add_posinfo {
  (my MY $self, my ($len, $sync)) = @_;
  $self->{curpos} += $len;
  $self->{startpos} = $self->{curpos} if $sync;
  $len;
}

sub update_posinfo {
  my MY $self = shift;
  my ($sync) = splice @_, 1;
  # $self->{curpos} = $self->{total} - length $_[0];
  $self->{startpos} = $self->{curpos} if $sync;
}

sub ensure_default_part {
  (my MY $self, my Template $tmpl) = @_;
  my Part $part = $self->build(
    $self->primary_ns
    , args => $self->default_part_for($tmpl)
    , '', implicit => 1
    , startpos => $self->{startpos}, bodypos => $self->{startpos}
  );
  $self->add_part($tmpl, $part);
  $part;
}

sub parse_decl {
  (my MY $self, my Template $tmpl, my $str, my @config) = @_;
  # local %+; # ← XXX: This causes massive test failure, but why??
  break_parser();
  $self->{template} = $tmpl;
  $self->configure(@config);
  $tmpl->{cf_string} = $str;
  $tmpl->{cf_utf8} = Encode::is_utf8($str);
  $self->{startln} = $self->{endln} = 1;
  ($self->{startpos}, $self->{curpos}, my $total) = (0, 0, length $str);
  my Part $part;
  while ($str =~ s{^(.*?)($$self{re_decl})}{}s) {
    if (not $part and (length $1 || $+{comment})) {
      $part = $self->ensure_default_part($tmpl);
    }
    $self->add_text($part, $1) if length $1;
    $self->{curpos} = $total - length $str;
    if (my $comment_ns = $+{comment}) {
      unless ($str =~ s{^(.*?)-->(\r?\n)?}{}s) {
	die $self->synerror_at($self->{startln}, q{Comment is not closed});
      }
      my $nlines = numLines($1) + ($2 ? 1 : 0);
      $self->{curpos} += length $&;
      #
      # Yet another illegular.
      # TYPE_COMMENT:
      #  - NODE_BODY is $nlines
      #  - NODE_ATTLIST is payload.
      #
      push @{$part->{toks}}, do {
        my $node = [];
        $node->[NODE_TYPE] = TYPE_COMMENT;
        @{$node}[NODE_BEGIN, NODE_END] = $self->posinfo($str);
        $node->[NODE_LNO] = $self->{startln};
        $node->[NODE_PATH] = $comment_ns;
        $node->[NODE_BODY] = $nlines;
        $node->[NODE_ATTLIST] = $1;
        $node;
      };
      $self->{startln} = $self->{endln} += $nlines;
      next;
    }
    my $declkind = $+{declname};
    my ($ns, $kind) = split /:/, $declkind, 2;
    if (my $sub = $self->can("declare_$kind")) {
      # add_part を自分で呼びたい、又は add_part 自体を呼びたくないものは
      # declare_ で処理する

      # 戻り値が undef なら、同じ $part を用いつづける。
      my @args = $self->parse_attlist(\$str, 1);
      my $newpart = $sub->($self, $tmpl, $ns, @args);

      if ($newpart) {
        $self->finalize_part($part) if $part;
        $newpart->{decllist} = \@args;
        $part = $newpart;
      }
    }
    elsif ($self->can("build_$kind")) {
      $self->finalize_part($part) if $part;
      # yatt:widget, entity
      my (@args) = $self->parse_attlist(\$str, 1); # To delay entity parsing.
      my $saved_attlist = [@args];

      # Cut partname="/route/pattern" from @args
      my ($partName, $mapping) = $self->cut_partname_and_route($declkind, \@args);

      $self->add_part($tmpl, $part = $self->build($ns, $kind, $kind, $partName));

      # $part decllist may contain not only attributes but also others
      # like argmacrosand possible future items.
      $part->{decllist} = $saved_attlist;

      if ($mapping) {
        $self->add_route($part, $mapping);
      }
      $self->add_args($part, @args);
    }
    else {
      die $self->synerror_at($self->{startln}, q{Unknown declarator (<!%s:%s >)}, $ns, $kind);
    }
    unless ($str =~ s{^>([\ \t]*\r?\n)?}{}s) {
      # XXX: たくさん出しすぎ
      die $self->synerror_at($self->{startln}, q{Declarator '<!%s:%s' is not closed with '>': %s}
		   , $ns, $kind
		   , $str);
    }
    # <!yatt:...> の直後には改行が必要、とする。
    unless ($1) {
      die $self->synerror_at($self->{startln}, q{<!%s:%s> must end with newline!}, $ns, $kind);
    }
    $self->add_posinfo(length $&);
    $self->{endln} += numLines($1);
    if ($part) {
      $part->{cf_bodypos} = $self->{curpos};
      $part->{cf_bodyln} = $self->{endln}; # part の本体開始行の初期値
    }
  } continue {
    $self->{startpos} = $self->{curpos};
  }

  # Even if no declarations are found, there should be at least one default part.
  $part //= $self->ensure_default_part($tmpl);
  push @{$part->{toks}}, nonmatched($str);
  # widget->{cf_endln} は, (視覚上の最後の行)より一つ先の行を指す。(末尾の改行を数える分,多い)
  $part->{cf_endln} = $self->{endln} += numLines($str);

  $self->finalize_part($part);
  $self->finalize_template($tmpl);
}

sub cut_partname_and_route {
  (my MY $self, my ($declkind, $argList)) = @_;
  my $nameAtt = YATT::Lite::Constants::cut_first_att($argList) or do {
    my Template $tmpl = $self->{template};
    die $self->synerror_at($self->{startln}, q{No part name in %s\n%s}
                           , $declkind
                           , nonmatched($tmpl->{cf_string}));
  };
  my ($partName, $mapping);
  if ($nameAtt->[NODE_TYPE] == TYPE_ATT_NAMEONLY) {
    $partName = $nameAtt->[NODE_PATH];
  } elsif ($nameAtt->[NODE_TYPE] == TYPE_ATT_TEXT) {
    if (ref $nameAtt->[NODE_BODY]) {
      my $t = $YATT::Lite::Constants::TYPE_[$nameAtt->[NODE_BODY][0][NODE_TYPE]];
      die $self->synerror_at($self->{startln}
                             , q{%s got wrong token for route spec: %s}
                             , $declkind, $t);
    }
    if ($nameAtt->[NODE_BODY] eq '') {
      $partName = $nameAtt->[NODE_PATH] // '';
    } else {
      # $partName が foo=bar なら pattern として扱う
      $mapping = $self->parse_location
        ($nameAtt->[NODE_BODY], $nameAtt->[NODE_PATH]) or do {
          die $self->synerror_at($self->{startln}
                                 , q{Invalid location in %s - "%s"}
                                 , $declkind, $nameAtt->[NODE_BODY])
        };
      $partName = $nameAtt->[NODE_PATH]
        // $self->location2name($nameAtt->[NODE_BODY]);
    }
  } else {
    die $self->synerror_at($self->{startln}, q{Invalid part name in %s}
                           , $declkind);
  }

  ($partName, $mapping);
}

sub finalize_template {
  (my MY $self, my Template $tmpl) = @_;

  $self->fixup_template_foreach_part_posinfo($tmpl);

  $tmpl->{cf_nlines} = $self->{endln};

  if ($self->{cf_match_argsroute_first}) {
    if ($self->{rootroute}) {
      $self->subroutes->append($self->{rootroute});
    }
  }
  if ($self->{subroutes}) {
    $tmpl->{cf_subroutes} = $self->{subroutes};
  }
  $tmpl
}

sub fixup_template_foreach_part_posinfo {
  (my MY $self, my Template $tmpl) = @_;
  # $default が partlist に足されてなかったら、先頭に足す... 逆か。
  # args が、 $default を先頭から削る?
  # fixup parts.
  my Part $prev;
  foreach my Part $part (@{$tmpl->{partlist}}) {
    if ($prev) {
      unless (defined $part->{cf_startpos}) {
	die $self->synerror_at($self->{startln}, q{startpos is undef});
      }
      unless (defined $prev->{cf_bodypos}) {
	die $self->synerror_at($self->{startln}, q{prev bodypos is undef});
      }
      $prev->{cf_bodylen} = $part->{cf_startpos} - $prev->{cf_bodypos};
    }
    if ($part->{toks} and @{$part->{toks}}) {
      # widget 末尾の連続改行を、単一の改行トークンへ変換。(行番号は解析済みだから大丈夫)
      if ($part->{toks}[-1] =~ s/(?:\r?\n)+\Z//) {
	push @{$part->{toks}}, "\n"
	  unless $tmpl->{cf_ignore_trailing_newlines};
      }
    }
    if (my $sub = $part->can('fixup')) {
      $sub->($part, $tmpl, $self);
    }
  } continue { $prev = $part }
  if ($prev) {
    $prev->{cf_bodylen} = length($tmpl->{cf_string}) - $prev->{cf_bodypos};
  }
}

sub parse_attlist {
  (my MY $self, my ($strref, @opt)) = @_;
  $self->parse_attlist_with_lvalue($self->{curpos}, undef, $strref, @opt);
}

sub parse_attlist_with_lvalue {
  (my MY $self, my ($outer_start, $outer_lvalue, $strref, @opt)) = @_;

  # To examine node range in perldebugger, do like following:
  #
  #   x substr($self->{template}{cf_string}, 18, 26-18)
  #

  my ($for_decl) = @opt;
  my (@result, @lvalue); # Note: @lvalue contains position of lvalue expression.
  my $curln = $self->{endln};
  while ($$strref =~ s{^$$self{re_att}}{}xs) {
    my $start = $self->{curpos};
    $self->{curpos} += length $&;
    # startln は不変に保つ. これは add_part が startln を使うため
    $self->{endln} += numLines($&);

    my AttMatch $m = \%+;
    next if $m->{ws} || $m->{comment};
    if ($m->{macro}) {
      push @result, $self->mkargmacro($start, $m->{macro});
      next;
    }

    my @common = ($start, $self->{curpos}, $curln);
    my $mklval = sub {
      if (@lvalue) {
        my ($s, $p, $l, $n) = splice(@lvalue);
        # For endpos, curpos should be fetched after the parsing.
        ($s, $self->{curpos}, $l, $n);
      } else {
        (@common, undef);
      }
    };

    # lvalue or rvalue
    if (not $m->{equal}) {
      # rvalue
      # create node. may have lvalue.
      if ($m->{nestclo}) {
        # "body = [code p q]" comes here
        unless ($outer_lvalue) {
          Carp::croak("syntax error");
        }
        my ($s, $p, $l, $n) = do {
          if ($outer_lvalue && @$outer_lvalue) {
            splice(@$outer_lvalue);
          } else {
            (@common, undef)
          }
        };
        my $node = [];
        $node->[NODE_TYPE] = TYPE_ATT_NESTED;
        $node->[NODE_BEGIN] = $outer_start;
        $node->[NODE_END] = $self->{curpos};
        $node->[NODE_LNO] = $l;
        $node->[NODE_PATH] = $n;
        $node->[NODE_BODY] = \@result;
        return $node;
      }

      if ($m->{nest}) {
        # [ 〜 ]
        push @result,
          $self->parse_attlist_with_lvalue($start, \@lvalue, $strref, @opt);
      } else {
        push @result, my $node = [];
        {
          if ($m->{bare} and is_ident($m->{bare})) {
            if (@lvalue) {
              $node->[NODE_TYPE] = TYPE_ATT_BARENAME;
              @{$node}[NODE_BEGIN, NODE_END, NODE_LNO, NODE_PATH] = splice(@lvalue);
              $node->[NODE_BODY] = $m->{bare};
            } else {
              $node->[NODE_TYPE] = TYPE_ATT_NAMEONLY;
              @{$node}[NODE_BEGIN, NODE_END, NODE_LNO] = @common;
              $node->[NODE_PATH] = split_ns($m->{bare});
            }
          } elsif ($+{entity} or $+{special}) {
            # XXX: 間に space が入ってたら?
            if ($m->{lcmsg}) {
              die $self->synerror_at($self->{startln}
                                     , q{l10n msg is not allowed here});
            }
            $node->[NODE_TYPE] = TYPE_ATT_TEXT;
            @{$node}[NODE_BEGIN, NODE_END, NODE_LNO, NODE_PATH] = $mklval->();

            # Below is a workaround for unclosed `<!yatt:args` with `&yatt:var;`
            # There would be a better way to handle this...
            $_ = $$strref;

            $node->[NODE_BODY] = [$self->mkentity(@common)];
            $node->[NODE_END] = $self->{curpos};
          } else {
            my ($quote, $value) = oneof($m, qw(bare sq dq));
            $node->[NODE_TYPE] = TYPE_ATT_TEXT;
            @{$node}[NODE_BEGIN, NODE_END, NODE_LNO, NODE_PATH] = $mklval->();
            $node->[NODE_BODY_BEGIN] = $start + ($quote ? 1 : 0);
            splice @$node, NODE_BODY, 0, (
              $for_decl ? $value : $self->_parse_text_entities_at(
                $node->[NODE_BODY_BEGIN], $value
              )
            );
          }
        };
        $node->[NODE_BODY_END] = $self->{curpos};
      }
    }
    # lvalue expression.
    elsif (
      # m->{equal} and
      not @lvalue
    ) {
      # got lvalue =, continue to rvalue
      if ($m->{bare} and is_ident($m->{bare})) {
        @lvalue = (@common, split_ns($m->{bare}));
      }
      elsif ($m->{nestclo}) {
        my ($s, $p, $l) = @common;
        @lvalue = ($outer_start, undef, $l, [splice @result]);
      }
      else {
        Carp::croak("unknown");
      }
    }
    else {
      # error
      die $self->synerror_at(
        $self->{startln}
        , q{assignment (=) after assignment (=) is not allowed}
      );
    }
  } continue {
    $curln = $self->{endln};
    $self->_verify_token($self->{curpos}, $$strref) if $self->{cf_debug};
  }
  wantarray ? @result : \@result;
}

sub mkargmacro {
  (my MY $self, my ($start, $string)) = @_;
  local $_ = $string;

  my $node = [];
  $node->[NODE_TYPE] = TYPE_ATT_MACRO;
  @{$node}[NODE_BEGIN, NODE_END, NODE_LNO] = ($start, $self->{curpos}, $self->{startln});

  # namespace-less なケースも扱いたいので % を : に置換
  s/^%/:/;

  # _parse_entpath だと curpos を移動させてしまうため
  my (@path) = $self->_parse_pipeline;

  $node->[NODE_PATH] = do {
    if (@path >= 2 and $path[0][0] eq 'var') {
      my $head = shift @path;
      $head->[1];
    } else {
      undef;
    }
  };

  splice @$node, NODE_BODY, 0, @path;

  if ($_ ne ';') {
    die $self->synerror_at($self->{startln}
                           , q{Invalid decl entity: %s (%s remains)}, $string, $_);
  }

  $node;
}

sub mkentity {
  (my MY $self) = shift;
  # assert @_ == 3;
  my $node = [];
  $node->[NODE_TYPE] = TYPE_ENTITY;
  @{$node}[NODE_BEGIN, NODE_END, NODE_LNO] = @_;
  if (my $ns = $+{entity}) {
    $node->[NODE_PATH] = $ns;
    splice @$node, NODE_BODY, 0, $self->_parse_entpath;
  } elsif (my $special = $+{special}) {
    $node->[NODE_BODY] = [call => $special
                          , $self->_parse_entpath(_parse_entgroup => ')')];
  } else {
    die "mkentity called without entity or special";
  }
  $node->[NODE_END] = $self->{curpos};
  $node;
}

sub split_ns {
  defined (my $value = shift)
    or return undef; # make sure one scalar.
  local %+;
  my @names = split /:/, $value;
  @names > 1 ? \@names : $value;
}

# widget の body の構文については、 Template が規定してよい。
sub parse_widget {
  (my MY $self, my Widget $widget) = @_;
  $self->{startln} = $self->{endln} = $widget->{cf_bodyln};
  # XXX: 戻り値でも良い気はする。とはいえ、デバッグは楽か。
  local $self->{chunklist} = my $chunks = [@{$widget->{toks} //= []}];
  local $_ = @$chunks && !ref $chunks->[0] ? shift @$chunks : '';
  $self->{startpos} = $self->{curpos} = $widget->{cf_bodypos};
  $self->_parse_body($widget, $widget->{tree} = []);
  push @{$widget->{tree}}, nonmatched($_); # XXX: nest 時以外
  $widget;
}

sub _get_chunk {
  (my MY $self, my $sink) = @_;
  my $chunks = $self->{chunklist};
  if (length $_) {
    push @$sink, $_ if $sink;
    $self->{startln} = $self->{endln} += numLines($_);
    $self->{curpos} = $self->{startpos} += length $_;
    $_ = '';
  }
  # comment の読み飛ばし
  while (@$chunks and ref $chunks->[0]) {
    my $next = shift @$chunks;
    push @$sink, $next if $sink;
    $self->{startln} = $self->{endln} += $next->[NODE_BODY];
    $self->{curpos} = $self->{startpos} = $next->[NODE_END];
  }
  return unless @$chunks;
  $_ = shift @$chunks;
  1
}

sub nonspace {
  local (%+, $&, $1, $2);
  $_[0] =~ /\S/;
}

sub splitline {
  local (%+, $&, $1, $2);
  split /(?<=\n)/, $_[0];
}

sub _verify_token {
  (my MY $self, my $pos) = splice @_, 0, 2;
  unless (defined $pos) {
    die $self->synerror_at($self->{startln}, q{Token pos is undef!: now='%s'}, $_[0]);
  }
  my $tok = $self->{template}->source_substr($pos, length $_[0]);
  unless (defined $tok) {
    die $self->synerror_at($self->{startln}, q{Token substr is empty!: now='%s'}, $_[0]);
  }
  unless ($tok eq $_[0]) {
    die $self->synerror_at($self->{startln}, q{Token mismatch!: substr='%s', now='%s'}
			, $tok, $_[0]);
  }
}

sub drop_leading_ws {
  my $list = shift;
  local (%+, $1, $2, $&);
  pop @$list while @$list and $list->[-1] =~ /^\s*$/s;
}

#========================================
# build($ns, $kind, $partName, @attlist)
sub build {
  (my MY $self, my ($ns, $decl, $kind, $partName, @rest)) = @_;
  local %+;
  $self->can("build_$kind")->
    ($self, name => $partName, decl => $decl, kind => $kind
     , namespace => $ns
     , folder => $self->{template}
     , startpos => $self->{startpos}, @rest);
}

sub build_widget { shift->Widget->new(@_) }
sub build_page { shift->Page->new(@_) }
sub build_action { shift->Action->new(@_) }
sub build_data { shift->Data->new(@_) }

sub build_entity { shift->Entity->new(@_) }

sub build_argmacro { shift->ArgMacro->new(@_) }

#========================================
# declare
sub declare_base {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;

  # Accept empty '<!yatt:base>' declaration as nop for parser testing aid.
  $self->{cf_vfs}->declare_base($self, $tmpl, $ns, @args)
    if @args;

  undef;
}

sub declare_args {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  my $kind = 'args';
  my $declkind = join(":", $ns, $kind);
  my Widget $newpart = $self->cut_implicit_default_part($tmpl, $declkind)
    || $self->build($ns, $kind => $self->default_part_for($tmpl), ''
                    , startln => $self->{startln});

  if (not grep {/\S/} @{$newpart->{toks}}) {
    $newpart->configure(
      # startpos => $self->{curpos},
      startln => $self->{startln},
    );
    $newpart->{toks} = [];
  }

  $self->cut_root_route_and_install_url_params($newpart, \@args);

  # $newpart->{cf_startpos} = $self->{startpos};
  # $newpart->{cf_bodypos} = $self->{curpos} + 1;
  $self->add_part($tmpl, $newpart, 1); # partlist と Item に足し直す. no_conflict_check

  $self->add_args($newpart, @args);

  $newpart;
}

sub cut_implicit_default_part {
  (my MY $self, my Template $tmpl, my ($declkind)) = @_;
  (my Part $oldpart, my @other) = $self->list_default_parts($tmpl);
  unless (not $oldpart or $oldpart->{cf_implicit}) {
    die $self->synerror_at($self->{startln}
                           , q{<!%s> at line %d conflicts with <!%s>}
                           , $oldpart->syntax_keyword, $oldpart->{cf_startln}
                           , $declkind);
  }
  if ($oldpart
      and $tmpl->{partlist} and @{$tmpl->{partlist}} == 1
      and $tmpl->{partlist}[0] == $oldpart) {
    # 先頭だったら再利用。
    shift @{$tmpl->{partlist}}; # == $oldpart
  } else {
    $oldpart->{cf_suppressed} = 1 if $oldpart; # 途中なら、古いものを隠して、新たに作り直し。

    return undef;
  }
}

sub cut_root_route_and_install_url_params {
  (my MY $self, my Part $part, my ($argList)) = @_;

  return unless @$argList and $argList->[0]
    and $argList->[0][NODE_TYPE] == TYPE_ATT_TEXT
    and not defined $argList->[0]->[NODE_PATH];

  my $patNode = shift @$argList;
  if (ref $patNode->[NODE_BODY]) {
    my $t = $YATT::Lite::Constants::TYPE_[$patNode->[NODE_BODY][0][NODE_TYPE]];
    die $self->synerror_at($self->{startln}
                           , q{%s got wrong token for route spec: %s}
                           , $part->syntax_keyword, $t);

  }
  my $mapping = $self->parse_location($patNode->[NODE_BODY], '', $part)
    or do {
      die $self->synerror_at($self->{startln}
                             , q{Invalid route spec in %s - "%s"}
                             , $part->syntax_keyword, $patNode->[NODE_BODY]);
    };
  if ($self->{cf_match_argsroute_first}) {
    $self->{rootroute} = $mapping;
  } else {
    $self->{subroutes}->append($mapping);
  }
  $self->add_url_params($part, lexpand($mapping->cget('params')));

}

sub declare_action {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  my $kind = 'action';
  my $declkind = join(":", $ns, $kind);

  my ($partName, $mapping) = $self->cut_partname_and_route($declkind, \@args);

  if ($partName eq '' and not $mapping) {
    # implicit な page は suppress
    # explicit な page は構文エラー(再利用は出来ない)
    my $declname = "$declkind ''";
    if (my Part $implicit = $self->cut_implicit_default_part($tmpl, $declname)) {
      die $self->synerror_at($self->{startln}
                             , q{<!%s> conflicts with name-less default widget}
                             , "$declkind ''");
    }
  }

  my Part $newpart = $self->build($ns, $kind => $kind, $partName, startln => $self->{startln});

  $self->add_part($tmpl, $newpart, 1); # partlist と Item に足し直す. no_conflict_check

  if ($mapping) {
    $self->add_route($newpart, $mapping);
  }

  $self->add_args($newpart, @args);

  $newpart;
}

sub list_default_parts {
  (my MY $self, my Template $tmpl) = @_;
  return unless $tmpl->{partlist};
  grep {
    my Part $part = $_;
    $part->{cf_name} eq '' and not $part->{cf_suppressed};
  } @{$tmpl->{partlist}};
}

# <!yatt:config cf=value...>
sub declare_config {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  # XXX: 一方が undef だったら？
  $tmpl->configure(map {($_->[NODE_PATH], $_->[NODE_BODY] // 1)} @args);
  undef;
}

sub declare_constants {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  $tmpl->{cf_constants} = \@args;
  undef;
}

# <!yatt:argmacro macroName=[...output_args...] ...args>
sub declare_argmacro {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  my $kind = 'argmacro';
  my $declkind = join(":", $ns, $kind);

  my $nameAtt = YATT::Lite::Constants::cut_first_att(\@args) or do {
    die $self->synerror_at($self->{startln}, q{No part name in %s\n%s}
                           , $declkind
                           , nonmatched($tmpl->{cf_string}));
  };

  my $partName = $nameAtt->[NODE_PATH];

  my $output_args = do {
    if ($nameAtt->[NODE_TYPE] == TYPE_ATT_NESTED) {
      $nameAtt->[NODE_BODY]
    } else {
      my $node = [];
      $node->[NODE_TYPE] = TYPE_ATT_NAMEONLY;
      $node->[NODE_PATH] = $partName;
      [$node];
    }
  };

  if ($tmpl->{argmacro_dict}{$partName}) {
    die $self->synerror_at($self->{startln}, q{Duplicate argmacro %s in %s}
                           , $partName
                           , $declkind);
  }

  my Part $newpart = $self->build(
    $ns, $kind => $kind, $partName, startln => $self->{startln},
    output_args => $output_args,
  );

  Scalar::Util::weaken($tmpl->{argmacro_dict}{$partName} = $newpart);

  $self->add_args($newpart, @args);

  $newpart;
}

sub finalize_part {
  (my MY $self, my Part $part) = @_;
  my $finalizer = $self->can("finalize__" . $part->{cf_kind})
    or return;
  $finalizer->($self, $part)
}

sub finalize__argmacro {
  (my MY $self, my ArgMacro $argmacro) = @_;
  require YATT::Lite::CGen::ArgMacro;
  my $builder = YATT::Lite::CGen::ArgMacro->new(
    vfs => $self->{cf_vfs}
  );

  $argmacro->{on_declare} = $builder->with_template(
    $self->{template},
    generate_on_declare => ($argmacro),
  );

  $argmacro;
}

#========================================

sub location2name {
  (my MY $self, my $location) = @_;
  $location =~ s{([^A-Za-z0-9])}{'_'.sprintf("%02x", unpack("C", $1))}eg;
  $location;
}

sub parse_location {
  (my MY $self, my ($location, $name, $item)) = @_;
  return unless $location =~ m{^/};
  $self->subroutes->create([$name, $location], $item);
}

sub subroutes {
  (my MY $self) = @_;
  $self->{subroutes} //= $self->SubRoutes->new;
}

sub SubRoutes {
  require YATT::Lite::WebMVC0::SubRoutes;
  'YATT::Lite::WebMVC0::SubRoutes'
}

#========================================
sub primary_ns {
  my MY $self = shift;
  unless ($self->{cf_namespace}) {
    'yatt';
  } else {
    first($self->{cf_namespace});
  }
}
sub namespace {
  my MY $self = shift;
  return unless defined $self->{cf_namespace};
  ref $self->{cf_namespace} && wantarray
    ? @{$self->{cf_namespace}}
      : $self->{cf_namespace};
}

#========================================
sub add_part {
  (my MY $self, my Template $tmpl, my Part $part, my $no_conflict_check) = @_;
  my $itemKey = $part->item_key;
  if (not $no_conflict_check and defined $tmpl->{Item}{$itemKey}) {
    die $self->synerror_at($self->{startln}, q{Conflicting part name! '%s'}, $part->{cf_name});
  }
  if ($tmpl->{partlist} and my Part $prev = $tmpl->{partlist}[-1]) {
    $prev->{cf_endln} = $self->{endln};
  }
  $part->{cf_startln} = $self->{startln};
  $part->{cf_bodyln} = $self->{endln};
  push @{$tmpl->{partlist}}, $tmpl->{Item}{$itemKey} = $part;
}

sub add_route {
  (my MY $self, my Part $part, my $mapping) = @_;
  $mapping->configure(item => $part);
  $self->{subroutes}->append($mapping);
  $self->add_url_params($part, lexpand($mapping->cget('params')));
}

sub add_text {
  (my MY $self, my Part $part, my $text) = @_;
  push @{$part->{toks}}, $text;
  $self->add_posinfo(length($text), 1);
  $self->{startln} = $self->{endln} += numLines($text);
}

sub add_lineinfo {
  (my MY $self, my $sink) = @_;
  # push @$sink, [TYPE_LINEINFO, $self->{endln}];
}

sub parse_arg_spec_for_part {
  (my MY $self, my Part $part, my $attNode) = @_;
    my ($node_type, $lno, $argName, $desc)
      = @{$attNode}[NODE_TYPE, NODE_LNO, NODE_PATH, NODE_BODY];
  my ($type, $dflag, $default);
  if ($node_type == TYPE_ATT_NESTED) {
    my $headDesc = $desc->[0];
    $type = $headDesc->[NODE_PATH] || $headDesc->[NODE_BODY];
    # primary of [primary key=val key=val] # delegate:foo の時は BODY に入る？
  } else {
    ($type, $dflag, $default) = $self->parse_type_dflag_default($desc);
  };
  ($type, $argName, nextArgNo($part)
   , $lno, $node_type, $dflag
   , $default);
}

sub add_args {
  (my MY $self, my Part $part) = splice @_, 0, 2;
  foreach my $argSpec (@_) {

    # XXX: comment もあるし、 %yatt:argmacro; もある。
    if ($argSpec->[NODE_TYPE] == TYPE_ATT_MACRO) {
      $self->add_argmacro($part, $argSpec);
      next;
    }

    my ($type, $argName, $nextArgNo, $lno, $node_type, $dflag, $default)
      = my @argSpec = $self->parse_arg_spec_for_part($part, $argSpec);
    unless (defined $argName) {
      die $self->synerror_at($self->{startln}, 'argName is empty!');
    }

    if (my $var = $part->{arg_dict}{$argName}) {
      if ($var->from_route) {
        # Override $type, $dflag, $default of this var.
        $self->set_var_type($var, $type); # type is always overridden.
        $self->set_dflag_default_to($var, $dflag, $default);
      } else {
        die $self->synerror_at($self->{startln}
                               , 'Argument %s redefined in %s %s'
                               , $argName, $part->{cf_kind}, $part->{cf_name});
      }
    } else {
      my $var = $self->mkvar_at($self->{startln}, @argSpec);
      $self->set_dflag_default_to($var, $dflag, $default);

      my $type = $var->type->[0];
      if ($node_type == TYPE_ATT_NESTED) {
        # XXX: [delegate:type ...], [code  ...] の ... が来る
        # 仮想的な widget にする？ のが一番楽そうではあるか。そうすれば add_args 出来る。
        # $self->add_arg_of_delegate/code/...へ。
        my $sub = $self->can("add_arg_of_type_$type") or do {
          die $self->synerror_at($self->{startln}, "Unknown arg type in arg '%s': %s", $argName, $type)
        };
        $sub->($self, $part, $var, $argSpec->[NODE_BODY]);
      } else {
        if (my $sub = $self->can("add_arg_of_type_$type")) {
          $sub->($self, $part, $var, []);
        } else {
          push @{$part->{arg_order}}, $argName;
          $part->{arg_dict}{$argName} = $var;
        }
      }
    }
  }
  $self;
}

# %macroName(renameTo=renameFrom);
sub add_argmacro {
  (my MY $self, my Part $part, my $node) = @_;
  # widget 宣言の中で argmacro を呼び出す

  my ArgMacro $argmacro = $self->find_argmacro($node);

  require YATT::Lite::CGen::ArgMacro;
  my $builder = YATT::Lite::CGen::ArgMacro->new(
    vfs => $self->{cf_vfs}
  );
  $builder->with_template(
    $self->{template},
    $argmacro->{on_declare} => ($self, $part, $node)
  );

  return;
}

sub find_argmacro {
  (my MY $self, my $node) = @_;

  my $ns = $node->[NODE_PATH];
  my ($call, $macroName, $renameSpec) = @{$node->[NODE_BODY]};

  # XXX: %yatt:foo; namespace の扱い

  my Template $tmpl = $self->{template};
  my ArgMacro $argmacro = $tmpl->{argmacro_dict}{$macroName};
  return $argmacro if $argmacro;

  # XXX: ディレクトリからの追加を許すか否か、その場合の意味論…
  foreach my Part $part ($tmpl->list_base) {
    next unless $part->isa(Template);
    my Template $base = $part;
    if ($argmacro = $base->{argmacro_dict}{$macroName}) {
      return $argmacro
    }
  }

  die $self->synerror_at($node->[NODE_LNO]
                         , "Unknown argmacro '%s'"
                         , $macroName)
}

sub add_url_params {
  (my MY $self, my Part $part, my @params) = @_;
  foreach my $param (@params) {
    my ($argName, $type_or_pat) = @$param;
    my $type = 'value'; # XXX: type_or_pat
    my $var = $self->mkvar_at($self->{startln}, $type, $argName
			      , nextArgNo($part));
    $var->from_route(1);
    push @{$part->{arg_order}}, $argName;
    $part->{arg_dict}{$argName} = $var;
  }
}

# code 型は仮想的な Widget を作る。
sub add_arg_of_type_code {
  (my MY $self, my Part $part, my ($var, $attlist)) = @_;
  $var->widget(my Widget $virtual = $self->Widget->new(name => $var->varname));
  $self->add_args($virtual, @$attlist);
  my $argName = $var->varname;
  push @{$part->{arg_order}}, $argName;
  $part->{arg_dict}{$argName} = $var;
}

sub add_arg_of_type_delegate {
  (my MY $self, my Widget $widget, my ($var, $attlist)) = @_;
  # XXX: 引数でない変数も足さないと...
  my $name = $var->varname;
  # XXX: 既に有ったらエラーにしないと。
  $widget->{var_dict}{$name} = $var;
  my ($type, @subtype) = @{$var->type};
  my @wpath = @subtype ? @subtype : $name;
  my Widget $delegate = $self->{cf_vfs}->find_part_from
    ($widget->{cf_folder}, @wpath) or do {
      $self->synerror_at($self->{startln}, "Can't find delegate widget for argument %s=[%s]", $name, join(":", $type, @subtype));
    };
  $var->weakened_set_widget($delegate);
  unless (Scalar::Util::isweak($var->[YATT::Lite::VarTypes::t_delegate::VSLOT_WIDGET])) {
    die "Can't weaken!";
  }
  $var->delegate_vars(\ my %delegate_vars);

  my ($attDict, $excludeDict) = do {
    my (%attDict, %exclDict);
    foreach my $argSpec (@$attlist) {
      if (my $attName = $argSpec->[NODE_PATH]) {
	defined $attDict{$attName}
	  and die $self->synerror_at
	  ($argSpec->[NODE_LNO]
	   , "Duplicate argname '%s' in delegate var %s"
	   , $attName, $name);
	$attDict{$attName} = $argSpec;
      } elsif ($argSpec->[NODE_TYPE] == TYPE_ATT_TEXT
	       and ($attName) = $argSpec->[NODE_BODY] =~ /^-(\w+)$/) {
	if (not $delegate->{arg_dict}{$attName}) {
	  die $self->synerror_at
	    ($argSpec->[NODE_LNO]
	     , "No such argument '%s' in delegate to '%s'"
	     , $attName, $name);
	}
	$exclDict{$attName} = $argSpec;
      } else {
	die $self->synerror_at
	  ($argSpec->[NODE_LNO]
	   , "Invalid decl spec for delegate var %s", $name);
      }
    }
    (\%attDict, \%exclDict);
  };

  foreach my $argName (@{$delegate->{arg_order}}) {
    # 既に宣言されている名前は、足さない。
    next if $widget->{arg_dict}{$argName};

    # Ignore [delegate -excluded_var]
    next if $excludeDict->{$argName};

    $delegate_vars{$argName} = my $orig = $delegate->{arg_dict}{$argName};

    my $actual = do {
      if (my $att = $attDict->{$argName}) {
	my @new = $self->parse_arg_spec_for_part($widget, $att);
	$new[0] ||= $orig->[0];
	$self->mkvar_at($self->{startln}, @new);
      } else {
	# clone して argno と lineno を変える。
	$self->mkvar_at($widget->{cf_startln}, @$orig)
	  ->argno(nextArgNo($widget))->lineno($widget->{cf_startln});
      }
    };
    $widget->{arg_dict}{$argName} = $actual;
    # XXX: lineno を widget の startln にするのは手抜き。本来は直前の arg のものを使うべき。
    push @{$widget->{arg_order}}, $argName;
  }
}
sub nextArgNo {
  (my Part $part) = @_;
  $part->{arg_order} ? scalar @{$part->{arg_order}} : 0;
}

#========================================
sub synerror_at {
  (my MY $self, my $ln) = splice @_, 0, 2;
  my %opts = ($self->_tmpl_file_line($ln), depth => 2);
  $self->_error(\%opts, @_);
}

sub _error {
  (my MY $self, my ($opts, $fmt)) = splice @_, 0, 3;
  if (my $vfs = $self->{cf_vfs}) {
    $vfs->error($opts, $fmt, @_);
  } else {
    sprintf($fmt, @_);
  }
}

sub _tmpl_file_line {
  (my MY $self, my $ln) = @_;
  ($$self{cf_path} ? (tmpl_file => $$self{cf_path}) : ()
   , defined $ln ? (tmpl_line => $ln) : ());
}

#========================================
sub is_ident {
  return undef unless defined $_[0];
  local %+;
  $_[0] =~ m{^[[:alpha:]_\:](?:\w+|:)*$}; # To exclude leading digit.
}

sub oneof {
  my $hash = shift;
  my $i = 0;
  foreach my $key (@_) {
    if (defined(my $value = $hash->{$key})) {
      return $i => $value;
    }
  } continue {
    $i++;
  }
  die "really??";
}

sub first { ref $_[0] ? $_[0][0] : $_[0] }

sub nonmatched {
  return unless defined $_[0] and length $_[0];
  $_[0];
}

sub shortened_original_entpath {
  (my MY $self) = @_;
  my $str = $self->{_original_entpath};
  $str =~ s/\n.*\z//s;
  $str;
}

#========================================

sub _parse_body;

sub _parse_text_entities_at;
sub _parse_text_entities;
sub _parse_entpath;
sub _parse_pipeline;
sub _parse_entgroup;
sub _parse_entterm;
sub _parse_group_string;
sub _parse_hash;

sub DESTROY {}

sub AUTOLOAD {
  unless (ref $_[0]) {
    confess "BUG! \$self isn't object!";
  }
  my $sub = our $AUTOLOAD;
  (my $meth = $sub) =~ s/.*:://;
  my $sym = $YATT::Lite::LRXML::{$meth}
    or croak "No such method: $meth";
  if ($meth =~ /ent|pipeline/) {
    require YATT::Lite::LRXML::ParseEntpath
  }
  elsif ($meth =~ /body/) {
    require YATT::Lite::LRXML::ParseBody
  }
  else {
    my MY $self = $_[0];
    die $self->synerror_at($self->{startln}, "Unknown method: %s", $meth);
  }
  my $code = *{$sym}{CODE}
    or croak "Can't find definition of: $meth";
  goto &$code;
}

#
use YATT::Lite::Breakpoint qw(break_load_parser break_parser);
break_load_parser();

1;
