package YATT::Lite::WebMVC0::DirApp; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

use constant DEBUG_ERROR => $ENV{DEBUG_YATT_ERROR};

use YATT::Lite -as_base, qw/*SYS *CON
			    Entity/;
use YATT::Lite::MFields qw/cf_dir_config
			   cf_use_subpath
			   cf_overwrite_status_code_for_errors_as
                           cf_ext_public_action
                           _ignore_warn
                           _ignore_die

			   Action/;

use YATT::Lite::WebMVC0::Connection;
sub Connection () {'YATT::Lite::WebMVC0::Connection'}
sub PROP () {Connection}

use YATT::Lite::Util qw/cached_in ckeval
			dofile_in compile_file_in
			try_invoke
			psgi_error
			terse_dump
		      /;

use YATT::Lite::Error;

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{cf_ext_public_action} //= $self->default_ext_public_action;
}

# sub handle_ydo, _do, _psgi...

sub handle {
  (my MY $self, my ($type, $con, $file)) = @_;
  chdir($self->{cf_dir})
    or die "Can't chdir '$self->{cf_dir}': $!";
  local $SIG{__WARN__} = sub {
    my ($msg) = @_;
    if ($self->{_ignore_warn}) {
      print STDERR "# ignore __WARN__ $msg\n" if DEBUG_ERROR;
      return;
    }
    print STDERR "# from __WARN__ $msg\n" if DEBUG_ERROR;
    die $self->raise(warn => $_[0]);
  };
  local $SIG{__DIE__} = sub {
    my ($err) = @_;
    if ($self->{_ignore_die}) {
      print STDERR "# ignore __DIE__ $err\n" if DEBUG_ERROR;
      return;
    }
    unless ($^S) {
      print STDERR "# interp state is falsy: ignore __DIE__ $err\n" if DEBUG_ERROR;
      return;
    }
    if (ref $err) {
      print STDERR Carp::longmess("# in __DIE__, got ref error: "
                                  , terse_dump($err)), "\n" if DEBUG_ERROR;
      die $err;
    } else {
      print STDERR "# from __DIE__ $err\n" if DEBUG_ERROR;
    }
    local $self->{cf_in_sig_die} = 1;
    die $self->error({ignore_frame => [undef, __FILE__, __LINE__]}, $err);
  };
  if (my $charset = $self->header_charset) {
    $con->set_charset($charset);
  }
  $self->SUPER::handle($type, $con, $file);
}

sub with_ignoring_die {
  (my MY $self, my ($sub, @args)) = @_;
  local $self->{_ignore_warn} = 1;
  local $self->{_ignore_die} = 1;
  $sub->(@args);
}

sub with_ignoring_warn {
  (my MY $self, my ($sub, @args)) = @_;
  local $self->{_ignore_warn} = 1;
  $sub->(@args);
}

#
# WebMVC0 specific url mapping.
#
sub prepare_part_handler {
  (my MY $self, my ($con, $file)) = @_;

  my $trans = $self->open_trans;

  my PROP $prop = $con->prop;

  my ($part, $sub, $pkg, @args);
  my ($type, $item) = $self->parse_request_sigil($con);

  if (defined $type and my $subpath = $prop->{cf_subpath}) {
    croak $self->error(q|Bad request: subpath %s and sigil %s|
		       , $subpath, terse_dump($type, $item))
      if $type ne 'action';
  }

  if (not defined $type
      and $self->{cf_use_subpath} and $prop->{cf_subpath}
      and (my $tmpl, $part, my ($formal, $actual)) = $self->find_subpath_handler(
        $trans, $file, $prop->{cf_subpath}
      )) {

      $pkg = $trans->find_product(perl => $tmpl) or do {
        croak $self->error("Can't compile template file: %s", $file);
      };

      $sub = $pkg->can($part->method_name) or do {
        croak $self->error("Can't find %s %s for file: %s"
                           , $part->cget('kind'), $part->public_name, $file);
      };
      @args = $trans->reorder_cgi_params($part, $con, $actual)
        unless $self->{cf_dont_map_args};
  } else {
    ($part, $sub, $pkg) = $trans->find_part_handler([$file, $type, $item]);

    @args = $trans->reorder_cgi_params($part, $con)
      unless $self->{cf_dont_map_args};
  }

  unless ($part->public) {
    # XXX: refresh する手もあるだろう。
    croak $self->error(q|Forbidden request %s|, $file);
  }

  ($part, $sub, $pkg, \@args);
}

sub find_subpath_handler {
  (my MY $self, my ($trans, $file, $subpath)) = @_;

  my $tmpl = $trans->find_file($file) or do {
    croak $self->error("No such file: %s", $file);
  };

  if (my @found = $tmpl->match_subroutes($subpath)) {
    return ($tmpl, @found);
  } else {
    if ($subpath ne '/') {
      die $self->psgi_error(404, "No such subpath:: ". $subpath
                            . " in file " . $tmpl->{cf_path});
    }
  }
  return;
}

#========================================
# Action handling
#========================================

sub default_ext_public_action {'ydo'}

sub find_handler {
  (my MY $self, my ($ext, $file, $con)) = @_;
  my PROP $prop = $con->prop;
  if ($prop->{cf_is_index}) {
    my $sub_fn = substr($prop->{cf_path_info}, length($prop->{cf_location}));
    $sub_fn =~ s,/.*,,;
    if ($sub_fn ne '' and my $action = $self->get_action_handler($sub_fn, 1)) {
      return $action
    }
  }
  $self->SUPER::find_handler($ext, $file, $con);
}

sub _handle_ydo {
  (my MY $self, my ($con, $file, @rest)) = @_;
  my $action = $self->get_action_handler($file)
    or die "Can't find action handler for file '$file'\n";

  # XXX: this は EntNS pkg か $YATT か...
  $action->($self->EntNS, $con);
}

# XXX: cached_in 周りは面倒過ぎる。
# XXX: package per dir で、本当に良いのか?
# XXX: Should handle union mount!

#
sub get_action_handler {
  (my MY $self, my ($filename, $can_be_missing)) = @_;
  my $path = "$self->{cf_dir}/$filename";

  # Each action item is stored as:
  # [$action_sub, $is_virtual, @more_opts..., $age_from_mtime]
  #
  my $item = $self->cached_in
    ($self->{Action} //= {}, $path, $self, undef, sub {
       # first time.
       my ($self, $sys, $path) = @_;
       return undef unless $path =~ m{\.$self->{cf_ext_public_action}\z};
       my $age = -M $path;
       return undef if not defined $age and $can_be_missing;
       my $sub = compile_file_in(ref $self, $path);
       # is not virtual.
       [$sub, 0, $age];
     }, sub {
       # second time
       my ($item, $sys, $path) = @_;
       my ($sub, $age);
       if (not defined $item) {
	 # XXX: (Accidental) negative cache. Is this ok?
	 return;
       } elsif ($item->[1]) {
	 # return $action_sub without examining $path when item is virtual.
	 return $item->[0];
       } elsif (not defined ($age = -M $path)) {
	 # item is removed from filesystem, so undef $sub.
       } elsif ($$item[-1] == $age) {
	 return;
       } else {
	 $sub = compile_file_in($self->{cf_app_ns}, $path);
       }
       @{$item}[0, -1] = ($sub, $age);
     });
  return unless defined $item and $item->[0];
  wantarray ? @$item : $item->[0];
}

sub set_action_handler {
  (my MY $self, my ($filename, $sub)) = @_;

  $filename =~ s,^/*,,;

  my $path = "$self->{cf_dir}/$filename";

  $self->{Action}{$path} = [$sub, 1, undef];
}

#========================================
# Response Header
#========================================

sub default_header_charset {''}
sub header_charset {
  (my MY $self) = @_;
  $self->{cf_header_charset} || $self->{cf_output_encoding}
    || $SYS->header_charset
      || $self->default_header_charset;
}

#========================================

sub get_lang_msg {
  (my MY $self, my $lang) = @_;
  $self->{locale_cache}{$lang} || do {
    if (-r (my $fn = $self->fn_msgfile($lang))) {
      $self->lang_load_msgcat($lang, $fn);
    }
  };
}

sub fn_msgfile {
  (my MY $self, my $lang) = @_;
  "$self->{cf_dir}/.htyattmsg.$lang.po";
}

#========================================
# Following code is for per-DirApp error handling.
# Since this complicates error handling too much, I might drop this code near(?) future.
#
sub error_handler {
  (my MY $self, my $type, my Error $err) = @_;
  # どこに出力するか、って問題も有る。 $CON を rewind すべき？
  my $errcon = try_invoke($self->CON, 'as_error') || do {
    my $con = $SYS
      ? $SYS->make_connection(undef, yatt => $self, noheader => 1)
      : $self->CON;
    try_invoke($con, 'as_error');
    $con;
  };

  $errcon->add_error($err);

  my $error_status = $self->{cf_overwrite_status_code_for_errors_as}
    // $err->{cf_http_status_code}
    // try_invoke($errcon, [cget => 'status'])
    // 500;

  $errcon->configure(status => $error_status);
  $err->{cf_http_status_code} = $error_status;

  my $msg = $err->message;

  # yatt/ytmpl 用の Code generator がまだ無いので、素直に raise.
  # XXX: 本当は正しくロードできる可能性もあるが,
  #  そこで更に fail すると真のエラーが隠されてしまうため、頑張らない。
  unless ($self->is_default_cgen_ready) {
    print STDERR "# error_handler(with cgen): $msg\n" if DEBUG_ERROR;
    die $err;
  }

  #
  # For [GH #172] - to avoid 'ARRAY(0x5575a6c9c2a8)Compilation failed in require'
  #
  if ($self->{cf_in_sig_die}) {
    print STDERR "# error_handler(sig die): $msg\n" if DEBUG_ERROR;
    die $err;
  }

  print STDERR "# error_handler(normal): $msg\n" if DEBUG_ERROR;

  my $is_psgi = $self->CON->cget('is_psgi');

  # error.ytmpl を探し、あれば呼び出す。
  my ($sub, $pkg);
  ($sub, $pkg) = $self->find_renderer($type => ignore_error => 1) or do {
    print {*$errcon} $err->reason;
    if ($is_psgi) {
      $self->DONE;
    } else {
      die $err->reason;
    }
  };
  $sub->($pkg, $errcon, $err);

  if ($is_psgi) {
    $self->raise_psgi_html($error_status
                           , $errcon->buffer); # ->DONE was not ok.
  } else {
    try_invoke($errcon, 'flush_headers');
    $self->DONE;
  }
}

# dir_config should be fetched from target dirapp for this request($CON)
# instead from container of called template($this)
# because widgets can be abstracted out to library dirs.

Entity dir_config => sub {
  my $this = shift;
  $CON->YATT->dir_config(@_);
};

sub dir_config {
  (my MY $self, my ($name, $default)) = @_;

  my PROP $prop = $CON->prop;
  my $cache = $prop->{dir_config_cache} //= +{};
  # This ensures every request has a fresh cache for dir_config
  # and every request tests the cache at most once.

  my $config = $cache->{$self->{cf_app_name}};

  unless ($config) {
    my $cfg = $self->{cf_dir_config} || +{};

    # If dirapp_config exist, merge it onto original dir_config.
    if (my $dirapp_config = $SYS->dirapp_config_for($self)) {
      $cfg->{$_} = $dirapp_config->{$_} for keys %$dirapp_config;
    }
    $config = $cache->{$self->{cf_app_name}} = $cfg;
  }

  return $config unless defined $name;

  $config->{$name} // $default;
}

sub merged_dir_config {
  (my MY $self, my $name) = @_;

  my $all_config = $self->dir_config;

  my $base = $all_config->{$name} // +{};

  YATT::Lite::Util::merge_hash_renaming {
    /^${name}[_\.](.*)/
  } $base, $all_config;
}

use YATT::Lite::Breakpoint;
YATT::Lite::Breakpoint::break_load_dirhandler();

1;
