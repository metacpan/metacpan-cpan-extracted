=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Tie::Plural - Select a string variant based on a quantity.

=head1 VERSION

This documentation describes version 0.01 of Plural.pm, January 07, 2005.

=cut

use strict;
package Tie::Plural;
$Tie::Plural::VERSION = '0.01';
use Carp;

# If exporting symbols:
use Exporter;
use vars qw/@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %pl/;
@ISA         = qw/Exporter/;
@EXPORT      = qw/%pl/;
@EXPORT_OK   = qw/plural/;
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

tie %pl, 'Tie::Plural';

sub plural ($;$$$)
{
    my ($num, $plural, $sing, $zero) = @_;

    defined or $_ = ''      for $sing;
    defined or $_ = 's'     for $plural;
    defined or $_ = $plural for $zero;

    my $s = $num==0? $zero : $num==1? $sing : $plural;
    return $s;
}

sub TIEHASH
{
    my $class = shift;
    my $dummy;  # not used;
    bless \$dummy, $class;
}

sub FETCH
{
    my $self = shift;
    my $key  = shift;

    my ($n, $p, $s, $z) = split $;, $key;
    return plural ($n, $p, $s, $z);
}


1;
__END__

=head1 SYNOPSIS

 $var = $pl{$num};
 $var = $pl{$num, $plural};
 $var = $pl{$num, $plural, $singular};
 $var = $pl{$num, $plural, $singular, $zero};

 $var = plural($num);
 $var = plural($num, $plural);
 $var = plural($num, $plural, $singular);
 $var = plural($num, $plural, $singular, $zero);

=head1 DESCRIPTION

This module provides a simple way to pluralize words within strings.
More precisely, it provides a way to select a string from a number of
choices based on a quantity.  This is accomplished by a tied hash, so
it is very easy to incorporate these choices into output strings,
which is generally where you need them.

=head1 VARIABLES

=over 4

=item %pl

 $variant = $pl{$number, $plural_form, $singular_form, $zero_form};

Based on C<$number>, returns one of C<$plural_form>, C<$singular_form>, or
C<$zero_form>.  If C<$number> is 0, C<$zero_form> is returned.  If C<$number>
is 1, C<$singular_form> is returned.  Otherwise, C<$plural_form> is returned.

Only C<$number> is required.  C<$plural_form> defaults to 's'.
C<$singular_form> defaults to '' (the empty string).  C<$zero_form> defaults
to whatever C<$plural_form> is.

=back

=head1 FUNCTIONS

=over 4

=item plural

 $variant = plural($number, $plural_form, $singular_form, $zero_form);

Based on C<$number>, returns one of the other arguments.  Works the same
as the C<%pl> tied-hash does.

This function is not exported by default.

=back

=head1 EXAMPLES

 for $num (0..3)
 {
     print "I have $num dog$pl{$num}.\n";
 }
# The above prints:
  I have 0 dogs.
  I have 1 dog.
  I have 2 dogs.
  I have 3 dogs.

 $num = 700;
 print "My wife owns $pl{$num,'many','one','no'} dress$pl{$num,'es'}.";
#
 "My wife owns many dresses."

=head1 EXPORTS

The variable C<%pl> is exported by default.  The function C<plural> is
available for export.  The tag C<:all> will export all available
symbols into your namespace.

=head1 SEE ALSO

Damian Conway's excellent L<Lingua::EN::Inflect> provides a much more
full-featured way to produce plural forms automagically.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.2.6 (Cygwin)

iD8DBQFB3wZ/Y96i4h5M0egRAvNyAKD5Ta0kDxh+x2qG5/nwBDpEXXjq+ACeLQ7O
Y9T9NXAUcsEIZfXRoF7/Pw4=
=FSBN
-----END PGP SIGNATURE-----

=end gpg
