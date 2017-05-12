use v5.10.1;
use Test::Roo;
use lib 't/lib';

with 'LogicMonitorTests';

has test_chain => (is => 'ro', default => 'api-test-chain');

test 'escalation chains' => sub {
    my $self = shift;

    ok my $chains = $self->lm->get_escalation_chains, 'Retrieve all chains';
    isa_ok $chains, 'ARRAY';

    my $chain1 = shift @$chains;
    isa_ok $chain1, 'WebService::LogicMonitor::EscalationChain';

    ok my $chain = $self->lm->get_escalation_chain_by_name($self->test_chain),
      'Retrieve one chain by name';
    isa_ok $chain, 'WebService::LogicMonitor::EscalationChain';
    is $chain->name, $self->test_chain;

    my $cur_time = time;
    $chain->description("API Testing [$cur_time]");
    ok $chain->update, 'Update chain';

    ok my $chain2 = $self->lm->get_escalation_chain_by_name($self->test_chain),
      'Retrieve updated chain';
    is $chain2->description, "API Testing [$cur_time]",
      'Description has been updated';

};

run_me;
done_testing;
