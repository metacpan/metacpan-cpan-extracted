
use strict;
use warnings;

use lib 'lib', '../lib'; #  XXX

use Test::More;

use JSON::PP;
use Data::Dumper;

# BEGIN { use_ok('WWW::Workflowy') }; # keeps the import magic from working
use WWW::Workflowy;

my $wf = WWW::Workflowy->new(
    outline => {
        'minutesSinceDateJoined' => 2882,
        'rootProjectChildren' => [
                                   {
                                     'lm' => 1259,
                                     'ch' => [
                                               {
                                                 'lm' => 1270,
                                                 'nm' => 'Test 2.1',
                                                 'id' => '63c98305-cd96-2016-4c4f-a20f7384ad9c'
                                               },
                                               {
                                                 'lm' => 1270,
                                                 'nm' => 'Test 2.2',
                                                 'id' => 'cf997f9e-2cef-aed8-d812-53be693f493e'
                                               },
                                               {
                                                 'lm' => 1270,
                                                 'ch' => [
                                                           {
                                                             'lm' => 1270,
                                                             'nm' => 'Test 2.3.1',
                                                             'id' => 'da52bd7b-87f9-6133-6254-c85547df4811'
                                                           },
                                                           {
                                                             'lm' => 1270,
                                                             'nm' => 'Test 2.3.2',
                                                             'id' => '2d06a022-f4ff-47d3-3180-43aeb4bbeabd'
                                                           }
                                                         ],
                                                 'nm' => 'Test 2.3',
                                                 'id' => 'e5932720-8811-e234-c35b-20f5ac7a83e3'
                                               }
                                             ],
                                     'nm' => 'Test2',
                                     'id' => '0da22641-65bf-9e96-70e7-dcc42c388cf3'
                                   },
                                   {
                                     'lm' => 1259,
                                     'ch' => [
                                               {
                                                 'lm' => 1285,
                                                 'nm' => 'Test 3.1 -- new!',
                                                 'id' => 'b18a71a4-91ec-d628-0fdf-97bc3264aace'
                                               },
                                               {
                                                 'lm' => 1285,
                                                 'nm' => 'aksjdhgkajshgsg',
                                                 'id' => 'bfd20738-461c-38a9-472f-0725d51c4b7e'
                                               }
                                             ],
                                     'nm' => 'Test3',
                                     'id' => '3d31a8f4-1dd5-dd5f-3af2-93e89a1e0763'
                                   }
                                 ],
        'dateJoinedTimestampInSeconds' => 1360996378,
        'initialMostRecentOperationTransactionId' => '106453325',
        'serverExpandedProjectsList' => [
                                          '0da22641',
                                          'e5932720'
                                        ],
        'rootProject' => {
                           'lm' => 1259,
                           'nm' => 'Test',
                           'id' => 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25'
                         },
        'shareType' => 'url',
        'initialPollingIntervalInMs' => 10000,
        'isReadOnly' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'overQuota' =>  bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
    }, 
);
$wf->sync_changes->run_remote_operations->shared_projectid = 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25';

my $concurrent_remote_operation_transactions = [
    '{"client_timestamp": 96134, "ppid": "4hTxEytH", "id": 128527449, "ops": [{"type": "create", "data": {"priority": 2, "projectid": "c23ef558-3b78-cd2e-59df-7e578cded1e1", "parentid": "0da22641-65bf-9e96-70e7-dcc42c388cf3"}, "server_data": {"shared_ancestor_ids_dict": {"c23ef558-3b78-cd2e-59df-7e578cded1e1": ":55877944:"}}}]}',
    '{"client_timestamp": 96134, "ppid": "paopgMgH", "id": 128527473, "ops": [{"type": "edit", "data": {"projectid": "c23ef558-3b78-cd2e-59df-7e578cded1e1", "name": "adding yet more stuff on the old Mac"}, "server_data": {"shared_ancestor_ids_dict": {"c23ef558-3b78-cd2e-59df-7e578cded1e1": ":55877944:"}}}, {"type": "create", "data": {"priority": 3, "projectid": "acafae16-c8f0-b7a6-d44c-4672f68815da", "parentid": "0da22641-65bf-9e96-70e7-dcc42c388cf3"}, "server_data": {"shared_ancestor_ids_dict": {"acafae16-c8f0-b7a6-d44c-4672f68815da": ":55877944:"}}}, {"type": "move", "data": {"priority": 0, "projectid": "acafae16-c8f0-b7a6-d44c-4672f68815da", "parentid": "c23ef558-3b78-cd2e-59df-7e578cded1e1"}, "server_data": {"shared_ancestor_ids_dict": {"acafae16-c8f0-b7a6-d44c-4672f68815da": ":55877944:", "c23ef558-3b78-cd2e-59df-7e578cded1e1": ":55877944:"}}}, {"type": "edit", "data": {"projectid": "acafae16-c8f0-b7a6-d44c-4672f68815da", "name": "tell me about it"}, "server_data": {"shared_ancestor_ids_dict": {"acafae16-c8f0-b7a6-d44c-4672f68815da": ":55877944:"}}}, {"type": "create", "data": {"priority": 1, "projectid": "40a5b129-afc9-d626-2792-6d68426a4870", "parentid": "c23ef558-3b78-cd2e-59df-7e578cded1e1"}, "server_data": {"shared_ancestor_ids_dict": {"40a5b129-afc9-d626-2792-6d68426a4870": ":55877944:"}}}]}',
    '{"client_timestamp": 96134, "ppid": "lEQtks39", "id": 128527505, "ops": [{"type": "edit", "data": {"projectid": "40a5b129-afc9-d626-2792-6d68426a4870", "name": "what goes on"}, "server_data": {"shared_ancestor_ids_dict": {"40a5b129-afc9-d626-2792-6d68426a4870": ":55877944:"}}}]}',
    # '{"client_timestamp": 96134, "ppid": "fB8DyH5u", "id": 128527561, "ops": [{"type": "edit", "data": {"projectid": "d789548d-ea28-ba88-0767-318618a7589d", "name": "Test 2.0 with stuff added to it plus more stuff - editing this on the old Mac"}, "server_data": {"shared_ancestor_ids_dict": {"d789548d-ea28-ba88-0767-318618a7589d": ":55877944:"}}}]}' # XXX can't handle editing nodes that don't exist; I wonder if there's fallback behavior of adding the node to the top level children or something; or maybe it just gets ignored
];

# my $run_operations = $result_json->{results}->[0]->{concurrent_remote_operation_transactions};  # as above:  an arrayref of strings

my $run_operations = $concurrent_remote_operation_transactions;


for my $run_op ( @$run_operations ) {
    my $decoded_run_op = decode_json $run_op or die;
# warn Data::Dumper::Dumper $decoded_run_op;
    # $run_remote_operations->( $run_op );
    $wf->sync_changes->run_remote_operations->( $decoded_run_op );
}

# print $wf->dump; # XXX

my ( $parent_node, $node, $priority, $siblings );

( $parent_node, $node, $priority, $siblings ) = WWW::Workflowy::_find_parent($wf->outline, 'c23ef558-3b78-cd2e-59df-7e578cded1e1');

ok $node;
ok $parent_node;
is $priority, 2;
is eval { $node->{id} } || $@, 'c23ef558-3b78-cd2e-59df-7e578cded1e1';
is eval { $node->{nm} } || $@,  "adding yet more stuff on the old Mac";
is eval { $parent_node->{id} } || $@, "0da22641-65bf-9e96-70e7-dcc42c388cf3";
ok $siblings;
ok grep( { $_->{id} eq 'cf997f9e-2cef-aed8-d812-53be693f493e' } @$siblings);
ok grep( { $_->{id} eq 'e5932720-8811-e234-c35b-20f5ac7a83e3' } @$siblings);

done_testing;


