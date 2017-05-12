#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 14;

use lib (File::Spec->catdir($Bin, 'lib'));

eval { require GoodWithSubclass };
is $@, '', 'require: module using true';
is GoodWithSubclass::Good(), 'GoodWithSubclass', 'require: module loaded OK';

# test idempotence
eval { require GoodWithSubSubclass };
is $@, '', 'require: module using true';
is GoodWithSubSubclass::Good(), 'GoodWithSubSubclass', 'require: module loaded OK';

eval { require UglyWithSubclass };
is $@, '', 'require: module using true';
is UglyWithSubclass::Ugly(), 'UglyWithSubclass', 'require: module loaded OK';

eval { require UglyWithSubSubclass };
is $@, '', 'require: module using true';
is UglyWithSubSubclass::Ugly(), 'UglyWithSubSubclass', 'require: module loaded OK';

eval { require Bad };
like $@, qr{Bad.pm did not return a true value\b}, 'require: module not using true';;

eval { require 'good_with_subclass.pl' };
is $@, '', 'require: script using true';
is good_with_subclass(), 'good_with_subclass', 'require: script loaded OK';

eval { require 'good_with_sub_subclass.pl' };
is $@, '', 'require: script using true';
is good_with_sub_subclass(), 'good_with_sub_subclass', 'require: script loaded OK';

eval { require 'bad.pl' };
like $@, qr{bad.pl did not return a true value\b}, 'require: script not using true';
