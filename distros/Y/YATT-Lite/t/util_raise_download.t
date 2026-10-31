#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# raise_download($filename, $bytes, [@header]) is exported to templates
# (&yatt:raise_download()), so $filename is often request-derived.
# It must never be able to inject or split response headers, and
# non-ASCII names must be carried safely (RFC 8187 filename*=).
#
use utf8;

use Test::More;
use Test::Differences;
use Encode ();

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util qw(raise_download content_disposition_attachment);

my $BODY = "line1\nline2\n";

# raise_download dies with a PSGI tuple; capture it.
sub download {
  my ($filename, @rest) = @_;
  local $@;
  my $res = eval { YATT::Lite::Util->raise_download($filename, $BODY, @rest); 1 };
  return $@ if ref $@ eq 'ARRAY';
  die "raise_download did not raise a response: ".($@ // 'returned normally');
}

sub headers_of {
  my ($res) = @_;
  my %h; my @h = @{$res->[1]};
  while (my ($k, $v) = splice @h, 0, 2) { push @{$h{lc $k}}, $v }
  \%h;
}

#========================================
subtest "plain ascii filename is passed through", sub {
  my $res = download("report.csv");
  is $res->[0], 200;
  my $h = headers_of($res);
  is_deeply $h->{'content-disposition'}, ['attachment; filename="report.csv"'];
  is_deeply $h->{'content-length'}, [length $BODY];
  is_deeply $res->[2], [$BODY];
};

#========================================
subtest "no filename, no Content-Disposition", sub {
  foreach my $fn (undef, '', "\r\n", "\x00") {
    my $res = download($fn);
    my $h = headers_of($res);
    ok !exists $h->{'content-disposition'}
      , "no Content-Disposition for ".(defined $fn ? "'".join('', map {sprintf "\\x%02x", ord} split //, $fn)."'" : 'undef');
  }
};

#========================================
subtest "control characters never reach the header", sub {
  my @cases = (
    ["a\r\nSet-Cookie: x=1\r\n\r\n<html>.txt" => 'attachment; filename="aSet-Cookie: x=1<html>.txt"'],
    ["a\nX-Injected: y.txt"                    => 'attachment; filename="aX-Injected: y.txt"'],
    ["a\x00b.txt"                              => 'attachment; filename="ab.txt"'],
    ["tab\there.txt"                           => 'attachment; filename="tabhere.txt"'],
    ["del\x7f.txt"                             => 'attachment; filename="del.txt"'],
  );
  foreach my $case (@cases) {
    my ($fn, $expect) = @$case;
    my $res = download($fn);
    my $h = headers_of($res);
    is_deeply $h->{'content-disposition'}, [$expect]
      , "Content-Disposition for ".join('', map {$_ =~ /[\x00-\x1f\x7f]/ ? sprintf("\\x%02x", ord) : $_} split //, $fn);
    foreach my $v (@{$res->[1]}) {
      unlike $v, qr/[\r\n\x00]/, "no CR/LF/NUL anywhere in the header list";
    }
    is scalar(@{$res->[1]}), 6, "exactly three headers (no header was injected)";
  }
};

#========================================
subtest "quotes and backslashes go to filename*=", sub {
  my $res = download(q{he said "hi"\there.txt});
  my $h = headers_of($res);
  is_deeply $h->{'content-disposition'}, [
    q{attachment; filename="he said _hi__there.txt"; filename*=UTF-8''he%20said%20%22hi%22%5Cthere.txt}
  ];
};

#========================================
subtest "non-ascii filename (character string)", sub {
  my $res = download("日本 語.csv");
  my $h = headers_of($res);
  is_deeply $h->{'content-disposition'}, [
    q{attachment; filename="__ _.csv"; filename*=UTF-8''%E6%97%A5%E6%9C%AC%20%E8%AA%9E.csv}
  ] or diag $h->{'content-disposition'}[0];
  foreach my $v (@{$res->[1]}) {
    like $v, qr/^[\x20-\x7e]*\z/, "header values are ASCII only";
  }
};

#========================================
subtest "non-ascii filename (utf-8 bytes) is encoded as-is", sub {
  my $bytes = Encode::encode_utf8("日本.csv");
  my $res = download($bytes);
  my $h = headers_of($res);
  is_deeply $h->{'content-disposition'}, [
    q{attachment; filename="______.csv"; filename*=UTF-8''%E6%97%A5%E6%9C%AC.csv}
  ] or diag $h->{'content-disposition'}[0];
};

#========================================
subtest "extra headers are checked too", sub {
  my $res = download("x.bin", ["X-Extra" => "ok"]);
  my $h = headers_of($res);
  is_deeply $h->{'x-extra'}, ['ok'], "extra header is passed through";

  local $@;
  ok !eval { YATT::Lite::Util->raise_download("x.bin", $BODY, ["X-Extra" => "a\r\nSet-Cookie: x"]); 1 };
  like $@, qr/contains a control character/, "CR/LF in an extra header value croaks";

  ok !eval { YATT::Lite::Util->raise_download("x.bin", $BODY, ["Bad Name\r\n" => "v"]); 1 };
  like $@, qr/header name is not a token/, "non-token header name croaks";
};

#========================================
subtest "content_disposition_attachment is exported for app code", sub {
  is content_disposition_attachment("a.txt"), 'attachment; filename="a.txt"';
  is content_disposition_attachment(undef), undef;
  is content_disposition_attachment(''), undef;
};

done_testing();
