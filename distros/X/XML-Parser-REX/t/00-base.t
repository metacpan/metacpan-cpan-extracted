# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
BEGIN { use_ok('XML::Parser::REX') };
use warnings;
use strict;

my @tokens = XML::Parser::REX::ShallowParse ("<xml>Hello World</xml>");
is ($tokens[0], "<xml>");
is ($tokens[1], "Hello World");
is ($tokens[2], "</xml>");

Test::More::done_testing();
