package YATT::Lite::Factory;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Breakpoint;
sub MY () {__PACKAGE__}
use mro 'c3';

use constant DEBUG_FACTORY => $ENV{DEBUG_YATT_FACTORY};
use constant DEBUG_REFCNT => $ENV{DEBUG_YATT_REFCNT};
use if DEBUG_REFCNT, B => qw/svref_2object/;

use 5.010;
use Scalar::Util qw(weaken);
use Encode qw/decode/;

use parent qw/File::Spec YATT::Lite::Site YATT::Lite::NSBuilder/;
use File::Path ();
use File::Basename qw/dirname/;

use YATT::Lite::PSGIEnv;

#----------------------------------------

# Subclass may override this to 0 to revert old behavior.
sub use_sibling_config_dir { 1 }

#----------------------------------------

# Note: Definition of default values are not yet gathered here.
# Some are in YATT::Lite, others are in YATT::Lite::Core, CGen.. and so on.

use YATT::Lite::MFields
([namespace =>
  (doc => "namespace prefix for yatt. (default: [yatt, perl])")]

 , ["^doc_root" =>
    (doc => "Primary template directory")]

 # Note: Don't confuse 'app_rootname' below with 'app_root'.
 # 'app_root' is defined in YATT::Lite::Partial::AppPath.
 #
 , [app_rootname =>
    (doc => "rootname() of app.psgi. Used to find app.site_config.yml")]

 , ["^app_base" =>
    (doc => "Base template dir for all DirApps")]

 , ["^site_prefix" =>
    (doc => "Location prefix for this siteapp")]

 , [index_name =>
    (doc => "Rootname of index template. (default: index)")]

 , [ext_public =>
    (doc => "public file extension for yatt. (default: yatt)")]

 , [ext_private =>
    (doc => "hidden file extension for yatt. (default: ytmpl)")]

 , [header_charset =>
    (doc => "Charset for outgoing HTTP Content-Type. (default: utf-8)")]

 , [tmpl_encoding =>
    (doc => "Perl encoding used while reading yatt templates. (default: 'utf-8')")]

 , [output_encoding =>
    (doc => "Perl encoding used for outgoing response body."
     ." Also this is used to decode incoming request parameters and PATH_INFO."
     ." (default: 'utf-8')")]

 , [render_as_bytes =>
    (doc => "Force render() to return raw bytes. (default: false)")]

 , ["^offline" =>
    (doc => "Whether header should be emitted or not.")]

 , [binary_config   =>
    (doc => "(This may be changed in future release) Whether .htyattconfig.* should be read with encoding or not.")]

 , [no_unicode =>
    (doc => "(Compatibility option) Avoid use of utf8.")]

 , [no_unicode_params =>
    (doc => "(Compatibility option) Avoid encoding conversion of input params.")]

 , [use_subpath =>
    (doc => "pass sub-path_info")]

 , qw/
       allow_missing_dir
       no_preload_app_base

       _tmpldirs
       _loc2yatt
       _path2yatt

       _loc2psgi_re
       _loc2psgi_dict

       _tmpl_cache

       _path2entns
       _entns2vfs_item

       debug_cgen

       only_parse
       config_filetypes

       dont_map_args
       dont_debug_param
       always_refresh_deps
       no_mro_c3

       special_entities
       default_lang
       no_lineinfo
       debug_parser
       check_lineno

       _outer_psgi_app
       _my_psgi_app

       match_argsroute_first
       allow_bare_entity_in_decl
       no_chdir
       /
 , [pagevars =>
    (doc => "Package name of per-page compile-time constants (see YATT::Lite::PageConsts)")]
 , [argmacro =>
    (doc => "Map of argmacro name to Perl module which defines it, or list of such maps optionally paired with namespace like [[ns => {name => Module}], {...}] (see YATT::Lite::ArgMacro)")]
 , [stash_unknown_params_to => 
    (doc => "Stash unknown foreign parameters into this name. Set to 'yatt.unknown_params' when PLACK_ENV is *not* development.")]
 , [body_argument =>
    (doc => "Name of 'body' argument. (default: body)")]
 , [body_argument_type =>
    (doc => "Type of 'body' argument. (default: code)")]
 , [prefer_call_for_entity =>
    (doc => ":name is interpreted as call if appropriate")]
 , [no_conditional_call =>
    (doc => "Disable conditional call (if=/unless= in widget call arguments)")]
);

use YATT::Lite::Util::AsBase qw/-as_base import/;
use YATT::Lite::Util qw/lexpand globref untaint_any ckrequire dofile_in
			lookup_dir fields_hash
			lookup_path
			trim_ext
			secure_text_plain
			psgi_error
                        psgi_text
			globref_default
			define_const
			terse_dump
                        psgi_dump
                        raise_psgi_dump
                        raise_response
                        trimleft_length
                        get_entity_symbol
		       /;

use YATT::Lite::XHF ();

use YATT::Lite::Partial::ErrorReporter;
use YATT::Lite::Partial::AppPath;

use YATT::Lite qw/Entity *SYS *YATT *CON/;
our @EXPORT_OK = qw/*CON/;

use YATT::Lite::Util::CycleDetector qw/Visits/;

#========================================
#
#
#

our $want_object;
sub want_object { $want_object }

sub find_load_factory_script {
  my ($pack, %opts) = @_;
  my $stop_at = delete $opts{stop_at};
  my ($found) = $pack->find_factory_script(delete $opts{dir}
                                           , stop_at => $stop_at)
    or return;
  my $self = $pack->load_factory_script($found)
    or croak "Can't load YATT::Lite::Factory instance from $found";
  $self->configure(%opts);
  $self;
}

sub load_factory_offline {
  shift->find_load_factory_script(offline => 1, @_);
}

sub configure_offline {
  (my MY $self, my $value) = @_;
  $self->{offline} = $value;
  if ($self->{offline}) {
    $self->configure(error_handler => sub {
		       my ($type, $err) = @_;
		       die $err;
		     })
  }
}

#========================================

#
# $class->create_factory_class($fresh_classname)
# Make $fresh_classname inherit Factory.
# Mainly for tests which create many factory classes in single run.
#
sub create_factory_class {
  my ($pack, $factory_class) = @_;

  define_const(globref($factory_class, 'default_app_ns')
               , $factory_class."::YATT");

  $pack->_import_as_base($factory_class);

  $factory_class;
}

sub load_factory_for_psgi {
  my ($pack, $psgi, %default) = @_;
  unless (defined $psgi) {
    croak "Usage: Factory->load_factory_for_psgi(psgi_filename, \%opts)";
  }
  unless (-r $psgi) {
    croak "psgi is not readable: $psgi";
  }
  # GH-260: rel2abs does not collapse "..". Without normalization,
  # "$app_root.config.d" built from ".../t/.." can never exist.
  (my $app_rootname = YATT::Lite::Util::normalize_fs_path($pack->rel2abs($psgi)))
    =~ s/\.psgi$//;

  $default{app_rootname} //= $app_rootname;

  #
  # Assume app_root is safe.
  #
  my $app_root = untaint_any(dirname($app_rootname));
  unless (-d $app_root) {
    croak "Can't find app_root for $psgi";
  }

  $default{doc_root} ||= "$app_root/html";
  if (-d "$app_root/ytmpl") {
    $default{app_base} ||= '@ytmpl';
  }

  my $env = delete $default{environment};

  my (@cf) = $pack->list_app_config_files($app_root, File::Basename::basename($app_rootname));

  if (@cf and $env) {
    croak "Can't use environment and @cf at once!";
  } elsif (@cf > 1) {
    croak "Multiple configuration files!: @cf";
  }

  if ($env) {
    my $config = $pack->config_for_env($app_root, $env);
    return $pack->_with_loading_file($config, sub {
      $pack->new(app_root => $app_root, %default
                 , $pack->load_config($config));
    });
  }

  my MY $self = do {
    if (@cf) {
      $pack->_with_loading_file($cf[0], sub {
                                  $pack->new(app_root => $app_root, %default
                                               , $pack->read_file($cf[0]));
                                })
    } else {
      $pack->new(app_root => $app_root, %default);
    }
  };

  unless ($self->{__after_new_is_called__}) {
    Carp::croak("after_new is not called correctly!");
  }

  $self;
}

sub list_app_config_files {
  my ($pack, $app_root, $app_base) = @_;

  # When psgi is at $app_root/app.psgi,
  # test $app_root.config.d/app.{xhf,yml} and return them if exists.
  # Otherwise list $app_root/app.{xhf,yml}.

  if ($pack->use_sibling_config_dir) {
    my $sibling_config_dir = "$app_root.config.d";
    if (-d $sibling_config_dir) {
      my @cf = $pack->list_config_files("$sibling_config_dir/$app_base");
      return @cf if @cf;
    }
  }

  $pack->list_config_files("$app_root/$app_base");
}

#
# Load Amon2 style config.pl
#
sub config_for_env {
  my ($pack, $app_root, $environment) = @_;
  "$app_root/config/$environment.pl";
}

sub load_config {
  my ($pack, $cf) = @_;
  my $config = dofile_in($pack, $cf);
  unless (defined $config) {
    croak "config script '$cf' returned undef!";
  }
  unless (ref $config eq 'HASH') {
    croak "config script '$cf' doesn't return HASH! $config";
  }
  wantarray ? %$config : $config;
}

#========================================

my ($_n_created, $_n_destroyed);
sub n_created {$_n_created}
sub n_destroyed {$_n_destroyed}
{
  our %sub2self;
  DESTROY {
    (my MY $self) = @_;
    if (DEBUG_FACTORY) {
      if (DEBUG_REFCNT) {
        printf STDERR "# DESTROY %s refcnt=%d\n", $self, svref_2object($self)->REFCNT;
      } else {
        print STDERR "# DESTROY $self\n";
      }
    }
    delete $self->{_my_psgi_app};
    if (my $outer = delete $self->{_outer_psgi_app}) {
      delete $sub2self{$outer};
    }
    ++$_n_destroyed;
  };
  sub to_app_and_forget {
    (my MY $self) = @_;
    my $sub = $self->to_app;
    delete $self->{_my_psgi_app};
    delete $self->{_outer_psgi_app};
    delete $sub2self{$sub};
    $sub;
  }
  sub to_app {
    (my MY $self) = @_;
    if (@_ >= 2) {
      croak "cascade support is dropped.Use wrapped_by(builder {}) instead.";
    }
    $self->{_outer_psgi_app} // do {
      if (my $old = delete $self->{_my_psgi_app}) {
        delete $sub2self{$old};
      }
      $self->prepare_app;
      my $sub = sub { $self->call(@_) };
      $self->{_my_psgi_app} = $sub;
      weaken($self->{_my_psgi_app}) if not $want_object;
      weaken($sub2self{$sub} = $self);
      print STDERR "to_app($self) returned $sub\n" if DEBUG_FACTORY;
      $sub;
    };
  }
  sub wrapped_by {
    my ($self, $outer_app) = @_;
    unless ($self->{_my_psgi_app}) {
      croak "wrapped_by is called without calling Site->to_app";
    }
    delete $sub2self{$self->{_my_psgi_app}};
    $self->{_outer_psgi_app} = $outer_app;
    $sub2self{$outer_app} = $self;
    weaken($self->{_outer_psgi_app}) if not $want_object;
    weaken($sub2self{$outer_app});
    $outer_app;
  }
  sub load_psgi_script {
    my ($pack, $fn) = @_;
    local $want_object = 1;
    local $0 = $fn;
    my $sub = $pack->sandbox_dofile($fn);
    if (ref $sub eq 'CODE') {
      $sub2self{$sub};
    } elsif ($sub->isa($pack) or $sub->isa(MY)) {
      $sub;
    } else {
      die "Unknown load result from: $fn";
    }
  }
  sub prepare_app {
    (my MY $self) = shift;
    $self->maybe::next::method(@_);
  }
  sub prepare_deployment {
    (my MY $self) = shift;
    $self->maybe::next::method(@_);
    $self->{stash_unknown_params_to}
      //= $self->default_stash_unknown_params_to;
  }
  sub finalize_response { shift->maybe::next::method(@_) }

  our $load_count;
  sub sandbox_dofile {
    my ($pack, $file) = @_;
    my $sandbox = sprintf "%s::Sandbox::S%d", __PACKAGE__, ++$load_count;
    my @__result__;
    if (wantarray) {
      @__result__ = dofile_in($sandbox, $file);
    } else {
      $__result__[0] = dofile_in($sandbox, $file);
    }
    my $sym = globref($sandbox, 'filename');
    unless (*{$sym}{CODE}) {
      *$sym = sub {$file};
    }
    wantarray ? @__result__ : $__result__[0];
  }
}

sub load_factory_script {
  my ($pack, $fn) = @_;
  my %was_loaded = map {$_ => 1} keys %INC;
  my $result = eval {
    local $want_object = 1;
    local $0 = $fn;
    local ($FindBin::Bin, $FindBin::Script
	   , $FindBin::RealBin, $FindBin::RealScript);
    FindBin->again if FindBin->can("again");
    if ($fn =~ /\.psgi$/) {
      $pack->load_psgi_script($fn);
    } else {
      $pack->sandbox_dofile($fn);
    }
  };
  my $err = $@;
  # アプリが lib/ に同梱した YATT::Lite が、読み込み中の YATT::Lite と
  # 混ざると、原因の分からないエラーになるので、先に報告する (GH-301)
  if (my @mixed = $pack->list_mixed_yatt_lib(\%was_loaded)) {
    die join("", "Mixed YATT::Lite library roots while loading $fn.\n"
	     , "Running YATT::Lite is from ", $pack->yatt_lib_root, ", but:\n"
	     , map({"  $_->[0] from $_->[1]\n"} @mixed)
	     , "The app may bundle another YATT::Lite in its library path.\n"
	     , $err ? "Original error: $err" : ());
  }
  die $err if $err;
  $result;
}

# YATT/Lite/Factory.pm (この file) を読み込んだ library root
sub yatt_lib_root {
  _inc_root('YATT/Lite/Factory.pm');
}

# $was_loaded に無い (=新たに読み込まれた) YATT::Lite の module のうち、
# yatt_lib_root と違う root から読まれ、しかも yatt_lib_root にも同じ
# module が有るもの (=別版で上書きされたもの) を [$key, $root] で返す。
# アプリ独自の YATT::Lite::* module は対象外。
sub list_mixed_yatt_lib {
  my ($pack, $was_loaded) = @_;
  my $root = $pack->yatt_lib_root // return;
  map {
    my $r = _inc_root($_);
    (defined $r and $r ne $root and -e "$root/$_") ? [$_, $r] : ();
  } grep {
    m{^YATT/Lite[/.]} and not ($was_loaded and $was_loaded->{$_})
  } sort keys %INC;
}

# %INC の値から $key を取り除いた root。$INC{$key} = 1 のような
# 手で登録されたものは undef
sub _inc_root {
  my ($key) = @_;
  my $path = $INC{$key};
  return undef unless defined $path and not ref $path
    and $path =~ s{/\Q$key\E\z}{};
  require Cwd;
  Cwd::realpath($path) // $path;
}

#
# find_factory_script($dir, %opts): search runyatt.psgi / app.psgi
# upward from $dir. With stop_at => $boundary the search never leaves
# $boundary (compared by realpath, so symlinked workspaces behave), and
# returns nothing instead. Tools working from their own cwd leave it
# unset; the language server sets it to the workspace root the client
# named, so a script planted above the workspace is never executed.
#
sub find_factory_script {
  my $pack = shift;
  my ($start, %opts) = @_;
  my $dir = $pack->rel2abs($start // $pack->curdir);
  my $boundary = defined $opts{stop_at}
    ? $pack->_canonical_dir($opts{stop_at}) : undef;
  my @path = $pack->no_upwards($pack->splitdir($dir));
  my $rootdir = $pack->rootdir;
  while (@path and length($dir = $pack->catdir(@path)) > length($rootdir)) {
    if (defined $boundary and not $pack->_dir_is_within($dir, $boundary)) {
      return;
    }
    if (my ($found) = grep {-r} map {"$dir/$_.psgi"} qw(runyatt app)) {
      return $found;
    }
  } continue { pop @path }
  return;
}

sub _canonical_dir {
  my ($pack, $dir) = @_;
  require Cwd;
  my $abs = $pack->rel2abs($dir);
  Cwd::realpath($abs) // $abs;
}

sub _dir_is_within {
  my ($pack, $dir, $boundary) = @_;
  my $real = $pack->_canonical_dir($dir);
  return 1 if $boundary eq $pack->rootdir;
  $real eq $boundary or index($real, "$boundary/") == 0;
}

#========================================
# `use Factory -as_base` in app.psgi will come here.
#
sub _import_as_base {
  my ($myPack, $callpack) = @_;
  $myPack->SUPER::_import_as_base($callpack);
  # To define EntNS in $callpack and set $myPack to @{$callpack::ISA}.
  $myPack->default_default_app->define_Entity(undef, $callpack);
}

# Just to allow writing `use Factory -Entity;` in your app.psgi.
# Not actually required.
sub _import_Entity {
  my ($myPack, $callpack) = @_;
  $myPack->default_default_app->define_Entity(undef, $callpack);
}

#========================================

sub new {
  my ($class) = shift;
  my MY $self = $class->SUPER::new(@_);
  $self->preload_app_base unless $self->{no_preload_app_base};
  ++$_n_created;
  $self;
}

#
# preload app_base (to avoid potential double-loading bug for base loading)
#
sub preload_app_base {
  (my MY $self) = @_;

  foreach my $dir (lexpand($self->{app_base})) {
    next if $dir =~ m{^::};
    $self->load_yatt($self->app_path_expand($dir));
  }
}

sub init_app_ns {
  (my MY $self) = @_;
  $self->SUPER::init_app_ns;

  # EntNS is initialized here.
  # Note: CGEN_perl is not initialized here and delayed until it is required.
  # This helps to avoid loading CGen::Perl for *.ydo in CGI.
  $self->{_default_app}->ensure_entns($self->{_app_ns});
}

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{app_root} //= YATT::Lite::Util::maybe_findbin_bin();
  if (defined $self->{app_root}) {
    $self->{app_root} = YATT::Lite::Util::normalize_fs_path($self->{app_root});
  }
  $self->{index_name} //= $self->default_index_name;
  $self->{ext_public} //= $self->default_ext_public;
  $self->{ext_private} //= $self->default_ext_private;
  if ($self->{no_unicode}) {
    $self->{no_unicode_params} = 1;
    $self->{binary_config} = 1;
    $self->{header_charset}
      //= ($self->{output_encoding} || $self->default_header_charset);
    $self->{output_encoding}
      //= $self->compat_default_output_encoding;
    $self->{render_as_bytes} = 1;
  } else {
    $self->{header_charset}
      //= ($self->{output_encoding} // $self->default_header_charset);
    $self->{tmpl_encoding}
      //= ($self->{output_encoding} // $self->default_tmpl_encoding);
    $self->{output_encoding} //= $self->default_output_encoding;
  }
  $self->{use_subpath} //= 1;

  $self->{always_refresh_deps} //= $self->default_always_refresh_deps;

  $self->{body_argument} //= $self->default_body_argument;
  $self->{body_argument_type} //= $self->default_body_argument_type;

  # prepare_app is too late to set delegated params
  if (($ENV{PLACK_ENV} // '') ne 'development') {
    $self->prepare_deployment;
  }
}

sub compat_default_output_encoding { '' }
sub default_output_encoding { 'utf-8' }
sub default_header_charset  { 'utf-8' }
sub default_tmpl_encoding   { 'utf-8' }
sub default_index_name { 'index' }
sub default_ext_public {'yatt'}
sub default_ext_private {'ytmpl'}
sub default_stash_unknown_params_to {'yatt.unknown_params'}
sub default_always_refresh_deps { 1 }

sub default_body_argument { 'body' }
sub default_body_argument_type { 'code' }

sub _after_after_new {
  (my MY $self) = @_;
  $self->SUPER::_after_after_new;

  if ($self->{doc_root}) {
    # GH-260: keep doc_root textually consistent with the normalized
    # app_root; rel_app_name relies on prefix-length arithmetic.
    $self->{doc_root} = YATT::Lite::Util::normalize_fs_path($self->{doc_root});
  }
  if (not $self->{allow_missing_dir}
      and $self->{doc_root}
      and not -d $self->{doc_root}) {
    croak "document_root '$self->{doc_root}' is missing!";
  }
  if ($self->{doc_root}) {
    trim_slash($self->{doc_root});
  }
  # XXX: $self->{tmpldirs}

  $self->{site_prefix} //= "";

  $self->{_tmpldirs} = [];
  if (my $dir = $self->{doc_root}) {
    push @{$self->{_tmpldirs}}, $dir;
    my $refcnt;
    if (DEBUG_REFCNT) {
      $refcnt = svref_2object($self)->REFCNT;
    }
    $self->get_yatt('/');
    if (DEBUG_REFCNT) {
      if (svref_2object($self)->REFCNT != $refcnt) {
        croak "Reference count of $self is increased from $refcnt to "
          . svref_2object($self)->REFCNT . "!";
      }
    }
  }
  $self;
}

#========================================

sub render {
  my MY $self = shift;
  my $raw_bytes = $self->render_encoded(@_);
  if ($self->{render_as_bytes}) {
    $raw_bytes;
  } else {
    decode(utf8 => $raw_bytes);
  }
}

sub parse_path_info {
  (my MY $self, my ($reqrec)) = @_;
  # [$path_info, $subpage, $action]
  my ($path_info, @rest) = ref $reqrec ? @$reqrec : $reqrec;

  $path_info =~ s,^/*,/,;

  my ($tmpldir, $loc, $file, $trailer, $is_index)
    = my @pi = $self->lookup_split_path_info($path_info);
  unless (@pi) {
    return;
  }

  ($path_info, $tmpldir, $loc,
   (@rest ? [$file, @rest] : $file),
   , $self->pi_to_connection_quad(\@pi)
   );
}

sub prepare_processing_context {
  (my MY $self, my ($reqrec, $args)) = @_;

  my ($path_info, $tmpldir, $loc, $widgetSpec, @rest)
    = $self->parse_path_info($reqrec) or do {
      die "No such location: ".terse_dump($reqrec);
    };

  my $dh = $self->get_lochandler(map {untaint_any($_)} $loc, $tmpldir) or do {
    die "No such directory: $path_info";
  };

  my $con = $self->make_connection
  (
    undef, @rest,
    , yatt => $dh, noheader => 1, path_info => $path_info,
    , encoding => $self->{output_encoding}
    , $self->make_debug_params($reqrec, $args)
  );

  ($dh, $con, $widgetSpec);
}

sub render_encoded {
  (my MY $self, my ($reqrec, $args, @opts)) = @_;

  my ($dh, $con, $widgetSpec) = $self->prepare_processing_context($reqrec, $args);

  $self->render_into_context($dh, $con, $widgetSpec, $args, @opts);

  $con->buffer;
}

sub render_into {
  (my MY $self, my ($con, $reqrec, $args, @opts)) = @_;

  my ($path_info, $tmpldir, $loc, $widgetSpec, @rest)
    = $self->parse_path_info($reqrec) or do {
      die "No such location: ".terse_dump($reqrec);
    };

  my $dh = $self->get_lochandler(map {untaint_any($_)} $loc, $tmpldir) or do {
    die "No such directory: $path_info";
  };

  $con->configure(yatt => $dh);

  $self->render_into_context($dh, $con, $widgetSpec, $args, @opts);
}

#
# Common context wrapper for the render path: sets $SYS/$YATT/$CON,
# runs before/after_dirhandler (site_config entities) and the chdir
# guard, but does NOT install the __DIE__/__WARN__ traps - that is the
# web handle path's intentional distinction (perl -d friendliness).
# GH-267
#
sub render_into_context {
  (my MY $self, my ($dh, $con, $widgetSpec, $args, @opts)) = @_;

  local ($SYS, $YATT, $CON) = ($self, $dh, $con);

  $self->before_dirhandler($dh, $con, lexpand($widgetSpec));

  my $chdir_guard = $dh->chdir_guard;

  $self->invoke_dirhandler
  (
    $dh,
   , render_into => $con
   , $widgetSpec
   , $args, @opts
  );

  $self->after_dirhandler($dh, $con, lexpand($widgetSpec));

  YATT::Lite::Util::try_invoke($con, 'flush_headers');
}

sub make_connection_for {
  (my MY $self, my ($reqrec, $args, @other)) = @_;

  my ($path_info, $tmpldir, $loc, $widgetSpec, @rest)
    = $self->parse_path_info($reqrec);

  $self->make_connection
  (
    undef, @rest,
    , noheader => 1, path_info => $path_info,
    , encoding => $self->{output_encoding},
    , $self->make_debug_params($reqrec, $args),
    , @other,
  );
}

sub lookup_split_path_info {
  (my MY $self, my $path_info) = @_;
  lookup_path($path_info
	      , $self->{_tmpldirs}
	      , $self->{index_name}
              , $self->{ext_public}
	      , $self->{use_subpath});
}

#========================================

sub K_MOUNT_MATCH () { "__yatt" }

sub lookup_psgi_mount {
  (my MY $self, my $path_info) = @_;
  $self->{_loc2psgi_re} // $self->rebuild_psgi_mount;
  $path_info =~ $self->{_loc2psgi_re}
    or return;
  my @mount_match = grep {/^@{[K_MOUNT_MATCH()]}/o} keys %+
    or return;
  if (@mount_match >= 2) {
    croak "Multiple match found for psgi_mount: \n"
      . join("\n  ", map {$self->{_loc2psgi_dict}{$_}[0]} @mount_match);
  }

  my $path_prefix = $+{$mount_match[0]};

  my $item = $self->{_loc2psgi_dict}{$path_prefix};

  wantarray ? @{$item}[1..$#$item] : $item->[2];
}

sub mount_psgi {
  (my MY $self, my ($path_prefix, $app, @opts)) = @_;
  unless (defined $path_prefix) {
    croak "path_prefix is empty! mount_psgi(path_prefix, psgi_app)";
  }
  if (not ref $path_prefix) {
    $path_prefix =~ s,^/*,/,;
  }
  my $dict = $self->{_loc2psgi_dict} //= +{};
  my $key = K_MOUNT_MATCH() . (keys %$dict);
  (my $strip = $path_prefix) =~ s,/\z,,;
  $dict->{$path_prefix} = [$key => $strip => $app, @opts];

  undef $self->{_loc2psgi_re};

  # For cascading call
  $self;
}

sub rebuild_psgi_mount {
  (my MY $self) = @_;
  my @re;
  foreach my $path_prefix (sort {length($b) <=> length($a)}
                             keys %{$self->{_loc2psgi_dict} //= +{}}) {
    my ($key, undef, $app) = @{$self->{_loc2psgi_dict}{$path_prefix}};
    push @re, qr{(?<$key>$path_prefix)};
  }
  my $all = join("|", @re);
  $self->{_loc2psgi_re} = qr{^(?:$all)};
}

sub psgi_file_app {
  my ($pack, $path) = @_;
  require Plack::App::File;
  Plack::App::File->new(root => $path)->to_app;
}

sub mount_static {
  (my MY $self, my ($location, $realpath)) = @_;
  my $app = ref $realpath eq 'CODE' ? $realpath
    : $self->psgi_file_app($realpath);
  $self->mount_psgi($location, $app);
}

#========================================

sub mount_action {
  (my MY $self, my ($path_info, $action)) = @_;
  if (my $ref = ref $path_info) {
    croak "mount_action doesn't support $ref path_info, sorry";
  }
  my ($tmpldir, $loc, $file, $trailer, $is_index)
    = my @pi = $self->lookup_split_path_info($path_info);
  unless (@pi) {
    croak "Can't find acutal directory for $path_info";
  }
  unless ($is_index) {
    croak "Conflicting mount_action($path_info) with file=$file\n";
  }
  my $realdir = $tmpldir.$loc;
  my $dh = $self->get_dirhandler($realdir);
  $dh->set_action_handler($trailer, $action);

  # For cascading call.
  $self;
}

#========================================

sub Connection () {'YATT::Lite::Connection'};

sub make_simple_connection {
  (my MY $self, my ($quad, @rest)) = @_;
  my @params = $self->pi_to_connection_quad($quad);
  $self->make_connection(undef, @params, @rest);
}

sub pi_to_connection_quad {
  (my MY $self, my ($pi)) = @_;
  my ($tmpldir, $loc, $file, $trailer, $is_index, $request_file) = @$pi;
  my $virtdir = "$self->{doc_root}$loc";
  my $realdir = "$tmpldir$loc";
  # GH-251: When request_file is not given (e.g. synthetic quads),
  # default to the canonical (extension-less) form.
  $request_file //= $is_index ? '' : trim_ext($file, $self->{ext_public});
  $self->connection_quad([$virtdir, $loc, $file, $trailer, $request_file]);
}

sub make_debug_params {
  (my MY $self, my ($reqrec, $args)) = @_;
  ();
}

sub make_connection {
  (my MY $self, my ($fh, @params)) = @_;
  require YATT::Lite::Connection;
  $self->Connection->create(
    $fh, @params, system => $self, root => $self->{doc_root}
 );
}

sub finalize_connection {}

sub connection_param {
  croak "Use of YATT::Lite::Factory::connection_param is deprecated!\n";
}
sub connection_quad {
  (my MY $self, my ($quad)) = @_;
  my ($virtdir, $loc, $file, $subpath, $request_file) = @$quad;
  (dir => $virtdir
   , location => $loc
   , file => $file
   , subpath => $subpath
   , (defined $request_file ? (request_file => $request_file) : ()));
}

#========================================
#
# Hook for subclassing
#
sub run_dirhandler {
  (my MY $self, my ($dh, $con, $file)) = @_;
  local ($SYS, $YATT, $CON) = ($self, $dh, $con);
  $self->before_dirhandler($dh, $con, $file);
  my $result = $self->invoke_dirhandler(
    $dh,
    handle => $dh->cut_ext($file), $con, $file
  );
  $self->after_dirhandler($dh, $con, $file);
  if (defined $result
      and (ref $result eq 'CODE'
           or ref $result eq 'ARRAY' and @$result == 3)) {
    $self->raise_response($result)
  }
}

sub before_dirhandler { &maybe::next::method; }
sub after_dirhandler  { &maybe::next::method; }

sub invoke_dirhandler {
  (my MY $self, my ($dh, $method, @args)) = @_;
  $dh->with_system($self, $method, @args);
}

sub invoke_sub_in {
  (my MY $self, my ($reqrec, $args, $sub, @rest)) = @_;

  my $wantarray = wantarray;

  my ($dh, $con, $widgetSpec)
    = $self->prepare_processing_context($reqrec, $args);

  local ($SYS, $YATT, $CON) = ($self, $dh, $con);

  $self->before_dirhandler($dh, $con, lexpand($widgetSpec));

  my @result;
  if ($wantarray) {
    @result = $sub->($dh, $con, @rest);
  } else {
    $result[0] = $sub->($dh, $con, @rest);
  }

  $self->after_dirhandler($dh, $con, lexpand($widgetSpec));

  YATT::Lite::Util::try_invoke($con, 'flush_headers');

  $wantarray ? @result : $result[0];
}

#========================================

sub get_lochandler {
  (my MY $self, my ($location, $tmpldir)) = @_;
  $tmpldir //= $self->{doc_root};
  $self->get_yatt($location) || do {
    $self->{_loc2yatt}{$location} = $self->load_yatt("$tmpldir$location");
  };
}

# location => yatt (dirhandler, dirapp)

sub get_yatt {
  (my MY $self, my $loc) = @_;
  if (my $yatt = $self->{_loc2yatt}{$loc}) {
    return $yatt;
  }
#  print STDERR Carp::longmess("get_yatt for $loc"
#			      , YATT::Lite::Util::terse_dump($self->{_tmpldirs}));
  my ($realdir, $basedir) = lookup_dir(trim_slash($loc), $self->{_tmpldirs});
  unless ($realdir) {
    $self->error("Can't find template directory for location '%s'", $loc);
  }
  $self->{_loc2yatt}{$loc} = $self->load_yatt($realdir, $basedir);
}

# phys-path => yatt

*get_dirhandler = *load_yatt; *get_dirhandler = *load_yatt;

sub load_yatt {
  (my MY $self, my ($path, $basedir, $visits, $from)) = @_;

  unless (defined $path and $path ne '') {
    croak "empty path for load_yatt!"
  }

  $path = $self->rel2abs($path, $self->{app_root});
  if (my $yatt = $self->{_path2yatt}{$path}) {
    return $yatt;
  }
  unless (-e $path) {
    croak "Can't load YATT directory '$path'! No such directory!";
  }
  if (not $visits) {
    $visits = Visits->start($path);
  } elsif (my $preds = $visits->check_cycle($path, $from)) {
    $self->error("Template config error! base has cycle!:\n     %s\n"
		 , join "\n  -> ", $from, @$preds);
  }
  #-- DFS-visits --
  if (not $self->{allow_missing_dir} and not -d $path) {
    croak "Can't find '$path'!";
  }
  if (my (@cf) = $self->list_config_files(untaint_any($path)."/.htyattconfig")) {
    $self->error("Multiple configuration files!", @cf) if @cf > 1;
    _with_loading_file {$self} $cf[0], sub {
      $self->build_yatt($path, $basedir, $visits, $self->read_file($cf[0]));
    };
  } else {
    $self->build_yatt($path, $basedir, $visits);
  }
}

sub build_yatt {
  (my MY $self, my ($path, $basedir, $visits, %opts)) = @_;
  trim_slash($path);

  my $app_name = $self->app_name_for($path, $basedir);

  #
  # base package と base vfs object の決定
  #
  my (@basepkg, @basevfs);
  $self->_list_base_spec_in($path, delete $opts{base}, $visits
			    , \@basepkg, \@basevfs);

  my $app_ns = $self->buildns(my @log = (INST => \@basepkg, $path));

  print STDERR "# Factory::buildns("
    , terse_dump(@log), ") => $app_ns\n" if DEBUG_FACTORY;

  my $has_rc;
  if ($has_rc = (-e (my $rc = "$path/.htyattrc.pl"))) {
    # Note: This can do "use fields (...)"
    dofile_in($app_ns, $rc);

    print STDERR "# Loaded: $rc\n" if DEBUG_FACTORY;
  }

  my @vfs_opts;
  if (defined(my $prefix = $self->page_prefix_for($path))) {
    push @vfs_opts, page_prefix => $prefix;
  }

  my @args = (vfs => [dir => $path
		      , entns => $self->{_path2entns}{$path}
		      , encoding => $self->{tmpl_encoding}
                      , @vfs_opts
		      , @basevfs ? (base => \@basevfs) : ()]
	      , dir => $path
	      , app_ns => $app_ns
	      , app_name => $app_name
	      , factory => $self

	      # XXX: Design flaw! Use of tmpl_cache will cause problem.
	      # because VFS->create for base do not respect Factory->get_yatt.
	      # To solve this, I should redesign all Factory/VFS related stuffs.
	      , tmpl_cache => $self->{_tmpl_cache} //= {}
	      , entns2vfs_item => $self->{_entns2vfs_item} //= {}

	      , $self->configparams_for(fields_hash($app_ns)));

  if (my @unk = $app_ns->YATT::Lite::Object::cf_unknowns(%opts)) {
    $self->error("Unknown option for yatt app '%s': '%s'"
		 , $path, join(", ", @unk));
  }

  printf STDERR "build_yatt.before_app_ns_new: refcnt=%d\n", svref_2object($self)->REFCNT if DEBUG_REFCNT && DEBUG_FACTORY;
  my $yatt = $self->{_path2yatt}{$path} = $app_ns->new(@args, %opts);
  printf STDERR "build_yatt.after_app_ns_new: refcnt=%d\n", svref_2object($self)->REFCNT if DEBUG_REFCNT && DEBUG_FACTORY;

  unless ($yatt->after_new_is_called) {
    Carp::croak("after_new is not called for $path!");
  }

  if ($has_rc) {
    print STDERR "# setting up rc actions\n" if DEBUG_FACTORY;
    $yatt->setup_rc_actions;
  }

  $yatt;
}

sub _list_base_spec_in {
  (my MY $self, my ($in, $desc, $visits, $basepkg, $basevfs)) = @_;

  print STDERR "# Factory::list_base_in("
    , terse_dump($in, $desc, $self->{app_base}), ")\n" if DEBUG_FACTORY;

  #
  # YATT::Lite->base can be either specified explicitly
  # or implicitly copied from YATT::Lite::Factory->app_base.
  #
  # Later case can lead circular inheritance for app_base itself.
  # To avoid this, $is_implicit flag is used.
  #
  my $is_implicit = not defined $desc;

  $desc //= $self->{app_base};

  #
  # First item in base is treated *primary* base.
  # Rest of them are treated mixin.
  #
  my ($base, @mixin) = lexpand($desc)
    or return;

  #
  # This builds [$package => $path] pairs and separately store
  # as primary and mixin.
  #
  my (@primary_pair, @mixin_pair);
  foreach my $task ([1, $base], [0, @mixin]) {
    my ($is_primary, @spec) = @$task;
    foreach my $basespec (@spec) {
      my ($pkg, $yatt);
      if ($basespec =~ /^::(.*)/) {
	ckrequire($1);
	push @{$is_primary ? \@primary_pair : \@mixin_pair}, [$1, undef];
      } elsif (my $realpath = $self->app_path_find_dir_in($in, $basespec)) {

	if ($is_implicit) {
	  #
	  # Simply drop circular inheritance for implicit case.
	  #
	  next if $visits->has_node($realpath);
	}
	$visits->ensure_make_node($realpath);

	push @{$is_primary ? \@primary_pair : \@mixin_pair}, [undef, $realpath];
      } else {
	$self->error("Invalid base spec: %s", $basespec);
      }
    }
  }

  #
  # This builds $basevfs for YATT::Lite::VFS::Folder::vivify_base_descs()
  # This preallocates YATT::Lite and its entns for each realpath.
  #
  foreach my $pair (@primary_pair, @mixin_pair) {
    my ($pkg, $dir) = @$pair;
    next unless $dir;
    my $yatt = $self->load_yatt($dir, undef, $visits, $in);
    $pair->[0] = ref $yatt;
    my $realdir = $yatt->cget('dir');
    push @$basevfs, [dir => $realdir, entns => $self->{_path2entns}{$realdir}];
  }

  #
  # This builds $basepkg for buildns()
  #
  push @$basepkg, map {defined $_->[0] ? $_->[0] : ()} do {
    if (not $self->{no_mro_c3}) {
      my %known_pkg;
      foreach my $pair (grep {defined $_->[0]} @primary_pair) {
	$known_pkg{$_} = 1 for @{mro::get_linear_isa($pair->[0])};
      }
      (grep(!$_->[0] || !$known_pkg{$_->[0]}, @mixin_pair)
       , @primary_pair);
    } else {
      @primary_pair;
    }
  };

  $visits->finish_node($in);
}

sub get_yatt_by_entns {
  (my MY $self, my $entns) = @_;
  $self->{_entns2vfs_item}{$entns};
}

#========================================

sub buildns {
  (my MY $self, my ($kind, $baselist, $path)) = @_;
  my $newns = $self->SUPER::buildns($kind, $baselist, $path);

  # EntNS を足し、Entity も呼べるようにする。
  $self->{_default_app}->define_Entity(undef, $newns
				      , map {$_->EntNS} @$baselist);

  # instns には MY を定義しておく。
  my $my = globref($newns, 'MY');
  unless (*{$my}{CODE}) {
    define_const($my, $newns);
  }

  # もし $newns の EntNS が Factory(SiteApp, app.psgi) の EntNS を継承していない
  # なら、継承する
  unless ($newns->EntNS->isa($self->EntNS)) {
    push @{globref_default(globref($newns->EntNS, 'ISA')
			   , [])}, $self->EntNS;
  }

  # basevfs に entns を渡せるように。
  $self->{_path2entns}{$path} = $newns->EntNS;

  $newns;
}

sub _cf_delegates {
  qw(no_unicode
     no_unicode_params
     output_encoding
     header_charset
     tmpl_encoding
     render_as_bytes
     debug_cgen
     at_done
     app_root
     namespace
     index_name
     ext_public
     ext_private
     only_parse
     use_subpath
     dont_map_args
     dont_debug_param
     always_refresh_deps
     no_mro_c3
     die_in_error
     special_entities
     default_lang
     no_lineinfo
     ext_pattern
     debug_parser
     check_lineno
     match_argsroute_first
     stash_unknown_params_to
     body_argument
     body_argument_type
     prefer_call_for_entity
     no_conditional_call
     allow_bare_entity_in_decl
     no_chdir
     pagevars
     argmacro
  );
}

sub configparams_for {
  (my MY $self, my $hash) = @_;
  # my @base = map { [dir => $_] } lexpand($self->{tmpldirs});
  # (@base ? (base => \@base) : ())

  my $debugging = YATT::Lite::Util::is_debugging();
  if ($debugging) {
    print STDERR "# Note: Factory->die_in_error is turned off for debugging\n";
  }

  (
   $self->cf_delegate_known(0, $hash, $self->_cf_delegates)
   , (exists $hash->{error_handler}
      ? (error_handler => \ $self->{error_handler}) : ())
   , die_in_error => ! $debugging
 );
}

# XXX: Should have better interface.
sub error {
  (my MY $self, my ($fmt, @args)) = @_;
  croak sprintf $fmt, @args;
}

#========================================

sub app_name_for {
  (my MY $self, my ($path, $basedir)) = @_;
  ensure_slash($path);
  if ($basedir) {
    ensure_slash($basedir);
    $self->_extract_app_name($path, $basedir)
      // $self->error("Can't extract app_name path=%s, base=%s"
		      , $path, $basedir);
  } else {
    foreach my $tmpldir (lexpand($self->{_tmpldirs})) {
      ensure_slash(my $cp = $tmpldir);
      if (defined(my $app_name = $self->_extract_app_name($path, $cp))) {
	# Can be empty string.
	return $app_name;
      }
    }
    return '';
  }
}

# Prefix of page names in the directory $path: '' for a template dir
# itself, 'sub/' for its subdirectory, undef when $path is not under
# any template dir (ie. not a page directory, eg. ytmpl).
sub page_prefix_for {
  (my MY $self, my $path) = @_;
  ensure_slash($path);
  foreach my $tmpldir (lexpand($self->{_tmpldirs})) {
    ensure_slash(my $cp = $tmpldir);
    if (defined(my $rel = $self->_extract_app_name($path, $cp))) {
      return $rel eq '' ? '' : "$rel/";
    }
  }
  return undef;
}

sub _extract_app_name {
  (my MY $self, my ($path, $basedir)) = @_;
  my ($bs, $name) = unpack('A'.length($basedir).'A*', $path);
  return undef unless $bs eq $basedir;
  $name =~ s{[/\\]+$}{};
  $name;
}

#========================================

sub read_file {
  (my MY $self, my $fn) = @_;
  my ($ext) = $fn =~ /\.(\w+)$/
    or croak "Can't extract fileext from filename: $fn";
  my $sub = $self->can("read_file_$ext")
    or croak "filetype $ext is not supported: $fn";
  $sub->($self, $fn);
}

sub default_config_filetypes {qw/xhf yml/}
sub config_filetypes {
  (my MY $self) = @_;
  if (ref $self and my $item = $self->{config_filetypes}) {
    lexpand($item)
  } else {
    $self->default_config_filetypes
  }
}

sub find_unique_config_file {
  (my MY $self, my ($base_path, @rest)) = @_;
  return if grep {not defined} $base_path, @rest;
  my @cf = $self->list_config_files(join("", $base_path, @rest));
  $self->error("Multiple configuration files!", @cf) if @cf > 1;
  return $cf[0] if @cf;
  return;
}

sub list_config_files {
  (my MY $self, my $base_path) = @_;
  map {
    my $cf = "$base_path.$_";
    -e $cf ? $cf : ()
  } $self->config_filetypes
}

sub read_file_xhf {
  (my MY $self, my $fn) = @_;
  my $bytes_semantics = ref $self && $self->{binary_config};
  $self->YATT::Lite::XHF::read_file_xhf
    ($fn, bytes => $bytes_semantics);
}

sub read_file_yml {
  (my MY $self, my $fn) = @_;
  require YAML::Tiny;
  my $yaml = YAML::Tiny->read($fn);
  unless (defined $yaml) { # YAML::Tiny old version doesn't raise error.
    Carp::croak(YAML::Tiny->errstr . ""); # errstr is deprecated, but only old version can reach this line.
  }
  wantarray ? lexpand($yaml->[0]) : $yaml->[0];
}

#========================================

sub trim_slash {
  $_[0] =~ s,/*$,,;
  $_[0];
}

sub ensure_slash {
  unless (defined $_[0] and $_[0] ne '') {
    $_[0] = '/';
  } else {
    my $abs = File::Spec->rel2abs($_[0]);
    my $sep = $^O =~ /^MSWin/ ? "\\" : "/";
    $abs =~ s{(?:\Q$sep\E)?$}{$sep}; # Should end with path-separator.
    $_[0] = $abs;
  }
}

#========================================
{
  Entity site_prefix => sub {
    my MY $self = $SYS;
    $self->{site_prefix};
  };
}


1;
