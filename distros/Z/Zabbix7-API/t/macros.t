use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix7::API;

use lib 't/lib';
use Zabbix7::API::TestUtils;
use Zabbix7::API::Macro;

unless ($ENV{ZABBIX_SERVER}) {
    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';
}

my $zabber = Zabbix7::API::TestUtils::canonical_login;

my $macro = Zabbix7::API::Macro->new(root => $zabber,
                                     data => { macro => '{$SUPERMACRO}',
                                               value => 'ITSABIRD' });

isa_ok($macro, 'Zabbix7::API::Macro',
       '... and a macro created manually');

ok($macro->globalp, q{... and since it has no hostid, it's global});

lives_ok(sub { $macro->create }, '... and pushing a new macro works');

ok($macro->exists, '... and the pushed macro returns true to existence tests (id is '.$macro->id.')');

$macro->value('ITSAPLANE');

$macro->update;
$macro->pull;

is($macro->value, 'ITSAPLANE',
   '... and pushing a modified macro updates its data on the server');

lives_ok(sub { $macro->delete }, '... and deleting a macro works');

ok(!$macro->exists,
   '... and deleting a macro removes it from the server');

my $host = $zabber->fetch_single('Host', params => { host => 'Zabbix Server',
                                                     search => { host => 'Zabbix Server' } });

# force presence of the "hosts" field -- some users have reported that
# their Zabbix server returned macro objects with this field set,
# which caused errors when updating the object
my $hostmacro = Zabbix7::API::Macro->new(root => $zabber,
                                         data => {
                                             # the Emperor's own!
                                             macro => '{$ULTRAMACRO}',
                                             value => 'ITSSUPERMAN',
                                             hostid => $host->id,
                                             hosts => [{hostid => 123}],
                                         });

ok(!$hostmacro->globalp, q{... and since it has a hostid, it's a host macro});

lives_ok(sub { $hostmacro->create }, '... and pushing a new host macro works');

ok($hostmacro->exists, '... and the pushed host macro returns true to existence tests (id is '.$hostmacro->id.')');

$hostmacro->value('UP UP AND AWAY');

$hostmacro->update;
$hostmacro->pull;

is($hostmacro->value, 'UP UP AND AWAY',
   '... and pushing a modified host macro updates its data on the server');

lives_ok(sub { $hostmacro->delete }, '... and deleting a host macro works');

eval { $zabber->logout };

done_testing;
