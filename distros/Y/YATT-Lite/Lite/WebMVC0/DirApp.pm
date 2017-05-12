package YATT::Lite::WebMVC0::DirApp; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use YATT::Lite -as_base, qw/*SYS
			    Entity/;
use YATT::Lite::MFields qw/cf_dir_config
			   cf_use_subpath
			   cf_overwrite_status_code_for_errors_as

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

# sub handle_ydo, _do, _psgi...

sub handle {
  (my MY $self, my ($type, $con, $file)) = @_;
  chdir($self->{cf_dir})
    or die "Can't chdir '$self->{cf_dir}': $!";
  local $SIG{__WARN__} = sub {
    my ($msg) = @_;
    die $self->raise(warn => $_[0]);
  };
  local $SIG{__DIE__} = sub {
    my ($err) = @_;
    die $err if ref $err;
    die $self->error({ignore_frame => [undef, __FILE__, __LINE__]}, $err);
  };
  if (my $charset = $self->header_charset) {
    $con->set_charset($charset);
  }
  $self->SUPER::handle($type, $con, $file);
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
      and $self->{cf_use_subpath} and my $subpath = $prop->{cf_subpath}) {
    my $tmpl = $trans->find_file($file) or do {
      croak $self->error("No such file: %s", $file);
    };
    ($part, my ($formal, $actual)) = $tmpl->match_subroutes($subpath) or do {
      # XXX: Is this secure against XSS? <- how about URI encoding?
      # die $self->psgi_error(404, "No such subpath: ". $subpath);
      die $self->psgi_error(404, "No such subpath");
    };
    $pkg = $trans->find_product(perl => $tmpl) or do {
      croak $self->error("Can't compile template file: %s", $file);
    };
    my $name = $part->cget('name');
    $sub = $pkg->can("render_$name") or do {
      croak $self->error("Can't find page %s for file: %s", $name, $file);
    };
    @args = $part->reorder_cgi_params($con, $actual)
      unless $self->{cf_dont_map_args};

  } else {
    ($part, $sub, $pkg) = $trans->find_part_handler([$file, $type, $item]);

    @args = $part->reorder_cgi_params($con)
      unless $self->{cf_dont_map_args} || $part->isa($trans->Action);
  }

  unless ($part->public) {
    # XXX: refresh する手もあるだろう。
    croak $self->error(q|Forbidden request %s|, $file);
  }

  ($part, $sub, $pkg, \@args);
}

#========================================
# Action handling
#========================================

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
sub error_handler {
  (my MY $self, my $type, my Error $err) = @_;
  # どこに出力するか、って問題も有る。 $CON を rewind すべき？
  my $errcon = do {
    if (my $con = $self->CON) {
      $con->as_error;
    } elsif ($SYS) {
      $SYS->make_connection(\*STDOUT, yatt => $self, noheader => 1);
    } else {
      \*STDERR;
    }
  };
  if (my $code = $err->{cf_http_status_code}) {
    $errcon->configure(status => $code);
  } elsif ($code = $errcon->cget('status')) {
    $err->{cf_http_status_code} = $code;
  }
  # error.ytmpl を探し、あれば呼び出す。
  my ($sub, $pkg);
  ($sub, $pkg) = $self->find_renderer($type => ignore_error => 1) or do {
    if ($err->{cf_http_status_code}
	|| $self->{cf_overwrite_status_code_for_errors_as}) {
       ($sub, $pkg) = (sub {
			 my ($this, $errcon, $err) = @_;
			 print {*$errcon} $err->reason;
		       }, $self->EntNS);
     } else {
       die $err;
     }
  };
  $sub->($pkg, $errcon, $err);
  try_invoke($errcon, 'flush_headers');
  $self->raise_psgi_html($self->{cf_overwrite_status_code_for_errors_as}
			 // $errcon->cget('status')
			 // 500
			 , $errcon->buffer); # ->DONE was not ok.
}

Entity dir_config => sub {
  my ($this, $name, $default) = @_;
  my MY $self = $this->YATT;
  return $self->{cf_dir_config} unless defined $name;
  $self->{cf_dir_config}{$name} // $default;
};

use YATT::Lite::Breakpoint;
YATT::Lite::Breakpoint::break_load_dirhandler();

1;
