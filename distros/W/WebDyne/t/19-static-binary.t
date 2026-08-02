#!/bin/perl
#
#  Regression test for binary-safe static file responses
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use HTTP::Status qw(HTTP_OK);
use IO::String;
use File::Temp qw(tempdir);
use File::Spec;

SKIP: {
    skip 'Skipping binary static test: missing fake/PSGI static request modules', 6
        unless eval { require WebDyne::Request::Fake; require WebDyne::Request::PSGI::Static; 1 };

    require_ok('WebDyne::Request::Fake');

    my $tmp_dn=tempdir(CLEANUP => 1);
    my $source_fn=File::Spec->catfile($tmp_dn, 'pixel.png');
    my $source_bytes=pack('C*', 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0xFF, 0x10, 0x20, 0x7F, 0x80);

    open(my $source_fh, '>', $source_fn) || die "unable to open '$source_fn' for write, $!";
    binmode($source_fh);
    print {$source_fh} $source_bytes;
    close($source_fh) || die "unable to close '$source_fn', $!";

    my $body=q();
    my $select_fh=IO::String->new($body);
    my $r=WebDyne::Request::Fake->new(
        filename => $source_fn,
        select   => $select_fh,
        noheader => 1,
    );
    my $r_child=$r->lookup_file($source_fn);
    my $status=$r_child->run();
    $select_fh->close();

    is($status, HTTP_OK, 'binary static response returns HTTP_OK');
    is($r->headers_out->{'Content-Length'}, length($source_bytes), 'binary static response sets content length');
    is($r->headers_out->{'Content-Type'}, 'image/png', 'binary static response sets image content type');
    is(length($body), length($source_bytes), 'binary static response preserves byte length');
    is(unpack('H*', $body), unpack('H*', $source_bytes), 'binary static response preserves exact bytes');
}

done_testing();
