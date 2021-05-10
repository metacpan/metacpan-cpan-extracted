package Text::NonWideChar::Util;

our $DATE = '2021-04-16'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       length_height
               );

sub length_height {
    my $text = shift;
    my $num_lines = 0;
    my $len = 0;
    for my $e (split /(\r?\n)/, $text) {
        if ($e =~ /\n/) {
            $num_lines++;
            next;
        }
        $num_lines = 1 if $num_lines == 0;
        my $l = length($e);
        $len = $l if $len < $l;
    }
    [$len, $num_lines];
}

1;
# ABSTRACT: Utility routines for text

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::NonWideChar::Util - Utility routines for text

=head1 VERSION

This document describes version 0.004 of Text::NonWideChar::Util (from Perl distribution Text-NonWideChar-Util), released on 2021-04-16.

=head1 SYNOPSIS

 use Text::NonWideChar::Util qw(
     length_height);

 # get length as well as number of lines
 say mbswidth_height("one\ntwo\nthree"); # => [5, 3]

=head1 DESCRIPTION

This module provides the non-wide version of some of the routines in
L<Text::WideChar::Util>.

=head1 FUNCTIONS

=head2 length_height($text) => [INT, INT]

This is the non-wide version of C<mbswidth_height()> and can be used if your
text only contains printable ASCII characters and newlines.

=head1 FAQ

=head2 Why split functionalities of wide character and color support into multiple modules/distributions?

Performance (see numbers in the function description), dependency
(L<Unicode::GCString> is used for wide character support), and overhead (loading
Unicode::GCString).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-NonWideChar-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-NonWideChar-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-NonWideChar-Util/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::WideChar::Util>

L<String::Pad>, L<Text::Wrap>

L<Text::ANSI::Util>, L<Text::ANSI::WideUtil>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
