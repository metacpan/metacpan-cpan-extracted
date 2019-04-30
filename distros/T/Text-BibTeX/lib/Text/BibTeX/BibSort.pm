# ----------------------------------------------------------------------
# NAME       : BibSort.pm
# CLASSES    : Text::BibTeX::BibSort
# RELATIONS  : sub-class of StructuredEntry
#              super-class of BibEntry
# DESCRIPTION: Provides methods for generating sort keys of entries
#              in a BibTeX-style bibliographic database.
# CREATED    : 1997/11/24, GPW (taken from Bib.pm)
# MODIFIED   : 
# VERSION    : $Id$
# COPYRIGHT  : Copyright (c) 1997-2000 by Gregory P. Ward.  All rights 
#              reserved.
# 
#              This file is part of the Text::BibTeX library.  This is free
#              software; you can redistribute it and/or modify it under the
#              same terms as Perl itself.
# ----------------------------------------------------------------------

package Text::BibTeX::BibSort;
use strict;
use vars qw(@ISA $VERSION);

use Text::BibTeX::Structure;

@ISA = qw(Text::BibTeX::StructuredEntry);
$VERSION = 0.88;

use Text::BibTeX qw(purify_string change_case);

use Carp;

=head1 NAME

Text::BibTeX::BibSort - generate sort keys for bibliographic entries

=head1 SYNOPSIS

   # Assuming $entry comes from a database of the 'Bib' structure
   # (i.e., that it's blessed into the BibEntry class, which inherits
   # the sort_key method from BibSort):
   $sort_key = $entry->sort_key;

=head1 DESCRIPTION

C<Text::BibTeX::BibSort> is a base class of C<Text::BibTeX::BibEntry>
for generating sort keys from bibliography entries.  It could in
principle (and, someday, might) offer a wide range of highly
customizable sort-key generators.  Currently, though, it provides only a
single method (C<sort_key>) for public use, and that method only pays
attention to one structure option, C<sortby>.

=head1 METHODS

=over 4

=item sort_key ()

Generates a sort key for a single bibliographic entry.  Assumes this
entry conforms to the C<Bib> database structure.  The nature of this
sort key is controlled by the C<sortby> option, which can be either
C<"name"> or C<"year">.  (The C<namestyle> also has a role, in
determining how author/editor names are formatted for inclusion in the
sort key.)

For by-name sorting (which is how BibTeX's standard styles work), the sort
key consists of one of the C<author>, C<editor>, C<organization>, or C<key>
fields (depending on the entry type and which fields are actually present),
followed by the year and the title.  All fields are drastically simplified
to produce the sort key: non-English letters are mercilessly anglicized,
non-alphabetic characters are stripped, and everything is forced to
lowercase.  (The first two steps are done by the C<purify_string> routine;
see L<Text::BibTeX/"Generic string-processing functions"> for a brief
description, and the description of the C function C<bt_purify_string()> in
L<bt_misc> for all the gory details.)

=cut

# methods for sorting -- everything here is geared towards generating
# a sort key; it's up to external code to actually order entries (since,
# of course, a single entry doesn't know anything about any other 
# entries!)

# also, we assume that an entry has been checked and coerced into
# shape -- that way we don't need to check for defined-ness of
# strings, or check the type, or anything.

sub sort_key
{
   my $self = shift;
   my ($sortby, $type, $nkey, $skey);

   $sortby = $self->structure->get_options ('sortby');
   croak ("BibSort::sort_key: sortby option is 'none'")
      if $sortby eq 'none';
   croak ("BibSort::sort_key: unknown sortby option '$sortby'")
      unless $sortby eq 'name' || $sortby eq 'year';

   $type = $self->type;

   if ($type eq 'book' || $type eq 'inbook')
   {
      $nkey = $self->format_alt_fields ('author' => 'sort_format_names',
                                        'editor' => 'sort_format_names',
                                        'key'    => 'sortify');
   }
   elsif ($type eq 'proceedings')
   {
      $nkey = $self->format_alt_fields ('editor' => 'sort_format_names',
                                        'organization' => 'sort_format_org',
                                        'key'    => 'sortify');
   }
   elsif ($type eq 'manual')
   {
      $nkey = $self->format_alt_fields ('author' => 'sort_format_names',
                                        'organization' => 'sort_format_org',
                                        'key'    => 'sortify');
   }
   else
   {
      $nkey = $self->format_alt_fields ('author' => 'sort_format_names',
                                        'key'    => 'sortify');
   }

   my $ykey = change_case ('l', (purify_string ($self->get ('year'))));
   $skey = ($sortby eq 'name') 
      ? $nkey . '    ' . $ykey
      : $ykey . '    ' . $nkey;
   $skey .= '    ' . $self->sort_format_title ('title');
   return $skey;

}  # sort_key


sub sortify
{
   my ($self, $field) = @_;
   return lc (purify_string ($self->get ($field)));
}


sub sort_format_names
{
   require Text::BibTeX::Name;
   require Text::BibTeX::NameFormat;

   my ($self, $field) = @_;
   my ($abbrev, $format, $name);

   $abbrev = ! ($self->structure->get_options ('namestyle') eq 'full');
   $format =  Text::BibTeX::NameFormat->new ("vljf", $abbrev);
   $name   = Text::BibTeX::Name->new;

   my (@snames, $i, $sname);
   @snames = $self->split ($field);
   for $i (0 .. $#snames)
   {
      $sname = $snames[$i];
      if ($sname eq 'others')           # hmmm... should we only do this on
      {                                 # the final name?
         $sname = 'et al';              # purified version of "et. al."
      }
      else
      {
         # A spot of ugliness here:
         #   - lc (purify_string (x)) ought to be sortify (x), but I have
         #     already made sortify a method that only operates on a field,
         #     rather than a generic function (as it is in BibTeX)
         
         $name->split ($sname, $self->filename, $self->line ($field), $i+1);
         $sname = $name->format ($format);
#         print "s_f_n: about to purify >$sname<\n";
         $snames[$i] = lc (purify_string ($sname));
      }
   }
   return join ('   ', @snames);
}



# sort_format_org and sort_format_title are suspiciously similar...
# could probably have one method to handle both tasks...

sub sort_format_org
{
   my ($self, $field) = @_;

   my $value = $self->get ($field);
   $value =~ s/^the\b\s*//i;
   return lc (purify_string ($value));
}


sub sort_format_title
{
   my ($self, $field) = @_;

   my $value = $self->get ($field);
   $value =~ s/^(the|an?)\b\s*//i;
   return lc (purify_string ($value));
}


# Hmm, I suspect format_alt_fields is a little more general purpose --
# probably belongs outside of the "generate sort key" methods.
# (Or.... does it maybe belong in one of the base classes, StructuredEntry
# or even Entry?)

sub format_alt_fields
{
   my $self = shift;
   my ($field, $method);

   while (@_)
   {
      ($field, $method) = (shift, shift);
      if ($self->exists ($field))
      {
         $method = $self->can ($method)
            || croak ("unknown method in class " . (ref $self));
         return &$method ($self, $field);
      }
   }

   return undef;                        # whoops, none of the alternate fields
                                        # were present
}

1;

=back

=head1 SEE ALSO

L<Text::BibTeX::Structure>, L<Text::BibTeX::Bib>,
L<Text::BibTeX::BibFormat>

=head1 AUTHOR

Greg Ward <gward@python.net>

=head1 COPYRIGHT

Copyright (c) 1997-2000 by Gregory P. Ward.  All rights reserved.  This file
is part of the Text::BibTeX library.  This library is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.
