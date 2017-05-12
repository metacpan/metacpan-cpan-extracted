package XAO::testcases::FS::qstart;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::basic);

sub set_up {
    my $self=shift;

    # We call the main setup, let it create the basic structure, then
    # disconnect, reconned in default mode without destroying or
    # checking the database.
    #
    $self->SUPER::set_up();

    $self->{'odb'}->disconnect;
    undef $self->{'odb'};

    $self->{'odb'}=XAO::Objects->new($self->{'odb_args'},{
        objname             => 'FS::Glue',
    });
    $self->assert($self->{'odb'}, "Can't re-connect to the FS database");

    dprint "Database reconnected in 'quick' (normal run) mode";
}

### sub test_1 ($) {
###     my $self=shift;
###     dprint "self=$self";
###     my $odb=$self->get_odb;
###     dprint "odb=$odb";
### }

1;
