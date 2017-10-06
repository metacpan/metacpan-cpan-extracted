use Test2::V0;
use Test2::Tools::JSON;

use Test2::Util::Table ();
use Test2::Compare::Custom;

sub table { join "\n" => Test2::Util::Table::table(@_) }

is intercept {
    is {
        json => '[1,2,3,]',
    }, {
        json => json([1,2,3]),
    };
}, array {
    event Ok => { pass => 0 };
    etc;
}, 'fail due to invalid JSON with trailing commas';

is {
    json => '[1,2,3,]',
}, {
    json => relaxed_json([1,2,3]),
}, 'compare with relaxed JSON';

done_testing;
