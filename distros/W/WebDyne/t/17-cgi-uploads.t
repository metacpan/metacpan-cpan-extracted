#!/bin/perl
#
#  Regression test for WebDyne::CGI::Simple upload field association
#
use strict qw(vars);
use warnings;

use Test::More tests => 8;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use File::Temp qw(tempfile);

require_ok('WebDyne::CGI::Simple');

my $boundary='WebDyneUploadBoundary';
my $body=join('',
    "--$boundary\r\n",
    "Content-Disposition: form-data; name=\"file_a\"; filename=\"a.txt\"\r\n",
    "Content-Type: text/plain\r\n",
    "\r\n",
    "content-a\r\n",
    "--$boundary\r\n",
    "Content-Disposition: form-data; name=\"file_b\"; filename=\"b.txt\"\r\n",
    "Content-Type: text/plain\r\n",
    "\r\n",
    "content-b\r\n",
    "--$boundary--\r\n",
);

my ($fh, $upload_fn)=tempfile();
binmode($fh);
print {$fh} $body;
seek($fh, 0, 0);

local $ENV{'REQUEST_METHOD'}='GET';
my $cgi_or=CGI::Simple->new(undef);
local $ENV{'CONTENT_LENGTH'}=length($body);
local $ENV{'CONTENT_TYPE'}="multipart/form-data; boundary=$boundary";
local $ENV{'REQUEST_METHOD'}='POST';
local *STDIN=$fh;
$cgi_or->_parse_multipart($fh);
bless($cgi_or, 'WebDyne::CGI::Simple');

my $uploads_hr=$cgi_or->uploads();
isa_ok($uploads_hr, 'Hash::MultiValue');

my @param=sort $cgi_or->param();
is_deeply(\@param, [qw(file_a file_b)], 'multipart upload creates expected field params');

my @upload_name=sort $cgi_or->upload();
is_deeply(\@upload_name, [qw(a.txt b.txt)], 'multipart upload exposes expected uploaded filenames');

my @file_a=$uploads_hr->get_all('file_a');
my @file_b=$uploads_hr->get_all('file_b');

is(scalar(@file_a), 1, 'file_a has one associated upload');
is(scalar(@file_b), 1, 'file_b has one associated upload');

is($file_a[0]->filename(), 'a.txt', 'file_a maps to a.txt only');
is($file_b[0]->filename(), 'b.txt', 'file_b maps to b.txt only');
