use Test2::V0;

use Test2::Require::Module 'Mojo::DOM';
use Test2::Require::Module 'LWP::UserAgent';

use WebService::OurWorldInData::Catalog;

my $ua    = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.1');

my $catalog = WebService::OurWorldInData::Catalog->new( ua => $ua );

is $catalog, object {
        prop isa => 'WebService::OurWorldInData::Catalog';

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'LWP::UserAgent';

        end();
    }, 'Base class object correct';

subtest 'find all charts (partial list)' => sub {
    ok my $charts = $catalog->find( '' ), 'Can find charts';
    is scalar @$charts, 1822, 'Found number of charts correct as of v0.03';
    is $charts, array { all_items match qr/\w/; etc; }, 'No blank lines';
};

subtest 'find search term' => sub {
    ok my $results = $catalog->find( 'covid' ), 'Can use the fake OWID search';

    is scalar @$results, 25, 'Found covid results';
    is $results, array {
            all_items match qr/covid/;
            etc();
        }, 'Results match search criteria';
};

subtest 'get_topics (partial list)' => sub {
    ok my @topics = $catalog->get_topics, 'Can get topics list';
    is scalar @topics, 29, 'Found number of topics correct as of v0.03';
};

done_testing;
