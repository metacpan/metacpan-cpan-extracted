package Timeout::Self;

our $DATE = '2015-01-14'; # DATE
our $VERSION = '0.01'; # VERSION

sub import {
    my $package = shift;
    die "Please specify timeout value" unless @_;
    $SIG{ALRM} = sub { die "Timeout\n" };
    alarm(shift);
}

1;
# ABSTRACT: Run alarm() at the start of program to timeout run

__END__

=pod

=encoding UTF-8

=head1 NAME

Timeout::Self - Run alarm() at the start of program to timeout run

=head1 VERSION

This document describes version 0.01 of Timeout::Self (from Perl distribution Timeout-Self), released on 2015-01-14.

=head1 SYNOPSIS

In a script:

 # run for at most 30 seconds
 use Timeout::Self qw(30);

From the command line:

 % perl -MTimeout::Self=30 yourscript.pl

=head1 DESCRIPTION

This module simply installs a $SIG{ALRM} that dies, and an alarm() call with a
certain value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Timeout-Self>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Timeout-Self>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Timeout-Self>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
