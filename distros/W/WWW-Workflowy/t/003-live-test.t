
use strict;
use warnings;

use lib 'lib', '../lib'; #  XXX

use Test::More;

use WWW::Workflowy;

my $wf = WWW::Workflowy->new(
    url => 'https://workflowy.com/shared/b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25/',
    # or else:  guid => 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25',
);

# print $wf->dump;

my $new_node_name = "Don't forget to shave the yak " . int rand 10000;

my $node_id = $wf->create(
    parent_id => 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25',
    priority  => 0,    # which position in the list of items under the parent to insert this node
    text      => $new_node_name,
);

ok $node_id, "create() returned a value for node_id: $node_id";


# $wf->fetch;
# $wf->sync;

# print $wf->dump;

my $node;

$node = $wf->find(
    sub {
        my $node = shift;
        my @parent_nodes = @{ shift() };
        return 1 if $node->{id} eq $node_id;
    },
);

ok $node, 'Found the node we created, by ID';

$node = $wf->find(
    sub {
        my $node = shift;
        return 1 if $node->{nm} eq $new_node_name;
    },
);

ok $node, 'Found the node we created, by text';

$wf->edit(
    save_id => $node_id,
    text      => "Think of an idea for a color for the bikeshed",
);

$node = $wf->find(
    sub {
        my $node = shift;
        return 1 if $node->{nm} eq $new_node_name;
    },
);

# die Data::Dumper::Dumper $wf->update_outline->operations;

ok ! $node, "after edit, can't find the node by its old text";

$node = $wf->find(
    sub {
        my $node = shift;
        return 1 if $node->{nm} eq "Think of an idea for a color for the bikeshed";
    },
);

ok $node, "after edit, can find the node by its new text";

# $wf->fetch;
# $wf->sync;

$wf->delete( $node_id,);

$node = $wf->find(
    sub {
        my $node = shift;
        return 1 if $node->{nm} eq "Think of an idea for a color for the bikeshed";
    },
);

ok ! $node, "after delete, can't find node by its new text either";

# $wf->fetch;

# print $wf->dump;

sleep $wf->polling_interval;  $wf->sync;

# $wf->fetch;

done_testing;

