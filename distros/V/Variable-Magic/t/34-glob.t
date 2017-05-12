#!perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

BEGIN {
 load_or_skip_all('Symbol', undef, [ 'gensym' ]);
 plan tests => 2 * 17 + 1;
}

use Variable::Magic qw<cast dispell VMG_COMPAT_GLOB_GET>;

my %get = VMG_COMPAT_GLOB_GET ? (get => 1) : ();

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init_watcher
        [ qw<get set len clear free copy dup local fetch store exists delete> ],
        'glob';

local *a = gensym();

watch { cast *a, $wiz } +{ }, 'cast';

watch { local *b = *a } +{ %get }, 'assign to';

SKIP: {
 skip 'This failed temporarily between perls 5.13.1 and 5.13.8 (included)'
                            => 5 * 2 if "$]" >= 5.013_001 and "$]" <= 5.013_008;

 my $cxt = 'void contex';
 my $exp = { set => 1 };

 watch { *a = \1 }          $exp, "assign scalar slot in $cxt";
 watch { *a = [ qw<x y> ] } $exp, "assign array slot in $cxt";
 watch { *a = { u => 1 } }  $exp, "assign hash slot in $cxt";
 watch { *a = sub { } }     $exp, "assign code slot in $cxt";
 watch { *a = gensym() }    $exp, "assign glob in $cxt";
}

{
 my $cxt = 'scalar context';
 my $exp = { %get, set => 1 };
 my $v;

 $v = watch { *a = \1 }          $exp, "assign scalar slot in $cxt";
 $v = watch { *a = [ qw<x y> ] } $exp, "assign array slot in $cxt";
 $v = watch { *a = { u => 1 } }  $exp, "assign hash slot in $cxt";
 $v = watch { *a = sub { } }     $exp, "assign code slot in $cxt";
 $v = watch { *a = gensym() }    $exp, "assign glob in $cxt";
}

watch {
 local *b = gensym();
 watch { cast *b, $wiz } +{ }, 'cast 2';
} +{ }, 'scope end';

%get = () if "$]" >= 5.013_007;

watch { undef *a } +{ %get }, 'undef';

watch { dispell *a, $wiz } +{ %get }, 'dispell';
