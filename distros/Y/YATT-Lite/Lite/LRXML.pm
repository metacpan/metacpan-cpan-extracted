#========================================
# Parsing and Building. part の型を確定させる所まで請け負うことに。
package YATT::Lite::LRXML; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.010; no if $] >= 5.017011, warnings => "experimental";

# 現在宣言 parse 中の template (path キー)。declare_import の循環検出用。GH-256
our %DECL_PARSING;

use base qw(YATT::Lite::VarMaker);
use fields qw/_re_decl
	      _re_body
	      _re_entopn
	      _re_att
	      _re_name
	      _re_evar _ch_etext
	      _re_eparen
	      _re_eopen _re_eclose

	      _template
	      _chunklist
	      _startln _endln
	      _startpos _curpos
	      namespace
	      vfs
	      default_part
	      base scheme path encoding debug
	      all
	      special_entities
              body_argument
              body_argument_type

	      _subroutes
	      _rootroute

              match_argsroute_first

	      _original_entpath
              allow_bare_entity_in_decl
	    /;

use YATT::Lite::Core qw(Part Widget Page Action Data Entity Template ArgMacro Import);
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
  $tmpl->{public}
    ? $self->default_public_part
      : $self->default_private_part;
}

#========================================
sub after_new {
  my MY $self = shift;
  $self->SUPER::after_new;
  Scalar::Util::weaken($self->{vfs}) if $self->{vfs};

  $self->{body_argument} //= $self->default_body_argument;

  $self->{namespace} ||= [qw(yatt perl)];
  my $nspat = qr!@{[join "|", $self->namespace]}!;
  $self->{_re_name} ||= $self->re_name;
  my $decl_prefix = $] >= 5.030 ? q{(?<=\A|\n)} : "";
  $self->{_re_decl} ||= qr{$decl_prefix<!(?<declname>$nspat(?::\w++)+)\b
			  |(?:<!--\#(?<comment>$nspat(?::\w++)*))\b}xs;
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
      , join "|", lexpand($self->{special_entities})
	if $self->{special_entities};
    sprintf q{&(?:%s)}, join "|", @entPat;
  };

  my $entCloseInAtt = $self->{allow_bare_entity_in_decl} ? "" : ";";

  $self->{_re_att}
    ||= qr{(?<ws>\s++)
	 | (?<comment>--+.*?--+)
	 | (?<macro>%(?:[\w\:\.]+(?:[\w:\.\-=\[\]\{\}\(,\)]+)?);)
	 |
	   (?:'(?<sq>[^\']*+)'
	   |"(?<dq>[^\"]*+)"
	   |(?<nest>\[) | (?<nestclo>\])
	   |$entOpen
	   |(?<bare>[^\s\'\"<>\[\]/=$entCloseInAtt]++)
	   )
           (?<equal>\s*=\s*+)?+
	}xs;
  $self->{_re_body} ||= qr{$entOpen
			|<(?:(?<clo>/?)(?<opt>:?)(?<elem>$nspat(?::\w++)+)
			  |\?(?<pi>$nspat(?::\w++)*))\b
		       }xs;
  # For entities.
  $self->{_re_entopn} = qr{$entOpen}xs;
  $self->{_re_eopen}  ||= qr{(?<open>  [\(\{\[])}xs;
  $self->{_re_eclose} ||= qr{(?<close> [\)\}\]])}xs;
  $self->{_re_evar}   ||= qr{: (?<var>\w+)}xs;
  $self->{_ch_etext}  ||= qr{(?: [^\ \t\n,;:()\[\]{}])}xs;
  $self->{_re_eparen} ||= qr{(\( (?<paren> (?: (?> [^()]+) | (?-2) )*) \) )}xs;
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
  binmode $fh, ":encoding($$self{encoding})" if $$self{encoding};
  $self->{path} = $fn;
  $self->{scheme} = 'file';
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
  $self->parse_body($tmpl) if $self->{all};
  wantarray ? ($tmpl, $self) : $tmpl;
}

sub parse_body {
  (my MY $self, my Template $tmpl) = @_;
  return if $tmpl->{_parse_ok};
  $self->{_template} = $tmpl;
  $self->parse_widget($_) for $tmpl->list_parts($self->Widget);
  $tmpl->{_parse_ok} = 1;
}

#
# parse_decllist_entities updates all decllists in given template.
# This method is for inspector and not used from normal code generation pass.
#
sub parse_decllist_entities {
  (my MY $self, my Template $tmpl) = @_;
  foreach my Part $part ($tmpl->list_parts) {
    # $self->{startln} = $self->{endln} = $part->{bodyln};
    # ($self->{startpos}, $self->{curpos}) = ($part->{startpos}) x 2;
    my $decllist = $part->{_decllist} or next;
    foreach my $node (@$decllist) {
      $node->[NODE_TYPE] == TYPE_ATT_TEXT
        or next;
      $self->{_endln} = $node->[NODE_LNO];
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
  ($self->{_startpos}, $self->{_curpos});
}

sub add_posinfo {
  (my MY $self, my ($len, $sync)) = @_;
  $self->{_curpos} += $len;
  $self->{_startpos} = $self->{_curpos} if $sync;
  $len;
}

sub update_posinfo {
  my MY $self = shift;
  my ($sync) = splice @_, 1;
  # $self->{_curpos} = $self->{total} - length $_[0];
  $self->{_startpos} = $self->{_curpos} if $sync;
}

sub ensure_default_part {
  (my MY $self, my Template $tmpl) = @_;
  my Part $part = $self->build(
    $self->primary_ns
    , args => $self->default_part_for($tmpl)
    , '', implicit => 1
    , startpos => $self->{_startpos}, bodypos => $self->{_startpos}
  );
  $self->add_part($tmpl, $part);
  $part;
}

sub parse_decl {
  (my MY $self, my Template $tmpl, my $str, my @config) = @_;
  # local %+; # ← XXX: This causes massive test failure, but why??
  break_parser();
  # 宣言 parse 中フラグ。declare_import の循環検出に使う。GH-256
  # (path キーの registry も持つのは、循環相手の Template object が
  #  cached_in の dict 代入前で、object 経由では検出できないケースがあるため)
  local $tmpl->{_decl_parsing} = 1;
  local $DECL_PARSING{$tmpl->{path} // Scalar::Util::refaddr($tmpl)} = 1;
  $self->{_template} = $tmpl;
  $self->configure(@config);
  $tmpl->{string} = $str;
  $tmpl->{utf8} = Encode::is_utf8($str);
  # 宣言/コメントの位置記録。再 parse で重複しないようここで初期化する。GH-258
  $tmpl->{_boundarylist} = [];
  $self->{_startln} = $self->{_endln} = 1;
  ($self->{_startpos}, $self->{_curpos}, my $total) = (0, 0, length $str);
  my Part $part;
  while ($str =~ s{^(.*?)($$self{_re_decl})}{}s) {
    if (not $part and (length $1 || $+{comment})) {
      $part = $self->ensure_default_part($tmpl);
    }
    $self->add_text($part, $1) if length $1;
    $self->{_curpos} = $total - length $str;
    if (my $comment_ns = $+{comment}) {
      unless ($str =~ s{^(.*?)-->(\r?\n)?}{}s) {
	die $self->synerror_at($self->{_startln}, q{Comment is not closed});
      }
      my $nlines = numLines($1) + ($2 ? 1 : 0);
      $self->{_curpos} += length $&;
      #
      # Yet another illegular.
      # TYPE_COMMENT:
      #  - NODE_BODY is $nlines
      #  - NODE_ATTLIST is payload.
      #
      push @{$part->{_toks}}, do {
        my $node = [];
        $node->[NODE_TYPE] = TYPE_COMMENT;
        @{$node}[NODE_BEGIN, NODE_END] = $self->posinfo($str);
        $node->[NODE_LNO] = $self->{_startln};
        $node->[NODE_PATH] = $comment_ns;
        $node->[NODE_BODY] = $nlines;
        $node->[NODE_ATTLIST] = $1;
        $node;
      };
      # 不変量: substr(string, startpos, endpos - startpos) はコメント全文。GH-258
      push @{$tmpl->{_boundarylist}}, +{
        kind => 'comment', declkind => $comment_ns
        , startpos => $self->{_startpos}, endpos => $self->{_curpos}
        , lineno => $self->{_startln}, nlines => $nlines
      };
      $self->{_startln} = $self->{_endln} += $nlines;
      next;
    }
    my $declkind = $+{declname};
    my ($ns, $kind) = split /:/, $declkind, 2;
    # 宣言境界の先頭 pos/行。この時点の _startpos は宣言先頭を指しており、
    # part の startpos (build 経由) と同じ値になる。GH-258
    my ($decl_startpos, $decl_startln) = ($self->{_startpos}, $self->{_startln});
    if (my $sub = $self->can("declare_$kind")) {
      # yatt:args, base, action, argmacro...

      # add_part を自分で呼びたい、又は add_part 自体を呼びたくないものは
      # declare_ で処理する.

      # 最初に、ここまでの宣言で作られた part を finalize
      # （ただし、宣言抜きで作られた default widget の場合は何もしない）
      if ($part and not $part->{implicit}) {
        $self->finalize_part($part);
      }

      # 戻り値が undef なら、同じ $part を用いつづける。
      my @args = $self->parse_attlist(\$str, 1);
      my $newpart = $sub->($self, $tmpl, $ns, @args);

      if ($newpart) {
        $newpart->{_decllist} = \@args;
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
      $part->{_decllist} = $saved_attlist;

      if ($mapping) {
        $self->add_route($part, $mapping);
      }
      $self->add_args($part, @args);
    }
    else {
      die $self->synerror_at($self->{_startln}, q{Unknown declarator (<!%s:%s >)}, $ns, $kind);
    }
    unless ($str =~ s{^>([\ \t]*\r?\n)?}{}s) {
      die $self->synerror_at($self->{_startln}, q{Declarator '<!%s:%s' is not closed with '>': %s}
		   , $ns, $kind
		   , _firstline_only($str));
    }
    # <!yatt:...> の直後には改行が必要、とする。
    unless ($1) {
      die $self->synerror_at($self->{_startln}, q{<!%s:%s> must end with newline!}, $ns, $kind);
    }
    $self->add_posinfo(length $&);
    $self->{_endln} += numLines($1);
    # 不変量: substr(string, startpos, endpos - startpos) は宣言全文
    # (閉じ '>' + 改行まで)。endpos は続く part の bodypos に等しい。GH-258
    push @{$tmpl->{_boundarylist}}, +{
      kind => 'decl', declkind => $declkind
      , startpos => $decl_startpos, endpos => $self->{_curpos}
      , lineno => $decl_startln
    };
    if ($part) {
      $part->{bodypos} = $self->{_curpos};
      $part->{bodyln} = $self->{_endln}; # part の本体開始行の初期値
    }
  } continue {
    $self->{_startpos} = $self->{_curpos};
    # Keep _startln in sync as well. add_text does this when body text
    # follows, but for back-to-back declarations nothing else would, and
    # every following part got the same startln. GH-275
    $self->{_startln} = $self->{_endln};
  }

  # Even if no declarations are found, there should be at least one default part.
  $part //= $self->ensure_default_part($tmpl);
  push @{$part->{_toks}}, nonmatched($str);
  # widget->{endln} は, (視覚上の最後の行)より一つ先の行を指す。(末尾の改行を数える分,多い)
  $part->{endln} = $self->{_endln} += numLines($str);

  $self->finalize_part($part);
  $self->finalize_template($tmpl);
}

sub cut_partname_and_route {
  (my MY $self, my ($declkind, $argList)) = @_;
  my $nameAtt = YATT::Lite::Constants::cut_first_att($argList) or do {
    my Template $tmpl = $self->{_template};
    die $self->synerror_at($self->{_startln}, q{No part name in %s\n%s}
                           , $declkind
                           , nonmatched($tmpl->{string}));
  };
  my ($partName, $mapping);
  if ($nameAtt->[NODE_TYPE] == TYPE_ATT_NAMEONLY) {
    $partName = $nameAtt->[NODE_PATH];
  } elsif ($nameAtt->[NODE_TYPE] == TYPE_ATT_TEXT) {
    if (ref $nameAtt->[NODE_BODY]) {
      my $t = $YATT::Lite::Constants::TYPE_[$nameAtt->[NODE_BODY][0][NODE_TYPE]];
      die $self->synerror_at($self->{_startln}
                             , q{%s got wrong token for route spec: %s}
                             , $declkind, $t);
    }
    if ($nameAtt->[NODE_BODY] eq '') {
      $partName = $nameAtt->[NODE_PATH] // '';
    } else {
      # $partName が foo=bar なら pattern として扱う
      $mapping = $self->parse_location
        ($nameAtt->[NODE_BODY], $nameAtt->[NODE_PATH]) or do {
          die $self->synerror_at($self->{_startln}
                                 , q{Invalid location in %s - "%s"}
                                 , $declkind, $nameAtt->[NODE_BODY])
        };
      $partName = $nameAtt->[NODE_PATH]
        // $self->location2name($nameAtt->[NODE_BODY]);
    }
  } else {
    die $self->synerror_at($self->{_startln}, q{Invalid part name in %s}
                           , $declkind);
  }

  ($partName, $mapping);
}

sub finalize_template {
  (my MY $self, my Template $tmpl) = @_;

  $self->fixup_template_foreach_part_posinfo($tmpl);

  $tmpl->{nlines} = $self->{_endln};

  if ($self->{match_argsroute_first}) {
    if ($self->{_rootroute}) {
      $self->subroutes->append($self->{_rootroute});
    }
  }
  if ($self->{_subroutes}) {
    $tmpl->{subroutes} = $self->{_subroutes};
  }
  $tmpl
}

sub fixup_template_foreach_part_posinfo {
  (my MY $self, my Template $tmpl) = @_;
  # $default が partlist に足されてなかったら、先頭に足す... 逆か。
  # args が、 $default を先頭から削る?
  # fixup parts.
  #
  # 本体区間は「bodypos 以降で最初の宣言境界」まで (無ければ EOF まで)。
  # _partlist だけを歩くと <!yatt:argmacro> のような partlist に入らない
  # 宣言を飲み込んでしまう (GH-258)。コメント境界は part 区間の内部要素
  # なので区間を切らない (raw 本体からの除去は part_body_source が行う)。
  my @decl_boundaries = grep {$_->{kind} eq 'decl'} @{$tmpl->{_boundarylist} // []};
  foreach my Part $part (@{$tmpl->{_partlist}}) {
    unless (defined $part->{bodypos}) {
      die $self->synerror_at($self->{_startln}, q{bodypos is undef});
    }
    my ($next) = grep {$_->{startpos} >= $part->{bodypos}} @decl_boundaries;
    $part->{bodylen} = ($next ? $next->{startpos} : length($tmpl->{string}))
      - $part->{bodypos};
    if ($part->{_toks} and @{$part->{_toks}}) {
      # widget 末尾の連続改行を、単一の改行トークンへ変換。(行番号は解析済みだから大丈夫)
      if ($part->{_toks}[-1] =~ s/(?:\r?\n)+\Z//) {
	push @{$part->{_toks}}, "\n"
	  unless $tmpl->{ignore_trailing_newlines};
      }
    }
    if (my $sub = $part->can('fixup')) {
      $sub->($part, $tmpl, $self);
    }
  }
}

sub parse_attlist {
  (my MY $self, my ($strref, @opt)) = @_;
  $self->parse_attlist_with_lvalue($self->{_curpos}, undef, $strref, @opt);
}

sub parse_attlist_with_lvalue {
  (my MY $self, my ($outer_start, $outer_lvalue, $strref, @opt)) = @_;

  # To examine node range in perldebugger, do like following:
  #
  #   x substr($self->{_template}{string}, 18, 26-18)
  #

  my ($for_decl) = @opt;
  my (@result, @lvalue); # Note: @lvalue contains position of lvalue expression.
  my $curln = $self->{_endln};
  while ($$strref =~ s{^$$self{_re_att}}{}xs) {
    my $start = $self->{_curpos};
    $self->{_curpos} += length $&;
    # startln は不変に保つ. これは add_part が startln を使うため
    $self->{_endln} += numLines($&);

    my AttMatch $m = \%+;
    next if $m->{ws} || $m->{comment};
    if ($m->{macro}) {
      push @result, $self->mkargmacro($start, $m->{macro});
      next;
    }

    my @common = ($start, $self->{_curpos}, $curln);
    my $mklval = sub {
      if (@lvalue) {
        my ($s, $p, $l, $n) = splice(@lvalue);
        # For endpos, curpos should be fetched after the parsing.
        ($s, $self->{_curpos}, $l, $n);
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
        $node->[NODE_END] = $self->{_curpos};
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
              # NODE_END from the lvalue stops right after '='. Cover the
              # value too, like the other attribute types do. GH-277
              $node->[NODE_END] = $self->{_curpos};
              $node->[NODE_BODY] = $m->{bare};
            } else {
              $node->[NODE_TYPE] = TYPE_ATT_NAMEONLY;
              @{$node}[NODE_BEGIN, NODE_END, NODE_LNO] = @common;
              $node->[NODE_PATH] = split_ns($m->{bare});
            }
          } elsif ($+{entity} or $+{special}) {
            # XXX: 間に space が入ってたら?
            if ($m->{lcmsg}) {
              die $self->synerror_at($self->{_startln}
                                     , q{l10n msg is not allowed here});
            }
            $node->[NODE_TYPE] = TYPE_ATT_TEXT;
            @{$node}[NODE_BEGIN, NODE_END, NODE_LNO, NODE_PATH] = $mklval->();

            # Below is a workaround for unclosed `<!yatt:args` with `&yatt:var;`
            # There would be a better way to handle this...
            $_ = $$strref;

            $node->[NODE_BODY] = [$self->mkentity(@common)];
            $node->[NODE_END] = $self->{_curpos};
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
        $node->[NODE_BODY_END] = $self->{_curpos};
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
        $self->{_startln}
        , q{assignment (=) after assignment (=) is not allowed}
      );
    }
  } continue {
    $curln = $self->{_endln};
    $self->_verify_token($self->{_curpos}, $$strref) if $self->{debug};
  }
  wantarray ? @result : \@result;
}

sub mkargmacro {
  (my MY $self, my ($start, $string)) = @_;
  local $_ = $string;

  my $node = [];
  $node->[NODE_TYPE] = TYPE_ATT_MACRO;
  @{$node}[NODE_BEGIN, NODE_END, NODE_LNO] = ($start, $self->{_curpos}, $self->{_startln});

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
    die $self->synerror_at($self->{_startln}
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
  $node->[NODE_END] = $self->{_curpos};
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
  $self->{_startln} = $self->{_endln} = $widget->{bodyln};
  # XXX: 戻り値でも良い気はする。とはいえ、デバッグは楽か。
  local $self->{_chunklist} = my $chunks = [@{$widget->{_toks} //= []}];
  local $_ = @$chunks && !ref $chunks->[0] ? shift @$chunks : '';
  $self->{_startpos} = $self->{_curpos} = $widget->{bodypos};
  $self->_parse_body($widget, $widget->{_tree} = []);
  push @{$widget->{_tree}}, nonmatched($_); # XXX: nest 時以外
  $widget;
}

sub _get_chunk {
  (my MY $self, my $sink) = @_;
  my $chunks = $self->{_chunklist};
  if (length $_) {
    push @$sink, $_ if $sink;
    $self->{_startln} = $self->{_endln} += numLines($_);
    $self->{_curpos} = $self->{_startpos} += length $_;
    $_ = '';
  }
  # comment の読み飛ばし
  while (@$chunks and ref $chunks->[0]) {
    my $next = shift @$chunks;
    push @$sink, $next if $sink;
    $self->{_startln} = $self->{_endln} += $next->[NODE_BODY];
    $self->{_curpos} = $self->{_startpos} = $next->[NODE_END];
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
    die $self->synerror_at($self->{_startln}, q{Token pos is undef!: now='%s'}, $_[0]);
  }
  my $tok = $self->{_template}->source_substr($pos, length $_[0]);
  unless (defined $tok) {
    die $self->synerror_at($self->{_startln}, q{Token substr is empty!: now='%s'}, $_[0]);
  }
  unless ($tok eq $_[0]) {
    die $self->synerror_at($self->{_startln}, q{Token mismatch!: substr='%s', now='%s'}
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
     , folder => $self->{_template}
     , startpos => $self->{_startpos}, @rest);
}

sub build_widget { shift->Widget->new(@_) }
sub build_page { shift->Page->new(@_) }
sub build_action { shift->Action->new(@_) }
sub build_data { shift->Data->new(@_) }

sub build_entity { shift->Entity->new(@_) }

sub build_argmacro { shift->ArgMacro->new(@_) }

sub build_import { shift->Import->new(@_) }

#========================================
# declare
sub declare_base {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;

  # Accept empty '<!yatt:base>' declaration as nop for parser testing aid.
  $self->{vfs}->declare_base($self, $tmpl, $ns, @args)
    if @args;

  undef;
}

# <!yatt:import [name...]="file" [name...]="file2" ...>   (GH-256)
#   name := srcName | local=srcName | srcName:kind | local=srcName:kind
#   kind := widget | page | action | entity | argmacro
#           (無注釈はソース内で一意な場合のみ自動判定)
#   kind の妥当性は vfs 側の _find_kind_part__$kind の有無で判定する
#   (find_kind_part_from dispatch。kind 追加時に LRXML の変更は不要)

sub declare_import {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;

  unless (@args) {
    die $self->synerror_at($self->{_startln}, q{No import arg});
  }

  foreach my $att (@args) {
    my ($specs, $fn) = $self->cut_import_spec($att);
    my Template $src = $self->{vfs}->import_resolve_source($self, $tmpl, $fn);
    foreach my $spec (@$specs) {
      $self->import_1($tmpl, $ns, $src, @$spec);
    }
  }

  undef;
}

# ブラケット群 [name...]="file" を ([[local, srcName, kind], ...], $fn) に分解する。
sub cut_import_spec {
  (my MY $self, my $att) = @_;

  my $names = $att->[NODE_PATH];
  unless ($att->[NODE_TYPE] == TYPE_ATT_TEXT
          and ref $names eq 'ARRAY'
          and not grep {not ref $_} @$names) {
    die $self->synerror_at($self->{_startln}
                           , q{import decl must use bracket form like [name...]="file"});
  }

  my $fn = $att->[NODE_BODY];

  my @specs;
  foreach my $node (@$names) {
    my ($local, $srcSpec);
    my $type = $node->[NODE_TYPE];
    if ($type == TYPE_ATT_NAMEONLY) {
      # srcName または srcName:kind (split_ns 済み)
      $srcSpec = $node->[NODE_PATH];
    } elsif ($type == TYPE_ATT_BARENAME or $type == TYPE_ATT_TEXT) {
      # local=srcName または local="srcName:kind"
      $local = $node->[NODE_PATH];
      $srcSpec = $node->[NODE_BODY];
    } else {
      die $self->synerror_at($self->{_startln}, q{Invalid import name spec});
    }

    if (ref $local) {
      die $self->synerror_at($self->{_startln}
                             , q{Invalid local name for import: %s}
                             , join(":", @$local));
    }

    my ($srcName, $kind) = do {
      if (ref $srcSpec eq 'ARRAY') {
        unless (@$srcSpec == 2) {
          die $self->synerror_at($self->{_startln}
                                 , q{Invalid import name spec: %s}
                                 , join(":", @$srcSpec));
        }
        @$srcSpec;
      } elsif (defined $srcSpec and $srcSpec =~ /^([^:]+):([^:]+)$/) {
        ($1, $2);
      } else {
        ($srcSpec, undef);
      }
    };

    unless (defined $srcName and $srcName ne '') {
      die $self->synerror_at($self->{_startln}, q{Invalid import name spec});
    }
    if (defined $kind and not $self->{vfs}->can("_find_kind_part__$kind")) {
      die $self->synerror_at($self->{_startln}
                             , q{Unknown import kind '%s' for '%s'}
                             , $kind, $srcName);
    }

    push @specs, [$local // $srcName, $srcName, $kind];
  }

  (\@specs, $fn);
}

sub import_1 {
  (my MY $self, my Template $tmpl, my $ns, my Template $src
   , my ($local, $srcName, $kind)) = @_;

  (my $ikind, my $found)
    = $self->{vfs}->import_find_source_part($self, $src, $srcName, $kind);

  if ($ikind eq 'argmacro') {
    if ($tmpl->{_argmacro_dict}{$local}) {
      die $self->synerror_at($self->{_startln}
                             , q{Duplicate argmacro %s in %s}
                             , $local, $tmpl->{path} // $tmpl->{name});
    }
    # weak ref でも ArgMacro 自身の _on_declare 自己循環が生存を保証する
    # (declare_argmacro と同じ)。
    Scalar::Util::weaken($tmpl->{_argmacro_dict}{$local} = $found);
  } else {
    my Import $import = $self->build($ns, import => import => $local);
    $import->{imported_kind} = $ikind;
    $import->{src_name} = $srcName;
    Scalar::Util::weaken($import->{src_folder} = $src);
    # 本体を持たない part なので、位置情報だけ整えておく
    # (fixup_template_foreach_part_posinfo が bodypos を要求する)
    $import->{bodypos} = $self->{_curpos};
    $import->{bodylen} = 0;
    $self->add_part($tmpl, $import);
  }
}

sub declare_args {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  my $kind = 'args';
  my $declkind = join(":", $ns, $kind);
  my Widget $newpart = $self->cut_implicit_default_part($tmpl, $declkind)
    || $self->build($ns, $kind => $self->default_part_for($tmpl), ''
                    , startln => $self->{_startln});

  if (not grep {/\S/} @{$newpart->{_toks}}) {
    $newpart->configure(
      # startpos => $self->{_curpos},
      startln => $self->{_startln},
    );
    $newpart->{_toks} = [];
  }

  $self->cut_root_route_and_install_url_params($newpart, \@args);

  # $newpart->{startpos} = $self->{_startpos};
  # $newpart->{bodypos} = $self->{_curpos} + 1;
  $self->add_part($tmpl, $newpart, 1); # partlist と Item に足し直す. no_conflict_check

  $self->add_args($newpart, @args);

  $newpart;
}

sub cut_implicit_default_part {
  (my MY $self, my Template $tmpl, my ($declkind)) = @_;
  (my Part $oldpart, my @other) = $self->list_default_parts($tmpl);
  unless (not $oldpart or $oldpart->{implicit}) {
    die $self->synerror_at($self->{_startln}
                           , q{<!%s> at line %d conflicts with <!%s>}
                           , $oldpart->syntax_keyword, $oldpart->{startln}
                           , $declkind);
  }
  if ($oldpart
      and $tmpl->{_partlist} and @{$tmpl->{_partlist}} == 1
      and $tmpl->{_partlist}[0] == $oldpart) {
    # 先頭だったら再利用。
    shift @{$tmpl->{_partlist}}; # == $oldpart
  } else {
    $oldpart->{suppressed} = 1 if $oldpart; # 途中なら、古いものを隠して、新たに作り直し。

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
    die $self->synerror_at($self->{_startln}
                           , q{%s got wrong token for route spec: %s}
                           , $part->syntax_keyword, $t);

  }
  my $mapping = $self->parse_location($patNode->[NODE_BODY], '', $part)
    or do {
      die $self->synerror_at($self->{_startln}
                             , q{Invalid route spec in %s - "%s"}
                             , $part->syntax_keyword, $patNode->[NODE_BODY]);
    };
  if ($self->{match_argsroute_first}) {
    $self->{_rootroute} = $mapping;
  } else {
    $self->{_subroutes}->append($mapping);
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
      die $self->synerror_at($self->{_startln}
                             , q{<!%s> conflicts with name-less default widget}
                             , "$declkind ''");
    }
  }

  my Part $newpart = $self->build($ns, $kind => $kind, $partName, startln => $self->{_startln});

  $self->add_part($tmpl, $newpart, 1); # partlist と Item に足し直す. no_conflict_check

  if ($mapping) {
    $self->add_route($newpart, $mapping);
  }

  $self->add_args($newpart, @args);

  $newpart;
}

sub list_default_parts {
  (my MY $self, my Template $tmpl) = @_;
  return unless $tmpl->{_partlist};
  grep {
    my Part $part = $_;
    $part->{name} eq '' and not $part->{suppressed};
  } @{$tmpl->{_partlist}};
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
  $tmpl->{constants} = \@args;
  undef;
}

# <!yatt:argmacro macroName=[...output_args...] ...args>
sub declare_argmacro {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;
  my $kind = 'argmacro';
  my $declkind = join(":", $ns, $kind);

  my $nameAtt = YATT::Lite::Constants::cut_first_att(\@args) or do {
    die $self->synerror_at($self->{_startln}, q{No part name in %s\n%s}
                           , $declkind
                           , nonmatched($tmpl->{string}));
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

  if ($tmpl->{_argmacro_dict}{$partName}) {
    die $self->synerror_at($self->{_startln}, q{Duplicate argmacro %s in %s}
                           , $partName
                           , $declkind);
  }

  my Part $newpart = $self->build(
    $ns, $kind => $kind, $partName, startln => $self->{_startln},
    output_args => $output_args,
  );

  Scalar::Util::weaken($tmpl->{_argmacro_dict}{$partName} = $newpart);

  $self->add_args($newpart, @args);

  $newpart;
}

sub finalize_part {
  (my MY $self, my Part $part) = @_;
  my $finalizer = $self->can("finalize__" . $part->{kind})
    or return;
  $finalizer->($self, $part)
}

sub finalize__argmacro {
  (my MY $self, my ArgMacro $argmacro) = @_;
  require YATT::Lite::CGen::ArgMacro;
  my $builder = YATT::Lite::CGen::ArgMacro->new(
    vfs => $self->{vfs}
  );

  $argmacro->{_on_declare} = $builder->with_template(
    $self->{_template},
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
  $self->{_subroutes} //= $self->SubRoutes->new;
}

sub SubRoutes {
  require YATT::Lite::WebMVC0::SubRoutes;
  'YATT::Lite::WebMVC0::SubRoutes'
}

#========================================
sub primary_ns {
  my MY $self = shift;
  unless ($self->{namespace}) {
    'yatt';
  } else {
    first($self->{namespace});
  }
}
sub namespace {
  my MY $self = shift;
  return unless defined $self->{namespace};
  ref $self->{namespace} && wantarray
    ? @{$self->{namespace}}
      : $self->{namespace};
}

#========================================
sub add_part {
  (my MY $self, my Template $tmpl, my Part $part, my $no_conflict_check) = @_;
  my $itemKey = $part->item_key;
  if (not $no_conflict_check and defined $tmpl->{_Item}{$itemKey}) {
    die $self->synerror_at($self->{_startln}, q{Conflicting part name! '%s'}, $part->{name});
  }
  if ($tmpl->{_partlist} and my Part $prev = $tmpl->{_partlist}[-1]) {
    $prev->{endln} = $self->{_endln};
  }
  $part->{startln} = $self->{_startln};
  $part->{bodyln} = $self->{_endln};
  push @{$tmpl->{_partlist}}, $tmpl->{_Item}{$itemKey} = $part;
}

sub add_route {
  (my MY $self, my Part $part, my $mapping) = @_;
  $mapping->configure(item => $part);
  $self->{_subroutes}->append($mapping);
  $self->add_url_params($part, lexpand($mapping->cget('params')));
}

sub add_text {
  (my MY $self, my Part $part, my $text) = @_;
  push @{$part->{_toks}}, $text;
  $self->add_posinfo(length($text), 1);
  $self->{_startln} = $self->{_endln} += numLines($text);
}

sub add_lineinfo {
  (my MY $self, my $sink) = @_;
  # push @$sink, [TYPE_LINEINFO, $self->{_endln}];
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
    # x:value のように : で区切った名前は、引数名としては不正 (GH-296)
    unless (defined $argName and not ref $argName) {
      # argmacro と勘違いして &yatt:argmacro; と書いた時に気づきやすいように
      if ($argSpec->[NODE_TYPE] == TYPE_ATT_TEXT
          and @{$argSpec->[NODE_BODY]} == 1
          and (my $entity = $argSpec->[NODE_BODY][0])->[NODE_TYPE]
          == TYPE_ENTITY) {
          die $self->synerror_at(
            $self->{_startln},
            'Use of entity(%s) is not allowed here. (Did you mean %%%s;?)',
            $self->{_template}->node_source($argSpec),
            $entity->[NODE_BODY][1],
          );
      } else {
          die $self->synerror_at(
            $self->{_startln}, 'Invalid argument spec: %s',
            $self->{_template}->node_source($argSpec),
          );
      }
    }

    if (my $var = $part->{_arg_dict}{$argName}) {
      if ($var->from_route) {
        # Override $type, $dflag, $default of this var.
        $self->set_var_type($var, $type); # type is always overridden.
        $self->set_dflag_default_to($var, $dflag, $default);
      } else {
        die $self->synerror_at($self->{_startln}
                               , 'Argument %s redefined in %s %s'
                               , $argName, $part->{kind}, $part->{name});
      }
    } else {
      my $var = $self->mkvar_at($self->{_startln}, @argSpec);
      $self->set_dflag_default_to($var, $dflag, $default);

      my $type = $var->type->[0];
      if ($node_type == TYPE_ATT_NESTED) {
        # XXX: [delegate:type ...], [code  ...] の ... が来る
        # 仮想的な widget にする？ のが一番楽そうではあるか。そうすれば add_args 出来る。
        # $self->add_arg_of_delegate/code/...へ。
        my $sub = $self->can("add_arg_of_type_$type") or do {
          die $self->synerror_at($self->{_startln}, "Unknown arg type in arg '%s': %s", $argName, $type)
        };
        # 先頭は型名 (code, delegate:foo など) なので、引数としては渡さない (GH-296)
        my (undef, @attlist) = @{$argSpec->[NODE_BODY]};
        $sub->($self, $part, $var, \@attlist);
      } else {
        if (my $sub = $self->can("add_arg_of_type_$type")) {
          $sub->($self, $part, $var, []);
        } else {
          push @{$part->{_arg_order}}, $argName;
          $part->{_arg_dict}{$argName} = $var;
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

  return if $self->add_part_option($part, $node);

  my ArgMacro $argmacro = $self->find_argmacro($node);

  require YATT::Lite::CGen::ArgMacro;
  my $builder = YATT::Lite::CGen::ArgMacro->new(
    vfs => $self->{vfs}
  );
  $builder->with_template(
    $self->{_template},
    $argmacro->{_on_declare} => ($self, $part, $node)
  );

  return;
}

# %yatt:NAME; / %yatt:NAME(VALUE); → $part->configure(yatt_NAME => VALUE // 1)
# Part に yatt_NAME field が無ければ偽を返し、argmacro の探索に任せる。
sub add_part_option {
  (my MY $self, my Part $part, my $node) = @_;

  my $ns = $node->[NODE_PATH];
  return unless defined $ns and $ns eq 'yatt';

  my ($head, @rest) = @{$node}[NODE_BODY .. $#$node];
  return if @rest; # %yatt:a:b; は find_argmacro でエラーにする

  my ($call, $name, @args) = @$head;
  return unless $call eq 'prop' or $call eq 'invoke';

  my $optName = "yatt_$name";
  return unless exists YATT::Lite::Util::fields_hash($part)->{$optName};

  if (@args >= 2) {
    die $self->synerror_at($node->[NODE_LNO]
                           , "Too many values for part option '%s'"
                           , $name);
  }

  my $value = do {
    if (not @args) {
      1;
    } elsif ($args[0][0] eq 'text') {
      $args[0][1];
    } else {
      die $self->synerror_at($node->[NODE_LNO]
                             , "Invalid value for part option '%s'"
                             , $name);
    }
  };

  $part->configure($optName => $value);

  1;
}

sub find_argmacro {
  (my MY $self, my $node) = @_;

  my $ns = $node->[NODE_PATH];
  my ($head, @rest) = @{$node}[NODE_BODY .. $#$node];
  my ($call, $macroName, $renameSpec) = @$head;
  if (@rest) {
    die $self->synerror_at($node->[NODE_LNO]
                           , "Invalid argmacro reference '%%%s;'"
                           , join(":", grep {defined} $ns, $macroName
                                  , map {$_->[1]} @rest));
  }

  # %ns:foo; は Site 設定 argmacro の ns に登録されたものだけを探す。
  # (ページ内定義は %foo; でしか参照できない)
  if (defined $ns) {
    unless (grep {$_ eq $ns} $self->namespace) {
      die $self->synerror_at($node->[NODE_LNO]
                             , "Unknown namespace '%s' in argmacro reference"
                             , $ns);
    }
    my $argmacro = $self->{vfs}
      && $self->{vfs}->find_argmacro_module($self, $ns, $macroName);
    return $argmacro if $argmacro;

    die $self->synerror_at($node->[NODE_LNO]
                           , "Unknown argmacro '%s:%s'%s"
                           , $ns, $macroName
                           , ($self->find_local_argmacro($macroName)
                              ? " (page-local argmacro '$macroName'"
                              ." can only be referenced as %$macroName;)"
                              : ""));
  }

  my $argmacro = $self->find_local_argmacro($macroName);
  return $argmacro if $argmacro;

  # Site 設定 argmacro の primary ns (名前空間無しの登録を含む)
  if ($self->{vfs}
      and $argmacro = $self->{vfs}->find_argmacro_module($self, undef, $macroName)) {
    return $argmacro;
  }

  die $self->synerror_at($node->[NODE_LNO]
                         , "Unknown argmacro '%s'"
                         , $macroName)
}

# ページ内(import 分を含む)と base 1 段の argmacro
sub find_local_argmacro {
  (my MY $self, my $macroName) = @_;

  my Template $tmpl = $self->{_template};
  my ArgMacro $argmacro = $tmpl->{_argmacro_dict}{$macroName};
  return $argmacro if $argmacro;

  # XXX: ディレクトリからの追加を許すか否か、その場合の意味論…
  foreach my Part $part ($tmpl->list_base) {
    next unless $part->isa(Template);
    my Template $base = $part;
    if ($argmacro = $base->{_argmacro_dict}{$macroName}) {
      return $argmacro
    }
  }
  return;
}

sub add_url_params {
  (my MY $self, my Part $part, my @params) = @_;
  foreach my $param (@params) {
    my ($argName, $type_or_pat) = @$param;
    my $type = 'value'; # XXX: type_or_pat
    my $var = $self->mkvar_at($self->{_startln}, $type, $argName
			      , nextArgNo($part));
    $var->from_route(1);
    push @{$part->{_arg_order}}, $argName;
    $part->{_arg_dict}{$argName} = $var;
  }
}

# code 型は仮想的な Widget を作る。
sub add_arg_of_type_code {
  (my MY $self, my Part $part, my ($var, $attlist)) = @_;
  $var->widget(my Widget $virtual = $self->Widget->new(name => $var->varname));
  $self->add_args($virtual, @$attlist);
  my $argName = $var->varname;
  push @{$part->{_arg_order}}, $argName;
  $part->{_arg_dict}{$argName} = $var;
}

# expr 型の引数宣言 ([expr x y]) も、code と同じく仮想的な Widget に持たせる (GH-294)
sub add_arg_of_type_expr {
  shift->add_arg_of_type_code(@_);
}

sub add_arg_of_type_delegate {
  (my MY $self, my Widget $widget, my ($var, $attlist)) = @_;
  # XXX: 引数でない変数も足さないと...
  my $name = $var->varname;
  # XXX: 既に有ったらエラーにしないと。
  $widget->{_var_dict}{$name} = $var;
  my ($type, @subtype) = @{$var->type};
  my @wpath = @subtype ? @subtype : $name;
  my Widget $delegate = $self->{vfs}->find_part_from
    ($widget->{folder}, @wpath) or do {
      $self->synerror_at($self->{_startln}, "Can't find delegate widget for argument %s=[%s]", $name, join(":", $type, @subtype));
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
	if (not $delegate->{_arg_dict}{$attName}) {
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

  foreach my $argName (@{$delegate->{_arg_order}}) {
    # 既に宣言されている名前は、足さない。
    next if $widget->{_arg_dict}{$argName};

    # Ignore [delegate -excluded_var]
    next if $excludeDict->{$argName};

    $delegate_vars{$argName} = my $orig = $delegate->{_arg_dict}{$argName};

    my $actual = do {
      if (my $att = $attDict->{$argName}) {
	my @new = $self->parse_arg_spec_for_part($widget, $att);
	$new[0] ||= $orig->[0];
	$self->mkvar_at($self->{_startln}, @new);
      } else {
	# clone して argno と lineno を変える。
	$self->mkvar_at($widget->{startln}, @$orig)
	  ->argno(nextArgNo($widget))->lineno($widget->{startln});
      }
    };
    $widget->{_arg_dict}{$argName} = $actual;
    # XXX: lineno を widget の startln にするのは手抜き。本来は直前の arg のものを使うべき。
    push @{$widget->{_arg_order}}, $argName;
  }
}
sub nextArgNo {
  (my Part $part) = @_;
  $part->{_arg_order} ? scalar @{$part->{_arg_order}} : 0;
}

#========================================
sub synerror_at {
  (my MY $self, my $ln) = splice @_, 0, 2;
  my %opts = ($self->_tmpl_file_line($ln), depth => 2);
  $self->_error(\%opts, @_);
}

sub _error {
  (my MY $self, my ($opts, $fmt)) = splice @_, 0, 3;
  if (my $vfs = $self->{vfs}) {
    $vfs->error($opts, $fmt, @_);
  } else {
    sprintf($fmt, @_);
  }
}

sub _tmpl_file_line {
  (my MY $self, my $ln) = @_;
  ($$self{path} ? (tmpl_file => $$self{path}) : ()
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

sub _firstline_only {
  my ($str) = @_;
  $str =~ s/\n.*\z/.../s;
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
    die $self->synerror_at($self->{_startln}, "Unknown method: %s", $meth);
  }
  my $code = *{$sym}{CODE}
    or croak "Can't find definition of: $meth";
  goto &$code;
}

#
use YATT::Lite::Breakpoint qw(break_load_parser break_parser);
break_load_parser();

1;
