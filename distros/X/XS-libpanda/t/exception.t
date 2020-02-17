use strict;
use warnings;
use lib 't';
use MyTest;
use Config;
use Test::More;
use Test::Catch;

plan skip_all => 'backtrace is not supported on 32bit systems' unless $Config{ivsize} == 8;
plan skip_all => 'available for linux only' unless $^O eq 'linux';

catch_run('[exception]');

done_testing;
