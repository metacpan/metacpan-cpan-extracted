package WDDX;

=head1 NAME

WDDX.pm - Module for reading and writing WDDX packets

=head1 VERSION

Version 1.02

    $Header: /home/cvs/wddx/WDDX.pm,v 1.4 2003/12/02 03:41:10 andy Exp $

=cut

use vars qw( $VERSION );
$VERSION = "1.02";

=head1 NAME


=head1 SYNOPSIS

 use WDDX;
 my $wddx = new WDDX;
 
 # Serialization example
 
 my $wddx_hash = $wddx->hash( {
         str     =>  $wddx->string( "Welcome to WDDX!\n" ),
         num     =>  $wddx->number( -12.456 ),
         date    =>  $wddx->datetime( date ),
         bool    =>  $wddx->boolean( 1 ),
         arr     =>  $wddx->array( [
                     $wddx->boolean( 0 ),
                     $wddx->number( 10 ),
                     $wddx->string( "third element" ),
                 ] ),
         rec     =>  $wddx->recordset(
                     [ "NAME", "AGE" ],
                     [ "string", "number" ],
                     [
                         [ "John Doe", 34 ],
                         [ "Jane Doe", 25 ],
                         [ "Fred Doe", 90 ],
                     ]
                 ),
         obj     =>  $wddx->hash( {
                     str => $wddx->string( "a string" ),
                     num => $wddx->number( 3.14159 ),
                 } ),
         bin     => $wddx->binary( $img_data ),
         null    => $wddx->null(),
     } );
 
 print $wddx->header;
 print $wddx->serialize( $wddx_hash );
 
 # Deserialization example
 
 my $wddx_request = $wddx->deserialize( $packet );
 
 # Assume that our code expects an array
 $wddx_request->type eq "array" or die "Invalid request";
 my $array_ref = $wddx_request->as_arrayref;


=head1 DESCRIPTION

=head2 About WDDX

From L<http://www.wddx.org/>:

=over 4

The Web Distributed Data Exchange, or WDDX, is a free, open XML-based
technology that allows Web applications created with any platform to
easily exchange data with one another over the Web.

=back

=head2 WDDX and Perl

WDDX defines basic data types that mirror the data types available in
other common programming languages. Many of these data types don't
have corresponding data types in Perl. To Perl, strings, numbers,
booleans, and dates are just scalars. However, in order to communicate
effectively with other languages (and this is the point of WDDX), you
do have to learn the basic WDDX data types. Here is a table that maps
the WDDX data type to Perl, along with the intermediate object WDDX.pm
represents it as:

 WDDX Type      WDDX.pm Data Object      Perl Type
 ---------      -------------------      ---------
 String         WDDX::String             Scalar
 Number         WDDX::Number             Scalar
 Boolean        WDDX::Boolean            Scalar (1 or "")
 Datetime       WDDX::Datetime           Scalar (seconds since epoch)
 Null           WDDX::Null               Scalar (undef)
 Binary         WDDX::Binary             Scalar
 Array          WDDX::Array              Array
 Struct         WDDX::Struct             Hash
 Recordset      WDDX::Recordset          WDDX::Recordset


In languages that have data types similar to the WDDX data types, the
WDDX modules allow you to convert directly from a variable to a WDDX
packet and vice versa. This Perl implementation is different; here you
must always go through an intermediate stage where the data is
represented by an object with a corresponding data type. These objects
can be converted to a WDDX packet, converted to a basic Perl type, or
converted to JavaScript code (which will recreate the data for you in
JavaScript). We will refer to these objects as I<data objects>
throughout this documentation.

=head1 Requirements

This module requires L<XML::Parser> and L<MIME::Base64>, which are
both available on CPAN at L<http://www.cpan.org/>. Windows users note:
These modules use compiled code, but I have been told that they are both
included with recent distributions of ActiveState Perl.

=cut

use strict;
use Carp;

require WDDX::Parser;
require WDDX::Boolean;
require WDDX::Number;
require WDDX::Datetime;
require WDDX::String;
require WDDX::Array;
require WDDX::Recordset;
require WDDX::Struct;
require WDDX::Null;
require WDDX::Binary;


# Each of these must have a corresponding WDDX::* class;
# These are lowerclass while the WDDX::* name will have initial cap
@WDDX::Data_Types = qw( boolean number string datetime null 
                        array struct recordset binary );

$WDDX::XML_HEADER = "<?xml version='1.0'?>\n" .
                    "<!DOCTYPE wddxPacket SYSTEM 'wddx_0100.dtd'>\n";
$WDDX::PACKET_HEADER = "<wddxPacket version='1.0'><header/><data>";
$WDDX::PACKET_FOOTER = "</data></wddxPacket>";

# if this is defined, serialize() uses it to indent packet
$WDDX::INDENT = undef;

# Create struct() as an alias to the hash() method:
*struct = \&hash;

{ my $i_hate_the_w_flag_sometimes = [
        \@WDDX::Data_Types,
        $WDDX::XML_HEADER,
        $WDDX::PACKET_HEADER,
        $WDDX::PACKET_FOOTER,
        $WDDX::INDENT,
        \&struct,
        $WDDX::VERSION
] }

1;


=head1 METHODS

=head2 new

This creates a new WDDX object. You need one of these to do pretty much 
anything else. It doesn't take any arguments.

=cut

sub new {
    my $this = shift;
    my $class = ref( $this ) || $this;
    
    # Currently no properties maintained in WDDX object
    my $self = bless [], $class;
    return $self;
}


=head2 C<< $wddx->deserialize( $string_or_filehandle ) >>

This method deserializes a WDDX packet and returns a data object. Note
that you can pass either a string or a reference to an open filehandle
containing a packet (XML::Parser is flexible this way):

  $wddx_obj = $wddx->deserialize( $packet );     # OR
  $wddx_obj = $wddx->deserialize( \*HANDLE );

If WDDX.pm or the underlying L<XML::Parser> finds any errors with the
structure of the WDDX packet, then it will C<die> with an error
message that identifies the problem. If you don't want this to terminate
your script, you will have to place this call within an C<eval> block
to trap the C<die>.

=cut

sub deserialize {
    my( $self, $xml ) = @_;
    my $parser = new WDDX::Parser();
    
    return $parser->parse( $xml, $self );
}


=head2 C<< $wddx->serialize( $wddx_obj ) >>

This accepts a data object as an argument and returns a WDDX packet.
This method calls the as_packet() method on the data object
it receives. However, this method does provide one feature that
C<as_packet()> does not. If C<$WDDX::INDENT> is set to a defined value,
then the generated WDDX packet is indented using C<$WDDX::INDENT>
as the unit of indentation. Otherwise packets are generated without
extra whitespace.

Note that the generated packet is not a valid XML document without the
header, see below.

=cut

sub serialize {
    my( $self, $data ) = @_;
    
    croak "You may only serialize WDDX data objects" unless
        eval { $data->can( "as_packet" ) };
    my $packet = eval { $data->as_packet };
    croak _shift_blame( $@ ) if $@;
    
    return defined( $WDDX::INDENT ) ? _xml_indent( $packet ) : $packet;
}


=head2 C<< $wddx->header >>

This returns a header that should accompany every serialized packet you 
send.

=cut

sub header {
    return $WDDX::XML_HEADER;
}


sub string {
    my( $this, $value ) = @_;
    return new WDDX::String( $value );
}

sub number {
    my( $this, $value ) = @_;
    return new WDDX::Number( $value );
}

sub datetime {
    my( $this, $value ) = @_;
    return new WDDX::Datetime( $value );
}

sub boolean {
    my( $this, $value ) = @_;
    return new WDDX::Boolean( $value );
}

sub hash {
    my( $this, $hashref ) = @_;
    
    my $var = eval {
        new WDDX::Struct( $hashref );
    };
    croak _shift_blame( $@ ) if $@;
    
    return $var;
}

sub array {
    my( $this, $arrayref ) = @_;
    
    my $var = eval {
        new WDDX::Array( $arrayref );
    };
    croak _shift_blame( $@ ) if $@;
    
    return $var;
}

sub recordset {
    my( $this, $names, $types, $tableref ) = @_;
    
    my $var = eval {
        new WDDX::Recordset( $names, $types, $tableref );
    };
    croak _shift_blame( $@ ) if $@;
    
    return $var;
}

sub binary {
    my( $this, $value ) = @_;
    return new WDDX::Binary( $value );
}

sub null {
    my( $this, $value ) = @_;
    return new WDDX::Null( $value );
}


############################################################
#
# Public Utility Methods (make life easier)
#

sub scalar2wddx {
    my( $wddx, $scalar, $type ) = @_;
    $type = defined( $type ) ? lc $type : "string";
    
    croak "Will not encode a reference as a scalar" if ref $scalar;
    my $var = eval "WDDX::\u$type->new( \$scalar )" or
        croak "Unable to create object of type WDDX::\u$type: " .
            _shift_blame( $@ );
    return $var;
}

sub hash2wddx {
    my( $wddx, $hashref, $coderef ) = @_;
    my $new_hash = {};
    $coderef = sub { "" } unless
        defined( $coderef ) && eval { &$coderef || 1 };
    
    while ( my( $name, $val ) = each %$hashref ) {
        
        eval { $val->can( "_serialize" ) } and do {
            $new_hash->{$name} = $val;
            next;
        };
        
        my $type = lc $coderef->( $name => $val, "HASH" );
        if ( $type ) {
            ref( $val ) eq "HASH"  and do {
                $new_hash->{$name} = $wddx->hash2wddx ( $val, sub { $type } );
                next;
            };
            ref( $val ) eq "ARRAY" and do {
                $new_hash->{$name} = $wddx->array2wddx( $val, sub { $type } );
                next;
            };
            my $var = eval "WDDX::\u$type->new( \$val )" or
                croak "Unable to create object of type WDDX::\u$type: " .
                    _shift_blame( $@ );
            $new_hash->{$name} = $var;
            next;
        }
        
        ref( $val ) eq "HASH"  and do {
            $new_hash->{$name} = hash2wddx ( $wddx, $val, $coderef );
            next;
        };
        ref( $val ) eq "ARRAY" and do {
            $new_hash->{$name} = array2wddx( $wddx, $val, $coderef );
            next;
        };
        
        # Scalars treated as strings by default
        $new_hash->{$name} = $wddx->string( $val );
    }
    return $wddx->hash( $new_hash );
}

sub array2wddx {
    my( $wddx, $arrayref, $coderef ) = @_;
    my $new_array = [];
    $coderef = sub { "" } unless
        defined( $coderef ) && eval { &$coderef || 1 };
    
    for ( my $i = 0; $i < @$arrayref; $i++ ) {
        my $val = $arrayref->[$i];
        
        eval { $val->can( "_serialize" ) } and do {
            push @$new_array, $val;
            next;
        };
        
        my $type = lc $coderef->( $i => $val, "ARRAY" );
        if ( $type ) {
            ref( $val ) eq "HASH"  and do {
                push @$new_array, hash2wddx( $wddx, $val, sub { $type } );
                next;
            };
            ref( $val ) eq "ARRAY" and do {
                push @$new_array, array2wddx( $wddx, $val, sub { $type } );
                next;
            };
            my $var = eval "WDDX::\u$type->new( $i => \$val )" or
                croak "Unable to create object of type WDDX::\u$type: " .
                    _shift_blame( $@ );
            push @$new_array, $var;
            next;
        }
        
        ref( $val ) eq "HASH"  and do {
            push @$new_array, hash2wddx( $wddx, $val, $coderef );
            next;
        };
        
        ref( $val ) eq "ARRAY" and do {
            push @$new_array, array2wddx( $wddx, $val, $coderef );
            next;
        };
        
        # Scalars treated as strings by default
        push @$new_array, $wddx->string( $val );
    }
    return $wddx->array( $new_array );
}

sub wddx2perl {
    my( $self, $wddx_obj ) = @_;
    my $result;
    $result = $wddx_obj->as_scalar   if $wddx_obj->can( "as_scalar" );
    $result = $wddx_obj->as_hashref  if $wddx_obj->type eq "hash";
    $result = $wddx_obj->as_arrayref if $wddx_obj->type eq "array";
    $result = $wddx_obj              if $wddx_obj->type eq "recordset";
    return $result;
}


############################################################
#
# Private Subs
#

# Takes a die message and strips any internal line refs
# This is necessary because we call public methods that invoke croak
# and croak would blame us even though we're just the messenger...
sub _shift_blame {
    my $msg = shift;
    $msg =~ s/ at \S*WDDX.*\.pm line \d+//g;
    $msg =~ s/\n\nFile '.*'; Line \d+//g;   # MacPerl thinks different
    chomp $msg;
    return $msg;
}


# This uses regex matches to do indentation based on whether tag
# starts with <? or <! or < and whether tag ends with /> or >
# It's called by serialize() if $WDDX::INDENT is defined
sub _xml_indent {
    my $xml = shift;
    my $indent = $WDDX::INDENT;
    my $level = 0;
    
    # It ain't pretty but it works...
    $xml =~ s{ (>?)\s*(< ([?!/]?) [^>/]* (/?) ) }{
# print "Matched: $&\n      1: $1\n      2: $2\n      3: $3\n      4: $4\n";
                $level-- if $3 eq "/" && not $4;
                my $result = $1 ? "$1\n" . ( $indent x $level ) . $2 : $2;
                $level++ unless $3 || $4;
                $result;
             }egx;
    return $xml;
}

__END__
=head1 WDDX DATA OBJECTS

=head2 Common Methods

All of the WDDX data objects share the following common methods:

=over

=item $wddx_obj->type

This returns the data type of the object. It is lowercase and maps
to the package name without the WDDX prefix. For example, type will
return "string" for WDDX::String objects, "datetime" for WDDX::Datetime
objects, etc.

=item $wddx_obj->as_packet

This returns a WDDX packet for the object. You can also do this by
passing the object to the C<$wddx->serialize> method. See the warning
in C<$wddx->header>.

=item $wddx_obj->as_javascript( $js_varname )

This method takes the name of a JavaScript variable and returns the
actual JavaScript code to assign this data object to the given
JavaScript variable. No temporary variables are created to avoid
any danger of variable name collisions.

Example:

  $options[0] = $wddx->string( "First Choice" );
  $options[1] = $wddx->string( "Second Choice" );
  $options[2] = $wddx->string( "Third Choice" );
  $w_array    = $wddx->array( \@options );
  print $w_array->as_javascript( "myArray" );

This prints the text (new lines added for readability):

  myArray=new Array();
  myArray[0]="First Choice";
  myArray[1]="Second Choice";
  myArray[2]="Third Choice";

All data types are supported, and arrays and hashes (structs) can nest
to any level. Recordset and binary objects require the JavaScript
WddxRecordset and WddxBinary constructors. The easiest way to include
these is to add a reference to the wddx.js file:

  <SCRIPT NAME="javascript" SRC="wddx.js"></SCRIPT>

wddx.js is the WDDX library for JavaScript. It is available as part of
the WDDX SDK at http://www.wddx.org/.


=back

=head2 WDDX::String

=over

=item $wddx->string( 'Just a bunch of text...' )

This creates a WDDX string object. Strings contain 8 bit characters,
can be any length, and should not include embedded nulls. However, 
control characters and characters that have special meaning for XML 
(like E<lt>, E<gt>, and E<amp>) are safely encoded for you.

=item $w_string->as_scalar

This returns the value of the WDDX::String as a Perl scalar.


=back

=head2 WDDX::Number

=over

=item $wddx->number( 3.14159 )

This creates a WDDX number object. Numbers are restricted to
+/-1.7e308 and if you exceed these bounds this method dies with an
error. Floating point numbers are restricted to 15 digits of accuracy
past the decimal. If you exceed this then the number is truncated to
15 digits with a warning. If you pass a non-numeric scalar to this,
then it is simply treated as a number: Perl will attempt to translate
it, will probably use zero, and will issue a warning.

=item $w_number->as_scalar

This returns the value of the WDDX::Number as a Perl scalar.


=back

=head2 WDDX::Boolean

=over

=item $wddx->boolean( 1 )

This creates a WDDX boolean object. It simply tests the argument in a
boolean context, so "0" and "" are false and anything else is true.

=item $w_boolean->as_scalar

This returns the value of the WDDX::Boolean as a Perl scalar. True
is represented by 1 and false is represented by an empty string.


=back

=head2 WDDX::Datetime

=over

=item $wddx->datetime

This creates a WDDX Datetime object. 

=item $w_datetime->use_timezone_info( 1 )

This sets or reads the flag that says whether to include the
timezone info (local hour and minute offset from UTC) in WDDX
packets created from this object. By default this is turned on 
for new objects. You can turn it off by passing a false (but not
undef) argument to this method.

When a WDDX::Datetime object is deserialized from a packet, this
method will indicate whether timezone information was present in that
packet.

=item $w_datetime->as_scalar

This returns the value of the WDDX::Datetime as a Perl scalar. It
contains the number of seconds since the epoch localized for the
current machine (like Perl's built-in C<time> function). This number
can be passed into Perl's C<localtime> function.


=back

=head2 WDDX::Null

=over

=item $wddx->null()

This creates a WDDX null object. This is roughly the equivalent of 
C<undef> in Perl. It takes no arguments.

=item $w_datetime->as_scalar

This simply returns C<undef> (this was a hard one to code :).


=back

=head2 WDDX::Binary

=over

=item $wddx->binary( $binary_data )

This creates a WDDX binary object. It takes a scalar containing any
data, which will be base64 encoded before being serialized into the
packet.


=back

=head2 WDDX::Array

=over

=item $wddx->array( [ $wddx_obj1, $wddx_obj2, ... ] )

This creates a WDDX::Array object. It takes a reference to an array
containing data objects. You must construct a WDDX data object for 
each element of an array before adding them to the array. WDDX::Arrays 
can contain any other WDDX data type and do not need to be of a uniform 
type, so one array can contain a WDDX::String, a WDDX::Number, and
a WDDX::Struct, for example.

If you need to create an array of uniform types, Perl's built-in
C<map> function makes this easy. If you have a standard Perl array
called C<@array>, you can generate a WDDX::Array of WDDX::String
objects like this:

  my @obj_array = map $wddx->number( $_ ), @array;
  my $wddx_array = $wddx->array( \@obj_array );

If you need to serialize more complicated array structures, refer to
C<array2wddx> in the UTILITY METHODS section.


=item $wddx_array->as_arrayref()

This returns a reference to a Perl array. Every element in the 
WDDX::Array is recursively deserialized to Perl data structures. Only 
WDDX::Recordsets remain as WDDX data objects.

=item $wddx_array->get_element( $i )

=item $wddx_array->get( $i )

This allows you to get an element of a WDDX::Array as a data object 
instead of having it deserialized to Perl.

=item $wddx_array->set( $i => $wddx_obj );

This allows you to set an element in a WDDX::Array. Note that C<$wddx_obj>
should be a WDDX data object of some type.

=item $wddx_array->splice( $offset, $length, $wddx_obj1, $wddx_obj2, ... );

=item $wddx_array->splice( $offset, $length );

=item $wddx_array->splice( $offset );

This allows you to insert or delete elements in a WDDX::Array using
the syntax of Perl's built-in C<splice> function.

=item $wddx_array->length();

This returns the number of elements in the WDDX::Array object.

=item $wddx_array->push( $wddx_obj1, $wddx_obj2, ... );

This will push the given elements onto the WDDX::Array object.

=item $wddx_array->pop();

This will pop the last element off the WDDX::Array object and return it.

=item $wddx_array->unshift( $wddx_obj1, $wddx_obj2, ... );

This will unshift the given elements onto the WDDX::Array object.

=item $wddx_array->shift();

This will shift the first element off the WDDX::Array object and return it.


=back

=head2 WDDX::Struct

=over

=item $wddx->struct( { key1 => $wddx_obj1, key2 => $wddx_obj2, ... } )

=item $wddx->hash  ( { key1 => $wddx_obj1, key2 => $wddx_obj2, ... } )

This creates a WDDX::Struct object. To WDDX, a struct is simply what 
Perl refers to as a hash (or associative array). These two methods are 
aliases so you can use whichever name you prefer.

There are no restrictions on keys, but values must be WDDX data types.
Just like with WDDX::Arrays, you have to create a WDDX data type for
each value you want to insert into a WDDX::Struct.

Here's how to use Perl's built-in C<map> function to generate a
WDDX::Struct if all of your values have the same data type.
If you have a standard Perl hash called C<%hash>, you can generate a
WDDX::Struct of WDDX::String objects like this:

  my %obj_hash = map { $_ => $wddx->number( $hash{$_} } keys %hash;
  my $wddx_hash = $wddx->hash( \@obj_hash );

If you need to serialize more complicated hash structures, refer to
C<hash2wddx> in the UTILITY METHODS section.

=item $wddx_array->as_hashref()

This returns a reference to a Perl hash. Every element in the hash
is recursively deserialized to Perl data structures. Only 
WDDX::Recordsets remain as data objects.

=item $wddx_hash->get_element( $key );

=item $wddx_hash->get( $key );

This allows you to get an element of a WDDX::Struct as a data object 
instead of having it deserialized to Perl.

=item $wddx_hash->set( $key => $wddx_obj );

This allows you to set a key/value pair in a WDDX::Struct. Note that
C<$wddx_obj> should be a WDDX data object of some type.

=item $wddx_hash->delete( $key );

This allows you to delete a key from a WDDX::Struct.

=item $wddx_hash->keys();

This will return a list of keys for the WDDX::Struct object or the number
of keys (if called in a scalar context).

=item $wddx_hash->values();

This will return a list of values for the WDDX::Struct object or the number
of values (if called in a scalar context). Note that each one of these
values should be a WDDX data object of some type.


=back

=head2 WDDX::Recordset

=over

=item $wddx->recordset( [ NAME_A, NAME_B, ... ], [ TYPE_A, TYPE_B, ... ],
[ DATA ] )

This creates a WDDX::Recordset object. Recordsets hold tabular data.
There is no corresponding data type in Perl, but it corresponds
with the type of output you would receive from a SQL query.

The first argument when constructing a recordset should be a reference
to an array containing the names of each of the fields. The second
argument an reference to an array containing the types of each of the
fields. Field types must be simple, so the valid types are "string",
"number", "boolean", or "datetime". The last argument is an optional
reference to an array of arrays -- in other words a table of data.
Note that this table of data contains plain old Perl scalars; you
should not create WDDX objects for each value as you would for an
array or a hash.

  $wddx_rec = $wddx->recordset( [ NAME_A, NAME_B, ... ], 
                                [ TYPE_A, TYPE_B, ... ], 
                                [ [ $val_a1, $val_b1, ... ], 
                                  [ $val_b1, $val_b2, ... ],
                                  ... 
                                ] )

This is simple to use with DBI:
  
  $data = $dbh->selectall_arrayref( "SELECT NAME, AGE FROM TABLE" ) or
    die $dbh->errstr;
  $wddx_rec = $wddx->recordset( [ "NAME", "AGE" ],
                                [ "string", "number" ],
                                $data );

Recordsets that are within arrays or hashes are not automatically 
deserialized for you when you deserialize the array or hash. They remain 
as recordset objects. You can use the methods below to access the data.

Note: It is possible to receive a packet for a recordset that does not
contain any records. In WDDX, the data type for each field is determined
by looking at how the data in the field has been tagged; so if there is
no data, then there is no data type information. Thus if you deserialize
an empty recordset packet, add data to the resulting recordset object,
and attempt to serialize it back into a packet, you will get an error
because WDDX.pm will not know what data type to assign to the data you
added. To avoid this, you should call the types() method to set the data
types before you serialize a recordset object that was created by
deserializing a packet. (If this explanation makes no sense, reread it
a few times; if it still doesn't make sense, email me and let me know. :)


=item $wddx_rec->names

Returns a reference to an array of the field names. You can also pass
a reference to an array to set the names.


=item $wddx_rec->types

Returns a reference to an array of the field data types. You can also pass
a reference to an array to set the data types.


=item $wddx_rec->table

Returns a reference to an array of rows, each containing an array of fields.
You can also pass a reference to an array to set all the data at once.


=item $wddx_rec->num_rows

Returns the number of rows.

=item $wddx_rec->num_columns

Returns the number of columns (or fields in a row).


=item $wddx_rec->get_row( $row_num )

Takes an row index (0 base) and returns a reference to an array for that row.

=item $wddx_rec->add_row( [ ARRAY ] )

Takes a reference to an array and adds this row to the bottom of the rows.

=item $wddx_rec->del_row( $row_num )

Takes a row index and deletes that row.

=item $wddx_rec->set_row( $row_num, [ ARRAY ] )

Takes a row index and a reference to an array. It replaces that row with
this new array.


=item $wddx_rec->get_column( $col_name )

Takes a column name or index (0 base) and returns a reference to an
array for that column.

=item $wddx_rec->add_column( 'NAME', 'TYPE', [ ARRAY ] )

Takes a column name, type, and a reference to an array and adds the column
to the end of the columns.

=item $wddx_rec->set_column( 'NAME', [ ARRAY ] )

Takes a column name or index (0 base) and a reference to an array.
Replaces the column with the values from this array.

=item $wddx_rec->del_column( $name )

Takes a column name or index (0 base) and deletes the column.


=item $wddx_rec->get_element( $col_name, $row_num )

Takes a column name or index (0 base) and row number and returns the
value of the intersecting cell.

=item $wddx_rec->set_element( $col_name, $row_num, 'New value' )

Takes a row number, a column number, and a value and sets the value of 
the intersecting cell.

=item $wddx_rec->get_field( $row_num, $col_num )

DEPRECATED! Takes a row number and column number and returns the value
of the intersecting cell.

This method is deprecated. Because WDDX often refers to columns in a
recordset as fields, this method name may be confusing. It has been
replaced by get_element() and will be removed in a future version.

=item $wddx_rec->set_field( $row_num, $col_num, 'New value' )

DEPRECATED! Takes a row number, a column number, and a value and sets
the value of the intersecting cell.

This method is deprecated. Because WDDX often refers to columns in a
recordset as fields, this method name may be confusing. It has been
replaced by set_element() and will be removed in a future version.


=back

=head1 Utility Methods

These methods make it easier to go from Perl to WDDX data objects and
vice versa.

=over 4

=item $wddx->wddx2perl( $wddx_obj );

This takes a WDDX data object and returns a scalar if it is a simple
data type, an array reference if it is an array, a hash reference if
it is a struct, and a WDDX::Recordset object if it is a recordset.


=item $wddx->scalar2wddx( $scalar, [ $type ] );

This method takes a scalar and a data type and returns the scalar as a
WDDX data object of the given type. Type should be one of the simple
WDDX data types (i.e. string, number, boolean, datetime, null, or
binary), and if it is not supplied, then string is assumed.

This method is convenient if you have the type stored in a variable,
since it avoids you having to do a bunch of if/else statements to
call the corresponding data object constructor. 

=item $wddx->array2wddx( $arrayref, [ $coderef ] );

=item $wddx->hash2wddx( $hashref, [ $coderef ] );

These methods attempt to provide a way for you to generate complex
WDDX data types from complicated Perl structures. In their simplest
form, they will generate a corresponding WDDX data object by
serializing all scalars as strings. This may be sufficient for your
needs, but it likely will not. Thus, these methods also allow you to
determine the type for each scalar. To do so, you must provide a
reference to a sub.

Your sub will be called for each value within the array or a hash
you supply, as well as each value within any nested arrays or 
hashes. Thus your sub may need to support both hashes and arrays.

If your sub is called within an array, it will receive the following
arguments:

 1. the index of the current element
 2. the value of the current element
 3. the text "ARRAY"
 
If your sub is called within a hash, it will receive the following
arguments:

 1. the key of the current pair
 2. the value of the current pair
 3. the text "HASH"

You must return the type of the data object to construct (e.g.
"number") or a false value if you want to let the element continue to
the next rule. The rules for converting elements into WDDX data
objects are as follows:

=over 2

1. If the element is already a WDDX data object, then it is left
alone.

2. Your subroutine is called (if provided). If a true value is not
returned, then we skip to rule 3. If you return an invalid data type,
then this method C<die>s with an error. If you return a valid data
type then:

=over 2

a. If the current element is a scalar then this element is
converted to a WDDX data object of the type you specified.

b. If the current element is a reference to a hash or an array,
then this hash or array is converted to a WDDX data object with
each element having the type you specified (this applies to
all nested arrays and hashes too).

=back

3. If the current element is a reference to a hash or an array
then C<wddx2array> or C<wddx2hash> is called on it and your sub
(if provided) propagates.

4. Any scalars that have not been handled by a previous rule
are treated as strings.

=back

Here is an example. Assume that you have the following data
structure in Perl:

 $weather_data = {
    title       => "Weather Conditions",
    region      => "San Francisco Bay Area",
    current     => {
      temp      => 72,
      sky       => "mostly clear",
      precip    => undef,
      wind      => 12
    },
    tomorrow    => {
      temps     => [ 62 => 75 ],
      sky       => "partly cloudy",
      precip    => undef,
      winds     => [ 5  => 10 ]
    }
 };

To convert this to a WDDX object you could create a handler and 
use it to create a WDDX object like this:
 
 $type_sub = sub {
    my( $name, $val, $mode ) = @_;
    ! defined( $val )   and return "null";
    $name =~ /temp/     and return "number";
    $name =~ /wind/     and return "number";
 };
 
 my $wddx_weather = $wddx->hash2wddx( $weather_data, $type_sub );

Then you can easily serialize the WDDX object to a packet:
 
 $WDDX::INDENT = "   ";
 print $wddx->serialize( $wddx_weather );

This prints:

 <wddxPacket version='1.0'>
    <header/>
    <data>
       <struct>
          <var name='tomorrow'>
             <struct>
                <var name='temps'>
                   <array length='2'>
                      <number>0</number>
                      <number>1</number>
                   </array>
                </var>
                <var name='precip'>
                   <null/>
                </var>
                <var name='winds'>
                   <array length='2'>
                      <number>0</number>
                      <number>1</number>
                   </array>
                </var>
                <var name='sky'>
                   <string>partly cloudy</string>
                </var>
             </struct>
          </var>
          <var name='title'>
             <string>Weather Conditions</string>
          </var>
          <var name='current'>
             <struct>
                <var name='wind'>
                   <number>12</number>
                </var>
                <var name='precip'>
                   <null/>
                </var>
                <var name='temp'>
                   <number>72</number>
                </var>
                <var name='sky'>
                   <string>mostly clear</string>
                </var>
             </struct>
          </var>
          <var name='region'>
             <string>San Francisco Bay Area</string>
          </var>
       </struct>
    </data>
 </wddxPacket>

Of course, the handler you construct will vary depending on each
particular data structure.


=back

=head1 EXAMPLES

I pulled the examples out of here when I realized that this POD was
over 50 screenfuls on a standard term! For more lengthy examples,
please visit http://www.scripted.com/wddx/ or http://www.wddx.org/.

=head1 BUGS

WDDX does not support 16 bit character sets (at least not without
encoding them as binary objects).

Every element of data must be encoded as an object. This increases
memory usage somewhat, and it also means any data you transfer must
fit in memory.

This is actually a non-bug: XML::Parser untaints data as it parses it.
This is dangerous. WDDX.pm retaints the data it receives from XML::Parser
so you should be safe if you are running in taint mode. Note: WDDX.pm
uses $0 to retaint data, so if you untaint $0 then any subsequent
WDDX.pm data will be untainted too. Taint is explained L<perlsec>. 


=head1 CREDITS

Nate Weiss, the man behind the WDDX SDK, has been an especially huge
help.

David Medinets started an earlier version of a Perl and WDDX module
available at http://www.codebits.com/wddx/.

The following people have helped provide feedback, bug reports, etc.
for this module:

 Thomas R. Hall
 David J. MacKenzie
 Jon Sala
 Wolfgang ???
 James Ritter
 Miguel Marques
 Vadim Geshel
 Adolfo Garcia
 Sean McGeever
 Allie Rogers
 Ziying Sherwin

=head1 AUTHOR

Origianally by Scott Guelich E<lt>scott@scripted.comE<gt>, now maintained
by Andy Lester C<< <andy@petdance.com> >>.
