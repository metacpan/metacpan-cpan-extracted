package WordListRole::WordList;

use Role::Tiny;

requires 'new';
requires 'each_word';
requires 'first_word';
requires 'next_word';
requires 'reset_iterator';
requires 'pick';
requires 'word_exists';
requires 'all_words';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-26'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.11'; # VERSION

1;
# ABSTRACT: The WordList methods

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::WordList - The WordList methods

=head1 VERSION

This document describes version 0.7.11 of WordListRole::WordList (from Perl distribution WordList), released on 2021-09-26.

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

This software is copyright (c) 2021, 2020, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
