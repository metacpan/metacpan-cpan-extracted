#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.03';   # automatically generated file
$DATE = '2004/05/28';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Layers.t
#
# UUT: Tie::Layers
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Tie::Layers;
#
# Don't edit this test script file, edit instead
#
# t::Tie::Layers;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 

   use FindBin;
   use File::Spec;
   use Cwd;

   ########
   # The working directory for this script file is the directory where
   # the test script resides. Thus, any relative files written or read
   # by this test script are located relative to this test script.
   #
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Pick up any testing program modules off this test script.
   #
   # When testing on a target site before installation, place any test
   # program modules that should not be installed in the same directory
   # as this test script. Likewise, when testing on a host with a @INC
   # restricted to just raw Perl distribution, place any test program
   # modules in the same directory as this test script.
   #
   use lib $FindBin::Bin;

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes expected and actual references and stringify
   # them by using "Data::Secs2" before passing them to the "&Test::ok"
   # Thus, almost any time of Perl data structures may be
   # compared by passing a reference to them to Test::Tech::ok
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );
   plan(tests => 23);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}




   # Perl code from C:
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
    my (@records, $record);   # force context;



   # Perl code from QC:
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



skip_tests( 1 ) unless
  ok(  $loaded = $fp->is_package_loaded($uut), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);



skip_tests( 1 ) unless
  ok(  $errors, # actual results
     '', # expected results
     "",
     "Load UUT");

#  ok:  2

   # Perl code from C:
    my $version = $Tie::Layers::VERSION;
    $version = '' unless $version;



ok(  $fp->is_package_loaded($uut), # actual results
     1, # expected results
     "",
     "Tie::Layers Version $version loaded");

#  ok:  3

   # Perl code from C:
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



ok(  open( \*LAYERS,'>layers1.txt'), # actual results
     1, # expected results
     "",
     "open( \*LAYERS,'>layers1.txt')");

#  ok:  4

ok(  (print LAYERS [qw(field1 value1 field2 value2)]), # actual results
     1, # expected results
     "",
     "print LAYERS [qw(field1 value1 field2 value2)]");

#  ok:  5

ok(  (print LAYERS [qw(field3 value3)]), # actual results
     1, # expected results
     "",
     "print LAYERS [qw(field3 value3)]");

#  ok:  6

ok(  (print LAYERS [qw(field4 value4 field5 value5 field6 value6)]), # actual results
     1, # expected results
     "",
     "print LAYERS [qw(field4 value4 field5 value5 field6 value6)]");

#  ok:  7

ok(  close(LAYERS), # actual results
     1, # expected results
     "",
     "print close(LAYERS)");

#  ok:  8

   # Perl code from C:
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



ok(  $slurp->fin('layers1.txt'), # actual results
     $test_data1, # expected results
     "",
     "Verify file layers1.txt content");

#  ok:  9

ok(  open( \*LAYERS,'<layers1.txt'), # actual results
     1, # expected results
     "",
     "open( \*LAYERS,'<layers1.txt')");

#  ok:  10

ok(  $record = <LAYERS>, # actual results
     [@test_data2], # expected results
     "",
     "readline record 1");

#  ok:  11

ok(  $record = <LAYERS>, # actual results
     [@test_data3], # expected results
     "",
     "readline record 2");

#  ok:  12

ok(  $record = <LAYERS>, # actual results
     [@test_data4], # expected results
     "",
     "readline record 3");

#  ok:  13

   # Perl code from C:
seek(LAYERS,0,0);



ok(  $record = <LAYERS>, # actual results
     [@test_data2], # expected results
     "",
     "seek(LAYERS,0,0)");

#  ok:  14

   # Perl code from C:
seek(LAYERS,2,0);



ok(  $record = <LAYERS>, # actual results
     [@test_data4], # expected results
     "",
     "seek(LAYERS,2,0)");

#  ok:  15

   # Perl code from C:
seek(LAYERS,-1,1);



ok(  $record = <LAYERS>, # actual results
     [@test_data3], # expected results
     "",
     "seek(LAYERS,-1,1)");

#  ok:  16

ok(  close(LAYERS), # actual results
     1, # expected results
     "",
     "readline close(LAYERS)");

#  ok:  17

   # Perl code from C:
$slurp->fout('layers1.txt', $test_data1);



ok(  $slurp->fin('layers1.txt'), # actual results
     $test_data1, # expected results
     "",
     "Verify fout content");

#  ok:  18

ok(  [$uut->config('binary')], # actual results
     ['binary', 0], # expected results
     "",
     "\$uut->config('binary')");

#  ok:  19

ok(  $slurp->{'Tie::Layers'}->{options}->{binary}, # actual results
     1, # expected results
     "",
     "\$slurp->{'Tie::Layers'}->{options}->{binary}");

#  ok:  20

ok(  [$slurp->config('binary', 0)], # actual results
     ['binary', 1], # expected results
     "",
     "\$slurp->config('binary', 0)");

#  ok:  21

ok(  $slurp->{'Tie::Layers'}->{options}->{binary}, # actual results
     0, # expected results
     "",
     "\$slurp->{'Tie::Layers'}->{options}->{binary}");

#  ok:  22

ok(  [$slurp->config('binary')], # actual results
     ['binary', 0], # expected results
     "",
     "\$slurp->config('binary')");

#  ok:  23

   # Perl code from C:
unlink 'layers1.txt';




    finish();

__END__

=head1 NAME

Layers.t - test script for Tie::Layers

=head1 SYNOPSIS

 Layers.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Layers.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

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

=cut

## end of test script file ##

