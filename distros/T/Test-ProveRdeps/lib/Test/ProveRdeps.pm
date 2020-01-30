package Test::ProveRdeps;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-30'; # DATE
our $DIST = 'Test-ProveRdeps'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;

use App::ProveRdeps;
use Data::Dmp;
use Test::Builder;

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    *{$caller.'::all_rdeps_ok'} = \&all_rdeps_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub all_rdeps_ok {
    my %opts = @_;
    my $res;
    my $ok = 1;

    {
        my $prres = App::ProveRdeps::prove_rdeps(%opts);
        unless ($prres->[0] == 200) {
            $Test->diag("Can't run prove_rdeps(): $prres->[0] - $prres->[1]");
            $Test->ok(0, "run prove_rdeps()");
            $ok = 0;
            last;
        }

        my $num_412 = 0;
        my $num_other_err = 0;
        for my $rec (@{ $prres->[2] }) {
            if ($rec->{status} == 412) {
                $num_412++;
            } elsif ($rec->{status} != 200) {
                $num_other_err++;
            }
        }

        if ($num_412 || $num_other_err) {
            $Test->diag("Some dependents cannot be tested or testing failed: ".dmp($prres->[2]));
        }

        if ($num_other_err) {
            $Test->ok(0, "prove_rdeps() result");
            $ok = 0;
            last;
        } else {
            $Test->ok(1, "prove_rdeps() result");
        }
    }

    $ok;
}

1;
# ABSTRACT: Test using App::ProveRdeps

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::ProveRdeps - Test using App::ProveRdeps

=head1 VERSION

This document describes version 0.002 of Test::ProveRdeps (from Perl distribution Test-ProveRdeps), released on 2020-01-30.

=head1 SYNOPSIS

 use Test::ProveRdeps tests=>1;
 all_rdeps_ok(
     modules => ["Foo::Bar"],
     # other options will be passed to App::ProveRdeps::prove_rdeps()
 );

=head1 DESCRIPTION

EXPERIMENTAL.

=for Pod::Coverage ^()$

=head1 FUNCTIONS

=head2 all_rdeps_ok

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-ProveRdeps>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-ProveDeps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-ProveRdeps>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::ProveRdeps> and L<prove-rdeps>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
