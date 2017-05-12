use strict;

BEGIN {
    # Windows can't change timezone inside Perl script
    if (($ENV{TZ}||'') ne 'GMT') {
        $ENV{TZ} = 'GMT';
        exec $^X, (map { "-I\"$_\"" } @INC), $0;
    };
}

use Test::More;
use Time::TZOffset;

my @summer = localtime();
@summer[3,4] = (1,7); 
is(Time::TZOffset::tzoffset(@summer), '+0000');
is(Time::TZOffset::tzoffset_as_seconds(@summer), 0);
my @winter = localtime();
@winter[3,4] = (1,1); 
is(Time::TZOffset::tzoffset(@winter), '+0000');
is(Time::TZOffset::tzoffset_as_seconds(@summer), 0);

done_testing;

