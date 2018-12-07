package Unicruft;

use 5.008004;
use strict;
use warnings;
use Carp;
use AutoLoader;
use Exporter;
#use Encode;  ##-- slower than pack/unpack!

our @ISA = qw(Exporter);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Unicruft', $VERSION);

# Preloaded methods go here.
#require Unicruft::Whatever;

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Exports
##======================================================================
our (%EXPORT_TAGS, @EXPORT_OK, @EXPORT);
BEGIN {
  %EXPORT_TAGS =
    (
     std  => [qw(latin1_to_utf8 utf8_to_ascii utf8_to_latin1 utf8_to_latin1_de utf8_to_utf8_de)],
     guts => [qw(ux_latin1_to_utf8 ux_utf8_to_ascii ux_utf8_to_latin1 ux_utf8_to_latin1_de),
	      qw(ux_latin1_bytes ux_utf8_bytes),
	     ],
    );
  $EXPORT_TAGS{all} = [@{$EXPORT_TAGS{std}}, @{$EXPORT_TAGS{guts}}];
  @EXPORT_OK        = @{$EXPORT_TAGS{all}};
  @EXPORT           = qw();
}

##======================================================================
## Constants
##======================================================================

##======================================================================
## Utils
##======================================================================

## $u8bytes = ux_utf8_bytes($str)
##  + returns UTF-8 byte-string encoded version of $str; respects perl UTF-8 flag
sub ux_utf8_bytes {
  return utf8::is_utf8($_[0]) ? pack('C0C*',unpack('U0C*',$_[0])) : $_[0];
}

## $l1bytes = ux_latin1_bytes($str)
##  + returns Latin-1 byte-string encoded version of $str; respects perl UTF-8 flag
sub ux_latin1_bytes {
  return utf8::is_utf8($_[0]) ? pack('C0C*',unpack('U0U*',$_[0])) : $_[0];
}

##======================================================================
## Wrappers
##======================================================================

## $u8str = latin1_to_utf8($l1str)
sub latin1_to_utf8 {
  ux_latin1_to_utf8(ux_latin1_bytes($_[0]));
}

## $astr = utf8_to_ascii($u8str)
sub utf8_to_ascii {
  ux_utf8_to_ascii(ux_utf8_bytes($_[0]));
}

## $l1str = utf8_to_latin1($u8str)
sub utf8_to_latin1 {
  ux_utf8_to_latin1(ux_utf8_bytes($_[0]));
}

## $destr = utf8_to_latin1_de($u8str)
sub utf8_to_latin1_de {
  ux_utf8_to_latin1_de(ux_utf8_bytes($_[0]));
}

## $destr = utf8_to_utf8_de($u8str)
sub utf8_to_utf8_de {
  utf8::upgrade(my $s = ux_utf8_to_latin1_de(ux_utf8_bytes($_[0])));
  return $s;
}

##======================================================================
## Exports: finish
##======================================================================


1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Unicruft - Perl interface to the unicruft transliteration library

=head1 SYNOPSIS

 use Unicruft;
 
 $libversion = Unicruft::library_version();
 
 $u8str = Unicruft::latin1_to_utf8($l1str);
 $astr  = Unicruft::utf8_to_ascii($u8str);
 $l1str = Unicruft::utf8_to_latin1($u8str);
 $l1str = Unicruft::utf8_to_latin1_de($u8str);
 $u8str = Unicruft::utf8_to_utf8_de($u8str);

=head1 DESCRIPTION

The perl Unicruft package provides a perl interface to the
libunicruft library, which is itself derived in part from
the Text::Unidecode perl module.

=head2 EXPORTS

Nothing is exported by default, but
the Unicruft module support the following export tags:

=over 4

=item :std

Standard conversion functions (those without a "ux_" prefix)

=item :guts

Low-level conversion functions (those with a "ux_" prefix).

=item :all

All conversion functions exported by :std and :guts.

=back


=head2 HIGH-LEVEL CONVERSION FUNCTIONS

=head3 library_version

Returns the version string of the unicruft C library against which
this perl module was compiled.

=head3 latin1_to_utf8

 $u8str = Unicruft::latin1_to_utf8($l1str);

Converts the Latin-1 (ISO-8859-1) string $l1str to UTF-8.
This task is better accomplished either with perl's utf8::upgrade() function
or the perl Encode module; it is included here only for completeness' sake.

$l1str may be either a byte-string or a perl-native UTF-8 string (i.e. a scalar with the SvUTF8 flag set).
The returned string $u8str will have its UTF-8 flag set.

=head3 utf8_to_ascii

 $astr  = Unicruft::utf8_to_ascii($u8str);

Approximate the UTF-8 string $u8str as 7-bit ASCII.
This is basically just a (fast) re-implementation of Text::Unidecode::unidecode($u8str).

$u8str may be either a byte-string (assumed to contain a valid UTF-8 byte sequence)
or a perl-native UTF-8 string (i.e. a scalar with the SvUTF8 flag set).
The returned string $astr will have its UTF-8 flag cleared
(although this is pretty arbitrary here, since 7-bit ASCII is also valid UTF-8).

=head3 utf8_to_latin1

 $l1str = Unicruft::utf8_to_latin1($u8str);

Approximate the UTF-8 string $u8str as 8-bit Latin-1 (ISO-8859-1).

$u8str may be either a byte-string (assumed to contain a valid UTF-8 byte sequence)
or a perl-native UTF-8 string (i.e. a scalar with the SvUTF8 flag set).
The returned string $l1str will have its UTF-8 flag cleared.

=head3 utf8_to_latin1_de

 $l1str = Unicruft::utf8_to_latin1_de($u8str);

Approximate the UTF-8 string $u8str as 8-bit Latin-1 (ISO-8859-1) using only
characters which occur in contemporary German orthography.

$u8str may be either a byte-string (assumed to contain a valid UTF-8 byte sequence)
or a perl-native UTF-8 string (i.e. a scalar with the SvUTF8 flag set).
The returned string $l1str will have its UTF-8 flag cleared.

=head3 utf8_to_utf8_de

 $u8str = Unicruft::utf8_to_utf8_de($u8str);

Approximate the UTF-8 string $u8str as 8-bit-safe UTF-8 using only
characters which occur in contemporary German orthography.  Really just a wrapper for:

 utf8::upgrade(my $s = Unicruft::utf8_to_latin1_de($u8str));
 return $s;

=head2 LOW-LEVEL UTILITY FUNCTIONS

The following functions are available, but not expected to be
of much use to the casual user.

=head3 ux_latin1_bytes

 $bytes = ux_latin1_bytes($string);

Returns an latin-1 encoded byte string representing its argument.
Respects perl UTF-8 flag.

=head3 ux_utf8_bytes

 $bytes = ux_latin1_bytes($string);

Returns an UTF-8 encoded byte string representing its argument.
Respects perl UTF-8 flag.


=head2 LOW-LEVEL CONVERSION FUNCTIONS

For each conversion function C<X_to_Y>, there is an underlying
C<ux_X_to_Y> function which places stricter requirements on its
argument string (potentially downgrading it to a byte-string),
but which is slightly faster since no copying or perl-level
conditionals are required.

=head3 ux_latin1_to_utf8

Like L<latin1_to_utf8()|/latin1_to_utf8>, but requires its argument to be a Latin-1-encoded byte string.

=head3 ux_utf8_to_ascii

Like L<utf8_to_ascii()|/utf8_to_ascii>, but requires its argument to be a UTF-8-encoded byte string.

=head3 ux_utf8_to_latin1

Like L<utf8_to_latin1()|/utf8_to_latin1>, but requires its argument to be a UTF-8-encoded byte string.

=head3 ux_utf8_to_latin1_de

Like L<utf8_to_latin1_de()|/utf8_to_latin1_de>, but requires its argument to be a UTF-8-encoded byte string.


=head1 SEE ALSO

Text::Unidecode(3pm),
unicruft(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
