package Yahoo::Marketing::DateTimeAccessor;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;
use base qw/ Class::Accessor::Chained /;

use DateTime::Format::W3CDTF;
use DateTime::Format::ISO8601;

sub _force_datetime_object {
    my ( $self, $value ) = @_;

    if( defined $value ){ 
        unless( ref $value ){  # not a date time object
            $value = DateTime::Format::ISO8601->new->parse_datetime( $value );
        }   
        # let's hope it looks like a duck... er, DateTime object
        $value->set_formatter( DateTime::Format::W3CDTF->new );
    }

    return $value;
}

sub set {
    my ( $self, $key, @values ) = @_;

    if ( $key =~ /Date$/ || $key =~ /Timestamp$/ ){
        @values = map { $self->_force_datetime_object( $_ ) } @values;
    }

    $self->SUPER::set( $key, @values );
}

1;

__END__

=head1 NAME

Yahoo::Marketing::DateTimeAccessor - provides a tweak to Class::Accessor's 
                                     set method to handle date time fields specially

=cut

=head1 SYNOPSIS


This module is used by the complex types to provide special setter functionality for *Date and *Timestamp fields.  It inherits from Class::Accessor::Chained, and overrides the set method to do the following: 

If a field appears to be a Date field or Timestamp field, the value passed in is turned into a DateTime object if it's a string, otherwise we assume it's a DateTime object and just ensure that the formatter is set appropriately.  DateTime with their formatter set properly should stringify correctly, so this behavior should be pretty transparent to users.  

You can use DateTime objects if you like, or use strings, and it should "just work".

=cut

=head1 CAVEATS

Timestamp fields in EWS are returned with nanoseconds.  DateTime::Format::ISO8601 has support for parsing dates in this format, but it cannot print them.  Therefore, the returned DateTime objects use DateTime::Format::W3CDTF as a formatter, which will not print the nanosecond portion of the DateTime.  If you need nanosecond support, please file an RT bug and some solution will be found (probably providing a way to turn off automatic date/timestamp handling all together).

=cut 

=head1 METHODS

=head2 set

Overrides the set method in Class::Accessor to provide automatic date/timestamp handling.  See SYNOPSIS above.

=cut


