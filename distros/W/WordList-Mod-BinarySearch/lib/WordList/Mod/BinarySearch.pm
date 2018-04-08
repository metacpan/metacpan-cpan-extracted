package WordList::Mod::BinarySearch;

our $DATE = '2018-04-02'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

our @patches = (
    ['word_exists', 'replace', sub {
         require File::SortedSeek;

         my ($self, $word) = @_;

         my $pkg = ref($self);

         my $dyn = ${"$pkg\::DYNAMIC"};
         die "Can't binary search on a dynamic wordlist" if $dyn;

         my $fh = \*{"$pkg\::DATA"};
         my $sort = ${"$pkg\::SORT"} || "";

         my $tell;
         if ($sort && $sort =~ /num/) {
             $tell = File::SortedSeek::numeric($fh, $word);
         } elsif (!$sort) {
             $tell = File::SortedSeek::alphabetic($fh, $word);
         } else {
             die "Wordlist is not ascibetically/numerically sort (sort=$sort)";
         }

         chomp(my $line = <$fh>);
         defined($line) && $line eq $word;
     }],
);

1;
# ABSTRACT: Provide word_exists() that uses binary search

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Mod::BinarySearch - Provide word_exists() that uses binary search

=head1 VERSION

This document describes version 0.001 of WordList::Mod::BinarySearch (from Perl distribution WordList-Mod-BinarySearch), released on 2018-04-02.

=head1 SYNOPSIS

 use WordList::Mod qw(get_mod_wordlist);
 my $wl = get_mod_wordlist("EN::Foo", "BinarySearch");
 say $wl->word_exists("foo"); # uses binary searching

=head1 DESCRIPTION

This mod provides an alternative C<word_exists()> method that performs binary
searching instead of the default linear.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Mod-BinarySearch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Mod-BinarySearch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Mod-BinarySearch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::SortedSeek>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
