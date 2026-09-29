#!usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Spelling::Comment' => '0.002' };

Test::Spelling::Comment->import();
Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();

__DATA__
Async
async
DDTHH
DeepMock
definedness
delegator
Dep
Devel
ENV
eval'd
exps
GH
GV
HH
MRO
overridable
pos
SSZ
Str
subtest
subtests
TimeTravel
TODO
unmock
xt
YYYY
