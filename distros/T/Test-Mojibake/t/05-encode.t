#!perl -T
use strict;
use warnings qw(all);

use Encode;
use Test::Mojibake;

all_files_encoding_ok(all_files(), $INC{'Encode.pm'});
