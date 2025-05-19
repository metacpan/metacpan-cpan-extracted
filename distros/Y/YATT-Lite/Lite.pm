package YATT::Lite; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.010; no if $] >= 5.017011, warnings => "experimental";

use Carp qw(carp croak confess);
our $VERSION = '0.131';
use mro 'c3';

use Scalar::Util qw/weaken/;
use List::MoreUtils qw/uniq/;

#
# YATT Internalへの Facade. YATT の初期化パラメータの保持者でもある。
#
use parent qw/YATT::Lite::Object File::Spec/;
use YATT::Lite::Partial::MarkAfterNew -as_base;
use YATT::Lite::MFields qw/YATT
	      cf_dir
	      cf_vfs cf_base
	      cf_factory
	      cf_header_charset
	      cf_output_encoding
	      cf_tmpl_encoding
	      cf_index_name
	      cf_ext_public
	      cf_ext_private
	      cf_app_ns
	      entns
	      cgen_class

	      cf_app_name
	      cf_debug_cgen cf_debug_parser cf_namespace cf_only_parse
	      cf_special_entities cf_no_lineinfo cf_check_lineno
	      cf_rc_script
	      cf_tmpl_cache
	      cf_dont_map_args
	      cf_dont_debug_param
	      cf_info
	      cf_lcmsg_sink
	      cf_always_refresh_deps
	      cf_no_mro_c3
	      cf_render_as_bytes

	      cf_default_lang

	      cf_entns2vfs_item
	      cf_import
              cf_match_argsroute_first
              cf_stash_unknown_params_to
              cf_body_argument
              cf_body_argument_type
	      cf_prefer_call_for_entity
	    /;

use constant DEBUG => $ENV{DEBUG_YATT_LITE};

MY->cf_mkaccessors(qw/app_name/);

# Entities を多重継承する理由は import も継承したいから。
# XXX: やっぱり、 YATT::Lite には固有の import を用意すべきではないか?
#   yatt_default や cgen_perl を定義するための。
use YATT::Lite::Entities -as_base, qw(*YATT *CON *SYS import);

# For error, raise, DONE. This is inserted to ISA too.
use YATT::Lite::Partial::ErrorReporter;

use YATT::Lite::Partial::AppPath;

use YATT::Lite::Util qw/globref lexpand extname ckrequire terse_dump escape
			set_inc ostream try_invoke list_isa symtab
			look_for_globref
			subname ckeval ckrequire
			secure_text_plain
                        raise_psgi_error
			define_const
                        add_entity_into
		       /;

sub Facade () {__PACKAGE__}
sub default_app_ns {'MyYATT'}
sub default_trans {'YATT::Lite::Core'}
sub default_export {(shift->SUPER::default_export, qw(Entity *SYS *CON))}
sub default_index_name { '' }
sub default_ext_public {'yatt'}
sub default_ext_private {'ytmpl'}
sub default_body_argument { 'body' }
sub default_body_argument_type { 'code' }
sub default_output_encoding { 'utf-8' }

sub with_system {
  (my MY $self, local $SYS, my $method) = splice @_, 0, 3;
  local $YATT = $self;
  $self->$method(@_);
}

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{cf_index_name} //= "";
  $self->{cf_ext_public} //= $self->default_ext_public;
  $self->{cf_ext_private} //= $self->default_ext_private;
  $self->{cf_body_argument} //= $self->default_body_argument;
  $self->{cf_body_argument_type} //= $self->default_body_argument_type;
  $self->{cf_output_encoding} //= $self->default_output_encoding;
}

sub _after_after_new {
  (my MY $self) = @_;
  weaken($self->{cf_factory});
}

sub rel_app_name {
  (my MY $self) = @_;
  unless ($SYS) {
    Carp::croak "rel_app_name() is called without setting \$SYS!";
  }
  # XXX: This assumes $dir is somewhere under $app_root tree.
  my $rel_app_name = substr($self->{cf_dir}, length($SYS->app_root));
  # Make sure leading / is removed.
  $rel_app_name =~ s|^/||;
  $rel_app_name;
}

# XXX: kludge!
sub find_neighbor_yatt {
  (my MY $self, my ($dir)) = @_;
  $self->{cf_factory}->load_yatt($dir);
}
sub find_neighbor_vfs {
  (my MY $self, my ($dir)) = @_;
  $self->find_neighbor_yatt($dir)->get_trans;
}
sub find_neighbor {
  (my MY $self, my ($dir)) = @_;
  $self->find_neighbor_vfs($dir)->root;
}

#
# list all configs (named $name). (base first, then local one)
# (useful to avoid config repeation)
#
sub cget_all {
  (my MY $self, my $name) = @_;
  (map($_->cget_all($name)
       , $self->list_base_obj)
   , lexpand($self->{"cf_$name"}));
}

sub list_base_obj {
  (my MY $self) = @_;
  map {
    $self->find_neighbor_yatt($self->app_path_normalize($_))
  } $self->list_base_dir;
}

sub list_base_dir {
  (my MY $self) = @_;

  my $base = $self->{cf_base} // do {
    my %vfs = lexpand($self->{cf_vfs});
    [map {
      #
      # Each element of $vfs{base} is either ARRAY (of vfs spec)
      # or YATT::Lite::VFS::Dir object (instantiated from spec).
      #
      if (ref $_ eq 'ARRAY') {
	my %vfs_base = @$_;
	$vfs_base{dir};
      } else {
	$_->{cf_path};
      }
    } lexpand($vfs{base})];
  };

  lexpand($base);
}

#========================================
# file extension based handler dispatching.
#========================================

sub handle {
  (my MY $self, my ($ext, $con, $file)) = @_;
  local ($YATT, $CON) = ($self, $con);
  $con->configure(yatt => $self);
  if (my $enc = $self->{cf_output_encoding}) {
    $con->configure(encoding => $enc);
  }

  unless (defined $file) {
    confess "\n\nFilename for DirHandler->handle() is undef!"
      ." in $self->{cf_app_ns}.\n";
  }

  my $sub = $YATT->find_handler($ext, $file, $CON);

  my $result = $sub->($YATT, $CON, $file);

  try_invoke($CON, 'flush_headers');

  $result;
}

sub render {
  my MY $self = shift;
  my $raw_bytes = $self->render_encoded(@_);
  if ($self->{cf_render_as_bytes}) {
    $raw_bytes
  } else {
    Encode::decode(utf8 => $raw_bytes);
  }
}

sub render_encoded {
  my MY $self = shift;
  my $buffer; {
    my $encName = $self->{cf_render_as_bytes} ? undef : $self->{cf_output_encoding};
    my $con = $SYS
      ? $SYS->make_connection(undef, buffer => \$buffer, yatt => $self,
                              noheader => 1,
                              encoding => $encName)
	: ostream(\$buffer, $encName ? ":encoding($encName)" : "");
    $self->render_into($con, @_);
  }
  $buffer;
}

sub render_into {
  (my MY $self, my ($con, $file, $args)) = @_;
  local ($YATT, $CON) = ($self, $con);
  if (ref $file eq 'ARRAY') {
    # [$file, $type, $item]
    $self->open_trans->render_into($CON, $file, $args);
  } else {
    $self->raw_render_into(
      $con,
      YATT::Lite::Util::rootname($file || $self->{cf_index_name}),
      $args,
    );
  }
  try_invoke($con, 'flush_headers');
}

sub raw_render_into {
  (local ($YATT), my ($con, $file, $args)) = @_;
  my ($part, $sub, $pkg) = $YATT->open_trans->find_part_renderer($file);
  $sub->($pkg, $con, $part->reorder_hash_params($args));
}

sub find_handler {
  (my MY $self, my ($ext, $file, $con)) = @_;
  $ext //= $self->cut_ext($file) || $self->{cf_ext_public};
  $ext = "yatt" if $ext eq $self->{cf_ext_public};
  my $sub = $self->can("_handle_$ext")
    or die "Unsupported file type: $ext";
  $sub;
}

#----------------------------------------

# 直接呼ぶことは禁止。∵ $YATT, $CON を設定するのは handle の役目だから。
sub _handle_yatt {
  (my MY $self, my ($con, $file)) = @_;

  my ($part, $sub, $pkg, $args)
    = $self->prepare_part_handler($con, $file);

  $sub->($pkg, $con, @$args);

  $con;
}

sub _handle_ytmpl {
  (my MY $self, my ($con, $file)) = @_;

  $self->raise_psgi_error(403, "Forbidden filetype: $file");
}

#----------------------------------------

sub prepare_part_handler {
  (my MY $self, my ($con, $file)) = @_;

  my $trans = $self->open_trans;

  my $mapped = [$file, my ($type, $item) = $con->sigil_type_item()];
  if (not $self->{cf_dont_debug_param}
      and -e ".htdebug_param") {
    $self->dump($mapped, [map {[$_ => $con->param($_)]} $con->param]);
  }

  # XXX: public に限定するのはどこで？ ここで？それとも find_自体？
  my ($part, $sub, $pkg) = $trans->find_part_handler($mapped);
  unless ($part->public) {
    # XXX: refresh する手もあるだろう。
    croak $self->error(q|Forbidden request %s|, terse_dump($mapped));
  }

  my @args; @args = $trans->reorder_cgi_params($part, $con)
    unless $self->{cf_dont_map_args} || $part->isa($trans->Action);

  ($part, $sub, $pkg, \@args);
}

# XXX: deprecated
sub parse_request_sigil {
  (my MY $self, my ($con)) = @_;
  $con->sigil_type_item();
}

sub cut_ext {
  my ($self, $fn) = @_;
  croak "Undefined filename!" unless defined $fn;
  return undef unless $fn =~ s/\.(\w+$)//;
  $1;
}

#========================================
# hook
#========================================
sub finalize_connection {}

#========================================
# Output encoding. Used in scripts/yatt*
#========================================
sub fconfigure_encoding {
  my MY $self = shift;
  return unless $self->{cf_output_encoding};
  my $enc = "encoding($self->{cf_output_encoding})";
  require PerlIO;
  foreach my $fh (@_) {
    next if grep {$_ eq $enc} PerlIO::get_layers($fh);
    binmode($fh, ":$enc");
  }
  $self;
}

#========================================
# Delayed loading of YATT::Lite::Core
#========================================

*open_vfs = *open_trans; *open_vfs = *open_trans;
sub open_trans {
  (my MY $self) = @_;
  my $trans = $self->get_trans;
  $trans->reset_refresh_mark;
  $trans;
}

*get_vfs = *get_trans; *get_vfs = *get_trans;
sub get_trans {
  (my MY $self) = @_;
  $self->{YATT} || $self->build_trans($self->{cf_tmpl_cache});
}

sub build_trans {
  (my MY $self, my ($vfscache, $vfsspec, @rest)) = @_;
  my $class = $self->default_trans;
  ckrequire($class);

  my @vfsspec = @{$vfsspec || $self->{cf_vfs}};
  push @vfsspec, base => $self->{cf_base} if $self->{cf_base};

  $self->{YATT} = $class->new
    (\@vfsspec
     , facade => $self
     , cache => $vfscache
     , entns2vfs_item => $self->{cf_entns2vfs_item}
     , entns => $self->{entns}
     , @rest
     , $self->cf_delegate_defined($self->_cf_delegates));
}

sub _cf_delegates {
  qw(namespace
     base
     die_in_error
     tmpl_encoding
     debug_cgen
     debug_parser
     special_entities
     no_lineinfo
     check_lineno
     index_name
     ext_public
     ext_private
     rc_script
     lcmsg_sink
     only_parse
     always_refresh_deps
     no_mro_c3
     import
     match_argsroute_first
     stash_unknown_params_to
     body_argument
     body_argument_type
     prefer_call_for_entity
    )
}

sub _before_after_new {
  (my MY $self) = @_;
  $self->{cf_app_ns} //= $self->default_app_ns;
  $self->{entns} = $self->ensure_entns($self->{cf_app_ns});
}

#========================================
# Code generator class
#========================================

sub root_CGEN_perl () { 'YATT::Lite::CGen::Perl' }
*CGEN_perl = *root_CGEN_perl; *CGEN_perl = *root_CGEN_perl;
sub ensure_cgen_for {
  my ($mypack, $type, $app_ns) = @_;
  $mypack->ensure_supplns("CGEN_$type" => $app_ns);
}

sub get_cgen_class {
  (my MY $self, my $type) = @_;
  my $name = "CGEN_$type";
  my $sub = $self->can("root_$name")
    or croak "Unknown cgen class: $type";
  $self->{cgen_class}{$type}
    ||= $self->ensure_cgen_for($type, $self->{cf_app_ns});
}

sub is_default_cgen_ready {
  (my MY $self) = @_;
  $self->{cgen_class}{perl};
}

#========================================
# Entity
#========================================

sub root_EntNS { 'YATT::Lite::Entities' }

# ${app_ns}::EntNS を作り、(YATT::Lite::Entities へ至る)継承関係を設定する。
# $app_ns に EntNS constant を追加する。
# 複数回呼ばれた場合、既に定義済みの entns を返す

sub should_use_mro_c3 {
  (my MY $self_or_pack) = @_;
  if (ref $self_or_pack) {
    not $self_or_pack->{cf_no_mro_c3}
  } else {
    mro::get_mro($self_or_pack) eq 'c3';
  }
}

#========================================

# These ns-related methods (ensure_...) are called as Class Methods.
# This means you can't touch instance fields.

# Old interface.
# ensure_entns($app_ns, @base_entns)
# returns EntNS for $app_ns with correct inheritance settings.
#
sub ensure_entns {
  my ($mypack, $app_ns, @base_entns) = @_;
  my $entns = $mypack->ensure_supplns(EntNS => $app_ns, \@base_entns
				      , undef, +{no_fields => 1});
  $entns;
}

# New interface.
# ensure_supplns($kind, $app_ns, [@base_suppls], [@base_mains], {%opts})
# returns ${app_ns}::${kind} with correct inheritance.
#
# [@base_suppls] gives base supplemental classes for this supplns.
# [@base_mains] gives (not supplemental but) main classes for this.
#
# If both base_suppls and base_mains is empty, base_mains is derived
# from current @ISA of $app_ns.
#
sub ensure_supplns {
  my ($mypack, $kind, $app_ns, $base_suppls, $base_mains, $opts) = @_;

  my $supplns = join("::", $app_ns, $kind);

  my $sym = do {no strict 'refs'; \*{$supplns}};
  if (*{$sym}{CODE}) {
    # croak "$kind for $app_ns is already defined!";
    return $supplns;
  }

  my $app_ns_filename = do {
    my $sub = $app_ns->can("filename");
    $sub ? ("(For path '".($sub->() // '')."')") : "";
  };

  print STDERR "# First ensure_supplns $kind for $app_ns $app_ns_filename: "
    , terse_dump($base_suppls, $base_mains, $opts), "\n" if DEBUG;

  if (not $base_suppls and not $base_mains) {
    my @isa = list_isa($app_ns);
    print STDERR "# app_ns $app_ns isa: "
      , terse_dump(@isa), "\n" if DEBUG;

    $base_mains = $mypack->should_use_mro_c3
      ? [reverse @isa] : \@isa;
  }

  my @baseclass = (lexpand($base_suppls), map {
    $mypack->ensure_supplns($kind => $_, undef, undef, $opts);
  } lexpand($base_mains));

  if ($mypack->should_use_mro_c3) {
    print STDERR "# $kind - Set mro c3 for $supplns $app_ns_filename since $mypack uses c3\n" if DEBUG;
    mro::set_mro($supplns, 'c3')
  } else {
    print STDERR "# $kind - Keep mro dfs for $supplns $app_ns_filename since $mypack uses dfs\n" if DEBUG;
  }

  # $app_ns が %FIELDS 定義を持たない時(ex YLObjectでもPartialでもない)に限り、
  # YATT::Lite への継承を設定する
  unless (YATT::Lite::MFields->has_fields($app_ns)) {
    # XXX: $mypack への継承にすると、あちこち動かなくなるぜ？なんで？
    print STDERR "# app_ns - Add ISA for '$app_ns' with fields: ",MY,"\n"
      if DEBUG;
    YATT::Lite::MFields->add_isa_to($app_ns, MY)->define_fields($app_ns);
  }

  unless (grep {$_->can($kind)} @baseclass) {
    my $base = try_invoke($app_ns, $kind) // $mypack->can("root_$kind")->();
    ckrequire($base);
    print STDERR "# $kind - Set default base for $supplns <- ($base)\n" if DEBUG;
    if ($mypack->should_use_mro_c3) {
      push @baseclass, $base;
    } else {
      unshift @baseclass, $base;
    }
  }

  do {
    my @cls = uniq @baseclass;
    print STDERR "# $kind - Add ISA for $supplns <- (@cls)\n" if DEBUG;
    YATT::Lite::MFields->add_isa_to($supplns, @cls);
  };
  if (not $opts->{no_fields}) {
    YATT::Lite::MFields->define_fields($supplns);
  }

  set_inc($supplns, 1);

  # $kind() を足すのは最後にしないと、再帰継承に陥る
  unless (my $code = *{$sym}{CODE}) {
    define_const($sym, $supplns);
  } elsif ((my $old = $code->()) ne $supplns) {
    croak "Can't add $kind() to '$app_ns'. Already has $kind as $old!";
  } else {
    # ok.
  }
  $supplns
}

sub list_entns {
  my ($pack, $inspected) = @_;
  map {
    defined(symtab($_)->{'EntNS'}) ? join("::", $_, 'EntNS') : ()
  } list_isa($inspected)
}

# use YATT::Lite qw(Entity); で呼ばれ、
# $callpack に Entity 登録関数を加える.
sub define_Entity {
  my ($myPack, $opts, $callpack, @base) = @_;

  # Entity を追加する先は、 $callpack が Object 系か、 stateless 系かで変化する
  # Object 系の場合は、 ::EntNS を作ってそちらに加え, 同時に YATT() も定義する
  my $is_objclass = is_objclass($callpack);
  my $destns = $is_objclass
    ? $myPack->ensure_entns($callpack, @base)
      : $callpack;

  # 既にあるなら何もしない。... バグの温床にならないことを祈る。
  my $ent = globref($callpack, 'Entity');
  unless (*{$ent}{CODE}) {
    *$ent = sub {
      my ($name, $sub) = @_;
      if ($myPack->add_entity_into($destns, $name, $sub)) {
        print STDERR "# defined entity $name in $destns\n" if DEBUG;
      }
    };
  }

  if ($is_objclass) {
    *{globref($destns, 'YATT')} = *YATT;

    unless ($callpack->can("entity")) {
      *{globref($callpack, "entity")} = $myPack->can('entity');
    }
  }

  return $destns;
}

#
# Note about 'Action' registration mechanism in .htyattrc.pl
#
#  First, *globref() = $action is not enough. Because...
#
#  There are 2 places to hold actions.
#    1. $YATT->{Action}      <= comes from *.ydo
#    2. $vfs_folder->{Item}  <= comes from !yatt:action in templates
#
#  Action in .htyattrc.pl is, special case of 2.
#  Since 2. is managed by yatt vfs, it must be wrapped by Action object
#  so that $vfs->find_part_handler works well.
#
#
#  This is bit complicated because .htyattrc.pl is loaded *BEFORE* $YATT
#  is instantiated. This means "Action => name, $handler" can not touch $YATT
#  at that time. So, I need to delay actual registration until $YATT is created.
#
#  To achieve this, $handler is registered first in %Actions of caller,
#  then installed into actual vfs.
#
# Also note: loading of .htyattrc.pl is handled by Factory.
#
sub ACTION_DICT_SYM () {'Actions'}
sub define_Action {
  my ($myPack, $opts, $callpack) = @_;

  *{globref($callpack, ACTION_DICT_SYM)} = my $action_dict = +{};

  *{globref($callpack, 'Action')} = sub {
    my ($name, $sub) = @_;
    my @caller = my ($callpack, $filename, $lineno) = caller;
    if (defined (my $old = $action_dict->{$name})) {
      croak "Duplicate definition of Action '$name'! previously"
	." at $old->[1][1] line $old->[1][2]\n new at $filename line $lineno\n";
    }
    $action_dict->{$name} = [$sub, \@caller];
  };
}

sub setup_rc_actions {
  (my $self) = @_;
  my $glob = look_for_globref($self, ACTION_DICT_SYM)
    or return;
  my $dict = *{$glob}{HASH};

  my $vfs = $self->get_vfs;
  foreach my $name (keys %$dict) {
    $vfs->add_root_action_handler($name, @{$dict->{$name}});
  }
}

# ここで言う Object系とは、
#   YATT::Lite::Object を継承してるか、
#   又は既に %FIELDS が定義されている class
# のこと
sub is_objclass {
  my ($class) = @_;
  return 1 if UNIVERSAL::isa($class, 'YATT::Lite::Object');
  my $sym = look_for_globref($class, 'FIELDS')
    or return 0;
  *{$sym}{HASH};
}

sub entity {
  (my MY $yatt, my $name) = splice @_, 0, 2;
  my $this = $yatt->EntNS;
  $this->can("entity_$name")->($this, @_);
}

BEGIN {
  MY->define_Entity(undef, MY);
}

#========================================
# Locale gettext support.
#========================================

sub use_encoded_config {
  (my MY $self) = @_;
  $self->{cf_tmpl_encoding}
}

use YATT::Lite::Partial::Gettext;

# Extract (and cache, for later merging) l10n msgs from filelist.
# By default, it merges $filelist into existing locale_cache.
# To get fresh list, explicitly pass $msglist=[].
#
sub lang_extract_lcmsg {
  (my MY $self, my ($lang, $filelist, $msglist, $msgdict)) = @_;

  if (not $msglist and not $msgdict) {
    ($msglist, $msgdict) = $self->lang_msgcat($lang)
  }

  $self->get_trans->extract_lcmsg($filelist, $msglist, $msgdict);
}

sub default_default_lang { 'en' }
sub default_lang {
  (my MY $self) = @_;
  $self->{cf_default_lang} || $self->default_default_lang;
}

#========================================
# Delegation to the core(Translator, which is useless for non-templating.)
#
# Note: these wrappers do not call YATT::Lite::VFS->reset_refresh_mark.
# This means once templates is compiled, it is not updated even if
# they are modified. You can avoid this behavior by
# directly using $YATT->open_trans->xxx instead.
#========================================
foreach
  (qw/find_part
      find_part_from_entns
      find_file
      find_product
      find_renderer
      find_part_handler
      ensure_parsed

      list_items
      list_base
      list_internal_base_folders

      add_to
    /
  ) {
  my $meth = $_;
  *{globref(MY, $meth)} = subname(join("::", MY, $meth)
				  , sub { shift->get_trans->$meth(@_) });
}

sub dump {
  my MY $self = shift;
  # XXX: charset...
  die [200, [$self->secure_text_plain]
       , [map {terse_dump($_)."\n"} @_]];
}

#========================================
# Builtin Entities.
#========================================

sub YATT::Lite::EntNS::entity_template {
  my ($this, $pkg) = @_;
  $YATT->get_trans->find_template_from_package($pkg // $this);
};

sub YATT::Lite::EntNS::entity_stash {
  my $this = shift;
  my $prop = $CON->prop;
  my $stash = $prop->{stash} //= {};
  unless (@_) {
    $stash
  } elsif (@_ > 1) {
    %$stash = @_;
  } elsif (not defined $_[0]) {
    carp "Undefined argument for :stash()";
  } elsif (ref $_[0]) {
    $prop->{stash} = $_[0]
  } else {
    $stash->{$_[0]};
  }
};

sub YATT::Lite::EntNS::entity_mkhidden {
  my ($this) = shift;
  \ join "\n", map {
    my $name = $_;
    map {
      my $v = $_;
      if (ref $v eq 'HASH') {
        map {
          _hidden_input(escape($name."[$_]"), $v->{$_});
        } keys %$v;
      } elsif (ref $v eq 'ARRAY') {
        map {
          _hidden_input(escape($name."[]"), $_);
        } @$v;
      } else {
        _hidden_input(escape($name), $v);
      }
    } $CON->multi_param($name);
  } do {
    if (@_) {
      @_;
    } else {
      $CON->param
    }
  };
};

sub _hidden_input {
  sprintf(qq|<input type="hidden" name="%s" value="%s">|
          , $_[0], escape($_[1]));
}

sub YATT::Lite::EntNS::entity_file_rootname {
  my ($this, $fn) = @_;
  $fn //= $CON->file();
  $fn =~ s/\.\w+$//;
  $fn;
};

sub YATT::Lite::EntNS::entity_app_name {
  my ($this) = @_;
  $YATT->cget('app_name');
};

#----------------------------------------
use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_facade();

1;
