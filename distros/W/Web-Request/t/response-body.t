#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Temp;
use FindBin;
use URI;
use Web::Response;

sub r($) {
    my $res = Web::Response->new([200]);
    $res->content(@_);
    return $res->finalize->[2];
}

is_deeply r "Hello World", [ "Hello World" ];
is_deeply r [ "Hello", "World" ], [ "Hello", "World" ];

{
    open my $fh, "$FindBin::Bin/body.t";
    is_deeply r $fh, $fh;
}

{
    my $foo = "bar";
    open my $io, "<", \$foo;
    is_deeply r $io, $io;
}

{
    my $uri = URI->new("foo"); # stringified object
    is_deeply r $uri, [ $uri ];
}

{
    my $tmp = File::Temp->new; # File::Temp has stringify method, but it is-a IO::Handle.
    is_deeply r $tmp, $tmp;
}

done_testing;
