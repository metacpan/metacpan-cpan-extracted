use Test::More tests => 16;
use WebService::GData::Base;
use WebService::GData::Constants qw(:all);

my $qpackage = 'WebService::GData::Query';

my $base = new WebService::GData::Base();

ok(
    ref($base) eq 'WebService::GData::Base',
    '$base is a WebService::GData::Base instance.'
);

ok( $base->isa('WebService::GData'), '$base isa WebService::GData.' );

ok( $base->override_method eq 'false',
    'override_method is set to false by default.' );

$base->override_method(1);

ok( $base->override_method eq 'false',
    'override_method does not change if the value is not an authorized one.' );

$base->override_method('true');

ok( $base->override_method eq 'true',
    'override_method does change if an authorized value is set.' );

ok( $base->query->isa($qpackage), 'query return an instance of ' . $qpackage );

my $string = 'should not be set';

ok( $base->query($string)->isa($qpackage),
    qq[query return a $qpackage instance if the parameter is a scalar.] );

ok(
    $base->query( \$string )->isa($qpackage),
    qq[query return an instance of $qpackage if the parameter is not an object.]
);

ok(
    $base->query( {} )->isa($qpackage),
    qq[query return an instance of $qpackage if the parameter is not an object.]
);

ok( !$base->auth, q[auth is not setted by default.] );

$base->auth(1);

ok( !$base->auth, q[auth is not setted by default.] );


ok(
    !$base->get_uri,
    q[no uri by default.]
);

$base->timeout(100);
ok($base->timeout eq 100, 'unknown method calls proxied to lwp::useragent properly.');

eval {
    $base->agent();
};
my $er = $@;
ok(
    $er->code eq 'forbidden_method_call',
    q[setting the agent directly throw an error.]
);

eval {
    $base->post();
};
my $error = $@;
ok(
    $error->code eq 'invalid_uri',
    q[not setting the uri throw an error.]
);
ok(
    $error->content eq 'The uri is empty in post().',
    q[the error contains the proper sub name]
);

