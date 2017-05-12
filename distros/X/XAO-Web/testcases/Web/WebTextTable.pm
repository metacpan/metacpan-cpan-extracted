package testcases::Web::WebTextTable;
use strict;
use XAO::Projects;
use XAO::Utils;

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $got=$page->expand(path => '/bits/WebTextTable/table-source');
    my $expect=$page->expand(path => '/bits/WebTextTable/table-result');
    dprint "Expect:>>>$expect<<< l=",length($expect);
    dprint "   Got:>>>$got<<< l=",length($got);
    $self->assert($got eq $expect,
                  "Text table does not match");
}

1;
