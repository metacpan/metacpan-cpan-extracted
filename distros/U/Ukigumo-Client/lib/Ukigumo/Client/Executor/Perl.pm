use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Perl;
use Config;
use Mouse;
use Ukigumo::Constants;

sub run {
    my ($self, $c) = @_;

    if (-f 'Makefile.PL') {
        $c->tee("perl Makefile.PL")==0 or return STATUS_FAIL;
        $c->tee("$Config{make} test")==0 or return STATUS_FAIL;
        return STATUS_SUCCESS;
    } elsif (-f 'Build.PL') {
        $c->tee("perl Build.PL")==0 or return STATUS_FAIL;
        $c->tee($^O eq 'MSWin32' ? "Build test" : "./Build test")==0 or return STATUS_FAIL;
        return STATUS_SUCCESS;
    } else {
        $c->logger->warnf("There is no Makefile.PL or Build.PL");
        return STATUS_NA;
    }
}

1;

__END__

=head1 NAME

Ukigumo::Client::Executor::Perl - Test executor for project written by perl.

=head1 DESCRIPTION

This executor runs 'perl Makefile.PL && make test' or 'perl Build.PL && ./Build test'.
