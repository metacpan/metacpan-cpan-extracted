#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Tie::Layers;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.03';
$DATE = '2004/05/28';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Do not edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 NAME

 - Software Test Description for Tie::Layers

=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Tie::Layers Program Module

 Revision: -

 Version: 

 Date: 2004/05/28

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

#######
#  
#  1. SCOPE
#
#
=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Tie::Layers|Tie::Layers>
The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

#######
#  
#  3. TEST PREPARATIONS
#
#
=head1 TEST PREPARATIONS

Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.


#######
#  
#  4. TEST DESCRIPTIONS
#
#
=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

=head2 Test Plan

 T: 23^

=head2 ok: 1


  C:
     use File::Package;
     my $uut = 'Tie::Layers'; # Unit Under Test
     my $fp = 'File::Package';
     my $loaded;
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     #
     # LAYER 2:  ENCODE/DECODE FIELDS
     #
     #~~~~~~   
     #####
     # 
     # Encodes a field a field_name, field_value pairs
     # into a scalar encoded_field. Also get a snap shot 
     # of the options.  
     #
     #
     sub encode_field
     {
         my ($self,$record) = @_;
         unless ($record) {
             $self->{current_event} = "No input\n" ;
             return undef;
         }
         return undef unless( $record);
         my @fields = @$record;
         ######
         # Record that called a stub layer
         #
         my $encoded_fields = "layer 2: encode_field\n";
         ######
         # Process the data and record it
         #
         my( $name, $data );
         for( my $i=0; $i < @fields; $i += 2) {
             ($name, $data) = ($fields[$i], $fields[$i+1]);   
             $encoded_fields .= "$name: $data\n";
         }
         #####
         # Get a snap-short of the options
         #
         my $options = $self->{'Tie::Layers'}->{options};
         foreach my $key (sort keys %$options ) {
             next if $key =~ /(print_record|print_layers|read_record|read_layers)/;
             $encoded_fields .= "option $key: $options->{$key}\n";
         }
         $encoded_fields;
     }
     #####
     # 
     # Encodes a field a field_name, field_value pairs
     # into a scalar encoded_field. Also get a snap shot 
     # of the options.  
     #
     #
     sub decode_field
     {
         my ($self,$record) = @_;
         unless ($record) {
             $self->{current_event} = "No input\n" ;
             return undef;
         }
         $record  = "layer 2: decode_field\n" . $record;
         my @fields = split /\s*[:\n]\s*/,$record;
         return \@fields;
     }

     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     #
     # LAYER 1:  ENCODE/DECODE RECORD
     #
     #~~~~~~   
     #########
     # This function un escapes the record separator
     #
     sub decode_record
     {
         my ($self,$record) = @_;
         unless ($record) {
             $self->{current_event} = "No input\n" ;
             return undef;
         }
         #######
         # Unless in strict mode, change CR and LF
         # to end of line string for current operating system
         #
         unless( $self->{'Tie::Layers'}->{options}->{binary} ) {
             $$record =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
             $$record =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
         }
         "layer 1: decode_record\n" . $$record;
      } 
     #############
     # encode the record
     #
     sub encode_record
     {
         my ($self, $record) = @_;
         unless ($record) {
             $self->{current_event} = "No input\n" ;
             return undef;
         }
         my $output = "layer 1: encode_record\n" . $$record;   
         $output;
     } 
     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     #
     # LAYER 0:  READ-WRITE FILE RECORD
     #
     #~~~~~~   
     #########
     # This function gets the next record from
     # the file and unescapes the record separator
     #
     sub read_record
     {
        my ($self) = @_;
        local($/);
        $/ = "\n\~-\~\n";
  
        my ($fh) = $self->{'Tie::Layers'}->{FH};
        $! = 0;
        my $record = <$fh>;
        unless($record) {
            $self->{current_event} = $!;
            return undef;
        }
        $record = substr($record, 0, length($record) - 4);
        $record = "layer 0: get_record\n" . $record;
        return $record;
     } 
     #######
     # append a record to the file and adding the
     # record separator
     #
     sub print_record
     {
         my ($self, $record) = @_;
         my ($fh) = $self->{'Tie::Layers'}->{FH};
         $record .= "\n" unless substr($record, -1, 1) eq "\n";
         $! = 0;
         my $success = print $fh "layer 0: put_record\n$record\~-\~\n";
         $self->{current_event} = $! unless($success);
         $success;
     }
     my (@records, $record);   # force context
 ^

 QC:
     my $test_data1 = 
 "layer 0: put_record
 layer 1: encode_record
 layer 2: encode_field
 field1: value1
 field2: value2
 option binary: 0
 option warn: 1
 \~-\~
 layer 0: put_record
 layer 1: encode_record
 layer 2: encode_field
 field3: value3
 option binary: 0
 option warn: 1
 \~-\~
 layer 0: put_record
 layer 1: encode_record
 layer 2: encode_field
 field4: value4
 field5: value5
 field6: value6
 option binary: 0
 option warn: 1
 \~-\~
 ";
 my @test_data2 = (
      'layer 2',
      'decode_field',
      'layer 1',
      'decode_record',
      'layer 0',
      'get_record',
      'layer 0',
      'put_record',
      'layer 1',
      'encode_record',
      'layer 2',
      'encode_field',
      'field1',
      'value1',
      'field2',
      'value2',
      'option binary',
      0,
      'option warn',
      1);

 my @test_data3 = (
      'layer 2',
      'decode_field',
      'layer 1',
      'decode_record',
      'layer 0',
      'get_record',
      'layer 0',
      'put_record',
      'layer 1',
      'encode_record',
      'layer 2',
      'encode_field',
      'field3',
      'value3',  
      'option binary',
      0,
      'option warn',
      1  
 );
 my @test_data4 = (
      'layer 2',
      'decode_field',
      'layer 1',
      'decode_record',
      'layer 0',
      'get_record',
      'layer 0',
      'put_record',
      'layer 1',
      'encode_record',
      'layer 2',
      'encode_field',
      'field4',
      'value4',
      'field5',
      'value5', 
      'field6',
      'value6',  
      'option binary',
      0,
      'option warn',
      1);
     my $test_data5 = 
 "layer 0: put_record
 layer 1: encode_record
 layer 2: encode_field
 field1: value1
 field2: value2
 option binary: 0
 option warn: 1";
 ^
 VO: ^
  N: UUT not loaded^
  A: $loaded = $fp->is_package_loaded($uut)^
 SE:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  C: my $errors = $fp->load_package($uut)^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3


  C:
     my $version = $Tie::Layers::VERSION;
     $version = '' unless $version;
 ^
  N: Tie::Layers Version $version loaded^
  A: $fp->is_package_loaded($uut)^
  E: 1^
 ok: 3^

=head2 ok: 4


  C:
     tie *LAYERS, 'Tie::Layers', 
         print_record => \&print_record, # layer 0
         print_layers => [
            \&encode_record, # layer 1
            \&encode_field,  # layer 2
         ],
         read_record => \&read_record, # layer 0
         read_layers => [
            \&decode_record,  # layer 1
            \&decode_field,    # layer 2
         ];
     my $layers = tied *LAYERS;
     unlink 'layers1.txt';
 ^
  N: open( \*LAYERS,'>layers1.txt')^
  A: open( \*LAYERS,'>layers1.txt')^
  E: 1^
 ok: 4^

=head2 ok: 5

  N: print LAYERS [qw(field1 value1 field2 value2)]^
  A: (print LAYERS [qw(field1 value1 field2 value2)])^
  E: 1^
 ok: 5^

=head2 ok: 6

  N: print LAYERS [qw(field3 value3)]^
  A: (print LAYERS [qw(field3 value3)])^
  E: 1^
 ok: 6^

=head2 ok: 7

  N: print LAYERS [qw(field4 value4 field5 value5 field6 value6)]^
  A: (print LAYERS [qw(field4 value4 field5 value5 field6 value6)])^
  E: 1^
 ok: 7^

=head2 ok: 8

  N: print close(LAYERS)^
  A: close(LAYERS)^
  E: 1^
 ok: 8^

=head2 ok: 9


  C:
     local(*FIN);
     tie *FIN, 'Tie::Layers', 
         binary => 1,
         read_layers => [
             sub 
             {
                 my ($self,$record) = @_;
                 unless ($record) {
                    $self->{current_event} = "No input\n" ;
                    return undef;
                 }
                 #######
                 # Unless in strict mode, change CR and LF
                 # to end of line string for current operating system
                 #
                 $$record =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
                 $$record =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
                 $$record;
             }
         ];
     my $slurp = tied *FIN;
 ^
  N: Verify file layers1.txt content^
  A: $slurp->fin('layers1.txt')^
  E: $test_data1^
 ok: 9^

=head2 ok: 10

  N: open( \*LAYERS,'<layers1.txt')^
  A: open( \*LAYERS,'<layers1.txt')^
  E: 1^
 ok: 10^

=head2 ok: 11

  N: readline record 1^
  A: $record = <LAYERS>^
  E: [@test_data2]^
 ok: 11^

=head2 ok: 12

  N: readline record 2^
  A: $record = <LAYERS>^
  E: [@test_data3]^
 ok: 12^

=head2 ok: 13

  N: readline record 3^
  A: $record = <LAYERS>^
  E: [@test_data4]^
 ok: 13^

=head2 ok: 14

  N: seek(LAYERS,0,0)^
  C: seek(LAYERS,0,0)^
  A: $record = <LAYERS>^
  E: [@test_data2]^
 ok: 14^

=head2 ok: 15

  N: seek(LAYERS,2,0)^
  C: seek(LAYERS,2,0)^
  A: $record = <LAYERS>^
  E: [@test_data4]^
 ok: 15^

=head2 ok: 16

  N: seek(LAYERS,-1,1)^
  C: seek(LAYERS,-1,1)^
  A: $record = <LAYERS>^
  E: [@test_data3]^
 ok: 16^

=head2 ok: 17

  N: readline close(LAYERS)^
  A: close(LAYERS)^
  E: 1^
 ok: 17^

=head2 ok: 18

  N: Verify fout content^
  C: $slurp->fout('layers1.txt', $test_data1);^
  A: $slurp->fin('layers1.txt')^
  E: $test_data1^
 ok: 18^

=head2 ok: 19

  N: $uut->config('binary')^
  A: [$uut->config('binary')]^
  E: ['binary', 0]^
 ok: 19^

=head2 ok: 20

  N: $slurp->{'Tie::Layers'}->{options}->{binary}^
  A: $slurp->{'Tie::Layers'}->{options}->{binary}^
  E: 1^
 ok: 20^

=head2 ok: 21

  N: $slurp->config('binary', 0)^
  A: [$slurp->config('binary', 0)]^
  E: ['binary', 1]^
 ok: 21^

=head2 ok: 22

  N: $slurp->{'Tie::Layers'}->{options}->{binary}^
  A: $slurp->{'Tie::Layers'}->{options}->{binary}^
  E: 0^
 ok: 22^

=head2 ok: 23

  N: $slurp->config('binary')^
  A: [$slurp->config('binary')]^
  E: ['binary', 0]^
 ok: 23^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
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

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
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

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<Tie::Layers>

=back

=for html


=cut

__DATA__

Name: ^
File_Spec: Unix^
UUT: Tie::Layers^
Revision: -^
Version: ^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
STD2167_Template: ^
Detail_Template: ^
Classification: None^
Temp: temp.pl^
Demo: Layers.d^
Verify: Layers.t^


 T: 23^


 C:
    use File::Package;

    my $uut = 'Tie::Layers'; # Unit Under Test
    my $fp = 'File::Package';
    my $loaded;

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # LAYER 2:  ENCODE/DECODE FIELDS
    #
    #~~~~~~   

    #####
    # 
    # Encodes a field a field_name, field_value pairs
    # into a scalar encoded_field. Also get a snap shot 
    # of the options.  
    #
    #
    sub encode_field
    {
        my ($self,$record) = @_;
        unless ($record) {
            $self->{current_event} = "No input\n" ;
            return undef;
        }

        return undef unless( $record);
        my @fields = @$record;

        ######
        # Record that called a stub layer
        #
        my $encoded_fields = "layer 2: encode_field\n";

        ######
        # Process the data and record it
        #
        my( $name, $data );
        for( my $i=0; $i < @fields; $i += 2) {
            ($name, $data) = ($fields[$i], $fields[$i+1]);   
            $encoded_fields .= "$name: $data\n";
        }

        #####
        # Get a snap-short of the options
        #
        my $options = $self->{'Tie::Layers'}->{options};
        foreach my $key (sort keys %$options ) {
            next if $key =~ /(print_record|print_layers|read_record|read_layers)/;
            $encoded_fields .= "option $key: $options->{$key}\n";
        }
        \$encoded_fields;
    }

    #####
    # 
    # Encodes a field a field_name, field_value pairs
    # into a scalar encoded_field. Also get a snap shot 
    # of the options.  
    #
    #
    sub decode_field
    {
        my ($self,$record) = @_;
        unless ($record) {
            $self->{current_event} = "No input\n" ;
            return undef;
        }
        $record  = "layer 2: decode_field\n" . $record;
        my @fields = split /\s*[:\n]\s*/,$record;
        return \@fields;
    }


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # LAYER 1:  ENCODE/DECODE RECORD
    #
    #~~~~~~   

    #########
    # This function un escapes the record separator
    #
    sub decode_record
    {
        my ($self,$record) = @_;
        unless ($record) {
            $self->{current_event} = "No input\n" ;
            return undef;
        }
        #######
        # Unless in strict mode, change CR and LF
        # to end of line string for current operating system
        #
        unless( $self->{'Tie::Layers'}->{options}->{binary} ) {
            $$record =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
            $$record =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
        }

        "layer 1: decode_record\n" . $$record;
     } 

    #############
    # encode the record
    #
    sub encode_record
    {
        my ($self, $record) = @_;
        unless ($record) {
            $self->{current_event} = "No input\n" ;
            return undef;
        }
        my $output = "layer 1: encode_record\n" . $$record;   
        \$output;
    } 

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    # LAYER 0:  READ-WRITE FILE RECORD
    #
    #~~~~~~   

    #########
    # This function gets the next record from
    # the file and unescapes the record separator
    #
    sub read_record
    {
       my ($self) = @_;

       local($/);
       $/ = "\n\~-\~\n";
 
       my ($fh) = $self->{'Tie::Layers'}->{FH};
       $! = 0;
       my $record = <$fh>;
       unless($record) {
           $self->{current_event} = $!;
           return undef;
       }
       $record = substr($record, 0, length($record) - 4);
       $record = "layer 0: get_record\n" . $record;
       return $record;
    } 

    #######
    # append a record to the file and adding the
    # record separator
    #
    sub print_record
    {
        my ($self, $record) = @_;
        my ($fh) = $self->{'Tie::Layers'}->{FH};
        $record .= "\n" unless substr($record, -1, 1) eq "\n";
        $! = 0;
        my $success = print $fh "layer 0: put_record\n$record\~-\~\n";
        $self->{current_event} = $! unless($success);
        $success;
    }
    my (@records, $record);   # force context
^


QC:
    my $test_data1 = 
"layer 0: put_record
layer 1: encode_record
layer 2: encode_field
field1: value1
field2: value2
option binary: 0
option warn: 1
\~-\~
layer 0: put_record
layer 1: encode_record
layer 2: encode_field
field3: value3
option binary: 0
option warn: 1
\~-\~
layer 0: put_record
layer 1: encode_record
layer 2: encode_field
field4: value4
field5: value5
field6: value6
option binary: 0
option warn: 1
\~-\~
";

my @test_data2 = (
     'layer 2',
     'decode_field',
     'layer 1',
     'decode_record',
     'layer 0',
     'get_record',
     'layer 0',
     'put_record',
     'layer 1',
     'encode_record',
     'layer 2',
     'encode_field',
     'field1',
     'value1',
     'field2',
     'value2',
     'option binary',
     0,
     'option warn',
     1);


my @test_data3 = (
     'layer 2',
     'decode_field',
     'layer 1',
     'decode_record',
     'layer 0',
     'get_record',
     'layer 0',
     'put_record',
     'layer 1',
     'encode_record',
     'layer 2',
     'encode_field',
     'field3',
     'value3',  
     'option binary',
     0,
     'option warn',
     1  
);

my @test_data4 = (
     'layer 2',
     'decode_field',
     'layer 1',
     'decode_record',
     'layer 0',
     'get_record',
     'layer 0',
     'put_record',
     'layer 1',
     'encode_record',
     'layer 2',
     'encode_field',
     'field4',
     'value4',
     'field5',
     'value5', 
     'field6',
     'value6',  
     'option binary',
     0,
     'option warn',
     1);

    my $test_data5 = 
"layer 0: put_record
layer 1: encode_record
layer 2: encode_field
field1: value1
field2: value2
option binary: 0
option warn: 1";
^

VO: ^
 N: UUT not loaded^
 A: $loaded = $fp->is_package_loaded($uut)^
SE:  ''^
ok: 1^

 N: Load UUT^
 C: my $errors = $fp->load_package($uut)^
 A: $errors^
SE: ''^
ok: 2^


 C:
    my $version = $Tie::Layers::VERSION;
    $version = '' unless $version;
^

 N: Tie::Layers Version $version loaded^
 A: $fp->is_package_loaded($uut)^
 E: 1^
ok: 3^


 C:
    tie *LAYERS, 'Tie::Layers', 
        print_record => \&print_record, # layer 0
        print_layers => [
           \&encode_record, # layer 1
           \&encode_field,  # layer 2
        ],
        read_record => \&read_record, # layer 0
        read_layers => [
           \&decode_record,  # layer 1
           \&decode_field,    # layer 2
        ];

    my $layers = tied *LAYERS;
    unlink 'layers1.txt';
^

 N: open( \*LAYERS,'>layers1.txt')^
 A: open( \*LAYERS,'>layers1.txt')^
 E: 1^
ok: 4^

 N: print LAYERS [qw(field1 value1 field2 value2)]^
 A: (print LAYERS [qw(field1 value1 field2 value2)])^
 E: 1^
ok: 5^

 N: print LAYERS [qw(field3 value3)]^
 A: (print LAYERS [qw(field3 value3)])^
 E: 1^
ok: 6^

 N: print LAYERS [qw(field4 value4 field5 value5 field6 value6)]^
 A: (print LAYERS [qw(field4 value4 field5 value5 field6 value6)])^
 E: 1^
ok: 7^

 N: print close(LAYERS)^
 A: close(LAYERS)^
 E: 1^
ok: 8^


 C:
    local(*FIN);
    tie *FIN, 'Tie::Layers', 
        binary => 1,
        read_layers => [
            sub 
            {
                my ($self,$record) = @_;
                unless ($record) {
                   $self->{current_event} = "No input\n" ;
                   return undef;
                }
                #######
                # Unless in strict mode, change CR and LF
                # to end of line string for current operating system
                #
                $$record =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
                $$record =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
                $$record;
            }
        ];
    my $slurp = tied *FIN;
^

 N: Verify file layers1.txt content^
 A: $slurp->fin('layers1.txt')^
 E: $test_data1^
ok: 9^

 N: open( \*LAYERS,'<layers1.txt')^
 A: open( \*LAYERS,'<layers1.txt')^
 E: 1^
ok: 10^

 N: readline record 1^
 A: $record = <LAYERS>^
 E: [@test_data2]^
ok: 11^

 N: readline record 2^
 A: $record = <LAYERS>^
 E: [@test_data3]^
ok: 12^

 N: readline record 3^
 A: $record = <LAYERS>^
 E: [@test_data4]^
ok: 13^

 N: seek(LAYERS,0,0)^
 C: seek(LAYERS,0,0)^
 A: $record = <LAYERS>^
 E: [@test_data2]^
ok: 14^

 N: seek(LAYERS,2,0)^
 C: seek(LAYERS,2,0)^
 A: $record = <LAYERS>^
 E: [@test_data4]^
ok: 15^

 N: seek(LAYERS,-1,1)^
 C: seek(LAYERS,-1,1)^
 A: $record = <LAYERS>^
 E: [@test_data3]^
ok: 16^

 N: readline close(LAYERS)^
 A: close(LAYERS)^
 E: 1^
ok: 17^

 N: Verify fout content^
 C: $slurp->fout('layers1.txt', $test_data1);^
 A: $slurp->fin('layers1.txt')^
 E: $test_data1^
ok: 18^

 N: \$uut->config('binary')^
 A: [$uut->config('binary')]^
 E: ['binary', 0]^
ok: 19^

 N: \$slurp->{'Tie::Layers'}->{options}->{binary}^
 A: $slurp->{'Tie::Layers'}->{options}->{binary}^
 E: 1^
ok: 20^

 N: \$slurp->config('binary', 0)^
 A: [$slurp->config('binary', 0)]^
 E: ['binary', 1]^
ok: 21^

 N: \$slurp->{'Tie::Layers'}->{options}->{binary}^
 A: $slurp->{'Tie::Layers'}->{options}->{binary}^
 E: 0^
ok: 22^

 N: \$slurp->config('binary')^
 A: [$slurp->config('binary')]^
 E: ['binary', 0]^
ok: 23^

 C: unlink 'layers1.txt'^

See_Also: L<Tie::Layers>^

Copyright:
copyright © 2004 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=item 3

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

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
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
^

HTML: ^


~-~
