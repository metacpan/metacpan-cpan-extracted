package testcases::Web::WebUtility;
use strict;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

sub test_number_ordinal_suffix {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my %matrix=(
        123     => 'rd',
        1001    => 'st',
        14      => 'th',
        23413   => 'th',
        0       => 'th',
        -234    => 'th',
        222     => 'nd',
    );

    foreach my $test (keys %matrix) {
        my $got=$page->expand(
            template    => '<%Utility mode="number-ordinal-suffix" number="<%N/f%>"%>',
            N           => $test,
        );
        my $expect=$matrix{$test};
        $self->assert($got eq $expect,
                      "Test for '$test' failed - expected '$expect', got '$got'");
    }
}

1;
