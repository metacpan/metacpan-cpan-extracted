#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
# see POD documentation at end
#
package Tie::FormA;

use strict;
use warnings;
use warnings::register;
use 5.001;


use vars qw($VERSION $DATE);
$VERSION = '0.02';
$DATE = '2004/06/03';

use Data::Startup 0.08;
use Tie::Layers 0.06 qw(is_handle);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Tie::Layers Exporter);
@EXPORT_OK = qw(is_handle encode_field decode_field
                encode_record decode_record);

my $default_options;

######
# Configuration
#
sub config
{
     $default_options = defaults() unless $default_options;
     my $options; 
     if( UNIVERSAL::isa($_[0],__PACKAGE__) ) {
         my $self = shift;
         $options = $self->{'Tie::FormA'}->{options};
     }
     elsif( ref($_[0]) eq 'HASH' ) {
         $options = shift;  
     }
     else {
         $options = $default_options;
     }
     Data::Startup::config($options,@_);
}

#######
# Object used to set default, startup, options values.
#
sub defaults
{
   my $class =  UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : '';
   my %options = (
       warn => 1,  
       EON => ":",        # end of name
       EOD => "^",        # end of data
       EOR => "\~-\~",  # record separator
       strict => 0,
       query_ready => 1,
   );
   my $options = Data::Startup::override(\%options,@_);
   $options = bless $options, $class if $class;
   $options;      
}



#######
# Object used to set default, startup, options values.
#
sub new
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = {};
   $self->{'Tie::FormA'}->{options} = defaults(@_); 
   bless $self,$class;
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
     $class = ref($class) if ref($class);
     my $self = bless {}, $class;
     $self->{'Tie::FormA'}->{options} = defaults(@_);

     #######
     # parse layers options
     # 
     my $layers_options = $self->{'Tie::FormA'}->{options}->{'Tie::Layers'};
     delete $self->{'Tie::FormA'}->{options}->{'Tie::Layers'};
     $layers_options = {} unless $layers_options;
     $layers_options->{print_layers} = [
         \&encode_record,
         \&encode_field,
     ];
     $layers_options->{read_layers}  = [
         \&decode_record,
         \&decode_field,
     ];
     $layers_options->{read_record} = \&read_record;
     $self->Tie::Layers::TIEHANDLE( $layers_options );
}


###########
###########
# 
# The following code is the field encoding and decoding layer 2
#
##########
##########


#####
# 
# encodes a field 
#
#
sub encode_field
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::FormA->new();

    my ($fields) = @_;
    unless( $fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }

    my $EON = $self->{'Tie::FormA'}->{options}->{EON};
    my $EOD = $self->{'Tie::FormA'}->{options}->{EOD};

    my( $name, $data, $encoded_fields);
    for( my $i=0; $i < @$fields; $i += 2) {

        ($name, $data) = ($fields->[$i], $fields->[$i+1]);

        if( $name =~ /[\x00-\x1f]/ ) {
            $name =~ s/[\x00-\x1f]/*/g;
            $self->{current_event} = ( "The field name contains ASCII control characters:\n\t$name" );
            goto EVENT;
        }
 
        $data = '' unless defined $data;  # handle undefs as empty strings 

        ######
        # Escape the $EON character by adding one more character
        #    
        $name =~ s/(\:+)/:$1/g;

        ######
        # need space to escape $EON. The space will not become part of the field 
        # The space will be stripped because leading and trailing spaces are not allowed.
        $name .= ' ' if substr( $name, -1, 1) eq $EON; 

        #######
        # Use single line field encoding or multiple line encoding
        #
        my ($field,$encoded_field);
        if( ($data !~ /[\x00-\x1f]/) && (length($data) + length($name) < 120) ) {
            $field = "$name${EON} $data";
            $field =~ s/(\^+)/\^$1/g;  # escape $EOD by adding one more
       
            #########
            # In strict mode the character in front of the $EOD is part of
            # the sequence and will not become part of field
            #  
            if( $self->{'Tie::FormA'}->{options}->{strict} ) {
                $field .= ' ';
            }
            else {

                ##########
                # need space to escape $EOD, however the space will become part of the field
                # This makes the lenient format ambiguous as to whether the space should
                # or should not be part of the field data
                # 
                $field .= ' ' if substr($field, -1, 1) eq $EOD; 

            } 
            $encoded_fields .= "$field${EOD}\n" # single line encoding
        }
        else {
            $field = "$name${EON}\n$data";
            $field =~ s/(\^+)/\^$1/g;    # escape $EOD by adding one more
            $encoded_fields .= "\n$field\n${EOD}\n\n"; # multiple line encoding
        }

    }

    return \$encoded_fields;

EVENT:
     if($self->{'Tie::FormA'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::FormA::encode_field() $VERSION\n";
     $self->{current_event};
}


##########
# Parse a email record into a field harsh
#
sub decode_field
{ 
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::FormA->new();

    my ($encoded_fields) = @_;
    unless( $encoded_fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $EON = $self->{'Tie::FormA'}->{options}->{EON};
    my $EOD = $self->{'Tie::FormA'}->{options}->{EOD};

    ##########
    # Place the fields in the db into a hash, %$record,
    # where the field name is the hash key.
    # 

    #######
    # Try to patch up where there is no last field delimiting [^\^]\^[^\^]
    #
    $$encoded_fields =~ s/[ \x00-\x1f]*$//;  # drop trailing white space
    unless( $$encoded_fields =~ /[^\^]\^$/ ) {
        $$encoded_fields .= ' ' unless ( $$encoded_fields =~ /\^$/ );        
        $$encoded_fields .= '^';
    }
    $$encoded_fields .= "\n";
 
    #########
    # The ending negated : and begining negated ^ cannot be the same character
    # for generic simple decode statement to work, so insert a space for 
    # the ending negated :
    #
    $$encoded_fields =~ s/([^:]:)(\^[^\^])/$1  $2/g; 
    $$encoded_fields =~ s/([^:]:)([^:\^]\^[^\^])/$1 $2/g; 
    my @fields;
    if( $self->{'Tie::FormA'}->{options}->{strict} ) {
        (@fields) = $$encoded_fields =~  /(.*?[^:]):[^:](.*?)[^\^]\^[^\^]/sg;
    }
    else {
        (@fields) = $$encoded_fields =~  /(.*?[^:]):[^:](.*?[^\^])\^[^\^]/sg;

    }
    for( my $i=0; $i < @fields; $i += 2 ) {
        $fields[$i] =~ s/:(:+)/$1/g;        # unescape EON
        $fields[$i] =~ s/\^(\^+)/$1/g;      # unescape EOD
        $fields[$i+1] =~ s/\^(\^+)/$1/g;    # unescape EOD

        ######
        # Could keep picking up \n as part of negated separation char in lenient format
        $fields[$i+1] =~ s/^[\012\015]*(.*?)[ \x00-\x1f]*$/$1/s unless $self->{'Tie::FormA'}->{options}->{strict};

        ##### 
        # no leading or trailing white space, ASCII controls characters allowed in field names
        $fields[$i] =~ s/^[ \x00-\x1f]*(.*?)[ \x00-\x1f]*$/$1/; 
        $fields[$i] =~ s/[\x00-\x1f]/_/g; # no ASCII control characters in name
    }
 
    return \@fields;

EVENT:
     if($self->{'Tie::FormA'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::FormA::encode_field() $VERSION\n";
     $self->{current_event};
}



###########
###########
# 
# The following code is the record encoding and decoding layer 1
#
##########
##########


#########
# This function un escapes the record separator
#
sub decode_record
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::FormA->new();

    my ($record) = @_;
    unless( $record ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $EOR = $self->{'Tie::FormA'}->{options}->{EOR};

    my $encoded_fields = $$record;


    $encoded_fields =~ s/$EOR$//;

    ####### 
    # unescape $EOR by taking away one - .
    #
    # "~--~"  => "~-~"
    # "~---~  => "~--~"
    # "~----~ => "~---~"
    #
    $encoded_fields =~ s/~-(-+)~/~$1~/g;

    #######
    # Unless in strict mode, change CR and LF
    # to end of line string for current operating system
    #
    unless( $self->{options}->{binary} ) {
        $encoded_fields =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
        $encoded_fields =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
    }
    return \$encoded_fields;

EVENT:
     if($self->{'Tie::FormA'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::FormA::decode_record() $VERSION\n";
     $self->{current_event};
}



#############
# encode the record
#
sub encode_record
{
    my $event;
    my $self = UNIVERSAL::isa($_[0],'Tie::Layers') ? shift : Tie::FormA->new();

    my ($encoded_fields) = @_;
    unless( $encoded_fields ) {
        $event = "No inputs\n";
        goto EVENT;
    }
    my $EOR = $self->{'Tie::FormA'}->{options}->{EOR};

    my $record = $$encoded_fields;

    ####### 
    # escape $EOR by adding one more .
    #
    # "~-~" => "~--~"
    # "~--~ => "~---~"
    # "~---~ => "~----~"
    #
    # Thus, the record will never contain the
    # record separator sequence.
    # 
    # ~-~n
    #
    if($record) {
      $record =~ s/~(-+)~/~-$1~/g;  
      $record .= "\n" if($record =~ /[\n\r]/ && substr($record, -1) ne "\n");
      $record .= ${EOR};
      $record .= "\n";   
    }
    else {
      $record = '';  # something to print
    }
    return \$record;

EVENT:
     if($self->{'Tie::FormA'}->{warn}) {
         warn($event);
     }
     $self->{current_event} .= $event;
     $self->{current_event} .= "\tTie::FormA::encode_record() $VERSION\n";
     $self->{current_event};

} 

###########
###########
# 
# The following code is the record encoding and decoding layer 0
#
##########
##########

####
#
#
sub read_record
{
    my ($self) = @_;

    local($/);
    $/ = $self->{'Tie::FormA'}->{options}->{EOR};
    my ($fh) = $self->{'Tie::Layers'}->{FH};
    return '' unless $fh;
    <$fh>;
}

1;


__END__

=head1 NAME

Tie::FormA - access a machine readable database file that minics a hardcopy form

=head1 SYNOPSIS

 require Tie::FormA;

 #####
 # Using support methods and file handle with
 # the file subroutines such as open(), readline()
 # print(), close()
 #
 tie *FORM_FILEHANDLE, 'Tie::FormA', @options
 $form = tied \*FORM_FILEHANDLE; 

 #####
 # Using support methods only, no file subroutines
 # 
 $form = Tie::Form->new(@options);

 \$encoded_fields  = $form->decode_record(\$record); 
 \@fields          = $form->decode_field(\$encoded_fields);

 \$encoded_fields  = $form->encode_field (\@fields);
 \$record          = $form->encode_record(\$encoded_fields);

 $record           = $form->get_record();

 ####
 # Subroutine interface
 #
 \$encoded_fields  = decode_record(\$record); 
 \@fields          = decode_field(\$encoded_fields);

 \$encoded_fields  = encode_field (\@fields);
 \$record          = encode_record(\$encoded_fields);

If a subroutine or method will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.

=head1 DESCRIPTION

The C<Tie::FormA> module provides a text database file
suitable for local data such as private mailing lists.
The C<Tie::FormA> cannot provide a data warehouse shared
by mulitple users.

=head2 File format description

Desireable goals for small local private databases file format are as follows:

=over 4

=item *

The database is a text file that can be edited with a simple text editor.
How many times have a basebase been corrupted and the data
cannot be recoveried? For most people many times.
One time is one time too many

=item *

The text format resembles as much as possible the standard
forms that all civilized people must from time to time fill
out in order to survive in a civilized society.
Forms are a necessary evil in the
pursue of happiness, freedom and prosperity
in a civilized society.
An example of a form is as follows:

  manhood length: ________
  time spent in big house: _________
  what drugs do you use: _________

Notice the applicant is not required to specify the
form data using Perl hash notation such as

  manhood_length => 2

By the way, that would be your entry. My entry would be

  manhood_length => 22

The political incorrect NH live free or die response would be

  manhood length: come up to my place and I'll show you
  time spent in big house: none of your business
  what drugs do you use: put it where the sun doesn't shine

The feds response to NH: no federal funding.

=item *

The record separator, field separator and any other
separator is unique and not embedded in the data.
With unique separators, various components of the
database may be accessed with simple file read and
write functions. 
There is no need to buffer and process the data to determine
if the separator is really a separtor or part of
the data.

=item *

The format has simple, straightforward method of escaping separators
when they are embedded in the data.  
Escape techiques such as the back-slash besides
causing blurred vision also leave the separator
embedded in the data. 
Try looking at the output of the metachar() function
and then try to read a eye chart.
This is totally unacceptable not only because it impairs
vision but also for poor computation performance.

=back

The C<Tie::FormA> program module
solution is to use separators of the following form:

 (not_the_char) . (char) . (not_the_char)

The separators are escaped in embedded text by
adding a extra (char) as follows:

 sequence             escaped

 [^$c]$c[^c]          [^$c]$c$c[^c]
 [^$c]$c$c[^c]        [^$c]$c$c$c[^c]

                 ...

 [^$c]$c x n[^c]      [^$c]$c($c x n)[^c]


=head1 SUBROUTINES

This package inherits most of its Tie methods from the
L<Tie::Layers|Tie::Layers> package.

The methods specific to this package are to encode
and decode fields and records, and to put and get
records as follows:

=head2 TIEHANDLE

 tie *FORM_FILEHANDLE, 'Tie::FormA', @options
 tie *FORM_FILEHANDLE, 'Tie::FormA', \@options
 tie *FORM_FILEHANDLE, 'Tie::FormA', \%options
 $form = tied \*FORM_FILEHANDLE; 

The C<TIEHANDLE> method supports the C<tie> Perl built-in
subroutine. The C<$form> object created by C<tie> may be
used to access the functions that are in addition to the
those established in Tie Handle Perl specification.
The available options are as follows:

 option      description
 ---------------------------
 EON         End of Name field termination separator
 EOD         End of Data field termination separator
 EOR         End of Record termination separator
 strict      strict processing of EON and EOD

Typically C<EON>, C<EOD>, C<EOR> should be read-only.
The L<requirements|Tie::FormA/REQUIREMENTS>
for these options are very specific.

=head2 encode_field

 \$encoded_fields = encode_field (\@fields);

The C<encode_field> subroutine method takes a C<@fields> and
returns a  C<encoded_fields> string. 
This subroutine will escape all field separators.

=head2 encode_record

 \$record = encode_record(\$encoded_fields);

The C<encode_record> subroutine takes a C<$encoded_fields> string 
and encodes it as C<$record>. This subroutines escapes the
record separator and embeds the record separator in the C<$record>
string.  

=head2 decode_field

 \@fields = decode_field(\$encoded_fields);

The C<decode_fiel> subroutine takes C<$encoded_fields>, 
unescape the field separators, decodes the fields and places
the results in C<@fields>.
The C<@fields> array is ordered name, value pairs of the
fields.
The even array elements are the
field names and the following odd array element is the
field data.

The below code will convert the decoded C<@fields> to a hash:

  %fields = @fields

=head2 decode_record 

 \$encoded_fields  = decode_record(\$record); 

The C<decode_record> subroutine takes a C<$record> string, removes the record
separator, unescapes the record separator in the fields string
and leaves the fields string in C<$encoded_fields>.

=head2 get_record

 $record = $form->get_record();

The get_record method reads a fully encoded C<$record> from the
underlying file of the  object.

=head2 new

 $form = Tie::FormA->new(@options);
 $form = Tie::FormA->new(\@options);
 $form = Tie::FormA->new(\%options);

The C<new> method provides an object that may be
used to access the functions that are in addition to the
those established in Tie Handle Perl specification.
The C<@options> are the same as C<TIEHANDLE>.

=head1 REQUIREMENTS

The general C<STD::TestGen> Perl module requirements are as follows:

=over 4

=item general [1] - load 

shall[1] load without error and

=item general [2] - pod check  

shall[2] passed the L<Pod::Checker|Pod::Checker> check
without error.

=back

=head2 File format requirements

For most databases, the file format is hidden.
In this case, since the file may be accessed and
edited by any text editor, the file format requirements
must be rigorously established in order that
they may be properly edited.

The C<Tie::FormA> module file 
format will be as follows:

 $field_name: $field_data ^

      ...

 $field_name: $field_data ^
 ~-~

     ...

 ~-~
 $field_name: $field_data ^

      ...

 $field_name: $field_data ^
 ~-~

The requirements for the file format are as follows:

=over 4

=item format [1] - separator strings

The format separator strings shall[1] be as follows:

 End of Field Name (EON):  [^:]:[^:]
 ENd of Field Data (EOD):  [^\^]\^[^\^]
 End of Record(EOR):  ~-~

The separator strings have the following format:

 (not_the_char) . (char) . (not_the_char)

The '^' character was and still available in console
text editors as a cursor. 
Because it appears very rarely in text, 
it is a good choice for use in a separator string.
If it does not appear a lot, it will not have to
be escaped a lot.
The "~-~" separator sequence is a natural looking 
text section separator.

=item format [2] - separator escapes

Separator strings embedded in $field_name and $field_data
strings shall[2] be escaped by adding one additional
middle character.
Escaped sequences must also be escaped. 
An escaped separator sequence will always have one additional
middle character from an unescaped separator sequence.

=item format [3] - field names

The characters [\x00-\x1f] shall[3] not be allowed in $field_name
strings. Spaces will be allowed. 
The character set [\x00-\x1f] are the ASCII control characters.
See ascii.computerdiamonds.com.
Embedded [\x00-\x1f] characters will be converted to
the '_' character. 

=item format [4] - field names

Leading and trailing [ \x00-\x1f] characters in any potential
$field_name string shall[4] not be part of the $field_name 
and discarded.

=item format [5] - EON

A leading [^:] in the EON separator
that is not a [ \x00-\x1f] shall[5] be the be the last character
in the $field_name string;
otherwise, it is not part of the the $field_name string
and discarded.
For the situation where the last part of a $field_name string 
is an escape sequence a [ \x00-\x1f] will be required between
the $field_name string and the EON. 
The following is a valid $field_name EON sequence:

  escaped              unescaped

  field_name:: :       fieldname:

=item format [6] - Strict EOD

For the strict format option, the leading [^\^] of the EOD shall[6]
not be part of the $field_data. The [^\^] character may be any
character including the [\x00-\x1f] characters.

Examples of strict format option are as follows:

 $field_name: $data ^
 $field_name: $data$c^

 $field_name: 
 line1
   ..
 line2
 ^

The $field_data for the above example is as follows:

 Example               $field_data   

 "$data ^"             "$data"  
 "$data$c^"            "$data"
 "$line1\n$line2\n^"   "$line1\n$line2"

=item format [7] - Lenient EOD

For the lenient format option, the leading [^\^] of the EOD shall[7]
be part of the $field_data.
The lenient format has ambiguous case when the last character in the
$field_data is the [\^] character. 
In order to be valid, a [^\^] must be used before the [\^],
making the [^\^] part of the $field_data whether that is intended
or not. 
For example in, "$data^^ ^", the $field_data is "$data^ " whether
or not the space is intended as part of the $field_data.
If this cannot be tolerated for an application the strict format
opion should be specified.

Examples of lenient format option are as follows:

 $field_name: $data1 ^

 $field_name: $data2^

 $field_name: 
 $line1
 $line2
 ^

The $field_data for the above example is as follows:

 Example               $field_data   

 "$data1 ^"            "$data1 "  
 "$data2^"             "$data2"
 "$line1\n$line2\n^"   "$line1\n$line2\n"

=back

=head2 Methods requirements

There are two options, that impact the methodsas
follows:

=over 4

=item strict => 1 option

This option determines whether to encode a
field in strict or lenient format.

=item binary => 1 option

This option determines whether or not to
process carriage returns and line feeds.
Different operating systems handle these
characters differently for text files.

=back

The requirements for the methods are as follows:

=over 4

=item methods [1] - encode_field

 $field = $tdb->encode_field (\@fields, \$fields)

The @fields array will contain a number of fields.
The $field_names will be the even elements and
the $field_data the following odd elements.

The encode_field subroutine shall[1] encode the $field_name string and
$field_data string into the $field string in accordance with the
L<File Format requirements|Tie::FormA/File Format>.
The encoding shall escape the EON and EOD separators and embed
the EON and EOD separators. 

The encoding will be conservative in complying
with the L<File Format requirements|Tie::FormA/File Format>.

As established by the
L<File Format requirements|Tie::FormA/File Format>,
the encoding will be different depending upon the
value of the strict option, $tdb->{options}->{strict}.

=item methods [2] - decode_field

 $success = $tdb->decode_field(\$fields, \@fields)

The decode_field subroutine shall[2] decode a $record string 
into the @fields array
in accordance with the
L<File Format requirements|Tie::FormA/File Format>.
The $field_names will be the even elements in the @fields array and
the $field_data the following odd elements.

The decoding will be liberal what it considers that complies to
the L<File Format requirements|Tie::FormA/File Format>.

As established by the
L<File Format requirements|Tie::FormA/File Format>,
the decoding will be different depending upon the
value of the strict option, $tdb->{options}->{strict}.

=item methods [3] - encode_record

 $success = $tdb->encode_record(\$fields, \$record) 
 $success = $tdb->encode_record( \$fields) 

The encode_record subroutine shall[3] encode the $fields string 
into the $record string in accordance with
L<File Format requirements|Tie::FormA/File Format>.
If the $record string is absence or the \$record reference
and the \$fields reference are the same, 
the encoding will modify the \$fields string.
In this case, the encoding will not
perserve the $fields string.
The encoding will escape the EOR and embed the EOR.

=item methods [4] - decode_record

 $success  = $tdb->decode_record(\$record, \$fields) 
 $success  = $tdb->decode_record(\$record) 

The decode_record subroutine shall[4] decode the $record string and
into the $fields string in accordance with the
L<File Format requirements|Tie::FormA/File Format>.
If the $fields string is absence or the \$record reference
and the \$fields reference are the same, 
the encoding will modify the \$record string.
In this case, the encoding will not
perserve the $record string.
The decoding will remove the EOR and unescape the EOR.

=item methods [5] - put_record

 $success = $tdb_out->put_record( \$record )

The put_record subroutine shall[5] write out the $record to the
file specified when the object $tdb_out was created with
the following statement

 $tdb_out = Tie::FormA( flag => '>', file => $file, @options );

=item methods [6] - get_record

 $success = $tdb_in->get_record( \$record )

The get_record subroutine shall[6] read a $record from the
file specified when the object $tdb_in was created with
the following statement

 $tdb_in = Tie::FormA( flag => '<', file=>$file, @options );

=item methods [7] - get_record

Unless $tdb_in was created with the binary option, {binary => 1},
the get_record subroutine shall[7] translate any "\015\012"
combination into the "\n" for the current operating system.

=item Tie::Layers

The methods inherit from
L<Tie::Layers|Tie::Layers>
will comply to the
L<Tie::Layers requirements|Tie::Layers/REQUIREMENTS>

=back

=head1 DEMONSTRATION

 #########
 # perl FormA.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     use File::SmartNL;
     use File::Spec;

     my $uut = 'Tie::FormA'; # Unit Under Test
     my $fp = 'File::Package';
     my $loaded;

     my (@fields);  # force context
     my $out_file = File::Spec->catfile('FormA','form1.txt');;
     unlink $out_file;

     my $lenient_in_file = File::Spec->catfile('FormA','lenient0.txt');
     my $strict_in_file = File::Spec->catfile('FormA','strict0.txt');

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut)
 $errors

 # ''
 # 

 ##################
 # Tie::FormA Version 0.01 loaded
 # 

 $fp->is_package_loaded($uut)

 # 1
 # 

 ##################
 # Read lenient FormA
 # 

     tie *FORM, 'Tie::FormA';
     open FORM,'<',File::Spec->catfile($lenient_in_file);
     @fields = <FORM>;
     close FORM;
 [@fields]

 # [
 #           [
 #             'UUT',
 #             'File/Version.pm',
 #             'File_Spec',
 #             '',
 #             'Revision',
 #             '',
 #             'End_User',
 #             '',
 #             'Author',
 #             'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
 #             'SVD',
 #             'SVD::DataCop-DataFile',
 #             'Template',
 #             'STD/STD001.frm'
 #           ],
 #           [
 #             'Email',
 #             'nobody@hotmail.com',
 #             'Form',
 #             'Udo-fully processed oils',
 #             'Tutorial',
 #             '*~~* Better Health thru Biochemistry *~~*',
 #             'REMOTE_ADDR',
 #             '213.158.186.150',
 #             'HTTP_USER_AGENT',
 #             'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
 #             'HTTP_REFERER',
 #             'http://computerdiamonds.com/'
 #           ],
 #           [
 #             'EOF',
 #             '\n',
 #             'EOL',
 #             '\n^\n',
 #             'EOV',
 #             '}',
 #             'SOV',
 #             '${'
 #           ],
 #           [
 #             'EOF',
 #             '^',
 #             'EOL',
 #             '~-~',
 #             'SOV',
 #             '${',
 #             'EOV',
 #             '}'
 #           ],
 #           [
 #             'EOF',
 #             '^^',
 #             'EOL',
 #             '~---~',
 #             'SOV',
 #             '${',
 #             'EOV',
 #             '}'
 #           ]
 #         ]
 # 

 ##################
 # Write lenient FormA
 # 

     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 File::SmartNL->fin($out_file)

 # 'UUT: File/Version.pm^
 # File_Spec: ^
 # Revision: ^
 # End_User: ^
 # Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 # SVD: SVD::DataCop-DataFile^
 # Template: STD/STD001.frm^
 # ~-~
 # Email: nobody@hotmail.com^
 # Form: Udo-fully processed oils^
 # Tutorial: *~~* Better Health thru Biochemistry *~~*^
 # REMOTE_ADDR: 213.158.186.150^
 # HTTP_USER_AGENT: Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)^
 # HTTP_REFERER: http://computerdiamonds.com/^
 # ~-~
 # EOF: \n^
 # EOL: \n^^\n^
 # EOV: }^
 # SOV: ${^
 # ~-~
 # EOF: ^^ ^
 # EOL: ~--~^
 # SOV: ${^
 # EOV: }^
 # ~-~
 # EOF: ^^^ ^
 # EOL: ~----~^
 # SOV: ${^
 # EOV: }^
 # ~-~
 # '
 # 

 ##################
 # Read strict FormA
 # 

     tie *FORM, 'Tie::FormA';
     open FORM,'<',File::Spec->catfile($strict_in_file);
     @fields = <FORM>;
     close FORM;
 [@fields]

 # [
 #           [
 #             'UUT',
 #             'File/Version.pm',
 #             'File_Spec',
 #             '',
 #             'Revision',
 #             '',
 #             'End_User',
 #             '',
 #             'Author',
 #             'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
 #             'SVD',
 #             'SVD::DataCop-DataFile',
 #             'Template',
 #             'STD/STD001.frm'
 #           ],
 #           [
 #             'Email',
 #             'nobody@hotmail.com',
 #             'Form',
 #             'Udo-fully processed oils',
 #             'Tutorial',
 #             '*~~* Better Health thru Biochemistry *~~*',
 #             'REMOTE_ADDR',
 #             '213.158.186.150',
 #             'HTTP_USER_AGENT',
 #             'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
 #             'HTTP_REFERER',
 #             'http://computerdiamonds.com/'
 #           ],
 #           [
 #             'EOF',
 #             '\n',
 #             'EOL',
 #             '\n^\n',
 #             'EOV',
 #             '}',
 #             'SOV',
 #             '${'
 #           ],
 #           [
 #             'EOF',
 #             '^',
 #             'EOL',
 #             '~-~',
 #             'SOV',
 #             '${',
 #             'EOV',
 #             '}'
 #           ],
 #           [
 #             'EOF',
 #             '^^',
 #             'EOL',
 #             '~---~',
 #             'SOV',
 #             '${',
 #             'EOV',
 #             '}'
 #           ]
 #         ]
 # 

 ##################
 # Write strict FormA
 # 

     open FORM, '>', $out_file;
     print FORM @fields;
     close FORM;
 File::SmartNL->fin($out_file)

 # 'UUT: File/Version.pm^
 # File_Spec: ^
 # Revision: ^
 # End_User: ^
 # Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
 # SVD: SVD::DataCop-DataFile^
 # Template: STD/STD001.frm^
 # ~-~
 # Email: nobody@hotmail.com^
 # Form: Udo-fully processed oils^
 # Tutorial: *~~* Better Health thru Biochemistry *~~*^
 # REMOTE_ADDR: 213.158.186.150^
 # HTTP_USER_AGENT: Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)^
 # HTTP_REFERER: http://computerdiamonds.com/^
 # ~-~
 # EOF: \n^
 # EOL: \n^^\n^
 # EOV: }^
 # SOV: ${^
 # ~-~
 # EOF: ^^ ^
 # EOL: ~--~^
 # SOV: ${^
 # EOV: }^
 # ~-~
 # EOF: ^^^ ^
 # EOL: ~----~^
 # SOV: ${^
 # EOV: }^
 # ~-~
 # '
 # 
 unlink $out_file;

=head1 QUALITY ASSURANCE

The module C<t::Tie::FormA> is the Software
Test Description(STD) module for the C<Tie::FormA>
program module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script,
execute the following in any directory:

 tmake -verbose -demo -run -test_verbose -pm=t::Tie::FormA

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory on the same level as the "lib" that
contains the C<Tie::FormA> program module.
The C<tmake> subroutine is in the C<Test::STDmaker|Test::STDmaker>
distribution file.

=head1 NOTES

=head2 Construction of Words

The construction of the words "shall", "may" and "should"
shall[1] conform to United States (US) Departmart of Defense (DoD)
L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>
which is more precise and even consistent, at times, with
RFC 2119, http://www.ietf.org/rfc/rfc2119.txt
Binding requirements shall[2] be uniquely identified by
the construction "shall[\d+]" , where "\d+" is an unique number
for each paragraph(s) uniquely identified by a header.
The construction of commonly used words and phrasing
shall[3] conform to US DoD 
L<STD490A 3.2.3.5|Docs::US_DOD::STD490A/3.2.3.5 Commonly used words and phrasing.>
In accordance with US Dod L<STD490A 3.2.6|Docs::US_DOD::STD490A/3.2.6 Underlining.>,
requirments shall[4] not be emphazied by underlining and capitalization.
All of the requirements are important in obtaining
the desired performance.

Unless otherwise specified, in accordance with the Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2003 SoftwareDiamonds.com

=head2 License

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

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commercial activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[1] pay a license fee to
Software Diamonds and shall[2] make donations,
to open source repositories carrying
the source code.

=back

The construction of the word "shall[x]" is always mandatory 
and not merely directory and identifies each binding
requirement of this License. 
It is the responsibility of the licensee to
conform to all requirements.

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

=head1 SEE ALSO

=over 4

=item L<Tie::Layers|Tie::Layers>

=item L<Test::STDmaker|Test::STDmaker>

=item L<Tie::CSV|Tie::CSV>

=item L<Tie::Eudora|Tie::Eudora>

=item L<Data::Query|Data::Query>

=back

=cut

### end of program module  ######