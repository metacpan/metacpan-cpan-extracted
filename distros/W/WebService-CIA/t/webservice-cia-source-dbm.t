use strict;
use Test::More tests => 14;

#1
BEGIN { use_ok('WebService::CIA::Source::DBM') }

if (-e './t/test.dbm') {
    unlink './t/test.dbm';
}

#2
my $source = eval {
    WebService::CIA::Source::DBM->new({DBM => './t/test.dbm'});
};
ok( ! $source, q(Shouldn't be able to create DBM in read-only mode) );

#3
$source = WebService::CIA::Source::DBM->new({DBM => './t/test.dbm', Mode => 'readwrite'});
ok( $source, 'new() - returns something' );

#4
ok( $source->isa('WebService::CIA::Source::DBM'), 'new() - returns WebService::CIA::Source::DBM object' );

#5
ok( ref $source->dbm eq 'HASH', 'dbm() - returns hashref' );

#6
ok( eval { $source->set('testcountry', {'Test' => 'Wombat'}); }, 'set() - write to the DBM' );

#7
ok( $source->value('testcountry', 'Test') eq 'Wombat', 'value() - valid args - returns previous set() value' );

#8
ok( ! defined $source->value('zz','Test'), 'value() - invalid args - returns undef' );

#9
ok( scalar keys %{$source->all('testcountry')} == 1 &&
    exists $source->all('testcountry')->{'Test'} &&
    $source->all('testcountry')->{'Test'} eq 'Wombat', 'all() - valid args - returns test string' );

#10
ok( scalar keys %{$source->all('zz')} == 0, 'all() - invalid args - returns empty hashref' );

#11
undef $source;
$source = eval {
    WebService::CIA::Source::DBM->new({DBM => './t/test.dbm', Mode => 'read'});
};
ok( $source, 'new() - open existing DBM readonly' );

#12
ok( $source->isa('WebService::CIA::Source::DBM'), 'new() - open existing DBM - returns WebService::CIA::Source::DBM object' );

#13
ok( $source->value('testcountry', 'Test') eq 'Wombat', 'value() - valid args - returns value set in previous session' );

#14
$source->set('testcountry', {'Test' => 'Platypus'});
ok( $source->value('testcountry','Test') eq 'Wombat', 'DBM opened read only is read only' );

unlink './t/test.dbm';
