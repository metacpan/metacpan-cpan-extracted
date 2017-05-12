use strict;
use warnings;
use Test::More;
use Parse::Crontab;
use Test::Parse::Crontab::Simple;

my $crontab_txt = <<EOF;
*/30 * * * * perl /path/to/cron_lib/some_worker1
#modified_prefix# 2014-12-31 00:00:00

0 23 * * * perl /path/to/cron_lib/some_worker2
#modified_prefix# 2014-12-31 23:00:00

0 15 * * * perl /path/to/cron_lib/some_worker3
#modified_prefix# 2014-12-31 15:00:00
EOF

my $crontab = Parse::Crontab->new( content => $crontab_txt );
Test::Parse::Crontab::Simple::set_prefix('#modified_prefix#');
match_ok $crontab;
done_testing;


