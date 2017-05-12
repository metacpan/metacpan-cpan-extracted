#!perl -T

use strict;
use warnings;

BEGIN { $ENV{PERL_TEST_LEANER_USES_TEST_MORE} = 1 }

use lib 't/lib';
use Test::Leaner::TestImport 'test_import_arg';

test_import_arg;
