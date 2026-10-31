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
use 5.010; no if $] >= 5.017011, warnings => "experimental";

use Carp;
use YATT::Lite::Breakpoint;
use YATT::Lite::Util qw(ostream lexpand);
use YATT::Lite::Test::XHFTest2; # To import Item class.
use base qw(YATT::Lite::Test::XHFTest2); # XXX: Redundant, but required.
use YATT::Lite::MFields;

BEGIN {
  foreach my $req (qw(Plack)) {
    unless (eval qq{require $req}) {
      plan skip_all => "$req is not installed."; exit;
    }
  }
}


use YATT::Lite::WebMVC0::SiteApp::CGI;
use YATT::t::t_preload; # To make Devel::Cover happy.

my MY $tests = MY->load_tests([dir => "$FindBin::Bin/../html"]
			      , @ARGV ? @ARGV : $FindBin::Bin);
$tests->enter;

plan $tests->test_plan;

my $dispatcher = $tests->load_dispatcher;
$dispatcher->configure(is_psgi => 0);

foreach my File $sect (@{$tests->{_files}}) {
  my $dir = $tests->{dir};
  my $sect_name = $tests->file_title($sect);
  foreach my Item $item (@{$sect->{_items}}) {
  SKIP: {
      if ($item->{PERL_MINVER} and $] < $item->{PERL_MINVER}) {
	Test::More::skip "by perl-$] < PERL_MINVER($item->{PERL_MINVER}) $sect_name", 1;
      }

      if (my $action = $item->{ACTION}) {
	my ($method, @args) = @$action;
	my $sub = $tests->can("action_$method")
	  or die "No such action: $method";
	$sub->($tests, @args);
	next;
      }

      my %env = (DOCUMENT_ROOT => $dir
		 , PATH_INFO => "/$item->{FILE}"
		 , PATH_TRANSLATED => "$dir/$item->{FILE}"
		);

      $item->{METHOD} //= 'GET';
      my $T = defined $item->{TITLE} ? "[$item->{TITLE}]" : '';

      my $con = ostream(my $buffer);
      eval {
	if ($item->{BREAK}) {
	  YATT::Lite::Breakpoint::breakpoint();
	}
	my $params = $item->{PARAM};
	if (defined $params) {
	  if (ref $params eq 'ARRAY'
	      and grep(ref $_ eq 'HASH', @$params)
	      or ref $params eq 'HASH'
	      and grep(ref $_ eq 'HASH', values %$params)) {
	    croak "HASH value is not allowed in PARAM block!";
	  }
	}
	$dispatcher->cf_let([noheader => 0
			     , lexpand($item->{SITE_CONFIG})]
			    , runas => cgi => $con, \%env
			    , [$params])
      };

      my $header;
      if ($item->{ERROR}) {
	like $@, qr{$item->{ERROR}}
	  , "[$sect_name] $T ERROR $item->{METHOD} $item->{FILE}";
	next;
      } elsif (ref $@ eq 'SCALAR' and ${$@} eq 'DONE') {
	# Request is completed.
      } elsif (ref $@ eq 'ARRAY' and @{$@} == 3) {
	# PSGI triple was raised.
	$header = join("\n", @{$@->[1]});
        $buffer ||= join("\n", @{$@->[2]});
      } elsif ($@) {
	Test::More::fail $item->{FILE};
	Test::More::diag $@;
	next;
      }

      if (not $header
          and $buffer =~ s/\A((?:[^\n\r]+\r?\n)*\r?\n)//) {
	$header = $1;
      }

      if ($item->{METHOD} eq 'POST' and $item->{HEADER}) {
	$header //= trimlast(nocr($buffer));
	like $header, $tests->mkpat($item->{HEADER})
	  , "[$sect_name] $T POST $item->{FILE}";
      } elsif (ref $item->{BODY}) {
	like nocr($buffer), $tests->mkseqpat($item->{BODY})
	  , "[$sect_name] $T $item->{METHOD} $item->{FILE}";
      } else {
	eq_or_diff trimlast(nocr($buffer)), $item->{BODY}
	  , "[$sect_name] $T $item->{METHOD} $item->{FILE}";
      }
    }
  }
}

sub test_plan {
  my MY $self = shift;
  # XXX: This is overkill!
  foreach my File $file (@{$self->{_files}}) {
    if ($file->{USE_COOKIE}) {
      return skip_all => "Cookie is not yet supported in offline.t";
    }
  }
  $self->SUPER::test_plan;
}
