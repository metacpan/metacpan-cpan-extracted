#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 9;

use lib (File::Spec->catdir($Bin, 'lib'));

eval 'use GoodWithSubclass';
is $@, '', 'use: GoodWithSubclass using true';
is GoodWithSubclass::Good(), 'GoodWithSubclass', 'use: GoodWithSubclass loaded OK';

eval 'use GoodWithSubSubclass';
is $@, '', 'use: GoodWithSubSubclass using true';
is GoodWithSubSubclass::Good(), 'GoodWithSubSubclass', 'use: GoodWithSubSubclass loaded OK';

eval 'use Bad';
like $@, qr{Bad.pm did not return a true value\b}, 'use: module not using true';;

eval 'use UglyWithSubclass';
is $@, '', 'use: UglyWithSubclass using true';
is UglyWithSubclass::Ugly(), 'UglyWithSubclass', 'use: UglWithSubclass loaded OK';

eval 'use UglyWithSubSubclass';
is $@, '', 'use: UglyWithSubSubclass using true';
is UglyWithSubSubclass::Ugly(), 'UglyWithSubSubclass', 'use: UglyWithSubSubclass loaded OK';
