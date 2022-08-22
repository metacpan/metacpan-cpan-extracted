package WordList::Password::RockYou::BloomOnly;

use strict;
use warnings;
use parent qw(WordList);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'WordList-Password-RockYou-BloomOnly'; # DIST
our $VERSION = '0.003'; # VERSION

our $SORT = 'popularity';

our %STATS = (
    'num_words' => 14344391,
);

my $bloom;
sub word_exists {
    my ($self, $word) = @_;

    unless ($bloom) {
        require Algorithm::BloomFilter;
        require File::ShareDir;
        require File::Slurper;

        my $dir;
        eval {
            $dir = File::ShareDir::dist_dir('WordList-Password-RockYou-BloomOnly');
        };
        if ($@) {
            $dir = "share";
        }
        (-d $dir) or die "Can't find share dir".($@ ? ": $@" : "");
        my $path = "$dir/bloom";
        (-f $path) or die "Can't find bloom filter data file '$path'";
        $bloom = Algorithm::BloomFilter->deserialize(File::Slurper::read_binary($path));
    }
    $bloom->test($word);
}

1;
# ABSTRACT: RockYou password wordlist (~14.3mil passwords) (bloom-only edition)

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Password::RockYou::BloomOnly - RockYou password wordlist (~14.3mil passwords) (bloom-only edition)

=head1 VERSION

This document describes version 0.003 of WordList::Password::RockYou::BloomOnly (from Perl distribution WordList-Password-RockYou-BloomOnly), released on 2022-08-20.

=head1 DESCRIPTION

C<word_exists()> can be used to test a string against the RockYou password
wordlist (~14.3 million passwords). You can use it with, e.g.
L<App::PasswordWordListUtils>'s L<exists-in-password-wordlist>. Uses bloom
filter (bloom size=33M, k=13, false-positve rate=0.01245%).

The other methods like C<each_word()>, C<all_words()>, C<first_word()>,
C<next_word()> will return empty list of words, because this distribution only
contains the bloom filter and not the actual wordlist.

=head1 METHODS

=head2 word_exists

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Password-RockYou-BloomOnly>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Password-RockYou-BloomOnly>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Password-RockYou-BloomOnly>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
