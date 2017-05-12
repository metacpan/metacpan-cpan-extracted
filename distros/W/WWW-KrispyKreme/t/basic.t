#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Pod;

BEGIN { use_ok('WWW::KrispyKreme') };

pod_file_ok('lib/WWW/KrispyKreme.pm', 'POD file looks good');

done_testing;
