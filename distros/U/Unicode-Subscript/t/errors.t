use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Unicode::Subscript qw(subscript superscript);

throws_ok {
    subscript(undef);
} qr/undefined/;

throws_ok {
    superscript(undef);
} qr/undefined/;

throws_ok {
    subscript(2, 4);
} qr/too many arguments/;

throws_ok {
    superscript(2, 4);
} qr/too many arguments/;

