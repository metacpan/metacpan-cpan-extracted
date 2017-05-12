# -*- perl -*-
# test the mechanism for adding recorders

use Test::More tests => 16;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

package TestRecorder;
sub new    { return bless {entered => 0, result => $_[1]}, $_[0] }
sub handle { $_[0]->{entered} = 1; return $_[0]->{result} }
sub renew  { $_[0]->{entered} = 0; $_[0]->{result} = $_[1] }
package main;

my $result = Test::MockCommand::Result->new(command  => 'fake',
    function  => 'open', arguments => []);

my $rec1 = TestRecorder->new($result);
my $rec2 = TestRecorder->new(undef);

Test::MockCommand->add_recorder($rec1);
Test::MockCommand->add_recorder($rec2);
my @recorders = Test::MockCommand->recorders();

is $recorders[0], $rec2, 'check second recorder is at the head of the list';
is $recorders[1], $rec1, 'check first recorder is next in the list';

Test::MockCommand->recording(1);
system('test');
Test::MockCommand->recording(0);

ok $rec2->{entered}, 'check that first-to-run recorder was entered';
ok $rec1->{entered}, 'check that next recorder entered (1st returned undef)';
my @results = Test::MockCommand->all_commands();
ok @results == 1, 'check only one command got recorded';
is $results[0], $result, 'check the command we expected got recorded';

$rec1->renew(undef);
$rec2->renew($result);
Test::MockCommand->clear();
Test::MockCommand->recording(1);
system('test');
Test::MockCommand->recording(0);

ok $rec2->{entered}, 'check that first-to-run recorder was entered';
ok !$rec1->{entered}, "check that next recorder wasn't entered";
@results = Test::MockCommand->all_commands();
ok @results == 1, 'check only one command got recorded';
is $results[0], $result, 'check the command we expected got recorded';

# remove rec2 as a recorder
Test::MockCommand->remove_recorder($rec2);

@recorders = Test::MockCommand->recorders();
is $recorders[0], $rec1, 'check second recorder is removed';

$rec1->renew($result);
$rec2->renew(undef);
Test::MockCommand->clear();
Test::MockCommand->recording(1);
system('test');
Test::MockCommand->recording(0);

ok $rec1->{entered}, 'check first recorder is entered';
ok !$rec2->{entered}, 'check second recorder is not entered';
@results = Test::MockCommand->all_commands();
ok @results == 1, 'check only one command got recorded';
is $results[0], $result, 'check the command we expected got recorded';
