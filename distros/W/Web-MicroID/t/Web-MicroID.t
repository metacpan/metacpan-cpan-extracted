use Test::More tests => 29;
BEGIN { use_ok('Web::MicroID') };
my $id = Web::MicroID->new;

is ($id->individual,    undef, 'individual method undef');
is ($id->indv_uri,      undef, 'indv_uri method undef');
is ($id->indv_val,      undef, 'indv_val method undef');
is ($id->serv_prov,     undef, 'serv_prov method undef');
is ($id->serv_prov_uri, undef, 'serv_prov_uri method undef');
is ($id->serv_prov_val, undef, 'serv_prov_val method undef');
is ($id->legacy,        undef, 'legacy method undef');

my $indv = 'mailto:user@domain.tld';
is ($id->individual($indv), $indv,             'individual method w/data');
is ($id->individual,        $indv,             'individual method');
is ($id->indv_uri,          'mailto',          'indv_uri method');
is ($id->indv_val,          'user@domain.tld', 'indv_val method');

my $serv_prov = 'http://domain.tld/';
is ($id->serv_prov($serv_prov), $serv_prov,   'serv_prov method (w/data)');
is ($id->serv_prov,             $serv_prov,   'serv_prov method');
is ($id->serv_prov_uri,         'http',       'serv_prov_uri method');
is ($id->serv_prov_val,         'domain.tld', 'serv_prov_val method');

is ($id->algorithm,         'sha1', 'Default algorithm method');
is ($id->algorithm('md5'),  'md5',  'Change algorithm');
is ($id->algorithm('sha1'), 'sha1', 'Change algorithm back');

my $micro_id = 'mailto+http:sha1:7964877442b3dd0b5b7487eabe264aa7d31f463c';
my $legacy   = '7964877442b3dd0b5b7487eabe264aa7d31f463c';
is ($id->generate,           $micro_id, 'generate method');
is ($id->legacy,             $legacy,   'legacy method');
is ($id->process($micro_id), 1,         'process method');
is ($id->process($legacy),   1,         'process legacy');
is ($id->process('xxx'),     undef,     'If process fails');

my $id2 = Web::MicroID->new(
    {individual => $indv, serv_prov  => $serv_prov}
);
is ($id2->process($legacy),   1,         'process legacy from new()');
is ($id2->generate,           $micro_id, 'generate method from new()');

my $micro_id_md5 = 'mailto+http:md5:d80be00ae63117fbcea24230d2cc0140';
my $legacy_md5   = 'd80be00ae63117fbcea24230d2cc0140';
my $id3 = Web::MicroID->new(
    {algorithm => 'md5', individual => $indv, serv_prov  => $serv_prov}
);
is ($id3->generate,             $micro_id_md5, 'generate from new() md5');
is ($id3->process($legacy_md5), 1,             'process from new() md5');

my $id4 = Web::MicroID->new(
    {individual => $indv, serv_prov  => $serv_prov, process => $legacy}
);
is ($id4->process,  1,         'process from new() process');

