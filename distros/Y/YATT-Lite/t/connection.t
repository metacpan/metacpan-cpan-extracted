#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

use YATT::Lite::Util qw(appname rootname catch ostream terse_dump);
sub myapp {join _ => MyTest => appname($0), @_}

use YATT::Lite::PSGIEnv;

require_ok('YATT::Lite');
require_ok('YATT::Lite::Connection');

my $i = 1;
{
  {
    my $T = "[noheader]";
    my $con = YATT::Lite::Connection->create(undef, noheader => 1);
    print {$con} "foo", "bar";
    print {$con} "baz";
    $con->flush;

    is $con->buffer, "foobarbaz", "$T Connection output";

    $con->set_header('Content-type', 'text/html');
    $con->set_header('X-Test', 'test');

    is_deeply {$con->list_header}
      , {'Content-type' => 'text/html', 'X-Test', 'test'}
	, "$T con->list_header";

    is $con->cget('encoding'), undef, "$T cget => undef";
    $con->configure(encoding => 'utf-8');
    is $con->cget('encoding'), 'utf-8', "$T cget => utf-8";

    eval {
      $con->error("Trivial error '%s'", 'MyError');
    };

    like $@, qr{^Trivial error 'MyError'}, $T . ' $con->error';

    eval {
      $con->raise(alert => "Trivial alert '%s'", 'MyAlert');
    };

    like $@, qr{^Trivial alert 'MyAlert'}, $T . ' $con->raise(alert)';
  }

  {
    my $con = YATT::Lite::Connection->create(undef, noheader => 1);
    eval {
      $con->raise_response([200, [], ["OK"]]);
    };
    is_deeply $@, [200, [], ["OK"]], "raise_response([TUPLE])";

    eval {
      $con->raise_response(sub {
                             my ($responder) = @_;
                             return sub {
                               my ($content) = @_;
                               [200, [], [$content]];
                             };
                           });
    };
    is_deeply $@->()->("OKOK"), [200, [], ["OKOK"]], "raise_response([delayed])";
  }

  SKIP:
  {
    my $T = '[with header]';
    skip "HTTP::Headers is not installed", 1
      if catch {require HTTP::Headers};
    my $con = YATT::Lite::Connection->create(undef);
    print {$con} "foo", "bar";
    print {$con} "baz";
    $con->flush;

    is $con->buffer, "foobarbaz", "$T Connection output";

    $con->set_header('Content-type', 'text/html');
    $con->set_header('X-Test', 'test');

    is_deeply {$con->list_header}
      , {'Content-type' => 'text/html', 'X-Test', 'test'}
	, "$T con->list_header";

    is $con->cget('encoding'), undef, "$T cget => undef";
    $con->configure(encoding => 'utf-8');
    is $con->cget('encoding'), 'utf-8', "$T cget => utf-8";

    eval {
      $con->error("Trivial error '%s'", 'MyError');
    };

    like $@, qr{^Trivial error 'MyError'}, $T . ' $con->error';

    eval {
      $con->raise(alert => "Trivial alert '%s'", 'MyAlert');
    };

    like $@, qr{^Trivial alert 'MyAlert'}, $T . ' $con->raise(alert)';
  }

  {
    my $T = '[logdump]';
    my $call = sub {
      my ($method, @args) = @_;
      my $con = YATT::Lite::Connection->create
	(undef, logfh => ostream(my $buffer = ""));
      $con->$method(@args);
      $buffer;
    };

    like $call->(logdump => 'auth.login' => 'foo', [], undef, {baz => 'bang'})
      , qr/^AUTH\.LOGIN: \[.*?\] 'foo', \[\], undef, \{'baz' => 'bang'\}/
	, "$T basic";

    like $call->(logdump => '/foo/bar')
      , qr|^DEBUG: \[.*?\] /foo/bar|
	, "$T (nontagword) => DEBUG";

    like $call->(logdump => [foo => 'bar'])
      , qr|^DEBUG: \[.*?\] \['foo','bar'\]|
	, "$T (struct) => DEBUG";

    like $call->(logdump => undef, 'bar')
      , qr/^UNDEF: \[.*?\] 'bar'/
	, "$T undef => UNDEF";
  }

  # ファイルに書けるか
  # header 周りの finalize はどうか。

  # もっと API を Plack::Request, Plack::Response に頼ったり、似せたりしてはどうか
  # もしくは Apache2::RequestRec に。
}

$i++;
{
  my $yatt = new YATT::Lite(app_ns => myapp($i)
			    , vfs => [data => {foo => 'bar'}]
			    , die_in_error => 1
			    , debug_cgen => $ENV{DEBUG});

  {
    package MyBackend1; sub MY () {__PACKAGE__}
    use base qw/YATT::Lite::Object/;
    use fields qw/cf_models cf_name/;
    sub model {
      (my MY $self, my $name) = @_;
      $self->{cf_models}{$name};
    }
  }
  my $backend = MyBackend1->new
    (name => 'Test', models => {foo => 'bar', bar => 3});;
  {
    my $con = YATT::Lite::Connection->create(undef, backend => $backend
					     , noheader => 1);
    is $con->backend(cget => 'name'), 'Test'
      , 'con->backend(method,@args)';
    is $con->model('foo'), 'bar'
      , 'con->model(foo)';
  }
}

# 次は YATT::Lite::WebMVC0::SiteApp から make_connection して...

$i++;
require_ok('YATT::Lite::WebMVC0::SiteApp');
{

  my $mux = YATT::Lite::WebMVC0::SiteApp->new
    (doc_root => rootname($0) . ".d"
     , app_ns => myapp($i)
     , site_prefix => '/myblog'
     , die_in_error => 1
     , debug_cgen => $ENV{DEBUG});

  {
    my $con = $mux->make_connection(undef, noheader => 1);
    print {$con} "foo", "bar";
    print {$con} "baz";
    $con->flush;

    is $con->buffer, "foobarbaz", "Connection output";

    is $con->request_path, "", "empty request path";

    is $con->site_location, '/myblog/', "con->site_location";
    is $con->site_loc, '/myblog/', "in short: con->site_loc";
  }

  my %base_env = qw{REQUEST_METHOD  GET
		    SERVER_NAME     0
		    SERVER_PORT     5000
		    SERVER_PROTOCOL HTTP/1.1
		    HTTP_REFERER    http://example.com/
		    psgi.url_scheme http
		 };

  {
    require Hash::MultiValue;
    my $mkcon = sub {
      my ($key, $class, $spec) = splice @_, 0, 3;
      $mux->make_connection(undef, noheader => 1, $key => $class->new(@$spec)
			    , @_)
    };

    is do {
      my $con = $mkcon->(hmv => 'Hash::MultiValue'
			 , [foo => 'a', foo => 'b', bar => 'baz']);
      $con->mkquery($con);
    }, "?foo=a&foo=b&bar=baz"
      , "mkquery";

    is do {
      my $con = $mkcon->(hmv => 'Hash::MultiValue'
			 , ["\x{86d9}\x{306e}\x{6b4c}\x{304c}" => "\x{805e}\x{3053}\x{3048}\x{3066}\x{304f}\x{308b}\x{3088}"]);
      $con->mkquery($con);
    }, '?%E8%9B%99%E3%81%AE%E6%AD%8C%E3%81%8C='
      . '%E8%81%9E%E3%81%93%E3%81%88%E3%81%A6%E3%81%8F%E3%82%8B%E3%82%88'
      , "mkquery() with utf8";

    is do {
      my $con = $mkcon->(hmv => 'Hash::MultiValue'
			 , [foo => 'a', foo => 'b', bar => 'baz']
			 , env => +{%base_env
				    , qw{PATH_INFO       /foo
					 REQUEST_URI     /foo}
				   }
			);
      $con->mkurl(undef, $con, local => 1);
    }, "/foo?foo=a&foo=b&bar=baz"
      , "mkurl(undef, CON) => same parameter";
  }

  my $THEME;
  {
    $THEME = '/foo';
    my %env = (%base_env
	       , qw{HTTP_HOST       0.0.0.0:5000
		    PATH_INFO       /foo
		    REQUEST_URI     /foo});
    my $con = $mux->make_connection(undef, env => \%env, noheader => 1);

    is $con->mkhost, '0.0.0.0:5000'
      , "[$THEME] mkhost()";
    is $con->mkprefix, 'http://0.0.0.0:5000'
      , "[$THEME] mkprefix()";
    is $con->mkurl, 'http://0.0.0.0:5000/foo'
      , "[$THEME] mkurl()";
    is $con->mkurl('bar'), 'http://0.0.0.0:5000/bar'
      , "[$THEME] mkurl(bar)";
    is $con->mkurl(undef, {bar => 'ba& z'})
      , 'http://0.0.0.0:5000/foo?bar=ba%26+z'
	, "[$THEME] mkurl(undef, {query})";
    is $con->mkurl(undef, undef, local => 1)
      , '/foo'
	, "[$THEME] mkurl(,,local => 1)";

    is $con->referer, 'http://example.com/', "[$THEME] referer";
  }

  {
    $THEME = '/';
    my %env = (%base_env
	       , qw{HTTP_HOST       0.0.0.0:5050
		    PATH_INFO       /
		    REQUEST_URI     /});
    my $con = $mux->make_connection(undef, env => \%env, noheader => 1);

    is $con->mkhost, '0.0.0.0:5050', "[$THEME] mkhost()";

    is $con->mkprefix('/'), 'http://0.0.0.0:5050/', "[$THEME] mkprefix(/)";

    '/foo' =~ m{/(\w+)}; # To test accidental-reference to $1, Fill $1.
    is $con->mkurl, 'http://0.0.0.0:5050/', "[$THEME] mkurl()";

    is $con->mkurl('bar'), 'http://0.0.0.0:5050/bar'
      , "[$THEME] mkurl(bar)";
    is $con->mkurl(undef, {bar => 'ba& z'})
      , 'http://0.0.0.0:5050/?bar=ba%26+z', "[$THEME] mkurl(undef, {query})";
    is $con->mkurl(undef, undef, local => 1), '/'
      , "[$THEME] mkurl(,,local => 1)";
  }

  {
    my $mkcon = sub {
      my Env $env;
      ($env->{HTTP_ACCEPT_LANGUAGE}) = @_;
      $mux->make_connection(undef, env => $env, noheader => 1);
    };

    my $con = $mkcon->(my $al = 'ja,en-US;q=0.8,en;q=0.6');
    is_deeply [$con->accept_language(detail => 1)]
      , [[ja => 1], ['en-US' => 0.8], [en => 0.6]]
	, "accept_language(detail) $al";

    is_deeply [$con->accept_language(long => 1)]
      , [qw/ja en_US en/]
	, "accept_language(long) $al";

    is_deeply [$con->accept_language]
      , [qw/ja en/]
	, "accept_language() $al";

    is scalar $con->accept_language
      , 'ja'
	, "scalar accept_language() $al";
  }


  {
    my $t = sub {
      my ($spec, $expect) = @_;
      my ($wantarray, $args) = ref $spec eq 'HASH'
	? (0, [%$spec]) : (1, $spec);
      my $con = $mux->make_connection(undef, @$args);
      my ($in, $out) = map {terse_dump($_)} ($args, $expect);
      if ($wantarray) {
	is_deeply [$con->mapped_path(@$args)], $expect
	  , "mapped_path($in) (array) => $out";
      } else {
	is_deeply scalar($con->mapped_path(@$args)), $expect
	  , "mapped_path($in) (scalar) => $out";

      }
    };

    $t->([], ["/"]);
    $t->(+{}, "/");

    $t->([location => "/", file => "foo.yatt", subpath => "/bar"]
	 , ["/foo.yatt", "/bar"]);
    $t->({location => "/", file => "foo.yatt", subpath => "/bar"}
	 , "/foo.yatt/bar");

    # If is_index is on, file should be ignored.
    $t->([location => "/foo", file => "index.yatt", subpath => "/bar"
	 , is_index => 1]
	 , ["/foo", "/bar"]);
    $t->({location => "/foo", file => "index.yatt", subpath => "/bar"
	 , is_index => 1}
	 , "/foo/bar");

    $t->([location => "/", file => "index.yatt", subpath => "/bar"
	 , is_index => 1]
	 , ["/", "/bar"]);
    $t->({location => "/", file => "index.yatt", subpath => "/bar"
	 , is_index => 1}
	 , "/bar");

  }
}

done_testing();
