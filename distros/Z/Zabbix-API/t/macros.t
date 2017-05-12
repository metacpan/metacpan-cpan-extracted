use Test::More;
use Test::Exception;
use Data::Dumper;

use Zabbix::API;

use lib 't/lib';
use Zabbix::API::TestUtils;

if ($ENV{ZABBIX_SERVER}) {

    plan tests => 21;

} else {

    plan skip_all => 'Needs an URL in $ENV{ZABBIX_SERVER} to run tests.';

}

use_ok('Zabbix::API::Macro');

my $zabber = Zabbix::API::TestUtils::canonical_login;

ok(my $default = $zabber->fetch('Macro', params => { search => { name => 'FOO' } })->[0],
   '... and a macro known to exist can be fetched');

isa_ok($default, 'Zabbix::API::Macro',
       '... and that macro');

ok($default->created,
   '... and it returns true to existence tests');

my $macro = Zabbix::API::Macro->new(root => $zabber,
                                    data => { macro => '{$SUPERMACRO}',
                                              value => 'ITSABIRD' });

isa_ok($macro, 'Zabbix::API::Macro',
       '... and a macro created manually');

use Zabbix::API::Host;
my $existing_host = $zabber->fetch('Host', params => { search => { host => 'Zabbix Server' } })->[0];

$macro->host($existing_host);

ok($macro->host, '... and the macro can set its host');

isa_ok($macro->host, 'Zabbix::API::Host',
       '... and the host');

lives_ok(sub { $macro->push }, '... and pushing a new macro works');

ok($macro->created, '... and the pushed macro returns true to existence tests (id is '.$macro->id.')');

ok($macro->host, '... and the host survived');

isa_ok($macro->host, 'Zabbix::API::Host',
       '... and the host still');

$macro->data->{value} = 'ITSAPLANE';

$macro->push;

is($macro->data->{value}, 'ITSAPLANE',
   '... and pushing a modified macro updates its data on the server');

# testing update by collision
my $same_macro = Zabbix::API::Macro->new(root => $zabber,
                                         data => { macro => '{$SUPERMACRO}',
                                                   value => 'ITSABIRD' });

$same_macro->host($existing_host);

lives_ok(sub { $same_macro->push }, '... and pushing an identical macro works');

ok($same_macro->created, '... and the pushed identical macro returns true to existence tests');

ok($same_macro->host, '... and the host survived');

isa_ok($same_macro->host, 'Zabbix::API::Host',
       '... and the host still');

$macro->pull;

is($macro->data->{value}, 'ITSABIRD',
   '... and the modifications on the identical macro are pushed');

is($same_macro->id, $macro->id, '... and the identical macro has the same id ('.$macro->id.')');

lives_ok(sub { $macro->delete }, '... and deleting a macro works');

ok(!$macro->created,
   '... and deleting a macro removes it from the server');

ok(!$same_macro->created,
   '... and the identical macro is removed as well') or $same_macro->delete;

eval { $zabber->logout };
