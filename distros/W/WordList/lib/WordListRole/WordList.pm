package WordListRole::WordList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-28'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.7'; # VERSION

use Role::Tiny;

requires 'new';
requires 'each_word';
requires 'first_word';
requires 'next_word';
requires 'reset_iterator';
requires 'pick';
requires 'word_exists';
requires 'all_words';

1;
# ABSTRACT: The WordList methods

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::WordList - The WordList methods

=head1 VERSION

This document describes version 0.7.7 of WordListRole::WordList (from Perl distribution WordList), released on 2021-01-28.

=head1 REQUIRED METHODS

=head2 new

=head2 each_word

=head2 next_word

=head2 reset_iterator

=head2 pick

Usage:

 @words = $wl->pick([ $num=1 [ , $allow_duplicates=0 ] ]);

Examples:

 ($word) = $wl->pick;    # pick one item, note the list context
 ($word) = $wl->pick(1); # ditto
 @words  = $wl->pick(3);

=head2 word_exists

=head2 all_words

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
