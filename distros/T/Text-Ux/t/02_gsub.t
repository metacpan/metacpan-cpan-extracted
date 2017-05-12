use strict;
use warnings;

use Test::More;
use Test::Warn;
use Text::Ux;

my $ux = Text::Ux->new;
$ux->build([qw(foo bar baz)]);

warning_is {
    my $res = $ux->gsub('', sub {});
    is $res, '';
} undef, 'No warnings';

warning_is {
    my $res = $ux->gsub(undef, sub {});
    is $res, undef;
} undef, 'No warnings';

warning_is {
    my $res = $ux->gsub('foo', sub { return });
    is $res, '';
} undef, 'No warnings';

done_testing;
