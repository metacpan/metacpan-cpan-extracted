package getopts;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-08'; # DATE
our $DIST = 'getopt'; # DIST
our $VERSION = '0.001'; # VERSION

use Getopt::Std ();

sub import {
    my $package = shift;
    my $caller = caller(0);
    my %opts;
    Getopt::Std::getopts(shift, \%opts);
    for (keys %opts) { ${"$caller\::opt_$_"} = $opts{$_} }
}

1;
# ABSTRACT: Shortcut for using Getopt::Std's getopts() from the command line

__END__

=pod

=encoding UTF-8

=head1 NAME

getopts - Shortcut for using Getopt::Std's getopts() from the command line

=head1 VERSION

This document describes version 0.001 of getopts (from Perl distribution getopt), released on 2020-04-08.

=head1 SYNOPSIS

 % perl -Mgetopts=oif: -e '...'

is shortcut for:

 % perl -MGetopt::Std -e 'getopts("oif:"); ...'

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/getopt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-getopt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=getopt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Std>

L<getopt>

perl's C<-s> switch

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
