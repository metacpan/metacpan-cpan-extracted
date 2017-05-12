use strict;
use warnings;
use Test::More 0.96;

require Timer::Simple;

# default_format_spec
my %specs = map { $_ => qr/%[0-9.]*$_/ } qw(d f);
like(Timer::Simple::default_format_spec( ), $specs{ eval { require Time::HiRes } ? 'f' : 'd'} , 'default_format_spec()');
like(Timer::Simple::default_format_spec(0), $specs{d}, 'default_format_spec(0)');
like(Timer::Simple::default_format_spec(1), $specs{f}, 'default_format_spec(1)');

# format_hms
is('01:02:03',        Timer::Simple::format_hms(1, 2, 3),        'format_hms(h,m,s)');
is('01:02:03',        Timer::Simple::format_hms(   3723),        'format_hms(s)');
is('01:02:03.123456', Timer::Simple::format_hms(1, 2, 3.123456), 'format_hms(h,m,s)');
is('01:02:03.123456', Timer::Simple::format_hms(   3723.123456), 'format_hms(s)');

# separate_hms
is_deeply([Timer::Simple::separate_hms(3723)  ], [1, 2,    3], 'separate_hms(s)');
is_deeply([Timer::Simple::separate_hms(7455.5)], [2, 4, 15.5], 'separate_hms(s)');

done_testing;
