package YATT::Lite; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.010; no if $] >= 5.017011, warnings => "experimental";

use Carp qw(carp croak confess);
our $VERSION = '0.101';
#use mro 'c3';

use Scalar::Util qw/weaken/;

#
# YATT Internalへの Facade. YATT の初期化パラメータの保持者でもある。
#
use parent qw/YATT::Lite::Object File::Spec/;
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
	      cf_app_ns entns
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

	      cf_default_lang

	      cf_path2entns
	    /;

MY->cf_mkaccessors(qw/app_name/);

# Entities を多重継承する理由は import も継承したいから。
# XXX: やっぱり、 YATT::Lite には固有の import を用意すべきではないか?
#   yatt_default や cgen_perl を定義するための。
use YATT::Lite::Entities -as_base, qw(*YATT *CON *SYS);

# For error, raise, DONE. This is inserted to ISA too.
use YATT::Lite::Partial::ErrorReporter;

use YATT::Lite::Partial::AppPath;

use YATT::Lite::Util qw/globref lexpand extname ckrequire terse_dump escape
			set_inc ostream try_invoke list_isa symtab
			look_for_globref
			subname ckeval
			secure_text_plain
			define_const
		       /;

sub Facade () {__PACKAGE__}
sub default_app_ns {'MyApp'}
sub default_trans {'YATT::Lite::Core'}
sub default_export {(shift->SUPER::default_export, qw(Entity *SYS *CON))}
sub default_index_name { '' }
sub default_ext_public {'yatt'}
sub default_ext_private {'ytmpl'}

sub with_system {
  (my MY $self, local $SYS, my $method) = splice @_, 0, 3;
  $self->$method(@_);
}

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{cf_index_name} //= "";
  $self->{cf_ext_public} //= $self->default_ext_public;
  $self->{cf_ext_private} //= $self->default_ext_private;
  weaken($self->{cf_factory});
}

# XXX: kludge!
sub create_neighbor {
  (my MY $self, my ($dir)) = @_;
  my MY $yatt = $self->{cf_factory}->load_yatt($dir);
  $yatt->get_trans->root;
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
  $sub->($YATT, $CON, $file);

  try_invoke($CON, 'flush_headers');

  $CON;
}

sub render {
  my MY $self = shift;
  my $buffer; {
    my $con = $SYS
      ? $SYS->make_connection(undef, buffer => \$buffer, yatt => $self)
	: ostream(\$buffer);
    $self->render_into($con, @_);
  }
  $buffer;
}

sub render_into {
  local ($YATT, $CON) = splice @_, 0, 2;
  $YATT->open_trans->render_into($CON, @_);
  try_invoke($CON, 'flush_headers');
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
  # XXX: http result code:
  print $con "Forbidden filetype: $file";
}

#----------------------------------------

sub prepare_part_handler {
  (my MY $self, my ($con, $file)) = @_;

  my $trans = $self->open_trans;

  my $mapped = [$file, my ($type, $item) = $self->parse_request_sigil($con)];
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

  my @args; @args = $part->reorder_cgi_params($con)
    unless $self->{cf_dont_map_args} || $part->isa($trans->Action);

  ($part, $sub, $pkg, \@args);
}

sub parse_request_sigil {
  (my MY $self, my ($con)) = @_;
  my ($subpage, $action);
  # XXX: url_param
  foreach my $name (grep {defined} $con->param()) {
    my ($sigil, $word) = $name =~ /^([~!])(\1|\w*)$/
      or next;
    # If $name in ('~~', '!!'), use value.
    my $new = $word eq $sigil ? $con->param($name) : $word;
    # else use $word from ~$word.
    # Note: $word may eq ''. This is for render_/action_.
    given ($sigil) {
      when ('~') {
	if (defined $subpage) {
	  $self->error("Duplicate subpage request! %s vs %s"
		       , $subpage, $new);
	}
	$subpage = $new;
      }
      when ('!') {
	if (defined $action) {
	  $self->error("Duplicate action! %s vs %s"
		       , $action, $new);
	}
	$action = $new;
      }
      default {
	croak "Really?";
      }
    }
  }
  if (defined $subpage and defined $action) {
    # XXX: Reserved for future use.
    $self->error("Can't use subpage and action at one time: %s vs %s"
		 , $subpage, $action);
  } elsif (defined $subpage) {
    (page => $subpage);
  } elsif (defined $action) {
    (action => $action);
  } else {
    ();
  }
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
     , entns => $self->{entns}
     , @rest
     # XXX: Should be more extensible.
     , $self->cf_delegate_defined(qw/namespace base
				     die_in_error tmpl_encoding
				     debug_cgen debug_parser
				     special_entities no_lineinfo check_lineno
				     index_name
				     ext_public
				     ext_private
				     rc_script
				     lcmsg_sink
				     only_parse
				     always_refresh_deps
				    /));
}

sub _before_after_new {
  (my MY $self) = @_;
  $self->{cf_app_ns} //= $self->default_app_ns;
  $self->{entns} = $self->ensure_entns($self->{cf_app_ns});
}

#========================================
# Entity
#========================================

sub root_EntNS { 'YATT::Lite::Entities' }

# ${app_ns}::EntNS を作り、(YATT::Lite::Entities へ至る)継承関係を設定する。
# $app_ns に EntNS constant を追加する。
# 複数回呼ばれた場合、既に定義済みの entns を返す

sub ensure_entns {
  my ($mypack, $app_ns, @baseclass) = @_;
  my $entns = "${app_ns}::EntNS";

  my $sym = do {no strict 'refs'; \*{$entns}};
  if (*{$sym}{CODE}) {
    # croak "EntNS for $app_ns is already defined!";
    return $entns;
  }

  # mro::set_mro($entns, 'c3'); # XXX: Should change to c3, but...

  # $app_ns が %FIELDS 定義を持たない時(ex YLObjectでもPartialでもない)に限り、
  # YATT::Lite への継承を設定する
  unless (YATT::Lite::MFields->has_fields($app_ns)) {
    # XXX: $mypack への継承にすると、あちこち動かなくなるぜ？なんで？
    YATT::Lite::MFields->add_isa_to($app_ns, MY)->define_fields($app_ns);
  }

  unless (grep {$_->can("EntNS")} @baseclass) {
    my $base = try_invoke($app_ns, 'EntNS') // $mypack->root_EntNS;
    # print "insert base '$base' for entns $entns\n";
    unshift @baseclass, $base;
  }

  # print "entns $entns should inherits: @baseclass\n";
  YATT::Lite::MFields->add_isa_to($entns, @baseclass);

  set_inc($entns, 1);

  # EntNS() を足すのは最後にしないと、再帰継承に陥る
  unless (my $code = *{$sym}{CODE}) {
    define_const($sym, $entns);
  } elsif ((my $old = $code->()) ne $entns) {
    croak "Can't add EntNS() to '$app_ns'. Already has EntNS as $old!";
  } else {
    # ok.
  }
  $entns
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
      my $longname = join "::", $destns, "entity_$name";
      subname($longname, $sub);
      print "defining entity_$name in $destns\n" if $ENV{DEBUG_ENTNS};
      *{globref($destns, "entity_$name")} = $sub;
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
#========================================
foreach
  (qw/find_part
      find_file
      find_product
      find_renderer
      find_part_handler
      ensure_parsed

      list_items

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
    my $esc = escape($name);
    map {
      sprintf(qq|<input type="hidden" name="%s" value="%s"/>|
	      , $esc, escape($_));
    } $CON->param($name);
  } @_;
};

sub YATT::Lite::EntNS::entity_file_rootname {
  my ($this, $fn) = @_;
  $fn //= $CON->file();
  $fn =~ s/\.\w+$//;
  $fn;
};

#----------------------------------------
use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_facade();

1;
