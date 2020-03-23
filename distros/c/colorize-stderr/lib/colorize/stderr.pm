package colorize::stderr;

our $DATE = '2020-03-21'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use colorize::handle ();

sub import {
    my ($pkg, $color) = @_;
    $color = "yellow" unless defined $color;

    colorize::handle->import(\*STDERR, $color);
}

sub unimport {
    my ($pkg) = @_;

    colorize::handle->unimport(\*STDERR);
}


1;
# ABSTRACT: Colorize STDERR

__END__

=pod

=encoding UTF-8

=head1 NAME

colorize::stderr - Colorize STDERR

=head1 VERSION

This document describes version 0.002 of colorize::stderr (from Perl distribution colorize-stderr), released on 2020-03-21.

=head1 SYNOPSIS

 use colorize::stderr;
 warn "blah!"; # will be printed in yellow

If you want to customize color:

 use colorize::stderr 'red on_white';
 warn "blah!";

Use in command-line, nifty for debugging (making it easy to notice whether an
output to terminal is to STDOUT or STDERR):

 % perl -Mcolorize::stderr ...

=head1 DESCRIPTION

This is a convenience wrapper over L<colorize::handle> for colorizing STDERR.

Caveat: although this module provides C<unimport()>, this code does not do what
you expect it to do:

 {
     use colorize::stderr;
     warn "colored warning!";
 }
 warn "back to uncolored";

Because C<no colorize::stderr> will be run at compile-time. You can do this
though:

 use colorize::stderr ();

 {
     colorize::stderr->import;
     warn "colored warning!";
     colorize::stderr->unimport;
 }
 warn "back to uncolored";

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/colorize-stderr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-colorize-handle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=colorize-stderr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<colorize::handle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
