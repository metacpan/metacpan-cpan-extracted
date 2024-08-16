package YATT::Lite::Core; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};

use parent qw(YATT::Lite::VFS);
use YATT::Lite::MFields qw/cf_namespace cf_debug_cgen cf_no_lineinfo cf_check_lineno
			   cf_index_name
	      cf_tmpl_encoding
	      cf_debug_parser
	      cf_parse_while_loading cf_only_parse
	      cf_die_in_error cf_error_handler
	      cf_special_entities
	      cf_lcmsg_sink
              cf_match_argsroute_first
              cf_body_argument
              cf_body_argument_type

              cf_stash_unknown_params_to
	      cf_prefer_call_for_entity

	      n_compiles
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
      , -fields => [qw(toks arg_dict arg_order
                       decllist
		       cf_namespace cf_kind cf_folder cf_data
                       cf_decl
		       cf_implicit cf_suppressed
		       cf_startln cf_bodyln cf_endln
		       cf_startpos cf_bodypos cf_bodylen
		       cf_subpattern
		     )]
      , -constants => [[public => 0]]
      , [Widget => -fields => [qw(tree var_dict has_required_arg)]
	 , [Page => (), -constants => [[public => 1]]]]
      , [Action => (), -constants => [[public => 1],
                                      [item_category => 'do'],
                                    ]]
      , [Data => ()]
      , [Entity => ()
         , -constants => [[item_category => 'entity']]
       ]
    ]

     , [Template => -base => MY->File
	, -alias => 'vfs_file'
	, -constants => [[can_generate_code => 1]]
	, -fields => [qw(product parse_ok cf_mtime cf_utf8 cf_age
			 cf_usage cf_constants
			 cf_ignore_trailing_newlines
			 cf_subroutes
		      )]]

     , [ParsingState => -fields => [qw(startln endln
				       startpos curpos
				       cf_path
                                    )]]

     , [AbstParser => -fields => [qw(cf_body_argument
                                     cf_body_argument_type
                                  )]]
    );

  sub YATT::Lite::Core::Part::public_name {
    (my Part $part) = @_;
    $part->{cf_name};
  }
  sub YATT::Lite::Core::Part::decl_kind {
    (my Part $part) = @_;
    join(":", $part->{cf_namespace}, $part->{cf_decl});
  }
  sub YATT::Lite::Core::Part::syntax_keyword {
    (my Part $part) = @_;
    join(" ", $part->decl_kind, $part->syntax_name);
  }
  *YATT::Lite::Core::Part::syntax_name = *YATT::Lite::Core::Part::public_name;
  *YATT::Lite::Core::Part::syntax_name = *YATT::Lite::Core::Part::public_name;
  sub YATT::Lite::Core::Widget::syntax_name {
    (my Widget $widget) = @_;
    $widget->{cf_decl} eq 'args' ? () : $widget->{cf_name};
  }
  sub YATT::Lite::Core::Action::syntax_name {
    (my Action $action) = @_;
    $action->{cf_name} eq '' ? q{''} : $action->{cf_name};
  }

  sub YATT::Lite::Core::Part::method_name {...}
  sub YATT::Lite::Core::Widget::method_name {
    (my Widget $widget) = @_;
    "render_$widget->{cf_name}";
  }
  sub YATT::Lite::Core::Action::method_name {
    (my Action $action) = @_;
    "do_$action->{cf_name}";
  }
  sub YATT::Lite::Core::Action::item_key {
    (my Action $action) = @_;
    "do\0$action->{cf_name}";
  }

  sub YATT::Lite::Core::Entity::method_name {
    (my Entity $entity) = @_;
    "entity_$entity->{cf_name}";
  }
  sub YATT::Lite::Core::Entity::item_key {
    (my Entity $entity) = @_;
    "entity\0$entity->{cf_name}";
  }

  sub YATT::Lite::Core::Part::configure_folder {
    (my Part $part, my Folder $folder) = @_;
    Scalar::Util::weaken($part->{cf_folder} = $folder);
    # die "Can't weaken!" unless Scalar::Util::isweak($part->{cf_folder});
  }

#  sub YATT::Lite::Core::Part::source {
#    (my Part $part) = @_;
#    join "", map {ref $_ ? "\n" x $$_[0] : $_} @{$part->{source}};
#  }
  sub YATT::Lite::Core::Template::source_length {
    (my Template $self) = @_;
    length $self->{cf_string};
  }
  sub YATT::Lite::Core::Template::list_parts {
    (my Template $self, my $type) = @_;
    return unless $self->{partlist};
    return @{$self->{partlist}} unless defined $type;
    grep { UNIVERSAL::isa($_, $type) } @{$self->{partlist}}
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
      substr $tmpl->{cf_string}, $offset;
    } else {
      return undef if $len < 0;
      substr $tmpl->{cf_string}, $offset, $len;
    }
  }

  sub YATT::Lite::Core::Part::reorder_hash_params {
    (my Widget $widget, my ($orig_params)) = @_;
    return unless $orig_params;
    return @$orig_params if ref $orig_params eq 'ARRAY';
    my $params = +{%$orig_params};
    my @params;
    foreach my $name (map($_ ? @$_ : (), $widget->{arg_order})) {
      push @params, delete $params->{$name};
    }
    if (my @unknown = grep {/^[a-z]\w*$/i} keys %$params) {
      die "Unknown args for $widget->{cf_name}: " . join(", ", @unknown)
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
    if ($self->{cf_stash_unknown_params_to}) {
      $stash = $cgi->stash->{$self->{cf_stash_unknown_params_to}} //= +{};
    }
    foreach my $name ($cgi->param) {
      next unless $name =~ /^[a-z]\w*$/i;
      my $argdecl = $widget->{arg_dict}{$name} or do {
        if ($stash) {
          push @{$stash->{$name}}, $cgi->multi_param($name);
          next;
        } else {
          my $wname = $widget->{cf_name}
            ? " for widget '$widget->{cf_name}'" : "";
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
      $list->[$argdecl->argno] = $argdecl->type->[0] eq 'list'
	? \@value : $value[0];
    }
    @$list;
  }
}
#========================================
sub configure_rc_script {
  (my MY $vfs, my $script) = @_;
  my Folder $f = $vfs->{root};
  my $pkg = $f->{cf_entns}
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
sub declare_base {
  (my MY $vfs, my ParsingState $state, my Template $tmpl, my ($ns, @args)) = @_;

  unless (@args) {
    $vfs->synerror($state, q{No base arg});
  }

  my $base = $tmpl->{cf_base} //= [];
  if (@$base) {
    $vfs->synerror($state, "Duplicate base decl! was=%s, new=%s"
		   , terse_dump($base), terse_dump(\@args));
  }

  foreach my $att (@args) {
    my $type = $vfs->node_type($att);

    $type == TYPE_ATT_TEXT
      or $vfs->synerror($state, q{Not implemented base decl type: %s}, $att);

    nonempty(my $fn = $vfs->node_value($att))
      or $vfs->synerror($state, q{base spec is empty!});

    if ($vfs->{on_memory}) {
      my $o = $vfs->find_file($fn)
	or $vfs->synerror($state, q{No such base path: %s}, $fn);
      push @$base, $o;
    } else {
      defined(my $realfn = $vfs->resolve_path_from($tmpl, $fn))
	or $vfs->synerror($state, q{Can't find object path for: %s}, $fn);

      -e $realfn
	or $vfs->synerror($state, q{No such base path: %s}, $realfn);

      push @$base, $vfs->find_neighbor_type(undef, $realfn);
    }
  }
}

sub synerror {
  (my MY $vfs, my ParsingState $state, my ($fmt, @opts)) = @_;
  my $opts = {depth => 2};
  $opts->{tmpl_file} = $state->{cf_path} if $state->{cf_path};
  $opts->{tmpl_line} = $state->{startln} if $state->{startln};
  die $vfs->error($opts, $fmt, @opts);
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
          )
	  , [debug_parser => 'debug']
	  , [tmpl_encoding => 'encoding']
	 )
	 , $self->{cf_parse_while_loading} ? (all => 1) : ()
	 , @_);
  }
  sub ensure_parsed {
    (my MY $self, my Part $part) = @_;
    my $parser = $self->get_parser;
    my Template $tmpl = $part->{cf_folder};
    return if $tmpl->{parse_ok};
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
    if (UNIVERSAL::isa($self->{root}, Template)) {
      $tmpl = $self->{root};
      $part = $self->find_part($name);
    } else {
      $tmpl = $self->find_file($name)
	or ($ignore_error and return)
	  or croak "No such template file: $name";
      $part = $tmpl->{Item}{''};
    }
    # XXX: それとも、 $part から $tmpl が引けるようにするか? weaken して...
    wantarray ? ($part, $tmpl) : $part;
  }

  sub find_part_renderer {
    (my MY $self, my ($widgetPath, %opts)) = @_;
    my $ignore_error = delete $opts{ignore_error};

    my @wpath = ref $widgetPath ? @$widgetPath : split ":", $widgetPath;

    my $part = $self->find_part_from($self->{root}, @wpath ? @wpath : '')
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

    $partName ||= $self->{cf_index_name};

    my Template $tmpl = do {
      if (UNIVERSAL::isa($self->{root}, Template)) {
        # Special case.
        # XXX: Should add action tests for this case.
        $self->{root};

      } else {
        # General container case.
        $self->find_file($partName)
          or ($ignore_error and return)
	  or croak "No such template file: $partName";
      }
    };

    (my Part $part, my $method) = do {
      (my Part $p, my $meth);
      if (not defined $kind and not defined $pureName) {
        foreach my $k (qw(page action)) {
          (my $itemKey, $meth) = $self->can("_itemKey_$k")->($self, '');
          $p = $tmpl->{Item}{$itemKey}
            and last;
        }
      }

      if ($p) {
        ($p, $meth);
      } else {

        $kind //= 'page';
        $pureName //= '';

        my ($itemKey, $meth) = $self->can("_itemKey_$kind")->($self, $pureName);

        $p = $tmpl->{Item}{$itemKey} || $self->find_part_from($tmpl, $itemKey)
          or ($ignore_error and return)
          or croak "No such $kind in file $partName: $pureName";

        ($p, $meth);
      };
    };

    my $pkg = $self->find_product(perl => $tmpl)
      or ($ignore_error and return)
	or croak "Can't compile template file: $partName";

    my $sub = $pkg->can($method)
      or ($ignore_error and return)
	or croak "Can't extract $method from file: $partName";

    ($part, $sub, $pkg, @rest);
  }

  sub _itemKey_page { shift; ($_[0], "render_$_[0]") }
  sub _itemKey_action { shift; ("do\0$_[0]", "do_$_[0]"); }

  #
  # Action name => sub {}
  #
  sub add_root_action_handler {
    (my MY $self, my ($name, $sub, $callinfo)) = @_;
    my Folder $root = $self->{root};

    my ($callpack, $filename, $lineno) = @$callinfo;

    # XXX: This means do_$A.yatt will conflict with "Action $A" in .htyattrc.pl
    my $action_name = "do_$name";

    *{globref($root->{cf_entns}, $action_name)} = $sub;

    $root->{Item}{"do\0$name"}
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
    $self->{cf_facade}->get_cgen_class($type);
  }

  # XXX: Action only コンパイルは？
  sub find_product {
    (my MY $self, my $spec, my Template $tmpl, my %opts) = @_;
    my ($type, $kind) = ref $spec ? @$spec : $spec;
    # local $YATT = $self;
    unless ($tmpl->{product}{$type}) {
      my $cgen = $self->build_cgen_of($type, \%opts);
      # 二重生成防止のため、代入自体は ensure_generated の中で行う。
      $cgen->ensure_generated($spec => $tmpl);
    };
    $tmpl->{product}{$type};
  }

  sub build_cgen_of {
    (my MY $self, my $cgenSpec, my $opts) = @_;
    my ($type, $cg_class) = lexpand($cgenSpec);
    $cg_class //= $self->get_cgen_class($type);
    $cg_class->new
      (vfs => $self
       , $self->cf_delegate(qw(no_lineinfo check_lineno only_parse
                               prefer_call_for_entity
                               lcmsg_sink))
       , parser => $self->get_parser
       , sink => $opts->{sink} || sub {
         my ($info, @script) = @_;
         if ($self->{cf_debug_cgen}) {
           my Template $real = $info->{folder};
           print STDERR "# compiling @{[$type//'undef']} code of @{[$real->{cf_path}//'undef']}\n";
           if ($self->{cf_debug_cgen} >= 2) {
             print STDERR "#--BEGIN--\n";
             print STDERR @script, "\n";
             print STDERR "#--END--\n\n"
           }
         }
         #
         $self->{n_compiles}++;

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
    local $self->{cf_lcmsg_sink} = sub {
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
    ($tmpl->{cf_name}) = $tmpl->{cf_path} =~ m{(\w+)\.\w+$}
      or $self->error("Can't extract part name from '%s'", [$tmpl->{cf_path}])
	if not defined $tmpl->{cf_name} and defined $tmpl->{cf_path};
  }
  sub YATT::Lite::Core::Template::reset {
    (my Template $tmpl) = @_;
    $tmpl->YATT::Lite::VFS::File::reset;
    undef $tmpl->{product};
    undef $tmpl->{parse_ok};
    undef $tmpl->{cf_subroutes};
    # delpkg($tmpl->{cf_package}); # No way to avoid redef error.
  }
  sub YATT::Lite::Core::Template::refresh {
    (my Template $tmpl, my MY $self) = @_;

    my $old_product = $tmpl->{product};

    if ($tmpl->{cf_path}) {
      printf STDERR "template_refresh(%s)\n", $tmpl->{cf_path} if DEBUG_REBUILD;
      my $mtime = stat_mtime($tmpl->{cf_path});
      if (not defined $mtime) {
	printf STDERR " => deleted\n" if DEBUG_REBUILD;
	return; # XXX: ファイルが消された
      } elsif (not defined $tmpl->{cf_mtime}) {
        if (DEBUG_REBUILD) {
          printf STDERR " => found new. mtime($mtime) for tmpl=$tmpl\n";
        }
      } elsif ($tmpl->{cf_mtime} >= $mtime) {
	if (DEBUG_REBUILD) {
	  printf STDERR " => use cached. mtime(was=$tmpl->{cf_mtime}"
	    .", now=$mtime) for tmpl=$tmpl\n";
	}
	$self->refresh_deps_for($tmpl) if $self->{cf_always_refresh_deps};
	return; # timestamp は、キャッシュと同じかむしろ古い
      } else {
        if (DEBUG_REBUILD) {
          printf STDERR " => found update. mtime($mtime) for tmpl=$tmpl\n";
        }
      }
      $tmpl->{cf_mtime} = $mtime;
      my $parser = $self->get_parser;
      # decl のみ parse.
      # XXX: $tmpl->{cf_package} の指すパッケージをこの段階で map {undef $_}
      # すべきではないか?
      $parser->load_file_into($tmpl, $tmpl->{cf_path});
    } elsif ($tmpl->{cf_string} and not $tmpl->{cf_mtime}) {
      # To avoid recompilation, use mtime to express generated time.
      # Not so good.
      $tmpl->{cf_mtime} = time;

      my $parser = $self->get_parser;
      $parser->load_string_into($tmpl, $tmpl->{cf_string}
				, scheme => "data", path => $tmpl->{cf_name});
    } else {
      return;
    }

    # $tmpl->YATT::Lite::VFS::Folder::vivify_base_descs($self);

    # If there was products, rebuild it too.
    foreach my $type ($old_product ? keys %$old_product : ()) {
      $self->find_product($type => $tmpl);
    }

    $tmpl;
  }
  sub YATT::Lite::Core::Widget::fixup {
    (my Widget $widget, my Template $tmpl, my AbstParser $parser) = @_;
    foreach my $argName (@{$widget->{arg_order}}) {
      $widget->{has_required_arg} = 1
	if $widget->{arg_dict}{$argName}->is_required;
    }
    $widget->{arg_dict}{$parser->{cf_body_argument}} ||= do {
      my ($type, @dflag_default) = $parser->parse_type_dflag_default(
        $parser->{cf_body_argument_type}
      );

      # lineno も入れるべきかも。 $widget->{cf_bodyln} あたり.
      my $var = $parser->mkvar_at(undef
                                  , $type
                                  , $parser->{cf_body_argument}
				  , scalar @{$widget->{arg_order} ||= []});
      # body_argument の印を付ける。public からは受理しないように.
      $var->mark_body_argument;
      $parser->set_dflag_default_to($var, @dflag_default);

      push @{$widget->{arg_order}}, $parser->{cf_body_argument};
      $var;
    };
  }

  sub YATT::Lite::Core::Template::match_subroutes {
    my Template $tmpl = shift;
    return unless $tmpl->{cf_subroutes};
    $tmpl->{cf_subroutes}->match($_[0]);
  }
}

use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_core();

1;
