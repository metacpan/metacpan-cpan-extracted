#!/bin/perl
#
#  Coverage for multipart parsing via WebDyne::CGI::Simple->new($r)
#
use strict qw(vars);
use warnings;

use Test::More tests => 4;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use File::Temp qw(tempfile);

require_ok('WebDyne::CGI::Simple');

my $boundary='WebDyneWrapperBoundary';
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

my ($fh)=tempfile();
binmode($fh);
print {$fh} $body;
seek($fh, 0, 0);

my $r=WebDyne::Test::MultipartRequest->new(
    fh             => $fh,
    content_length => length($body),
    headers        => { 'content-type' => "multipart/form-data; boundary=$boundary" },
);
my $cgi_or=WebDyne::CGI::Simple->new($r);

is_deeply([sort $cgi_or->param()], [qw(file_a file_b)], 'wrapper-created CGI object exposes multipart field params');
is_deeply([sort $cgi_or->upload()], [qw(a.txt b.txt)], 'wrapper-created CGI object exposes uploaded filenames');
my $uploads_hr=$cgi_or->uploads();
is_deeply([sort map { $_->filename() } $uploads_hr->get_all('file_a')], ['a.txt'], 'wrapper-created CGI object maps file_a upload correctly');


package WebDyne::Test::MultipartRequest;

sub new {
    my ($class, %arg)=@_;
    return bless(\%arg, $class);
}

sub headers_in {
    my ($self, $name)=@_;
    return $self->{'headers'}{lc($name)};
}

sub content_length {
    return shift()->{'content_length'};
}

sub input {
    my $self=shift();
    seek($self->{'fh'}, 0, 0);
    return $self->{'fh'};
}

sub method {
    return 'POST';
}

sub args {
    return undef;
}

sub body {
    return undef;
}
