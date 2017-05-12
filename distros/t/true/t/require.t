#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 6;

use lib (File::Spec->catdir($Bin, 'lib'));

eval { require Good };
is $@, '', 'require: module using true';
is Good::Good(), 'Good', 'require: module loaded OK';

eval { require Bad };
like $@, qr{Bad.pm did not return a true value\b}, 'require: module not using true';;

eval { require 'good.pl' };
is $@, '', 'require: script using true';
is good(), 'good', 'require: script loaded OK';

eval { require 'bad.pl' };
like $@, qr{bad.pl did not return a true value\b}, 'require: script not using true';
