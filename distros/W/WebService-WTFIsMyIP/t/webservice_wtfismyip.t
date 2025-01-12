use Test2::V0 -no_srand => 1;
use WebService::WTFIsMyIP;
use Test2::Require::EnvVar 'WEBSERVICE_WTFISMYIP_LIVE_TESTS';
use stable qw( postderef );

is(
    WebService::WTFIsMyIP->new,
    object {
        prop 'blessed' => 'WebService::WTFIsMyIP';
        call ua => object {
            prop 'isa' => 'HTTP::AnyUA';
        };
        call base_url => object {
            prop 'isa' => 'URI';
        };
        call json => hash {
            field 'IPAddress' => D();
            field 'ISP'       => D();
            etc;
        };
    },
);

{
    diag '';
    diag '';
    diag '';

    my %hash = WebService::WTFIsMyIP->new->json->%*;

    foreach my $key (sort keys %hash) {
        diag "$key=$hash{$key}";
    }

    diag '';
    diag '';
}

done_testing;
