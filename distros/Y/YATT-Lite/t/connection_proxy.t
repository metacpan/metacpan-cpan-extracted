#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#
# GH-295: YATT::Lite::ConnectionProxy - $CON while capturing output.
# Output goes to the capture buffer, methods are delegated to the
# original connection.
#
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use utf8;

use YATT::t::t_preload; # To make Devel::Cover happy.

my $CLS = 'YATT::Lite::ConnectionProxy';
require_ok($CLS);
require YATT::Lite::Connection;

my $mkcon = sub {
  YATT::Lite::Connection->create(undef, noheader => 1, @_);
};

{
  my $con = $mkcon->(encoding => 'utf-8');
  print $con "before;";
  my $proxy;
  my $got = $CLS->capture($con, sub {
    ($proxy) = @_;
    print $proxy "captured";
  });
  is $got, "captured", "print is captured";
  is $con->buffer, "before;", "original output is not affected";

  ok $proxy->isa('YATT::Lite::Connection'), "proxy isa original class";
  ok $proxy->isa($CLS), "proxy isa $CLS";
  is $proxy->connection, $con, "connection returns the original";
}

{
  my $con = $mkcon->();
  $CLS->capture($con, sub {
    my ($CON) = @_;
    is $CON->cget('noheader'), 1, "cget is delegated";
    $CON->configure(encoding => 'utf-8');
    $CON->set_header('X-Test', 'test');
  });
  is $con->cget('encoding'), 'utf-8', "configure is delegated";
  is_deeply {$con->list_header}, {'X-Test' => 'test'}
    , "set_header is delegated";
}

{
  my $con = $mkcon->(encoding => 'utf-8');
  $CLS->capture($con, sub {
    my ($CON) = @_;
    ok my $sub = $CON->can('cget'), "can returns a method";
    is $sub->($CON, 'encoding'), 'utf-8'
      , "method from can works with the proxy";
    ok !$CON->can('no_such_method'), "can returns false for unknown";
    ok $CON->can('connection'), "can finds proxy's own method";

    eval {$CON->no_such_method};
    like $@, qr{^Can't locate object method "no_such_method" via package "YATT::Lite::Connection"}
      , "unknown method is reported with the original class";
  });
}

{
  my $con = $mkcon->();
  my $got = $CLS->capture($con, sub {
    my ($outer) = @_;
    print $outer "(";
    print $outer $CLS->capture($outer, sub {
      my ($inner) = @_;
      is $inner->connection, $con, "nested capture unwraps the proxy";
      print $inner "inner";
    });
    print $outer ")";
  });
  is $got, "(inner)", "nested capture";
}

{
  my $con = $mkcon->();
  $CLS->capture($con, sub {print {$_[0]} "x"});
  is $con->cget('noheader'), 1
    , "original connection is intact after proxy is destroyed";
}

{
  my $got = $CLS->capture(undef, sub {
    my ($fh) = @_;
    ok !Scalar::Util::blessed($fh) || !$fh->isa($CLS)
      , "non-connection gets a bare filehandle";
    print $fh "bare";
  });
  is $got, "bare", "bare filehandle capture";
}

{
  my $con = $mkcon->(encoding => 'utf-8');
  my $got = $CLS->capture($con, sub {print {$_[0]} "日本語"});
  ok utf8::is_utf8($got), "result is a character string";
  is $got, "日本語", "utf8 roundtrip";
}

done_testing();
