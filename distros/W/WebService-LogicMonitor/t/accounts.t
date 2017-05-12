use Test::Roo;
use lib 't/lib';

with 'LogicMonitorTests';

test accounts => sub {
    my $self = shift;

    ok my $accounts = $self->lm->get_accounts;
    isa_ok $accounts, 'ARRAY';

    my $account1 = shift @$accounts;
    isa_ok $account1, 'WebService::LogicMonitor::Account';

    ok my $account =
      $self->lm->get_account_by_email('logicmonitor-apitest@sophos.com');
    isa_ok $account, 'WebService::LogicMonitor::Account';

    note "Fragile tests ahead";
    is $account->id,       58;
    is $account->username, 'apitest';
};

run_me;
done_testing;
