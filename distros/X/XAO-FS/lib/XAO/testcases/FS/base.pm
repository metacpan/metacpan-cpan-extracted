package XAO::testcases::FS::base;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::testcases::base;

use base qw(XAO::testcases::base);

sub new ($) {
    my $proto=shift;
    my $self=$proto->SUPER::new(@_);

    # Reading configuration
    #
    my %d;
    if(open(F,'.config')) {
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }

    (!$@ && $d{'test_dsn'}) ||
        die "Invalid config, re-run 'perl Makefile.PL'\n";

    $self->{'dbconfig'}=\%d;

    if($d{'test_dsn'} eq 'none') {
        dprint "No DSN configured, skipping all tests";
        $self->{'skip_db_tests'}=1;
        return;
    }

    return $self;
}

sub list_tests ($) {
    my $self=shift;

    if($self->{'skip_db_tests'}) {
        return wantarray ? () : [];
    }
    else {
        return $self->SUPER::list_tests(@_);
    }
}

sub reconnect ($) {
    my $self=shift;

    my $dbconfig=$self->{'dbconfig'};

    $self->assert($dbconfig->{'test_dsn'},
                  "No test configuration available (no .config)");

    $self->{'odb'}=XAO::Objects->new(
        objname             => 'FS::Glue',
        dsn                 => $dbconfig->{'test_dsn'},
        user                => $dbconfig->{'test_user'},
        password            => $dbconfig->{'test_password'},
        check_consistency   => 1,
    );

    return $self->get_odb;
}

sub set_up ($) {
    my $self=shift;

    ### $self->SUPER::set_up(@_);

    my $dbconfig=$self->{'dbconfig'};

    $self->assert($dbconfig->{'test_dsn'},
                  "No test configuration available (no .config)");

    $self->{'odb'}=XAO::Objects->new(
        objname             => 'FS::Glue',
        dsn                 => $dbconfig->{'test_dsn'},
        user                => $dbconfig->{'test_user'},
        password            => $dbconfig->{'test_password'},
        empty_database      => 'confirm',
        check_consistency   => 1,
    );

    $self->assert($self->{odb}, "Can't connect to the FS database");

    $self->{'odb_args'}={
        dsn         => $dbconfig->{'test_dsn'},
        user        => $dbconfig->{'test_user'},
        password    => $dbconfig->{'test_password'},
    };

    my $global=$self->{'odb'}->fetch('/');
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

    ### $self->SUPER::tear_down(@_);

    $self->{odb}=undef;
}

sub get_odb {
    my $self=shift;
    my $odb=$self->{'odb'};
    $self->assert(defined($odb) && ref($odb), 'No object database handler');
    $odb;
}

use vars qw(*SE);
sub stderr_stop {
    open(SE,">&STDERR");
    open(STDERR,">/dev/null");
}

sub stderr_restore {
    open(STDERR,">&SE");
    close(SE);
}

1;
