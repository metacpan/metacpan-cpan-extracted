use Test2::V0;

use WebService::OurWorldInData;

my $owid = WebService::OurWorldInData->new;

is $owid, object {
        prop isa => 'WebService::OurWorldInData';

        field base_url => 'https://ourworldindata.org';
        field ua       => check_isa 'HTTP::Tiny';

        end();
    }, 'Base class object correct';

done_testing;
