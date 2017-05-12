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
	      subroutes
	      rootroute

	      _original_entpath
	    /;

use YATT::Lite::Core qw(Part Widget Page Action Data Template);
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
	 | (?:(?<attname>[\w:]+)\s*=\s*+)?+
	   (?:'(?<sq>[^']*+)'
	   |"(?<dq>[^\"]*+)"
	   |(?<nest>\[) | (?<nestclo>\])
	   |$entOpen
	   |(?<bare>[^\s'\"<>\[\]/=]++)
	   )
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

sub parse_decl {
  (my MY $self, my Template $tmpl, my $str, my @config) = @_;
  break_parser();
  $self->{template} = $tmpl;
  $tmpl->reset if $tmpl->{product};
  $self->configure(@config);
  $tmpl->{cf_string} = $str;
  $tmpl->{cf_utf8} = Encode::is_utf8($str);
  $self->{startln} = $self->{endln} = 1;
  $self->add_part($tmpl, my Part $part = $self->build
		  ($self->primary_ns, $self->default_part_for($tmpl)
		   , '', implicit => 1
		   , startpos => 0, bodypos => 0));
  ($self->{startpos}, $self->{curpos}, my $total) = (0, 0, length $str);
  while ($str =~ s{^(.*?)($$self{re_decl})}{}s) {
    $self->add_text($part, $1) if length $1;
    $self->{curpos} = $total - length $str;
    if (my $comment_ns = $+{comment}) {
      unless ($str =~ s{^(.*?)-->(\r?\n)?}{}s) {
	die $self->synerror_at($self->{startln}, q{Comment is not closed});
      }
      my $nlines = numLines($1) + ($2 ? 1 : 0);
      $self->{curpos} += length $&;
      push @{$part->{toks}}, [TYPE_COMMENT, $self->posinfo($str)
			      , $self->{startln}
			      , $comment_ns, $nlines, $1];
      $self->{startln} = $self->{endln} += $nlines;
      next;
    }
    my ($ns, $kind) = split /:/, $+{declname}, 2;
    # XXX: build と declare の順序が逆ではないか? 気にしなくていい?
    my $is_new;
    if ($self->can("build_$kind")) {
      # yatt:widget, action
      my (@args) = $self->parse_attlist($str, 1); # To delay entity parsing.
      my $nameAtt = YATT::Lite::Constants::cut_first_att(\@args) or do {
	die $self->synerror_at($self->{startln}, q{No part name in %s:%s\n%s}
			       , $ns, $kind
			       , nonmatched($str));
      };
      my ($partName, $mapping, @opts);
      if ($nameAtt->[NODE_TYPE] == TYPE_ATT_NAMEONLY) {
	$partName = $nameAtt->[NODE_PATH];
      } elsif ($nameAtt->[NODE_TYPE] == TYPE_ATT_TEXT) {
	# $partName が foo=bar なら pattern として扱う
	$mapping = $self->parse_location
	  ($nameAtt->[NODE_BODY], $nameAtt->[NODE_PATH]) or do {
	    die $self->synerror_at($self->{startln}
				   , q{Invalid location in %s:%s - "%s"}
				   , $ns, $kind, $nameAtt->[NODE_BODY])
	  };
	$partName = $nameAtt->[NODE_PATH]
	  // $self->location2name($nameAtt->[NODE_BODY]);
      } else {
	die $self->synerror_at($self->{startln}, q{Invalid part name in %s:%s}
			       , $ns, $kind);
      }
      $self->add_part($tmpl, $part = $self->build($ns, $kind, $partName));
      if ($mapping) {
	$mapping->configure(item => $part);
	$self->{subroutes}->append($mapping);
	$self->add_url_params($part, lexpand($mapping->cget('params')));
      }
      $self->add_args($part, @args);
      $is_new++;
    } elsif (my $sub = $self->can("declare_$kind")) {
      # yatt:base, yatt:args vs perl:base, perl:args...
      # 戻り値が undef なら、同じ $part を用いつづける。
      $part = $sub->($self, $tmpl, $ns, $self->parse_attlist($str, 1))
	// $part;
    } else {
      die $self->synerror_at($self->{startln}, q{Unknown declarator (<!%s:%s >)}, $ns, $kind);
    }
    unless ($str =~ s{^>([\ \t]*\r?\n)?}{}s) {
      # XXX: たくさん出しすぎ
      die $self->synerror_at($self->{startln}, q{Invalid character in decl %s:%s : %s}
		   , $ns, $kind
		   , $str);
    }
    # <!yatt:...> の直後には改行が必要、とする。
    unless ($1) {
      die $self->synerror_at($self->{startln}, q{<!%s:%s> must end with newline!}, $ns, $kind);
    }
    $self->add_posinfo(length $&);
    $self->{endln} += numLines($1);
    $part->{cf_bodypos} = $self->{curpos};
    $part->{cf_bodyln} = $self->{endln}; # part の本体開始行の初期値
  } continue {
    $self->{startpos} = $self->{curpos};
  }
  push @{$part->{toks}}, nonmatched($str);
  # widget->{cf_endln} は, (視覚上の最後の行)より一つ先の行を指す。(末尾の改行を数える分,多い)
  $part->{cf_endln} = $self->{endln} += numLines($str);
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

  $self->finalize_template($tmpl);
}

sub finalize_template {
  (my MY $self, my Template $tmpl) = @_;
  if ($self->{rootroute}) {
    $self->subroutes->append($self->{rootroute});
  }
  if ($self->{subroutes}) {
    $tmpl->{cf_subroutes} = $self->{subroutes};
  }
  $tmpl
}

sub parse_attlist {
  my MY $self = shift;
  my ($for_decl) = my @opt = splice @_, 1;
  my (@result);
  my $curln = $self->{endln};
  while ($_[0] =~ s{^$$self{re_att}}{}xs) {
    my $start = $self->{curpos};
    $self->{curpos} += length $&;
    # startln は不変に保つ. これは add_part が startln を使うため
    $self->{endln} += numLines($&);
    next if $+{ws} || $+{comment};
    last if $+{nestclo};
    next if $+{macro};		#XXX: 今はまだ argmacro を無視！
    push @result, do {
      my @common = ($start, $self->{curpos}, $curln);
      if (not $+{attname} and $+{bare} and is_ident($+{bare})) {
	[TYPE_ATT_NAMEONLY, @common, split_ns($+{bare})];
      } elsif ($+{nest}) {
	[TYPE_ATT_NESTED, @common, $+{attname}
	 , $self->parse_attlist($_[0], @opt)];
      } elsif ($+{entity} or $+{special}) {
	# XXX: 間に space が入ってたら?
	if ($+{lcmsg}) {
	  die $self->synerror_at($self->{startln}
				 , q{l10n msg is not allowed here});
	}
	[TYPE_ATT_TEXT, @common, $+{attname}, [$self->mkentity(@common)]];
      } else {
	# XXX: stringify したくなるかもだから、 sq/dq の区別も保存するべき?
	my ($quote, $value) = oneof(\%+, qw(bare sq dq));
	[!$quote && is_ident($value) ? TYPE_ATT_BARENAME : TYPE_ATT_TEXT
	 , @common, split_ns($+{attname})
	 , $for_decl ? $value : $self->_parse_text_entities($value)];
      }
    };
  } continue {
    $curln = $self->{endln};
    $self->_verify_token($self->{curpos}, $_[0]) if $self->{cf_debug};
  }
  wantarray ? @result : \@result;
}

sub mkentity {
  (my MY $self) = shift;
  # assert @_ == 3;
  [TYPE_ENTITY, @_, do {
    if (my $ns = $+{entity}) {
      ($ns, $self->_parse_entpath);
    } elsif (my $special = $+{special}) {
      (undef, [call => $special
	       , $self->_parse_entpath(_parse_entgroup => ')')]);
    } else {
      die "mkentity called without entity or special";
    }
  }];
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
  (my MY $self, my ($ns, $kind, $partName)) = splice @_, 0, 4;
  $self->can("build_$kind")->
    ($self, name => $partName, kind => $kind
     , startpos => $self->{startpos}, @_);
}
# 今度はこっちが今一ね。
sub build_widget { shift->Widget->new(@_) }
sub build_page { shift->Page->new(@_) }
sub build_action {
  (my MY $self, my (%opts)) = @_;
  $opts{name} = "do_$opts{name}";
  $self->Action->new(%opts);
}
sub build_data { shift->Data->new(@_) }

#========================================
# declare
sub declare_base {
  (my MY $self, my Template $tmpl, my ($ns, @args)) = @_;

  $self->{cf_vfs}->declare_base($self, $tmpl, $ns, @args);

  undef;
}

sub declare_args {
  (my MY $self, my Template $tmpl, my $ns) = splice @_, 0, 3;
  my Part $newpart = do {
    # 宣言抜きで作られていた part を一旦一覧から外す。
    my Part $oldpart = delete $tmpl->{Item}{''};
    unless ($oldpart->{cf_implicit}) {
      die $self->synerror_at($self->{startln}, q{Duplicate !%s:args declaration}, $ns);
    }
    if (@{$tmpl->{partlist}} == 1) {
      # 先頭だったら再利用。
      shift @{$tmpl->{partlist}}; # == $oldpart
    } else {
      $oldpart->{cf_suppressed} = 1; # 途中なら、古いものを隠して、新たに作り直し。
      $self->build($ns, $self->default_part_for($tmpl), ''
		   , startln => $self->{startln});
    }
  };
  $newpart->{cf_startpos} = $self->{startpos};
  $newpart->{cf_bodypos} = $self->{curpos} + 1;
  $self->add_part($tmpl, $newpart); # partlist と Item に足し直す

  if (@_ and $_[0] and $_[0]->[NODE_TYPE] == TYPE_ATT_TEXT
      and not defined $_[0]->[NODE_PATH]) {
    my $patNode = shift;
    my $mapping = $self->parse_location($patNode->[NODE_BODY], '', $newpart)
      or do {
	die $self->synerror_at($self->{startln}
			       , q{Invalid location in %s:%s - "%s"}
			       , $ns, 'args', $patNode->[NODE_BODY])
      };
    $self->{rootroute} = $mapping;
    $self->add_url_params($newpart, lexpand($mapping->cget('params')));
  }

  $self->add_args($newpart, @_);
  $newpart;
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
  (my MY $self, my Template $tmpl, my Part $part) = @_;
  if (defined $tmpl->{Item}{$part->{cf_name}}) {
    die $self->synerror_at($self->{startln}, q{Conflicting part name! '%s'}, $part->{cf_name});
  }
  Scalar::Util::weaken($part->{cf_folder} = $tmpl);
  # die "Can't weaken!" unless Scalar::Util::isweak($part->{cf_folder});
  if ($tmpl->{partlist} and my Part $prev = $tmpl->{partlist}[-1]) {
    $prev->{cf_endln} = $self->{endln};
  }
  $part->{cf_startln} = $self->{startln};
  $part->{cf_bodyln} = $self->{endln};
  push @{$tmpl->{partlist}}, $tmpl->{Item}{$part->{cf_name}} = $part;
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

sub add_args {
  (my MY $self, my Part $part) = splice @_, 0, 2;
  foreach my $argSpec (@_) {
    # XXX: text もあるし、 %yatt:argmacro; もある。
    my ($node_type, $lno, $argName, $desc, @rest)
      = @{$argSpec}[NODE_TYPE, NODE_LNO, NODE_PATH, NODE_BODY
		    , NODE_BODY+1 .. $#$argSpec];
    unless (defined $argName) {
      die $self->synerror_at($self->{startln}, 'Invalid argument spec');
    }
    if (exists $part->{arg_dict}{$argName}) {
      die $self->synerror_at($self->{startln}, 'Argument %s redefined in %s %s'
		   , $argName, $part->{cf_kind}, $part->{cf_name});
    }
    my ($type, $dflag, $default);
    if ($node_type == TYPE_ATT_NESTED) {
      $type = $desc->[NODE_PATH] || $desc->[NODE_BODY];
      # primary of [primary key=val key=val] # delegate:foo の時は BODY に入る？
    } else {
      ($type, $dflag, $default) = split m{([|/?!])}, $desc || '', 2;
    };
    my $var = $self->mkvar_at($self->{startln}
			      , $type, $argName, nextArgNo($part)
			      , $lno, $node_type, $dflag
			      , defined $default
			      ? $self->_parse_text_entities($default) : undef);

    if ($node_type == TYPE_ATT_NESTED) {
      # XXX: [delegate:type ...], [code  ...] の ... が来る
      # 仮想的な widget にする？ のが一番楽そうではあるか。そうすれば add_args 出来る。
      # $self->add_arg_of_delegate/code/...へ。
      my $t = $var->type->[0];
      my $sub = $self->can("add_arg_of_type_$t")
	or die $self->synerror_at($self->{startln}, "Unknown arg type in arg '%s': %s", $argName, $t);
      $sub->($self, $part, $var, \@rest);
    } else {
      push @{$part->{arg_order}}, $argName;
      $part->{arg_dict}{$argName} = $var;
    }
  }
  $self;
}

sub add_url_params {
  (my MY $self, my Part $part, my @params) = @_;
  foreach my $param (@params) {
    my ($argName, $type_or_pat) = @$param;
    my $type = 'value'; # XXX: type_or_pat
    my $var = $self->mkvar_at($self->{startln}, $type, $argName
			      , nextArgNo($part));
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
  my Widget $delegate = $self->{cf_vfs}->find_part_from
    ($widget->{cf_folder}, @subtype ? @subtype : $name);
  $var->weakened_set_widget($delegate);
  unless (Scalar::Util::isweak($var->[YATT::Lite::VarTypes::t_delegate::VSLOT_WIDGET])) {
    die "Can't weaken!";
  }
  $var->delegate_vars(\ my %delegate_vars);
  foreach my $argName (@{$delegate->{arg_order}}) {
    # 既に宣言されている名前は、足さない。
    next if $widget->{arg_dict}{$argName};
    $delegate_vars{$argName} = my $orig = $delegate->{arg_dict}{$argName};
    # clone して argno と lineno を変える。
    $widget->{arg_dict}{$argName} = my $clone
      = $self->mkvar_at($widget->{cf_startln}, @$orig)
	->argno(nextArgNo($widget))->lineno($widget->{cf_startln});
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
  given ($meth) {
    when (/ent/)  { require YATT::Lite::LRXML::ParseEntpath }
    when (/body/) { require YATT::Lite::LRXML::ParseBody }
    default {
      my MY $self = $_[0];
      die $self->synerror_at($self->{startln}, "Unknown method: %s", $meth);
    }
  }
  my $code = *{$sym}{CODE}
    or croak "Can't find definition of: $meth";
  goto &$code;
}

#
use YATT::Lite::Breakpoint qw(break_load_parser break_parser);
break_load_parser();

1;
