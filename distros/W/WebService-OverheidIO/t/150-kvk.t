use strict;
use warnings;

use Test::Deep;
use Test::More;

use HTTP::Response;
use IO::All;
use Sub::Override;
use WebService::OverheidIO::KvK;

{

    my $model = WebService::OverheidIO::KvK->new(
        key => 'very key'
    );
    isa_ok($model, "WebService::OverheidIO::KvK");

    my $answer = io->catfile('t/data/search_kvk.json')->slurp;
    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
        my $self = shift;
        return HTTP::Response->new(200, undef, undef, $answer);
        },
    );

    $answer = $model->search("foo");

    my $company = $answer->{_embedded}{rechtspersoon}[0];

    my $expected_data = {
        subdossiernummer => "0000",
        handelsnaam      => "Euronet Communications B.V.",
        vestigingsnummer => "15999696",
        dossiernummer    => "33301540",
        _links           => { self => { href => "/api/kvk/33301540/0000" }, },
    };

    cmp_deeply($company, $expected_data, "EuroNet Communications found");

}

done_testing;

__END__

