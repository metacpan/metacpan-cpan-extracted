package WordList::Phrase::EN::Quote::JamesFT;

use strict;
use parent 'WordList';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-01'; # DATE
our $DIST = 'WordList-Phrase-EN-Quote-JamesFT'; # DIST
our $VERSION = '0.002'; # VERSION

our %STATS = ("shortest_word_len",35,"num_words_contain_whitespace",5421,"num_words_contains_unicode",11,"num_words_contain_unicode",11,"num_words_contains_nonword_chars",5421,"avg_word_len",97.3894115476849,"longest_word_len",236,"num_words_contains_whitespace",5421,"num_words",5421,"num_words_contain_nonword_chars",5421); # STATS

our $DYNAMIC=1;
our $SORT = 'custom';

sub new {
    require TableData::Quote::JamesFT;

    my $class = shift;
    my $self = $class->SUPER::new;
    $self->{_table} = TableData::Quote::JamesFT->new;
    $self;
}

sub next_word {
    my $self = shift;
    return unless $self->{_table}->has_next_row;
    my $row = $self->{_table}->get_next_row_arrayref;
    qq("$row->[0]" -- $row->[1]);
}

sub reset_iterator {
    my $self = shift;
    $self->{_table}->reset_iterator;
}

1;
# ABSTRACT: Famous quotes from JamesFT github repository

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::EN::Quote::JamesFT - Famous quotes from JamesFT github repository

=head1 VERSION

This document describes version 0.002 of WordList::Phrase::EN::Quote::JamesFT (from Perl distribution WordList-Phrase-EN-Quote-JamesFT), released on 2023-12-01.

=head1 SYNOPSIS

 use WordList::Phrase::EN::Quote::JamesFT;

 my $wl = WordList::Phrase::EN::Quote::JamesFT->new;

 # Pick a (or several) random word(s) from the list
 my ($word) = $wl->pick;
 my ($word) = $wl->pick(1);  # ditto
 my @words  = $wl->pick(3);  # no duplicates

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }  # case-sensitive

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words (beware, some wordlists are *huge*)
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

This wordlist contains list of quotes, which is retrieved from
L<Tables::Quotes::JamesFT>, which in turn is retrieved from
L<https://github.com/JamesFT/Database-Quotes-JSON>.

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 97.3894115476849 |
 | longest_word_len                 | 236              |
 | num_words                        | 5421             |
 | num_words_contain_nonword_chars  | 5421             |
 | num_words_contain_unicode        | 11               |
 | num_words_contain_whitespace     | 5421             |
 | num_words_contains_nonword_chars | 5421             |
 | num_words_contains_unicode       | 11               |
 | num_words_contains_whitespace    | 5421             |
 | shortest_word_len                | 35               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-EN-Quote-JamesFT>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-EN-Quote-JamesFT>.

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-EN-Quote-JamesFT>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
