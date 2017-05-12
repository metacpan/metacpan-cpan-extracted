#!/perl -I..

use strict;
use Test::More tests => 61;
use lib 'blib/lib', 'blib/arch';

# time-as-string tests

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(time_format %time) }

# Get day/month names in current locale
my ($Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Thursday, $Thu, $June, $Jun) = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}

# June 5, 2003 at 1:58:09 pm
my $d  = '2003-06-05';
my $t  =   '13:58:09';
my $d_t = "$d $t";
my $dTt = "${d}T$t";
my $dt  = "$d$t";
my $dtx;
($dtx = $dt) =~ tr/-://d;   # no separators at all

# Date/time strings with Z (UTC indicator) appended. Per CPAN RT bug 55630.
my ($tz, $d_tz, $dTtz, $dtz, $dtxz);
($tz, $d_tz, $dTtz, $dtz, $dtxz) = map {$_ . 'Z'} ($t, $d_t, $dTt, $dt, $dtx);
my $out;
my $err;

# time_format tests (22 * 2)
is time_format('yyyymmdd', $d),     '20030605'    => 'ymd f() d only';
is time_format('yyyymmdd', $t),     '19691231'    => 'ymd f() t only';
is time_format('yyyymmdd', $d_t),   '20030605'    => 'ymd f() d&t';
is time_format('yyyymmdd', $dTt),   '20030605'    => 'ymd f() d T t';
is time_format('yyyymmdd', $dt),    '20030605'    => 'ymd f() dt';
is time_format('yyyymmdd', $dtx),   '20030605'    => 'ymd f() dt-nosep';
is time_format('yyyymmdd', $tz),    '19691231'    => 'ymd f() t only (z)';
is time_format('yyyymmdd', $d_tz),  '20030605'    => 'ymd f() d&t (z)';
is time_format('yyyymmdd', $dTtz),  '20030605'    => 'ymd f() d T t (z)';
is time_format('yyyymmdd', $dtz),   '20030605'    => 'ymd f() dt (z)';
is time_format('yyyymmdd', $dtxz),  '20030605'    => 'ymd f() dt-nosep (z)';

is time_format('hhmmss',   $d),     '000000'      => 'hms f() d only';
is time_format('hhmmss',   $t),     '135809'      => 'hms f() t only';
is time_format('hhmmss',   $d_t),   '135809'      => 'hms f() d&t';
is time_format('hhmmss',   $dTt),   '135809'      => 'hms f() d T t';
is time_format('hhmmss',   $dt),    '135809'      => 'hms f() dt';
is time_format('hhmmss',   $dtx),   '135809'      => 'hms f() dt-nosep';
is time_format('hhmmss',   $tz),    '135809'      => 'hms f() t only (zz)';
is time_format('hhmmss',   $d_tz),  '135809'      => 'hms f() d&t (zz)';
is time_format('hhmmss',   $dTtz),  '135809'      => 'hms f() d T t (zz)';
is time_format('hhmmss',   $dtz),   '135809'      => 'hms f() dt (zz)';
is time_format('hhmmss',   $dtxz),  '135809'      => 'hms f() dt-nosep (zz)';

is $time{'yyyymmdd', $d},           '20030605'    => 'ymd %{} d only';
is $time{'yyyymmdd', $t},           '19691231'    => 'ymd %{} t only';
is $time{'yyyymmdd', $d_t},         '20030605'    => 'ymd %{} d&t';
is $time{'yyyymmdd', $dTt},         '20030605'    => 'ymd %{} d T t';
is $time{'yyyymmdd', $dt},          '20030605'    => 'ymd %{} dt';
is $time{'yyyymmdd', $dtx},         '20030605'    => 'ymd %{} dt-nosep';
is $time{'yyyymmdd', $tz},          '19691231'    => 'ymd %{} t only (z)';
is $time{'yyyymmdd', $d_tz},        '20030605'    => 'ymd %{} d&t (z)';
is $time{'yyyymmdd', $dTtz},        '20030605'    => 'ymd %{} d T t (z)';
is $time{'yyyymmdd', $dtz},         '20030605'    => 'ymd %{} dt (z)';
is $time{'yyyymmdd', $dtxz},        '20030605'    => 'ymd %{} dt-nosep (z)';

is $time{'hhmmss',   $d},           '000000'      => 'hms %{} d only';
is $time{'hhmmss',   $t},           '135809'      => 'hms %{} t only';
is $time{'hhmmss',   $d_t},         '135809'      => 'hms %{} d&t';
is $time{'hhmmss',   $dTt},         '135809'      => 'hms %{} d T t';
is $time{'hhmmss',   $dt},          '135809'      => 'hms %{} dt';
is $time{'hhmmss',   $dtx},         '135809'      => 'hms %{} dt-nosep';
is $time{'hhmmss',   $tz},          '135809'      => 'hms %{} t only (z)';
is $time{'hhmmss',   $d_tz},        '135809'      => 'hms %{} d&t (z)';
is $time{'hhmmss',   $dTtz},        '135809'      => 'hms %{} d T t (z)';
is $time{'hhmmss',   $dtz},         '135809'      => 'hms %{} dt (z)';
is $time{'hhmmss',   $dtxz},        '135809'      => 'hms %{} dt-nosep (z)';

# Whatever the local time zone, 'Z' times should be reported as UTC.  (5 * 2)
is time_format('tz', $tz),    'UTC'      => 'tzone f() t only (z)';
is time_format('tz', $d_tz),  'UTC'      => 'tzone f() d&t (z)';
is time_format('tz', $dTtz),  'UTC'      => 'tzone f() d T t (z)';
is time_format('tz', $dtz),   'UTC'      => 'tzone f() dt (z)';
is time_format('tz', $dtxz),  'UTC'      => 'tzone f() dt-nosep (z)';

is $time{'tz', $tz},          'UTC'      => 'tzone %{} t only (z)';
is $time{'tz', $d_tz},        'UTC'      => 'tzone %{} d&t (z)';
is $time{'tz', $dTtz},        'UTC'      => 'tzone %{} d T t (z)';
is $time{'tz', $dtz},         'UTC'      => 'tzone %{} dt (z)';
is $time{'tz', $dtxz},        'UTC'      => 'tzone %{} dt-nosep (z)';


# Reported bug case:
eval { $out = time_format('yyyy.mm.dd', '2007.12.31'); };
is $@, '', 'December bug I: no error';
is $out, '2007.12.31' => 'December bug I';

eval { $out = time_format('yyyy.mm.dd', '2000.01.01'); };
is $@, '', 'December bug II: no error';
is $out, '2000.01.01' => 'December bug II';

eval { $out = time_format('yyyy.mm.dd', '1968.01.01'); };
is $@, '', 'December bug III: no error';
is $out, '1968.01.01' => 'December bug III';
