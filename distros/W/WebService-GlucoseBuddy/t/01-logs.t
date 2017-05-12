use strict;
use warnings;

use Test::More 0.98 tests => 12;
use Test::MockObject 1.20110612;
use URI 1.59;
use DateTime 0.70;

BEGIN {
    my $mech = Test::MockObject->new;
    $mech->fake_module('WWW::Mechanize', new => sub { return $mech });
    $mech->mock(uri => sub {
        return URI->new('https://www.glucosebuddy.com/logs/new');
    }),
    $mech->mock(content => sub {
        return <<END_TEXT;
BG,12.0,mmol/L,"",Before Breakfast,11/10/2011 08:30:34,""
BG,4.2,mmol/L,"",Before Dinner,11/10/2011 20:30:37,""
BG,7.8,mmol/L,"",Before Bed,11/11/2011 00:14:23,""
BG,3.6,mmol/L,"",Before Breakfast,11/11/2011 08:31:22,""
BG,7.9,mmol/L,"",After Lunch,11/11/2011 18:21:50,""
BG,5.3,mmol/L,"",Before Dinner,11/13/2011 09:41:23,""
BG,10.6,mmol/L,"",After Breakfast,11/13/2011 11:53:58,""
BG,4.2,mmol/L,"",Before Breakfast,11/16/2011 08:26:51,""
BG,9.7,mmol/L,"",Before Dinner,11/16/2011 21:31:08,""
BG,5.3,mmol/L,"",Before Breakfast,11/17/2011 07:35:25,""
BG,5.6,mmol/L,"",Before Dinner,11/17/2011 21:33:52,""
BG,6.7,mmol/L,"",After Dinner,11/18/2011 00:05:45,""
BG,7.9,mmol/L,"",Before Bed,11/18/2011 00:21:33,""
BG,9.8,mmol/L,"",After Breakfast,11/19/2011 12:05:22,""
BG,4.8,mmol/L,"",Before Breakfast,11/21/2011 08:30:29,""
BG,4.0,mmol/L,"",Before Breakfast,11/22/2011 08:40:31,""
BG,4.1,mmol/L,"",Before Dinner,11/22/2011 20:35:07,""
BG,8.1,mmol/L,"",Before Breakfast,11/23/2011 08:20:00,""
END_TEXT
    });
    $mech->set_true(qw(submit_form get success));
    $mech->set_isa('WWW::Mechanize');

    # load module and set version otherwise our module will complain
    # is there a way of doing this in Test::MockObject?
    use_ok 'WWW::Mechanize';
    $WWW::Mechanize::VERSION = '1.70';

    use_ok 'WebService::GlucoseBuddy';
}

my $gb = new_ok('WebService::GlucoseBuddy' => [
    username    => 'foo',
    password    => 'foo123',
]);

my $from_time = DateTime->new(
    year    => 2011, 
    month   => 11, 
    day     => 13, 
    hour    => 9, 
);

my $logs_set = $gb->logs(
    from    => $from_time,
    to      => $from_time->clone->add(days => 4),
);

my $log = $logs_set->next;
isa_ok($log => 'WebService::GlucoseBuddy::Log');

my $reading = $log->reading;
isa_ok($reading => 'WebService::GlucoseBuddy::Log::Reading');

is($reading->type  => 'BG',     'Reading type');
is($reading->value => 5.3,      'Reading value');
is($reading->unit  => 'mmol/L', 'Reading unit');

is($log->name   => '',                      'Log name');
is($log->event  => 'Before Dinner',         'Log event');
is($log->time   => '2011-11-13T09:41:23',   'Log time');
is($log->notes  => '',                      'Log notes');

done_testing();
