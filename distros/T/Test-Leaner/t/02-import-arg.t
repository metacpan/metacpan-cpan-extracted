#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use lib 't/lib';
use Test::Leaner::TestImport 'test_import_arg';

test_import_arg;
