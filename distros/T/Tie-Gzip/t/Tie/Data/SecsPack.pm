#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Data::SecsPack;

use strict;
use 5.001;
use warnings;
use warnings::register;

#####
# Connect up with the event log.
#
use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.02';
$DATE = '2004/04/15';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(pack_int pack_num str2int unpack_num);

# use SelfLoader;

# 1

# __DATA__

#####
#  Pack a list of integers, twos complement, MSB first (big endian, network) order.
#  Assumming the native computer does two's arith.
#
sub pack_int
{
     return undef unless(defined($_[0]));      
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     return ("No inputs\n",undef) unless defined($_[0]);

     my $format = shift;
     my $format_length;
     ($format,$format_length) = $format =~ /([SUIT])(\d+)?/;
     unless($format) {
         return (undef,"Only integer formats supported.\n");
     }

     ######
     # Do not use $_ off a @_ array. If do, then modify
     # the input symbol in the calling subroutine name 
     # space. Very hard to predict the outcome.
     #
     my @string_integer = @_;

     my @integers=();
     my $max_bytes = 0;
     my @bytes;
     my($str_format,$integer);
     use integer;
     foreach (@string_integer) {
         $str_format = $_ < 0 ? 'S' : 'U';
         if ($str_format eq 'S') {
             return (undef,"Signed number when unsigned specified\n") if $format eq 'U';
             $format = 'S';
         }
         if ($_ == 0) {
             push @integers, [0];
             next;
         }
         if ($_ == -1) {
             push @integers, [0xFF];
             next;
         }
         @bytes = ();
         while($_ != 0 && $_ != -1) {   
             push @bytes,$_ & 0xFF;
             $_ >>= 8;  # arith or logical shift, who cares long 2-complement
         }
         $max_bytes = $max_bytes < scalar(@bytes) ? scalar(@bytes) : $max_bytes;
         @bytes = reverse @bytes; # SECS-II MSB first
         push @integers, [@bytes];
     }
     return (undef,'No integers in input.') unless @integers;

     ####
     # Round up the max length to the nearest power of 2 boundary.
     #
     if( $max_bytes  <= 1) {
         $max_bytes  = 1; 
     }
     elsif( $max_bytes  <= 2) {
         $max_bytes  = 2; 
     }
     elsif( $max_bytes  <= 4) {
         $max_bytes  = 4; 
     }
     elsif( $max_bytes  <= 8) {
         $max_bytes  = 8; 
     }
     else {
         return ("Integer or float out of SECS-II range.\n",undef);
     }
     if ($format_length) {
         if( $format_length < $max_bytes ) {
             return (undef, "Integer bigger than format length of $max_bytes bytes.\n");
         }
         $max_bytes  = $format_length;
     }

     $format = 'U' if $format eq 'I';
     my $signed = $format eq 'S' ? 1 : 0;
     my ($i, $fill, $length, $integers);
     foreach (@integers) {
         @bytes = @{$_};
         $length = $max_bytes - scalar @bytes;
         if($length) {
             $fill =  $signed && $bytes[0] < 0 ? 0xFF : 0;
             for($i=0; $i< $length; $i++) {
                 unshift @bytes,$fill;
             }
         }
         $integers .= pack ("C$max_bytes",  @bytes);
     }
     $format .= $max_bytes;
     no integer;

     ($format, $integers);
}


#####
#  Pack a list of integers, twos complement, MSB first (big endian, network) order.
#  Assumming the native computer does two's arith.
#
sub pack_num
{
     return undef unless(defined($_[0]));      
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $format = shift @_;
     return ("No inputs\n",undef) unless defined($_[0]);

     ($format, my $format_length) = $format =~ /([FSUIT])(\d+)?/;
     unless($format) {
         return (undef, "Only integer and floating point formats supported.\n");
     }
     my @nums;
     my $str = join '',@_;
     if( $str =~ /\./ || $str =~ /\d+E-?\d+/ || $format eq 'F' ) {
         return (undef,"Floating points under development..\n");
#         ($str, @nums) = str2float( @_ );
#         ($format, my $integers) = pack_float($format,@nums);
#         return ($format,$integers,$str);
     }

     ($str, @nums) = str2int(@_);
     ($format, my $integers) = pack_int($format,@nums);
     ($format,$integers,$str);

}


######
# Convert number (oct, bin, hex, decimal) to decimal
#
sub str2int
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     unless( wantarray ) {
         unless(defined($_[0])) {
            return undef;
         }
         my $str = $_[0];
         return 0+oct($1) if($str =~ /^\s*(-?\s*0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*$/);
         return 0+$1 if ($str =~ /^\s*(-?\s*[0-9]+)\s*$/ );
         return undef;
     }
     return '',() unless @_;
     my @integers = ();
     my @strs = @_;
     foreach $_ (@strs) {
         while ( length($_) ) {
             if($_  =~ s/^\s*(-?)s\*(0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;:]?//) {
                 push @integers,0+oct($1 . $2);
             }
             elsif ($_ =~ s/^\s*(-?)\s*([0-9]+)\s*[,;:]?// ) {
                 push @integers,0+"$1$2";
             }
             else {
                 last;
             }
         }
     }
     (join ('',@strs), @integers);
}



#####
#  Pack a list of integers, twos complement, MSB first (big endian, network) order.
#  Assumming the native computer does two's arith.
#
sub unpack_num
{
     return undef unless(defined($_[0]));      
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     return undef unless defined($_[0]);

     my $format_in = shift;
     my ($format, $format_length) = $format_in =~ /([TFSU])(\d)?/;
     $format_length = 1 if $format eq 'T';
     return "Format $format_in not supported.\n" unless $format;
     return "Floating points under development..\n" if $format eq 'F';
     unless($format_length && 0 < $format_length  && $format_length <= 8) {
         return "Invalid bytes per element.\n";
     }
     my $signed = $format =~ /S/ ? 1 : 0;
     my @bytes;
     my @integers = ();
     my $num;
     use integer;
     my $seci_int = shift @_;
     while ($seci_int) {
         @bytes = unpack "C$format_length",$seci_int;
         $seci_int = substr($seci_int,$format_length);
         $num = $signed && $bytes[0] < 0 ? -1 : 0;
         foreach (@bytes) {
             $num <<= 8;       
             $num |= $_ & 0xFF;
         }         
         push @integers, $num;
     }
     no integer;
     \@integers;
}

1

__END__


=head1 NAME

Data::SecsPack - pack and unpack numbers in accordance with SEMI E5-94

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #  
 use Data::SecsPack qw(pack_int pack_num str2int unpack_num);

 ($format, $integers) = pack_int($format, @string_integers);

 ($format, $numbers, $string) = pack_num($format, @strings);

 $integer = str2int($string);
 ($string, @integers) = str2int(@strings);

 \@numbers = unpack_num($format, $string_numbers); 

 #####
 # Class interface
 #
 use Data::SecsPack;

 ($format, $integers) = Data::Str2Num->pack_int($format, @string_integers);

 ($format, $numbers, $string) = Data::Str2Num->pack_num($format, @strings);

 $integer = Data::Str2Num->str2int($string)
 ($string, @integers) = Data::Str2Num->str2int(@strings);

 \@numbers = Data::Str2Num->unpack_num($format, $string_numbers); 

=head1 DESCRIPTION

The subroutines in the C<Data::SecsPack> module packs and unpacks
numbers in accordance with SEMI E5-94. The E5-94 establishes the
standard for communication between the equipment used to fabricate
semiconductors and the host computer that controls the fabrication.
The equipment in a semiconductor factory (fab) or any other fab
contains every conceivable known microprocessor and operating system
known to man. And there are a lot of specialize real-time embedded 
processors and speciallize real-time embedded operating systems
in addition to the those in the PC world.

The communcication between host and equipment used packed
nested list data structures that include arrays of characters,
integers and floats. The standard has been in place and widely
used in china, germany, korea, japan, france, italy and
the most remote places on this planent for decades.
The basic data structure and packed data formats have not
changed for decades. 

This stands in direct contradiction to common conceptions
of many in the Perl community. The following quote is taken from
page 761, I<Programming Perl> third edition, discussing the 
C<pack> subroutine:

"Floating-point numbers are in the native machine format only.
Because of the variety of floating format and lack of a standard 
"network" represenation, no facility for interchange has been
made. This means that packed floating-point data written
on one machine may not be readable on another. That is
a problem even when both machines use IEEE floating-point arithmetic, 
because the endian-ness of memory representation is not part
of the IEEE spec."

SEMI E5-94 and their precessors do standardize the endian-ness of
floating point, the packing of nested data, used in many programming
languages, and much, much more. The nested data has many performance
advantages over the common SQL culture of viewing and representing
data. The automated fabs of the world make use of nested 
data not only for communication between machines but also for local
processing at the host and equipment.

The endian-ness of SEMI E5-94 is the first MSB byte. Maybe this
is because it makes it easy to spot numbers in a packed data
structure.

Does this standard communications protocol ensure that
everything goes smoothly without any glitches with this wild
mixture of hardware and software talking to each other
in real time?
Of course not. Bytes get reverse. Data gets jumbled from
point A to point B. Machine time is non-existance.
Big ticket, multi-million dollar fab equipment has to
work to earn its keep. And, then there is the everyday
business of suiting up, with humblizing hair nets,
going through air and other
showers just to get in to the clean room.
And make sure not to do anything that will damage
a little cassette containing a million dollars 
worth of product.
It is totally amazing that the product does
get out the door.

=head2 SECSII Format

The L<Data::SecsPack|Data::SecsPack> suroutines 
packs and unpacks numbers in accordance with 
L<SEMI|http://http://www.semiconductor-intl.org> E5-94, 
Semiconductor Equipment Communications Standard 2 (SECS-II),
section 6 Data Structures, Figure 1, Item and List Header,
and Table 1, Item Format Codes.
The base copyright hard copy paper and PDF files avaiable
from
 
 Semiconductor Equipment and Materials International
 805 East Middlefield Road,
 Mountain View, CA 94043-4080 USA
 (415) 964-5111
 Easylink: 62819945
 http://www.semiconductor-intl.org
 http://www.reed-electronics.com/semiconductor/
 
Rows of SEMI E5-94 table 1, Item Format Codes, relating to numbers,
with the addition of the customary unpack format code
and the hex of the format code are as follows:

          C<Item Format COde Table>

 unpacked   binary  octal  hex   description
 ----------------------------------------
 T          001001   11    0x24  Boolean
 S8         011000   30    0x60  8-byte integer (signed)
 S1         011001   31    0x62  1-byte integer (signed)
 S2         011010   32    0x64  2-byte integer (signed)
 S4         011100   34    0x70  4-byte integer (signed)
 F4         100000   40    0x80  8-byte floating
 F8         100100   44    0x90  4-byte floating
 U8         101000   50    0xA0  8-byte integer (unsigned)
 U1         101001   51    0xA4  1-byte integer (unsigned)
 U2         101010   52    0xA8  2-byte integer (unsigned)
 U4         101100   54    0xB0  4-byte integer (unsigned)

Notes:

=over 4

=item 1
 
ASCII  format - Non-printing characters are equipment specific

=item 2 

Integer formats - most significant byte sent first

=item 3

floating formats - IEEE 753 with the byte containing the sign sent first.

=back
   
SEMI E5-94, section 6 Data Structures, establishes the requirements
for the data strutures and data items.

=head2 pack_int subroutine

 ($format, $integers) = pack_int($format, @string_integers);

The C<pack_int> subroutine takes an array of strings, <@string_integers>,
and a format code, as specifed in the above C<Item Format Code Table>
and packs the integers, C<$integers> in the C<$format> in accordance with C<SEMI E5-94>.
The C<pack_int> subroutine also accepts the format code C<I1 I2 I8>
and format codes with out the bytes-per-element number and packs the
numbers in the format using the less space, with unsigned preferred over
signed. In any case, the C<pack_int> subroutine returns
the correct C<$format> of the packed C<$integers>.

When the C<pack_int> encounters an error, it returns C<undef> for C<$format> and
a description of the error as C<$integers>. All the C<@string_integers> must
be valid Perl numbers. 

=head2 pack_num subroutine

 ($format, $numbers, $string) = pack_num($format, @strings);

Currently C<pack_num> only supports integers. The support of floating point is
under development.

The C<pack_num> subroutine does a quick scan of C<@strings> to see if it
can find a floating point number. If the C<pack_num> routine finds a float,
it returns "floating point under development" error; otherwise, it
processes C<@strings> for integers.

The C<pack_num> subroutine process C<@strings> for integers in two steps.
The C<pack_num> subroutine uses C<str2int> to convert the parse the leading
numbers from the C<@strings> as follows:

 ($string, @integers) = str2int(@strings); 

The C<pack_num> subroutine uses C<pack_int> to pack the C<@integers> in
accordance with SEMI E5-94 as follows:

 ($format, $numbers) = pack_int($format, @string_integers);

The results of the integer processing is the array

 C<($format, $numbers, $string)>

The C<str2int> subroutine does not report any errors while the C<pack_int>
routine and thus the C<pack_num> routine reports errors by an undefined
C<$format> and the error message in C<$numbers>


=head2 str2int subroutine

 $integer = str2int($string);
 ($string, @integers) = str2int(@strings); 

The C<Data::SecsPack> program module translates an scalar string to a scalar integer.
Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

The scalar C<str2int> subroutine is basically the same except if it cannot perform
the conversion to an integer, it returns an "undef" instead of a 0.
Also, if the string is a decimal or floating point, it will return an undef.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.
The scalar C<str2int> is the same and supercedes C&<Data::Str2Num::str2int>.
The C<Data::SecsPack> program module superceds the C<Data::Str2Num> program module. 

The C<str2int> subroutine in an array context supports converting multiple run of
numbers in an array of strings C<@strings> to an array of integers, C<@integers>.
It keeps converting the strings, starting with the first string in C<@strings>,
continuing to the next and next until it fails an conversion.
The C<str2int> returns the join of the remaining strings in C<@strings> and
the array of integers C<@integers>.

=head2 unpack_num subroutine

 \@numbers = unpack_num($format, $string_numbers); 

The C<unpack_num> subroutine unpacks an array of numbers C<$string_numbers>
packed in accordance with SEMI-E5 C<$format>. 
A valid C<$format> is in accordance with the above C<Item Format Code Table>.
The floating point formats C<F4 F8> return the error "Floating point under development".

The C<unpack_num> returns a reference, C<\@numbers>, to the unpacked number array
or scalar error message C<$error>. To determine a valid return or an error,
check that C<ref> of the return exists or is 'C<ARRAY>'.


=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $uut = 'Data::SecsPack';
 =>     my $loaded;

 =>     my ($result,@result)
 => my $errors = $fp->load_package($uut, qw(pack_int pack_num str2int unpack_num))
 => $errors
 ''

 => $result = $uut->str2int('033')
 '27'

 => $result = $uut->str2int('0xFF')
 '255'

 => $result = $uut->str2int('0b1010')
 '10'

 => $result = $uut->str2int('255')
 '255'

 => $result = $uut->str2int('hello')
 undef

 => [my ($string, @integers) = str2int('78 45 25', '512 1024', '100000 hello world')]
 [
           'hello world',
           '78',
           '45',
           '25',
           '512',
           '1024',
           '100000'
         ]

 => my ($format, $integers) = pack_num('I',@integers)
 => $format
 'U4'

 => unpack('H*',$integers)
 '0000004e0000002d000000190000020000000400000186a0'

 => ref(my $int_array = unpack_num('U4',$integers))
 'ARRAY'

 => $int_array
 [
           78,
           45,
           25,
           512,
           1024,
           100000
         ]

 => ($format, my $numbers, $string) = pack_num('I', '78 45 25', '512 1024', '100000 hello world')
 => $format
 'U4'

 => $string
 'hello world'

 => unpack('H*', $numbers)
 '0000004e0000002d000000190000020000000400000186a0'


=head1 QUALITY ASSURANCE

The module "t::Data::Str2Num" is the Software
Test Description(STD) module for the "Data::Str2Num".
module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script and include it results in the "Data::Str2Num" POD,
execute the following in any directory:

 tmake -test_verbose -replace -run  -pm=t::Data::Str2Num

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory containing  "t::Data::Str2Num" on the same level as the "lib" 
directory that contains the "Data::Str2Num" module.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, 490A (L<STD490A/3.2.3.6>).
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head2 SEE_ALSO:

=over 4

=item L<File::Spec|File::Spec>

=item L<Data::Str2Num|Data::Str2Num>

=back

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut
### end of script  ######