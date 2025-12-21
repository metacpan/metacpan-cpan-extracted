package WordListBundle::ID::ByCategory;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-14'; # DATE
our $DIST = 'WordListBundle-ID-ByCategory'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Collection of Indonesian words of various categories

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListBundle::ID::ByCategory - Collection of Indonesian words of various categories

=head1 VERSION

This document describes version 0.001 of WordListBundle::ID::ByCategory (from Perl distribution WordListBundle-ID-ByCategory), released on 2025-01-14.

=head1 DESCRIPTION

This distribution contains the following wordlist modules:

=over

=item 1. L<WordList::ID::ByCategory::Animal>

=item 2. L<WordList::ID::ByCategory::Bird>

=item 3. L<WordList::ID::ByCategory::Flower>

=item 4. L<WordList::ID::ByCategory::Food>

=item 5. L<WordList::ID::ByCategory::Fruit>

=item 6. L<WordList::ID::ByCategory::Insect>

=item 7. L<WordList::ID::ByCategory::MusicalInstrument>

=item 8. L<WordList::ID::ByCategory::Vegetable>

=item 9. L<WordList::ID::ByCategory::WaterAnimal>

=back

They can be used to aid in creating flash cards or for supplying words in word
guessing games.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListBundle-ID-ByCategory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListBundle-ID-ByCategory>.

=head1 SEE ALSO

L<TableDataBundle::Lingua::Word::ID::ByCategory>

L<WordListBundle::EN::ByCategory>

L<WordList>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListBundle-ID-ByCategory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
