use Test::More;

use URI::file;
use WWW::Correios::SRO;
pass 'WWW::Correios::SRO sucessfully loaded';

subtest 'Testing sub sro_ok' => sub {
    my $code = 'SS123456785BR';
    ok WWW::Correios::SRO::sro_ok($code), "$code is a valid SRO";

    $code = 'SL473124829BR';
    ok WWW::Correios::SRO::sro_ok($code), "$code is a valid SRO";

    $code = "RE743967753BR";
    ok WWW::Correios::SRO::sro_ok($code), "$code is a valid SRO";

    $code = "RE897448272BR";
    ok WWW::Correios::SRO::sro_ok($code), "$code is a valid SRO";

    $code = "ZZ897448272BR";
    ok WWW::Correios::SRO::sro_ok($code), "$code is a valid SRO";

    #weird, crazy and wrong SRO's. ;-)
    ok ! WWW::Correios::SRO::sro_ok( 0 ), '0 is a bogus SRO';

    $code = "ZZ897448273BR";
    ok ! WWW::Correios::SRO::sro_ok($code), 
      "$code is wrong - has a wrong validation digit";

    $code = "ZZZ897448272BR";
    ok ! WWW::Correios::SRO::sro_ok($code), 
      "$code is wrong - More than 2 chars on the first parameter";

    $code = "Z897448272BR";
    ok ! WWW::Correios::SRO::sro_ok($code), 
      "$code is wrong - Less than 2 chars on the first parameter";

    $code = "ZZ89744827BR";
    ok ! WWW::Correios::SRO::sro_ok($code),
      "$code is wrong - where's validation digit?";

    $code = "ZZ897448272BRasil";
    ok ! WWW::Correios::SRO::sro_ok($code),
      "$code is wrong - country is not 'BR'"; #HUE!
};

subtest 'Testing sub sro_sigla' => sub {
    my $code = 'SS123456785BR';
    is( WWW::Correios::SRO::sro_sigla($code), 'SEDEX',
      "$code -> SS" );

    $code = 'SL473124829BR';
    is( WWW::Correios::SRO::sro_sigla($code), 'SEDEX',
      "$code -> SL" );

    $code = "RE897448272BR";
    is( WWW::Correios::SRO::sro_sigla($code), 'OBJETO REGISTRADO ECONÔMICO',
      "$code -> RE" );

    $code = "ZZ897448272BR";
    is( WWW::Correios::SRO::sro_sigla($code), undef,
      "$code -> Code Not Found" );

    $code = "RE89744827BR";
    is( WWW::Correios::SRO::sro_sigla($code), undef,
      "$code -> wrong, no validation digit" );

    $code = "RE897448273BR";
    is( WWW::Correios::SRO::sro_sigla($code), undef,
      "$code -> wrong validation digit" );

    $code = "RE897448272BRasil";
    is( WWW::Correios::SRO::sro_sigla($code), undef,
      "$code -> wrong, not BR at the end" );

    $code = "ZZ8974482722BR";
    is( WWW::Correios::SRO::sro_sigla($code), undef,
      "$code -> wrong, more than 8 + 1 digits" );
};

subtest 'Testing status_da_entrega()' => sub {
    my $data = {
        tipo   => 'BDI',
        status => '00',
    };
    is WWW::Correios::SRO::status_da_entrega($data), 'entregue'
        => 'entregue';

    $data->{status} = '02';
    is WWW::Correios::SRO::status_da_entrega($data), 'retirar'
        => 'retirar';

    $data->{status} = '09';
    is WWW::Correios::SRO::status_da_entrega($data), 'erro'
        => 'erro';

    $data->{status} = '08';
    is WWW::Correios::SRO::status_da_entrega($data), 'incompleto'
        => 'incompleto';

    $data->{status} = '22';
    is WWW::Correios::SRO::status_da_entrega($data), 'acompanhar'
        => 'acompanhar';
};

done_testing;
