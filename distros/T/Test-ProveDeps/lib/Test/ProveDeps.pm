package Test::ProveDeps;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-29'; # DATE
our $DIST = 'Test-ProveDeps'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

use App::ProveDeps;
use Data::Dmp;
use Test::Builder;

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    *{$caller.'::all_dependents_ok'} = \&all_dependents_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub all_dependents_ok {
    my %opts = @_;
    my $res;
    my $ok = 1;

    {
        my $pdres = App::ProveDeps::prove_deps(%opts);
        unless ($pdres->[0] == 200) {
            $Test->diag("Can't run prove_deps(): $pdres->[0] - $pdres->[1]");
            $Test->ok(0, "run prove_deps()");
            $ok = 0;
            last;
        }

        my $num_412 = 0;
        my $num_other_err = 0;
        for my $rec (@{ $pdres->[2] }) {
            if ($rec->{status} == 412) {
                $num_412++;
            } elsif ($rec->{status} != 200) {
                $num_other_err++;
            }
        }

        if ($num_412 || $num_other_err) {
            $Test->diag("Some dependents cannot be tested or testing failed: ".dmp($pdres->[2]));
        }

        if ($num_other_err) {
            $Test->ok(0, "prove_deps() result");
            $ok = 0;
            last;
        } else {
            $Test->ok(1, "prove_deps() result");
        }
    }

    $ok;
}

1;
# ABSTRACT: Test using App::ProveDeps

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::ProveDeps - Test using App::ProveDeps

=head1 VERSION

This document describes version 0.001 of Test::ProveDeps (from Perl distribution Test-ProveDeps), released on 2020-01-29.

=head1 SYNOPSIS

 use Test::ProveDeps tests=>1;
 all_dependents_ok(
     modules => ["Foo::Bar"],
     # other options will be passed to App::ProveDeps::prove_deps()
 );

=head1 DESCRIPTION

EXPERIMENTAL.

=for Pod::Coverage ^()$

=head1 FUNCTIONS

=head2 all_dependents_ok

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-ProveDeps>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-ProveDeps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-ProveDeps>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::ProveDeps> and L<prove-deps>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
