package testcases::Web::FS;
use strict;
use XAO::Objects;

use base qw(XAO::testcases::Web::base);

sub test_everything {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $odb=$page->odb();
    $self->assert(ref($odb),
                  "Can't get FS database handler from Page");
}

1;
