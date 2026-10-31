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
    use fields qw/models name/;
    sub model {
      (my MY $self, my $name) = @_;
      $self->{models}{$name};
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
    (doc_root => rootname(MY->rel2abs($0)) . ".d"
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

    # GH-251: mapped_path now reproduces the requested url path:
    # site_prefix(/myblog) + location + request_file + subpath.

    $t->([], ["/myblog/"]);
    $t->(+{}, "/myblog/");

    # With request_file, the requested form is reproduced.
    $t->([location => "/", file => "foo.yatt", request_file => "foo"
	 , subpath => "/bar"]
	 , ["/myblog/foo", "/bar"]);
    $t->({location => "/", file => "foo.yatt", request_file => "foo"
	 , subpath => "/bar"}
	 , "/myblog/foo/bar");

    $t->({location => "/", file => "foo.yatt", request_file => "foo.yatt"
	 , subpath => "/bar"}
	 , "/myblog/foo.yatt/bar");

    # Without request_file (old-style construction), falls back to
    # the physical file name.
    $t->([location => "/", file => "foo.yatt", subpath => "/bar"]
	 , ["/myblog/foo.yatt", "/bar"]);
    $t->({location => "/", file => "foo.yatt", subpath => "/bar"}
	 , "/myblog/foo.yatt/bar");

    # If is_index is on, file should be ignored.
    $t->([location => "/foo", file => "index.yatt", subpath => "/bar"
	 , is_index => 1]
	 , ["/myblog/foo", "/bar"]);
    $t->({location => "/foo", file => "index.yatt", subpath => "/bar"
	 , is_index => 1}
	 , "/myblog/foo/bar");

    $t->([location => "/", file => "index.yatt", subpath => "/bar"
	 , is_index => 1]
	 , ["/myblog", "/bar"]);
    $t->({location => "/", file => "index.yatt", subpath => "/bar"
	 , is_index => 1}
	 , "/myblog/bar");

    # Explicit "/index" request (request_file given, not is_index).
    $t->({location => "/", file => "index.yatt", request_file => "index"
	 , subpath => "/bar"}
	 , "/myblog/index/bar");

  }

  # GH-251: site_path/site_url/current_path/current_url
  {
    $THEME = 'GH-251';
    my %env = (%base_env
	       , qw{HTTP_HOST       0.0.0.0:5000
		    PATH_INFO       /foo
		    REQUEST_URI     /myblog/foo?q=1});
    my $con = $mux->make_connection(undef, env => \%env, noheader => 1);

    is $con->site_path, '/myblog/', "[$THEME] site_path()";
    is $con->site_path("/admin/"), '/myblog/admin/'
      , "[$THEME] site_path(/admin/)";
    is $con->site_path("/admin/", {q => 'x y'}), '/myblog/admin/?q=x+y'
      , "[$THEME] site_path(/admin/, {query})";
    is $con->site_path("/admin/", [q => 'x', page => 2])
      , '/myblog/admin/?q=x&page=2'
      , "[$THEME] site_path(/admin/, [query])";

    is $con->site_url("/admin/"), 'http://0.0.0.0:5000/myblog/admin/'
      , "[$THEME] site_url(/admin/)";

    is $con->current_path, '/myblog/foo', "[$THEME] current_path()";
    is $con->current_path([page => 2]), '/myblog/foo?page=2'
      , "[$THEME] current_path([query])";
    is $con->current_url([page => 2])
      , 'http://0.0.0.0:5000/myblog/foo?page=2'
      , "[$THEME] current_url([query])";

    like do {local $@; eval {$con->site_path("admin/")}; $@}
      , qr{site_path requires a '/'-leading path}
      , "[$THEME] site_path(relative) should croak";

    like do {local $@; eval {$con->site_path("/admin/", "q")}; $@}
      , qr{query for site_path must be a HASH/ARRAY ref}
      , "[$THEME] site_path with non-ref query should croak";

    like do {local $@; eval {$con->site_path("/admin/", q => 1)}; $@}
      , qr{Too many arguments for site_path}
      , "[$THEME] site_path with flat key=>value pairs should croak";

    like do {local $@; eval {$con->current_path(page => 2)}; $@}
      , qr{Too many arguments for current_path}
      , "[$THEME] current_path with flat key=>value pairs should croak";
  }

  {
    $THEME = 'GH-251 current_path(CON)';
    require Hash::MultiValue;
    my $con = $mux->make_connection
      (undef, noheader => 1
       , hmv => Hash::MultiValue->new(foo => 'a', foo => 'b', bar => 'baz')
       , env => +{%base_env
		  , qw{PATH_INFO   /foo
		       REQUEST_URI /myblog/foo}});
    is $con->current_path($con), "/myblog/foo?foo=a&foo=b&bar=baz"
      , "[$THEME] current_path(CON) inherits current query params";
  }

  {
    $THEME = 'GH-251 raise_redirect';
    my %env = (%base_env
	       , qw{HTTP_HOST   0.0.0.0:5000
		    PATH_INFO   /foo
		    REQUEST_URI /myblog/foo});
    my $con = $mux->make_connection(undef, env => \%env, noheader => 1);
    my $err = do {
      local $@;
      eval { $con->raise_redirect($con->site_path("/auth/")) };
      $@;
    };
    is ref $err, 'ARRAY', "[$THEME] raise_redirect dies with PSGI tuple";
    is $err->[0], 302, "[$THEME] status 302";
    is +{@{$err->[1]}}->{Location}, '/myblog/auth/'
      , "[$THEME] Location header";
  }

  # GH-251: mkurl(,,mapped_path=>1) should keep mount prefix
  # and reproduce the requested file name form (request_file).
  {
    $THEME = 'GH-251 mkpath mapped_path';
    my %env = (%base_env
	       , 'yatt.script_name' => '/myblog'
	       , qw{HTTP_HOST   0.0.0.0:5000
		    PATH_INFO   /item/detail/3
		    REQUEST_URI /myblog/item/detail/3});
    my $con = $mux->make_connection
      (undef, env => \%env, noheader => 1
       , location => "/", file => "item.yatt", request_file => "item"
       , subpath => "/detail/3");

    is $con->mkurl(undef, undef, mapped_path => 1, local => 1)
      , '/myblog/item/detail/3'
      , "[$THEME] mapped_path base keeps mount prefix + requested form";

    is scalar($con->mapped_path), '/myblog/item/detail/3'
      , "[$THEME] mapped_path reproduces the requested url path";

    # When the request spelled the extension, it is reproduced.
    my $con_ext = $mux->make_connection
      (undef, env => \%env, noheader => 1
       , location => "/", file => "item.yatt", request_file => "item.yatt"
       , subpath => "/detail/3");
    is scalar($con_ext->mapped_path), '/myblog/item.yatt/detail/3'
      , "[$THEME] requested extension is reproduced";

    # Old-style construction (no request_file) falls back to the
    # physical file name.
    my $con_legacy = $mux->make_connection
      (undef, env => \%env, noheader => 1
       , location => "/", file => "item.yatt", subpath => "/detail/3");
    is scalar($con_legacy->mapped_path), '/myblog/item.yatt/detail/3'
      , "[$THEME] legacy fallback uses physical file name";

    # file_location also follows the request form (GH-251).
    is $con->file_location, '/myblog/item'
      , "[$THEME] file_location follows request form (ext-less)";
    is $con_ext->file_location, '/myblog/item.yatt'
      , "[$THEME] file_location follows request form (ext spelled)";
    is $con_legacy->file_location, '/myblog/item'
      , "[$THEME] file_location legacy fallback trims last ext";

    # page_location is canonical, independent of the request spelling.
    is $con->page_location, '/myblog/item'
      , "[$THEME] page_location is canonical";
    is $con_ext->page_location, '/myblog/item'
      , "[$THEME] page_location ignores request spelling";

    # is_current_file($path): site-rooted literal, same form as
    # site_path's argument.
    ok $con->is_current_file("/item")
      , "[$THEME] is_current_file(/item) (canonical form)";
    ok $con->is_current_file("/item.yatt")
      , "[$THEME] is_current_file(/item.yatt) (physical form)";
    ok $con_ext->is_current_file("/item")
      , "[$THEME] is_current_file is request-spelling independent";
    ok !$con->is_current_file("/other")
      , "[$THEME] is_current_file(/other) => false";
    ok !$con->is_current_file("/myblog/item")
      , "[$THEME] is_current_file is mount-prefix independent";

    my %env2 = (%base_env
		, 'yatt.script_name' => '/myblog'
		, qw{HTTP_HOST   0.0.0.0:5000
		     PATH_INFO   /zzz/detail/4
		     REQUEST_URI /myblog/zzz/detail/4});
    my $con2 = $mux->make_connection
      (undef, env => \%env2, noheader => 1
       , location => "/zzz/", file => "index.yatt", subpath => "/detail/4"
       , is_index => 1);

    is $con2->mkurl(undef, undef, mapped_path => 1, local => 1)
      , '/myblog/zzz/detail/4'
      , "[$THEME] is_index case should not produce double slash";

    ok $con2->is_current_file("/zzz/")
      , "[$THEME] is_current_file(/zzz/) (directory form for index)";
  }
}

# GH-259: mkquery($CON) should not reproduce POST body_parameters.
$i++;
SKIP:
{
  my $THEME = 'GH-259';
  skip "Plack::Request is not installed", 11
    if catch {require Plack::Request};
  require Hash::MultiValue;

  my $mux = YATT::Lite::WebMVC0::SiteApp->new
    (doc_root => rootname(MY->rel2abs($0)) . ".d"
     , app_ns => myapp($i)
     , site_prefix => '/myblog'
     , die_in_error => 1
     , debug_cgen => $ENV{DEBUG});

  my %base_env = qw{SERVER_NAME     0
		    SERVER_PORT     5000
		    SERVER_PROTOCOL HTTP/1.1
		    HTTP_REFERER    http://example.com/
		    psgi.url_scheme http
		 };

  my $make_con = sub {
    my ($method, $qs, $body, @rest) = @_;
    my Env $env = +{%base_env
		    , REQUEST_METHOD => $method
		    , PATH_INFO => '/foo'
		    , REQUEST_URI => '/myblog/foo' . (defined $qs ? "?$qs" : '')
		    , (defined $qs ? (QUERY_STRING => $qs) : ())};
    if (defined $body) {
      $env->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
      $env->{CONTENT_LENGTH} = length($body);
      open my $fh, '<', \ $body or die "Can't open memstream: $!";
      $env->{'psgi.input'} = $fh;
    }
    $mux->make_connection(undef, noheader => 1, is_psgi => 1
			  , env => $env
			  , cgi => Plack::Request->new($env), @rest);
  };

  ok $make_con->(POST => 'q=1', 'nx=secret')->has_content
    , "[$THEME] has_content: true for POST with body";
  ok ! $make_con->(GET => 'q=1', undef)->has_content
    , "[$THEME] has_content: false for GET";
  ok ! $mux->make_connection(undef, noheader => 1
			     , hmv => Hash::MultiValue->new(foo => 1))
    ->has_content
    , "[$THEME] has_content: false without env";

  {
    my $con = $make_con->(POST => 'q=1&m=a&m=b', 'nx=secret&token=t1');
    is scalar($con->mkquery($con)), '?q=1&m=a&m=b'
      , "[$THEME] mkquery(CON): query params only, original order";
    is $con->current_path($con), '/myblog/foo?q=1&m=a&m=b'
      , "[$THEME] current_path(CON): body params do not leak";
    is $con->mkurl(undef, $con, local => 1), '/myblog/foo?q=1&m=a&m=b'
      , "[$THEME] mkurl(undef, CON, local): body params do not leak";
    is $con->param('nx'), 'secret'
      , "[$THEME] body param is still accessible via param()";
  }

  {
    my $con = $make_con->(POST => undef, 'nx=secret');
    is $con->current_path($con), '/myblog/foo'
      , "[$THEME] POST without query string => bare path";
    is scalar($con->mkquery($con)), ''
      , "[$THEME] POST without query string => empty mkquery";
  }

  is do {
    my $con = $make_con->(POST => 'q=1', 'nx=secret'
			  , mkquery_with_body_params => 1);
    scalar($con->mkquery($con));
  }, '?nx=secret&q=1'
    , "[$THEME] mkquery_with_body_params restores old merged behavior";

  is do {
    my $con = $make_con->(GET => 'q=1&r=2', undef);
    scalar($con->mkquery($con));
  }, '?q=1&r=2'
    , "[$THEME] GET mkquery(CON) is unchanged";
}

# GH-259: SiteApp-level mkquery_with_body_params should reach connections.
$i++;
SKIP:
{
  my $THEME = 'GH-259 siteapp flag';
  skip "Plack::Request is not installed", 2
    if catch {require Plack::Request};

  my $mux = YATT::Lite::WebMVC0::SiteApp->new
    (doc_root => rootname(MY->rel2abs($0)) . ".d"
     , app_ns => myapp($i)
     , site_prefix => '/myblog'
     , die_in_error => 1
     , mkquery_with_body_params => 1);

  my $body = 'nx=secret';
  my Env $env = +{qw{SERVER_NAME     0
		     SERVER_PORT     5000
		     SERVER_PROTOCOL HTTP/1.1
		     psgi.url_scheme http}
		  , REQUEST_METHOD => 'POST'
		  , PATH_INFO => '/foo'
		  , REQUEST_URI => '/myblog/foo?q=1'
		  , QUERY_STRING => 'q=1'
		  , CONTENT_TYPE => 'application/x-www-form-urlencoded'
		  , CONTENT_LENGTH => length($body)};
  open my $fh, '<', \ $body or die "Can't open memstream: $!";
  $env->{'psgi.input'} = $fh;
  my $con = $mux->make_connection(undef, noheader => 1, is_psgi => 1
				  , env => $env
				  , cgi => Plack::Request->new($env));

  is scalar($con->mkquery($con)), '?nx=secret&q=1'
    , "[$THEME] flag on SiteApp restores merged behavior";
  is $con->current_path($con), '/myblog/foo?nx=secret&q=1'
    , "[$THEME] current_path(CON) with SiteApp-level flag";
}

{
  # GH-233: cf_pairs lists config items (fields without cf_ prefix).
  my $con = YATT::Lite::Connection->create(undef, noheader => 1
                                           , encoding => "utf-8");
  my %pairs = map {@$_} $con->cf_pairs;
  is $pairs{encoding}, "utf-8", "cf_pairs contains config items";
  ok exists $pairs{noheader}, "cf_pairs contains noheader";
  ok !exists $pairs{buffer}, "cf_pairs doesn't contain buffer";
  is_deeply [grep {/^_/} keys %pairs], [], "cf_pairs doesn't contain private fields";
}

done_testing();
