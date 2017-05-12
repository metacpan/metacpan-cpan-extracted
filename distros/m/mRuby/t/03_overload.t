use strict;
use warnings;

use Test::More tests => 3;
use mRuby::Bool qw/mrb_true mrb_false/;
use mRuby::Symbol qw/mrb_sym/;

is mrb_sym('foo'), 'foo', 'mrb_sym';
ok mrb_true(), 'mrb_true';
ok !mrb_false(), 'mrb_false';
