use strict;
use warnings;
use Test::More;
use Parse::Crontab;
use Test::Parse::Crontab::Simple;

my $crontab_txt = <<EOF;
*/30 * * * * perl /path/to/cron_lib/some_worker1
###sample 2014-12-31 00:00:00

0 23 * * * perl /path/to/cron_lib/some_worker2
###sample 2014-12-31 23:00:00

0 15 * * * perl /path/to/cron_lib/some_worker3
EOF

my $crontab = Parse::Crontab->new( content => $crontab_txt );
match_ok $crontab;
done_testing;


