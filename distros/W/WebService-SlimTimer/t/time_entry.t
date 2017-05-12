use strict;
use warnings;

use Test::More;
use Test::Exception;

use YAML::XS;
use DateTime;

BEGIN { use_ok('WebService::SlimTimer::TimeEntry'); }

my $entry_desc = <<'EOF'
end_time: 2011-06-27 02:23:17 Z
created_at: 2011-06-26 23:11:07.235323 Z
comments: ""
updated_at: 2011-06-27 00:24:11.958693 Z
tags: ""
id: 66666
duration_in_seconds: 4685
task:
  coworkers: []

  name: Foo
  created_at: 2007-10-06 22:39:50.967670 Z
  completed_on:
  owners:
  - name: Tester
    user_id: 777
    email: me@testers.org
  updated_at: 2010-08-10 14:34:24.739162 Z
  role: owner
  tags: ""
  id: 999
  reporters: []

  hours: 352.69
in_progress: true
start_time: 2011-06-27 01:05:12 Z
EOF
;

my $te = WebService::SlimTimer::TimeEntry->new(Load($entry_desc));
isa_ok $te, 'WebService::SlimTimer::TimeEntry';

is $te->id, 66666, 'Id is ok.';
is $te->task_id, 999, 'Task id is ok.';
is $te->task_name, 'Foo', 'Task name is ok.';
is $te->duration, 4685, 'Duration is ok.';

my $created_at = DateTime->new(
                    year => 2011,
                    month => 6,
                    day => 26,
                    hour => 23,
                    minute => 11,
                    second => 07,
                    nanosecond => 235323000,
                );
is $te->created_at, $created_at, 'Creation date is ok.';

is $te->in_progress, 1, 'Is in progress.';

TODO: {
local $TODO = 'Updating entries not implemented yet.';

$entry_desc =~ s/^in_progress: true/in_progress: false/;
my $te2 = WebService::SlimTimer::TimeEntry->new(Load($entry_desc));
is $te2->in_progress, 0, 'Now completed as expected.';
}

$entry_desc =~ s/^duration_in_seconds: \d+$//m;
throws_ok { WebService::SlimTimer::TimeEntry->new(Load($entry_desc)) }
    qr/Validation failed/,
    'Using invalid entry description failed.';

done_testing();
