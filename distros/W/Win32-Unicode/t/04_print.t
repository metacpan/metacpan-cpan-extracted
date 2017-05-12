use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Test::Output;
use Win32::Unicode;
use File::Spec;

open STDERR, '>', File::Spec->devnull or die $!;

my $str = " I \x{2665} Perl";

stdout_is { printW($str) }  $str;
stdout_is { printfW("[%s]", $str) } "[$str]" ;
stdout_is { sayW($str) } "$str\n";

stderr_like { printW undef } qr/uninitialized/;
stderr_like { printfW undef } qr/uninitialized/;
stderr_like { warnW undef } qr/uninitialized/;

ok warnW($str), "warnW";
dies_ok { dieW($str) } "dieW";

TODO: {
    local $TODO = 'ToDo';
    stdout_is { printW STDOUT $str }  $str;
    stdout_is { printfW STDOUT "[%s]", $str } "[$str]" ;
    stdout_is { sayW STDOUT $str } "$str\n";
};

throws_ok { printW STDOUT, $str } qr/No comma allowed after filehandle/;
throws_ok { printfW STDOUT, $str } qr/No comma allowed after filehandle/;

done_testing;
