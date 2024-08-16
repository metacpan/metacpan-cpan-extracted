# -*- coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

# For future Test::FCGI::Mechanize...

use Test::Builder ();
my $Test = Test::Builder->new;

{
  package YATT::Lite::Test::TestFCGI; sub MY () {__PACKAGE__}
  use parent qw(YATT::Lite::Object File::Spec);
  use YATT::Lite::MFields qw/res status ct content cookie_jar last_request
		sockfile
		raw_result
		onerror
		cf_rootdir cf_fcgiscript
		cf_debug_fcgi
		kidpid
	      /;		# base form

  use HTML::Entities ();

  sub check_skip_reason {
    my MY $self = shift;

    unless (eval {require FCGI and require CGI::Fast}) {
      return 'FCGI.pm is not installed';
    }

    unless (eval {require HTTP::Response}) {
      return 'HTTP::Response is not installed';
    }

    if (ref $self and not -x $self->{cf_fcgiscript}) {
      return "Can't find cgi-bin/runyatt.cgi"
    }

    return;
  }

  sub plan {
    shift;
    require Test::More;
    Test::More::plan(@_);
  }

  sub skip_all {
    shift;
    require Test::More;
    Test::More::plan(skip_all => shift);
  }

  sub which {
    my ($pack, $exe) = @_;
    foreach my $path ($pack->path) {
      if (-x (my $fn = $pack->join($path, $exe))) {
	return $fn;
      }
    }
  }

  use IO::Socket::UNIX;
  use Fcntl;
  use POSIX ":sys_wait_h";
  use Time::HiRes qw(usleep);
  use File::Basename;

  sub mkservsock {
    shift; new IO::Socket::UNIX(Local => shift, Listen => 5);
  }
  sub mkclientsock {
    shift; new IO::Socket::UNIX(Peer => shift);
  }

  sub fork_server {
    (my MY $self) = @_;

    my $sessdir  = MY->tmpdir . "/fcgitest$$";
    unless (mkdir $sessdir, 0700) {
      die "Can't mkdir $sessdir: $!";
    }

    my $sock = $self->mkservsock($self->{sockfile} = "$sessdir/socket");

    unless (defined($self->{kidpid} = fork)) {
      die "Can't fork: $!";
    } elsif (not $self->{kidpid}) {
      # child
      open STDIN, '<&', $sock or die "kid: Can't reopen STDIN: $!";
      open STDOUT, '>&', $sock or die "kid: Can't reopen STDOUT: $!";
      # open STDERR, '>&', $sock or die "kid: Can't reopen STDERR: $!";
      # XXX: -MDevel::Cover=$ENV{HARNESS_PERL_SWITCHES}
      # XXX: Taint?
      my @opts = qw(-T);
      if (my $switch = $ENV{HARNESS_PERL_SWITCHES}) {
	push @opts, split " ", $switch;
      }
      exec $^X, @opts, $self->{cf_fcgiscript};
      die "Can't exec $self->{cf_fcgiscript}: $!";
    }
  }

  DESTROY {
    (my MY $self) = @_;
    if ($self->{kidpid}) {
      # print STDERR "# shutting down $self->{kidpid}\n";
      # Shutdown FCGI fcgiscript. TERM is ng.
      kill USR1 => $self->{kidpid};
      waitpid($self->{kidpid}, 0);

      if (-e $self->{sockfile}) {
	# print STDERR "# removing sockfile $self->{sockfile}\n";
	unlink $self->{sockfile};
	rmdir dirname($self->{sockfile});
      }
    }
  }

  sub parse_result {
    my MY $self = shift;
    # print map {"#[[$_]]\n"} split /\n/, $result;
    my $res = $self->{res} = HTTP::Response->parse(shift);
    if (defined $res) {
      $res->request($self->{last_request});
      $self->{cookie_jar} //= do {
	require HTTP::Cookies;
	HTTP::Cookies->new();
      };
      $self->{cookie_jar}->extract_cookies($res);
    }
    $res;
  }

  sub bake_cookies {
    my MY $self = shift;
    return unless $self->{cookie_jar};
    $self->{cookie_jar}->add_cookie_header($self->{last_request});
    $self->{last_request}->header('Cookie');
  }

  # Poor-man's emulation of WWW::Mechanize.
  # These members are readonly from client.
  # ($self->cookie_jar($x) has no results)
  sub cookie_jar {
    my MY $self = shift; $self->{cookie_jar};
  }

  sub content {
    my MY $self = shift;
    unless (defined $self->{res}) {
      undef;
    } elsif (ref $self->{res}) {
      $self->{res}->content;
    } else {
      $self->{res};
    }
  }

  sub title {
    my MY $self = shift;
    defined (my $res = $self->content) or return undef;
    my ($title) = $res =~ m{<title>(.*?)</title>}s or return $res;
    HTML::Entities::decode_entities($title);
  }

  sub decode_entities {
    (my MY $self, my $str) = @_;
    HTML::Entities::decode_entities($str);
  }

  sub content_nocr {
    my MY $self = shift;
    defined (my $res = $self->content)
      or return undef;

    $res =~ s/\r//g;
    $res =~ s/\n+$/\n/;
    $res;
  }

  use Carp;
  use YATT::Lite::Util qw(encode_query);
  sub is_coverage_mode {
    my ($pack) = @_;
    my $symtab = (my $root = \%::);
    foreach my $ns (qw(Devel:: Cover::)) {
      my $glob = $symtab->{$ns}
	or return 0;
      $symtab = *{$glob}{HASH}
	or return 0;
    }
    return 1;
  }
}

#========================================
{
  package
    YATT::Lite::Test::TestFCGI::Auto; sub MY () {__PACKAGE__}
  use parent qw(YATT::Lite::Test::TestFCGI);

  sub class {
    my $pack = shift;
    if (eval {require FCGI::Client}) {
      'YATT::Lite::Test::TestFCGI::FCGIClient';
    } elsif ($pack->which('cgi-fcgi')) {
      'YATT::Lite::Test::TestFCGI::cgi_fcgi';
    }
  }
}

{
  package
    YATT::Lite::Test::TestFCGI::FCGIClient; sub MY () {__PACKAGE__}
  use parent qw(YATT::Lite::Test::TestFCGI);
  use YATT::Lite::MFields qw(connection raw_error);

  sub fork_server {
    my $self = shift;
    local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    $self->SUPER::fork_server(@_);
  }

  sub check_skip_reason {
    my MY $self = shift;

    my $reason = $self->SUPER::check_skip_reason;
    return $reason if $reason;

    unless (eval {require FCGI::Client}) {
      return 'FCGI::Client is not installed';
    }
    return
  }

  use Carp;
  use YATT::Lite::Util qw(terse_dump);
  sub request {
    (my MY $self, my ($method, $path, $query, $want_error)) = @_;
    croak "Should run fork_server before request" unless $self->{kidpid};

    require FCGI::Client;
    my $client = FCGI::Client::Connection->new
      (sock => $self->mkclientsock($self->{sockfile})
       , (timeout => (YATT::Lite::Util::is_debugging() ? 1800 :
                      $self->is_coverage_mode ? 120 : 10))
     );

    my $env = {REQUEST_METHOD    => uc($method)
	       , GATEWAY_INTERFACE => "FCGI::Client"
	       , REQUEST_URI     => $path
	       , PATH_INFO       => $path
	       , DOCUMENT_ROOT   => $self->{cf_rootdir}
	       , PATH_TRANSLATED => "$self->{cf_rootdir}$path"
	       , REDIRECT_STATUS => 200
	      };
    my @content;
    if (defined $query) {
      if ($env->{REQUEST_METHOD} eq 'GET') {
	$env->{QUERY_STRING} = $self->encode_query($query);
      } elsif ($env->{REQUEST_METHOD} eq 'POST') {
	$env->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
	my $enc = $self->encode_query($query);
	push @content, $enc;
	$env->{CONTENT_LENGTH} = length($enc);
      }
    }

    $self->{last_request} = do {
      require HTTP::Request;
      my $req = HTTP::Request->new($env->{REQUEST_METHOD}
				   , "http://localhost$path");
    };

    if (my $cookies = $self->bake_cookies()) {
      $env->{HTTP_COOKIE} = $cookies;
    }

    print STDERR "# FCGI_REQUEST: ", terse_dump($env, @content), "\n"
      if $self->{cf_debug_fcgi};

    ($self->{raw_result}, $self->{raw_error}) = $client->request
      ($env, @content);

    print STDERR "# FCGI_RAW_RESULT: ", terse_dump($self->{raw_result}), "\n"
      if $self->{cf_debug_fcgi};
    print STDERR "# FCGI_RAW_ERROR: ", terse_dump($self->{raw_error}), "\n"
      if $self->{cf_debug_fcgi};

    if (defined $self->{raw_error} and $self->{raw_error} ne '') {
      if ($want_error) {
	$self->{res} = $self->{raw_error};
	return;
      }
      print STDERR map {"# ERR: $_\n"} split /\r?\n/, $self->{raw_error};
      die "error occured: " . terse_dump($method, $path, $query);
    }

    # print STDERR "# ANS: ", terse_dump($self->{raw_result}, $self->{raw_error}), "\n";

    unless (defined $self->{raw_result}) {
      $self->{res} = undef;
      return;
    }

    # Status line を補う。
    my $res = do {
      if ($self->{raw_result} =~ m{^HTTP/\d+\.\d+ \d+ }) {
	$self->{raw_result}
      } elsif ($self->{raw_result} =~ /^Status: (\d+ .*)/) {
	"HTTP/1.0 $1\x0d\x0a$self->{raw_result}"
      } else {
	"HTTP/1.0 200 Faked OK\x0d\x0a$self->{raw_result}"
      }
    };
    $self->parse_result($res);
  }

}

#========================================
{
  package
    YATT::Lite::Test::TestFCGI::cgi_fcgi; sub MY () {__PACKAGE__}
  use parent qw(YATT::Lite::Test::TestFCGI);
  use YATT::Lite::MFields qw(wrapper);

  sub check_skip_reason {
    my MY $self = shift;

    my $reason = $self->SUPER::check_skip_reason;
    return $reason if $reason;

    $self->{wrapper} = MY->which('cgi-fcgi')
      or return 'cgi-fcgi is not installed';

    unless (-x $self->{cf_fcgiscript}) {
      return 'fcgi fcgiscript is not runnable';
    }

    return;
  }

  use File::Basename;
  use IPC::Open2;

  sub request {
    (my MY $self, my ($method, $path, $query)) = @_;
    # local $ENV{SERVER_SOFTWARE} = 'PERL_TEST_FCGI';
    local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    my $is_post = (local $ENV{REQUEST_METHOD} = uc($method)
		   =~ m{^(POST|PUT)$});
    local $ENV{REQUEST_URI} = $path;
    local $ENV{DOCUMENT_ROOT} = $self->{cf_rootdir};
    local $ENV{PATH_TRANSLATED} = "$self->{cf_rootdir}$path";
    local $ENV{QUERY_STRING} = $self->encode_query($query)
      unless $is_post;
    local $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded'
      if $is_post;
    my $enc = $self->encode_query($query);
    local $ENV{CONTENT_LENGTH} = length $enc
      if $is_post;

    # XXX: open3
    my $kid = open2 my $read, my $write
      , $self->{wrapper}, qw(-bind -connect) => $self->{sockfile}
	or die "Can't invoke $self->{wrapper}: $!";
    if ($is_post) {
      print $write $enc;
    }
    close $write;

    #XXX: Status line?
    #XXX: waitpid
    $self->parse_result(do {local $/; <$read>});
  }
}

1;
