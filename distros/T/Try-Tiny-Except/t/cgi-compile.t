#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "CGI::Compile required"
        unless eval { require CGI::Compile; 1 };
    plan tests => 4;
}

use Try::Tiny::Except ();
$Try::Tiny::Except::always_propagate=sub {
    (ref eq 'ARRAY' and
     @$_==2 and
     $_->[0] eq "EXIT\n");
};

$My::called=0;

my $code=CGI::Compile->new(return_exit_val=>1)->compile(\<<'CODE');
use strict;
use warnings;
use Try::Tiny;

$My::called++;

try {$My::called++};

$My::called++;
exit 19;
CODE

my $rc=$code->();
is $My::called, 3, 'check assumptions -- shared variable';
is $rc, 19, 'check assumptions -- exit code';



$My::called=0;

$code=CGI::Compile->new(return_exit_val=>1)->compile(\<<'CODE');
use strict;
use warnings;
use Try::Tiny;

$My::called++;

try {$My::called++; exit 13};

$My::called++;
exit 21;
CODE

$rc=$code->();
is $My::called, 2, 'exit inside try{} -- shared variable';
is $rc, 13, 'exit inside try{} -- exit code';

done_testing;
