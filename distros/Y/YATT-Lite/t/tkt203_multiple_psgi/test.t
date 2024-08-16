#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------
use utf8;

use Test::More;
use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity/;


BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      diag("$req is not installed.");
      skip_all();
    }
    $req->import;
  }
}

#========================================

use Getopt::Long;

GetOptions("F|fork" => \ my $o_fork)
  or die "Unknown options";

my $testDir = $FindBin::Bin;

my @TESTEE = (
  [foo => sub {
    YATT::Lite::Factory->find_load_factory_script(dir => "$testDir/foo");
  }],
  [bar => sub {
    YATT::Lite::Factory->find_load_factory_script(dir => "$testDir/bar");
  }],
  [baz => sub {
    YATT::Lite::Factory->load_factory_script("$testDir/baz.psgi");
  }],
);

{
  if ($o_fork) {
    foreach my $testNo (0 .. $#TESTEE) {
      my @thisTest = list_beginning($testNo, \@TESTEE);
      my $title = join "", map {$_->[0]} @thisTest;
      defined (my $kidPid = fork)
        or BAIL_OUT("fork failed for testNo=$testNo, title=$title");
      if ($kidPid) {
        waitpid $kidPid, 0;
      } else {
        subtest "testNo=$testNo, title=$title", sub {
          plan tests => scalar @thisTest;
          doTest(@thisTest);
        };
        exit;
      }
    }
  } else {
    doTest(list_beginning(0, \@TESTEE))
  }
}

sub doTest {
  my (@thisTest) = @_;
  my @actualTest = map {
    my ($key, $builder) = @$_;
    [$key, $builder->()];
  } @thisTest;
  foreach my $item (@actualTest) {
    my ($key, $site) = @$item;
    my $dh = $site->get_lochandler('/');
    is $dh->mytest, uc($key), ref($dh).": $key->mytest";
  }
}

sub list_beginning {
  my ($pos, $list) = @_;
  map {
    $list->[$_];
  } map {
    ($_+$pos) % @$list;
  } 0 .. $#$list;
}

#========================================
done_testing();

