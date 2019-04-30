# ----------------------------------------------------------------------
# NAME       : BibTeX/Name.pm
# CLASSES    : Text::BibTeX::Name
# RELATIONS  : 
# DESCRIPTION: Provides an object-oriented interface to the BibTeX-
#              style author names (parsing them, that is; formatting
#              them is done by the Text::BibTeX::NameFormat class).
# CREATED    : Nov 1997, Greg Ward
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This
#              library is free software; you may redistribute it and/or
#              modify it under the same terms as Perl itself.
# ----------------------------------------------------------------------

package Text::BibTeX::Name;

require 5.004;

use strict;
use Carp;
use vars qw'$VERSION';
$VERSION = 0.88;

use Text::BibTeX;

=encoding UTF-8

=head1 NAME

Text::BibTeX::Name - interface to BibTeX-style author names

=head1 SYNOPSIS

   use Text::BibTeX::Name;

   $name = Text::BibTeX::Name->new();
   $name->split('J. Random Hacker');
   # or:
   $name = Text::BibTeX::Name->new('J. Random Hacker');

   @firstname_tokens = $name->part ('first');
   $lastname = join (' ', $name->part ('last'));

   $format = Text::BibTeX::NameFormat->new();
   # ...customize $format...
   $formatted = $name->format ($format);

=head1 DESCRIPTION

C<Text::BibTeX::Name> provides an abstraction for BibTeX-style names and
some basic operations on them.  A name, in the BibTeX world, consists of
a list of I<tokens> which are divided amongst four I<parts>: `first',
`von', `last', and `jr'.

Tokens are separated by whitespace or commas at brace-level zero.  Thus
the name

   van der Graaf, Horace Q.

has five tokens, whereas the name

   {Foo, Bar, and Sons}

consists of a single token.  Skip down to L<"EXAMPLES"> for more examples, or
read on if you want to know the exact details of how names are split into
tokens and parts.

How tokens are divided into parts depends on the form of the name.  If
the name has no commas at brace-level zero (as in the second example),
then it is assumed to be in either "first last" or "first von last"
form.  If there are no tokens that start with a lower-case letter, then
"first last" form is assumed: the final token is the last name, and all
other tokens form the first name.  Otherwise, the earliest contiguous
sequence of tokens with initial lower-case letters is taken as the `von'
part; if this sequence includes the final token, then a warning is
printed and the final token is forced to be the `last' part.

If a name has a single comma, then it is assumed to be in "von last,
first" form.  A leading sequence of tokens with initial lower-case
letters, if any, forms the `von' part; tokens between the `von' and the
comma form the `last' part; tokens following the comma form the `first'
part.  Again, if there are no tokens following a leading sequence of
lowercase tokens, a warning is printed and the token immediately
preceding the comma is taken to be the `last' part.

If a name has more than two commas, a warning is printed and the name is
treated as though only the first two commas were present.

Finally, if a name has two commas, it is assumed to be in "von last, jr,
first" form.  (This is the only way to represent a name with a `jr'
part.)  The parsing of the name is the same as for a one-comma name,
except that tokens between the two commas are taken to be the `jr' part.

=head1 CAVEAT

The C code that does the actual work of splitting up names takes a shortcut
and makes few assumptions about whitespace.  In particular, there must be
no leading whitespace, no trailing whitespace, no consecutive whitespace
characters in the string, and no whitespace characters other than space.
In other words, all whitespace must consist of lone internal spaces.

=head1 EXAMPLES

The strings C<"John Smith"> and C<"Smith, John"> are different
representations of the same name, so split into parts and tokens the
same way, namely as:

   first => ('John')
   von   => ()
   last  => ('Smith')
   jr    => ()

Note that every part is a list of tokens, even if there is only one
token in that part; empty parts get empty token lists.  Every token is
just a string.  Writing this example in actual code is simple:

   $name = Text::BibTeX::Name->new("John Smith");  # or "Smith, John"
   $name->part ('first');       # returns list ("John")
   $name->part ('last');        # returns list ("Smith")
   $name->part ('von');         # returns list ()
   $name->part ('jr');          # returns list ()

(We'll omit the empty parts in the rest of the examples: just assume
that any unmentioned part is an empty list.)  If more than two tokens
are included and there's no comma, they'll go to the first name: thus
C<"John Q. Smith"> splits into

   first => ("John", "Q."))
   last  => ("Smith")

and C<"J. R. R. Tolkein"> into

   first => ("J.", "R.", "R.")
   last  => ("Tolkein")

The ambiguous name C<"Kevin Philips Bong"> splits into

   first => ("Kevin", "Philips")
   last  => ("Bong")

which may or may not be the right thing, depending on the particular
person.  There's no way to know though, so if this fellow's last name is
"Philips Bong" and not "Bong", the string representation of his name
must disambiguate.  One possibility is C<"Philips Bong, Kevin"> which
splits into

   first => ("Kevin")
   last  => ("Philips", "Bong")

Alternately, C<"Kevin {Philips Bong}"> takes advantage of the fact that
tokes are only split on whitespace I<at brace-level zero>, and becomes

   first => ("Kevin")
   last  => ("{Philips Bong}")

which is fine if your names are destined to be processed by TeX, but
might be problematic in other contexts.  Similarly, C<"St John-Mollusc,
Oliver"> becomes

   first => ("Oliver")
   last  => ("St", "John-Mollusc")

which can also be written as C<"Oliver {St John-Mollusc}">:

   first => ("Oliver")
   last  => ("{St John-Mollusc}")

Since tokens are separated purely by whitespace, hyphenated names will
work either way: both C<"Nigel Incubator-Jones"> and C<"Incubator-Jones,
Nigel"> come out as

   first => ("Nigel")
   last  => ("Incubator-Jones")

Multi-token last names with lowercase components -- the "von part" --
work fine: both C<"Ludwig van Beethoven"> and C<"van Beethoven, Ludwig">
parse (correctly) into

   first => ("Ludwig")
   von   => ("van")
   last  => ("Beethoven")

This allows these European aristocratic names to sort properly,
i.e. I<van Beethoven> under I<B> rather than I<v>.  Speaking of
aristocratic European names, C<"Charles Louis Xavier Joseph de la
Vall{\'e}e Poussin"> is handled just fine, and splits into

   first => ("Charles", "Louis", "Xavier", "Joseph")
   von   => ("de", "la")
   last  => ("Vall{\'e}e", "Poussin")

so could be sorted under I<V> rather than I<d>.  (Note that the sorting
algorithm in L<Text::BibTeX::BibSort> is a slavish imitiation of BibTeX
0.99, and therefore does the wrong thing with these names: the sort key
starts with the "von" part.)

However, capitalized "von parts" don't work so well: C<"R. J. Van de
Graaff"> splits into

   first => ("R.", "J.", "Van")
   von   => ("de")
   last  => ("Graaff")

which is clearly wrong.  This name should be represented as C<"Van de
Graaff, R. J.">

   first => ("R.", "J.")
   last  => ("Van", "de", "Graaff")

which is probably right.  (This particular Van de Graaff was an
American, so he probably belongs under I<V> -- which is where my
(British) dictionary puts him.  Other Van de Graaff's mileages may
vary.)

Finally, many names include a suffix: "Jr.", "III", "fils", and so
forth.  These are handled, but with some limitations.  If there's a
comma before the suffix (the usual U.S. convention for "Jr."), then the
name should be in I<last, jr, first> form, e.g. C<"Doe, Jr., John">
comes out (correctly) as

   first => ("John")
   last  => ("Doe")
   jr    => ("Jr.")

but C<"John Doe, Jr."> is ambiguous and is parsed as

   first => ("Jr.")
   last  => ("John", "Doe")

(so don't do it that way).  If there's no comma before the suffix -- the
usual for Roman numerals, and occasionally seen with "Jr." -- then
you're stuck and have to make the suffix part of the last name.  Thus,
C<"Gates III, William H."> comes out

   first => ("William", "H.")
   last  => ("Gates", "III")

but C<"William H. Gates III"> is ambiguous, and becomes

   first => ("William", "H.", "Gates")
   last  => ("III")

-- not what you want.  Again, the curly-brace trick comes in handy, so
C<"William H. {Gates III}"> splits into

   first => ("William", "H.")
   last  => ("{Gates III}")

There is no way to make a comma-less suffix the C<jr> part.  (This is an
unfortunate consequence of slavishly imitating BibTeX 0.99.)

Finally, names that aren't really names of people but rather are
organization or company names should be forced into a single token by
wrapping them in curly braces.  For example, "Foo, Bar and Sons" should
be written C<"{Foo, Bar and Sons}">, which will split as

   last  => ("{Foo, Bar and Sons}")

Of course, if this is one name in a BibTeX C<authors> or C<editors>
list, this name has to be wrapped in braces anyways (because of the C<"
and ">), but that's another story.

=head1 FORMATTING NAMES

Putting a split-up name back together again in a flexible, customizable
way is the job of another module: see L<Text::BibTeX::NameFormat>.

=head1 METHODS

=over 4

=item new([ [OPTS,] NAME [, FILENAME, LINE, NAME_NUM]])

Creates a new C<Text::BibTeX::Name> object.  If NAME is supplied, it
must be a string containing a single name, and it will be be passed to
the C<split> method for further processing.  FILENAME, LINE, and
NAME_NUM, if present, are all also passed to C<split> to allow better
error messages.

If the first argument is a hash reference, it is used to define
configuration values. At the moment the available values are:

=over 4 

=item BINMODE

Set the way Text::BibTeX deals with strings. By default it manages
strings as bytes. You can set BINMODE to 'utf-8' to get NFC normalized
UTF-8 strings and you can customise the normalization with the NORMALIZATION option.

   Text::BibTeX::Name->new(
      { binmode => 'utf-8', normalization => 'NFD' },
      "Alberto Simões"});

=back

=cut

sub new {
    my $class = shift;
    my $opts = ref $_[0] eq 'HASH' ? shift : {};

    $opts->{ lc $_ } = $opts->{$_} for ( keys %$opts );

    my ( $name, $filename, $line, $name_num ) = @_;

    $class = ref($class) || $class;
    my $self = bless { }, $class;

    $self->{binmode} = 'bytes';
    $self->{normalization} = 'NFC';
    $self->{binmode} = 'utf-8'
        if exists $opts->{binmode} && $opts->{binmode} =~ /utf-?8/i;
    $self->{normalization} = $opts->{normalization} if exists $opts->{normalization};

    $self->split( Text::BibTeX->_process_argument($name, $self->{binmode}, $self->{normalization}),
        $filename, $line, $name_num, 1 )
        if ( defined $name );
    $self;
}


sub DESTROY
{
   my $self = shift;
   $self->free;                         # free the C structure kept by `split'
}


=item split (NAME [, FILENAME, LINE, NAME_NUM])

Splits NAME (a string containing a single name) into tokens and
subsequently into the four parts of a BibTeX-style name (first, von,
last, and jr).  (Each part is a list of tokens, and tokens are separated
by whitespace or commas at brace-depth zero.  See above for full details
on how a name is split into its component parts.)

The token-lists that make up each part of the name are then stored in
the C<Text::BibTeX::Name> object for later retrieval or formatting with
the C<part> and C<format> methods.

=cut

sub split
{
   my ($self, $name, $filename, $line, $name_num) = @_;

   # Call the XSUB with default values if necessary
   $self->_split (Text::BibTeX->_process_argument($name, $self->{binmode}, $self->{normalization}), $filename, 
                  defined $line ? $line : -1,
                  defined $name_num ? $name_num : -1,
                  1);
}


=item part (PARTNAME)

Returns the list of tokens in part PARTNAME of a name previously split with
C<split>.  For example, suppose a C<Text::BibTeX::Name> object is created and
initialized like this:

   $name = Text::BibTeX::Name->new();
   $name->split ('Charles Louis Xavier Joseph de la Vall{\'e}e Poussin');

Then this code:

   $name->part ('von');

would return the list C<('de','la')>.

=cut

sub part {
    my ( $self, $partname ) = @_;

    croak "unknown name part"
        unless $partname =~ /^(first|von|last|jr)$/;

    if ( exists $self->{$partname} ) {
        my @x = map { Text::BibTeX->_process_result($_, $self->{binmode}, $self->{normalization}) }
            @{ $self->{$partname} };
        return @x > 1 ? @x : $x[0];
    }
    return undef;
}


=item format (FORMAT)

Formats a name according to the specifications encoded in FORMAT, which
should be a C<Text::BibTeX::NameFormat> (or descendant) object.  (In short,
it must supply a method C<apply> which takes a C<Text::BibTeX::NameFormat>
object as its only argument.)  Returns the formatted name as a string.

See L<Text::BibTeX::NameFormat> for full details on formatting names.

=cut

sub format
{
   my ($self, $format) = @_;

   $format->apply ($self);
}

1;

=back

=head1 SEE ALSO

L<Text::BibTeX::Entry>, L<Text::BibTeX::NameFormat>, L<bt_split_names>.

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
