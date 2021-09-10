use strict;
use warnings;

use Test::More;
use WWW::Salesforce::Simple ();

can_ok(
    'WWW::Salesforce::Simple',
    (
        qw(new login bye do_query do_queryAll _retrieve_queryMore),
        qw(get_field_list get_tables),
    )
);

done_testing();
