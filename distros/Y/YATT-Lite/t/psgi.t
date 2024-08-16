#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;
use YATT::Lite::Breakpoint;
use YATT::t::t_preload; # To make Devel::Cover happy.

# A.K.A $fn:r, [file rootname] and file-name-sans-extension
sub rootname { my $fn = shift; $fn =~ s/\.\w+$//; join "", $fn, @_ }

BEGIN {
  # Because use YATT::Lite::DBSchema::DBIC loads DBIx::Class::Schema.
  foreach my $req (qw(Plack Plack::Test Plack::Response HTTP::Request::Common)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}

use File::Basename;
use Plack::Response;
use HTTP::Request::Common;
use YATT::Lite::WebMVC0::SiteApp;
use YATT::Lite::PSGIEnv;

my $rootname = untaint_any($FindBin::Bin."/".rootname($FindBin::RealScript));

sub is_or_like($$;$) {
  my ($got, $expect, $title) = @_;
  if (ref $expect) {
    like $got, $expect, $title;
  } else {
    is $got, $expect, $title;
  }
}

{
  my $site = YATT::Lite::WebMVC0::SiteApp
    ->new(app_root => $FindBin::Bin
	  , doc_root => "$rootname.d"
	  , app_ns => 'MyYATT'
	  , app_base => ['@psgi.ytmpl']
	  , namespace => ['yatt', 'perl', 'js']
	  , use_subpath => 1
          # , match_argsroute_first => 0
	  , (psgi_fallback => YATT::Lite::WebMVC0::SiteApp
	     ->psgi_file_app("$rootname.d.fallback"))
	 );

  is $site->cget('no_unicode'), undef, "No no_unicode, by default";

  foreach my $cf (qw/header_charset output_encoding tmpl_encoding/) {
    is $site->cget($cf), 'utf-8', "$cf is utf8 by default";
  }

  my $app = $site->to_app;
  {
    my $client = Plack::Test->create($app);

    sub test_action (&@) {
      my ($subref, $request, %params) = @_;

      my $path = $request->uri->path;

      $site->get_lochandler(dirname($path))
	->set_action_handler(basename($path) => $subref);

      $client->request($request, %params);
    }

    test_action {
      my ($this, $con) = @_;
      isa_ok $con, "YATT::Lite::WebMVC0::Connection";
    } GET "/virt";

    test_action {
      my ($this, $con) = @_;
      is $con->param('foo'), 'bar', "param('foo')";
    } GET "/virt?foo=bar";

    undef *test_action; # To free $site ref
  }

  {
    # mount_psgi and PATH_INFO test.
    my $t = sub {
      my ($mount_path, $req_path, $want_pathinfo, $more_desc) = @_;

      $site->mount_psgi(
        $mount_path,
        sub {
          my ($env) = @_;
          is $env->{PATH_INFO}, $want_pathinfo
            , "mount psgi $mount_path, GET $req_path => PT($want_pathinfo)"
              . ($more_desc // '')
              ;
          [200, [], "OK"]
        }
      );

      Plack::Test->create($app)->request(GET $req_path)
    };

    $t->("/mnt"  => "/mnt"  => ""
           , ": PT maybe '' for root");

    $t->("/mnt"  => "/mnt/"  => "/"
           , ": Nonempty PT must start with /");

    $t->("/mnt/" => "/mnt/" => "/"
           , ": Last / in mount path is not trimmed from PT");

    $t->("/mnt2" => "/mnt2"  => ""
           , ": mnt2, not mnt. Longest must win.");
  }

  {
    use Plack::Test;

    # mount_psgi and PATH_INFO test.
    use Plack::App::CGIBin;
    # /cgi-bin outside of doc_root.
    $site->mount_psgi(
      "/cgi-bin/",
      Plack::App::CGIBin->new(root => "$rootname.cgi-bin")
    );

    test_psgi $site->to_app, sub {
      my ($cb) = @_;
      my $res = $cb->(GET "/cgi-bin/test1.cgi?foo=bar");
      is $res->content, "\nQUERY_STRING: foo=bar\n";
    };

    # /cgi-bin inside of doc_root.
    $site->mount_psgi(
      "/cgi-bin/",
      Plack::App::CGIBin->new(root => "$rootname.d/cgi-bin")
    );

    test_psgi $site->to_app, sub {
      my ($cb) = @_;
      my $res = $cb->(GET "/cgi-bin/test1.cgi?x=y");
      is $res->content, "\nUnder doc_root, QUERY_STRING: x=y\n";
    };
  }

  {
    ;;
    $site->mount_static("/static" => "$rootname.static");
    test_psgi $site->to_app, sub {
      my ($cb) = @_;
      my $res = $cb->(GET "/static/test.yatt");
      is $res->content, "<?perl die?>\n";
    };
  }

  my $hello = sub {
    my ($id, $body, $rest) = @_;
    $rest //= "";
    <<END;
<div id="$id">
  Hello $body$rest!
</div>

END
  };

  my $out_index = $hello->(content => 'World;-)');
  my $out_beta = $hello->(beta => "world line");

  # XXX: subdir
  # XXX: .htyattrc.pl and entity
  #
  foreach my $test
    (["/", 200, $out_index, ["Content-Type", qq{text/html; charset="utf-8"}]]
     , ["/index", 200, $out_index]
     , ["/index.yatt", 200, $out_index]
     , ["/index.yatt/foo/bar", 200, $hello->(content => "Worldfoo/bar")]
     , ["/index/foo/bar", 200, $hello->(content => "Worldfoo/bar")]
     , ["/index/baz/1234", 200, $hello->(other => "ok?(1234)")]
     , ["/defaction.yatt?!!=", 200, "OK"]
     , ["/defaction.yatt", 200, "OK"]
     , ["/mid_defaction.yatt?!!=", 200, "OK2"]
     , ["/mid_defaction.yatt", 200, "OK2"]
     , ["/baz/5678", 200, $hello->(other => "ok?(5678)")]
     , ["/no_subpath/foobar", 404, qr{No such subpath}]
     , ["/test.lib/Foo.pm", 403, qr{Forbidden}]
     , ["/.htaccess", 403, qr{Forbidden}]
     , ["/hidden.ytmpl", 403, qr{Forbidden}]
     , ["/beta/world_line", 200, $out_beta]
     , ["/beta/world_line.yatt", 200, $out_beta]
     , ["/beta/world_line.yatt/baz", 200, $hello->(beta => "bazworld line")]
     , ["/beta/world_line/baz", 200, $hello->(beta => "bazworld line")]
     , ["/beta/world_line.yatt/edit/1234", 200, $hello->(edit => "1234's world")]
     , ["/beta/world_line/edit/1234", 200, $hello->(edit => "1234's world")]

     # psgi file handlers
     , [[psgi_static => "/test.css"], 200, "* {font-size: x-large; }\n"]
     , [[psgi_fallback => "/beta/fbck.html"], 200
	, "<h2>Fallback contents, outside of document root</h2>\n"]
    ) {
    unless (defined $test) {
      $DB::single = 1;
      1 if $DB::single; # To suppress warning
      next;
    }
    my ($path_or_spec, $code, $body, $header) = @$test;
    my ($theme, $path) = do {
      if (ref $path_or_spec) {
	("($path_or_spec->[0]) $path_or_spec->[1]", $path_or_spec->[1]);
      } else {
	($path_or_spec, $path_or_spec);
      }
    };
    my $tuple = do {
      my Env $env = Env->psgi_simple_env;
      $env->{PATH_INFO} = $path;
      $env->{SCRIPT_NAME} = '';
      $app->($env);
    };
    is $tuple->[0], $code, "[code] $theme";
    is_or_like join("", do {
      if (ref $tuple->[2] eq 'ARRAY') {
	@{$tuple->[2]}
      } elsif (my $sub = $tuple->[2]->can("getlines")) {
	$sub->($tuple->[2]);
      } else {
	die "Unknown tuple type: ". ref($tuple->[2]);
      }
    }), $body, "[body] $theme";
    if ($header and my @h = @$header) {
      my %header = @{$tuple->[1]};
      while (my ($key, $value) = splice @h, 0, 2) {
	is_or_like $header{$key}, $value, "[header][$key] $path";
      }
    }
  }

  {
    my $path;
    # For post
    my $post_env = sub {
      my ($path, $data) = @_;
      my Env $env = Env->psgi_simple_env;
      $env->{REQUEST_METHOD} = "POST";
      if (($env->{PATH_INFO} = $path) =~ s/\?(.*)//) {
	$env->{QUERY_STRING} = $1;
      }
      $env->{SCRIPT_NAME} = '';
      $data //= "";
      $env->{CONTENT_LENGTH} = length $data;
      $env->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
      open my $fh, '<', \ $data or die "Can't open memstream: $!";
      $env->{'psgi.input'} = $fh;
      $env;
    };

    {
      my $theme = "POST ";
      my $res = $app->($post_env->(my $p = "/?~~=qux", "any=data1"));
      is $res->[0], 200, "$theme $p status";
      like join("", @{$res->[2]}), qr/Qux!/, "$theme $p body";
    }

    {
      my $theme = "POST redirect ";
      my $p = "/?!!=redir";
      my $res = Plack::Response->new
	(@{$app->($post_env->($p, "z=w"))});
      is $res->status, 302, "$theme $p status";
      is $res->headers->header('Location'), "/qux", "$theme $p location";
    }

    {
      my $theme = "render from action";
      my $res = $app->($post_env->(my $p = "/?!!=hello", "any=data"));
      is $res->[0], 200, "$theme $p status";
      is_or_like join("", @{$res->[2]})
	, $hello->(content => "World from action")
	  , "$theme $p body";
    }
  }
  {
    ;
    my $theme = "[route matching order]";
    my $get_env = sub {
      my ($path) = @_;
      my Env $env = Env->psgi_simple_env;
      $env->{PATH_INFO} = $path;
      $env->{SCRIPT_NAME} = '';
      $env;
    };
    {
      my $res = $app->($get_env->("/index2/doc/".(my $p = "hello.md")));
      is $res->[0], 200, "$theme $p status";
      is_or_like join("", @{$res->[2]})
	, "<h2>Render doc: hello.md</h2>\n"
	  , "$theme $p body";
    }
    {
      my $theme = "First action should match";
      my $res = $app->($get_env->("/index2/doc/".(my $p = "hello.gif")));
      is $res->[0], 200, "$theme $p status";
      is_or_like join("", @{$res->[2]})
	, "Action: $p"
	  , "$theme $p body";
    }
  }
}

{
  {
    package MyBackend1; sub MY () {__PACKAGE__}
    use base qw/YATT::Lite::Object/;
    use fields qw/base_path
		  paths
		  cf_name/;
    sub startup {
      (my MY $self, my $router, my @apps) = @_;
      my $docs = $self->{base_path} = $router->cget('doc_root');
      $docs =~ s,/+$,,;
      $docs = File::Spec->rel2abs($docs);
      foreach my $app (@apps) {
	my $dir = $app->cget('dir');
	$dir =~ s/^\Q$docs\E//;
        $dir =~ s{\\}{/}g; # XXX: Just to pass test on Win32...ummm
	push @{$self->{paths}}, $dir;
      }
    }

    sub paths {
      (my MY $self) = @_;
      sort @{$self->{paths}}
    }
  }
  my $backend = MyBackend1->new(name => 'backend test');
  my $app = YATT::Lite::WebMVC0::SiteApp
    ->new(app_root => $FindBin::Bin
	  , doc_root => "$rootname.d"
	  , app_ns => 'MyYATT2'
	  , backend => $backend
	 )
      ->to_app;

  is_deeply [$backend->paths]
    , ['', qw|/beta /cgi-bin /test.lib|]
    , "backend startup is called";
}

{
  my $t = sub {
    is_deeply [YATT::Lite::Factory->n_created, YATT::Lite::Factory->n_destroyed]
      , [2, 2], "Site apps are destroyed correctly.";
  };

  if ($] >= 5.018
      and not grep(defined && /^-MDevel::Cover/, $ENV{HARNESS_PERL_SWITCHES})
    ) {
    $t->();
  } else {
    TODO: {
      local $TODO = "Perl before 5.018 has problem about this test.";
      $t->();
    }
  }
}

done_testing();
