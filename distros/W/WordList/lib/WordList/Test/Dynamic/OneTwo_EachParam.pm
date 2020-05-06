package WordList::Test::Dynamic::OneTwo_EachParam;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.6.0'; # VERSION

use strict;

use WordList::Test::Dynamic::OneTwo_Each;
our @ISA = qw(WordList::Test::Dynamic::OneTwo_Each);

use Role::Tiny::With;
with 'WordListRole::FirstNextResetFromEach';

our $DYNAMIC = 1;

our %PARAMS = (
    foo => {
        summary => 'Just a dummy, required parameter',
        schema => 'str*',
        req => 1,
    },
);

1;
# ABSTRACT: Wordlist that returns one, two (via implementing each_word())

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Dynamic::OneTwo_EachParam - Wordlist that returns one, two (via implementing each_word())

=head1 VERSION

This document describes version 0.6.0 of WordList::Test::Dynamic::OneTwo_EachParam (from Perl distribution WordList), released on 2020-05-04.

=head1 SYNOPSIS

 use WordList::Test::Dynamic::OneTwo_EachParam;

 my $wl = WordList::Test::Dynamic::OneTwo_EachParam->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

Just like L<WordList::Test::Dynamic::OneTwo_Each>, except it accepts a required
parameter (C<foo>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
