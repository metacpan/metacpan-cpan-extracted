#!perl -T

use 5.010;
use strict;
use warnings;

#use Data::Dump::OneLine qw(dump1);
use Test::More 0.98;
use Text::sprintfn;

# [fmt, args, res], ...
my @tests = (
    # no named, must be same as sprintf
    ['<%%>', [], "<%>"], # %%
    ['<%d>', [4], "<4>"], # simple
    ['<% 4d>', [4], "<   4>"], # flag (1)
    ['<% +4d>', [4], "<  +4>"], # flag (2)
    ['<%vd>', ["ABC"], "<65.66.67>"], # vector flag (1)
    ['<%*vd>', [":", "ABC"], "<65:66:67>"], # vector flag (2)
    ['<%04d>', [4], "<0004>"], # width
    ['<%-5d>', [-4], "<-4   >"], # width (2, negative)
    ['<%*d>', [4, 5], "<   5>"], # width *
    ['<%*d> <%d>', [4, 5, 6], "<   5> <6>"], # width * (2)
    ['<%5.2f>', [4], "< 4.00>"], # width + precision
    ['<%*.2f>', [4, 5], "<5.00>"], # width + precision (2)
    ['<%*.*f>', [4, 5, 6], "<6.00000>"], # width + precision (3)
    # FUDGED: perl < 5.23 give 4.0000 while newer perls give 5.0000
    #['<%*1$.*f>', [4, 5, 10], "<5.0000>"], # width + precision (4)
    ['<%2$d>', [-4, 5], "<5>"], # param index
    ['<%2$-3d> <%.*f> <%d>', [4, 5, 6, 7], "<5  > <5.0000> <6>"], # combo (1)

    # with named but no hash provided, must be same as sprinf (albeit with warnings)
    # DISABLED: has warnings
    #['<%(v1)d> N', [4, 5], "<%(v1)d> N"], # simple (1)

    # with named
    ['<%(v1)$d>', [{v1=>10}, 4, 5], "<10>"], # simple (1)
    ['<%(v1)d>', [{v1=>10}, 4, 5], "<10>"], # simple (1b, $ optional)
    ['<%(v1)d> <%d>', [{v1=>10}, 4, 5], "<10> <4>"], # simple (2)
    ['<%(v1)d> <%(v1)d> <%d> <%(v2)d> <%d>',
     [{v1=>10, v2=>2}, 4, 5], "<10> <10> <4> <2> <5>"], # simple (3)
    ['<%(v1)04d>', [{v1=>10}, 4, 5], "<0010>"], # flag + width
    ['<%(v1)vd>', [{v1=>"DE"}, "ABC"], "<68.69>"], # vector flag (1)
    ['<%(v1)*vd>', [{v1=>"DE"}, ":", "ABC"], "<68:69>"], # vector flag (2)
    ['<%(v1)(v2)d>', [{v1=>10, v2=>3}, 4, 5], "< 10>"], # named width
    ['<%5.(v2)f>', [{v1=>10, v2=>2}, 4, 5], "< 4.00>"], # named precision
    ['<%(v1)5.2f>',
     [{v1=>10, v2=>2}, 4, 5], "<10.00>"], # named param + precision
    ['<%1$(v1).(v2)f>',
     [{v1=>10, v2=>2}, 4, 5], "<      4.00>"], # named width + precision
    ['<%(v1)(v1).(v2)f>',
     [{v1=>10, v2=>2}, 4, 5], "<     10.00>"], # named param + width + precision
    ['<%(v1)(v1).(v2)f> <%vd>',
     [{v1=>-6, v2=>2}, "AB"], "<-6.00 > <65.66>"], # combo 1
    ['<%(v1)(v1).(v2)f> <%*vd>',
     [{v1=>-6, v2=>2}, ":", "AB"], "<-6.00 > <65:66>"], # combo 1
    # XXX more combos
);

for my $t (@tests) {
    my ($fmt, $args, $res) = @$t;
    is(sprintfn($fmt, @$args), $res, "$fmt = $res");
}

DONE_TESTING:
done_testing();

__END__
    > <%04x> <%1$6.2f>',
     [10, 17],
     '<10> <0011> < 10.00>'],

    '<%(v1)03d> <%(v3)(v1)s> <%(v2)(v1).(v0)f>' =>
        [[{v1=>5, v2=>4, v3=>"foo", v0=>1}, 1, 2, 3],
         '<005> <  foo> <  4.0>'],
