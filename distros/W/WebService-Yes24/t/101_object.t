use strict;
use warnings;
use Test::Base tests => 2;

use WebService::Yes24;

my $yes24 = WebService::Yes24->new;
ok $yes24;
isa_ok $yes24, 'WebService::Yes24';
