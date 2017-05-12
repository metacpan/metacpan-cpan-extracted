#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package Tie::Layers;

use 5.001;
use strict;
use warnings;
use warnings::register;
use attributes;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.06';
$DATE = '2004/05/28';
$FILE = __FILE__;

use File::Spec;
use Data::Startup 0.08;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(is_handle);

use vars qw($default_options);
$default_options= defaults();

#######
# 
#
sub defaults
{
   my $class =  UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : '';
   my %options = (   
      binary => 0,
      warn => 1,
      print_layers => [],
      print_record => undef,
      read_layers => [],
      read_record => \&layer_readline,
   );
   my $options = Data::Startup::override(\%options,@_);
   $options = bless $options, $class if $class;
   $options;      
}


####
# slurp in a file
#
sub fin
{
   my ($layer, $file, @options) = @_;
   $default_options = Tie::Layers->default() unless $default_options;
   my $options = Data::Startup::override($default_options, $layer->{'Tie::Layers'}->{options});
   $options = Data::Startup::override($options, @options);

   $layer->{current_event} = '';
   goto EVENT unless OPEN($layer, '<', $file, $options);
   $layer->{current_event} = '';
   my $data = join '', $layer->READLINE( );
   goto EVENT if $layer->{current_event};
   goto EVENT unless CLOSE($layer);
   return $data;

EVENT:
   $layer->{current_event} .= "\tTie::Layer::fin $VERSION\n";
   if($options->warn) {
       warn( $layer->{current_event} );
       return undef;
   }   
   my $event = $layer->{event};      
   return \$event;
}



####
# slurp in a file
#
sub fout
{
   my ($layer, $file, $data, @options) = @_;
   $default_options = Tie::Layers->default() unless $default_options;
   my $options = Data::Startup::override($default_options, $layer->{'Tie::Layers'}->{options});
   $options = Data::Startup::override($options, @options);

   my $fh;
   $layer->{current_event} = '';
   goto EVENT unless OPEN($layer, '>', $file, $options);
   goto EVENT unless PRINT($layer, $data );
   goto EVENT unless CLOSE($layer);
   return '';

EVENT:
   $layer->{current_event} .= "\tTie::Layers::fout $VERSION\n";  
   if($options->warn) {
       warn( $layer->{current_event} );
       return undef;
   }         
   $layer->{event};
}



########
# Determines if a file handle
#
# Lifted from Archive::Tar
#
sub is_handle
{
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $fh = shift ;

    return ((UNIVERSAL::isa($fh,'GLOB') or UNIVERSAL::isa(\$fh,'GLOB')) 
		and defined fileno($fh)  )
}

####
#
#
sub layer_readline
{
    my ($self) = @_;
    my ($fh) = $self->{'Tie::Layers'}->{FH};
    <$fh>;
} 


######
#
#
sub BINMODE
{
     my $self = shift;
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        return undef if $self->{event} =~ /No open file handle/;
        my $event = "No open file handle\n";
        $event .= "\tTie::Layers::BINMODE() $VERSION\n";
        $self->{event} .= $event;
        warn($event) if $self->{'Tie::Layers'}->{warn};
        return undef;
     }
     binmode $fh;
}


######
# Configuration
#
sub config
{
     $default_options = defaults() unless $default_options;
     my $options; 
     if( UNIVERSAL::isa($_[0],__PACKAGE__) ) {
         my $self = shift;
         if(ref($self) && attributes::reftype($self) eq 'HASH') {
             $options = $self->{'Tie::Layers'}->{options};
         }
         else {
             $options = $default_options;
         }
     }
     elsif( ref($_[0]) eq 'HASH' ) {
         $options = shift;  
     }
     else {
         $options = $default_options;
     }
     Data::Startup::config($options,@_);
}



#####
# Started with CPAN::Tarzip::DESTROY, CPAN::Tarzip::gtest 
#
sub CLOSE
{
     my($self) = @_;
     $self->{current_event} = '';
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        return undef unless $self->{event};
        return undef if $self->{event} =~ /No open file handle/;
        $self->{current_event} = "No open file handle\n";
        goto EVENT;
     }
     my $success = close($fh);
     $self->{'Tie::Layers'}->{FH} = undef;
     return 1 if $success;
     return 0 if $self->{event} =~ /Bad close/;
     $self->{current_event} = "Bad close\n\t$!\n";

EVENT:
     $self->{current_event} .= "\tTie::Layers::CLOSE() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}


#####
#
#
sub DESTROY
{
   ######
   #  Sometimes get a DESTROY when coming out of TIEHANDLE. Do not
   #  want TIEHANDLE going around closing stuff, especially when use
   #  OPEN with a fh. Need to close something, call CLOSE directly.  
   #
   #  CLOSE( @_ );
   #
}

#####
#
#
sub EOF
{
     my $self = shift;
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        return undef if $self->{event} =~ /No open file handle/;
        $self->{current_event} = "No open file handle\n";
        $self->{current_event}  .= "\tTie::Layers::EOF() $VERSION\n";
        $self->{event} .= $self->{current_event};
        warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
        return undef;
     }
     eof($fh);
}




######
#
#
sub FILENO
{
     my $self = shift;
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        return undef if $self->{event} =~ /No open file handle/;
        $self->{current_event} = "No open file handle\n";
        $self->{current_event} .= "\tTie::Layers::FILENO() $VERSION\n";
        $self->{event} .= $self->{current_event};
        warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
        return undef;
     }
     fileno($fh);
}


#####
# 
#
sub GETC
{
     my $self = shift; 
     return undef if $self->{event} =~ /GETC not supported/;
     $self->{current_event} = "GETC not supported.\n";
     $self->{current_event} .= "\tTie::Layers::GETC() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}


######
#  A tied object can be used to close current file
#  and open another file.
#
sub OPEN
{

     ######
     # Make a copy so change without impacting
     # the using variables.
     #
     my ($self, $file, @options) = @_;
     $self->{current_event} = '';
     unless (defined $file) {
        $self->{current_event} = "No inputs\n";
        goto EVENT;
     }

     #####
     # clean out the object data
     #
     my $fh = $self->{'Tie::Layers'}->{FH};
     close{$fh} if $fh;
     $self->{'Tie::Layers'}->{FH} = undef;
     $self->{event} = '';
     $self->{'Tie::Layers'}->{recmap} = [0];
     $self->{'Tie::Layers'}->{rec} = 0;

   
     $file =~ s/^\s*([<>+|]+)\s*//;
     my $mode = $1;
     $self->{'Tie::Layers'}->{mode} = $mode;
     $file = shift @options unless $file;
     $self->{'Tie::Layers'}->{file} = $file;

     $default_options = Tie::Layers->default() unless $default_options;
     my $options = Data::Startup::override($default_options, $self->{'Tie::Layers'}->{options});
     $options = Data::Startup::override($options,@options);
     $self->{'Tie::Layers'}->{options} = $options;
 
     ######
     # Open the table file
     #    
     if( is_handle($file) ) {
         $self->{'Tie::Layers'}->{file} = '';
         $self->{'Tie::Layers'}->{FH} = $file; 
     }

     else {

        my $fh; 
        $self->CLOSE;
        $self->{event} = '';
        unless ( open( $fh, $self->{'Tie::Layers'}->{mode}, $file,) ) {
            $self->{current_event} = "Cannot open $file\n\t$!";
            while(chomp($self->{current_event})) {};
            $self->{current_event} .= "\n";
            goto EVENT;
        }
        $self->{'Tie::Layers'}->{FH} = $fh;
        $self->{'Tie::Layers'}->{file} = $file;
     }

     ##########
     # binary 
     #
     binmode $self->{'Tie::Layers'}->{FH} if $self->{'Tie::Layers'}->{options}->{binary}; 
     $self->{'Tie::Layers'}->{file_abs} = File::Spec->rel2abs( $self->{'Tie::Layers'}->{file} ) if $self->{'Tie::Layers'}->{file};
     return 1;

EVENT:
     $self->{current_event} .= "\tTie::Layers::OPEN() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}



#####
# 
#
sub PRINT
{
     my $self = shift;   
     $self->{current_event} = '';
     my $fh = $self->{'Tie::Layers'}->{FH};
      unless ($fh) {
        $self->{current_event} = "No open file handle\n";
        goto EVENT;
     }
     my ($fieldref);
     my @print_layers = reverse @{$self->{'Tie::Layers'}->{options}->{print_layers}};
     my @records = @_;
     foreach $fieldref (@records) {
         foreach (@print_layers ) {
             $self->{current_event} = '';
             $fieldref = &$_($self, $fieldref);
             goto EVENT if $self->{current_event};
         }
         if(ref($fieldref) eq 'SCALAR') {
             $fieldref = $$fieldref;
         }
         elsif (ref($fieldref) eq 'ARRAY') {
             $fieldref = join '',@$fieldref;
         }
     }
     my $buf = join(defined $, ? $, : '', @records);
     $buf .= $\ if defined $\;
     my $print_record = $self->{'Tie::Layers'}->{options}->{print_record};
     my $success = 0;
     $self->{current_event} = '';
     if($print_record) {
         $success = &$print_record($self, $buf);
     }
     else {
         $success = print $fh $buf;
     }
     goto EVENT if $self->{current_event};
     $self->{'Tie::Layers'}->{rec}++;
     $self->{'Tie::Layers'}->{recmap}->[$self->{'Tie::Layers'}->{rec}] = tell($fh);
     return $success if $success;
     $self->{current_event} = "Bad write.\n\t$!\n";

EVENT:
     $self->{current_event} .= "\tTie::Layers::PRINT() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}


#####
# 
#
sub PRINTF
{
     my $self = shift;   
     $self->PRINT (sprintf(shift,@_));
}


#####
#
sub READ
{
     my $self = shift; 
     return undef if $self->{event} =~ /READ not supported/;
     $self->{current_event} = "READ not supported.\n";
     $self->{current_event} .= "\tTie::Layers::READ() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}


#####
#
sub READLINE
{
     my($self) = @_;
     $self->{current_event} = '';
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        $self->{current_event} = "No open file handle\n";
        goto EVENT;
     }

     my $wantarray = wantarray( );
     my ($lineref,$line);
      my @lines = ();
     my $read_record = $self->{'Tie::Layers'}->{options}->{read_record};
     $read_record = $read_record ? $read_record : \&layer_readline;
     do {
         $lineref = \$line;
         $$lineref = &$read_record($self, $fh);
         if($line) {
             $self->{'Tie::Layers'}->{rec}++;
             $self->{'Tie::Layers'}->{recmap}->[$self->{'Tie::Layers'}->{rec}] = tell($fh);
             foreach (@{$self->{'Tie::Layers'}->{options}->{read_layers}}) {
                 $self->{current_event} = '';
                 $lineref = &$_($self, $lineref);
                 goto EVENT if $self->{current_event};
             }
             push @lines,$lineref if($lineref || !$wantarray);
         }
     } while($wantarray && $line);

     return  @lines if $wantarray;
     return '' unless $lines[0];  
     return $lines[0];

EVENT:
     $self->{current_event} .= "\tTie::Layers::READLINE() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}


#####
#
#
sub SEEK
{
     my ($self, $offset, $whence) = @_;
     $self->{current_event} = '';
     my $fh = $self->{'Tie::Layers'}->{FH};
     unless ($fh) {
        return undef if $self->{event} && $self->{event} =~ /No open file handle/;
        $self->{current_event}  = "No open file handle\n";
        goto EVENT;
     }

     my $position;
     if($whence == 0) {
        $position = 0;
     }
     else {

        #####
        # Read records until the end of the file
        #
        my $line;
        if($whence == 2) {
           do {
               $line = READLINE($self);                    
           } while ($line);
           goto EVENT unless defined($line);
        }
        $position = $self->{'Tie::Layers'}->{rec};
     }

     $position += $offset;
     if($position < 0) {
        $self->{current_event} = "Seek before beginning of file.\n";
        goto EVENT;
     }
     elsif( @{$self->{'Tie::Layers'}->{recmap}} <= $position ) {
        $self->{current_event} = "Seek after end of file.\n";
        goto EVENT;
     }         
     return seek($fh,$self->{'Tie::Layers'}->{recmap}->[$position],0);


EVENT:
     $self->{current_event} .= "\tTie::Layers::SEEK() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}



#####
#
#
sub TELL
{
    my $self = shift;
    $self->{'Tie::Layers'}->{rec};
}


######
#  Started with CPAN::Tarzip::TIEHANDLE which
#  still retains a faint resemblence.
#
sub TIEHANDLE
{
     my $class = shift @_;

     #########
     # create new object of $class
     # 
     # If there is ref($class) than $class
     # is an object whose class is ref($class).
     # 
     my $self = ref($class) ? $class : bless {},$class;
     $default_options = default() unless $default_options;
     $self->{'Tie::Layers'}->{options} = Data::Startup::override($default_options, @_);
     $self;
}

#####
# 
#
sub WRITE
{
     my $self = shift; 
     return undef if $self->{event} =~ /WRITE not supported/;
     $self->{current_event} = "WRITE not supported.\n";
     $self->{current_event} .= "\tTie::Layers::WRITE() $VERSION\n";
     $self->{event} .= $self->{current_event};
     warn($self->{current_event}) if $self->{'Tie::Layers'}->{warn};
     undef;
}

1

__END__


=head1 NAME

  Tie::Layers - read and write files pipelined through a stack of subroutine layers

=head1 SYNOPSIS

 #####
 # Subroutines
 #
 use Tie::Layers qw(is_handle config);

 $yes = is_handle( $file_handle );

 ($key, $old_value) = config(\%options, $key);
 ($key, $old_value) = config(\%options, $key => $new_value ); 

 ####
 # Config default startup options
 #
 @old_options_list = config(\%options, @option_list);
 @old_options_list = config(\%options, \@option_list);
 @old_options_list = config(\%options, \%option_list);

 #####
 # Class interface
 #
 require Tie::Layers;

 #####
 # Using support methods and file handle with
 # the file subroutines such as open(), readline()
 # print(), close()
 #
 tie *LAYERS_FILEHANDLE, 'Tie::Layers', @options
 $layers = tied \*LAYERS_FILEHANDLE; 


 #####
 # Using support methods only, no file subroutines
 # 
 $layers = Tie::Layers->TIEHANDLE(@options);

 ($key, $old_value) = $layers->config($key); 
 ($key, $old_value) = $layers->config($key => $new_value );  

 @old_options_list = $layers->config(@option_list); 
 @old_options_list = $layers->config(\@option_list); 
 @old_options_list = $layers->config(\%option_list);

 $data = $layers->fin($filename, @options);

 $data = $layers->fout($filename, $data, @options);

 $yes = $layers->is_handle( $file_handle );

If a subroutine or method will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.

=head1 DESCRIPTION

The C<Tie::Layers> program module contains the tie file handle C<Tie::Layers>
package.
The C<Tie::Layers> package provides the ability to insert a stack of subroutines between
file subroutines C<print> and C<realine> and the underlying C<$file>.
The syntax of the subroutines of each layer of the readline stack and the print
stack must comply to the
the requirements described herein below.
This is necessary so that the C<Tie::Layers> C<READLINE> and C<PRINT> subroutines
know how to transfer the output from one layer to the input of another layer.
The stacks are setup by supplying options with a reference to
the subroutine for each layer in the print stack and the readline stack.
The C<Tie::Layers> are line orientated and do not support any character
file subrouintes. The C<getc>, C<read>, and C<write> file subroutines
are supported by the C<Tie::Layers> package. The seek routines are line
oriented in that the C<seek> and C<tell> subroutine positions are the line
in the underlying file and not the character position in the file.

=head2 options

The C<Tie::Layers> program module subroutines/methods and the file subroutines
using a filehandle that was created with a C<tie> to 'Tie::Layers, use the
following options:

 option            default            description
 ----------------------------------------------------------------------
 binary       =>   0,                 apply binmode to the $file
 warn         =>   1,                 issue a warn for events
 print_layers =>   [],                stack of print subroutines 
 print_record =>   undef,             print to $file
 read_layers  =>   [],                stack of readline subroutines
 read_record  =>   \&layer_readline,  read a line from $file

The C<Tie::Layers> package is a foundation that is inherited by other
packages. 
The object data hash must be shared by other classes. 
To provide a orderly method of allocating object data space,
the options for the C<Tie::Layers> class are stored in the
following hash:

 $self->{'Tie::Layers'}->{options}

This is public data that may be accessed directly or by using the
C<config> subroutine.
Future design changes of the C<options> data will emphasize
backward compatibility.
The private data for the C<Tie::Layers> classes is restricted
all other members of C<$self->{'Tie::Layers}>. 
As with all private data, future design changes will
emphasize performance over backward compatibility.

=head2 readline stack

The stack for C<readline> is setup with the C<read_layers> and
C<read_record> options. Say the layers are numbered so that layer 0
reads a line from the underlying C<$file>, and the line data is processing
layer_1 to layer_2 and so forth to the last layer_n. The reference to the
subroutine for each layer would be as follows:

 read_record  => \&realine_0    #layer 0

 read_layers => 
     [ \&read_layer_routine_1,  # layer 1

       # ....
                  
       \&read_layer_routine_n,  # layer n
     ];

The synopsis for the C<read_record> and C<read_layers>
subroutine references are as follow:

 $line = read_record($self);  # layer 0
 $lineref = read_layer_routines($self, $lineref); # layers 1 - n

If the C<read_record> option does not exist,
the C<Tie::Layers> methods will supply a
default C<read_record>.

Events are passed from the layer routines by as follows:

 $self->{current_event} = $event;

The C<$lineref> may be either a scalar text or any valid
Perl reference.
When the layer C<$lineref> are references, the

  @array = readline(LAYER)  # or
  @array = <LAYER>

will return an @array of references; otherwise, they
behave as usual and return an @array of text scalar
lines.
The added feature of allowing returns of an
array of references gives layered C<Tie::Layers>
the capability to decode database files such
as comma delimited variable files.

=head2 print stack

The stack for C<print> is setup with the C<print_layers> and
C<print_record> options. Say the layers are numbered so that layer 0
prints a line from the underlying C<$file>, and the line data is processing
from top layer_n down to layer_2 and layer_1. The reference to the
subroutine for each layer would be as follows:

 print_record  => \&print_0    #layer 0

 print_layers => 
     [ \&print_layer_routine_1,  # layer 1

       # ....
                  
       \&print_layer_routine_n,  # layer n
     ];


If the C<print_record> option does not exist,
the C<Tie::Layers> methods will use 
C<print> to print to the underlying file.

The synopsis for the C<print_record> and C<print_layers>
subroutine references are as follow:

 $success = print_record($self, $line);  # layer 0
 $lineref = print_layer_subroutine($self, $lineref); # layers 1 - n

Events are passed from the layer routines by as follows:

 $self->{current_event} = $event;

The C<$lineref> may be either a scalar text or any valid
Perl reference.

=head2 config

 ($key, $old_value) = config(\%options, $key);
 ($key, $old_value) = config(\%options, $key => $new_value ); 

 ####
 # Config default startup options
 #
 @old_options_list = config(\%options, @option_list);
 @old_options_list = config(\%options, \@option_list);
 @old_options_list = config(\%options, \%option_list);

The C<Tie::Layers> package maintains global startup (default) 
options. 
When the C<TIEHANDLE> method creates a new
C<Tie::Layers> object, the C<TIEHANLE> method
sets options for the object,
C<$self->{'Tie::Layers'}->{options} to the
startup (default) optins.

The C<config> subroutine/method can read and modify either
the startup options or the individual options of a 
C<Tie::Layers> object.
When used as a subroutine or class or a object without
hash data, the C<config> subroutine/method access the
startup options; otherwise, it accesses the 
C<Tie::Layers> options.

The C<config> subroutine/method responses with no inputs with all the C<$key,$value>
pairs in C<\%options>; a single C<$key> input with the C<$key,$value>
for that C<$key>; and, a group of C<$key, $value> pairs, C<@option_list>
by replacing all the C<$option> C<$key> in the group by the paired <$value> returning
the C<@old_options_list> of old C<$key,$value> pairs.
The C<config> method does not care if the C<@option_list> is an
array, a reference to an array or a reference to a hash.

=head2 fin

 $data = $layers->fin($filename, @options);

The C<fin> method slurps in the entire C<$filename>
using the readline stack. The C<$layers->{event}>
returns the events from each layer in the
readline stack.

=head2 fout

 $success = $layers->fout($filename, $data, @options);

The C<fout> method

=head2 is_handle

 $yes = is_handle( $file_handle );

The C<is_handle> subroutine determines whether or 
not C<$file_handle> is a file handle.

=head1 DEMONSTRATION

 #########
 # perl Layers.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

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

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)
 $errors

 # ''
 # 
     my $version = $Tie::Layers::VERSION;
     $version = '' unless $version;

 ##################
 # Tie::Layers Version 0.05 loaded
 # 

 $fp->is_package_loaded($uut)

 # 1
 # 
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

 ##################
 # open( *LAYERS,'>layers1.txt')
 # 

 open( \*LAYERS,'>layers1.txt')

 # 1
 # 

 ##################
 # print LAYERS [qw(field1 value1 field2 value2)]
 # 

 (print LAYERS [qw(field1 value1 field2 value2)])

 # '1'
 # 

 ##################
 # print LAYERS [qw(field3 value3)]
 # 

 (print LAYERS [qw(field3 value3)])

 # '1'
 # 

 ##################
 # print LAYERS [qw(field4 value4 field5 value5 field6 value6)]
 # 

 (print LAYERS [qw(field4 value4 field5 value5 field6 value6)])

 # '1'
 # 

 ##################
 # print close(LAYERS)
 # 

 close(LAYERS)

 # 1
 # 
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

 ##################
 # Verify file layers1.txt content
 # 

 $slurp->fin('layers1.txt')

 # 'layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field1: value1
 # field2: value2
 # option binary: 0
 # option warn: 1
 # ~-~
 # layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field3: value3
 # option binary: 0
 # option warn: 1
 # ~-~
 # layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field4: value4
 # field5: value5
 # field6: value6
 # option binary: 0
 # option warn: 1
 # ~-~
 # '
 # 

 ##################
 # open( *LAYERS,'<layers1.txt')
 # 

 open( \*LAYERS,'<layers1.txt')

 # 1
 # 

 ##################
 # readline record 1
 # 

 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field1',
 #           'value1',
 #           'field2',
 #           'value2',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # readline record 2
 # 

 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field3',
 #           'value3',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # readline record 3
 # 

 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field4',
 #           'value4',
 #           'field5',
 #           'value5',
 #           'field6',
 #           'value6',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # seek(LAYERS,0,0)
 # 

 seek(LAYERS,0,0)
 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field1',
 #           'value1',
 #           'field2',
 #           'value2',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # seek(LAYERS,2,0)
 # 

 seek(LAYERS,2,0)
 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field4',
 #           'value4',
 #           'field5',
 #           'value5',
 #           'field6',
 #           'value6',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # seek(LAYERS,-1,1)
 # 

 seek(LAYERS,-1,1)
 $record = <LAYERS>

 # [
 #           'layer 2',
 #           'decode_field',
 #           'layer 1',
 #           'decode_record',
 #           'layer 0',
 #           'get_record',
 #           'layer 0',
 #           'put_record',
 #           'layer 1',
 #           'encode_record',
 #           'layer 2',
 #           'encode_field',
 #           'field3',
 #           'value3',
 #           'option binary',
 #           '0',
 #           'option warn',
 #           '1'
 #         ]
 # 

 ##################
 # readline close(LAYERS)
 # 

 close(LAYERS)

 # 1
 # 

 ##################
 # Verify fout content
 # 

 $slurp->fout('layers1.txt', $test_data1);
 $slurp->fin('layers1.txt')

 # 'layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field1: value1
 # field2: value2
 # option binary: 0
 # option warn: 1
 # ~-~
 # layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field3: value3
 # option binary: 0
 # option warn: 1
 # ~-~
 # layer 0: put_record
 # layer 1: encode_record
 # layer 2: encode_field
 # field4: value4
 # field5: value5
 # field6: value6
 # option binary: 0
 # option warn: 1
 # ~-~
 # '
 # 

 ##################
 # $uut->config('binary')
 # 

 [$uut->config('binary')]

 # [
 #           'binary',
 #           0
 #         ]
 # 

 ##################
 # $slurp->{'Tie::Layers'}->{options}->{binary}
 # 

 $slurp->{'Tie::Layers'}->{options}->{binary}

 # 1
 # 

 ##################
 # $slurp->config('binary', 0)
 # 

 [$slurp->config('binary', 0)]

 # [
 #           'binary',
 #           1
 #         ]
 # 

 ##################
 # $slurp->{'Tie::Layers'}->{options}->{binary}
 # 

 $slurp->{'Tie::Layers'}->{options}->{binary}

 # 0
 # 

 ##################
 # $slurp->config('binary')
 # 

 [$slurp->config('binary')]

 # [
 #           'binary',
 #           0
 #         ]
 # 
 unlink 'layers1.txt'

=head1 QUALITY ASSURANCE

Running the test script C<Layers.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Layers.t> test script, C<Layers.d> demo script,
and C<t::Tie::Layers> Software Test Description (STD) program module POD,
from the C<t::Tie::Layers> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Layers.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Tie::Layers> program module
is in the distribution file
F<Tie-Layers-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt> support@SoftwareDiamonds.com E<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the

pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License for 'Tie::Gzip', 
Software Diamonds
is not liable for meeting any requirement, 
binding or otherwise.

=head2 License

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

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Tie_Layers|Docs::Site_SVD::Tie_Layers>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of file ###

