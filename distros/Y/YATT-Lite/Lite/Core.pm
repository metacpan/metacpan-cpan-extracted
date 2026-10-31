package YATT::Lite::Core; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};

use parent qw(YATT::Lite::VFS);
use YATT::Lite::MFields qw/namespace debug_cgen no_lineinfo check_lineno
			   index_name
	      tmpl_encoding
	      debug_parser
	      parse_while_loading only_parse
	      die_in_error error_handler
	      special_entities
	      lcmsg_sink
              match_argsroute_first
              body_argument
              body_argument_type
              allow_bare_entity_in_decl

              stash_unknown_params_to
	      prefer_call_for_entity
	      no_conditional_call
              pagevars
              argmacro
              _argmacro_registry
              _argmacro_module_cache

	      _n_compiles
	    /;
use YATT::Lite::Util;
use YATT::Lite::Constants;
use YATT::Lite::Entities;

# XXX: YATT::Lite に？
use YATT::Lite::Breakpoint ();

#========================================
# 以下、 package YATT::Lite のための、内部クラス
#========================================
{
  use YATT::Lite::VFS qw(Folder Item);
  use YATT::Lite::Types
    ([Part => -base => MY->Item
      , -fields => [qw(_toks _arg_dict _arg_order
                       _argmacro_instance_dict
                       _argmacro_instance_list
                       _argmacro_trigger_dict
                       _argmacro_output_dict
                       _decllist
		       namespace kind folder data
                       decl
		       implicit suppressed
		       startln bodyln endln
		       startpos bodypos bodylen
		       subpattern
                       yatt_no_last_newline
		     )]
      , -constants => [[public => 0]]
      , [Widget => -fields => [qw(_tree _var_dict _has_required_arg)]
	 , [Page => (), -constants => [[public => 1]]]]
      , [Action => (), -constants => [[public => 1],
                                      [item_category => 'do'],
                                    ]]
      , [Data => ()]
      , [Entity => ()
         , -constants => [[item_category => 'entity']]
       ]
      , [ArgMacro => ()
         , -fields => [qw(
           output_args
           _on_declare
           _on_expand
           to_name
           from_name
           rename_map
           resolve_map
           refer_names
         )]
       ]
      # <!yatt:import> が作る alias Part。実体は持たず、lookup 時に
      # ソース側 Part へ解決される (resolve_alias)。GH-256
      , [Import => ()
         , -fields => [qw(
           imported_kind
           src_name
           src_folder
         )]
       ]
    ]

     , [Template => -base => MY->File
	, -alias => 'vfs_file'
	, -constants => [[can_generate_code => 1]]
	, -fields => [qw(_product _parse_ok
                         mtime utf8 age
			 usage constants
			 ignore_trailing_newlines
			 subroutes
                         _decl_parsing
		      )]]

     , [ParsingState => -fields => [qw(_startln _endln
				       _startpos _curpos
				       path
                                    )]]

     , [AbstParser => -fields => [qw(body_argument
                                     body_argument_type
                                  )]]
    );

  sub YATT::Lite::Core::Part::public_name {
    (my Part $part) = @_;
    $part->{name};
  }
  sub YATT::Lite::Core::Part::decl_kind {
    (my Part $part) = @_;
    join(":", $part->{namespace}, $part->{decl});
  }
  sub YATT::Lite::Core::Part::syntax_keyword {
    (my Part $part) = @_;
    join(" ", $part->decl_kind, $part->syntax_name);
  }
  *YATT::Lite::Core::Part::syntax_name = *YATT::Lite::Core::Part::public_name;
  *YATT::Lite::Core::Part::syntax_name = *YATT::Lite::Core::Part::public_name;
  sub YATT::Lite::Core::Widget::syntax_name {
    (my Widget $widget) = @_;
    $widget->{decl} eq 'args' ? () : $widget->{name};
  }
  sub YATT::Lite::Core::Action::syntax_name {
    (my Action $action) = @_;
    $action->{name} eq '' ? q{''} : $action->{name};
  }

  sub YATT::Lite::Core::Widget::callsite_name {
    (my Widget $widget) = @_;
    if ($widget->{decl} eq 'args') {
      my Template $tmpl = $widget->{folder};
      join(":", $widget->{namespace}, $tmpl->{name});
    } else {
      join(":", $widget->{namespace}, $widget->{name});
    }
  }

  # item_key / method_name の符号化 (do\0 / entity\0, render_ / do_ / entity_)
  # は各 part class の class メソッド *_for($name) に集約する。
  # instance メソッドはそこへ委譲するだけ。GH-256
  sub YATT::Lite::Core::Part::method_name {...}
  sub YATT::Lite::Core::Widget::method_name_for {"render_$_[1]"}
  sub YATT::Lite::Core::Widget::method_name {
    (my Widget $widget) = @_;
    $widget->method_name_for($widget->{name});
  }
  sub YATT::Lite::Core::Action::method_name_for {"do_$_[1]"}
  sub YATT::Lite::Core::Action::method_name {
    (my Action $action) = @_;
    $action->method_name_for($action->{name});
  }
  sub YATT::Lite::Core::Action::item_key_for {"do\0$_[1]"}
  sub YATT::Lite::Core::Action::item_key {
    (my Action $action) = @_;
    $action->item_key_for($action->{name});
  }

  sub YATT::Lite::Core::Entity::method_name_for {"entity_$_[1]"}
  sub YATT::Lite::Core::Entity::method_name {
    (my Entity $entity) = @_;
    $entity->method_name_for($entity->{name});
  }
  sub YATT::Lite::Core::Entity::item_key_for {"entity\0$_[1]"}
  sub YATT::Lite::Core::Entity::item_key {
    (my Entity $entity) = @_;
    $entity->item_key_for($entity->{name});
  }

  #========================================
  # <!yatt:import> の alias Part (GH-256)
  #========================================

  # kind 名 → part class の登録簿。_Item 系の名前空間を持つ kind のみ。
  # (argmacro は _argmacro_dict 系なので含めない)
  our %PART_KIND_CLASS
    = (widget => Widget, page => Page, action => Action, entity => Entity);

  sub YATT::Lite::Core::Import::part_class_of_imported_kind {
    (my Import $import) = @_;
    $PART_KIND_CLASS{$import->{imported_kind} // ''} // YATT::Lite::Core->Item;
  }
  sub YATT::Lite::Core::Import::method_name {
    (my Import $import) = @_;
    $import->part_class_of_imported_kind->method_name_for($import->{name});
  }
  sub YATT::Lite::Core::Import::item_key {
    (my Import $import) = @_;
    $import->part_class_of_imported_kind->item_key_for($import->{name});
  }
  sub YATT::Lite::Core::Import::src_item_key {
    (my Import $import) = @_;
    $import->part_class_of_imported_kind->item_key_for($import->{src_name});
  }
  sub YATT::Lite::Core::Import::public {
    (my Import $import) = @_;
    my Part $part = eval { $import->resolve_alias };
    $part ? $part->public : 0;
  }
  # alias をソース側 Part へ解決する。$vfs が渡されたときは
  # ソース template の refresh も行う (常に最新のメタ情報を返すため)。
  sub YATT::Lite::Core::Import::resolve_alias {
    (my Import $import, my $vfs) = @_;
    my Template $src = $import->{src_folder}
      or croak "import source template is gone (for part '$import->{name}')";
    if ($vfs) {
      $src->refresh($vfs)
        unless $vfs->{mark}{Scalar::Util::refaddr($src)}++;
    }
    my $key = $import->src_item_key;
    my $item = $src->{_Item}{$key}
      // ($vfs ? $vfs->find_part_from($src, $key) : undef)
      or croak "No such part '$import->{src_name}' in "
        . ($src->{path} // $src->{name})
        . " (imported as '$import->{name}')";
    # import の import (再輸出) も解決する。循環は宣言時に禁止済み。
    $item->resolve_alias($vfs);
  }

  sub YATT::Lite::Core::Template::list_import_sources {
    (my Template $tmpl) = @_;
    my (%seen, @result);
    foreach my Part $part (@{$tmpl->{_partlist} || []}) {
      next unless UNIVERSAL::isa($part, Import);
      my Import $import = $part;
      my Folder $src = $import->{src_folder} or next;
      next if $seen{Scalar::Util::refaddr($src)}++;
      push @result, $src;
    }
    @result;
  }

  sub YATT::Lite::Core::Part::configure_folder {
    (my Part $part, my Folder $folder) = @_;
    Scalar::Util::weaken($part->{folder} = $folder);
    # die "Can't weaken!" unless Scalar::Util::isweak($part->{folder});
  }

  # "%name;" or "%name(to=from);" (for error messages)
  sub YATT::Lite::Core::ArgMacro::call_spec {
    (my ArgMacro $argmacro) = @_;
    '%' . $argmacro->{name}
      . ($argmacro->{to_name}
         ? "($argmacro->{to_name}=" . ($argmacro->{from_name} // '') . ")"
         : '')
      . ';';
  }

  sub YATT::Lite::Core::ArgMacro::clone_with_renamespec {
    (my ArgMacro $orig, my ($toName, $fromName)) = @_;
    my ArgMacro $new = fields::new(ArgMacro);
    %$new = %$orig;
    Scalar::Util::weaken($new->{folder});
    $new->{output_args} = YATT::Lite::Util::deep_copy_array($orig->{output_args});
    $new->{to_name} = $toName;
    $new->{from_name} = $fromName;
    $new;
  }

#  sub YATT::Lite::Core::Part::source {
#    (my Part $part) = @_;
#    join "", map {ref $_ ? "\n" x $$_[0] : $_} @{$part->{source}};
#  }
  sub YATT::Lite::Core::Template::source_length {
    (my Template $self) = @_;
    length $self->{string};
  }
  sub YATT::Lite::Core::Template::list_parts {
    (my Template $self, my $type) = @_;
    return unless $self->{_partlist};
    return @{$self->{_partlist}} unless defined $type;
    grep { UNIVERSAL::isa($_, $type) } @{$self->{_partlist}}
  }
  sub YATT::Lite::Core::Template::widget_list {
     (my Template $self) = @_;
     $self->list_parts(Widget);
  }
  sub YATT::Lite::Core::Template::node_source {
    (my Template $tmpl, my $node) = @_;
    unless (ref $node eq 'ARRAY') {
      confess "Node is not an ARRAY";
    }
    $tmpl->source_region($node->[NODE_BEGIN], $node->[NODE_END]);
  }
  sub YATT::Lite::Core::Template::node_body_source {
    (my Template $tmpl, my $node) = @_;
    unless (ref $node eq 'ARRAY') {
      confess "Node is not an ARRAY";
    }
    $tmpl->source_region($node->[NODE_BODY_BEGIN], $node->[NODE_BODY_END]);
  }
  sub YATT::Lite::Core::Template::node_outer_source {
    (my Template $tmpl, my $node) = @_;
    unless (ref $node eq 'ARRAY') {
      confess "Node is not an ARRAY";
    }
    $tmpl->source_region($node->[NODE_BEGIN], $node->[NODE_BODY_END]);
  }
  sub YATT::Lite::Core::Template::source_region {
    (my Template $tmpl, my ($begin, $end)) = @_;
    $tmpl->source_substr($begin, $end - $begin);
  }
  sub YATT::Lite::Core::Template::source_substr {
    (my Template $tmpl, my ($offset, $len)) = @_;
    unless (defined $len) {
      substr $tmpl->{string}, $offset;
    } else {
      return undef if $len < 0;
      substr $tmpl->{string}, $offset, $len;
    }
  }

  # source_substr ベースの part (action/entity) の本体抽出。GH-258
  # (bodypos, bodylen) 区間内の yatt コメント span は「同じ改行数の \n 列」に
  # 置換して返す (行番号保存)。yatt コメントは宣言より強い構文要素なので、
  # raw 本体の中でも widget 同様「取り除かれる」意味論を成立させる。
  # コメントが無ければ source_substr と同一 (バイト単位)。
  sub YATT::Lite::Core::Template::part_body_source {
    (my Template $tmpl, my Part $part) = @_;
    my ($bodypos, $bodylen) = ($part->{bodypos}, $part->{bodylen});
    my $src = $tmpl->source_substr($bodypos, $bodylen);
    return $src unless defined $src;
    my $end = $bodypos + $bodylen;
    # 後ろから置換すれば手前の offset がずれない
    foreach my $entry (reverse @{$tmpl->{_boundarylist} // []}) {
      next unless $entry->{kind} eq 'comment';
      next unless $entry->{startpos} >= $bodypos and $entry->{endpos} <= $end;
      substr($src, $entry->{startpos} - $bodypos
             , $entry->{endpos} - $entry->{startpos})
        = "\n" x $entry->{nlines};
    }
    $src;
  }

  sub YATT::Lite::Core::Template::get_type_item {
    (my Template $tmpl, my ($type, $name)) = @_;
    my $class = $PART_KIND_CLASS{$type}
      or Carp::croak "Unknown type: $type";
    $tmpl->{_Item}{$class->item_key_for($name)};
  }

  sub YATT::Lite::Core::Part::reorder_hash_params {
    (my Widget $widget, my ($orig_params)) = @_;
    return unless $orig_params;
    return @$orig_params if ref $orig_params eq 'ARRAY';
    my $params = +{%$orig_params};
    my @params;
    foreach my $name (map($_ ? @$_ : (), $widget->{_arg_order})) {
      push @params, delete $params->{$name};
    }
    if (my @unknown = grep {/^[a-z]\w*$/i} keys %$params) {
      die "Unknown args for $widget->{name}: " . join(", ", @unknown)
	. "\n";
    }
    wantarray ? @params : \@params;
  }
}
{
  sub reorder_cgi_params {
    (my MY $self, my Widget $widget, my ($cgi, $list)) = @_;
    $list ||= [];
    my $stash;
    if ($self->{stash_unknown_params_to}) {
      $stash = $cgi->stash->{$self->{stash_unknown_params_to}} //= +{};
    }
    foreach my $name ($cgi->param) {
      next unless $name =~ /^[a-z]\w*$/i;
      my $argdecl = $widget->{_arg_dict}{$name} or do {
        if ($stash) {
          push @{$stash->{$name}}, $cgi->multi_param($name);
          next;
        } else {
          my $wname = $widget->{name}
            ? " for widget '$widget->{name}'" : "";
          die "Unknown args$wname: $name\n";
        }
      };
      if ($argdecl->is_unsafe_param) {
        if ($stash) {
          push @{$stash->{$name}}, $cgi->multi_param($name);
        }
        next;
      }
      my @value = $cgi->multi_param($name);
      my $type = $argdecl->type->[0];
      if ($type eq 'list') {
        $list->[$argdecl->argno] = \@value;
      } elsif ($type eq 'scalar') {
        # scalar may receive nested query structures (?choice[foo]=1).
        $list->[$argdecl->argno] = $value[0];
      } elsif (grep {ref $_} @value) {
        # text/bool never take a reference (?q[]=... would otherwise
        # reach escape() as a structure). Treat like an unknown param.
        if ($stash) {
          push @{$stash->{$name}}, @value;
        }
        next;
      } else {
        $list->[$argdecl->argno] = $value[0];
      }
    }
    @$list;
  }
}
#========================================
sub configure_rc_script {
  (my MY $vfs, my $script) = @_;
  my Folder $f = $vfs->{_root};
  my $pkg = $f->{entns}
    or die $vfs->error("package name is not specified for configure rc_script");
  # print STDERR "#### $pkg \n";
  # XXX: base は設定済みだったはずだけど...
  ckeval(qq{package $pkg; use strict; use YATT::Lite; $script});
}
#========================================

# Template alias さえ拡張すれば済むように。
# 逆に言うと、 vfs_file だけを定義して Template を定義しなかった場合, 継承が働かなくなった。
sub create_file {
  (my MY $vfs, my $spec) = splice @_, 0, 2;
  $vfs->Template->new(path => $spec, @_);
}

#
# called from <!yatt:base>
#
my %BASE_ATTS = ('' => 1, qw(file 1 dir 1));
sub declare_base {
  (my MY $vfs, my ParsingState $state, my Template $tmpl, my ($ns, @args)) = @_;

  unless (@args) {
    $vfs->synerror($state, q{No base arg});
  }

  my $base = $tmpl->{base} //= [];
  if (@$base) {
    $vfs->synerror($state, "Duplicate base decl! was=%s, new=%s"
		   , terse_dump($base), terse_dump(\@args));
  }

  foreach my $att (@args) {
    my $type = $vfs->node_type($att);

    $type == TYPE_ATT_TEXT
      or $vfs->synerror($state, q{Not implemented base decl type: %s}, $att);

    my $key = $vfs->node_path($att);
    unless ($BASE_ATTS{$key // ''}) {
      $vfs->synerror($state, q{Unknown base option: %s}, $key // '')
    }

    nonempty(my $fn = $vfs->node_value($att))
      or $vfs->synerror($state, q{base spec is empty!});

    if ($vfs->{_on_memory}) {
      my $o = $vfs->find_file($fn)
	or $vfs->synerror($state, q{No such base path: %s}, $fn);
      push @$base, $o;
    } else {
      defined(my $realfn = $vfs->resolve_path_from($tmpl, $fn))
	or $vfs->synerror($state, q{Can\'t find object path for: %s}, $fn);

      -e $realfn
	or $vfs->synerror($state, q{No such base path: %s}, $realfn);

      push @$base, my $o = $vfs->find_neighbor_type(undef, $realfn);

      $tmpl->add_dependency($realfn, $o);

      # GH-262: ここで find_product(perl => $o) してはいけない。
      # declare 段階は記述子を置くだけにする(base の decl parse は
      # find_neighbor_type 経由の create 時に済んでいる)。product の生成は
      # cgen 時の setup_inheritance_for → ensure_generated_for_folders と
      # dispatch 時の find_part_handler の事前コンパイルが遅延実行する。
      # eager に生成すると、この宣言自身を parse 中のテンプレートが
      # cached_in の dict 登録前(Util.pm:210)のため再 lookup で二重 create
      # され、EntNS confliction になる(base+widget-use の循環参照が壊れる)。
    }
  }
}

sub synerror {
  (my MY $vfs, my ParsingState $state, my ($fmt, @opts)) = @_;
  my $opts = {depth => 2};
  $opts->{tmpl_file} = $state->{path} if $state->{path};
  $opts->{tmpl_line} = $state->{_startln} if $state->{_startln};
  die $vfs->error($opts, $fmt, @opts);
}

#
# called from <!yatt:import> (LRXML::declare_import). GH-256
#
sub import_resolve_source {
  (my MY $vfs, my ParsingState $state, my Template $tmpl, my $fn) = @_;

  my $o = do {
    if ($vfs->{_on_memory}) {
      $vfs->find_file($fn)
        or $vfs->synerror($state, q{No such import path: %s}, $fn);
    } else {
      defined(my $realfn = $vfs->resolve_path_from($tmpl, $fn))
        or $vfs->synerror($state, qq{Can\'t find object path for import: %s}, $fn);

      -e $realfn
        or $vfs->synerror($state, q{No such import path: %s}, $realfn);

      # find_neighbor_type より前に path で検査する。相手が cached_in の
      # dict 代入前 (load 途中) だと、find_file が同じファイルの Template を
      # 二重生成して EntNS confliction になってしまうため。
      if ($YATT::Lite::LRXML::DECL_PARSING{$realfn}) {
        $vfs->synerror($state, q{Circular import detected: %s}, $fn);
      }

      my $found = $vfs->find_neighbor_type(undef, $realfn);

      $tmpl->add_dependency($realfn, $found);

      $found;
    }
  };

  unless (UNIVERSAL::isa($o, MY->Template)) {
    $vfs->synerror($state, q{import from non-template is not supported: %s}, $fn);
  }

  my Template $src = $o;
  if ($src->{_decl_parsing}) {
    $vfs->synerror($state, q{Circular import detected: %s}, $fn);
  }

  # import 対象は宣言時点でコンパイルしておく (cf. <!yatt:base> declare_base)。
  # これにより名前検証と @ISA/entns 確立が済んだ状態で以後の処理ができる。
  $vfs->find_product(perl => $src);

  $src;
}

#
# ソース template から import 対象を探す。$kind が undef なら自動判定。
# 戻り値: ($kind, $part_or_argmacro)
#
#
# find_kind_part_from (VFS.pm) の kind 別実装。
# item-key の符号化は各 part class の item_key_for に集約されている。GH-256
#
sub _find_kind_part__widget {
  (my MY $vfs, my ($from, $name)) = @_;
  my Part $part = $vfs->find_part_from($from, MY->Widget->item_key_for($name))
    or return undef;
  # widget と page は同じ名前空間なので kind で照合する
  ($part->{kind} // '') eq 'widget' ? $part : undef;
}
sub _find_kind_part__page {
  (my MY $vfs, my ($from, $name)) = @_;
  my Part $part = $vfs->find_part_from($from, MY->Page->item_key_for($name))
    or return undef;
  ($part->{kind} // '') eq 'page' ? $part : undef;
}
sub _find_kind_part__action {
  (my MY $vfs, my ($from, $name)) = @_;
  $vfs->find_part_from($from, MY->Action->item_key_for($name));
}
sub _find_kind_part__entity {
  (my MY $vfs, my ($from, $name)) = @_;
  $vfs->find_part_from($from, MY->Entity->item_key_for($name));
}
sub _find_kind_part__argmacro {
  (my MY $vfs, my ($from, $name)) = @_;
  my Folder $folder = $from;
  my $macro = $folder->{_argmacro_dict} && $folder->{_argmacro_dict}{$name};
  return $macro if $macro;
  # find_argmacro (LRXML.pm) と同じく base 1 段のみ探索
  foreach my Folder $base ($folder->list_base) {
    next unless UNIVERSAL::isa($base, MY->Template);
    my Template $baseTmpl = $base;
    return $baseTmpl->{_argmacro_dict}{$name}
      if $baseTmpl->{_argmacro_dict} && $baseTmpl->{_argmacro_dict}{$name};
  }
  # find_argmacro と同じく、最後に Site 設定 (argmacro => ...) の primary ns
  $vfs->find_argmacro_module(undef, undef, $name);
}

#
# argmacro の登録エラーは parse 時を待たず、構築時に報告する
#
sub after_new {
  (my MY $vfs) = @_;
  $vfs->SUPER::after_new;
  $vfs->argmacro_registry if $vfs->{argmacro};
}

# LRXML の既定 namespace と同じ
sub argmacro_namespace_list {
  (my MY $vfs) = @_;
  my @nslist = lexpand($vfs->{namespace});
  @nslist ? @nslist : qw(yatt perl);
}

#
# Site 設定 argmacro を {$ns}{$name} => 'Module' に正規化して返す。
#
#   argmacro => {name => 'Module', ...}
#   argmacro => [[ns => {name => 'Module', ...}], {name => 'Module'}, ...]
#
# 名前空間無しの登録は primary ns (namespace の先頭) での登録と同義。
# (ns, name) の重複、namespace に無い ns、形式不正は登録エラー。
#
sub argmacro_registry {
  (my MY $vfs) = @_;
  $vfs->{_argmacro_registry} //= do {
    my @nslist = $vfs->argmacro_namespace_list;
    my %known; $known{$_} = 1 for @nslist;
    my $die = sub {
      my ($fmt, @args) = @_;
      die $vfs->error({depth => 3}, $fmt, @args);
    };
    my %registry;
    my $spec = $vfs->{argmacro};
    foreach my $item (ref $spec eq 'ARRAY' ? @$spec : ($spec // ())) {
      my ($ns, $dict) = ref $item eq 'ARRAY' ? @$item
        : (undef, $item);
      if (ref $item eq 'ARRAY' and @$item != 2
          or ref $dict ne 'HASH') {
        $die->(q{Invalid argmacro registration: %s}
               , terse_dump($item));
      }
      if (defined $ns and not $known{$ns}) {
        $die->(q{Unknown namespace '%s' in argmacro registration}, $ns);
      }
      $ns //= $nslist[0];
      foreach my $name (sort keys %$dict) {
        $name =~ /^\w+\z/
          or $die->(q{Invalid argmacro name '%s'}, $name);
        $registry{$ns}{$name}
          and $die->(q{Duplicate argmacro registration '%s:%s'}, $ns, $name);
        $registry{$ns}{$name} = $dict->{$name};
      }
    }
    \%registry;
  };
}

#
# Site 設定 argmacro で ($ns, $name) に登録された ArgMacro を返す。
# $ns が undef なら primary ns。
# Module は YATT::Lite::ArgMacro を use して定義する(1 pm = 1 macro)。
# Core::ArgMacro は VFS 単位で一度だけ作り、ここで strong に保持する。
#
sub find_argmacro_module {
  (my MY $vfs, my ParsingState $state, my ($ns, $name)) = @_;
  return undef unless $vfs->{argmacro};
  $ns //= ($vfs->argmacro_namespace_list)[0];
  my $pkg = $vfs->argmacro_registry->{$ns}{$name}
    or return undef;

  $vfs->{_argmacro_module_cache}{"$ns:$name"} //= do {
    my $die = sub {
      my ($fmt, @args) = @_;
      $state ? $vfs->synerror($state, $fmt, @args)
        : die $vfs->error({depth => 2}, $fmt, @args);
    };
    YATT::Lite::Util::ckrequire($pkg);
    unless (UNIVERSAL::isa($pkg, 'YATT::Lite::ArgMacro')) {
      $die->(q{argmacro module '%s' for '%s' is not a YATT::Lite::ArgMacro}
             , $pkg, $name);
    }
    $pkg->as_argmacro_part($vfs->get_parser, $name, $ns);
  };
}

sub import_find_source_part {
  (my MY $vfs, my ParsingState $state, my Template $src, my ($srcName, $kind)) = @_;

  my $srcDesc = $src->{path} // $src->{name};

  # 全 kind を probe する (widget/page は同じ名前空間だが kind 照合で区別される)
  my @hits;
  foreach my $k (qw(widget page action entity argmacro)) {
    if (defined (my $found = $vfs->find_kind_part_from($src, $k, $srcName))) {
      push @hits, [$k => $found];
    }
  }

  if (defined $kind) {
    foreach my $hit (@hits) {
      return @$hit if $hit->[0] eq $kind;
    }
    if (@hits) {
      $vfs->synerror($state
                     , q{Import kind mismatch for '%s': expected %s, but %s has %s}
                     , $srcName, $kind, $srcDesc
                     , join(", ", map {$_->[0]} @hits));
    }
    $vfs->synerror($state, q{No such part to import: %s:%s (in %s)}
                   , $srcName, $kind, $srcDesc);
  } else {
    unless (@hits) {
      $vfs->synerror($state, q{No such part to import: %s (in %s)}
                     , $srcName, $srcDesc);
    }
    if (@hits > 1) {
      $vfs->synerror($state
                     , q{Ambiguous import '%s' in %s (found as: %s); add kind annotation like [%s:%s]}
                     , $srcName, $srcDesc, join(", ", map {$_->[0]} @hits)
                     , $srcName, $hits[0][0]);
    }
    return @{$hits[0]};
  }
}

#========================================
{
  sub Parser {
#    local $@;
#    my $err = catch {
      require YATT::Lite::LRXML;
#    };
#    unless ($err =~ /^Can't locate loadable object for module main::Tie::Hash::NamedCapture/) {
#      die $err || $@ || "(unknown reason)";
#    }
    'YATT::Lite::LRXML'
  }
  sub cgen_perl { 'YATT::Lite::CGen::Perl' }
  sub stat_mtime {
    my ($fn) = @_;
    -e $fn or return;
    (stat($fn))[9];
  }
  sub get_parser {
    my MY $self = shift;
    # $self->{parser} ||=
      $self->Parser->new
	(vfs => $self, $self->cf_delegate
	 (qw(namespace special_entities
             match_argsroute_first
             body_argument
             body_argument_type
             allow_bare_entity_in_decl
          )
	  , [debug_parser => 'debug']
	  , [tmpl_encoding => 'encoding']
	 )
	 , $self->{parse_while_loading} ? (all => 1) : ()
	 , @_);
  }
  sub ensure_parsed {
    (my MY $self, my Part $part) = @_;
    my $parser = $self->get_parser;
    my Template $tmpl = $part->{folder};
    return if $tmpl->{_parse_ok};
    $parser->parse_decllist_entities($tmpl);
    $parser->parse_body($tmpl);
  }
  sub render {
    my MY $self = shift;
    open my $fh, '>', \ (my $str = "") or die "Can't open capture buffer!: $!";
    $self->render_into($fh, @_);
    close $fh;
    $str;
  }
  sub render_into {
    (my MY $self, my ($fh, $namerec, $args, @opts)) = @_;
    my ($part, $sub, $pkg) = $self->find_part_handler($namerec);
    unless ($part->public) {
      # XXX: refresh する手もあるだろう。
      croak $self->error(q|Forbidden request '%s'|, terse_dump($namerec));
    }

    my @args = do {
      if (not defined $args) {
	();
      } elsif (ref $args eq 'ARRAY') {
	@$args
      } else {
	# $args can be a Hash::MultiValue and other HASH compatible obj.
	$part->reorder_hash_params($args);
      }
    };

    if (@opts) {
      $self->cf_let(\@opts, $sub, $pkg, $fh, @args);
    } else {
      $sub->($pkg, $fh, @args);
    }
  }

  # root から見える part (と、その template)を取り出す。
  sub get_part {
    (my MY $self, my $name, my %opts) = @_;
    my $ignore_error = delete $opts{ignore_error};
    my Template $tmpl;
    my Part $part;
    if (UNIVERSAL::isa($self->{_root}, Template)) {
      $tmpl = $self->{_root};
      $part = $self->find_part($name);
    } else {
      $tmpl = $self->find_file($name)
	or ($ignore_error and return)
	  or croak "No such template file: $name";
      $part = $tmpl->{_Item}{''};
    }
    # XXX: それとも、 $part から $tmpl が引けるようにするか? weaken して...
    wantarray ? ($part, $tmpl) : $part;
  }

  sub find_part_renderer {
    (my MY $self, my ($widgetPath, %opts)) = @_;
    my $ignore_error = delete $opts{ignore_error};

    my @wpath = ref $widgetPath ? @$widgetPath : split ":", $widgetPath;

    my $part = $self->find_part_from($self->{_root}, @wpath ? @wpath : '')
      or ($ignore_error and return)
      or croak "No such widget: ".join(":", @wpath);

    my $tmpl = $part->cget('folder');

    my $path = $tmpl->cget('path');

    my $method = "render_".$part->cget('name');

    my $pkg = $self->find_product(perl => $tmpl)
      or ($ignore_error and return)
	or croak "Can't compile template file: $path";

    my $sub = $pkg->can($method)
      or ($ignore_error and return)
	or croak "Can't extract $method from file: $path";

    ($part, $sub, $pkg);
  }

  sub find_part_handler {
    (my MY $self, my $nameSpec, my %opts) = @_;
    my $ignore_error = delete $opts{ignore_error};
    my ($partName, $kind, $pureName, @rest)
      = ref $nameSpec ? @$nameSpec : $nameSpec;

    $partName ||= $self->{index_name};

    my Template $tmpl = do {
      if (UNIVERSAL::isa($self->{_root}, Template)) {
        # Special case.
        # XXX: Should add action tests for this case.
        $self->{_root};

      } else {
        # General container case.
        $self->find_file($partName)
          or ($ignore_error and return)
	  or croak "No such template file: $partName";
      }
    };

    # part 探索より先にコンパイルする。継承 part の探索 (lookup_base) は
    # @ISA に依存し、@ISA は setup_inheritance_for (コード生成時) が張るため。
    # GH-255
    my $pkg = $self->find_product(perl => $tmpl)
      or ($ignore_error and return)
	or croak "Can't compile template file: $partName";

    (my Part $part, my $method) = do {
      (my Part $p, my $meth);
      if (not defined $kind and not defined $pureName) {
        foreach my $k (qw(page action)) {
          (my $itemKey, $meth) = $self->can("_itemKey_$k")->($self, '');
          $p = $tmpl->{_Item}{$itemKey}
            and last;
        }
      }

      if ($p) {
        ($p, $meth);
      } else {

        $kind //= 'page';
        $pureName //= '';

        my ($itemKey, $meth) = $self->can("_itemKey_$kind")->($self, $pureName);

        $p = $tmpl->{_Item}{$itemKey} || $self->find_part_from($tmpl, $itemKey)
          or ($ignore_error and return)
          or croak "No such $kind in file $partName: $pureName";

        ($p, $meth);
      };
    };

    # import alias はソース Part へ解決してから返す
    # (public 判定や引数 reorder が常に最新のソース側メタで動くように)。GH-256
    $part = $part->resolve_alias($self);

    my $sub = $pkg->can($method)
      or ($ignore_error and return)
	or croak "Can't extract $method from file: $partName";

    ($part, $sub, $pkg, @rest);
  }

  sub _itemKey_page {
    shift;
    (MY->Page->item_key_for($_[0]), MY->Page->method_name_for($_[0]));
  }
  sub _itemKey_action {
    shift;
    (MY->Action->item_key_for($_[0]), MY->Action->method_name_for($_[0]));
  }

  #
  # Action name => sub {}
  #
  sub add_root_action_handler {
    (my MY $self, my ($name, $sub, $callinfo)) = @_;
    my Folder $root = $self->{_root};

    my ($callpack, $filename, $lineno) = @$callinfo;

    # XXX: This means do_$A.yatt will conflict with "Action $A" in .htyattrc.pl
    my $action_name = "do_$name";

    *{globref($root->{entns}, $action_name)} = $sub;

    $root->{_Item}{MY->Action->item_key_for($name)}
      = $self->Action->new(name => $action_name, kind => 'action'
			   , folder => $root
			   , startln => $lineno
			 );

  }

  sub find_renderer {
    my MY $self = shift;
    my ($part, $sub, $pkg) = $self->find_part_handler(@_)
      or return;
    wantarray ? ($sub, $pkg) : $sub;
  }

  # DirHandler INST 固有 CGEN_perl の生成
  sub get_cgen_class {
    (my MY $self, my $type) = @_;
    $self->{facade}->get_cgen_class($type);
  }

  # XXX: Action only コンパイルは？
  sub find_product {
    (my MY $self, my $spec, my Template $tmpl, my %opts) = @_;
    my ($type, $kind) = ref $spec ? @$spec : $spec;
    # local $YATT = $self;
    unless ($tmpl->{_product}{$type}) {
      my $cgen = $self->build_cgen_of($type, \%opts);
      # 二重生成防止のため、代入自体は ensure_generated の中で行う。
      $cgen->ensure_generated($spec => $tmpl);
    };
    $tmpl->{_product}{$type};
  }

  sub build_cgen_of {
    (my MY $self, my $cgenSpec, my $opts) = @_;
    my ($type, $cg_class) = lexpand($cgenSpec);
    $cg_class //= $self->get_cgen_class($type);
    $cg_class->new
      (vfs => $self
       , $self->cf_delegate(qw(no_lineinfo check_lineno only_parse
                               prefer_call_for_entity
                               no_conditional_call
                               lcmsg_sink
                               pagevars
                             ))
       , parser => $self->get_parser
       , sink => $opts->{sink} || sub {
         my ($info, @script) = @_;
         if ($self->{debug_cgen}) {
           my Template $real = $info->{folder}; # XXX: type???
           print STDERR "# compiling @{[$type//'undef']} code of @{[$real->{path}//'undef']}\n";
           if ($self->{debug_cgen} >= 2) {
             print STDERR "#--BEGIN--\n";
             print STDERR @script, "\n";
             print STDERR "#--END--\n\n"
           }
         }
         #
         $self->{_n_compiles}++;

         ckeval(@script);
       })
  }

  #
  # extract_lcmsg
  #  - filelist is a list(or scalar) of filename or item name(no ext).
  #  - msgdict is used to share same msgid.
  #  - msglist is used to keep msg order.
  #
  # XXX: find_product and extract_lcmsg is exclusive.
  sub extract_lcmsg {
    (my MY $self, my ($filelist, $msglist, $msgdict)) = @_;
    require Locale::PO;
    $msglist //= [];
    $msgdict //= {};
    local $self->{lcmsg_sink} = sub {
      $self->define_lcmsg_in($msglist, $msgdict, @_);
    };
    my $type = 'perl';
    foreach my $name (lexpand($filelist)) {
      my Template $tmpl = $self->find_file($name)
	or croak "No such template: $name";
      $self->find_product($type => $tmpl);
    }
    # XXX: not wantarray
    @$msglist;
  }


  sub define_lcmsg_in {
    (my MY $self, my ($list, $dict, $place, $msgid, $other_msgs, $args)) = @_;
    if (my $obj = $dict->{$msgid}) {
      $obj->reference(join " ", grep {defined $_} $obj->reference, $place);
    } else {
      my @o = (-msgid => $msgid);
      if ($other_msgs and $other_msgs->[0]) {
	push @o, -msgid_plural => $other_msgs->[0]
	  , -msgstr_n => {0 => '', 1 => ''};
      } else {
	push @o, -msgstr => '';
      }
      push @$list, my $po = $dict->{$msgid} = Locale::PO->new(@o);
      $po->add_flag('perl-format');
      $po->reference($place);
    }
  }

  sub YATT::Lite::Core::Template::after_create {
    (my Template $tmpl, my MY $self) = @_;
    # XXX: ここでは SUPER が使えない。
    $tmpl->YATT::Lite::VFS::File::after_create($self);
    ($tmpl->{name}) = $tmpl->{path} =~ m{(\w+)\.\w+$}
      or $self->error("Can't extract part name from '%s'", [$tmpl->{path}])
	if not defined $tmpl->{name} and defined $tmpl->{path};
  }
  sub YATT::Lite::Core::Template::reset {
    (my Template $tmpl) = @_;
    $tmpl->YATT::Lite::VFS::File::reset;
    undef $tmpl->{_product};
    undef $tmpl->{_parse_ok};
    undef $tmpl->{subroutes};
    undef $tmpl->{_argmacro_dict};
    # delpkg($tmpl->{package}); # No way to avoid redef error.
  }
  sub YATT::Lite::Core::Template::refresh {
    (my Template $tmpl, my MY $self) = @_;

    my $old_product = $tmpl->{_product};
    my $old_signature;

    if ($tmpl->{path}) {
      printf STDERR "template_refresh(%s)\n", $tmpl->{path} if DEBUG_REBUILD;
      my $mtime = stat_mtime($tmpl->{path});
      if (not defined $mtime) {
	printf STDERR " => deleted\n" if DEBUG_REBUILD;
	return; # XXX: ファイルが消された
      } elsif (not defined $tmpl->{mtime}) {
        if (DEBUG_REBUILD) {
          printf STDERR " => found new. mtime($mtime) for tmpl=$tmpl\n";
        }
      } elsif ($tmpl->{mtime} >= $mtime) {
	if (DEBUG_REBUILD) {
	  printf STDERR " => use cached. mtime(was=$tmpl->{mtime}"
	    .", now=$mtime) for tmpl=$tmpl\n";
	}
	$self->refresh_deps_for($tmpl) if $self->{always_refresh_deps};
	return; # timestamp は、キャッシュと同じかむしろ古い
      } else {
        if (DEBUG_REBUILD) {
          printf STDERR " => found update. mtime($mtime) for tmpl=$tmpl\n";
        }
      }
      $tmpl->{mtime} = $mtime;
      $old_signature = $tmpl->part_interface_signature;
      my $parser = $self->get_parser;
      # decl のみ parse.
      # XXX: $tmpl->{package} の指すパッケージをこの段階で map {undef $_}
      # すべきではないか?
      $parser->load_file_into($tmpl, $tmpl->{path});
    } elsif ($tmpl->{string} and not $tmpl->{mtime}) {
      # To avoid recompilation, use mtime to express generated time.
      # Not so good.
      $tmpl->{mtime} = time;

      my $parser = $self->get_parser;
      $parser->load_string_into($tmpl, $tmpl->{string}
				, scheme => "data", path => $tmpl->{name});
    } else {
      return;
    }

    # $tmpl->YATT::Lite::VFS::Folder::vivify_base_descs($self);

    # If there was products, rebuild it too.
    foreach my $type ($old_product ? keys %$old_product : ()) {
      $self->find_product($type => $tmpl);
    }

    # part 宣言のインタフェースが変わった場合は、コンパイル済みの依存元
    # (呼び出し側) も作り直す。gen_putargs が呼び出し側のコンパイル時に
    # 名前付き実引数を位置引数へ変換しているため。本文だけの変更なら
    # 静的呼び出しの CODE slot 差し替えで追随するので再生成しない。
    # 依存元自体のソースは不変 (re-parse されない) なので、連鎖は一段で止まる。
    # GH-255
    if (($old_signature // '') ne $tmpl->part_interface_signature) {
      $self->rebuild_products_of_dependents($tmpl);
    }

    $tmpl;
  }
  sub YATT::Lite::Core::Template::part_interface_signature {
    (my Template $tmpl) = @_;
    join ";", map {
      my Part $part = $_;
      my $args = join ",", map {
        my $var = $part->{_arg_dict} && $part->{_arg_dict}{$_};
        $_ . "=" . (($var && eval {$var->type->[0]}) // '');
      } map {$_ ? @$_ : ()} $part->{_arg_order};
      join "\0", $part->{kind} // '', $part->{name} // ''
        , ($part->public ? 1 : 0), $args;
    } @{$tmpl->{_partlist} || []};
  }
  sub rebuild_products_of_dependents {
    (my MY $self, my Template $tmpl) = @_;
    foreach my Template $dep ($tmpl->list_dependents) {
      my $old = $dep->{_product};
      next unless $old and %$old;
      printf STDERR "rebuilding products of dependent: %s\n", $dep->{path}
        if DEBUG_REBUILD;
      $dep->{_product} = +{};
      foreach my $type (keys %$old) {
        eval { $self->find_product($type => $dep) };
        if ($@) {
          # 失敗した product を残すと古い stash が生き続けるので消しておく
          delete $dep->{_product}{$type};
          die $@;
        }
      }
    }
  }
  sub YATT::Lite::Core::Widget::fixup {
    (my Widget $widget, my Template $tmpl, my AbstParser $parser) = @_;
    foreach my $argName (@{$widget->{_arg_order}}) {
      $widget->{_has_required_arg} = 1
	if $widget->{_arg_dict}{$argName}->is_required;
    }
    $widget->{_arg_dict}{$parser->{body_argument}} ||= do {
      my ($type, @dflag_default) = $parser->parse_type_dflag_default(
        $parser->{body_argument_type}
      );

      # lineno も入れるべきかも。 $widget->{bodyln} あたり.
      my $var = $parser->mkvar_at(undef
                                  , $type
                                  , $parser->{body_argument}
				  , scalar @{$widget->{_arg_order} ||= []});
      # body_argument の印を付ける。public からは受理しないように.
      $var->mark_body_argument;
      $parser->set_dflag_default_to($var, @dflag_default);

      push @{$widget->{_arg_order}}, $parser->{body_argument};
      $var;
    };
  }

  sub YATT::Lite::Core::Template::match_subroutes {
    my Template $tmpl = shift;
    return unless $tmpl->{subroutes};
    $tmpl->{subroutes}->match($_[0]);
  }
}

use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_core();

1;
