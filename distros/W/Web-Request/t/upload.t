#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

my @temp_files = ();

my $app = sub {
    my $env = shift;
    my $req = Web::Request->new_from_env($env);

    isa_ok $req->uploads->{foo}, 'HASH';
    is $req->uploads->{foo}->{filename}, 'foo2.txt';

    my @files = $req->upload('foo');
    is scalar(@files), 2;
    is $files[0]->filename, 'foo1.txt';
    is $files[1]->filename, 'foo2.txt';
    ok -e $files[0]->tempname;

    is join(', ', sort { $a cmp $b } $req->upload()), 'bar, foo';

    for (qw(foo bar)) {
        my $temp_file = $req->upload($_)->path;
        ok -f $temp_file;
        push @temp_files, $temp_file;
    }

    my $res = $req->new_response(status => 200);

    undef $req; # Simulate when we instantiate Web::Request multiple times

    # redo the test with the same $env
    $req = Web::Request->new_from_env($env);
    @files = $req->upload('foo');
    is scalar(@files), 2;
    is $files[0]->filename, 'foo1.txt';
    ok -e $files[0]->tempname;

    $res->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    $cb->(POST "/", Content_Type => 'form-data', Content => [
             foo => [ "t/data/foo1.txt" ],
             foo => [ "t/data/foo2.txt" ],
             bar => [ "t/data/foo1.txt" ],
         ]);
};

# Check if the temp files got cleaned up properly
ok !-f $_ for @temp_files;

done_testing;

