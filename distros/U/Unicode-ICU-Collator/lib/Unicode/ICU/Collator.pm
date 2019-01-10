package Unicode::ICU::Collator;
use strict;
use Exporter qw(import);

BEGIN {
  our $VERSION = '0.003';
  use XSLoader;
  XSLoader::load('Unicode::ICU::Collator' => $VERSION);
}

{
  my @loc_constants =
    qw(ULOC_ACTUAL_LOCALE ULOC_VALID_LOCALE);
  my @attr_constants =
    (
     qw(UCOL_FRENCH_COLLATION UCOL_ALTERNATE_HANDLING UCOL_CASE_FIRST
	UCOL_CASE_LEVEL UCOL_NORMALIZATION_MODE UCOL_DECOMPOSITION_MODE
	UCOL_STRENGTH UCOL_HIRAGANA_QUATERNARY_MODE UCOL_NUMERIC_COLLATION),
     qw(UCOL_DEFAULT UCOL_PRIMARY UCOL_SECONDARY UCOL_TERTIARY
	UCOL_DEFAULT_STRENGTH UCOL_CE_STRENGTH_LIMIT UCOL_QUATERNARY
	UCOL_IDENTICAL UCOL_STRENGTH_LIMIT UCOL_OFF UCOL_ON UCOL_SHIFTED
	UCOL_NON_IGNORABLE UCOL_LOWER_FIRST UCOL_UPPER_FIRST)
     );
  my @rule_constants =
    qw(UCOL_TAILORING_ONLY UCOL_FULL_RULES);
    
  our %EXPORT_TAGS =
    (
     locale => \@loc_constants,
     attributes => \@attr_constants,
     rules => \@rule_constants,
     constants => [ @loc_constants, @attr_constants, @rule_constants ],
    );


  our @EXPORT_OK = map @$_, values %EXPORT_TAGS;
}

sub sort {
  my $self = shift;
  return map $_->[1],
    sort { $a->[0] cmp $b->[0] }
      map [ $self->getSortKey($_), $_ ], @_;
}

sub CLONE_SKIP { 1 }

sub AUTOLOAD {
  our $AUTOLOAD;

  (my $constname = $AUTOLOAD) =~ s/.*:://;
  my ($error, $val) = constant($constname);
  if ($error) {
    require Carp;
    Carp::croak($error);
  }

  {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  }

  goto &$AUTOLOAD;
}

# everything else is XS
1;

__END__

=head1 NAME

Unicode::ICU::Collator - wrapper around ICU collation services

=head1 SYNOPSIS

  use Unicode::ICU::Collator;
  my $coll = Unicode::ICU::Collator->new($locale);

  # name of the locale actually selected
  print $coll->getLocale;

  # sort according to locale
  my @sorted = $coll->sort(@unsorted);

  # comparisons
  my @sorted = sort {
    $coll->cmp($a->name, $b->name)
  } @unsorted;

  # build sort keys
  my @sorted = map $_->[1],
    sort { $a->[0] cmp $b->[0] }
      map [ $coll->getSortKey($_->name), $_ ], @unsorted;

  # get the display name of a collation locale
  print Unicode::ICU::Collator->getDisplayName("de__phonebook", "en");
  # German (PHONEBOOK)
  print Unicode::ICU::Collator->getDisplayName("de__phonebook", "de");
  # Deutsch (PHONEBOOK)

=head1 DESCRIPTION

Unicode::ICU::Collator is a thin (and currently incomplete) wrapper
around ICU's collation functions.

=head1 CLASS METHODS

=over

=item new($locale)

Create a new collation object for the specified locale.

  my $coll = Unicode::ICU::Collator->new("en");
  my $coll_de = Unicode::ICU::Collator->new("de_phonebook");

=item available()

Return a list of the available collation locale names.

  my @locales = Unicode::ICU::Collator->available;

=item getDisplayName($locale, $display_locale)

Return a descriptive name of the locale C<$locale> for display in
locale C<$display_locale>.

  # probably "English"
  my $en_en = Unicode::ICU::Collator->getDisplayName("en", "en");
  # "German"
  my $de_en = Unicode::ICU::Collator->getDisplayName("de", "en");
  # "Deutsch"
  my $de_de = Unicode::ICU::Collator->getDisplayName("de", "de");
  # "Deutsch (PHONEBOOK)"
  my $deph_de = Unicode::ICU::Collator->getDisplayName("de__phonebook", "de");

=back

=head1 INSTANCE METHODS

=over

=item cmp($str1, $str2)

Compare two strings per the collation selected, returning -1, 0, or 1
as per perl's C<cmp>.

  my $cmp = $coll->cmp($str1, $str2);
  my @sorted = sort { $coll->cmp($a, $b) } @unsorted;

=item eq($str1, $str2)

=item ne($str1, $str2)

=item lt($str1, $str2)

=item gt($str1, $str2)

=item le($str1, $str2)

=item ge($str1, $str2)

Compare the strings lexically within the collation, returning true or
false.

=item getSortKey($str)

Returns a binary string suitable for use with perl's built-in string
comparison operators such as cmp, for comparing the source strings.

  my @sorted = map $_->[1],
    sort { $a->[0] cmp $b->[0] }
      map [ $coll->getSortKey($_->name), $_ ], @unsorted;

=item sort(@list)

Return the contents of C<@list> (which can be any list, not just an
array) sorted per the collation.

Currently this is a simply perl code wrapper around C<getSortKey()>
but that may change.

  my @sorted = $coll->sort(@unsorted);

=item getLocale()

=item getLocale($type)

Return the locale used as the source of the collation, the most
specific collation name known or the collation name supplied to new,
depending on C<$type>.

C<$type> is one of the following constants, as exported by the
C<:locale> export tag:

=over

=item *

ULOC_ACTUAL_LOCALE - the actual locale being used.  eg. if you supply
C<"en_US"> to new, this will probably return C<"en">.  If C<$type> is
not provided, this is the default.

=item *

ULOC_VALID_LOCALE - the most specific locale supported by ICU.

=back

  my $name = $coll->getLocale();
  use Unicode::ICU::Collator ':locale';
  my $name = $coll->getLocale(ULOC_VALID_LOCALE());

Previously you could supply C<ULOC_REQUESTED_LOCALE> to get the locale
name supplied to C<new()>, but this was deprecated in ICU and current
versions of ICU return an error, so I've removed it.

=item setAttribute($attr, $value)

Set an attribute for the collation.

Constants for C<$attr> and C<$value> are exported by the
C<:attributes> tag.

Please see the documentation of C<UColAttribute> type in the ICU
documentation for details.

  $coll->setAttribute(UCOL_NUMERIC_COLLATION(), UCOL_ON());

=item getAttribute($attr)

Return the value of a collation attribute.

  my $value = $coll->getAttribute(UCOL_NUMERIC_COLLATION());

=item getRules()

=item getRules($type)

Retrieve the collation rules used by this collator.

Note: this is typically a long string for C<UCOL_FULL_RULES>, and
probably isn't very useful.

Values for C<$type> are:

=over

=item *

UCOL_FULL_RULES - the full set of rules for the collation.  This is the default.

=item *

UCOL_TAILORING_ONLY - only the rule tailoring.

=back

=item getVersion()

Return version information for the collator as a dotted decimal
string.

=item getUCAVersion()

Return the UCA version information for a collator.

=back

=head1 LICENSE

Unicode::ICU::Collator is licensed under the same terms as Perl itself.

=head1 SEE ALSO

http://site.icu-project.org/

http://userguide.icu-project.org/collation

http://icu-project.org/apiref/icu4c/ucol_8h.html

L<Unicode::Collate>

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut


