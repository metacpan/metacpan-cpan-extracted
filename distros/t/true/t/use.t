#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 5;

use lib (File::Spec->catdir($Bin, 'lib'));

eval 'use Good';
is $@, '', 'use: Good using true';
is Good::Good(), 'Good', 'use: Good loaded OK';

eval 'use Bad';
like $@, qr{Bad.pm did not return a true value\b}, 'use: module not using true';;

eval 'use Ugly';
is $@, '', 'use: Ugly using true';
is Ugly::Ugly(), 'Ugly', 'use: Ugly loaded OK';
