package testcases::Web::Templates;
use strict;
use XAO::Templates;
use XAO::Projects;
use Encode;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_templates {
    my $self=shift;

    my %tests=(
        '/bits/test-unicode'    => "Проверка Юникода<%End%>\n",
        '/bits/test-ascii'      => "Ascii\n",
    );

    foreach my $path (keys %tests) {
        my $got=XAO::Templates::get(path => $path);

        $self->assert(defined $got,
            "Expected to get a defined content for $path");

        $self->assert($got eq $tests{$path},
            "Expected to get '$tests{$path}', got '$got'");

        $self->assert(!Encode::is_utf8($got),
            "Expected to get bytes for '$path', got a perl unicode string '$got'");
    }
}

###############################################################################
1;
