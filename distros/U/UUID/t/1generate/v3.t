#
# make sure v3 works.
#
use strict;
use warnings;
use MyTest;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v3 type unparse variant);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v3(my $bin, dns => 'www.example.com');
    ok 1,                'v3 seems ok';
    ok defined($bin),    'v3 defined';
    is length($bin), 16, 'v3 length';
    is type($bin), 3,    'v3 type';
    is variant($bin), 1, 'v3 variant';
    unparse $bin, my $foo;
    pass 'v3 unparse';
    note $foo;
}

{ # degenerate case
    generate_v3(my $bin, '' => 'www.example.com');
    ok 1,                'degen seems ok';
    ok defined($bin),    'degen defined';
    is length($bin), 16, 'degen length';
    is type($bin), 3,    'degen type';
    is variant($bin), 1, 'degen variant';
    unparse $bin, my $foo;
    pass 'v3 unparse';
    note $foo;
}

done_testing;
