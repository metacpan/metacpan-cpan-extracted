#!/perl -I..

use strict;
use Test::More tests => 23;

BEGIN { use_ok 'Time::Format' }

my $tl_notok;
BEGIN {$tl_notok = eval ('use Time::Local; 1')? 0 : 1}

# Get day/month names in current locale
my ($Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Thursday, $Thu, $June, $Jun) = map langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}
my $june = lc $June;
my $JUNE = uc $June;

SKIP:
{
    skip 'Time::Local not available', 22  if $tl_notok;
    skip 'XS version not available',  22  if !defined $Time::Format_XS::VERSION;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # (3) \Q \E tests
    is $time{q[\QThis is a test string that should not be changed.\E],$t},
                     'This is a test string that should not be changed.',        '\Q...\E';

    is $time{q[\QThis is a test string that should not be changed.],$t},
                     'This is a test string that should not be changed.',        '\Q...';

    is $time{q[This is a test string that should not be changed.],$t},
                   'T13i9 i9 a te9t 9tring that 913oul5 not be c13ange5.',        'unquoted';

    # (8) Static upper/lower tests
    is $time{q[aaabbbccc\Ueeefff\Eggg],$t},   'aaabbbcccEEEFFFggg',            'upper1';
    is $time{q[aaabbbccc\Ueeefffggg],$t},     'aaabbbcccEEEFFFGGG',            'upper2';
    is $time{q[AAABBBCCC\LEEEFFF\EGGG],$t},   'AAABBBCCCeeefffGGG',            'lower1';
    is $time{q[AAABBBCCC\LEEEFFFGGG],$t},     'AAABBBCCCeeefffggg',            'lower2';
    is $time{q[aaabbbccc\ueeefffggg],$t},     'aaabbbcccEeefffggg',            'upperfirst1';
    is $time{q[AAABBBCCC\uEEEFFFGGG],$t},     'AAABBBCCCEEEFFFGGG',            'upperfirst2';
    is $time{q[aaabbbccc\leeefffggg],$t},     'aaabbbccceeefffggg',            'lowerfirst1';
    is $time{q[AAABBBCCC\lEEEFFFGGG],$t},     'AAABBBCCCeEEFFFGGG',            'lowerfirst2';

    # (3) Backslash tests
    is $time{q[a\aab\bbc\cce\eef\ffg\gg],$t},  'aaabbbccceeefffggg',            'extraneous backslashes';
    is $time{q[aaa\Qbbbccc\Ueeefff\Eggg],$t},  'aaabbbccc\Ueeefffggg',          '\Q trumps \U';
    is $time{q[a\aab\bbc\cc\Qe\eef\ffg\gg],$t},'aaabbbccce\eef\ffg\gg',         '\Q trumps \ ';

    # (8) Variable upper/lower tests
    is $time{q[xxx \UMonth\E zzz],$t},         "xxx \U$June\E zzz",            'upper month';
    is $time{q[xxx \LMonth\E zzz],$t},         "xxx \L$June\E zzz",            'lower month';
    is $time{q[xxx \umonth zzz],$t},           "xxx \u$june zzz",              'ucfirst month';
    is $time{q[xxx \lMONTH zzz],$t},           "xxx \l$JUNE zzz",              'lcfirst month';
    is $time{q[xxx \l\UMonth\E zzz],$t},       "xxx \l\U$June\E zzz",          'lcfirst upper month';
    is $time{q[xxx \u\LMonth\E zzz],$t},       "xxx \u\L$June\E zzz",          'ucfirst lower month';
    is $time{q[xxx \U\lMonth\E zzz],$t},       "xxx \U\l$June\E zzz",          'upper lcfirst month';
    is $time{q[xxx \L\uMonth\E zzz],$t},       "xxx \L\u$June\E zzz",          'lower ucfirst month';
}
