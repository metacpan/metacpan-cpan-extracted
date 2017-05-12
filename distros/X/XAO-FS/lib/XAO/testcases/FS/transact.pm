package XAO::testcases::FS::transact;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

sub test_transact {
    my $self=shift;

    my $odb=$self->{odb};
    $self->assert(defined($odb) && ref($odb),
                  'Object database creating failure');

    ##
    # Testing just normal stuff, this should work even where there is no
    # support of transactions.
    #
    my $customer=$odb->fetch('/Customers/c1');
    $self->assert(! $odb->transact_active,
                  "1 - Transaction is active before transact_begin()");
    $odb->transact_begin;
    $self->assert($odb->transact_active,
                  "1 - Transaction is not active after transact_begin()");
    my $text='test' . time;
    $customer->put(name => $text);
    $customer=$odb->fetch('/Customers')->get('c1');
    my $got=$customer->get('name');
    $self->assert($got eq $text,
                  "1a - Got wrong value '$got', expected '$text'");
    $odb->transact_commit;
    $self->assert(! $odb->transact_active,
                  "1 - Transaction is still active after transact_commit()");
    $customer=$odb->fetch('/Customers')->get('c1');
    $got=$customer->get('name');
    $self->assert($got eq $text,
                  "1b - Got wrong value '$got', expected '$text'");

    ##
    # Testing roll back. Will only work if there is real support for
    # transactions. We still go through the ordeal and then check if
    # driver correctly reports its transactions support status.
    #
    my $pname=$odb->fetch('/')->get('project');
    $odb->transact_begin;
    my $newtext=$text."NEW";
    $customer->put(name => $newtext);
    $got=$odb->fetch('/Customers/c1/name');
    $self->assert($got eq $newtext,
                  "2a - Got wrong value '$got', expected '$newtext'");
    $odb->fetch('/')->put(project => 'foobar');
    $odb->transact_rollback;
    $got=$odb->fetch('/Customers/c1/name');
    if($odb->transact_can) {
        $self->assert($got eq $text,
                      "2b - Got wrong value '$got', expected '$text'");
        $self->assert($odb->fetch('/project') eq $pname,
                      "2c - Got wrong value for /project, expected '$pname'");
    }
    else {
        $self->assert($got eq $newtext,
                      "2d - Got a value that would be expected from\n" .
                      "a driver that supports transaction ($got),\n" .
                      "expected '$newtext'");
        return;
    }
}

sub test_isolation {
    my $self=shift;

    my $odb1=$self->{odb};
    $self->assert(defined($odb1) && ref($odb1),
                  '1 - Object database creating failure');

    if(! $odb1->transact_can) {
        print STDERR "Driver does not support transactions\n";
        return;
    }

    my $oa=$self->{odb_args};
    my $odb2=XAO::Objects->new(objname => 'FS::Glue',
                                dsn => $oa->{dsn},
                                user => $oa->{user},
                                password => $oa->{password});
    $self->assert(defined($odb2) && ref($odb2),
                  '2 - Object database creating failure');

    my $o1c1=$odb1->fetch('/Customers/c1');
    my $o1c2=$odb1->fetch('/Customers/c2');
    my $o2c1=$odb2->fetch('/Customers/c1');
    my $o2c2=$odb2->fetch('/Customers/c2');

    $o1c2->put(name => 'c2_init');
    $o1c1->put(name => 'o1c1_before');
    $odb1->transact_begin;
    $o1c1->put(name => 'o1c1_after');

    my $got=$o1c1->get('name');
    $self->assert($got eq 'o1c1_after',
                  "3 - isolation failure - got '$got', expected 'o1c1_after'");
    $got=$o2c1->get('name');
    $self->assert($got eq 'o1c1_before',
                  "4 - isolation failure - got '$got', expected 'o1c1_before'");

    # Once we begin a transaction values are frozen and o1c2 should read
    # c2_init even after it was changed outside of odb2 transaction.
    #
    $o2c2->put(name => 'o2c2_before');
    $got=$o2c2->get('name');
    $self->assert($got eq 'o2c2_before',
                  "5 - isolation failure - got '$got', expected 'o2c2_before'");
    $got=$o1c2->get('name');
    $self->assert($got eq 'c2_init',
                  "6 - isolation failure - got '$got', expected 'c2_init'");

    $odb2->transact_begin;
    $o2c2->put(name => 'o2c2_after');

    $got=$o2c2->get('name');
    $self->assert($got eq 'o2c2_after',
                  "7 - isolation failure - got '$got', expected 'o2c2_after'");
    $got=$o1c2->get('name');
    $self->assert($got eq 'c2_init',
                  "8 - isolation failure - got '$got', expected 'c2_init'");

    $odb1->transact_commit;
    $got=$o1c1->get('name');
    $self->assert($got eq 'o1c1_after',
                  "9 - isolation failure - got '$got', expected 'o1c1_after'");
    $got=$o2c1->get('name');
    $self->assert($got eq 'o1c1_before',
                  "10 - isolation failure - got '$got', expected 'o1c1_before'");

    $odb2->transact_rollback;
    $got=$o1c2->get('name');
    $self->assert($got eq 'o2c2_before',
                  "11 - isolation failure - got '$got', expected 'o2c2_before'");
    $got=$o2c2->get('name');
    $self->assert($got eq 'o2c2_before',
                  "12 - isolation failure - got '$got', expected 'o2c2_before'");

    # once our transaction has been rolled back we should start getting
    # the value committed by odb1 transaction
    #
    $got=$o2c1->get('name');
    $self->assert($got eq 'o1c1_after',
                  "13 - isolation failure - got '$got', expected 'o1c1_after'");
}

1;
