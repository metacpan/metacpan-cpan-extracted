package YATT::Lite::Factory;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Breakpoint;
sub MY () {__PACKAGE__}

use constant DEBUG_FACTORY => $ENV{DEBUG_YATT_FACTORY};

use 5.010;
use Scalar::Util qw(weaken);
use Encode qw/decode/;

use parent qw/File::Spec YATT::Lite::NSBuilder/;
use File::Path ();
use File::Basename qw/dirname/;

use YATT::Lite::PSGIEnv;

# Note: Definition of default values are not yet gathered here.
# Some are in YATT::Lite, others are in YATT::Lite::Core, CGen.. and so on.

use YATT::Lite::MFields
([cf_namespace =>
  (doc => "namespace prefix for yatt. (default: [yatt, perl])")]

 , [cf_doc_root =>
    (doc => "Primary template directory")]

 , [cf_app_base =>
    (doc => "Base dir for this siteapp")]

 , [cf_site_prefix =>
    (doc => "Location prefix for this siteapp")]

 , [cf_index_name =>
    (doc => "Rootname of index template. (default: index)")]

 , [cf_ext_public =>
    (doc => "public file extension for yatt. (default: yatt)")]

 , [cf_ext_private =>
    (doc => "hidden file extension for yatt. (default: ytmpl)")]

 , [cf_header_charset =>
    (doc => "Charset for outgoing HTTP Content-Type. (default: utf-8)")]

 , [cf_tmpl_encoding =>
    (doc => "Perl encoding used while reading yatt templates. (default: 'utf-8')")]

 , [cf_output_encoding =>
    (doc => "Perl encoding used for outgoing response body."
     ." Also this is used to decode incoming request parameters and PATH_INFO."
     ." (default: 'utf-8')")]

 , [cf_offline =>
    (doc => "Whether header should be emitted or not.")]

 , [cf_binary_config   =>
    (doc => "(This may be changed in future release) Whether .htyattconfig.* should be read with encoding or not.")]

 , [cf_no_unicode =>
    (doc => "(Compatibility option) Avoid use of utf8.")]

 , [cf_no_unicode_params =>
    (doc => "(Compatibility option) Avoid encoding conversion of input params.")]

 , [cf_use_subpath =>
    (doc => "pass sub-path_info")]

 , qw/
       cf_allow_missing_dir

       tmpldirs
       loc2yatt
       path2yatt

       loc2psgi_re
       loc2psgi_dict

       tmpl_cache

       path2entns

       cf_debug_cgen

       cf_only_parse
       cf_config_filetypes

       cf_dont_map_args
       cf_dont_debug_param
       cf_always_refresh_deps
     /);

use YATT::Lite::Util::AsBase;
use YATT::Lite::Util qw/lexpand globref untaint_any ckrequire dofile_in
			lookup_dir fields_hash
			lookup_path
			secure_text_plain
			psgi_error
			globref_default
			define_const
			terse_dump
		       /;

use YATT::Lite::XHF ();

use YATT::Lite::Partial::ErrorReporter;
use YATT::Lite::Partial::AppPath;

use YATT::Lite qw/Entity *SYS *YATT *CON/;


use YATT::Lite::Util::CycleDetector qw/Visits/;

#========================================
#
#
#

our $want_object;
sub want_object { $want_object }

sub find_load_factory_script {
  my ($pack, %opts) = @_;
  my ($found) = $pack->find_factory_script(delete $opts{dir})
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
  $self->{cf_offline} = $value;
  if ($self->{cf_offline}) {
    $self->configure(error_handler => sub {
		       my ($type, $err) = @_;
		       die $err;
		     })
  }
}

#========================================

sub load_factory_for_psgi {
  my ($pack, $psgi, %default) = @_;
  unless (defined $psgi) {
    croak "Usage: Factory->load_factory_for_psgi(psgi_filename, \%opts)";
  }
  unless (-r $psgi) {
    croak "psgi is not readable: $psgi";
  }
  (my $app_rootname = $pack->rel2abs($psgi)) =~ s/\.psgi$//;

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
  if (my (@cf) = map {
    my $cf = "$app_rootname.$_";
    -e $cf ? $cf : ()
  } $pack->default_config_filetypes) {
    croak "Multiple configuration files!: @cf" if @cf > 1;
    $pack->_with_loading_file($cf[0], sub {
				$pack->new(app_root => $app_root, %default
					   , $pack->read_file($cf[0]));
			      })
  } else {
    $pack->new(app_root => $app_root, %default);
  }
}

#========================================

{
  my %sub2app;
  sub to_app {
    my ($self, $cascade, @fallback) = @_;
    $self->prepare_app;
    my $sub = sub { $self->call(@_) };
    $sub2app{$sub} = $self; weaken($sub2app{$sub});
    if ($cascade) {
      $sub2app{$cascade} = $self; weaken($sub2app{$cascade});
      $cascade->add($sub, @fallback);
      $cascade->to_app;
    } else {
      $sub;
    }
  }
  sub wrapped_by {
    my ($self, $builder) = @_;
    my $outer_app = $builder->($self->to_app);
    $sub2app{$outer_app} = $self; weaken($sub2app{$outer_app});
    $outer_app;
  }
  sub load_psgi_script {
    my ($pack, $fn) = @_;
    local $want_object = 1;
    local $0 = $fn;
    my $sub = $pack->sandbox_dofile($fn);
    if (ref $sub eq 'CODE') {
      $sub2app{$sub};
    } elsif ($sub->isa($pack) or $sub->isa(MY)) {
      $sub;
    } else {
      die "Unknown load result from: $fn";
    }
  }
  sub prepare_app { return }

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
}

sub find_factory_script {
  my $pack = shift;
  my $dir = $pack->rel2abs($_[0] // $pack->curdir);
  my @path = $pack->no_upwards($pack->splitdir($dir));
  my $rootdir = $pack->rootdir;
  while (@path and length($dir = $pack->catdir(@path)) > length($rootdir)) {
    if (my ($found) = grep {-r} map {"$dir/$_.psgi"} qw(runyatt app)) {
      return $found;
    }
  } continue { pop @path }
  return;
}

#========================================

sub init_app_ns {
  (my MY $self) = @_;
  $self->SUPER::init_app_ns;
  $self->{default_app}->ensure_entns($self->{app_ns});
}

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{cf_index_name} //= $self->default_index_name;
  $self->{cf_ext_public} //= $self->default_ext_public;
  $self->{cf_ext_private} //= $self->default_ext_private;
  if ($self->{cf_no_unicode}) {
    $self->{cf_no_unicode_params} = 1;
    $self->{cf_binary_config} = 1;
    $self->{cf_header_charset}
      //= ($self->{cf_output_encoding} || $self->default_header_charset);
    $self->{cf_output_encoding}
      //= $self->compat_default_output_encoding;
  } else {
    $self->{cf_header_charset}
      //= ($self->{cf_output_encoding} // $self->default_header_charset);
    $self->{cf_tmpl_encoding}
      //= ($self->{cf_output_encoding} // $self->default_tmpl_encoding);
    $self->{cf_output_encoding} //= $self->default_output_encoding;
  }
  $self->{cf_use_subpath} //= 1;
}

sub compat_default_output_encoding { '' }
sub default_output_encoding { 'utf-8' }
sub default_header_charset  { 'utf-8' }
sub default_tmpl_encoding   { 'utf-8' }
sub default_index_name { 'index' }
sub default_ext_public {'yatt'}
sub default_ext_private {'ytmpl'}

sub _after_after_new {
  (my MY $self) = @_;
  $self->SUPER::_after_after_new;

  if (not $self->{cf_allow_missing_dir}
      and $self->{cf_doc_root}
      and not -d $self->{cf_doc_root}) {
    croak "document_root '$self->{cf_doc_root}' is missing!";
  }
  if ($self->{cf_doc_root}) {
    trim_slash($self->{cf_doc_root});
  }
  # XXX: $self->{cf_tmpldirs}

  $self->{cf_site_prefix} //= "";

  $self->{tmpldirs} = [];
  if (my $dir = $self->{cf_doc_root}) {
    push @{$self->{tmpldirs}}, $dir;
    $self->get_yatt('/');
  }
}

#========================================

sub render {
  my MY $self = shift;
  my $raw_bytes = $self->render_encoded(@_);
  decode(utf8 => $raw_bytes);
}

sub render_encoded {
  (my MY $self, my ($reqrec, $args, @opts)) = @_;
  # [$path_info, $subpage, $action]
  my ($path_info, @rest) = ref $reqrec ? @$reqrec : $reqrec;

  $path_info =~ s,^/*,/,;

  my ($tmpldir, $loc, $file, $trailer, $is_index)
    = my @pi = $self->lookup_split_path_info($path_info);
  unless (@pi) {
    die "No such location: $path_info";
  }

  my $dh = $self->get_lochandler(map {untaint_any($_)} $loc, $tmpldir) or do {
    die "No such directory: $path_info";
  };

  my $con = $self->make_simple_connection
  (
    \@pi, yatt => $dh, noheader => 1, path_info => $path_info
    , $self->make_debug_params($reqrec, $args)
  );

  $self->invoke_dirhandler
  (
    $dh, $con
   , render_into => $con
   , @rest ? [$file, @rest] : $file
   , $args, @opts
  );

  $con->buffer;
}

sub lookup_split_path_info {
  (my MY $self, my $path_info) = @_;
  lookup_path($path_info
	      , $self->{tmpldirs}
	      , $self->{cf_index_name}, ".$self->{cf_ext_public}"
	      , $self->{cf_use_subpath});
}

#========================================

sub K_MOUNT_MATCH () { "__yatt" }

sub lookup_psgi_mount {
  (my MY $self, my $path_info) = @_;
  $self->{loc2psgi_re} // $self->rebuild_psgi_mount;
  $path_info =~ $self->{loc2psgi_re}
    or return;
  my @mount_match = grep {/^@{[K_MOUNT_MATCH()]}/o} keys %+
    or return;
  if (@mount_match >= 2) {
    croak "Multiple match found for psgi_mount: \n"
      . join("\n  ", map {$self->{loc2psgi_dict}{$_}[0]} @mount_match);
  }

  my $path_prefix = $+{$mount_match[0]};

  my $item = $self->{loc2psgi_dict}{$path_prefix};

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
  my $dict = $self->{loc2psgi_dict} //= +{};
  my $key = K_MOUNT_MATCH() . (keys %$dict);
  $dict->{$path_prefix} = [$key => $path_prefix => $app, @opts];

  undef $self->{loc2psgi_re};

  # For cascading call
  $self;
}

sub rebuild_psgi_mount {
  (my MY $self) = @_;
  my @re;
  foreach my $path_prefix (keys %{$self->{loc2psgi_dict} //= +{}}) {
    my ($key, undef, $app) = @{$self->{loc2psgi_dict}{$path_prefix}};
    push @re, qr{(?<$key>$path_prefix)};
  }
  my $all = join("|", @re);
  $self->{loc2psgi_re} = qr{^(?:$all)(?:/|$)};
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
  $self->mount_psgi
    ($location, sub {
       (my Env $env) = @_;
       local $env->{PATH_INFO} = _trim_prefix($env->{PATH_INFO}, $location);
       $app->($env);
     });
}

sub _trim_prefix {
  substr($_[0], length($_[1]));
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
  my ($tmpldir, $loc, $file, $trailer) = @$quad;
  my $virtdir = "$self->{cf_doc_root}$loc";
  my $realdir = "$tmpldir$loc";
  my @params = $self->connection_quad([$virtdir, $loc, $file, $trailer]);
  $self->make_connection(undef, @params, @rest);
}

sub make_debug_params {
  (my MY $self, my ($reqrec, $args)) = @_;
  ();
}

sub make_connection {
  (my MY $self, my ($fh, @params)) = @_;
  require YATT::Lite::Connection;
  $self->Connection->create(
    $fh, @params, system => $self, root => $self->{cf_doc_root}
 );
}

sub finalize_connection {}

sub connection_param {
  croak "Use of YATT::Lite::Factory::connection_param is deprecated!\n";
}
sub connection_quad {
  (my MY $self, my ($quad)) = @_;
  my ($virtdir, $loc, $file, $subpath) = @$quad;
  (dir => $virtdir
   , location => $loc
   , file => $file
   , subpath => $subpath);
}

#========================================
#
# Hook for subclassing
#
sub run_dirhandler {
  (my MY $self, my ($dh, $con, $file)) = @_;
  local ($SYS, $YATT, $CON) = ($self, $dh, $con);
  $self->before_dirhandler($dh, $con, $file);
  $self->invoke_dirhandler($dh, $con
			   , handle => $dh->cut_ext($file), $con, $file);
  $self->after_dirhandler($dh, $con, $file);
}

sub before_dirhandler { &maybe::next::method; }
sub after_dirhandler  { &maybe::next::method; }

sub invoke_dirhandler {
  (my MY $self, my ($dh, $con, $method, @args)) = @_;
  $dh->with_system($self, $method, @args);
}

#========================================

sub get_lochandler {
  (my MY $self, my ($location, $tmpldir)) = @_;
  $tmpldir //= $self->{cf_doc_root};
  $self->get_yatt($location) || do {
    $self->{loc2yatt}{$location} = $self->load_yatt("$tmpldir$location");
  };
}

# location => yatt (dirhandler, dirapp)

sub get_yatt {
  (my MY $self, my $loc) = @_;
  if (my $yatt = $self->{loc2yatt}{$loc}) {
    return $yatt;
  }
#  print STDERR Carp::longmess("get_yatt for $loc"
#			      , YATT::Lite::Util::terse_dump($self->{tmpldirs}));
  my ($realdir, $basedir) = lookup_dir(trim_slash($loc), $self->{tmpldirs});
  unless ($realdir) {
    $self->error("Can't find template directory for location '%s'", $loc);
  }
  $self->{loc2yatt}{$loc} = $self->load_yatt($realdir, $basedir);
}

# phys-path => yatt

sub load_yatt {
  (my MY $self, my ($path, $basedir, $visits, $from)) = @_;
  $path = $self->rel2abs($path, $self->{cf_app_root});
  if (my $yatt = $self->{path2yatt}{$path}) {
    return $yatt;
  }
  if (not $visits) {
    $visits = Visits->start($path);
  } elsif (my $preds = $visits->check_cycle($path, $from)) {
    $self->error("Template config error! base has cycle!:\n     %s\n"
		 , join "\n  -> ", $from, @$preds);
  }
  #-- DFS-visits --
  if (not $self->{cf_allow_missing_dir} and not -d $path) {
    croak "Can't find '$path'!";
  }
  if (my (@cf) = map {
    my $cf = untaint_any($path) . "/.htyattconfig.$_";
    -e $cf ? $cf : ()
  } $self->config_filetypes) {
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

  if (-e (my $rc = "$path/.htyattrc.pl")) {
    # Note: This can do "use fields (...)"
    dofile_in($app_ns, $rc);
  }

  my @args = (vfs => [dir => $path
		      , entns => $self->{path2entns}{$path}
		      , encoding => $self->{cf_tmpl_encoding}
		      , @basevfs ? (base => \@basevfs) : ()]
	      , dir => $path
	      , app_ns => $app_ns
	      , app_name => $app_name
	      , factory => $self

	      # XXX: Design flaw! Use of tmpl_cache will cause problem.
	      # because VFS->create for base do not respect Factory->get_yatt.
	      # To solve this, I should redesign all Factory/VFS related stuffs.
	      , tmpl_cache => $self->{tmpl_cache} //= {}

	      , $self->configparams_for(fields_hash($app_ns)));

  if (my @unk = $app_ns->YATT::Lite::Object::cf_unknowns(%opts)) {
    $self->error("Unknown option for yatt app '%s': '%s'"
		 , $path, join(", ", @unk));
  }

  $self->{path2yatt}{$path} = $app_ns->new(@args, %opts);
}

sub _list_base_spec_in {
  (my MY $self, my ($in, $desc, $visits, $basepkg, $basevfs)) = @_;

  print STDERR "# Factory::list_base_in("
    , terse_dump($in, $desc, $self->{cf_app_base}), ")\n" if DEBUG_FACTORY;

  my $is_implicit = not defined $desc;

  $desc //= $self->{cf_app_base};

  my ($base, @mixin) = lexpand($desc)
    or return;

  my @pkg_n_dir;
  foreach my $task ([1, $base], [0, @mixin]) {
    my ($is_primary, @spec) = @$task;
    foreach my $basespec (@spec) {
      my ($pkg, $yatt);
      if ($basespec =~ /^::(.*)/) {
	ckrequire($1);
	push @pkg_n_dir, [$is_primary, $1, undef];
      } elsif (my $realpath = $self->app_path_find_dir_in($in, $basespec)) {
	if ($is_implicit) {
	  next if $visits->has_node($realpath);
	}
	$visits->ensure_make_node($realpath);
	push @pkg_n_dir, [$is_primary, undef, $realpath];
      } else {
	$self->error("Invalid base spec: %s", $basespec);
      }
    }
  }

  foreach my $tuple (@pkg_n_dir) {
    my ($is_primary, $pkg, $dir) = @$tuple;
    next unless $dir;
    my $yatt = $self->load_yatt($dir, undef, $visits, $in);
    $tuple->[1] = ref $yatt;
    my $realdir = $yatt->cget('dir');
    push @$basevfs, [dir => $realdir, entns => $self->{path2entns}{$realdir}];
  }

  push @$basepkg, map {
    my ($is_primary, $pkg, $dir) = @$_;
    ($is_primary && $pkg) ? ($pkg) : ()
  } @pkg_n_dir;

  $visits->finish_node($in);
}

#========================================

sub buildns {
  (my MY $self, my ($kind, $baselist, $path)) = @_;
  my $newns = $self->SUPER::buildns($kind, $baselist, $path);

  # EntNS を足し、Entity も呼べるようにする。
  $self->{default_app}->define_Entity(undef, $newns
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
  $self->{path2entns}{$path} = $newns->EntNS;

  $newns;
}

sub _cf_delegates {
  qw(no_unicode
     no_unicode_params
     output_encoding
     header_charset
     tmpl_encoding
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
  );
}

sub configparams_for {
  (my MY $self, my $hash) = @_;
  # my @base = map { [dir => $_] } lexpand($self->{cf_tmpldirs});
  # (@base ? (base => \@base) : ())
  (
   $self->cf_delegate_known(0, $hash, $self->_cf_delegates)
   , (exists $hash->{cf_error_handler}
      ? (error_handler => \ $self->{cf_error_handler}) : ())
   , die_in_error => ! YATT::Lite::Util::is_debugging());
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
    foreach my $tmpldir (lexpand($self->{tmpldirs})) {
      ensure_slash(my $cp = $tmpldir);
      if (defined(my $app_name = $self->_extract_app_name($path, $cp))) {
	# Can be empty string.
	return $app_name;
      }
    }
    return '';
  }
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
  if (my $item = $self->{cf_config_filetypes}) {
    lexpand($item)
  } else {
    $self->default_config_filetypes
  }
}

sub read_file_xhf {
  (my MY $self, my $fn) = @_;
  my $bytes_semantics = ref $self && $self->{cf_binary_config};
  $self->YATT::Lite::XHF::read_file_xhf
    ($fn, bytes => $bytes_semantics);
}

sub read_file_yml {
  (my MY $self, my $fn) = @_;
  require YAML::Tiny;
  my $yaml = YAML::Tiny->read($fn);
  wantarray ? lexpand($yaml->[0]) : $yaml;
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
    $self->{cf_site_prefix};
  };
}


1;
