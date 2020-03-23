package colorize::handle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-21'; # DATE
our $DIST = 'colorize-stderr'; # DIST
our $VERSION = '0.002'; # VERSION

BEGIN { if ($^O =~ /^(MSWin32)$/) { require Win32::Console::ANSI } }

use strict;
use warnings;
use PerlIO::via::ANSIColor;

my %colorized; # key = handle

sub import {
    my ($pkg, $handle, $color) = @_;
    die "Please specify handle and color" unless $handle && $color;

    return if $colorized{$handle};

    my @layers = PerlIO::get_layers($handle);
    PerlIO::via::ANSIColor->color($color);
    binmode($handle, ":via(ANSIColor)");

    $colorized{$handle} = [scalar(@layers)];
}

sub unimport {
    my ($pkg, $handle) = @_;
    die "Please specify handle" unless $handle;

    return unless $colorized{$handle};
    my $pos = $colorized{$handle}[0];

    my @layers = PerlIO::get_layers($handle);
    if ($pos == $#layers && $layers[$pos] eq 'via') {
        # get_layers() only return 'via' so we assume that the last 'via' layer
        # is us.
        binmode($handle, ':pop');
    }

    undef $colorized{$handle};
}


1;
# ABSTRACT: Colorize a filehandle

__END__

=pod

=encoding UTF-8

=head1 NAME

colorize::handle - Colorize a filehandle

=head1 VERSION

This document describes version 0.002 of colorize::handle (from Perl distribution colorize-stderr), released on 2020-03-21.

=head1 SYNOPSIS

 use colorize::handle \*STDERR, "yellow";

Also see the more convenient subclass L<colorize::stderr> for colorizing STDERR.

=head1 DESCRIPTION

This is a thin wrapper over L<PerlIO::via::ANSIColor>.

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

L<PerlIO::via::ANSIColor>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
