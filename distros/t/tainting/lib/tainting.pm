package tainting;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'tainting'; # DIST
our $VERSION = '0.031'; # VERSION

use strict;
use warnings;

use Taint::Runtime qw(taint_env taint_start taint_stop);

my $env_tainted;

sub import {
    my $self = shift;

    taint_start();
    taint_env() unless $env_tainted++;
}

sub unimport {
    my $self = shift;

    taint_stop();
}

1;
# ABSTRACT: (DEPRECATED) Enable taint mode lexically

__END__

=pod

=encoding UTF-8

=head1 NAME

tainting - (DEPRECATED) Enable taint mode lexically

=head1 VERSION

This document describes version 0.031 of tainting (from Perl distribution tainting), released on 2021-08-06.

=head1 SYNOPSIS

To enable tainting in a lexical block:

 {
     use tainting;
     # tainting is enabled
 }
 # tainting is disabled again

To disable tainting in a lexical block:

 use tainting;
 {
     no tainting;
     # tainting is disabled
 }
 # tainting is enabled again

=head1 DESCRIPTION

B<DEPRECATION NOTICE>: tainting.pm is broken and will be purged from CPAN
because the lexical switching is done at compile time while tainting is
performed at runtime. Please see L<Taint::Runtime> and localize C<$TAINT>
instead.

This module provides a simpler interface to L<Taint::Runtime>. The idea is so
that there is no functions or variables to import. Just C<use> or C<no>, like
L<warnings> or L<strict>. Tainting of C<%ENV> will be done one time
automatically the first time this module is used.

Please (PLEASE) read Taint::Runtime's documentation first about the pro's and
con's of enabling/disabling tainting at runtime. TL;DR: Use -T if you can.

=for Pod::Coverage ^(import|unimport)$

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/tainting>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-tainting>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=tainting>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Taint::Runtime>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
