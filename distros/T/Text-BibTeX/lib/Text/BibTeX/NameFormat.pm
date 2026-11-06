# ----------------------------------------------------------------------
# NAME       : BibTeX/NameFormat.pm
# CLASSES    : Text::BibTeX::NameFormat
# RELATIONS  : 
# DESCRIPTION: Provides a way to format already-parsed BibTeX-style
#              author names.  (The parsing is done by the 
#              Text::BibTeX:Name class.)
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

package Text::BibTeX::NameFormat;

use 5.026;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

=head1 NAME

Text::BibTeX::NameFormat - format BibTeX-style author names

=head1 SYNOPSIS

   use Text::BibTeX::NameFormat;

   $format = Text::BibTeX::NameFormat->($parts, $abbrev_first);

   $format->set_text ($part,
                      $pre_part, $post_part,
                      $pre_token, $post_token);

   $format->set_options ($part, $abbrev, $join_tokens, $join_part

   ## Uses the encoding/binmode and normalization form stored in $name
   $formatted_name = $format->apply ($name);

=head1 DESCRIPTION

After splitting a name into its components parts (represented as a
C<Text::BibTeX::Name> object), you often want to put it back together
again as a single string formatted in a consistent way.
C<Text::BibTeX::NameFormat> provides a very flexible way to do this,
generally in two stages: first, you create a "name format" which
describes how to put the tokens and parts of any name back together, and
then you apply the format to a particular name.

The "name format" is encapsulated in a C<Text::BibTeX::NameFormat>
object.  The constructor (C<new>) includes some clever behind-the-scenes
trickery that means you can usually get away with calling it alone, and
not need to do any customization of the format object.  If you do need
to customize the format, though, the C<set_text()> and C<set_options()>
methods provide that capability.

=head1 CONSTANTS

Two sets of constants are used with name formats.  The "name part"
constants name the four "parts" of a BibTeX name: C<BTN_FIRST>,
C<BTN_VON>, C<BTN_LAST>, and C<BTN_JR>.  The "join method" constants
are the ways in which adjacent tokens can be joined together:
C<BTJ_MAYTIE>, C<BTJ_SPACE>, C<BTJ_FORCETIE>, and C<BTJ_NOTHING> (see
L</"FORMATTING RULES">).  Both sets of values may be
imported from the C<Text::BibTeX> module, using the import tags
C<nameparts> and C<joinmethods>.  For instance:

   use Text::BibTeX qw(:nameparts :joinmethods);
   use Text::BibTeX::Name;
   use Text::BibTeX::NameFormat;

The "name part" constants are used to specify surrounding text or
formatting options on a per-part basis: for instance, you can supply the
"pre-token" text, or the "abbreviate" flag, for a single part without
affecting other parts.  The "join methods" are two of the three
formatting options that you can set for a part: you can control how to
join the individual tokens of a name (C<"JR Smith">, or C<"J R Smith">,
or C<"J~R Smith">, and you can control how the final token of one part
is joined to the next part (C<"la Roche"> versus C<"la~Roche">).

=head1 FORMATTING RULES

A name format controls the following:

=over 4

=item *

which name parts are printed, and in what order (e.g. "first von last
jr", or "von last jr first")

=item *

the text that precedes and follows each part (e.g. if the first name
follows the last name, you probably want a comma before the `first'
part: "Smith, John" rather than "Smith John")

=item *

the text that precedes and follows each token (e.g. if the first name is
abbreviated, you may want a period after each token: "J. R. Smith"
rather than "J R Smith")

=item *

whether the tokens of each part are abbreviated

=item *

the method used to join the tokens of each part together

=item *

the method used to join each part to the following part

=back

There are I<two> join methods for each part: one between the tokens
within the part, and one between the part and the next part.  The first
allows you, for example, to change C<"J R Smith"> (first name
abbreviated with no post-token text but tokens joined by a space) to
C<"JR Smith"> (the same, but first-name tokens jammed together).  The
second is mainly used to ensure that `von' and `last' parts may be
joined with a tie: C<"de~Roche"> rather than C<"de Roche">.

The join methods are:

=over 4

=item C<BTJ_MAYTIE>

Insert a "discretionary tie" between tokens: either a space or a "tie"
is inserted, depending on context.  (A tie, otherwise known as an
unbreakable space, is always C<"~">, as in TeX.)

=item C<BTJ_SPACE>

Always insert a space between tokens.

=item C<BTJ_FORCETIE>

Always insert a tie (C<"~">) between tokens.

=item C<BTJ_NOTHING>

Insert nothing between tokens---just jam them together.

=back

With C<BTJ_MAYTIE>, the choice between a space and a tie follows BibTeX.
Within a part, a tie is used after the first token if it is less than
three characters long, and before the last token.  Between parts, a tie
is used only if the preceding part consists of a single token less than
three characters long.  In all other cases, a space is used.

=head2 Defaults

C<new> sets up the whole format, based on the PARTS and ABBREV_FIRST
arguments, so that customization is rarely needed:

=over 4

=item *

The token join method is C<BTJ_MAYTIE> for all parts.

=item *

The part join method is C<BTJ_SPACE> for the `first', `last', and `jr'
parts.  If the `von' part immediately precedes the `last' part (which
will almost always be the case), C<BTJ_MAYTIE> is used to join `von' to
`last'; otherwise `von' also gets C<BTJ_SPACE>.

=item *

The `von', `last', and `jr' parts are not abbreviated; the `first' part
is abbreviated if ABBREV_FIRST is true.

=item *

All the surrounding text starts out empty.  If ABBREV_FIRST is true, the
post-token text for the first name is C<".">, which changes
C<"J R Smith"> to C<"J. R. Smith">.

If `jr' immediately follows `last' (almost always the case), the
pre-part text for `jr' is C<", "> and the part join method for `last' is
C<BTJ_NOTHING>, so you get C<"John Smith, Jr">.  Because the C<", "> is
associated with the `jr' part, it is not printed when there is no `jr'
part.

Likewise, if `first' immediately follows `jr' or `last' (as in
"last name first" formats), the pre-part text for `first' is C<", ">
and the part join method of the preceding part is C<BTJ_NOTHING>.

=back

So if you only need C<"fvlj"> and C<"vljf"> part orders, only want to
abbreviate the first name, and want periods after abbreviated tokens,
ties in the "right" places and commas in the conventional places, you
don't need to customize anything.  For something out of the
ordinary---for instance, abbreviated tokens jammed together with no
punctuation, or abbreviated last names---use C<set_text> and
C<set_options>.

=head1 METHODS

=over 4

=item new(PARTS, ABBREV_FIRST)

Creates a new name format, with the two most common customizations: which
parts to include (and in what order), and whether to abbreviate the first
name.  PARTS should be a string with at most four characters, one representing
each part that you want to occur in a formatted name (defaults to C<"fvlj">).
For example, C<"fvlj"> means to format names in "first von last jr" order,
while C<"vljf"> denotes "von last jr first."  ABBREV_FIRST is just a boolean
value: false to print out the first name in full, and true to abbreviate it
with periods after each token and discretionary ties between tokens (defaults
to false).  All intra- and inter-token punctuation and spacing is independently
controllable with the C<set_text> and C<set_options> methods, although these
will rarely be necessary---sensible defaults are chosen for everything, based
on the PARTS and ABBREV_FIRST values that you supply.  See L</Defaults>
for full details of the choices made.

=cut

sub new
{
   my ($class, $parts, $abbrev_first) = @_;

   $parts ||= "fvlj";
   $abbrev_first = defined($abbrev_first)? $abbrev_first : 0;

   croak "invalid name format \"$parts\"" unless $parts =~ /^[fvlj]{1,4}$/;

   $class = ref ($class) || $class;
   my $self = bless {}, $class;
   $self->{_cstruct} = create ($parts, $abbrev_first);
   $self;
}


sub DESTROY
{
   # the C structure is freed with its Perl wrapper
}


=item set_text (PART, PRE_PART, POST_PART, PRE_TOKEN, POST_TOKEN)

Allows you to customize some or all of the surrounding text for a single
name part.  Every name part has four possible chunks of text that go
around or within it: before/after the part as a whole, and before/after
each token in the part.  For instance, if you are abbreviating first
names and wish to control the punctuation after each token in the first
name, you would set the "post token" text:

   $format->set_text ('first', undef, undef, undef, '');

would set the post-token text to the empty string, resulting in names
like C<"J R Smith">.  (Normally, abbreviated first names will have a
period after each token: C<"J. R. Smith">.)  Note that supplying
C<undef> for the other three values leaves them unchanged.

See L</"FORMATTING RULES"> for full information on formatting names.

=cut

sub set_text
{
   my ($self, $part, $pre_part, $post_part, $pre_token, $post_token) = @_;

   # The C code keeps its own copies of these strings
   _set_text ($self->{'_cstruct'},
              $part,
              $pre_part,
              $post_part,
              $pre_token,
              $post_token);
   1;
}


=item set_options (PART, ABBREV, JOIN_TOKENS, JOIN_PART)

Allows further customization of a name format: you can set the
abbreviation flag and the two token-join methods.  Alas, there is no
mechanism for leaving a value unchanged; you must set everything with
C<set_options>.

For example, let's say that just dropping periods from abbreviated
tokens in the first name isn't enough; you I<really> want to save
space by jamming the abbreviated tokens together: C<"JR Smith"> rather
than C<"J R Smith">  Assuming the two calls in the above example have
been done, the following will finish the job:

   $format->set_options (BTN_FIRST,
                         1,             # keep same value for abbrev flag
                         BTJ_NOTHING,   # jam tokens together
                         BTJ_SPACE);    # space after final token of part

Note that we unfortunately had to know (and supply) the current values
for the abbreviation flag and post-part join method, even though we were
only setting the intra-part join method.

=cut

sub set_options
{
   my ($self, $part, $abbrev, $join_tokens, $join_part) = @_;

   _set_options ($self->{'_cstruct'}, $part,
                 $abbrev, $join_tokens, $join_part);
   1;
}


=item apply (NAME)

Once a name format has been created and customized to your heart's
content, you can use it to format any number of names using the C<apply>
method.  NAME must be a C<Text::BibTeX::Name> object (i.e., a pre-split
name); C<apply> returns a string containing the parts of the name
formatted according to the C<Text::BibTeX::NameFormat> structure it is
called on.

=cut

sub apply
{
   my ($self, $name) = @_;

   my $name_struct = $name->{'_cstruct'} ||
      croak "invalid Name object: no C structure";
   my $format_struct = $self->{'_cstruct'} ||
      croak "invalid NameFormat object: no C structure";
   my $utf8 = ($name->{binmode} // 'utf-8') eq 'utf-8';
   my $ans = format_name ($name_struct, $format_struct, $utf8 ? 1 : 0);
   return $utf8 ? Text::BibTeX::_normalise($name->{normalization} // 'NFC', $ans) : $ans;
}

=back

=head1 EXAMPLES

Although the process of splitting and formatting names may sound
complicated and convoluted from reading the above (along with
L<Text::BibTeX::Name>), it's actually quite simple.  There are really
only three steps to worry about: split the name (create a
C<Text::BibTeX::Name> object), create and customize the format
(C<Text::BibTeX::NameFormat> object), and apply the format to the name.

The first step is covered in L<Text::BibTeX::Name>; here's a brief
example:

   $orig_name = 'Charles Louis Xavier Joseph de la Vall{\'e}e Poussin';
   $name = Text::BibTeX::Name->new($orig_name);

The various parts of the name can now be accessed through
C<Text::BibTeX::Name> methods; for instance C<$name-E<gt>part('von')>
returns the list C<("de","la")>.

Creating the name format is equally simple:

   $format = Text::BibTeX::NameFormat->new('vljf', 1);

creates a format that will print the name in "von last jr first" order,
with the first name abbreviated.  And for no extra charge, you get the
right punctuation at the right place: a comma before any `jr' or `first'
tokens, and periods after each `first' token.

For instance, we can perform no further customization on this format,
and apply it immediately to C<$name>.  There are in fact two ways to do
this, depending on whether you prefer to think of it in terms of
"Applying the format to a name" or "formatting a name".  The first is
done with C<Text::BibTeX::NameFormat>'s C<apply> method:

   $formatted_name = $format->apply ($name);

while the second uses C<Text::BibTeX::Name>'s C<format> method:

   $formatted_name = $name->format ($format);

which is just a wrapper around C<Text::BibTeX::NameFormat::apply>.  In
either case, the result with the example name and format shown is

   de~la Vall{\'e}e~Poussin, C.~L. X.~J.

Note the strategic insertion of TeX "ties" (non-breakable spaces) at
sensitive spots in the name.  (The exact rules for insertion of
discretionary ties are given in L</"FORMATTING RULES">.)

=head1 SEE ALSO

L<Text::BibTeX::Entry>, L<Text::BibTeX::Name>.

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;

