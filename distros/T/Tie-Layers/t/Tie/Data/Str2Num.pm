#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Data::Str2Num;

use strict;
use 5.001;
use warnings;
use warnings::register;

#####
# Connect up with the event log.
#
use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.07';
$DATE = '2004/05/21';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(str2float str2int str2integer);

use Data::Startup;

use vars qw($default_options);
$default_options = new();

######
# Provide a way to module wide configure
#
sub config
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = new() unless $default_options;
     $default_options->config(@_);
}


#######
# Object used to set default, startup, options values.
#
sub new
{
   Data::Startup->new(
 
      ######
      # Make Test variables visible to tech_config
      #  
      ascii_float => 0
   );

}


######
# Covert a string to floats.
#
sub str2float
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     return '',() unless @_;

     $default_options = Data::Str2Num->new() unless ref($default_options);
     my $options = $default_options->override(pop @_) if ref($_[-1]);

     #########
     # Drop leading empty strings
     #
     my @strs = @_;
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     my @floats = ();
     my $early_exit unless wantarray;
     my ($sign,$integer,$fraction,$exponent);
     foreach (@strs) {
         next unless defined $_;
         while ( length($_) ) {

             ($sign, $integer,$fraction,$exponent) = ('',undef,undef,undef);

             #######
             # Parse the integer part
             #
             if($_  =~ s/^\s*(-?)\s*(0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?//) {
                 $integer = 0+oct($1 . $2);
                 $sign = $1 if $integer =~ s/^\s*-//;
             }
             elsif ($_ =~ s/^\s*(-?)\s*([0-9]+)\s*[,;\n]?//) {
                 ($sign,$integer) = ($1,$2);
             }

             ######
             # Parse the decimal part
             # 
             $fraction = $1 if $_ =~ s/^\.([0-9]+)\s*[,;\n]?// ;

             ######
             # Parse the exponent part
             $exponent = $1 . $2 if $_ =~ s/^E(-?)([0-9]+)\s*[,;\n]?//;

             goto LAST unless defined($integer) || defined($fraction) || defined($exponent);

             $integer = '' unless defined($integer);
             $fraction = '' unless defined($fraction);
             $exponent = 0 unless defined($exponent);

             if($options->{ascii_float} ) {
                 $integer .= '.' . $fraction if( $fraction);
                 $integer .= 'E' . $exponent if( $exponent);
                 push @floats,$sign . $integer;  
             }
             else {
                 ############
                 # Normalize decimal float so that there is only one digit to the
                 # left of the decimal point.
                 # 
                 while($integer  && substr($integer,0,1) == 0) {
                    $integer = substr($integer,1);
                 }
                 if( $integer ) {
                     $exponent += length($integer) - 1;
                 }
                 else {
                     while($fraction && substr($fraction,0,1) == 0) {
                         $fraction = substr($fraction,1);
                         $exponent--;
                     }
                     $exponent--;
                 }
                 $integer .= $fraction;
                 while($integer  && substr($integer,0,1) == 0) {
                    $integer = substr($integer,1);
                 }
                 $integer = 0 unless $integer;
                 push @floats,[$sign . $integer,  $exponent];
             }
             goto LAST if $early_exit;
         }
         last if $early_exit;
     }

LAST:
     #########
     # Drop leading empty strings
     #
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     return (\@strs, @floats) unless $early_exit;
     ($integer,$fraction,$exponent) = @{$floats[0]};
     "${integer}${fraction}E${exponent}"
}



######
# Convert number (oct, bin, hex, decimal) to decimal
#
sub str2int
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     ####  
     # do no let the wantarray kink in
     my $num = str2integer(@_); 
     $num;  
}



######
# Convert number (oct, bin, hex, decimal) to decimal
#
sub str2integer
{
     shift  if UNIVERSAL::isa($_[0],__PACKAGE__);
     unless( wantarray ) {
         return undef unless(defined($_[0]));
         my $str = $_[0];
         return 0+oct($1) if($str =~ /^\s*(-?\s*0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?$/);
         return 0+$1 if ($str =~ /^\s*(-?\s*[0-9]+)\s*[,;:\n]?$/ );
         return undef;
     }

     #######
     # Pick up input strings
     #
     return [],() unless @_;

     $default_options = Data::Str2num->new() unless ref($default_options);
     my $options = $default_options->override(pop @_) if ref($_[-1]);
     my @strs = @_;

     #########
     # Drop leading empty strings
     #
     while (@strs && $strs[0] !~ /^\s*\S/) {
          shift @strs;
     }
     @strs = () unless(@strs); # do not shift @strs out of existance

     my ($int,$num);
     my @integers = ();
     foreach $_ (@strs) {
         next unless defined $_;
         while ( length($_) ) {
             if($_  =~ s/^\s*(-?)\s*(0[0-7]+|0?b[0-1]+|0x[0-9A-Fa-f]+)\s*[,;\n]?//) {
                 $int = $1 . $2;
                 $num = 0+oct($int);
             }
             elsif ($_ =~ s/^\s*(-?)\s*([0-9]+)\s*[,;\n]?// ) {
                 $int = $1 . $2;
                 $num = 0+$int;
 
             }
             else {
                 goto LAST;
             }

             #######
             # If the integer is so large that Perl converted it to a float,
             # repair the str so that the large integer may be dealt as a string
             # or converted to a float. The using routine may be using Math::BigInt
             # instead of using the native Perl floats and this automatic conversion
             # would cause major damage.
             # 
             if($num =~ /\s*[\.E]\d+/) {
                 $_ = $int;
                 goto LAST;
             }
 
             #######
             # If there is a string float instead of an int  repair the str to 
             # perserve the float. The using routine may decide to use str2float
             # to parse out the float.
             # 
             elsif($_ =~ /^\s*[\.E]\d+/) {
                 $_ = $int . $_;
                 goto LAST;
             }
             push @integers,$num;
         }
     }

LAST:
     #########
     # Drop leading empty strings
     #
     while (@strs && (!defined($strs[0]) || $strs[0] !~ /^\s*\S/)) {
          shift @strs;
     }
     @strs = ('') unless(@strs); # do not shift @strs out of existance

     (\@strs, @integers);
}

1

__END__

=head1 NAME

Data::Str2Num - int str to int; float str to float, else undef. No warnings.

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #  
 use Data::Str2Num qw(config str2float str2int str2integer);

 $float = str2float($string, [@options]);
 (\@strings, @floats) = str2float(@strings, [@options]);

 $integer = $secspack->str2int($string);

 $integer = str2integer($string, [@options]);
 (\@strings, @integers) = str2int(@strings, [@options]);


 #####
 # Class, Object interface
 #
 # For class interface, use Data::SecsPack instead of $self
 #
 use Data::Str2Num;

 $str2num = 'Data::Str2Num';
 $str2num = new Data::Str2Num;

 $float = $secspack->str2float($string, [@options]);
 (\@strings, @floats) = $secspack->str2float(@strings, [@options]);

 $integer = $secspack->str2int($string);

 $integer = $secspack->str2integer($string, [@options])
 (\@strings, @integers) = $secspack->str2int(@strings, [@options]);


Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.

=head1 DESCRIPTION

The C<Data::Str2Num> program module provides subroutines that
parse numeric strings from the beginning of alphanumeric strings.

=head2 str2float

 $float = str2float($string);
 $float = str2float($string, [@options]);
 $float = str2float($string, {@options});

 (\@strings, @floats) = str2float(@strings);
 (\@strings, @floats) = str2float(@strings, [@options]);
 (\@strings, @floats) = str2float(@strings, {@options});

The C<str2float> subroutine, in an array context, supports converting multiple run of
integers, decimals or floats in an array of strings C<@strings> to an array
of integers, decimals or floats, C<@floats>.
It keeps converting the strings, starting with the first string in C<@strings>,
continuing to the next and next until it fails an conversion.
The C<str2int> returns the stripped string data, naked of all integers,
in C<@strings> and the array of floats C<@floats>.
For the C<ascii_float> option, the members of the C<@floats> are scalar
strings of the float numbers; otherwise, the members are a reference
to an array of C<[$decimal_magnitude, $decimal_exponent]> where the decimal
point is set so that there is one decimal digit to the left of the decimal
point for $decimal_magnitude.

In a scalar context, it parse out any type of $number in the leading C<$string>.
This is especially useful for C<$string> that is certain to have a single number.

=head2 str2int

 $integer = $secspack->str2int($string);

The C<str2int> subroutine is the same as the C<str2integer> subroutine except that
that the subroutine always returns the scalar processing  C<str2integer> subroutine.

=head2 str2integer

 $integer = str2int($string);
 $integer = str2int($string, [@options]);
 $integer = str2int($string, {@options});

 (\@strings, @integers) = str2int(@strings); 
 (\@strings, @integers) = str2int(@strings, [@options]); 
 (\@strings, @integers) = str2int(@strings, {@options}); 

In a scalar context,
the C<Data::SecsPack> program module translates an scalar string to a scalar integer.
Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

What is C<$x> for the following:

  my $x = 0 + '0x100';  # $x is 0 with a warning

Instead use C<str2int> uses a few simple Perl lines, without
any C<evals> starting up whatevers or firing up the
regular expression engine with its interpretative overhead,
to provide a slightly different response as follows:>.

 $x = str2int('033');   # $x is 27
 $x = str2int('0xFF');  # $x is 255
 $x = str2int('255');   # $x is 255
 $x = str2int('hello'); # $x is undef no warning
 $x = str2int(0.5);     # $x is undef no warning
 $x = str2int(1E0);     # $x is 1 
 $x = str2int(0xf);     # $x is 15
 $x = str2int(1E30);    # $x is undef no warning

The scalar C<str2int> subroutine performs the conversion to an integer
for strings that look like integers and actual integers without
generating warnings. 
A non-numeric string, decimal or floating string returns an "undef" 
instead of the 0 and a warning
that C<0+'hello'> produces.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.
The scalar C<str2int> is the same and supercedes C&<Data::StrInt::str2int>.
The C<Data::SecsPack> program module superceds the C<Data::StrInt> program module. 

The C<str2int> subroutine, in an array context, supports converting multiple run of
integers in an array of strings C<@strings> to an array of integers, C<@integers>.
It keeps converting the strings, starting with the first string in C<@strings>,
continuing to the next and next until it fails a conversion.
The C<str2int> returns the remaining string data in C<@strings> and
the array of integers C<@integers>.

=head1 DEMONSTRATION

 #########
 # perl Str2Num.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     my $fp = 'File::Package';

     my $uut = 'Data::Str2Num';
     my $loaded;
     my ($result,@result); # force a context

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut, 'str2float','str2int','str2integer',)
 $errors

 # ''
 #

 ##################
 # str2int('033')
 # 

 $uut->str2int('033')

 # '27'
 #

 ##################
 # str2int('0xFF')
 # 

 $uut->str2int('0xFF')

 # '255'
 #

 ##################
 # str2int('0b1010')
 # 

 $uut->str2int('0b1010')

 # '10'
 #

 ##################
 # str2int('255')
 # 

 $uut->str2int('255')

 # '255'
 #

 ##################
 # str2int('hello')
 # 

 $uut->str2int('hello')

 # undef
 #

 ##################
 # str2integer(1E20)
 # 

 $result = $uut->str2integer(1E20)

 # undef
 #

 ##################
 # str2integer(' 78 45 25', ' 512E4 1024 hello world') @numbers
 # 

 my ($strings, @numbers) = str2integer(' 78 45 25', ' 512E4 1024 hello world')
 [@numbers]

 # [
 #          '78',
 #          '45',
 #          '25'
 #        ]
 #

 ##################
 # str2integer(' 78 45 25', ' 512E4 1024 hello world') @strings
 # 

 join( ' ', @$strings)

 # '512E4 1024 hello world'
 #

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world')
 [@numbers]

 # [
 #          [
 #            '78',
 #            '1'
 #          ],
 #          [
 #            '-24',
 #            '-6'
 #          ],
 #          [
 #            '25',
 #            -3
 #          ],
 #          [
 #            '0',
 #            -1
 #          ],
 #          [
 #            '512',
 #            '6'
 #          ]
 #        ]
 #

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') @strings
 # 

 join( ' ', @$strings)

 # 'hello world'
 #

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers
 # 

 ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1})
 [@numbers]

 # [
 #          '78',
 #          '-2.4E-6',
 #          '0.0025',
 #          '255',
 #          '63',
 #          '0',
 #          '512E4'
 #        ]
 #

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) @strings
 # 

 join( ' ', @$strings)

 # 'hello world'
 #

=head1 QUALITY ASSURANCE
 
Running the test script C<Str2Num.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for C<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Str2Num.t>
test script, the C<Str2Num.d> demo script,
and the C<t::Data::Str2Num> STD program module PODs,
from the C<t::Data::Str2Num> program module's content.
The C<t::Data::Str2Num> program modules are
in the distribution file
F<Data-Str2Num-$VERSION.tar.gz>.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 2004 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
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

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
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

=head1 SEE_ALSO:

=over 4

=item L<Data::Startup|Data::Startup> 

=back

=cut

### end of program module  ######