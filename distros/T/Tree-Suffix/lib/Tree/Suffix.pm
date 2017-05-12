package Tree::Suffix;

use strict;
use warnings;

use XSLoader;

our $VERSION = '0.22';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

1;

__END__

=head1 NAME

Tree::Suffix - Perl interface to the libstree library.

=head1 SYNOPSIS

    use Tree::Suffix;

    $tree = Tree::Suffix->new;
    $tree = Tree::Suffix->new(@strings);

    $bool = $tree->allow_duplicates($bool);

    $count = $tree->insert(@strings);
    $count = $tree->remove(@strings);

    $count = $tree->find($string);
    $count = $tree->match($string);
    $count = $tree->search($string);
    @pos = $tree->find($string);
    @pos = $tree->match($string);
    @pos = $tree->search($string);

    $string = $tree->string($id);
    $string = $tree->string($id, $start ,$end);

    @lcs = $tree->lcs;
    @lcs = $tree->lcs($min_len, $max_len);
    @lcs = $tree->longest_common_substrings;

    @lrs = $tree->lrs;
    @lrs = $tree->lrs($min_len, $max_len);
    @lrs = $tree->longest_repeated_substrings;

    $count = $tree->strings;
    @pos = $tree->strings;

    $count = $tree->nodes;

    $tree->clear;
    $tree->dump;

=head1 DESCRIPTION

The C<Tree::Suffix> module provides an interface to the C library libstree,
which implements generic suffix trees.

NOTICE: as libstree has outstanding bugs and has long been abandoned, this
distribution is not being maintained.

=head1 METHODS

=over

=item $tree = Tree::Suffix->B<new>

=item $tree = Tree::Suffix->B<new>(@strings)

Creates a new Tree::Suffix object. The constructor will accept a list of
strings to be inserted into the tree.

=item $tree->B<allow_duplicates>($bool)

Determines whether duplicate strings are permitted in the tree.  By default,
duplicates are allowed.  Note, this must be called before strings are inserted
for it to have an effect.  Returns the value of the flag.

=item $tree->B<insert>(@strings)

Inserts the list of strings into the tree, excluding duplicates if they are
not allowed.  Returns the number of successfull insertions.

=item $tree->B<remove>(@strings)

Remove the list of strings from the tree, including duplicates if they are
allowed.  Returns the number of successful removals.

=item $tree->B<find>($string)

=item $tree->B<match>($string)

=item $tree->B<search>($string)

In scalar context, returns the number of occurrences of the substring in the
tree.  In list context, returns the positions of all occurrences of the given
string as a list of array references in the form [string_index, start, end].

=item $tree->B<string>($string_index)

=item $tree->B<string>($string_index, $start)

=item $tree->B<string>($string_index, $start, $end)

Returns the string at index_id.  The start and end positions may be specified
to return a substring.

=item $tree->B<lcs>

=item $tree->B<lcs>($min_len, $max_len)

=item $tree->B<longest_common_substrings>

Returns a list of the longest common substrings. The minimum and maximum
length of the considered substrings may be specified.

=item $tree->B<lrs>

=item $tree->B<lrs>($min_len, $max_len)

=item $tree->B<longest_repeated_substrings>

Returns a list of the longest repeated substrings. The minimum and maximum
length of the considered substrings may be specified.

=item $tree->B<strings>

In scalar context, returns the total number of strings in the tree.  In list
context, returns the list of string indexes.

=item $tree->B<nodes>

Returns the total number of nodes in the tree.

=item $tree->B<clear>

Removes all strings from the tree.

=item $tree->B<dump>

Prints a representation of the tree to STDOUT.

=back

=head1 EXAMPLE

To find the longest palindrome of a string:

    use Tree::Suffix;
    $str   = 'mississippi';
    $tree  = Tree::Suffix->new($str, scalar reverse $str);
    ($pal) = $tree->lcs;
    print "Longest palindrome: $pal\n";

This would print:

    Longest palindrome: ississi

=head1 SEE ALSO

libstree L<http://www.icir.org/christian/libstree/>

L<SuffixTree>

L<http://en.wikipedia.org/wiki/Suffix_tree>

=head1 NOTES

A memory leak will be exhibited if you are using a version of libstree < .4.2.

=head1 REQUESTS AND BUGS

When reporting a bug, first verify that you can successfully run the tests in
the libstree distribution.

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Tree-Suffix>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Suffix

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/tree-suffix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Suffix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Suffix>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Dist=Tree-Suffix>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Suffix>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
