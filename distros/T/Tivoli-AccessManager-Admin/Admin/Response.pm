package Tivoli::AccessManager::Admin::Response;
use strict;
use warnings;
use Carp;
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Response.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::Response::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-g -Wall',
		VERSION => '1.11',
		NAME   => 'Tivoli::AccessManager::Admin::Response',
	  );

my %codes  = (
    INFO    => 0,
    WARNING => 1,
    ERROR   => 2,
);

sub _get_type {
    my $self = shift;
    my $type = shift;

    return 0 unless ( $self->{used} );
    for ( my $i = 0; $i < $self->response_getcount(); $i++ ) {
	if ( $self->response_getmodifier( $i ) == $codes{$type} ) {
	    return 1;
	}
    }
    return 0;
}

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_response();
    $self->{isok}      = 1;
    $self->{iswarning} = 0;
    $self->{iserror}   = 0;
    $self->{used}      = 0;
    $self->{value}[0] = undef;
    $self->{value}[1]  = undef;

    return $self;
}

sub value { 
    my $self = shift;

    return undef unless $self->isok;

    if ( wantarray ) {
	return @{$self->{value}[1]} if defined($self->{value}[1]);
	return ();
    }
    else {
	return $self->{value}[0] if defined($self->{value}[0]); 
	return scalar(@{$self->{value}[1]}) if defined($self->{value}[1]);
	return undef;
    }
}

sub messages {
    my $self = shift;
    my @message = ();

    if ( defined $self->{messages} ) {
	@message  = @{$self->{messages}};
    }

    if ($self->{used} ) {
	my $count = $self->response_getcount();
	for ( my $foo = 0; $foo < $count; $foo++ ) {
	    push @message, $self->response_getmessage( $foo );
	}
    }
    return wantarray ? @message : $message[0];
}

sub codes {
    my $self = shift;
    my @code;

    return 0 unless $self->{used};
    if ( wantarray ) {
	for ( my $i = 0; $i < $self->response_getcount(); $i++ ) {
	    push @code, $self->response_getcode($i);
	}
	return @code;
    }
    else {
	return $self->response_getcode(0);
    }
}

sub isok { 
    my $self = shift;

    if ( $self->{used} ) {
	return $self->response_getok() && $self->{isok};
    }
    else {
	return $self->{isok};
    }
}

sub DESTROY {
    my $self = shift;

    $self->response_free();
}

sub set_value { 
    my $self = shift;

    # I think I want to clear everything out before I start setting it.  I
    # think.
    @{$self->{value}} = ();

    # Pay close attention to the last two conditions -- they are different.
    # The first condition performs a straight assignment between the values
    # array and what I was sent.  The second one dumps the entire contents of
    # @_ into value[1].  Very different.
    if ( @_ == 1 ) {
	my $foo = shift;
	$self->{value}[ref($foo) eq 'ARRAY'] = $foo;
    }
    elsif ( @_ == 2 and ref($_[1]) eq 'ARRAY' ) {
	@{$self->{value}} = @_;
    }
    elsif ( @_ >= 2 ) {
	@{$self->{value}[1]} = @_;
    }
    else { 
	return 0;
    }
    return 1;
}

sub set_message { 
    my $self = shift;
    my @mesgs = @_;

    push @{$self->{messages}}, @mesgs;
}

sub set_isok      { $_[0]->{isok} = $_[1]; }
sub set_iswarning { $_[0]->{iswarning} = $_[1]; }
sub set_iserror   { $_[0]->{iserror} = $_[1]; }
sub iserror   { $_[0]->_get_type( "ERROR" ) || $_[0]->{iserror}; }
sub iswarning { $_[0]->_get_type( "WARNING" ) || $_[0]->{iswarning}; }
sub isinfo    { $_[0]->_get_type( "INFO" ); }

1;

=head1 NAME

Tivoli::AccessManager::Admin::Response

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;

    $resp = Tivoli::AccessManager::Admin::Response->new;

    $resp->iserror and die $resp->messages;

    $resp->set_isok(0);
    $resp->set_message("Line1", "Line2", "Line3");
    $resp->set_iswarning(1);

    $resp->set_value( "foo" );
    print $resp->value;


=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::Response> is the general purpose object returned by just about
every other method.  It handles the response structures returned from the TAM
API and provides a fair amount of other manipulations.

=head1 CONSTRUCTOR

=head2 new()

Allocates space for the response structure and does the necessary magic to
make it work.

=head3 Parameters

None

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::Response> object.

=head1 METHODS

=head2 value

Retrieves the value stored in the Response object.  It is, as you may suspect,
a read-only method.  As every method in the TAM namespace returns an object of
this type, you will likely only use isok more often.

=head3 Returns

The return should DWYM.  It can return a scalar in scalar context, an array in
list context and undef otherwise.  It tries hard to guess what you meant.  If
you call it in list context and the response object has an array ref, the
right thing happens.

=head2 isok

Indicates if the Response object is .. well, okay.  If the underlying TAM
Response structure has been used, L</"isok"> will return the value of
ivadmin_response_isok logically anded with internal isok value.  If the
structure hasn't been used, L</"isok"> will return the value of its internal isok
flag.

I am still not certain that isok = ! error.

=head3 Returns

True if the flags are so aligned :)

=head2 iserror, iswarning, isinfo

These are read-only methods which return true if the Response object is 
flagged as an error, warning or informational respectively

=head3 Returns

True if the response is an error, a warning or informational. 

=head2 messages

Returns the messages in the Response object.  This is a read-only method.

=head3 Returns

If used in scalar context, only the first message in the message array is
returned.  If used in array context, the full message array will be returned.

=head2 codes

Retrieves the error codes associated with the Response object.  This is a
read-only method.

=head3 Returns

If used in scalar context, only the first code in the code array is
returned.  If used in array context, the full code array will be returned.

=head2 set_value( VALUE | VALUE,ARRAYREF | ARRAY )

Sets the returned value, but does it weirdly.  

If you just send a single parameter, the value will be returned when the
response object is used in scalar context.

If you send a value and an array reference, the value will be returned in
scalar context and the list from the array ref will be returned in list
context.

If you send more than two parameters, the entire list is stored and will be
returned in list context.  Scalar context will give you the number of
elements.

=head2 set_message( STRING[,...] )

Sets the message(s) in the Response object.  You can send any number of
strings to be included in the message.

=head3 Parameters

=over 4

=item STRING[,...]

The message you want to store.

=back

=head3 Returns

I honestly have no idea what it returns.

=head2 set_isok( 0 | 1 )

Sets the isok flag to true or false.

=head3 Parameters

=over 4

=item 0 or 1

Do you want the isok flag to be false or true?

=back

=head3 Returns

The new value of the isok flag although you will likely never need to actually
test the return value 

=head2 set_iswarning( 0|1 )

Sets the iswarning flag to false or true.

=head3 Parameters

=over 4

=item 0 or 1

Do you want the iswarning flag to be false or true?

=back

=head3 Returns

The new value of the iswarning flag, although you will likely never need to
actually test the return value 

=head2 set_iserror( 0|1 )

Sets the iswarning flag to false or true.

=head3 Parameters

=over 4

=item 0 or 1

Do you want the iserror flag to be false or true?

=back

=head3 Returns

The new value of the iserror flag, although you will likely never need to
actually test the return value 

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list of all the people I am indebted to for their
help while writing these modules.

=head1 BUGS

None known yet.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted by IBM.

=cut

__DATA__
__C__

#include "ivadminapi.h"

ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL ) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    return rsp;
}

void _response( SV* self ) {
    ivadmin_response *rsp;
    int id = 5;
    
    Newz( id, rsp, 1, ivadmin_response );

    /* Create the hash key */
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "response", 8, 1 );

    if ( fetched == NULL ) {
	croak("Couldn't create the _response slot in $self");
    }

    sv_setiv(*fetched, (IV) rsp );
    SvREADONLY_on(*fetched);
}

int response_getok( SV* resp ) {
    ivadmin_response* rsp = _getresponse( resp );

    return(ivadmin_response_getok( *rsp ));
}

int response_getcode( SV* resp, int i ) {
    ivadmin_response* rsp = _getresponse( resp );
    return(ivadmin_response_getcode( *rsp, i ));
}

int response_getcount( SV* resp ) {
    ivadmin_response* rsp = _getresponse( resp );
    return(ivadmin_response_getcount( *rsp ));
}

SV* response_getmessage( SV* resp, int i ) {
    ivadmin_response* rsp = _getresponse( resp );
    const char* msg;

    msg = ivadmin_response_getmessage( *rsp, i );
    return(msg ? newSVpv(msg,0) : NULL);
}

int response_getmodifier( SV* resp, int i ) {
    ivadmin_response* rsp = _getresponse( resp );
    return(ivadmin_response_getmodifier(*rsp, i));
}

void response_free( SV* self ) {
    ivadmin_response* rsp = _getresponse( self );
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "response", 8, 0 );

    Safefree( rsp );

    SvREADONLY_off(*fetched);
    sv_setiv(*fetched, (IV) &PL_sv_undef );
    SvREADONLY_on(*fetched);
}
