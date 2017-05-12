#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use Path::Tiny;
use Test::JsonAPI::Autodoc::Path;

use Test::More;

subtest 'relative path' => sub {
    my $got = Test::JsonAPI::Autodoc::Path->document_path("$FindBin::Bin/../doc");

    (my $filename = path($0)->basename) =~ s/\.t$//;
    my $expected = path($FindBin::Bin)->parent->child("doc/$filename.md");

    is $got->realpath, $expected->realpath, 'can use relative path';

    $got->remove_tree;
};

subtest 'default' => sub {
    my $got = Test::JsonAPI::Autodoc::Path->document_path();

    (my $filename = path($0)->basename) =~ s/\.t$//;
    my $expected = path($FindBin::Bin)->parent->child("docs/$filename.md");

    is $got->realpath, $expected->realpath, 'can use default path';

    $got->remove_tree;
};

subtest 'home dir path' => sub {
    my $got = Test::JsonAPI::Autodoc::Path->document_path('~/.test_jsonapi_autodoc_test_XXXXX');

    (my $filename = path($0)->basename) =~ s/\.t$//;
    my $expected = path($ENV{HOME})->child(".test_jsonapi_autodoc_test_XXXXX/$filename.md");

    is $got->realpath, $expected->realpath, 'can use home dir path';
    $got->parent->remove_tree;
};

done_testing;
