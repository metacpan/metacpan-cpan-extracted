package WordList::Mod::Bloom;

our $DATE = '2018-04-02'; # DATE
our $VERSION = '0.002'; # VERSION

our @patches = (
    ['word_exists', 'replace', sub {
         require MIME::Base64;

         my ($self, $word) = @_;

         my $pkg = ref($self);

         my $dyn = ${"$pkg\::DYNAMIC"};
         die "Can't use bloom filter on a dynamic wordlist" if $dyn;

         my $bloom = ${"$pkg\::BLOOM_FILTER"};

         unless ($bloom) {
             (my $wl_subpkg = $pkg) =~ s/\AWordList:://;
             my $bloom_pkg = "WordList::Bloom::$wl_subpkg";
             (my $bloom_pkg_pm = "$bloom_pkg.pm") =~ s!::!/!g;
             require $bloom_pkg_pm;

             my $fh = \*{"$bloom_pkg\::DATA"};
             my $bloom_str = do {
                 local $/;
                 MIME::Base64::decode_base64(<$fh>);
             };

             require Algorithm::BloomFilter;
             ${"$pkg\::BLOOM_FILTER"} = $bloom =
                 Algorithm::BloomFilter->deserialize($bloom_str);
         }

         $bloom->test($word);
     }],
);

1;
# ABSTRACT: Provide word_exists() that uses bloom filter

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Mod::Bloom - Provide word_exists() that uses bloom filter

=head1 VERSION

This document describes version 0.002 of WordList::Mod::Bloom (from Perl distribution WordList-Mod-Bloom), released on 2018-04-02.

=head1 SYNOPSIS

In your F<WordList/EN/Foo.pm>:

 package WordList::EN::Foo;

 __DATA__
 word1
 word2
 ...

In your F<WordList/Bloom/EN/Foo.pm>:

 package WordList::Bloom::EN::Foo;
 1;
 __DATA__
 (The actual bloom filter, base64-encoded)

Then:

 use WordList::Mod qw(get_mod_wordlist);
 my $wl = get_mod_wordlist("EN::Foo", "Bloom");

 $wl->word_exists("foo"); # uses bloom filter to check for existence.

=head1 DESCRIPTION

EXPERIMENTAL.

This mod provides an alternative C<word_exists()> method that checks a bloom
filter located in the data section of C<<
WordList::Bloom::<Your_WordList_Subpackage> >>. This provides a low
startup-overhead way to check an item against a big list (e.g. millions). Note
that testing using a bloom filter can result in a false positive (i.e.
C<word_exists()> returns true but the word is not actually in the list.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Mod-Bloom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Mod-Bloom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Mod-Bloom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
