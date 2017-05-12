package Unicode::Map8;

# Copyright 1998, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $DEBUG $MAPS_DIR %ALIASES);

require DynaLoader;
@ISA=qw(DynaLoader);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(NOCHAR MAP8_BINFILE_MAGIC_HI MAP8_BINFILE_MAGIC_LO);

$VERSION = '0.13';
#$DEBUG++;

bootstrap Unicode::Map8 $VERSION;

#$MAPS_DIR;  # where to locate map files
#%ALIASES;   # alias names

# Try to locate the maps directory, and read the aliases file
for (split(':', $ENV{MAPS_PATH} || ""),
     (map "$_/Unicode/Map8/maps", @INC),
     "."
    )
{
    if (open(ALIASES, "$_/aliases")) {
	$MAPS_DIR = $_;
	local($_);
	while (<ALIASES>) {
	    next if /^\s*\#/;
	    chomp;
	    my($charset, @aliases) = split(' ', $_);
	    next unless $charset;
	    my $alias;
	    for $alias (@aliases) {
		$ALIASES{$alias} = $charset;
	    }
	}
	close(ALIASES);
	last;
    }
}
$MAPS_DIR ||= ".";

sub new
{
    my $class = shift;
    my $self;
    if (@_) {
	my $file = shift;
	$file = $file->{ID} if ref($file); # Unicode::Map compatibility

	if ($file =~ /\.bin$/) {
	    $self = Unicode::Map8::_new_binfile($file);
	} elsif ($file =~ /\.txt$/) {
	    $self = Unicode::Map8::_new_txtfile($file);
	} else {
	    my $charset = $ALIASES{$file} || $file;
	    $file = "$MAPS_DIR/$charset";
	    $self = Unicode::Map8::_new_binfile("$file.bin") ||
		    Unicode::Map8::_new_txtfile("$file.txt") ||
		    Unicode::Map8::_new_binfile("$file")     ||
		    Unicode::Map8::_new_txtfile("$file");
	    $self->{'charset'} = $charset if $self;
	}
    } else {
	$self = Unicode::Map8::_new();
    }
    bless $self, $class if $self;
    print "CREATED $self\n" if $DEBUG && $self;
    $self;
}

sub tou
{
    require Unicode::String;
    my $self = shift;
    Unicode::String::utf16($self->to16(@_));
}

sub unmapped_to8
{
    my($self, $code) = @_;
    "";
}

sub unmapped_to16
{
    my($self, $code) = @_;
    "";
}

# Some Unicode::Map compatibility stuff

*from_unicode = \&to8;
*to_unicode   = \&to16;

1;

__END__

=head1 NAME

Unicode::Map8 - Mapping table between 8-bit chars and Unicode

=head1 SYNOPSIS

 require Unicode::Map8;
 my $no_map = Unicode::Map8->new("ISO646-NO") || die;
 my $l1_map = Unicode::Map8->new("latin1")    || die;

 my $ustr = $no_map->to16("V}re norske tegn b|r {res\n");
 my $lstr = $l1_map->to8($ustr);
 print $lstr;

 print $no_map->tou("V}re norske tegn b|r {res\n")->utf8

=head1 DESCRIPTION

The I<Unicode::Map8> class implement efficient mapping tables between
8-bit character sets and 16 bit character sets like Unicode.  The
tables are efficient both in terms of space allocated and translation
speed.  The 16-bit strings is assumed to use network byte order.

The following methods are available:

=over 4

=item $m = Unicode::Map8->new( [$charset] )

The object constructor creates new instances of the Unicode::Map8
class.  I takes an optional argument that specify then name of a 8-bit
character set to initialize mappings from.  The argument can also be a
the name of a mapping file.  If the charset/file can not be located,
then the constructor returns I<undef>.

If you omit the argument, then an empty mapping table is constructed.
You must then add mapping pairs to it using the addpair() method
described below.

=item $m->addpair( $u8, $u16 );

Adds a new mapping pair to the mapping object.  It takes two
arguments.  The first is the code value in the 8-bit character set and
the second is the corresponding code value in the 16-bit character
set.  The same codes can be used multiple times (but using the same
pair has no effect).  The first definition for a code is the one that
is used.

Consider the following example:

  $m->addpair(0x20, 0x0020);
  $m->addpair(0x20, 0x00A0);
  $m->addpair(0xA0, 0x00A0);

It means that the character 0x20 and 0xA0 in the 8-bit charset maps to
themselves in the 16-bit set, but in the 16-bit character set 0x0A0 maps
to 0x20.

=item $m->default_to8( $u8 )

Set the code of the default character to use when mapping from 16-bit to
8-bit strings.  If there is no mapping pair defined for a character
then this default is substituted by to8() and recode8().

=item $m->default_to16( $u16 )

Set the code of the default character to use when mapping from 8-bit to
16-bit strings. If there is no mapping pair defined for a character
then this default is used by to16(), tou() and recode8().

=item $m->nostrict;

All undefined mappings are replaced with the identity mapping.
Undefined character are normally just removed (or replaced with the
default if defined) when converting between character sets.

=item $m->to8( $ustr );

Converts a 16-bit character string to the corresponding string in the
8-bit character set.

=item $m->to16( $str );

Converts a 8-bit character string to the corresponding string in the
16-bit character set.

=item $m->tou( $str );

Same an to16() but return a Unicode::String object instead of a plain
UCS2 string.

=item $m->recode8($m2, $str);

Map the string $str from one 8-bit character set ($m) to another one
($m2).  Since we assume we know the mappings towards the common 16-bit
encoding we can use this to convert between any of the 8-bit character
sets.

=item $m->to_char16( $u8 )

Maps a single 8-bit character code to an 16-bit code.  If the 8-bit
character is unmapped then the constant NOCHAR is returned.  The
default is not used and the callback method is not invoked.

=item $m->to_char8( $u16 )

Maps a single 16-bit character code to an 8-bit code. If the 16-bit
character is unmapped then the constant NOCHAR is returned.  The
default is not used and the callback method is not invoked.

=back

The following callback methods are available.  You can override these
methods by creating a subclass of Unicode::Map8.

=over 4

=item $m->unmapped_to8

When mapping to 8-bit character string and there is no mapping defined
(and no default either), then this method is called as the last
resort.  It is called with a single integer argument which is the code
of the unmapped 16-bit character.  It is expected to return a string
that will be incorporated in the 8-bit string.  The default version of
this method always returns an empty string.

Example:

 package MyMapper;
 @ISA=qw(Unicode::Map8);
 
 sub unmapped_to8
 {
    my($self, $code) = @_;
    require Unicode::CharName;
    "<" . Unicode::CharName::uname($code) . ">";
 }

=item $m->unmapped_to16

Likewise when mapping to 16-bit character string and no mapping is
defined then this method is called.  It should return a 16-bit string
with the bytes in network byte order.  The default version of
this method always returns an empty string.

=back

=head1 FILES

The I<Unicode::Map8> constructor can parse two different file formats;
a binary format and a textual format.

The binary format is simple.  It consist of a sequence of 16-bit
integer pairs in network byte order.  The first pair should contain
the magic value 0xFFFE, 0x0001.  Of each pair, the first value is the
code of an 8-bit character and the second is the code of the 16-bit
character.  If follows from this that the first value should be less
than 256.

The textual format consist of lines that is either a comment (first
non-blank character is '#'), a completely blank line or a line with
two hexadecimal numbers.  The hexadecimal numbers must be preceded by
"0x" as in C and Perl.  This is the same format used by the Unicode
mapping files available from <URL:ftp://ftp.unicode.org/Public>.

The mapping table files are installed in the F<Unicode/Map8/maps>
directory somewhere in the Perl @INC path.  The variable
$Unicode::Map8::MAPS_DIR is the complete path name to this directory.
Binary mapping files are stored within this directory with the suffix
I<.bin>.  Textual mapping files are stored with the suffix I<.txt>.

The scripts I<map8_bin2txt> and I<map8_txt2bin> can translate between
these mapping file formats.

A special file called F<aliases> within $MAPS_DIR specify all the
alias names that can be used to denote the various character sets.
The first name of each line is the real file name and the rest is
alias names separated by space.

The `C<umap --list>' command be used to list the character sets
supported.

=head1 BUGS

Does not handle Unicode surrogate pairs as a single character.

=head1 SEE ALSO

L<umap(1)>,
L<Unicode::String>

=head1 COPYRIGHT

Copyright 1998 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
