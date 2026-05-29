#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Zuzu::Web::PSGI::CLI;

my $exit_code = Zuzu::Web::PSGI::CLI::run(@ARGV);
exit $exit_code;
