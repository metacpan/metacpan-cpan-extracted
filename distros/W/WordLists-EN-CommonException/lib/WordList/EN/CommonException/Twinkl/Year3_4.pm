package WordList::EN::CommonException::Twinkl::Year3_4;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-07-01'; # DATE
our $DIST = 'WordLists-EN-CommonException'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our $SORT = 'custom';

our %STATS = ("avg_word_len",7.10185185185185,"num_words_contain_unicode",0,"num_words_contains_whitespace",0,"num_words",108,"num_words_contain_whitespace",0,"shortest_word_len",4,"num_words_contains_unicode",0,"longest_word_len",12,"num_words_contain_nonword_chars",0,"num_words_contains_nonword_chars",0); # STATS

1;
# ABSTRACT: Common exception words (years 3 & 4) from twinkl.co.uk

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::CommonException::Twinkl::Year3_4 - Common exception words (years 3 & 4) from twinkl.co.uk

=head1 VERSION

This document describes version 0.001 of WordList::EN::CommonException::Twinkl::Year3_4 (from Perl distribution WordLists-EN-CommonException), released on 2020-07-01.

=head1 SYNOPSIS

 use WordList::EN::CommonException::Twinkl::Year3_4;

 my $wl = WordList::EN::CommonException::Twinkl::Year3_4->new;

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

Source: L<https://twink.co.uk/>

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 7.10185185185185 |
 | longest_word_len                 | 12               |
 | num_words                        | 108              |
 | num_words_contain_nonword_chars  | 0                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 0                |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 4                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-EN-CommonException>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-EN-CommonException>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-EN-CommonException>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
accident
accidentally
actual
actually
address
although
answer
appear
arrive
believe
bicycle
breath
breathe
build
busy
business
calendar
caught
centre
century
certain
circle
complete
consider
continue
decide
describe
different
difficult
disappear
early
earth
eight
eighth
enough
exercise
experience
extreme
famous
favorite
February
forward
forwards
fruit
grammar
group
guard
guide
heard
heart
height
history
imagine
increase
important
interest
island
knowledge
learn
length
library
material
medicine
mention
minute
natural
naughty
notice
occasion
occasionally
often
opposite
ordinary
particular
peculiar
perhaps
popular
position
possess
possession
possible
potatoes
pressure
probably
promise
purpose
quarter
question
recent
regular
reign
remember
sentence
separate
special
straight
strange
strength
suppose
surprise
therefore
though
thought
through
various
weight
woman
women
