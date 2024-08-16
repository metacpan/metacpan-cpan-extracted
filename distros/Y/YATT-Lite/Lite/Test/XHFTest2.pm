package YATT::Lite::Test::XHFTest2; sub Tests () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Exporter qw(import);

use File::Basename qw(dirname);

use base qw(YATT::Lite::Object);
use fields qw/files cf_dir cf_libdir
	      cf_debug
	      cookie_jar/;
use YATT::Lite::Types
  (export_default => 1
   , [File => -fields => [qw(cf_file items
			     cf_REQUIRE cf_USE_COOKIE
			     cf_FILE_READABLE
			   )]]
   , [Item => -fields => [qw(cf_TITLE cf_FILE cf_METHOD cf_ACTION
                             cf_STATUS
			     cf_BREAK
			     cf_SKIP_IF_ERROR
                             cf_ACCEPT_ERROR
			     cf_SAME_RESULT
			     cf_PERL_MINVER
			     cf_SITE_CONFIG
			     cf_PARAM cf_HEADER cf_BODY cf_ERROR)]]);

our @EXPORT;
push @EXPORT, qw(trimlast nocr);

use Carp;
use Test::More;
use YATT::Lite::Test::TestUtil;
use File::Basename;
use List::Util qw(sum);

use YATT::Lite::Util qw(lexpand untaint_any rootname);

push @EXPORT, qw(plan is is_deeply like eq_or_diff sum);

sub load_tests {
  my ($pack, $spec) = splice @_, 0, 2;
  my Tests $tests = $pack->new(@$spec);
  foreach my $fn ($tests->list_xhf(@_)) {
    push @{$tests->{files}}, $tests->load_file($fn);
  }
  $tests;
}

sub enter {
  (my Tests $tests) = @_;
  unless (defined $tests->{cf_dir}) {
    croak "dir is undef";
  }
  chdir $tests->{cf_dir} or die "Can't chdir to '$tests->{cf_dir}': $!";
}

sub test_plan {
  my Tests $self = shift;
  unless ($self->{files} and @{$self->{files}}) {
    return skip_all => "No t/*.xhf are defined";
  }
  foreach my File $file (@{$self->{files}}) {
    foreach my $fn (lexpand $file->{cf_FILE_READABLE}) {
      # Note: This assumes $tests->test_plan is called after $tests->enter.
      unless (-r $fn) {
	return skip_all => "FILE $fn is not readable"
      }
    }
    foreach my $req (lexpand($file->{cf_REQUIRE})) {
      unless (eval qq{require $req}) {
	return skip_all => "$req is not installed.";
      }
    }
  }
  (tests => $self->ntests(@_));
}

sub load_dispatcher {
  my Tests $self = shift;
  require YATT::Lite::Factory;
  my $script = do {
    if (defined $self->{cf_libdir}) {
      my $rn = rootname($self->{cf_libdir});
      my @found = grep {-r} map {"$rn.$_"} qw(cgi psgi);
      $found[0];
    } elsif (-r (my $psgi = dirname($self->{cf_dir}) . "/app.psgi")) {
      $psgi;
    } else {
      undef;
    }
  };
  unless ($script and -r $script) {
    croak "Can't load dispatcher. runyatt.cgi, runyatt.psgi or app.psgi is required";
  }

  # $dir/t/../app.psgi => $dir/app.psgi
  (my $realpath = $script) =~ s{/([^\.][^/]*)/\.\.(?:/|$)}{/}g;

  my $dispatcher = YATT::Lite::Factory->load_factory_script($realpath);
  $dispatcher->configure(noheader => 1);
  $dispatcher;
}

sub ntests {
  my Tests $tests = shift;
  sum(@_, map {$tests->ntests_per_file($_)} @{$tests->{files}});
}

sub ntests_per_file {
  (my Tests $tests, my File $file) = @_;
  sum(map {$tests->ntests_per_item($_)} @{$file->{items}});
}

sub ntests_per_item {
  (my Tests $tests, my Item $item) = @_;
  $item->{cf_ACTION} ? 0 : 1;
}

sub file_title {
  (my Tests $tests, my File $file) = @_;
  join ';', $tests->{cf_dir}, basename($file->{cf_file});
}

sub mkpat_by {
  (my Tests $tests, my $sep) = splice @_, 0, 2;
  my $str = join $sep, map {ref $_ ? @$_ : $_} @_;
  qr{$str}sm;
}

sub mkpat { shift->mkpat_by('|', @_) }
sub mkseqpat { shift->mkpat_by('.*?', @_) }

sub list_xhf {
  my $pack = shift;
  unless (@_) {
    <*.xhf>
  } else {
    map {
      -d $_ ? <$_/*.xhf> : $_
    } @_;
  }
}

use YATT::Lite::XHF;
sub Parser {'YATT::Lite::XHF'}
# XXX: Currently, all t/*.xhf is loaded as binary (not Wide char).
sub load_file {
  shift->load_file_into([], @_);
}

sub load_file_into {
  my ($pack, $array, $fn) = splice @_, 0, 3;
  _with_loading_file {$pack} $fn, sub {
    my File $file = $pack->File->new(file => $fn);
    my $parser = $pack->Parser->new(file => $fn);
    if (my @global = $parser->read(skip_comment => 0)) {
      $file->configure(@global);
    }
    while (my @config = $parser->read) {
      if (@config == 2 and $config[0] =~ /^include$/i) {
	$pack->load_file_into($file->{items} //= [], $pack->resolve_in($fn, $_))
	  for lexpand $config[1];
      } else {
	push @{$file->{items}}, $pack->Item->new(@config);
      }
    }
    push @$array, @{$file->{items}};
    $file;
  };
}

sub resolve_in {
  my ($pack, $origfn, $newfn) = @_;
  dirname($origfn) . '/' . $newfn;
}

#========================================
use 5.010; no if $] >= 5.017011, warnings => "experimental";

sub mechanized {
  (my Tests $tests, my $mech) = @_;
  foreach my File $sect (@{$tests->{files}}) {
    my $dir = $tests->{cf_dir};
    my $sect_name = $tests->file_title($sect);

    my $last_body;
    foreach my Item $item (@{$sect->{items}}) {

      if ($item->{cf_BREAK}) {
        YATT::Lite::Breakpoint::breakpoint();
      }

      if (my $action = $item->{cf_ACTION}) {
	my ($method, @args) = @$action;
	my $sub = $tests->can("action_$method")
	  or die "No such action: $method";
	$sub->($tests, @args);
	next;
      }

      my $method = $tests->item_method($item);
      my $error;
      local $mech->{onerror} = sub {
	$error = join " ", @_;
      };
      my $res = $tests->mech_request($mech, $item);
      my $T = defined $item->{cf_TITLE} ? "[$item->{cf_TITLE}]" : '';

      SKIP: {
	if (defined $error) {
	  if (defined $item->{cf_SKIP_IF_ERROR}
	      and $error =~ m{$item->{cf_SKIP_IF_ERROR}}) {
	    my $skip_count = $tests->skipcount_for_request_error($item);
	    skip $error, $skip_count;
          } elsif ($item->{cf_ACCEPT_ERROR}
                   and grep {$error =~ $_} lexpand($item->{cf_ACCEPT_ERROR})) {
            # ok
	  }
          elsif (not $res->is_success
                 and defined (my $content = $res->decoded_content)
                 and ($item->{cf_ERROR} or $item->{cf_BODY})
               ) {
            if ($item->{cf_ERROR}) {
              like $content, qr{$item->{cf_ERROR}}, "[$sect_name] $T HTTP Error should match $item->{cf_ERROR}";

              next;
            } else {
              # fall through to BODY test
            }
          }
          else {
	    fail "[$sect_name] $T Unknown error: $error "
              . $tests->item_url($item);
	    next;
	  }
	}

	if ($item->{cf_HEADER} and my @header = @{$item->{cf_HEADER}}) {
	  while (my ($key, $pat) = splice @header, 0, 2) {
	    my $title = "[$sect_name] $T HEADER $key of $method $item->{cf_FILE}";
	    if ($res) {
	      like $res->header($key), qr{$pat}s, $title;
	    } else {
	      fail "$title - no \$res";
	    }
	  }
	}

	if (my $body = $item->{cf_SAME_RESULT} ? $last_body : $item->{cf_BODY}) {
	  if (ref $body) {
	    like nocr($mech->content), $tests->mkseqpat($body)
	      , "[$sect_name] $T BODY of $method $item->{cf_FILE}";
	  } else {
	    eq_or_diff trimlast(nocr($mech->content)), $body
	      , "[$sect_name] $T BODY of $method $item->{cf_FILE}";
	  }
	} elsif (my $errpat = $item->{cf_ERROR}) {
	  $errpat =~ s{\^}{^(?:(?i)ERROR: )?};

	  # XXX: It might be better to wrap $mech to have specialized ->title()
	  # for http_localhost.t too.
	  #
	  like $mech->title // $mech->content, qr{$errpat}
	    , "[$sect_name] $T ERROR of $method $item->{cf_FILE}";
	}
      }
    } continue {
      $last_body = $item->{cf_BODY} if $item->{cf_BODY};
    }
  }
}

sub item_method {
  (my Tests $tests, my ($item)) = @_;
  $item->{cf_METHOD} // 'GET';
}

sub run_psgicb {
  (my Tests $tests, my ($cb, $item)) = @_;
  my $jar = $tests->{cookie_jar} ||= do {
    require HTTP::Cookies;
    HTTP::Cookies->new;
  };
  my $req = $tests->mkrequest($item);
  my $res = $cb->($req);
  $jar->extract_cookies($res);
  $res;
}

sub mkrequest {
  (my Tests $tests, my Item $item) = @_;
  require HTTP::Request::Common;
  my $builder = HTTP::Request::Common->can($item->{cf_METHOD});
  my $req = $builder->($tests->item_url($item)
		       , $tests->mkformref_if_post($item));
  if (my $jar = $tests->{cookie_jar}) {
    $jar->add_cookie_header($req);
  }
  $req;
}

sub mkformref_if_post {
  (my Tests $tests, my Item $item) = @_;
  return unless $item->{cf_METHOD} eq 'POST';
  defined (my $ary = $item->{cf_PARAM})
    or return;
  if (ref $ary eq 'ARRAY'
      and grep(ref $_ eq 'HASH', @$ary)
      or ref $ary eq 'HASH'
      and grep(ref $_ eq 'HASH', values %$ary)) {
    croak "HASH value is not allowed in PARAM block!";
  }
  $ary;
}

sub mech_request {
  (my Tests $tests, my ($mech, $item)) = @_;
  my $url = $tests->item_url($item);
  my $method = $tests->item_method($item);
  if ($method eq 'GET') {
    return $mech->get($url);
  }
  elsif ($method eq 'POST') {
    return $mech->post($url, $item->{cf_PARAM});
  }
  else {
    die "Unknown test method: $method\n";
  }
}

sub item_url {
  (my Tests $tests, my Item $item) = @_;
  my $url = do {
    if (($item->{cf_METHOD} // '') eq 'POST') {
      $tests->item_url_file($item)
    } else {
      join '?', $tests->item_url_file($item), $tests->item_query($item);
    }
  };
  print STDERR "#item_url: $url\n" if $tests->{cf_debug};
  $url;
}

sub item_url_file {
  (my Tests $tests, my Item $item) = @_;
  $tests->base_url . $item->{cf_FILE}
}

use YATT::Lite::Util qw(encode_query);
sub item_query {
  (my Tests $tests, my Item $item) = @_;
  my $param = $item->{cf_PARAM}
    or return;
  $tests->encode_query($item->{cf_PARAM});
}

sub skipcount_for_request_error {
  (my Tests $tests, my Item $item) = @_;
  lexpand($item->{cf_HEADER})/2
    + (defined $item->{cf_BODY} || defined $item->{cf_ERROR});
}

#========================================
sub action_remove {
  my Tests $tests = shift;
  my @files = glob(shift);
  unlink map {untaint_any($_)} @files if @files;
}

#========================================
sub trimlast {
  return undef unless defined $_[0];
  $_[0] =~ s/\s+$/\n/g;
  $_[0];
}

use Encode qw(is_utf8 encode);
sub nocr {
  return undef unless defined $_[0];
  $_[0] =~ s|\r||g;
  if (is_utf8($_[0])) {
    encode(utf8 => $_[0]);
  } else {
    $_[0];
  }
}

1;
