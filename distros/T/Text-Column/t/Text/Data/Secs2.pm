#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Data::Secs2;

use 5.001;
use strict;
use warnings;
use warnings::register;
use attributes;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.18';
$DATE = '2004/04/29';
$FILE = __FILE__;

use Data::SecsPack 0.03;
use Data::Startup;

use vars qw(@ISA @EXPORT_OK $default_options);
require Exporter;
@ISA=qw(Exporter Data::Startup);
@EXPORT_OK = qw(arrayify config listify neuterify numberify perlify
                perl_typify secsify secs_elementify stringify textify
                transify);

$default_options = new Data::Secs2;

#######
# Object used to set default, startup, options values.
#
sub new
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = $class->Data::Startup::new(
       perl_secs_numbers => 'multicell',
       obj_format_code => '',
       add_obj_format_code => 0,   
       type => 'ascii',   
       spaces => '  ',
       indent => '',
       'Data::SecsPack' => {}
   );
   $self->Data::Startup::override(@_);

}


# use SelfLoader;

# 1

# __DATA__


###########
# The keys for hashes are not sorted. In order to
# establish a canonical form for the  hash, sort
# the hash and convert it to an array with a two
# leading control elements in the array. 
#
# The elements determine if the data is an array
# or a hash and its reference.
#
sub arrayify
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($var) = shift @_;

     my $class = ref($var);
     return $var unless $class;

     my $reftype = attributes::reftype($var);
     $class = $class ne $reftype ? $class : '';
     my @array = ($class,$reftype);

     #####
     # Add rest of the members to the canoncial array
     # based on underlying data type
     # 
     if ( $reftype eq 'HASH') {
         foreach (sort keys %$var ) {
             push @array, ($_, $var->{$_});
         }
     }
     elsif($reftype eq 'ARRAY') {
         push @array, @$var;
     }
     elsif($reftype eq 'SCALAR') {
         push @array, $$var;
     }
     elsif($reftype eq 'REF') {
         push @array, $var;
     }
     elsif($reftype eq 'CODE') {
         push @array, $var;
     }
     elsif($reftype eq 'GLOB') {
         push @array,(*$var{SCALAR},*$var{ARRAY},*$var{HASH},*$var{CODE},
                          *$var{IO},*$var{NAME},*$var{PACKAGE},"*$var"),
     }
     else {
         warn "Unknown underlying data type\n";
         @array = '';
     }
     \@array;
}


######
# Program module wide configuration
#
sub config
{
     $default_options = Data::Secs2->new() unless $default_options;
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift :  $default_options;
     $self = ref($self) ? $self : $default_options;
     $self->Data::Startup::config(@_);

}


#######
# 
#
my %format = (
  L  =>  0x00, #  List (length in elements)
  B  =>  0x20, #  Binary
  T  =>  0x24, #  Boolean
  A  =>  0x40, #  ASCII
  J  =>  0x44, #  JIS-8
 S8  =>  0x60, #  8-byte integer (unsigned)
 S1  =>  0x62, #  1-byte integer (unsigned)
 S2  =>  0x64, #  2-byte integer (unsigned)
 S4  =>  0x70, #  4-byte integer (unsigned)
 F8  =>  0x80, #  8-byte floating
 F4  =>  0x90, #  4-byte floating
 U8  =>  0xA0, #  8-byte integer (unsigned)
 U1  =>  0xA4, #  1-byte integer (unsigned)
 U2  =>  0xA8, #  2-byte integer (unsigned)
 U4  =>  0xB0, #  4-byte integer (unsigned)
);




################
# This subroutine walks a nested data structure, and listify each level
# into a perlified SECII message. The assumption is that the nested 
# data structure consists of only references to Perl arrays, 
#
sub listify
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     $default_options = Data::Secs2->new() unless $default_options;
     my $self = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift :  $default_options;
     $self = ref($self) ? $self : $default_options;
     my %options = %$self; # try not to mangle or bless the default options

     #########
     # Return an array, so going to walk the array, looking
     # for hash and array references to arrayify
     #
     # Use a stack for the walk instead of recursing. Easier
     # to maintain when the data is on a separate stack instead
     # of the call (return) stack and only the pertient data
     # is stored on the separate stack. The return stack does
     # not grow. Instead the separate recurse stack grows.
     #
     my %dups = ();
     my @vars = ();
     my @index = ();

     #####
     # Perl format code
     my @secs_obj = ('U1','P');  
     my $i = 0;
     my @var = @_; # do not clobber @_ so make a copy
     my $var = \@var;
     my ($is_numeric,$format,$num,$ref,$ref_dup,@dup_index,$str);

     for(;;) {

        while($i < @$var) {

             ######
             # Index to the same reference structure in the nested data.
             # First number is the number of indices. The indices are
             # within each level of the nested listes.
             #
             $ref_dup = (ref($var->[$i])) ? "$var->[$i]"  : '';
             if( $dups{$ref_dup} ) {
                 ($format,$num) = Data::SecsPack->pack_num('I',$dups{$ref_dup}, $options{'Data::SecsPack'});
                 ($format,$num) = ('U1','') unless defined($format); # what else can we do
                 push @secs_obj, ('L', '3', 'A', '', 'A', 'Index', $format, $num);
                 $i++;
                 next;
             }

             if( $options{perl_secs_numbers} =~ /multicell/i) {

                 #####
                 # Try to convert to a pack numeric array.
                 if (ref($var->[$i]) eq 'ARRAY') {
                  
                     #####
                     # Quit very coarse filter that eliminates many numerics
                     #
                     $is_numeric = 1;
                     foreach (@{$var->[$i]}) {
                        if (ref($_) && ref($_) ne 'ARRAY') {
                            $is_numeric = 0;
                            last;
                        }
                        unless (defined $_ && $_ =~ /\s*\S+\s*/ ) {
                            $is_numeric = 0;
                            last;
                        }
                     }
                     if($is_numeric) {
                         ($format,$num,$str) = Data::SecsPack->pack_num('I',@{$var->[$i]}, $options{'Data::SecsPack'});
                         if(defined($format) && (!defined($str) || $str eq '')) {
                             push @secs_obj, $format, $num;
                             $i++;
                             next;
                         }
                     }
                 }
             }
    
             $var->[$i] = arrayify( $var->[$i] );
             $ref = ref($var->[$i]);

             ####
             # If $var->[$i] is a reference it is a reference to an array of
             # an underlying data type or object that is arrayified.
             #
             if ($ref) {

                 $dups{$ref_dup} = (scalar @secs_obj); # element in @secs_obj

                 ########
                 # Nest for an 'ARRAY' reference to the arrayified the refereceddata
                 #
                 # The listify subroutine uses @vars stacks to nest. When listify finds
                 # member of the current array that is a reference to another array,
                 # listify stops working on the current array. It save the position
                 # that it stop working by pushing a refenrence to the current array
                 # and the position (index), $i of the array reference onto the @vars
                 # stack. Listify will then start working on the new array. When all work
                 # on the new array is listify will pop the old $var array reference
                 # and array index $i off of the @vars stack and continue work on the
                 # old array.
                 #   
                 if($ref eq 'ARRAY' ) {
                  
                     ####
                     # Save info so listify can resume work on the old array
                     # 
                     push @vars, ($var,$i+1);

                     ####
                     # Start work on the new array
                     # 
                     $var = $var->[$i];
                     $i = 0;

                     #####
                     # Output a List element whose body is the number of
                     # members in the new array that listify is starting
                     # to work on.
                     # 
                     push @secs_obj, ('L', scalar @$var);
                     next;
                 }
             }

             ########
             # Otherwise, a pure simple scalar
             # 
             else {

                 #####
                 # An undefined is translated to SECSII data structure as L[0]
                 # 
                 if(defined $var->[$i]) {

                     ######
                     # Try for a single packed number type
                     #
                     ($format,$num) = Data::SecsPack->pack_num('I',$var->[$i], $options{'Data::SecsPack'});
                     if(defined($format)) {
                         push @secs_obj, $format, $num;
                     }
 
                     #####
                     # Else ascii  
                     else {
                         push @secs_obj, 'A', $var->[$i];
                     }
                 }
                 else {
                     push @secs_obj, 'L', 0;
                 }

             }
             $i++;
         }

         #####
         # At the end of the current array, so go back
         # working on any array whose work was interupted
         # to work on the current array.
         #
         last unless @vars;
         ($var,$i) = splice( @vars, -2, 2);

     }

     ########
     # Listified unpacked SECSII message
     # 
     \@secs_obj;

}


#######
# 
#
my @bin_format = (
  'L',   #  0 List (length in elements)
   '',   #  1
   '',   #  2
   '',   #  3
   '',   #  4
   '',   #  5
   '',   #  6
   '',   #  7
  'B',   #  8 Binary
  'T',   #  9 Boolean
   '',   # 10
   '',   # 11
   '',   # 12
   '',   # 13
   '',   # 14
   '',   # 15
  'A',   # 16 ASCII
  'J',   # 17 JIS-8
   '',   # 18
   '',   # 19
   '',   # 20
   '',   # 21
   '',   # 22
   '',   # 23
 'S8',   # 24 8-byte integer (unsigned)
 'S1',   # 25 1-byte integer (unsigned)
 'S2',   # 26 2-byte integer (unsigned)
   '',   # 27
 'S4',   # 28 4-byte integer (unsigned)
   '',   # 29
   '',   # 30
   '',   # 31
 'F8',   # 32 8-byte floating
   '',   # 33
   '',   # 34
   '',   # 35
 'F4',   # 36 4-byte floating
   '',   # 37
   '',   # 38
   '',   # 39
 'U8',   # 40 8-byte integer (unsigned)
 'U1',   # 41 1-byte integer (unsigned)
 'U2',   # 42 2-byte integer (unsigned)
   '',   # 43
 'U4',   # 44 4-byte integer (unsigned)
   '',   # 45
   '',   # 46
   '',   # 47
   '',   # 48
   '',   # 49
   '',   # 50
   '',   # 51
   '',   # 52
   '',   # 53
   '',   # 54
   '',   # 55
   '',   # 56
   '',   # 57
   '',   # 58
   '',   # 59
   '',   # 60
   '',   # 61
   '',   # 63
);




sub neuterify
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my $binary_secs = shift;

     $default_options = Data::Secs2->new() unless $default_options;
     my $options = $default_options->override(@_);

     my @secs_format_element = unpack('C3',$binary_secs);
     my @secs_obj = ();

     #####
     # Data format code S - Secsii  P - Perl
     my $obj_format_code = $options->{obj_format_code} if defined $options->{obj_format_code};
     if( $options->{$obj_format_code} ) {
         if(!$options->{add_obj_format_code} && $secs_format_element[0] == 165 
               && $secs_format_element[1] == 1 &&
               ($secs_format_element[2] == 80 || $secs_format_element[2] == 83)  ) {
                substr($binary_secs,2,1) = $options->{$obj_format_code};
         }
         else {
            @secs_obj = ('U1',$obj_format_code);
         }
     }

     use integer;     
     my ($format, $bytes_per_cell, $length_size, $length, $length_num);
     while($binary_secs) {

          #####
          # Decode format byte
          $format = unpack('C1',$binary_secs);
          $binary_secs = substr($binary_secs,1);
          $length_size = $format & 0x03;
          $format = $bin_format[($format & 0xFC) >> 2];
          unless($format) {
             return("Unknown SECSII format\n");
          }
          push @secs_obj,$format;

          #####
          # decode number of elements
          $bytes_per_cell = $format =~ /(\d)$/ ? $1 : 1;
          $length = substr($binary_secs,0,$length_size);
          $binary_secs = substr($binary_secs,$length_size);
          $length_num = Data::SecsPack->unpack_num('U1', $length, $options->{'Data::SecsPack'});
          unless(ref($length_num) eq 'ARRAY') {
             return("Bad length.");
          }
          $length_num = ${$length_num}[0];

          ######
          # Grab the elements
          if($format eq 'L') {
              push @secs_obj,$length_num;
          }
          elsif($length_num) {
              push @secs_obj,substr($binary_secs,0,$length_num);
              $binary_secs = substr($binary_secs,$length_num);  
          }
          else {
              push @secs_obj,'';
          }        
     }
     no integer;
     \@secs_obj;
}



#####
#
#
sub numberify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my $secs_obj = shift;

     $default_options = Data::Secs2->new() unless $default_options;
     my $options = $default_options->override(@_);

     my ($i,$number,$format);
     for ($i=0; $i < @{$secs_obj}; $i = $i +2) {
         if( $secs_obj->[$i] =~  /[SUF]\d/ || $secs_obj->[$i] eq 'T') {
             if( ref($secs_obj->[$i+1]) eq 'ARRAY' ) {
                 ($format, $number) = Data::SecsPack->pack_num( $secs_obj->[$i], @{$secs_obj->[$i+1]}, $options->{'Data::SecsPack'} );
                 return $number unless defined $format;
                 $secs_obj->[$i+1] = $number;
             }
         }
     }
     return '';
}


#####
#
#
sub perlify
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     ########
     # Listified unpacked SECSII message
     # 
     my $secs_obj = shift @_;
     $default_options = Data::Secs2->new() unless $default_options;
     my $options = $default_options->override(@_);

     my @nested_stack = ();

     my ($head, $body);
     my ($class, $type);

     #####
     # Establish root array with a count that goes on
     # until the $secs_obj is exhasted. 
     #
     my $new_var_p;
     my $count = -1;
     my @root_array = ('','ARRAY');
     my $nested_var_p = \@root_array;
     my (%dup,$position);

     $head = $secs_obj->[0];
     $body = $secs_obj->[1];
     unless ($head eq 'U1' && ($body eq 'P' || 
                ref($body) eq 'SCALAR' && $$body eq '80') ){
         return "Not a Perl SECS object\n";
     }

     my $i = 2;
     while($i < @{$secs_obj} ) {

         $head = $secs_obj->[$i++];
         $body = $secs_obj->[$i++];
         if( $head eq 'L') {

             if($body == 0) {
                push @$nested_var_p, undef;  
                $count--;
             }
             else {

                 return "Wrong format type for class\n" if 'A' ne $secs_obj->[$i++];
                 $class = $secs_obj->[$i++];
                 return "Wrong format type for type\n" if 'A' ne $secs_obj->[$i++];
                 $type = $secs_obj->[$i++];
                 return "No body for element\n" unless $i < @{$secs_obj};
                 if( $class eq '' && $type eq 'Index') {
                     $head = $secs_obj->[$i++];
                     unless( $head =~ /^U/  && $body == 3) {
                         return "Perl index item has wrong format code\n";
                     }
                     $body = $secs_obj->[$i++];
                     unless( $body eq 'ARRAY' ) {
                         $body = Data::SecsPack->unpack_num($head, $body, $options->{'Data::SecsPack'});
                         return $body unless ref($body) eq 'ARRAY';
                     }
                     return "Perl Index body must have only one cell\n" unless @$body == 1;
                     $new_var_p = $dup{$body->[0]};
                     push @$nested_var_p, $new_var_p;  
                     $count--;
                 }
                 else {

                     #######
                     # The position $i - 6 is the index into @secs_obj of the
                     # element $head 'L'. This is the position that appears in
                     # Perl 'L', 3, 'A', '','A','Index',U1, $position Index
                     # list element.
                     # 
                     $new_var_p = [$class,$type];
                     push @nested_stack,$nested_var_p, $count-1, $i - 6;
                     $nested_var_p = $new_var_p;
                     $count = $body-2;
                 }
             }
         }     
         elsif( $head =~ /^[AJB]/ ) {
             push @$nested_var_p,$body;
             $count--;
         }
         elsif($head =~ /^[TSUF]/ ) {

             unless( ref($body) eq 'ARRAY' ) {

                 $body = Data::SecsPack->unpack_num($head, $body, $options->{'Data::SecsPack'});

                 #####
                 # a scalar $body is error message
                 return $body unless ref($body) eq 'ARRAY'; 
             }

             #######
             # Note: PERL does not support multiple cell numbers.
             # Thus, strict PERL Secs Object, listified without the multicell
             # option will either have a scalar number or a full blown list:
             # L, x, 'U1 .. S8', one-cell-number,  ... 'U1 .. S8'  one-cell-number
             #
             # In that case, we are now in one of these single cell numerics.
             # The other case, would be a single cell under a multicell option
             # in which it is could or could not be a reference to an array.
             #
             if(@$body == 1) {
                 push @$nested_var_p,${$body}[0];
             }

             #########
             # Multicell scalar produced by multicell listification
             # that groups like numerics together to save format header
             # space. Push a reference to the numbeic Perl array.
             #
             else {
                 push @$nested_var_p,$body; 
             }
             $count--
         }
         else {
             return "Unknown format type\n";
         }

         #####
         # At the end of the current array, so go back
         # working on any array whose work was interupted
         # to work on the current array.
         #
         while(@nested_stack && $count <= 0) {
             last unless $count == 0;
             $new_var_p = perl_typify($nested_var_p);
             ($nested_var_p, $count, $position) = splice(@nested_stack,-3,3);
             push @$nested_var_p, $new_var_p;
             $dup{$position} = $new_var_p;
         }
     }
     $nested_var_p = perl_typify($nested_var_p);
     @$nested_var_p;
}


######
#
#
sub perl_typify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($array) = (@_);
  
     my @array = @$array;
     my $class = shift @array;
     my $reftype = shift @array;
     my $ref;

     #####
     # Add rest of the members to the canoncial array
     # based on underlying data type
     # 
     if ( $reftype eq 'HASH') {
         $ref = {@array};
     }
     elsif($reftype eq 'ARRAY') {
         $ref = \@array;
     }
     elsif($reftype eq 'SCALAR') {
         return "Bad scalar body\n" unless @array == 1;
         $ref = \$array[0];
     }
     elsif($reftype eq 'REF') {
         return "Bad ref body\n" unless @array == 1;
         $ref = $array[0];
     }
     elsif($reftype eq 'CODE') {
         return "Bad code body\n" unless @array == 1;
         $ref = $array[0];
     }
     elsif($reftype eq 'GLOB') {
         return "Bad glob body\n" unless @array == 8;
         $ref = \@array;
     }
     else {
         return "Unknown underlying data type\n";
     }
     $ref = bless $ref,$class if($class);
     return($ref);
}


####
# Take the listify Perl structure and convert it to
# a readable ASCII format.
#
sub secsify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my @secs_obj = @{shift @_};  # separate copy so do not clobber @_;

     $default_options = Data::Secs2->new() unless $default_options;
     my $options = ref($_[-1]) ? $default_options->override(pop @_) : $default_options ;

     my $spaces = $options->{spaces};
     $spaces = '  ' unless $spaces;
     my $indent = '';
     my $length = 0;

     my @level = ();

     my ($format, $element);
     my $string = '';

     while (@secs_obj) {

         $format = shift @secs_obj;
         if(@level && $level[-1] <= 0) {
             while (@level && $level[-1] <= 0) {pop @level};
             $indent = $options->{type} eq 'ascii' ? $spaces x scalar @level : '';
         }
         if ($format eq 'L') {
             $length = shift @secs_obj;
             $element = secs_elementify( $format . $length, $options );
             goto ERROR if ref($element);
             $string .= $indent . $element;
             $level[-1] -= 1 if @level;
             push @level, $length;
             $indent = $options->{type} eq 'ascii' ? $spaces x scalar @level : '';
             $length =  0;
         }
         elsif ($format =~ /[SUF]\d/) {
             $element = secs_elementify($format,shift @secs_obj, $options);
             goto ERROR if ref($element);
             $string .= $indent . $element;
             $level[-1] -= 1 if @level;
         }
         elsif ($format =~ /[AJBT]/) {
             $element = secs_elementify( $format, shift @secs_obj, $options);
             goto ERROR if ref($element);
             $string .= $indent . $element;
             $level[-1] -= 1 if @level;
         }
         else {           
             my $error = "Unknown format $format\n";
             $error = "# ERROR\n" . 'A[' . length($error) . '] ' . $error;
             $element = \$error;
             goto ERROR;
         }
         $string .= "\n" if substr($string, -1, 1) ne "\n" && $options->{type} =~ /asc/i;

     };

     ########
     # Stingified SECSII message of a Perl Nested Data
     # 
     return $string;

ERROR:
     $$element .= "\n" if substr($$element,-1,1) ne "\n";
     $string = "\n" . $string;
     $$element .= 'B[' . length($string) . "] " . $string;
     return $element;
   
}

####
# Used in this program module only by the secsify subroutine
#
sub secs_elementify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::Secs2->new() unless $default_options;

     ########
     # Two type of inputs:
     #   list element:  $format @options
     #   item element:  $format $cells @options
     #
     #
     my ($format, @cells) = @_;
     my $options = $default_options->override(pop @cells) if ref $cells[-1] ne 'ARRAY';
     my $cells = shift @cells;

     my $bytes_per_cell =  $format =~ /(\d)$/ ? $1 : 1;

     my ($length,$body_bytes);
     if($format =~ 'L(\d+)') {
        $format = 'L';
        $length = $1; 
        $body_bytes = $length; 
     }
     else {
         $body_bytes = length($cells);
         $length = $body_bytes / $bytes_per_cell; 
     }

     my $body;
     if($options->{type} eq 'ascii') {
         $body = $format . '[' . $length . ']' ;
         return $body unless $length; # do not get space after A[0]
         if ($format =~ /[SUF]\d/ || $format eq 'T') {
             if(ref($cells) eq 'ARRAY') {
                 $body .= ' ' . (join ' ' , @$cells);
             }
             else {
                 my $numbers = Data::SecsPack->unpack_num($format, $cells, $options->{'Data::SecsPack'});
                 unless(ref($numbers) eq 'ARRAY') {
                     my $error = '# ERROR\nA[' . length($numbers) . ']' . $numbers;
                     return \$error;
                 }
                 $body .= ' ' . (join ' ' , @$numbers);
             }
         }
         elsif ($format =~ /[AJB]/) {
             $body .= ($cells =~ /\n/) ? "\n" : ' ';
             $body .= $cells;
         } 
         elsif( $format !~ /[L]/ ) {
             my $error =  "Unknown format $format\n";
             $error = '# ERROR\nA[' . length($error) . ']' . $error;
             return \$error;
         }
     }
     else {
         my ($len_format,$len_num) = Data::SecsPack->pack_num('I', $body_bytes, $options->{'Data::SecsPack'});
         unless(defined($len_format) && $len_format =~ /^U/ ) {
             my $error =  "Element length number is not unsigned integer\n";
             return \$error;
         }
         my $len_size = length($len_num);
         unless($len_size < 4) {
             my $error = "Number of cells in the item is too big\n";
             return \$error;
         }
         $body = pack ("C1",($format{$format}+$len_size)) . $len_num;
         return $body if $format eq 'L' || $length == 0;
         if ($format =~ /[SUF]\d/ || $format eq 'T') {
             if(ref($cells) eq 'ARRAY') {
                 ($format, my $number) = Data::SecsPack->pack_num($format, @$cells, $options->{'Data::SecsPack'});
                 if(defined($format)) {
                     return $body . $cells;
                 }
                 else {
                     my $error = 'Could not pack number.\n';
                     return \$error;
                 }
             }
         }        
         $body .= $cells;
     }
     $body;
}

#####
# If the variable is not a scalar,
# stringify it.
#
sub stringify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     return $_[0] unless ref($_[0]) ||  1 < @_;
     secsify(listify(@_));

}

sub transify
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my $ascii_secs = shift;

     $default_options = Data::Secs2->new() unless $default_options;
     my $options = $default_options->override(@_);

     #####
     # Data format code S - Secsii  P - Perl
     my @secs_obj = ();
     my $obj_format_code = $options->{obj_format_code} if defined $options->{obj_format_code};
     if($options->{obj_format_code}) {
         unless( $options->{add_obj_format_code} ) {
             $ascii_secs =~ s/^\s*U1\s*(80|83)\s*\n?//s;
         }
         push @secs_obj,('U1',$options->{obj_format_code});
     }
    
     use integer;     
     my ($format, $byte_code, $bytes_per_cell, $length);
     my (@open_list, $list_location, $list_close_char, $item_count, $counted_list);
     my ($open_char, $close_char, $esc_esc, $str);
     $list_close_char = '';
     $list_location = 0;
     $item_count = 0;
     $counted_list = 0;
     my (@integers,$integer);
     $ascii_secs =~ s/^\s*//s;
     while($ascii_secs) {

          #####
          # Parse format code
          ($format,$byte_code) = ($1,$2) if $ascii_secs =~ s/^\s*(\S)(\d)?//;
          return "No format code\n\t$ascii_secs" unless($format);
          $bytes_per_cell = $byte_code;
          $bytes_per_cell = '' unless $bytes_per_cell;
          $item_count++;
          $bytes_per_cell = 1 unless $bytes_per_cell;

          ######
          # Look for number of elements in brackets jammed tight
          # against the format code. If not there then going to be
          # doing some parentheses type work.
          #
          $length = undef;          
          $length = $1 if $ascii_secs =~ s/^s*\[\s*(\d+)\s*\]//s;
          unless (defined $length) {
              $length = $1 if $ascii_secs =~ s/^\s*\,\s*(\d+)//s;
          }
          my $skip = 1;
          if(substr($ascii_secs,0,2) eq '\r\n' || substr($ascii_secs,0,2) eq '\n\r') {
              $skip = 2;    
          }
          $ascii_secs = substr($ascii_secs,$skip);

          ######
          # If length is specified, go with it.  
          # 
          if(defined $length) {
              if($format eq 'L') {
                  push @open_list,[$list_location,$list_close_char,$item_count,$counted_list] if $list_location;
                  $list_location = scalar @secs_obj + 1;
                  $item_count = 0;
                  $counted_list = $length;
                  $list_close_char = '';
                  $close_char = '';
                  push @secs_obj,$format,$length;
              }

              ####
              # Grab the length number of characters from input stream
              elsif($format =~ /^[JAB]$/) {
                  if(0 < $length) {
                      push @secs_obj,$format,substr($ascii_secs,0,$length);
                      $ascii_secs = substr($ascii_secs,$length);
                  }
                  else {
                      push @secs_obj,$format,'';  # length 0 
                  }
              }

              #####
              # Count the numbers, should agree with length 
              elsif ($format =~ /^[SUSFT]$/)  {
                  if(0 < $length) {
                       ($ascii_secs, @integers) = Data::SecsPack->str2int($ascii_secs);
                       $ascii_secs = ${$ascii_secs}[0] if ref($ascii_secs) eq 'ARRAY';
                       return "Wrong number of integers\n\t$ascii_secs" if($length != @integers);
                       push @secs_obj, Data::SecsPack->pack_int("$format$byte_code",@integers, $options->{'Data::SecsPack'});
                  }
                  else {
                      push @secs_obj,$format,'';  # length 0 
                  }
                 
              }
              else {
                  return "Unkown format $format\n";
              }

          }
       
          else {

              ######
              # Count the numbers
              if( $format =~ /^[UTISF]$/ ) {
                  ($format,$integer,$ascii_secs) = Data::SecsPack->pack_num("$format$byte_code",$ascii_secs,$options->{'Data::SecsPack'});
                  if(defined $format) {
                      push @secs_obj,$format,$integer;
                  }
                  else {
                      return "Integer could not be packed.";
                  }
              }

              elsif( $format =~ /^[LAJB]$/ ) {

                  ######
                  # Otherwise, look for parentheses type enclosing.  
                  # 
                  $open_char = $1 if $ascii_secs =~ s/^\s*(\S)//;
                  if($open_char eq '(') {
                      $close_char = ')';
                  }
                  elsif($open_char eq '[') {
                      $close_char = ']';
                  }
                  elsif($open_char eq '{') {
                      $close_char = '}';
                  }
                  elsif($open_char eq '<') {
                      $close_char = '>';
                  }
                  else {
                      $close_char = $open_char;
                  }

                  ####
                  # Need to save old list item count, list location, and start a new open list 
                  if($format eq 'L') {

                      ####
                      # Note: For open list, there must be L at the even location. Does $list_location
                      # for an open list must always be odd and never can be zero.
                      push @open_list,[$list_location,$list_close_char,$item_count,$counted_list] if $list_location; 
                      $list_location = scalar @secs_obj + 1;
                      $item_count = 0;
                      $counted_list = 0;
                      $list_close_char = $close_char;
                      $close_char = '';
                     push @secs_obj,$format,0;
                  }

                  ####
                  # Close a text string 
                  else {

                      $str = '';
                      use integer;
                      for(;;) { 
                          unless($ascii_secs =~ s/(.*?)\Q$close_char\E//s) {
                              return "No matching $close_char for $open_char\n\t$ascii_secs";
                          }
                          $str .= $1;
                          ($esc_esc) = $str =~ /(\\+)$/;

                          #####
                          # close_char escaped 
                          if($esc_esc && length($esc_esc) % 2) {
                              $str .= $close_char;
                          }

                          else {
                              last;
                          }
                      }                   
                      no integer;
                      $close_char = '';
                      push @secs_obj,$format,$str;
                  }
              }
              else  {
                  return "Unkown format $format\n";
              }
          }

          ######
          # Try closing any open list 
          while(($list_close_char && $ascii_secs =~ s/^\s*\Q$list_close_char\E//s) || 
              ($counted_list && $counted_list <= $item_count) ) {
              
              if($list_close_char && $counted_list ==0) {
                  $secs_obj[$list_location] = $item_count;
              }
              if(@open_list) {
                  ($list_location,$list_close_char,$item_count,$counted_list) = @{$open_list[-1]};
                  pop @open_list;
              }
              else {
                  $list_close_char = '';
                  $list_location = 0;
                  $item_count = 0;
                  $counted_list = 0;
                  $close_char = '';
              }
          }

          $ascii_secs =~ s/^\s*//s;

     }
     no integer;
     my $open_lists = scalar @open_list;
     $open_lists++ if $counted_list || $list_close_char;
     return "There are $open_lists open lists.\n" if $open_lists;
     \@secs_obj ;
}


#####
#
#
sub textify
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     my $secs_obj = shift;

     $default_options = Data::Secs2->new() unless $default_options;
     my $options = $default_options->override(@_);

     my ($i,$number);
     for ($i=0; $i < @{$secs_obj}; $i = $i +2) {
         if( $secs_obj->[$i] =~  /[SUF]\d/ || $secs_obj->[$i] eq 'T') {
             unless( ref($secs_obj->[$i+1]) eq 'ARRAY' ) {
                 $number = Data::SecsPack->unpack_num( $secs_obj->[$i], $secs_obj->[$i+1], $options->{'Data::SecsPack'} );
                 return $number unless ref($number) eq 'ARRAY';
                 $secs_obj->[$i+1] = $number;
             }
         }
     }
     return '';
}


1

__END__

=head1 NAME
  
Data::Secs2 - pack, unpack, format, transform from Perl data SEMI E5-94 nested data.

=head1 SYNOPSIS

 #####
 # Subroutine interface
 #  
 use Data::Secs2 qw(arrayify config listify neuterify numberify perlify 
                 perl_typify secsify secs_elementify stringify textify transify);

 \@array  = arrayify( $ref );

 $old_value = config( $option );
 $old_value = config( $option => $new_value);

 $body = secs_elementify($format, $cells);
 $body = secs_elementify($format, $cells, @options);
 $body = secs_elementify($format, $cells, [@options]);
 $body = secs_elementify($format, $cells, {optioins});

 \@secs_obj  = listify(@vars);

 \@secs_obj  = neuterify($binary_secs);
 \@secs_obj  = neuterify($binary_secs, @options);
 \@secs_obj  = neuterify($binary_secs, [@options]);
 \@secs_obj  = neuterify($binary_secs, {@options});

 $error = numberify( \@secs_obj );

 @vars  = perlify(\@secs_obj);

 $ref  = perl_typify(\@array);

 $ascii_secs = secsify( \@secs_obj);
 $ascii_secs = secsify( \@secs_obj, @options);
 $ascii_secs = secsify( \@secs_obj, [@options]);
 $ascii_secs = secsify( \@secs_obj, {@options});

 $binary_secs = secsify( \@secs_obj, type => 'binary');
 $binary_secs = secsify( \@secs_obj, type => 'binary', @options);
 $binary_secs = secsify( \@secs_obj, [type => 'binary',@options]);
 $binary_secs = secsify( \@secs_obj, {type => 'binary',@options});

 $string = stringify(@arg, [@options]);
 $string = stringify(@arg, {@options});

 \@secs_obj  = transify($acsii_secs);
 \@secs_obj  = transify($acsii_secs, @options);
 \@secs_obj  = transify($acsii_secs, [@options]);
 \@secs_obj  = transify($acsii_secs, {@options});

 $error  = textify( \@secs_obj );

 #####
 # Class, Object interface
 #
 # For class interface, use Data::Secs2 instead of $self
 # use Data::Secs2;
 #
 $secs2 = 'Data::Secs2'  # uses built-in config object

 $secs2 = new Data::Secs2( @options );
 $secs2 = new Data::Secs2( [@options] );
 $secs2 = new Data::Secs2( {options} );

 \@array  = secs2->arrayify( $ref );

 $old_value = secs2->secs_config( $option);
 $old_value = secs2->secs_config( $option => $new_value);

 $body = secs2->secs_elementify($format, $cells);
 $body = secs2->secs_elementify($format, $cells, @options);
 $body = secs2->secs_elementify($format, $cells, [@options]);
 $body = secs2->secs_elementify($format, $cells, {optioins});

 \@secs_obj  = secs2->listify(@vars);

 \@secs_obj  = secs2->neuterify($binary_secs);
 \@secs_obj  = secs2->neuterify($binary_secs, @options);
 \@secs_obj  = secs2->neuterify($binary_secs, [@options]);
 \@secs_obj  = secs2->neuterify($binary_secs, {@options});

 $error = secs2->numberify( \@secs_obj );

 @vars  = secs2->perlify(\@secs_obj);

 $ref  = secs2->perl_typify(\@array);

 $ascii_secs = secs2->secsify( \@secs_obj);
 $ascii_secs = secs2->secsify( \@secs_obj, @options);
 $ascii_secs = secs2->secsify( \@secs_obj, [@options]);
 $ascii_secs = secs2->secsify( \@secs_obj, {@options});

 $binary_secs = secs2->secsify( \@secs_obj, type => 'binary');
 $binary_secs = secs2->secsify( \@secs_obj, type => 'binary', @options);
 $binary_secs = secs2->secsify( \@secs_obj, [type => 'binary',@options]);
 $binary_secs = secs2->secsify( \@secs_obj, {type => 'binary',@options});

 $body = secs2->stringify( @arg );

 \@secs_obj  = secs2->transify($acsii_secs);
 \@secs_obj  = secs2->transify($acsii_secs, @options);
 \@secs_obj  = secs2->transify($acsii_secs, [@options]);
 \@secs_obj  = secs2->transify($acsii_secs, {@options});

 $error = secs2->textify( \@secs_obj );

=head1 DESCRIPTION

The 'Data::SECS2' module provides a widely accepted
method of packing nested lists into a linear string
and unpacking the string of nested lists. 
Nested data has a long history in mathematics.
In the hardware world, data and data passed between
hardware is not stored in SQL style tables but
nested lists. One widely used standard for transmitting
nested list between machines is SEMI E5-94.

The L<Data::Secs2|Data::Secs2> program module
facilitates the secsification of the nested data in accordance with 
L<SEMI|http://www.semiconductor-intl.org> E5-94,
Semiconductor Equipment Communications Standard 2 (SECS-II),
pronounced 'sex two' with gussto and a perverted smile. 
The SEMI E4 SECS-I standard addresses transmitting SECSII messages from one machine to
another machine serially via RS-232 RW-422 or whatever. And, there is
another SECS standard for TCP/IP, the SEMI E37 standard,
High-Speed SECS Message Services (HSMS) Generic Services.

In order not to plagarize college students,
credit must be given where credit is due.
Tony Blair, when he was a college intern at Intel Fab 4, in Manchester, England
invented the SEMI SECS standards.
When the Intel Fab 4 management discovered Tony's secsification of
their host and equipment, 
they called a board of directors meeting, voted,
and elected to have security to escort Tony out the door.
This was Mr. Blair's introduction to voting and elections which he
leverage into being elected prime minister of all of England. 
In this new position he used the skills he learned
at the Intel fab to secsify intelligence reports on Iraq's
weopons of mass distruction.

Using a well-known, widely-used standard for
packing and unpacking Perl nested data provides many different
new directions.
Not only is this standard essential in real-time communications in the factory
between equipment computers and operating systems and host computer
and operating system
but it has uses in snail-time computations.
In snail-time the standard's data structure is usefull
in nested data operations such as comparing nested data, 
storing the packed nested data in a file, 
and also for transmitting nested data 
from one Perl site to another or even between Perl
and other programming languages.

And do not forget the added benefit 
(or perhaps fault depending upon your point of view) 
of SEMI SECS humor
and that the real originators of the SECS-II yielded
and allowed Tony Blair to take illegal credit for 
inventing SECS-II.
After all the practical definition of politics is
getting your own way. 
Julius Ceasar invented the Julian calendar and the month of July,
Augustus Ceasar the month of Auguest,
Al Gore the information highway and
Tony Blair not only SECS-II but SECS-I and High-Speed SECS.

=head2 SECSII Format

The nested data linear format used by the
L<Data::Secs2|Data::Secs2> suroutines is in accordance with 
L<SEMI|http://http://www.semiconductor-intl.org> E5-94,
Semiconductor Equipment Communications Standard 2 (SECS-II),
pronounced 'sex two' with gussto and a perverted smile. 
This industry standard is copyrighted and cannot be
reproduced without violating the copyright.
However for those who have brought the original hard media
copy, there are robot help and Perl POD open source
copyrighted versions of the SECII hard copy copyrighted version available.
The base copyright is hard copy paper and PDF files available
from
 
 Semiconductor Equipment and Materials International
 805 East Middlefield Road,
 Mountain View, CA 94043-4080 USA
 (415) 964-5111
 Easylink: 62819945
 http://www.semiconductor-intl.org
 http://www.reed-electronics.com/semiconductor/

Other important SEMI standards address message transfer protocol of SECSII messages.
They are the SEMI E4 SECS-I for transmitting SECSII messages from one machine to
another machine via RS-232 and the SEMI E37 
High-Speed SECS Message Services (HSMS) Generic Services
for transmitting SECSII via TCP/IP.

In order not to plagarize college students,
credit must be given where credit is due.
Tony Blair, when he was a college intern at Intel Fab 4, in London
invented the SEMI SECS standards.
When the Intel Fab 4 management discovered Tony's secsification of
their host and equipment, 
they elected to have security to escort Tony out the door.
This was Mr. Blair's introduction to elections which he
leverage into being elected prime minister. 
In this new position he used the skills he learned
at the Intel fab to secsify intelligence reports on Iraq's
weopons of mass distruction.
 
The SEMI E5 SECS-II standard provides, among many other things,
a standard method of forming packed nested list data.
In accordance with SEMI E5 SECS-II transmitted information consists
of items and lists.
An item consists of the following: 

=over

=item 1

an item header(IH) with a format code,
and the number of bytes in the following body

=item 2

followed by the item body (IB) consisting of a number of elements. 

=back

A item (IB) may consist of zero bytes in which there are no body
bytes for that item. As established by SEMI E5-94, 6.2.2,

=over 4

=item 

consists of groups of data of the same representation
in order to save repeated item headers

=item integers

Most Significant Byte (MS) sent first

=item signed integers

signed integers are two's complement, MSB sent first

=item floating point numbers

IEEE 754, sign bit sent first

=item non-printing ASCII

equipment specific

=back

As specified in E4-95 6.3, a list element consists of an
ordered set of elements that are either an item element or a list element.
Because a list element may contains a list element, and SEMI E5 places
no restriction on the level of nesting, SECSII lists may
be nested to theoretically to any level. 
Practically nested is limited by machine resources. 
A list has the same header format as an item, no body and the length
number is the number of elements in the list instead of the number of
bytes in the body. 

The item and list header format codes are as in below Table 1 

               Table 1 Item Format Codes

 unpacked   binary  octal  hex   description
 ----------------------------------------
 L          000000   00    0x00  LIST (length of elements, not bytes)
 B          001000   10    0x20  Binary
 T          001001   11    0x24  Boolean
 A          010000   20    0x40  ASCII
 J          010001   21    0x44  JIS-8
 S8         011000   30    0x60  8-byte integer (signed)
 S1         011001   31    0x62  1-byte integer (signed)
 S2         011010   32    0x64  2-byte integer (signed)
 S4         011100   34    0x70  4-byte integer (signed)
 F8         100000   40    0x80  8-byte floating
 F4         100100   44    0x90  4-byte floating
 U8         101000   50    0xA0  8-byte integer (unsigned)
 U1         101001   51    0xA4  1-byte integer (unsigned)
 U2         101010   52    0xA8  2-byte integer (unsigned)
 U4         101100   54    0xB0  4-byte integer (unsigned)

Table 1 complies to SEMI E5-94 Table 1, p.94, with an unpack text 
symbol and hex columns added. The hex column is the upper 
Most Significant Bits (MSB) 6 bits
of the format code in the SEMI E5-94 item header (IH) or list header (LH)
with the the lower Least Significant BIt (LSB) set to zero.

Figure 1 below provides the layout for a SEMI E5-94 header 
and complies to SEMI E5-94 Figure 2, p. 92, except Figure 1 
renumbers the bits from 0 to 7 instead of  from 1 to 8.

                              bits                                    
   MSB                                                     LSB
   
    7        6       5       4       3       2      1       0
 +-------+-------+-------+-------+-------+-------+-------+-------+
 | Format code                                   |# length bytes | 
 +---------------------------------------------------------------+
 |MSB                MS length byte                         LSB  |
 +---------------------------------------------------------------+
 |                    length byte                                |
 +---------------------------------------------------------------+
 |                   LS length byte                              |
 +---------------------------------------------------------------+

                Figure 1 Item and List Header


=head2 SECS Object

This section establishes a formal definition of a SECS Object
and introduces technical definitions that supercede Webster
Dictionary definitions and only apply for the content of
this Program Module for the following:
SECS Object (SECS-OBJ), Element, Item Element (IE), 
List Element (LE), Element Header (EH), Element Format Code (EFC),
Element Body (EB) and Element Cells (EC).
If any of the technical definitions appear to have sexual innuendos,
it is entirely coincidental.  
The definitions should applied only on their technical merits.
Any other interperetation is totally unprofessional.

A SECS Object is a Perl C<ARRAY> that mimics the
SEMI E5-94 SECS-II, section 6, data structure where 
SECS-II transmitted bytes are layed out in memory.
The relation between between SEMI E5-94 "byte sent first" is that
"bytes sent first" will have the lowest byte address.

A SECS Object consists of consecutive ordered Elements stored
as a Perl C<ARRAY>.
Each Element takes two consistive positions
in the Perl <ARRAY>: the Element Header and the Element Body. 
The Element Headers positions are always even number indices where the Element Bodies
positions are always odd number indices. 

The EH consists of and only of a Element Format Code as specified in the
Table 1 Item Format Codes unpack column.

Elements may be either an Item Element or a List Element.
The Element Body for a List Element is the sum of the
nested List Elements and Item Elements in the List Element. 
The Element Body for a Item Element is a group of Element Cells of the
same data representation and bytes per Element Cell.
The bytes in an body of an Item Element is, thus, the number of cells in the
body times the bytes per Element Cell.
The Element Body for each Element Format Code is as follows:

=over 4

=item L
 
Unpacked sum of nested Element Lists and Element Items in the Element List

=item S U F T

a number cells either as a numberified Perl C<SCALAR> packed in accordance with SEMI E5-94
or a reference to textified (unpacked) Perl C<ARRAY> of numbers

=item A J

unpacked string

=item B

packed numberified Perl C<SCALAR> of binary bytes or a reference
to a Perl C<SCALLAR> of unpack textified binary in the hex
'H*' Perl format

In short, a Perl SECS Object consists of a LIST group of SECS elements,
INDEX group of elements, or SECSII item element as follows:

 LIST, INDEX, and SCALAR

 LIST => 'L', $number-of-elements, 
           'A', $class,
           'A', $built-in-class,
           @cells

 $cells[$i] may contain a LIST, INDEX or SCALAR)

 INDEX => 'L' '3', 'A', ' ', 'A' 'Index', 'U1', $position  
   
 SCALAR = $format, $scalar

where $format is any SECSII item element format code 
(no list element format codes allowed for SCALAR and
$position is a linear index of the Perl SECSII Object
array. In the Perl SECS Object INDEX, the 'U1' may
be 'U2', or 'U4'. The 'U8' format code will never occur
because SECSII messages cannot be that large. The
length byte is limited to three bytes.

=back

The first element of a SECS Object 
is always a SECS Object Format Code C<U1>
and a packed element body of either a
numberfied  'P' or 'S', textified 80 or 83, depending
upon whether the SECS Object has information necessary to convert
to Perl data structure, 'P', or most remain as a SECS Object, 'S'.

=head1 SUBROUTINES

=head2 arrayify

 \@array  = arrayify( $ref );

The purpose of the C<arrayify> subroutine is
to provide a canoncial array representation of 
Perl reference types. When C<$var> is
not a reference, the C<arrayify> subroutine passes
C<$var> through unchanged;
otherewise, the ref($ref) is changed to
a reference to a canoncial array where the
first member is the the C<$var> class,
the second member the underlying
data type. If ref($var) and the underlying 
type type are the same, 
then C<$var> is classless and 
the first member is the empty string ''.
The rest of the members of the canonical array,
based on the underlying data type, are as follows:

=over

=item 'HASH'

hash key, value pairs, sorted by the key

=item 'ARRAY'

members of the array

=item 'SCALAR'

the scalar

=item 'REF'

the reference

=item 'CODE'

the reference

=item 'GLOB'

values of the C<GLOB> in the
following order:

 *$var{SCALAR},
 *$var{ARRAY},
 *$var{HASH},
 *$var{CODE},
 *$var{IO},
 *$var{NAME},
 *$var{PACKAGE},
 "*$var"

=back

=head2 config

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

When Perl loads 
the C<Data::Secs2> program module,
Perl creates a
C<$Data::Secs2::default_options> object
using the C<new> method which 
inherits L<Data::Startup|Data::Startup>.

Using the C<config> as a subroutine 

 config(@_) 

writes and reads
the C<$Data::Secs2::default_options> object
directly using the L<Data::Startup::config|Data::Startup/config>
method.
Avoided the C<config> and in multi-threaded environments
where separate threads are using C<Data::Secs2>.
All other subroutines are multi-thread safe.
They use C<override> to obtain a copy of the 
C<$Data::Secs2::default_options> and apply any option
changes to the copy keeping the original intact.

Using the C<config> as a method,

 $options->config(@_)

writes and reads the C<$options> object
using the L<Data::Startup::config|Data::Startup/config>
method.
It goes without saying that that object
should have been created using one of
the following or equivalent:

 $default_options = $class->Data::Secs2::new(@_);
 $default_options = new Data::Secs2(@_);
 $options = $default_options->override(@_);

The underlying object data for the C<Data::Secs2>
class of objects is a hash. For object oriented
conservative purist, the C<config> subroutine is
the accessor function for the underlying object
hash.

Since the data are all options whose names and
usage is frozen as part of the C<Data::Secs2>
interface, the more liberal minded, may avoid the
C<config> accessor function layer, and access the
object data directly.

The options are as follows:
                                         values  
 subroutine         option               default 1sts
 ----------------------------------------------------------
 arrayify
 listify            perl_secs_numbers    'multicell','strict'

 neuterify          obj_format_code      '', 'S','P'
                    add_obj_format_code  0

 numberify
 perlify            
 perl_typify

 secsify            spaces               '  ', ' ' x n
                    type                 'ascii','binary

 secs_elementify    type                 'ascii','binary
 stringify
 textify

 transify           obj_format_code      '', 'S','P' 
                    add_obj_format_code  0


=head2 listify

 \@secs_obj  = listify(@vars);

The C<listify> subroutine takes a list of Perl variables, C<@arg>
that may contain references to nested data and 
converts it to a <L<SECS Object|Data::Secs2/SECS Object>  
that mimics a SECSII data structure of a linearized
list of items. The Secs Object has Secs Object format
code P' since it contains all the information necessary
to contruct a Perl data structure.

Information is included to recontruct Perl hashes, arrays
and objects by provided two item header for each Perl
data type. The first item is the object class which is
empty for Perl hashes and arrays and the second item
is the Perl underlying data type.
Valid Perl underlying data types are: HASH ARRAY
SCALAR REF GLOB.

The C<listify> subroutine walks the Perl data structure.
Undefineds are converted to a SECS-II to empty list element 
L[0]. Scalars are tested for numbers. If the C<listify>
subroutine finds a scalar is a number, it converts it to a
SECS-II U1 U2 U4 U8 S1 S2 S4 S8 F4 F8 item element 
with the preference in the order the formats are
listed; otherwise the scalar is converted to a A
SECS-II item element.
When the C<listify> subroutine finds a reference it
applies the C<arrayify> subroutine and converts
it to a SECS-II list element with the array members
as item or list elements of the SECS-II list element.

The C<listify> subroutine has the ability to produce
multicell numerics or the standard Perl single cell numerics
as determined by the startup C<$option->{perl_secs_numbers}>. 
This option may be set with the C<new> subroutine or the
C<config> subroutine since the C<listify> has no inputs
for options. With the multicell numerics, the arrays with
a single scalar will be converted back to Perl by
the C<pearlify> subroutine as a scalar. 
The tradeoff is, thus, a compact SECS-II data structure
that makes use of multicell numerics or maintaining
the ability to convert back to exactly the same Perl
data structure.
                
The output for the C<lisify> subroutine
is a Secs Object that complies to the
L<SECS Object||Data::Secs2/Secs Object> established herein above.

=head2 neuterify

 \@secs_obj  = neuterify($binary_secs);
 \@secs_obj  = neuterify($binary_secs, @options);
 \@secs_obj  = neuterify($binary_secs, [@options]);
 \@secs_obj  = neuterify($binary_secs, {@options});

The C<neuterify> subroutine produces
a C<@secs_obj> from a SEMI E5-94 packed
data structure C<$binary_secs> and produces
a SECS object C<@secs_obj>.

The C<neuterify> subroutine uses option C<{obj_format_code => 'P'}>, 
or C<{obj_format_code => 'S'}> as the value for the leading
L<SECS Object|Data::Secs2/SECS Object>  U1 format byte.
SEMI E5-94 SECII item. If the C<neuterify> subroutine receives the
option C<{add_obj_format_code}>, C<neuterify> will add the
byte to the beginning of the packed data; otherwise, 
C<neuterify> probes the leading byte of the packed data.
If the probes shows the leading byte is a C<Secs Object Format Code>,
C<neuterify> modifies the packed data byte; otherweise it adds the byte
to the beginning of the packed data.

The return is either a reference to a  
L<SECS Object|Data::Secs2/L<SECS Object|Data::Secs2/SECS Object> > 
or case of an error an error message.
To determine an error from a L<SECS Object|Data::Secs2/SECS Object> ,
check if the return is a reference or
a reference to an ARRAY.

=head2 new

 $secs2 = new Data::Secs2( @options );
 $secs2 = new Data::Secs2( [@options] );
 $secs2 = new Data::Secs2( {options} );

The C<new> subroutine provides a method set local options
once for any of the other subroutines. 
The options may be modified at any time by
C<$secs2->config($option => $new_value)>.
Calling any of the subroutines as a
C<$secs2> method will perform that subroutine
with the options saved in C<secs2>.

=head2 numberify

 $error = numberify( \@secs_obj );

The C<numberify> subroutine ensures that
all the bodies in a
L<SECS Object|Data::Secs2/SECS Object> 
for numeric items,
format U, S, F, T, are scalar strings
packed in accordance with SEMI E5-94.

=head2 perlify subroutine

 @vars = perlify( \@secs_obj );

The C<perlify> subroutine converts a 
L<SECS Object|Data::Secs2/SECS Object> 
with a SECS Object Format Code of 'P'
into Perl variables.
SECS Objests a format code 'P' should
contain all the information necessary
to reconstruct listified Perl Data Structure.

=head2 perl_typify

 $ref  = perl_typify(\@array);

The C<perl_typify> subroutine converts an C<@array> produced
by the C<arrayify> subroutine from a C<$ref> back to a 
C<$ref>.

=head2 secsify subroutine

 $ascii_secs = secsify( \@secs_obj);
 $ascii_secs = secsify( \@secs_obj, @options);
 $ascii_secs = secsify( \@secs_obj, [@options]);
 $ascii_secs = secsify( \@secs_obj, {@options});

 $binary_secs = secsify( \@secs_obj, type => 'binary');
 $binary_secs = secsify( \@secs_obj, type => 'binary', @options);
 $binary_secs = secsify( \@secs_obj, [type => 'binary',@options]);
 $binary_secs = secsify( \@secs_obj, {type => 'binary',@options});

The C<secsify> subroutine processes each element in
a SECS Object producing either an C<$ascii_sec> text string or
a SEMI E5 packed C<$binary_secs> text string.
The C<secsify> subroutine does not care if the C<@secs_obj> is
a Perl SECS Object or just a plain or SECS Object.
For the C<$ascii_sec> output, the C<secsify> subroutine
produces one line of text for each SECS element, indenting
the line C<$options->{spaces}> consist with each level
of list nesting.

The C<secsify> subroutine uses the C<secs_elementify> subroutine
to form the SECSII elements and passes its options 
to the C<secs_elementify> subroutine.

In case of an error, the return is an reference 
a error message.

=head2 secs_elementify

 $body = secs_elementify($format, $cells);
 $body = secs_elementify($format, $cells, @options);
 $body = secs_elementify($format, $cells, [@options]);
 $body = secs_elementify($format, $cells, {options});

The C<secs_elementify> subroutine is the low-level work horse
for the C<secsify> subroutine that
produces a SEMI SECSII item C<$body> from a Perl
L<SECS Object|Data::Secs2/SECS Object>  item header C<$format> and item body C<@cells>.

For {type => 'binary'}, $body is a packed
SEMI E5-94 SECII element.
For {type => 'ascii'} or no type option, the C<$body> 
is the ascii unpacked SECSII element.
The return is either a reference to a  
L<SECS Object|Data::Secs2/L<SECS Object|Data::Secs2/SECS Object> > 
or case of an error an error message.
To determine an error from a L<SECS Object|Data::Secs2/SECS Object> ,
check if the return is a reference or
a reference to an ARRAY.

=head2 stringify subroutine

The C<stringify> subroutined stringifies a Perl data structure
by applying the C<listify> and C<secify> subroutines.

=head2 transify

 \@secs_obj  = transify($acsii_secs);
 \@secs_obj  = transify($acsii_secs, @options);
 \@secs_obj  = transify($acsii_secs, [@options]);
 \@secs_obj  = transify($acsii_secs, {@options});

The C<transify> subroutine takes a free style
text consisting of list of secsii items and
converts it to L<SECS Object|Data::Secs2/SECS Object>.
The C<transify> subroutine is very liberal
in what it accepts as valid input. 

The number of body elements
may be supplied either as enclosed in brackets
of a "comma" after the unpacked format code.
Text strings may be enclosed in parentheses,
brackets, or any other character. 

The enclosing ending character may be
escaped with the backslash '\'.
List may be counted by suppling a count
in either brackets or following a comma
after the 'L' format character or
by enclosing parentheseses, bracketers or
any other character.

The C<transify> subroutine uses option C<{obj_format_code => 'P'}>, 
or C<{obj_format_code => 'S'}> as the value for the leading
L<SECS Object|Data::Secs2/SECS Object>  U1 format byte.
SEMI E5-94 SECII item. If the C<transify> subroutine receives the
option C<{add_obj_format_code}>, C<transify> will add the
a C<Secs Object Format Code> to the beginning of the C<@secs_obj>; otherwise, 
C<transify> probes the leading C<@secs_obj>.
If the probes shows the leading byte is a C<Secs Object Format Code>,
C<transify> modifies the code; otherweise it a C<Secs Object Format Code>
to the beginning of the C<@secs_obj>

The return is either a reference to a  
L<SECS Object|Data::Secs2/L<SECS Object|Data::Secs2/SECS Object> > 
or case of an error an error message.
To determine an error from a L<SECS Object|Data::Secs2/SECS Object> ,
check if the return is a reference or
a reference to an ARRAY.

=head2 textify

 $error = textify( \@secs_obj );

The C<textify> subroutine ensures that
all the bodies in a
L<SECS Object|Data::Secs2/SECS Object> 
for numeric items,
format U, S, F, T, are references
to an array of numbers.

=head1 REQUIREMENTS

The requirements are coming.

=head1 DEMONSTRATION

 #########
 # perl Secs2.d
 ###

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

 =>     use Data::Secs2 qw(arrayify config listify neuterify numberify perlify 
 =>          perl_typify secsify secs_elementify stringify textify transify);

 =>     my $uut = 'Data::Secs2';
 =>     my $loaded;

 => my $test_data1 =
 => 'U1[1] 80
 => L[5]
 =>   A[0]
 =>   A[5] ARRAY
 =>   U1[1] 2
 =>   A[5] hello
 =>   U1[1] 4
 => ';

 => my $test_data2 =
 => 'U1[1] 80
 => L[6]
 =>   A[0]
 =>   A[4] HASH
 =>   A[4] body
 =>   A[5] hello
 =>   A[6] header
 =>   A[9] To: world
 => ';

 => my $test_data3 =
 => 'U1[1] 80
 => U1[1] 2
 => L[4]
 =>   A[0]
 =>   A[5] ARRAY
 =>   A[5] hello
 =>   A[5] world
 => U2[1] 512
 => ';

 => my $test_data4 =
 => 'U1[1] 80
 => U1[1] 2
 => L[6]
 =>   A[0]
 =>   A[4] HASH
 =>   A[6] header
 =>   L[6]
 =>     A[11] Class::None
 =>     A[4] HASH
 =>     A[4] From
 =>     A[6] nobody
 =>     A[2] To
 =>     A[6] nobody
 =>   A[3] msg
 =>   L[4]
 =>     A[0]
 =>     A[5] ARRAY
 =>     A[5] hello
 =>     A[5] world
 => ';

 => my $test_data5 =
 => 'U1[1] 80
 => L[6]
 =>   A[0]
 =>   A[4] HASH
 =>   A[6] header
 =>   L[6]
 =>     A[11] Class::None
 =>     A[4] HASH
 =>     A[4] From
 =>     A[6] nobody
 =>     A[2] To
 =>     A[6] nobody
 =>   A[3] msg
 =>   L[4]
 =>     A[0]
 =>     A[5] ARRAY
 =>     A[5] hello
 =>     A[5] world
 => L[6]
 =>   A[0]
 =>   A[4] HASH
 =>   A[6] header
 =>   L[3]
 =>     A[0]
 =>     A[5] Index
 =>     U1[1] 10
 =>   A[3] msg
 =>   L[3]
 =>     A[0]
 =>     A[5] ARRAY
 =>     A[4] body
 => ';

 => my $test_data6 = [ [78,45,25], [512,1024], 100000 ];

 => my $test_data7 = 'a50150010541004105' . unpack('H*','ARRAY') . 
 =>                  'a5034e2d19' .  'a90402000400' . 'b104000186a0';

 => #######
 => # multicell numberics, Perl Secs Object
 => #
 => my $test_data8 =
 => 'U1[1] 80
 => L[5]
 =>   A[0]
 =>   A[5] ARRAY
 =>   U1[3] 78 45 25
 =>   U2[2] 512 1024
 =>   U4[1] 100000
 => ';

 => #######
 => # Strict Perl numberics, Perl Secs Object
 => #
 => my $test_data9 =
 => 'U1[1] 80
 => L[5]
 =>   A[0]
 =>   A[5] ARRAY
 =>   L[5]
 =>     A[0]
 =>     A[5] ARRAY
 =>     U1[1] 78
 =>     U1[1] 45
 =>     U1[1] 25
 =>   L[4]
 =>     A[0]
 =>     A[5] ARRAY
 =>     U2[1] 512
 =>     U2[1] 1024
 =>   U4[1] 100000
 => ';

 => ##################
 => # stringify an array
 => # 
 => ###

 => stringify( '2', 'hello', 4 )
 'U1[1] 80
 U1[1] 2
 A[5] hello
 U1[1] 4
 '

 => ##################
 => # stringify a hash reference
 => # 
 => ###

 => stringify( {header => 'To: world', body => 'hello'})
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[4] body
   A[5] hello
   A[6] header
   A[9] To: world
 '

 => ##################
 => # ascii secsify lisfication of test_data1 an array reference
 => # 
 => ###

 => secsify( listify( ['2', 'hello', 4] ) )
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[1] 2
   A[5] hello
   U1[1] 4
 '

 => ##################
 => # ascii secsify lisfication of test_data3 - array with an array ref
 => # 
 => ###

 => secsify( listify( '2', ['hello', 'world'], 512 ) )
 'U1[1] 80
 U1[1] 2
 L[4]
   A[0]
   A[5] ARRAY
   A[5] hello
   A[5] world
 U2[1] 512
 '

 => my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'
 bless( {
                  'From' => 'nobody',
                  'To' => 'nobody'
                }, 'Class::None' )

 => ##################
 => # ascii secsify lisfication of test_data5 - hash with nested hashes, arrays, common objects
 => # 
 => ###

 =>     secsify( listify( {msg => ['hello', 'world'] , header => $obj }, 
 =>      {msg => [ 'body' ], header => $obj} ) )
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[3]
     A[0]
     A[5] Index
     U1[1] 10
   A[3] msg
   L[3]
     A[0]
     A[5] ARRAY
     A[4] body
 '

 => ##################
 => # ascii secsify listifcation perilification transfication of test_data4
 => # 
 => ###

 => secsify( listify(perlify( transify($test_data4 ))) )
 'U1[1] 80
 U1[1] 2
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 '

 => ##################
 => # ascii secsify listifcation perilification transfication of test_data5
 => # 
 => ###

 => secsify( listify(perlify( transify($test_data5))) )
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[3]
     A[0]
     A[5] Index
     U1[1] 10
   A[3] msg
   L[3]
     A[0]
     A[5] ARRAY
     A[4] body
 '

 => ##################
 => # binary secsify an array reference
 => # 
 => ###

 => my $big_secs2 = unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary'}))
 'a501500105410041054152524159a50102410568656c6c6fa50104'

 => ##################
 => # binary secsify numeric arrays
 => # 
 => ###

 => $big_secs2 = unpack('H*',secsify( listify( $test_data6 ), {type => 'binary'}))
 'a501500105410041054152524159a5034e2d19a90402000400b104000186a0'

 => ##################
 => # neuterify a big secsii
 => # 
 => ###

 => secsify(neuterify (pack('H*',$big_secs2)))
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[3] 78 45 25
   U2[2] 512 1024
   U4[1] 100000
 '

 => ##################
 => # neuterify a multicell binary Perl SECS obj
 => # 
 => ###

 => secsify(neuterify (pack('H*',$test_data7)))
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[3] 78 45 25
   U2[2] 512 1024
   U4[1] 100000
 '

 => ##################
 => # transify a free for all secsii input
 => # 
 => ###

 =>     my $ascii_secsii =
 => '
 => L
 => (
 =>   A \'\' A \'HASH\' A \'header\'
 =>   L [ A "Class::None"  A "HASH" 
 =>       A  "From" A "nobody"
 =>       A  "To" A "nobody"
 =>     ]
 =>   A "msg"
 =>   L,4 A[0] A[5] ARRAY
 =>     A  "hello" A "world"
 => )

 => L 
 => (
 =>   A[0] A "HASH"  A /header/
 =>   L[3] A[0] A \'Index\' U1 10
 =>   A  \'msg\'
 =>   L < A[0] A \'ARRAY\' A  \'body\' >
 => )

 => '
 => my $list = transify ($ascii_secsii, obj_format_code => 'P');
 => ref($list)
 'ARRAY'

 => ##################
 => # secsify transifed free style secs text
 => # 
 => ###

 => ref($list) ? secsify( $list ) : ''
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[3]
     A[0]
     A[5] Index
     U1[1] 10
   A[3] msg
   L[3]
     A[0]
     A[5] ARRAY
     A[4] body
 '

 => ##################
 => # strict Perl listify numberic arrays
 => # 
 => ###

 => ref(my $number_list = Data::Secs2->new(perl_secs_numbers => 'strict')->listify( $test_data6 ))
 'ARRAY'

 => ##################
 => # secify strict Perl  listified numberic arrays
 => # 
 => ###

 => secsify($number_list)
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   L[5]
     A[0]
     A[5] ARRAY
     U1[1] 78
     U1[1] 45
     U1[1] 25
   L[4]
     A[0]
     A[5] ARRAY
     U2[1] 512
     U2[1] 1024
   U4[1] 100000
 '

 => ##################
 => # multicell listify numberic arrays
 => # 
 => ###

 => ref($number_list = listify( $test_data6 ))
 'ARRAY'

 => ##################
 => # secify multicell listified numberic arrays
 => # 
 => ###

 => secsify($number_list)
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[3] 78 45 25
   U2[2] 512 1024
   U4[1] 100000
 '

 => ##################
 => # read configuration
 => # 
 => ###

 => config('perl_secs_numbers')
 'multicell'

 => ##################
 => # write configuration
 => # 
 => ###

 => config('perl_secs_numbers','strict')
 'multicell'

 => ##################
 => # verifiy write configuration
 => # 
 => ###

 => config('perl_secs_numbers')
 'strict'

 => ##################
 => # restore configuration
 => # 
 => ###

 => config('perl_secs_numbers','multicell')
 'strict'

 => ##################
 => # textify listified list of number arrays
 => # 
 => ###

 => textify($number_list)
 ''

 => ##################
 => # verify 1st textified item element body
 => # 
 => ###

 => [@{$number_list->[9]}]
 [
           '78',
           '45',
           '25'
         ]

 => ##################
 => # verify 2nd textified item element body
 => # 
 => ###

 => [@{$number_list->[11]}]
 [
           '512',
           '1024'
         ]

 => ##################
 => # verify 3rd textified item element body
 => # 
 => ###

 => [@{$number_list->[13]}]
 [
           '100000'
         ]

 => ##################
 => # numberify listified list of number arrays
 => # 
 => ###

 => numberify($number_list)
 ''

 => ##################
 => # verify 1st numberified item element body
 => # 
 => ###

 => unpack('H*', $number_list->[9])
 '4e2d19'

 => ##################
 => # verify 2nd numberified item element body
 => # 
 => ###

 => unpack('H*', $number_list->[11])
 '02000400'

 => ##################
 => # verify 3rd numberified item element body
 => # 
 => ###

 => unpack('H*', $number_list->[13])
 '000186a0'


=head1 QUALITY ASSURANCE

Running the test script C<Secs2.t> verifies
the requirements for this module.

The <tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<secs2.t> test script, C<secs2.d> demo script,
and C<t::Data::Secs2> STD program module POD,
from the C<t::Data::Secs2> program module contents.
The  C<t::Data::Secs2> program module
is in the distribution file
F<Data-Secs2-$VERSION.tar.gz>.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyright © 2003 2004 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
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

=head1 SEE ALSO

=over 4

=item L<Data::SecsPack|Data::SecsPack> 

=item L<Docs::Site_SVD::Data_Secs2|Docs::Site_SVD::Data_Secs2>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of file ###