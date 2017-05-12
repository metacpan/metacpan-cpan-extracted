#!perl

use strict;
use warnings;
use utf8;
use Path::Tiny;

use Test::More;
use Test::JsonAPI::Autodoc;

BEGIN {
    $ENV{TEST_JSONAPI_AUTODOC} = 1;
}

my $tempdir = Path::Tiny->tempdir('test-jsonapi-autodoc-XXXXXXXX');
set_documents_path($tempdir);

describe 'POST /foobar' => sub {
    ok 1;
};

(my $filename = path($0)->basename) =~ s/\.t$//;
$filename .= '.md';

eval { path("$tempdir/$filename")->openr_utf8 };
ok $@, "Not generate document if http_ok or plack_ok does not exist in describe";

done_testing;
