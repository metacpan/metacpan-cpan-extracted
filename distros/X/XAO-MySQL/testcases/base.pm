package testcases::base;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(Test::Unit::TestCase);

sub set_up {
    my $self=shift;

    ##
    # Reading configuration
    #
    my %d;
    if(open(F,'.config')) {
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }
    $self->assert($d{test_dsn},
                  "No test configuration available (no .config)");

    $self->{odb}=XAO::Objects->new(objname => 'FS::Glue',
                                   dsn => $d{test_dsn},
                                   user => $d{test_user},
                                   password => $d{test_password},
                                   empty_database => 'confirm');
    $self->assert($self->{odb}, "Can't connect to the FS database");

    $self->{odb_args}={
        dsn => $d{test_dsn},
        user => $d{test_user},
        password => $d{test_password},
    };

    my $global=$self->{odb}->fetch('/');
    $self->assert($global, "Can't fetch Global from FS database");

    $global->build_structure(
        Customers => {
            type => 'list',
            class => 'Data::Customer',
            key => 'customer_id',
            structure => {
                name => {
                    type => 'text',
                    maxlength => 40,
                },
            },
        },
    );

    my $clist=$self->{odb}->fetch('/Customers');
    $self->assert($clist, "Can't fetch /Customers from FS database");

    my $customer=$clist->get_new();
    $self->assert(ref($customer), "Can't create new Data::Customer");

    $customer->put(name => 'Test Customer #1');

    $clist->put(c1 => $customer);

    $customer->put(name => 'Test Customer #2');

    $clist->put(c2 => $customer);
}

sub tear_down {
    my $self=shift;
    $self->{odb}=undef;
}

sub get_odb {
    my $self=shift;
    my $odb=$self->{odb};
    $self->assert(defined($odb) && ref($odb), 'No object database handler');
    $odb;
}

sub timestamp ($$) {
    my $self=shift;
    time;
}

sub timediff ($$$) {
    my $self=shift;
    my $t1=shift;
    my $t2=shift;
    $t1-$t2;
}

1;
