# no code
## no critic: TestingAndDebugging::RequireUseStrict
package WordLists::EN::Adverb;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-26'; # DATE
our $DIST = 'WordLists-EN-Adverb'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Collection of English adverbs

__END__

=pod

=encoding UTF-8

=head1 NAME

WordLists::EN::Adverb - Collection of English adverbs

=head1 VERSION

This document describes version 0.003 of WordLists::EN::Adverb (from Perl distribution WordLists-EN-Adverb), released on 2021-09-26.

=head1 DESCRIPTION

This distribution contains the following wordlist modules:

=over

=item * L<WordList::EN::Adverb::TalkEnglish>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-EN-Adverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-EN-Adverb>.

=head1 SEE ALSO

L<TableDataBundle::Lingua::Word::EN::Adverb>

L<WordLists::EN::Noun>, L<WordLists::EN::Adjective>

L<WordList>

The wordlists can be used for games, e.g. L<Games::Hangman>, L<Games::TabNoun>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-EN-Adverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
