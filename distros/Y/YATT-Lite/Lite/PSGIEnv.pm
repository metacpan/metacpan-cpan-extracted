package YATT::Lite::PSGIEnv; sub Env () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

my @PSGI_FIELDS;
BEGIN {
  @PSGI_FIELDS
    = qw/
	  HTTPS
	  GATEWAY_INTERFACE
	  REQUEST_METHOD
	  SCRIPT_NAME
	  SCRIPT_FILENAME
	  DOCUMENT_ROOT

	  PATH_INFO
	  PATH_TRANSLATED
	  REDIRECT_STATUS
	  REQUEST_URI
	  DOCUMENT_URI

	  QUERY_STRING
	  CONTENT_TYPE
	  CONTENT_LENGTH

	  SERVER_NAME
	  SERVER_PORT
	  SERVER_PROTOCOL
	  HTTP_USER_AGENT
	  HTTP_REFERER
	  HTTP_COOKIE
	  HTTP_FORWARDED
	  HTTP_HOST
	  HTTP_PROXY_CONNECTION
	  HTTP_ACCEPT

	  HTTP_ACCEPT_CHARSET
	  HTTP_ACCEPT_LANGUAGE
	  HTTP_ACCEPT_ENCODING

	  REMOTE_ADDR
	  REMOTE_HOST
	  REMOTE_USER
	  HTTP_X_REAL_IP
	  HTTP_X_CLIENT_IP
	  HTTP_X_FORWARDED_FOR

	  psgi.version
	  psgi.url_scheme
	  psgi.input
	  psgi.errors
	  psgi.multithread
	  psgi.multiprocess
	  psgi.run_once
	  psgi.nonblocking
	  psgi.streaming
	  psgix.session
	  psgix.session.options
	  psgix.logger
       /;
  our %FIELDS = map {$_ => ''} @PSGI_FIELDS;
}

use YATT::Lite::Util qw(ckeval globref define_const);

sub import {
  my ($myPack, @more_fields) = @_;

  my $callpack = caller;
  my $envpack = $callpack . "::Env";
  {
    my $sym = globref($callpack, 'Env');
    if (my $val = *{$sym}{CODE}) {
      my $old = $val->();
      croak "Conflicting definition of Env" unless $old eq $envpack;
    } else {
      define_const($sym, $envpack);
    }
  }
  {
    my $sym = globref($envpack, 'ISA');
    my $val;
    if ($val = *{$sym}{ARRAY} and @$val) {
      croak "Conflicting definition of ISA: @$val" unless grep {$_ eq $myPack} @$val;
    } else {
      *$sym = [$myPack];
    }
  }
  {
    my $sym = globref($envpack, 'FIELDS');
    my $fields = +{map {$_ => 1} @PSGI_FIELDS, @more_fields};
    if (my $val = *{$sym}{HASH}) {
      foreach my $f (keys %$fields) {
	unless ($val->{$f} == $fields->{$f}) {
	  croak "Conflicting definition of field $f";
	}
      }
    } else {
      *$sym = $fields;
    }
  }
}

sub psgi_fields {
  wantarray ? @PSGI_FIELDS : {map {$_ => 1} @PSGI_FIELDS};
}

sub psgi_simple_env {
  my ($pack) = shift;
  my Env $given = {@_};
  my Env $env = {};
  $env->{'psgi.version'} = [1, 1];
  $env->{'psgi.url_scheme'} = 'http';
  $env->{'psgi.input'} = \*STDIN;
  $env->{'psgi.errors'} = \*STDERR;
  $env->{'psgi.multithread'} = 0;
  $env->{'psgi.multiprocess'} = 0;
  $env->{'psgi.run_once'} = 0;
  $env->{'psgi.nonblocking'} = 0;
  $env->{'psgi.streaming'} = 0;

  $env->{PATH_INFO} = $given->{PATH_INFO} || '/';

  $env;
}

1;
