use strict;
use warnings;

use Test::More;
use Test::Exception;

use YAML::XS;
use DateTime;

BEGIN { use_ok('WebService::SlimTimer::Task'); }

my $task_desc = <<'EOF'
coworkers: []

name: Foo
created_at: 2011-06-28 10:25:25.139663 Z
completed_on:
owners:
- name: Tester
  user_id: 777
  email: me@testers.org
updated_at: 2011-06-28 10:25:25.139663 Z
role: owner
tags: ""
id: 999
reporters: []

hours: 123.45
EOF
;

my $t = WebService::SlimTimer::Task->new(Load($task_desc));
isa_ok $t, 'WebService::SlimTimer::Task';

is $t->id, 999, 'Id is ok.';
is $t->name, 'Foo', 'Name is ok.';
is $t->hours, 123.45, 'Hours are ok.';

my $created_at = DateTime->new(
                    year => 2011,
                    month => 6,
                    day => 28,
                    hour => 10,
                    minute => 25,
                    second => 25,
                    nanosecond => 139663000,
                );
is $t->created_at, $created_at, 'Creation date is ok.';

is $t->completed_on, undef, q{Isn't completed yet.};

$task_desc =~ s/^completed_on:/completed_on: 2028-01-01 00:00:00.000000 Z/m;
my $t2 = WebService::SlimTimer::Task->new(Load($task_desc));
is $t2->completed_on, DateTime->new(year => 2028), 'Now completed as expected.';

# Test that constraints on optional timestamps work too.
$task_desc =~ s/2028-01-01 //;
throws_ok { WebService::SlimTimer::Task->new(Load($task_desc)) }
    qr/Incorrectly formatted datetime/,
    'Using invalid timestamp failed.';

done_testing();
