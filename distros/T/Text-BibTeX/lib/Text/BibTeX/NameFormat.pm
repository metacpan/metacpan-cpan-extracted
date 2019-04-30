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

require 5.004;

use strict;
use Carp;
use vars qw'$VERSION';
$VERSION = 0.88;

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

Note that C<Text::BibTeX::NameFormat> is a fairly direct translation of
the name-formatting C interface in the B<btparse> library.  This manual
page is meant to provide enough information to use the Perl class, but
for more details and examples, consult L<bt_format_names>.

=head1 CONSTANTS

Two enumerated types for dealing with names and name formatting have
been brought from C into Perl.  In the B<btparse> documentation, you'll
see references to C<bt_namepart> and C<bt_joinmethod>.  The former lists
the four "parts" of a BibTeX name: first, von, last, and jr; its values
(in both C and Perl) are C<BTN_FIRST>, C<BTN_VON>, C<BTN_LAST>, and
C<BTN_JR>.  The latter lists the ways in which C<bt_format_name()> (the
C function that corresponds to C<Text::BibTeX::NameFormat>'s C<apply>
method) can join adjacent tokens together: C<BTJ_MAYTIE>, C<BTJ_SPACE>,
C<BTJ_FORCETIE>, and C<BTJ_NOTHING>.  Both sets of values may be
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
on the PARTS and ABBREV_FIRST values that you supply.  See the description of
C<bt_create_name_format()> in L<bt_format_names> for full details of the
choices made.

=cut

sub new
{
   my ($class, $parts, $abbrev_first) = @_;

   $parts ||= "fvlj";
   $abbrev_first = defined($abbrev_first)? $abbrev_first : 0;

   die unless $parts =~ /^[fvlj]{1,4}$/;

   $class = ref ($class) || $class;
   my $self = bless {}, $class;
   $self->{_cstruct} = create ($parts, $abbrev_first);
   $self;
}


sub DESTROY
{
   my $self = shift;
   free ($self->{'_cstruct'}) 
      if defined $self->{'_cstruct'};
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

See L<bt_format_names> for full information on formatting names.

=cut

sub set_text
{
   my ($self, $part, $pre_part, $post_part, $pre_token, $post_token) = @_;

   # Engage in a little conspiracy with the XS code (_set_text) and the
   # underlying C function (bt_set_format_text) here.  In particular,
   # neither of those functions copy the strings we pass in here -- they
   # just copy the C pointers.  Ultimately, those refer back to the Perl
   # strings that we're passing in now.  Thus, if those Perl strings
   # were to go away (ref count drop to zero), then the C code might
   # have dangling pointers to free'd strings -- oops!  The solution is
   # to keep references of those Perl strings here, so that their ref
   # count can never drop to zero without our assent.  Every time
   # set_text is called, the old references are overridden (ref count
   # drops), and when the NameFormat object is destroyed, we destroy
   # them (ref count drops).  Other than that, there will always be some
   # reference to the strings passed in to set_text.

   # XXX what if some of these are undef?

   $self->{'textrefs'} = [\$pre_part, \$post_part, \$pre_token, \$post_token];

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
 
   my $ans = format_name ($name_struct, $format_struct);

   $ans = Text::BibTeX->_process_result($ans, $name->{binmode}, $name->{normalization});
   
   return $ans;
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
discretionary ties are given in L<bt_format_names>.)

=head1 SEE ALSO

L<Text::BibTeX::Entry>, L<Text::BibTeX::Name>, L<bt_format_names>.

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;

