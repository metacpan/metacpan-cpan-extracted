#
# TO DO:
#
# - Implement SlowMappers for expat builtin encodings (for which there
#   are no .enc files), e.g. UTF-16, US-ASCII, ISO-8859-1.
# - Instead of parsing the .xml file with XML::Encoding, we should use XS.
#   If this will not be implemented for a while, we could try reading the
#   .enc file directly, instead of the .xml file.
#   I started writing XML::UM::EncParser to do this (see EOF), but got stuck.
#

use strict;

package XML::UM::SlowMapper;
use Carp;
use XML::Encoding;

use vars qw{ $VERSION $ENCDIR %DEFAULT_ASCII_MAPPINGS };
$VERSION = '0.01';

my $UTFCHAR = '[\\x00-\\xBF]|[\\xC0-\\xDF].|[\\xE0-\\xEF]..|[\\xF0-\\xFF]...';

#
# The directory that contains the .xml files that come with XML::Encoding.
# Include the terminating '\' or '/' !!
#
$ENCDIR = "/home1/enno/perlModules/XML-Encoding-1.01/maps/";
#$ENCDIR = "c:\\src\\perl\\xml\\XML-Encoding-1.01\\maps\\";

#
# From xmlparse.h in expat distribution:
#
# Expat places certain restrictions on the encodings that are supported
# using this mechanism.
#
# 1. Every ASCII character that can appear in a well-formed XML document,
# other than the characters
#
#  $@\^`{}~
#
# must be represented by a single byte, and that byte must be the
# same byte that represents that character in ASCII.
#
# [end of excerpt]

#?? Which 'ASCII characters can appear in a well-formed XML document ??

# All ASCII codes 0 - 127, excl. 36,64,92,94,96,123,125,126 i.e. $@\^`{}~
%DEFAULT_ASCII_MAPPINGS = map { (chr($_), chr($_)) } (0 .. 35, 37 .. 63, 
						      65 .. 91, 93, 95, 
						      97 .. 122, 124, 127);

sub new
{
    my ($class, %hash) = @_;
    my $self = bless \%hash, $class;
    
    $self->read_encoding_file;

    $self;
}

sub dispose
{
    my $self = shift;
    $self->{Factory}->dispose_mapper ($self);
    delete $self->{Encode};
}

# Reads the XML file that contains the encoding definition.
# These files come with XML::Encoding.
sub read_encoding_file
{
#?? This should parse the .enc files (the .xml files are not installed) !!

    my ($self) = @_;
    my $encoding = $self->{Encoding};

    # There is no .enc (or .xml) file for US-ASCII, but the mapping is simple
    # so here it goes...
    if ($encoding eq 'US-ASCII')
    {
	$self->{EncMapName} = 'US-ASCII';
	$self->{Map} = \%DEFAULT_ASCII_MAPPINGS;	# I hope this is right
	return;
    }

    my $file = $self->find_encoding_file ($encoding);
    
    my %uni = %DEFAULT_ASCII_MAPPINGS;
    my $prefix = "";
    my $DIR = "file:$ENCDIR";

    my $enc = new XML::Encoding (Handlers => { 
					       Init =>
					       sub {
						   my $base = shift->base ($DIR);
					       }
				 },

				 PushPrefixFcn => 
				 sub { 
				     $prefix .= chr (shift); 
				     undef;
				 },

				 PopPrefixFcn => 
				 sub {
				     chop $prefix;
				     undef;
				 },

				 RangeSetFcn => 
				 sub {
				     my ($byte, $uni, $len) = @_;
				     for (my $i = $uni; $len--; $uni++)
				     {
					 $uni{XML::UM::unicode_to_utf8($uni)} = $prefix . chr ($byte++);
				     }
				     undef;
				 });

    $self->{EncMapName} = $enc->parsefile ($file);

#print "Parsed Encoding " . $self->{Encoding} . " MapName=" . $self->{EncMapName} . "\n";

    $self->{Map} = \%uni;
}

sub find_encoding_file
{
    my ($self, $enc) = @_;

    return "$ENCDIR\L$enc\E.xml";	 # .xml filename is lower case
}

# Returns a closure (method) that converts a UTF-8 encoded string to an 
# encoded byte sequence.
sub get_encode
{
    my ($self, %hash) = @_;
    my $MAP = $self->{Map};
    my $ENCODE_UNMAPPED = $hash{EncodeUnmapped} || \&XML::UM::encode_unmapped_dec;

    my $code = "sub {\n    my \$str = shift;\n    \$str =~ s/";

    $code .= "($UTFCHAR)/\n";
    $code .= "defined \$MAP->{\$1} ? \$MAP->{\$1} : ";
    $code .= "\&\$ENCODE_UNMAPPED(\$1) /egs;\n";

    $code .= "\$str }\n";
#    print $code;

    my $func = eval $code;
    croak "could not eval generated code=[$code]: $@" if $@;

    $func;
}

#
# Optimized version for when the encoding is UTF-8.
# (In that case no conversion takes place.)
#
package XML::UM::SlowMapper::UTF8;
use vars qw{ @ISA };
@ISA = qw{ XML::UM::SlowMapper };

sub read_encoding_file
{
    # ignore it
}

sub get_encode
{
    \&dont_convert;
}

sub dont_convert	# static
{
    shift		# return argument unchanged
}

package XML::UM::SlowMapperFactory;

sub new
{
    my ($class, %hash) = @_;
    bless \%hash, $class;
}

sub get_encode
{
    my ($self, %options) = @_;
    my $encoding = $options{Encoding};

    my $mapper = $self->get_mapper ($encoding);
    return $mapper->get_encode (%options);
}

sub get_mapper
{
    my ($self, $encoding) = @_;
    $self->{Mapper}->{$encoding} ||= 
	($encoding eq "UTF-8" ?
	 new XML::UM::SlowMapper::UTF8 (Encoding => $encoding, 
					Factory => $self) :
	 new XML::UM::SlowMapper (Encoding => $encoding, 
				  Factory => $self));
}

#
# Prepare for garbage collection (remove circular refs)
#
sub dispose_encoding
{
    my ($self, $encoding) = @_;
    my $mapper = $self->{Mapper}->{$encoding};
    return unless defined $mapper;

    delete $mapper->{Factory};
    delete $self->{Mapper}->{$encoding};
}

package XML::UM;
use Carp;

use vars qw{ $FACTORY %XML_MAPPING_CRITERIA };
$FACTORY = XML::UM::SlowMapperFactory->new;

sub get_encode		# static
{
    $FACTORY->get_encode (@_);
}

sub dispose_encoding	# static
{
    $FACTORY->dispose_encoding (@_);
}

# Convert UTF-8 byte sequence to Unicode index; then to '&#xNN;' string
sub encode_unmapped_hex	# static
{
    my $n = utf8_to_unicode (shift);
    sprintf ("&#x%X;", $n);
}

sub encode_unmapped_dec	# static
{
    my $n = utf8_to_unicode (shift);
    "&#$n;"
}

# Converts a UTF-8 byte sequence that represents one character,
# to its Unicode index.
sub utf8_to_unicode	 # static
{
    my $str = shift;
    my $len = length ($str);

    if ($len == 1)
    {
	return ord ($str);
    }
    if ($len == 2)
    {
	my @n = unpack "C2", $str;
	return (($n[0] & 0x3f) << 6) + ($n[1] & 0x3f);
    }
    elsif ($len == 3)
    {
	my @n = unpack "C3", $str;
	return (($n[0] & 0x1f) << 12) + (($n[1] & 0x3f) << 6) + 
		($n[2] & 0x3f);
    }
    elsif ($len == 4)
    {
	my @n = unpack "C4", $str;
	return (($n[0] & 0x0f) << 18) + (($n[1] & 0x3f) << 12) + 
		(($n[2] & 0x3f) << 6) + ($n[3] & 0x3f);
    }
    else
    {
	croak "bad UTF8 sequence [$str] hex=" . hb($str);
    }
}

# Converts a Unicode character index to the byte sequence
# that represents that character in UTF-8.
sub unicode_to_utf8	# static
{
    my $n = shift;
    if ($n < 0x80)
    {
	return chr ($n);
    }
    elsif ($n < 0x800)
    {
	return pack ("CC", (($n >> 6) | 0xc0), (($n & 0x3f) | 0x80));
    }
    elsif ($n < 0x10000)
    {
	return pack ("CCC", (($n >> 12) | 0xe0), ((($n >> 6) & 0x3f) | 0x80),
		     (($n & 0x3f) | 0x80));
    }
    elsif ($n < 0x110000)
    {
	return pack ("CCCC", (($n >> 18) | 0xf0), ((($n >> 12) & 0x3f) | 0x80),
		     ((($n >> 6) & 0x3f) | 0x80), (($n & 0x3f) | 0x80));
    }
    croak "number [$n] is too large for Unicode in \&unicode_to_utf8";
}

#?? The following package is unfinished. 
#?? It should parse the .enc file and create an array that maps
#?? Unicode-index to encoded-str. I got stuck...

# package XML::UM::EncParser;
#
# sub new
# {
#     my ($class, %hash) = @_;
#     my $self = bless \%hash, $class;
#     $self;
# }
#
# sub parse
# {
#     my ($self, $filename) = @_;
#     open (FILE, $filename) || die "can't open .enc file $filename";
#     binmode (FILE);
#
#     my $buf;
#     read (FILE, $buf, 4 + 40 + 2 + 2 + 1024);
#    
#     my ($magic, $name, $pfsize, $bmsize, @map) = unpack ("NA40nnN256", $buf);
#     printf "magic=%04x name=$name pfsize=$pfsize bmsize=$bmsize\n", $magic;
#    
#     if ($magic != 0xFEEBFACE)
#     {
# 	close FILE;
# 	die sprintf ("bad magic number [0x%08X] in $filename, expected 0xFEEBFACE", $magic);
#     }
#
#     for (my $i = 0; $i < 256; $i++)
#     {
# 	printf "[%d]=%d ", $i, $map[$i];
# 	print "\n" if ($i % 8 == 7);
#     }
#
#     for (my $i = 0; $i < $pfsize; $i++)
#     {
# 	print "----- PrefixMap $i ----\n";
# 	read (FILE, $buf, 2 + 2 + 32 + 32);
# 	my ($min, $len, $bmap_start, @ispfx) = unpack ("CCnC64", $buf);
# 	my (@ischar) = splice @ispfx, 32, 32, ();
# #?? could use b256 instead of C32 for bitvector a la vec()
#
# 	print "ispfx=@ispfx\n";
# 	print "ischar=@ischar\n";
# 	$len = 256 if $len == 0;
#
# 	print " min=$min len=$len bmap_start=$bmap_start\n";
#     }
#
#     close FILE;
# }

1; # package return code

__END__

=head1 NAME

XML::UM - Convert UTF-8 strings to any encoding supported by XML::Encoding

=head1 SYNOPSIS

 use XML::UM;

 # Set directory with .xml files that comes with XML::Encoding distribution
 # Always include the trailing slash!
 $XML::UM::ENCDIR = '/home1/enno/perlModules/XML-Encoding-1.01/maps/';

 # Create the encoding routine
 my $encode = XML::UM::get_encode (
	Encoding => 'ISO-8859-2',
	EncodeUnmapped => \&XML::UM::encode_unmapped_dec);

 # Convert a string from UTF-8 to the specified Encoding
 my $encoded_str = $encode->($utf8_str);

 # Remove circular references for garbage collection
 XML::UM::dispose_encoding ('ISO-8859-2');

=head1 DESCRIPTION

This module provides methods to convert UTF-8 strings to any XML encoding
that L<XML::Encoding> supports. It creates mapping routines from the .xml
files that can be found in the maps/ directory in the L<XML::Encoding>
distribution. Note that the XML::Encoding distribution does install the 
.enc files in your perl directory, but not the.xml files they were created
from. That's why you have to specify $ENCDIR as in the SYNOPSIS.

This implementation uses the XML::Encoding class to parse the .xml
file and creates a hash that maps UTF-8 characters (each consisting of up
to 4 bytes) to their equivalent byte sequence in the specified encoding. 
Note that large mappings may consume a lot of memory! 

Future implementations may parse the .enc files directly, or
do the conversions entirely in XS (i.e. C code.)

=head1 get_encode (Encoding => STRING, EncodeUnmapped => SUB)

The central entry point to this module is the XML::UM::get_encode() method. 
It forwards the call to the global $XML::UM::FACTORY, which is defined as
an instance of XML::UM::SlowMapperFactory by default. Override this variable
to plug in your own mapper factory.

The XML::UM::SlowMapperFactory creates an instance of XML::UM::SlowMapper
(and caches it for subsequent use) that reads in the .xml encoding file and
creates a hash that maps UTF-8 characters to encoded characters.

The get_encode() method of XML::UM::SlowMapper is called, finally, which
generates an anonimous subroutine that uses the hash to convert 
multi-character UTF-8 blocks to the proper encoding.

=head1 dispose_encoding ($encoding_name)

Call this to free the memory used by the SlowMapper for a specific encoding.
Note that in order to free the big conversion hash, the user should no longer
have references to the subroutines generated by get_encode().

The parameters to the get_encode() method (defined as name/value pairs) are:

=over 4

=item * Encoding

The name of the desired encoding, e.g. 'ISO-8859-2'

=item * EncodeUnmapped (Default: \&XML::UM::encode_unmapped_dec)

Defines how Unicode characters not found in the mapping file (of the 
specified encoding) are printed. 
By default, they are converted to decimal entity references, like '&#123;'

Use \&XML::UM::encode_unmapped_hex for hexadecimal constants, like '&#xAB;'

=back

=head1 CAVEATS

I'm not exactly sure about which Unicode characters in the range (0 .. 127) 
should be mapped to themselves. See comments in XML/UM.pm near
%DEFAULT_ASCII_MAPPINGS.

The encodings that expat supports by default are currently not supported, 
(e.g. UTF-16, ISO-8859-1),
because there are no .enc files available for these encodings.
This module needs some more work. If you have the time, please help!

=head1 AUTHOR

Original Author is Enno Derksen.

Send bug reports, hints, tips, suggestions to T.J Mather at
<F<tjmather@tjmather.com>>. 

=cut
