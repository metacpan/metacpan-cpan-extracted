package testcases::config;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(testcases::base);

sub test_everything {
    my $self=shift;

    my $config=XAO::Objects->new(objname => 'Config', baseobj => 1);
    $self->assert(ref($config),
                  "Can't get base config object");

    my $fsconfig=XAO::Objects->new(objname => 'FS::Config',
                                   odb_args => {
                                     dsn => $self->{odb_args}->{dsn},
                                     user => $self->{odb_args}->{user},
                                     password => $self->{odb_args}->{password},
                                   });
    $self->assert(ref($fsconfig),
                  "Can't get FS config object");

    $config->embed(fs => $fsconfig);

    $self->assert(ref($config->odb),
                  "Can't get database handler from the config");

    my $ok=0;
    try {
        $config->odb($self->get_odb);
    }
    otherwise {
        $ok=1;
    };
    $self->assert($ok,
                  "Setting odb succeeded without enabling special access");

    $config->embedded('fs')->enable_special_access();
    $config->odb($self->get_odb);
    $config->embedded('fs')->enable_special_access();
    $self->assert(ref($config->odb),
                  "Updating odb did not work");
    $self->assert($config->odb == $self->get_odb,
                  "ODB after update points to wrong location");
}

1;
