package WordListRole::BinarySearch;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-23'; # DATE
our $DIST = 'WordListRole-BinarySearch'; # DIST
our $VERSION = '0.004'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Role::Tiny;

sub word_exists {
    no strict 'refs'; # this is required because Role::Tiny forces full stricture

    require File::SortedSeek;

    my ($self, $word) = @_;

    my $class = $self->{orig_class} // ref($self);

    my $dyn = ${"$class\::DYNAMIC"};
    die "Can't binary search on a dynamic wordlist" if $dyn;

    my $fh = \*{"$class\::DATA"};
    my $sort = ${"$class\::SORT"} || "";

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
}

1;
# ABSTRACT: Provide word_exists() that uses binary search

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::BinarySearch - Provide word_exists() that uses binary search

=head1 VERSION

This document describes version 0.004 of WordListRole::BinarySearch (from Perl distribution WordListRole-BinarySearch), released on 2020-05-23.

=head1 SYNOPSIS

 use Role::Tiny;
 use WordList::EN::Enable;
 my $wl = WordList::EN::Enable->new;
 Role::Tiny->apply_roles_to_object($wl, "WordListRole::BinarySearch");

=head1 DESCRIPTION

This role provides an alternative C<word_exists()> method that performs binary
searching instead of the default linear. The list must be sorted numerically
(C<$SORT> is C<num> or C<numeric>) or alphabetically (C<$SORT> is empty).

=head1 PROVIDED METHODS

=head2 word_exists

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListRole-BinarySearch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListRole-BinarySearch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListRole-BinarySearch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::SortedSeek>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
