#
# make sure v5 works.
#
use strict;
use warnings;
use MyTest;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(generate_v5 type unparse variant);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

{
    generate_v5(my $bin, dns => 'www.example.com');
    ok 1,                'v5 seems ok';
    ok defined($bin),    'v5 defined';
    is length($bin), 16, 'v5 length';
    is type($bin), 5,    'v5 type';
    is variant($bin), 1, 'v5 variant';
    unparse $bin, my $foo;
    pass 'v3 unparse';
    note $foo;
}

{ # degenerate case
    generate_v5(my $bin, '' => 'www.example.com');
    ok 1,                'degen seems ok';
    ok defined($bin),    'degen defined';
    is length($bin), 16, 'degen length';
    is type($bin), 5,    'degen type';
    is variant($bin), 1, 'degen variant';
    unparse $bin, my $foo;
    pass 'v5 unparse';
    note $foo;
}

done_testing;
