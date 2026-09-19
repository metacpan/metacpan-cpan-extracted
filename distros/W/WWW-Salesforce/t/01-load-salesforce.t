use strict;
use warnings;

use Test::More;
use WWW::Salesforce ();

can_ok(
    'WWW::Salesforce',
    (
        qw(getErrorDetails checkRetrieveStatus checkAsyncStatus),
        qw(retrieveMetadata describeMetadata get_session_headerM get_clientM),
        qw(update upsert search setPassword retrieve resetPassword query),
        qw(queryAll queryMore getUserInfo getDeleted getUpdated),
        qw(getServerTimestamp get_client get_session_header logout),
        qw(describeLayout describeSObjects describeTabs describeSObject create),
        qw(delete describeGlobal convertLead new bye do_query do_queryAll),
        qw(_retrieve_queryMore get_field_list get_tables),
    )
);

done_testing();
