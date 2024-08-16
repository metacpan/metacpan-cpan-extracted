#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN {
  if (-d (my $dir = "$FindBin::RealBin/../../../../t")) {
    local (@_, $@) = $dir;
    do "$dir/t_lib.pl";
    die $@ if $@;
  }
}

use Cwd ();
my ($app_root);
BEGIN {
  if (-r __FILE__) {
    # detect where app.psgi is placed.
    $app_root = dirname(dirname(File::Spec->rel2abs(__FILE__)));
  } else {
    # older uwsgi do not set __FILE__ correctly, so use cwd instead.
    $app_root = Cwd::cwd();
  }
}
#----------------------------------------

use Test::More;

BEGIN {
  foreach my $req (qw(Plack::Test)) {
    unless (eval qq{require $req}) {
      plan(skip_all => "$req is not installed."); exit;
    }
  }
}

use Plack::Test;
use Plack::Util;

use Test::Refcount;

use YATT::Lite::Breakpoint;
use YATT::Lite::Util qw(lexpand);
use YATT::Lite::Test::XHFTest2;
use base qw(YATT::Lite::Test::XHFTest2);
use YATT::t::t_preload; # To make Devel::Cover happy.

my MY $tests = MY->load_tests([dir => "$FindBin::Bin/../html"]
			      , @ARGV ? @ARGV : $FindBin::Bin);
$tests->enter;

plan $tests->test_plan(+4); # Run 4 additional test.

use Cwd;
$ENV{YATT_DOCUMENT_ROOT} = cwd;
use YATT::Lite::Factory; sub Factory () {'YATT::Lite::Factory'}

{
ok(my $site = Factory->load_factory_script("$FindBin::Bin/../app.psgi")
   , "load_psgi");

is_refcount($site, 2, "refcount after load_factory_script(includes sub2self)");

test_psgi $site->to_app, sub {
  my ($cb) = shift;
  foreach my File $sect (@{$tests->{files}}) {
    my $dir = $tests->{cf_dir};
    my $sect_name = $tests->file_title($sect);
    foreach my Item $item (@{$sect->{items}}) {
    SKIP: {
	if ($item->{cf_PERL_MINVER} and $] < $item->{cf_PERL_MINVER}) {
	  Test::More::skip "by perl-$] < PERL_MINVER($item->{cf_PERL_MINVER}) $sect_name", 1;
	}

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

	$item->{cf_METHOD} //= 'GET';
	my $T = defined $item->{cf_TITLE} ? "[$item->{cf_TITLE}]" : '';

	my $res = do {
	  $site->cf_let([lexpand($item->{cf_SITE_CONFIG})]
			, sub {
			  $tests->run_psgicb($cb, $item);
			});
	};

	if ($item->{cf_ERROR}) {
	  (my $str = $res->content) =~ s/^Internal Server error\n//;
	  like $str, qr{$item->{cf_ERROR}}
	    , "[$sect_name] $T ERROR $item->{cf_METHOD} $item->{cf_FILE}";
	  next;
	} elsif ($item->{cf_STATUS}
                 ? $item->{cf_STATUS} == $res->code
                 : $res->code >= 300 && $res->code < 500) {
	  # fall through
	} elsif ($res->code != 200) {
	  Test::More::fail $item->{cf_FILE};
	  Test::More::diag $res->content;
	  next;
	}

	if ($item->{cf_METHOD} eq 'POST' and $item->{cf_HEADER}) {
	  my @header = @{$item->{cf_HEADER}};
	  while (my ($f, $v) = splice @header, 0, 2) {
	    my $name = "[$sect_name] $T POST $item->{cf_FILE} $f";
	    my $got = $res->header($f);
	    if (defined $got) {
	      like $got, qr/$v/, $name;
	    } else {
	      fail $name; diag("Header '$f' was undef");
	    }
	  }
	} elsif (ref $item->{cf_BODY}) {
	  like nocr($res->content), $tests->mkseqpat($item->{cf_BODY})
	    , "[$sect_name] $T $item->{cf_METHOD} $item->{cf_FILE}";
	} else {
	  eq_or_diff trimlast(nocr($res->content)), $item->{cf_BODY}
	    , "[$sect_name] $T $item->{cf_METHOD} $item->{cf_FILE}";
	}
      }
    }
  }
};

is_refcount($site, 1, "refcount after test_psgi");
}

is_deeply [YATT::Lite::Factory->n_created, YATT::Lite::Factory->n_destroyed]
  , [1, 1], "Site apps are destroyed correctly.";

sub base_url {
  shift; "http://localhost/";
}
