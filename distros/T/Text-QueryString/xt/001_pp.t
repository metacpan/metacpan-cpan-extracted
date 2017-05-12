use strict;
use Test::More;

local $ENV{PERL_TEXT_QUERYSTRING_BACKEND} = 'PP';
my @files =  <t/*.t>;
foreach my $f (@files) {
    subtest $f => sub {
        do $f;
    };
}
    