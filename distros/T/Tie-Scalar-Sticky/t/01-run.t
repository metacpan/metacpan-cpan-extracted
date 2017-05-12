#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;

use Tie::Scalar::Sticky;

tie my $sticky, 'Tie::Scalar::Sticky';

$sticky = 5;
is($sticky,5,'assigned digit');

$sticky = undef;
is($sticky,5,'rejected undef');

$sticky = 0;
is($sticky,0,'assigned zero as digit');

$sticky = undef;
is($sticky,0,'rejected undef');

$sticky = 'a';
is($sticky,'a','assigned alpha');

$sticky = '';
is($sticky,'a','rejected empty string');

$sticky = '0';
is($sticky,0,'assigned zero as char');


tie my $sticky2, 'Tie::Scalar::Sticky' => qw/ foo bar /;

$sticky2 = 5;
is($sticky2,5,'assigned digit');

$sticky2 = undef;
is($sticky2,5,'rejected undef');

$sticky2 = 0;
is($sticky2,0,'assigned zero as digit');

$sticky2 = undef;
is($sticky2,0,'rejected undef');

$sticky2 = 'a';
is($sticky2,'a','assigned alpha');

$sticky2 = '';
is($sticky2,'a','rejected empty string');

$sticky2 = '0';
is($sticky2,0,'assigned zero as char');

$sticky2 = 'foo';
is($sticky2, 0,'rejected "foo"');

$sticky2 = 'bar';
is($sticky2, 0,'rejected "bar"');
