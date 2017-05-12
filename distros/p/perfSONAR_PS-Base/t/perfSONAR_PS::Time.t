use Test::More 'no_plan';
use Data::Compare qw( Compare );

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::Time');
use perfSONAR_PS::Time;

my $time1 = perfSONAR_PS::Time->new("point", 1010);
ok (defined $time1);
is ($time1->getType, "point");
is ($time1->getTime, 1010);
is ($time1->getStartTime, 1010);
is ($time1->getEndTime, 1010);
ok (!defined $time1->getDuration);

my $time2 = perfSONAR_PS::Time->new("range", 1000, 1010);
ok (defined $time2);
is ($time2->getType, "range");
ok (!defined $time2->getTime);
is ($time2->getStartTime, 1000);
is ($time2->getEndTime, 1010);
is ($time2->getDuration, 10);


my $time3 = perfSONAR_PS::Time->new("duration", 1000, 10);
ok (defined $time3);
is ($time3->getType, "duration");
ok (!defined $time3->getTime);
is ($time3->getStartTime, 1000);
is ($time3->getEndTime, 1010);
is ($time3->getDuration, 10);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

