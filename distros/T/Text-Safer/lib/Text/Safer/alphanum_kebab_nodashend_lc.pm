package Text::Safer::alphanum_kebab_nodashend_lc;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-14'; # DATE
our $DIST = 'Text-Safer'; # DIST
our $VERSION = '0.003'; # VERSION

our %META = (
    summary => 'Like alphanum_kebab, but additionally lower case & remove dash at the beginning & end of text, e.g. "Foo Bar, Co., Ltd." -> "foo-bar-co-ltd"',
    args => {
    },
);

sub encode_safer {
    my ($text, $args) = @_;
    $args //= {};

    $text =~ s/[^A-Za-z0-9_-]+/-/g;
    $text =~ s/-\z//; $text =~ s/\A-//;
    $text = "-" if !length($text);
    lc $text;
}

1;
# ABSTRACT: Like alphanum_kebab, but additionally lower case & remove dash at the beginning & end of text, e.g. "Foo Bar, Co., Ltd." -> "foo-bar-co-ltd"

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Safer::alphanum_kebab_nodashend_lc - Like alphanum_kebab, but additionally lower case & remove dash at the beginning & end of text, e.g. "Foo Bar, Co., Ltd." -> "foo-bar-co-ltd"

=head1 VERSION

This document describes version 0.003 of Text::Safer::alphanum_kebab_nodashend_lc (from Perl distribution Text-Safer), released on 2025-06-14.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 encode_safer

Arguments:

=over

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Safer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Safer>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Safer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
