package WordList::Password::RockYou::BloomOnly;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordList-Password-RockYou-BloomOnly'; # DIST
our $VERSION = '0.002'; # VERSION

use parent qw(WordList);

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
            $dir = dist_dir('WordList-Password-RockYou-BloomOnly');
        };
        if ($@) {
            $dir = "share";
        }
        (-d $dir) or die "Can't find share dir";
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

This document describes version 0.002 of WordList::Password::RockYou::BloomOnly (from Perl distribution WordList-Password-RockYou-BloomOnly), released on 2020-05-24.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Password-RockYou-BloomOnly>

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
