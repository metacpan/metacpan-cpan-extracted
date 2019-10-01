package testcases::Content::WebContent;
use strict;
use XAO::Objects;

use base qw(testcases::Content::base);

sub test_everything {
    my $self=shift;

    my $cobj=XAO::Objects->new(objname => 'Web::Content');
    $self->assert(ref($cobj),
                  "Can't load Web::Content object");

    ##
    # Building structure
    #
    my $odb=$cobj->odb;
    $self->assert(ref($odb),
                  "No database handler");
    my $structure=$cobj->data_structure;
    $self->assert(ref($structure) eq 'HASH',
                  "No database structure returned");
    $odb->fetch('/')->build_structure($structure);
    $odb->fetch('/')->drop_placeholder('Content');
    $cobj->build_structure;
    $cobj->build_structure;

    # XXX - We shall have some more tests here.
}

1;
