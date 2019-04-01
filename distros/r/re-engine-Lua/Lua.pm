package re::engine::Lua;
use strict;
use warnings;
use 5.010;
use XSLoader;

BEGIN {
    # All engines should subclass the core Regexp package
    our @ISA = qw( Regexp );

    our $VERSION = '0.19';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub import {
    $^H{regcomp} = ENGINE;
    return;
}

sub unimport {
    delete $^H{regcomp}
      if $^H{regcomp} == ENGINE;
    return;
}

1;

__END__

=head1 NAME

re::engine::Lua - Lua regular expression engine

=for html
<a href="http://cpants.charsbar.org/dist/overview/re-engine-Lua"><img alt="Kwalitee Status" src="http://cpants.cpanauthors.org/dist/re-engine-Lua.png" /></a>
<a href="LICENSE"><img alt="Licence" src="http://img.shields.io/badge/Licence-MIT-brightgreen.svg" /></a>

=head1 SYNOPSIS

    use re::engine::Lua;

    if ('Hello, world' =~ /Hello, (world)/) {
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

Replaces perl's regex engine in a given lexical scope with the Lua 5.3 one.

See "Lua 5.3 Reference Manual", section 6.4.1 "Patterns",
L<http://www.lua.org/manual/5.3/manual.html#6.4.1>.

=head2 Character Class:

A I<character class> is used to represent a set of characters. The following
combinations are allowed in describing a character class:

=over 4

=item B<x>

(where I<x> is not one of the I<magic characters> C<^$()%.[]*+-?>) represents
the character I<x> itself.

=item B<.>

(a dot) represents all characters.

=item B<%a>

represents all letters.

=item B<%c>

represents all control characters.

=item B<%d>

represents all digits.

=item B<%g>

represents all printable characters except space.

=item B<%l>

represents all lowercase letters.

=item B<%p>

represents all punctuation characters.

=item B<%s>

represents all space characters.

=item B<%u>

represents all uppercase letters.

=item B<%w>

represents all alphanumeric characters.

=item B<%x>

represents all hexadecimal digits.

=item B<%z> DEPRECATED

represents the character with representation 0.

=item B<%x>

(where I<x> is any non-alphanumeric character) represents the character I<x>.
This is the standard way to escape the magic characters. Any punctuation
character (even the non magic) can be preceded by a C<'%'> when used to
represent itself in a pattern.

=item B<[set]>

represents the class which is the union of all characters in I<set>. A range of
characters can be specified by separating the end characters of the range, in
ascending order, with a C<'-'>. All classes C<%x> described above can also be
used as components in I<set>. All other characters in I<set> represent themselves.
For example, C<[%w_]> (or C<[_%w]>) represents all alphanumeric characters plus the
underscore, C<[0-7]> represents the octal digits, and C<[0-7%l%-]> represents
the octal digits plus the lowercase letters plus the C<'-'> character.

The interaction between ranges and classes is not defined. Therefore, patterns
like C<[%a-z]> or C<[a-%%]> have no meaning.

=item B<[^set]>

represents the complement of I<set>, where I<set> is interpreted as above.

=back

For all classes represented by single letters (C<%a>, C<%c>, etc.), the
corresponding uppercase letter represents the complement of the class. For
instance, C<%S> represents all non-space characters.

The definitions of letter, space, and other character groups depend on the
current locale. In particular, the class C<[a-z]> may not be equivalent to
C<%l>.

=head2 Pattern Item:

A I<pattern item> can be

=over 4

=item *

a single character class, which matches any single character in the class;

=item *

a single character class followed by C<'*'>, which matches 0 or more
repetitions of characters in the class. These repetition items will always
match the longest possible sequence;

=item *

a single character class followed by C<'+'>, which matches 1 or more
repetitions of characters in the class. These repetition items will always
match the longest possible sequence;

=item *

a single character class followed by C<'-'>, which also matches 0 or more
repetitions of characters in the class. Unlike C<'*'>, these repetition items
will always match the I<shortest> possible sequence;

=item *

a single character class followed by C<'?'>, which matches 0 or 1
occurrence of a character in the class;

=item *

C<%n>, for I<n> between 1 and 9; such item matches a substring equal to
the i<n>-th captured string (see below);

=item *

C<%bxy>, where I<x> and I<y> are two distinct characters; such item
matches strings that start with I<x>, end with I<y>, and where the I<x> and
I<y> are I<balanced>. This means that, if one reads the string from left to
right, counting I<+1> for an I<x> and I<-1> for a I<y>, the ending I<y> is the
first I<y> where the count reaches 0. For instance, the item C<%b()> matches
expressions with balanced parentheses.

=item *

C<%f[set]>, a I<frontier pattern>; such item matches an empty string at any
position such that the next character belongs to I<set> and the previous
character does not belong to I<set>. The set I<set> is interpreted as
previously described. The beginning and the end of the subject are handled
as if they were the character '\0'.

=back

=head2 Pattern:

A I<pattern> is a sequence of pattern items. A caret C<'^'> at the beginning
of a pattern anchors the match at the beginning of the subject string.
A C<'$'> at the end of a pattern anchors the match at the end of the subject string.
At other positions, C<'^'> and C<'$'> have no special meaning and represent
themselves.

=head2 Captures:

A pattern can contain sub-patterns enclosed in parentheses; they describe
I<captures>. When a match succeeds, the substrings of the subject string that
match captures are stored (I<captured>) for future use. Captures are numbered
according to their left parentheses. For instance, in the pattern
C<"(a*(.)%w(%s*))">, the part of the string matching C<"a*(.)%w(%s*)"> is
stored as the first capture (and therefore has number 1); the character
matching C<"."> is captured with number 2, and the part matching C<"%s*"> has
number 3.

As a special case, the empty capture C<()> captures the current string
position (a number). For instance, if we apply the pattern C<"()aa()"> on the
string C<"flaaap">, there will be two captures: 3 and 5.
 NOT SUPPORTED BY re::engine::Lua, the two captures are empty string,
 the position are available in @- and @+ as usually.

=head1 AUTHOR

FranE<ccedil>ois PERRAD <francois.perrad@gadz.org>

=head1 HOMEPAGE

The development is hosted at L<https://framagit.org/perrad/re-engine-lua>.

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2019 FranE<ccedil>ois PERRAD.

This program is free software; you can redistribute it and/or modify it
under the same terms as Lua.

The code fragment from original Lua 5.3.3 is under a MIT license,
see L<http://www.lua.org/license.html>.

=cut

