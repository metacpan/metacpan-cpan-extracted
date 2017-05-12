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
    is( WWW::Correios::SRO::sro_sigla($code), 'SEDEX FÍSICO', 
      "$code -> SS" );

    $code = 'SL473124829BR';
    is( WWW::Correios::SRO::sro_sigla($code), 'SEDEX LÓGICO',
      "$code -> SL" );

    $code = "RE897448272BR";
    is( WWW::Correios::SRO::sro_sigla($code), 'REGISTRADO ECONÔMICO',
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

subtest 'SRO 1 -> SS123456785BR' => sub {
    my $uri  = URI::file->new_abs('t/SRO.html');
    my $code = 'SS123456785BR';
    my @tracker = WWW::Correios::SRO::sro($code, $uri);
    my $single  = WWW::Correios::SRO::sro($code, $uri);
    
    is(scalar @tracker, 10, 'found 10 entries');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results');
    
    ### item 0
    is($tracker[0]->data, '24/05/2010 09:50', '[0] correct date');
    is($tracker[0]->date, '24/05/2010 09:50', '[0] correct date (2)');
    is($tracker[0]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[0] correct location');
    is($tracker[0]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[0] correct location (2)');
    is($tracker[0]->status, 'Entregue', '[0] correct status');
    is($tracker[0]->extra, undef, '[0] correct extra');
    
    ### item 1
    is($tracker[1]->data, '24/05/2010 08:42', '[1] correct date');
    is($tracker[1]->date, '24/05/2010 08:42', '[1] correct date (2)');
    is($tracker[1]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[1] correct location');
    is($tracker[1]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[1] correct location (2)');
    is($tracker[1]->status, 'Saiu para entrega', '[1] correct status');
    is($tracker[1]->extra, undef, '[0] correct extra');
    
    ### item 2
    is($tracker[2]->data, '22/05/2010 12:10', '[2] correct date');
    is($tracker[2]->date, '22/05/2010 12:10', '[2] correct date (2)');
    is($tracker[2]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[2] correct location');
    is($tracker[2]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[2] correct location (2)');
    is($tracker[2]->status, 'Destinatário ausente', '[2] correct status');
    is($tracker[2]->extra, 'Será realizada uma nova tentativa de entrega.', '[2] correct extra');
    
    ### item 3
    is($tracker[3]->data, '22/05/2010 11:19', '[3] correct date');
    is($tracker[3]->date, '22/05/2010 11:19', '[3] correct date (2)');
    is($tracker[3]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[3] correct location');
    is($tracker[3]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[3] correct location (2)');
    is($tracker[3]->status, 'Saiu para entrega', '[3] correct status');
    is($tracker[3]->extra, undef, '[3] correct extra');
    
    ### item 4
    is($tracker[4]->data, '22/05/2010 09:22', '[4] correct date');
    is($tracker[4]->date, '22/05/2010 09:22', '[4] correct date (2)');
    is($tracker[4]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[4] correct location');
    is($tracker[4]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[4] correct location (2)');
    is($tracker[4]->status, 'Destinatário ausente', '[4] correct status');
    is($tracker[4]->extra, 'Será realizada uma nova tentativa de entrega.', '[4] correct extra');
    
    ### item 5
    is($tracker[5]->data, '22/05/2010 08:17', '[5] correct date');
    is($tracker[5]->date, '22/05/2010 08:17', '[5] correct date (2)');
    is($tracker[5]->local, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[5] correct location');
    is($tracker[5]->location, 'CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[5] correct location (2)');
    is($tracker[5]->status, 'Saiu para entrega', '[5] correct status');
    is($tracker[5]->extra, undef, '[5] correct extra');
    
    ### item 6
    is($tracker[6]->data, '22/05/2010 05:38', '[6] correct date');
    is($tracker[6]->date, '22/05/2010 05:38', '[6] correct date (2)');
    is($tracker[6]->local, 'CTE BENFICA - RIO DE JANEIRO/RJ', '[6] correct location');
    is($tracker[6]->location, 'CTE BENFICA - RIO DE JANEIRO/RJ', '[6] correct location (2)');
    is($tracker[6]->status, 'Encaminhado', '[6] correct status');
    is($tracker[6]->extra, 'Em trânsito para CEE LARANJEIRAS - RIO DE JANEIRO/RJ', '[6] correct extra');
    
    ### item 7
    is($tracker[7]->data, '21/05/2010 20:23', '[7] correct date');
    is($tracker[7]->date, '21/05/2010 20:23', '[7] correct date (2)');
    is($tracker[7]->local, 'CTCE VITORIA - VITORIA/ES', '[7] correct location');
    is($tracker[7]->location, 'CTCE VITORIA - VITORIA/ES', '[7] correct location (2)');
    is($tracker[7]->status, 'Encaminhado', '[7] correct status');
    is($tracker[7]->extra, 'Em trânsito para CTE BENFICA - RIO DE JANEIRO/RJ', '[7] correct extra');
    
    ### item 8
    is($tracker[8]->data, '21/05/2010 17:43', '[8] correct date');
    is($tracker[8]->date, '21/05/2010 17:43', '[8] correct date (2)');
    is($tracker[8]->local, 'ACF ESPLANADA - VITORIA /ES', '[8] correct location');
    is($tracker[8]->location, 'ACF ESPLANADA - VITORIA /ES', '[8] correct location (2)');
    is($tracker[8]->status, 'Encaminhado', '[8] correct status');
    is($tracker[8]->extra, 'Em trânsito para CTCE VITORIA - VITORIA/ES', '[8] correct extra');
    
    ### item 9
    is($tracker[9]->data, '21/05/2010 16:41', '[9] correct date');
    is($tracker[9]->date, '21/05/2010 16:41', '[9] correct date (2)');
    is($tracker[9]->local, 'ACF ESPLANADA - VITORIA /ES', '[9] correct location');
    is($tracker[9]->location, 'ACF ESPLANADA - VITORIA /ES', '[9] correct location (2)');
    is($tracker[9]->status, 'Postado', '[9] correct status');
    is($tracker[9]->extra, undef, '[9] correct extra');
};

### SECOND SAMPLE (was failing in 0.1)
subtest 'SRO 2 -> SL473124829BR' => sub {
    my $uri = URI::file->new_abs('t/SRO2.html');
    my $other_code = 'SL473124829BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);
    
    is(scalar @tracker, 2, 'found 2 entries in sample #2');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results in sample #2');
    
    ### item 0
    is($tracker[0]->data, '22/08/2011 20:51', '[0] correct date in sample #2');
    is($tracker[0]->date, '22/08/2011 20:51', '[0] correct date (2) in sample #2');
    is($tracker[0]->local, 'CHINA - CHINA', '[0] correct location in sample #2');
    is($tracker[0]->location, 'CHINA - CHINA', '[0] correct location (2) in sample #2');
    is($tracker[0]->status, 'Encaminhado', '[0] correct status in sample #2');
    is(
        $tracker[0]->extra,
        'Em trânsito para UNIDADE DE TRATAMENTO INTERNACIONAL - BRASIL',
        '[0] correct extra in sample #2'
    );
};

### THIRD SAMPLE (new code - DG - still unknown the proper usage for it)
subtest 'SRO 3 -> SL473124829BR' => sub {
    my $uri = URI::file->new_abs('t/SRO3.html');
    my $other_code = 'DG289357397BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);
    
    is(scalar @tracker, 6, 'found 6 entries in sample #3');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results in sample #3');
    
    ### item 0
    is($tracker[0]->data, '06/03/2014 16:53', '[0] correct date');
    is($tracker[0]->date, '06/03/2014 16:53', '[0] correct date (2)');
    is($tracker[0]->local, 'AC EUCLIDES DA CUNHA - EUCLIDES DA CUNHA/BA', '[0] correct location');
    is($tracker[0]->location, 'AC EUCLIDES DA CUNHA - EUCLIDES DA CUNHA/BA', '[0] correct location (2)');
    is($tracker[0]->status, 'Entrega Efetuada', '[0] correct status');
    is($tracker[0]->extra, undef, '[1] correct extra');
    
    ### item 1
    is($tracker[1]->data, '06/03/2014 10:47', '[1] correct date');
    is($tracker[1]->date, '06/03/2014 10:47', '[1] correct date (2)');
    is($tracker[1]->local, 'EUCLIDES DA CUNHA/BA', '[1] correct location');
    is($tracker[1]->location, 'EUCLIDES DA CUNHA/BA', '[1] correct location (2)');
    is($tracker[1]->status, 'Saiu para entrega ao destinatário', '[1] correct status');
    is($tracker[1]->extra, undef, '[1] correct extra');
    
    ### item 2
    is($tracker[2]->data, '05/03/2014 21:38', '[2] correct date');
    is($tracker[2]->date, '05/03/2014 21:38', '[2] correct date (2)');
    is($tracker[2]->local, 'CTE SALVADOR - SALVADOR/BA', '[2] correct location');
    is($tracker[2]->location, 'CTE SALVADOR - SALVADOR/BA', '[2] correct location (2)');
    is($tracker[2]->status, 'Encaminhado', '[2] correct status');
    is($tracker[2]->extra, 'Em trânsito para AC EUCLIDES DA CUNHA - EUCLIDES DA CUNHA/BA', '[2] correct extra');
    
    ### item 3
    is($tracker[3]->data, '28/02/2014 21:39', '[3] correct date');
    is($tracker[3]->date, '28/02/2014 21:39', '[3] correct date (2)');
    is($tracker[3]->local, 'CTE BELO HORIZONTE - BELO HORIZONTE/MG', '[3] correct location');
    is($tracker[3]->location, 'CTE BELO HORIZONTE - BELO HORIZONTE/MG', '[3] correct location (2)');
    is($tracker[3]->status, 'Encaminhado', '[3] correct status');
    is($tracker[3]->extra, 'Encaminhado para CTE SALVADOR - SALVADOR/BA', '[3] correct extra');
    
    ### item 4
    is($tracker[4]->data, '28/02/2014 17:31', '[4] correct date');
    is($tracker[4]->date, '28/02/2014 17:31', '[4] correct date (2)');
    is($tracker[4]->local, 'AC JUSTINOPOLIS - RIBEIRAO DAS NEVES/MG', '[4] correct location');
    is($tracker[4]->location, 'AC JUSTINOPOLIS - RIBEIRAO DAS NEVES/MG', '[4] correct location (2)');
    is($tracker[4]->status, 'Encaminhado', '[4] correct status');
    is($tracker[4]->extra, 'Em trânsito para CTC BELO HORIZONTE - BELO HORIZONTE/MG', '[4] correct extra');
    
    ### item 5
    is($tracker[5]->data, '28/02/2014 17:09', '[5] correct date');
    is($tracker[5]->date, '28/02/2014 17:09', '[5] correct date (2)');
    is($tracker[5]->local, 'AC JUSTINOPOLIS - RIBEIRAO DAS NEVES/MG', '[5] correct location');
    is($tracker[5]->location, 'AC JUSTINOPOLIS - RIBEIRAO DAS NEVES/MG', '[5] correct location (2)');
    is($tracker[5]->status, 'Postado depois do horário limite da agência', '[5] correct status');
    is($tracker[5]->extra, 'Objeto sujeito a encaminhamento no próximo dia útil', '[5] correct extra');
};

### FOURTH SAMPLE (new code - JH - still unknown the proper usage for it)
subtest 'SRO 4 - JH748867227BR' => sub { 
    my $uri = URI::file->new_abs('t/SRO4.html');
    my $other_code = 'JH748867227BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);
    
    is(scalar @tracker, 3, 'found 3 entries in sample #4');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results in sample #4');
    
    ### item 0
    is($tracker[0]->data, '04/04/2014 16:29', '[0] correct date');
    is($tracker[0]->date, '04/04/2014 16:29', '[0] correct date (2)');
    is($tracker[0]->local, 'CDD HUMAITA - RIO DE JANEIRO/RJ', '[0] correct location');
    is($tracker[0]->location, 'CDD HUMAITA - RIO DE JANEIRO/RJ', '[0] correct location (2)');
    is($tracker[0]->status, 'Entrega Efetuada', '[0] correct status');
    is($tracker[0]->extra, undef, '[1] correct extra');
    
    ### item 1
    is($tracker[1]->data, '04/04/2014 11:55', '[1] correct date');
    is($tracker[1]->date, '04/04/2014 11:55', '[1] correct date (2)');
    is($tracker[1]->local, 'RIO DE JANEIRO/RJ', '[1] correct location');
    is($tracker[1]->location, 'RIO DE JANEIRO/RJ', '[1] correct location (2)');
    is($tracker[1]->status, 'Saiu para entrega ao destinatário', '[1] correct status');
    is($tracker[1]->extra, undef, '[1] correct extra');
    
    ### item 2
    is($tracker[2]->data, '31/03/2014 18:03', '[2] correct date');
    is($tracker[2]->date, '31/03/2014 18:03', '[2] correct date (2)');
    is($tracker[2]->local, 'AGF PRAIA DA ENSEADA - GUARUJA/SP', '[2] correct location');
    is($tracker[2]->location, 'AGF PRAIA DA ENSEADA - GUARUJA/SP', '[2] correct location (2)');
    is($tracker[2]->status, 'Postado depois do horário limite da agência', '[2] correct status');
    is($tracker[2]->extra, 'Objeto sujeito a encaminhamento no próximo dia útil', '[2] correct extra');
};

#### FIFTH SAMPLE (new code - DM - still unknown the proper usage for it)
subtest 'SRO 5 - DM010256601BR' => sub {
    my $uri = URI::file->new_abs('t/SRO5.html');
    my $other_code = 'DM010256601BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);
    
    is(scalar @tracker, 6, 'found 6 entries in sample #5');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results in sample #5');
    
    ### item 0
    is($tracker[0]->data, '23/06/2014 08:28', '[0] correct date');
    is($tracker[0]->date, '23/06/2014 08:28', '[0] correct date (2)');
    is($tracker[0]->local, 'FRANCA / SP', '[0] correct location');
    is($tracker[0]->location, 'FRANCA / SP', '[0] correct location (2)');
    is($tracker[0]->status, 'Objeto saiu para entrega ao destinatário', '[0] correct status');
    is($tracker[0]->extra, undef, '[1] correct extra');
    
    ### item 1
    is($tracker[1]->data, '23/06/2014 08:11', '[1] correct date');
    is($tracker[1]->date, '23/06/2014 08:11', '[1] correct date (2)');
    is($tracker[1]->local, 'FRANCA / SP', '[1] correct location');
    is($tracker[1]->location, 'FRANCA / SP', '[1] correct location (2)');
    is($tracker[1]->status, 'Objeto encaminhado de Unidade de Distribuição em FRANCA / SP para Unidade de Distribuição em FRANCA / SP', '[1] correct status');
    is($tracker[1]->extra, undef, '[1] correct extra');
    
    ### item 2
    is($tracker[2]->data, '23/06/2014 04:31', '[2] correct date');
    is($tracker[2]->date, '23/06/2014 04:31', '[2] correct date (2)');
    is($tracker[2]->local, 'RIBEIRAO PRETO / SP', '[2] correct location');
    is($tracker[2]->location, 'RIBEIRAO PRETO / SP', '[2] correct location (2)');
    is($tracker[2]->status, 'Objeto encaminhado de Unidade de Tratamento em RIBEIRAO PRETO / SP para Unidade de Distribuição em FRANCA / SP', '[2] correct status');
    is($tracker[2]->extra, undef, '[2] correct extra');
    
    ### item 3
    is($tracker[3]->data, '20/06/2014 21:35', '[3] correct date');
    is($tracker[3]->date, '20/06/2014 21:35', '[3] correct date (3)');
    is($tracker[3]->local, 'BELO HORIZONTE / MG', '[3] correct location');
    is($tracker[3]->location, 'BELO HORIZONTE / MG', '[3] correct location (3)');
    is($tracker[3]->status, 'Objeto encaminhado de Unidade Operacional em BELO HORIZONTE / MG para Unidade de Distribuição em RIBEIRAO PRETO / SP', '[2] correct status');
    is($tracker[3]->extra, undef, '[3] correct extra');
    
    ### item 4
    is($tracker[4]->data, '20/06/2014 17:14', '[4] correct date');
    is($tracker[4]->date, '20/06/2014 17:14', '[4] correct date (2)');
    is($tracker[4]->local, 'RIBEIRAO DAS NEVES / MG', '[4] correct location');
    is($tracker[4]->location, 'RIBEIRAO DAS NEVES / MG', '[4] correct location (4)');
    is($tracker[4]->status, 'Objeto encaminhado de Agência dos Correios em RIBEIRAO DAS NEVES / MG para Unidade Operacional em BELO HORIZONTE / MG', '[4] correct status');
    is($tracker[4]->extra, undef, '[4] correct extra');
    
    ### item 5
    is($tracker[5]->data, '20/06/2014 16:46', '[5] correct date');
    is($tracker[5]->date, '20/06/2014 16:46', '[5] correct date (5)');
    is($tracker[5]->local, 'RIBEIRAO DAS NEVES / MG', '[5] correct location');
    is($tracker[5]->location, 'RIBEIRAO DAS NEVES / MG', '[5] correct location (5)');
    is($tracker[5]->status, 'Objeto postado', '[5] correct status');
    is($tracker[5]->extra, undef, '[5] correct extra');
};

#### SIXTH SAMPLE (new code - PE - still unknown the proper usage for it)
subtest 'SRO 6 - PE096907205BR' => sub {
    my $uri = URI::file->new_abs('t/SRO6.html');
    my $other_code = 'PE096907205BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);
    
    is(scalar @tracker, 6, 'found 6 entries in sample #6');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }
    
    is_deeply($single, $tracker[0], 'checking single-wantarray results in sample #6');
    
    ### item 0
    is($tracker[0]->data, '01/08/2014 13:43', '[0] correct date');
    is($tracker[0]->date, '01/08/2014 13:43', '[0] correct date (2)');
    is($tracker[0]->local, 'CEE BRASILIA NORTE - BRASILIA/DF', '[0] correct location');
    is($tracker[0]->location, 'CEE BRASILIA NORTE - BRASILIA/DF', '[0] correct location (2)');
    is($tracker[0]->status, 'Entrega Efetuada', '[0] correct status');
    is($tracker[0]->extra, undef, '[1] correct extra');
    
    ### item 1
    is($tracker[1]->data, '01/08/2014 10:26', '[1] correct date');
    is($tracker[1]->date, '01/08/2014 10:26', '[1] correct date (2)');
    is($tracker[1]->local, 'BRASILIA/DF', '[1] correct location');
    is($tracker[1]->location, 'BRASILIA/DF', '[1] correct location (2)');
    is($tracker[1]->status, 'Saiu para entrega ao destinatário', '[1] correct status');
    is($tracker[1]->extra, undef, '[1] correct extra');
    
    ### item 2
    is($tracker[2]->data, '31/07/2014 13:45', '[2] correct date');
    is($tracker[2]->date, '31/07/2014 13:45', '[2] correct date (2)');
    is($tracker[2]->local, 'CTE BRASILIA - BRASILIA/DF', '[2] correct location');
    is($tracker[2]->location, 'CTE BRASILIA - BRASILIA/DF', '[2] correct location (2)');
    is($tracker[2]->status, 'Encaminhado', '[2] correct status');
    is($tracker[2]->extra, 'Em trânsito para CEE BRASILIA NORTE - BRASILIA/DF', '[2] correct extra');
    
    ### item 3
    is($tracker[3]->data, '29/07/2014 16:51', '[3] correct date');
    is($tracker[3]->date, '29/07/2014 16:51', '[3] correct date (2)');
    is($tracker[3]->local, 'CTE BENFICA - RIO DE JANEIRO/RJ', '[3] correct location');
    is($tracker[3]->location, 'CTE BENFICA - RIO DE JANEIRO/RJ', '[3] correct location (2)');
    is($tracker[3]->status, 'Encaminhado', '[3] correct status');
    is($tracker[3]->extra, 'Encaminhado para CTE BRASILIA - BRASILIA/DF', '[3] correct extra');
    
    ### item 4
    is($tracker[4]->data, '28/07/2014 14:41', '[4] correct date');
    is($tracker[4]->date, '28/07/2014 14:41', '[4] correct date (2)');
    is($tracker[4]->local, 'AC ITAIPAVA - PETROPOLIS /RJ', '[4] correct location');
    is($tracker[4]->location, 'AC ITAIPAVA - PETROPOLIS /RJ', '[4] correct location (2)');
    is($tracker[4]->status, 'Encaminhado', '[4] correct status');
    is($tracker[4]->extra, 'Em trânsito para CTE BENFICA - RIO DE JANEIRO/RJ', '[4] correct extra');
    
    ### item 5
    is($tracker[5]->data, '28/07/2014 10:02', '[5] correct date');
    is($tracker[5]->date, '28/07/2014 10:02', '[5] correct date (2)');
    is($tracker[5]->local, 'AC ITAIPAVA - PETROPOLIS /RJ', '[5] correct location');
    is($tracker[5]->location, 'AC ITAIPAVA - PETROPOLIS /RJ', '[5] correct location (2)');
    is($tracker[5]->status, 'Postado', '[5] correct status');
    is($tracker[5]->extra, undef, '[5] correct extra');
};

### SEVENTH SAMPLE (valid code, but without info inside it)
subtest 'SRO 7 -> ZZ897448272BR' => sub {
    my $uri = URI::file->new_abs('t/SRO7.html');
    my $other_code = 'ZZ897448272BR'; # exemplo dos correios
    my @tracker = WWW::Correios::SRO::sro($other_code, $uri);
    my $single  = WWW::Correios::SRO::sro($other_code, $uri);

    is( scalar @tracker, 0, 'found 0 entries in sample #7' );
    is( $single, undef, 'Sample #7 is undef' );
};


subtest 'Unknown sro prefix with verifica_prefixo enabled' => sub {
    my $uri  = URI::file->new_abs('t/SRO3.html');
    my $code = 'DG289357397BR'; 
    my @tracker = WWW::Correios::SRO::sro($code, $uri, 1);
    my $single  = WWW::Correios::SRO::sro($code, $uri, 1);

    is ( scalar @tracker, 0, "Invalid code, didn't search details" );
    is ( $single, undef, "Invalid code, didn't search details" );
};

subtest 'Known sro prefix with verifica_prefixo enabled' => sub {
    # same test as first SRO. It must have 10 entries too.
    my $uri  = URI::file->new_abs('t/SRO.html');
    my $code = 'SS123456785BR';
    my @tracker = WWW::Correios::SRO::sro($code, $uri, 1);
    my $single  = WWW::Correios::SRO::sro($code, $uri, 1);

    is(scalar @tracker, 10, 'found 10 entries');
    foreach (@tracker) {
        isa_ok($_, 'WWW::Correios::SRO::Item');
        can_ok($_, qw(data date location local status extra));
    }

    is_deeply($single, $tracker[0], 'checking single-wantarray results');
};

done_testing;
