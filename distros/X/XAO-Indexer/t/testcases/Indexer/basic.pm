package testcases::Indexer::basic;
use strict;
use XAO::Utils;

use base qw(testcases::Indexer::base);

sub test_basic {
    my $self=shift;
    my $config=$self->siteconfig;
    $self->assert(ref($config),
                  "Can't get test project configuration");
    my $odb=$config->odb;
    $self->assert(ref($odb),
                  "Can't get database handler");

    my $index_list=$odb->fetch('/Indexes');

    ##
    # Checking data structure for some signature properties.
    #
    my $index_new=$index_list->get_new;
    my $ds=$index_new->data_structure;
    $self->assert($ds->{'Data'}->{'structure'}->{'id_3'}->{'type'} eq 'blob',
                  "Wrong data structure (id_5)");
    $self->assert($ds->{'Data'}->{'structure'}->{'idpos_5'}->{'type'} eq 'blob',
                  "Wrong data structure (idpos_9)");

    ##
    # Trying multiple build_structure calls
    #
    $index_new->build_structure;
    $index_new->build_structure;
}

1;
