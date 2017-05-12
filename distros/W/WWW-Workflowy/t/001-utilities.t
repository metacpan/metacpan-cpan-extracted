
use strict;
use warnings;

use lib 'lib', '../lib'; #  XXX

use Test::More;

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

my  ( $parent_node, $node, $priority, $siblings );

#

diag "parent of root level node";

( $parent_node, $node, $priority, $siblings ) = WWW::Workflowy::_find_parent($wf->outline, 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25');  # root level node; no parent

ok $node;
ok ! $parent_node;
is $priority, 0;
is eval { $node->{id} } || $@, 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25';
is eval { $node->{nm} } || $@, 'Test';
ok $siblings;
ok grep( { $_->{id} eq 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25' } @$siblings);  # we are one of our own siblings
is scalar @$siblings, 1;                                                       # only ourself; no other siblings

#

diag "parent of non-root level node";

( $parent_node, $node, $priority, $siblings ) = WWW::Workflowy::_find_parent($wf->outline, 'bfd20738-461c-38a9-472f-0725d51c4b7e');

ok $node;
ok $parent_node;
is $priority, 1;
is eval { $node->{id} } || $@, 'bfd20738-461c-38a9-472f-0725d51c4b7e';
is eval { $node->{nm} } || $@, 'aksjdhgkajshgsg';
is eval { $parent_node->{id} } || $@, '3d31a8f4-1dd5-dd5f-3af2-93e89a1e0763';
ok $siblings;
ok grep( { $_->{id} eq 'bfd20738-461c-38a9-472f-0725d51c4b7e' } @$siblings);    # we are one of our own sublings
ok grep( { $_->{id} eq 'b18a71a4-91ec-d628-0fdf-97bc3264aace' } @$siblings);    # our other sibling
is scalar @$siblings, 2;

#




done_testing;


