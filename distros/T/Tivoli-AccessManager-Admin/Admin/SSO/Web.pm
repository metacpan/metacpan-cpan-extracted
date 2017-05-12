package Tivoli::AccessManager::Admin::SSO::Web;
use strict;
use warnings;
use Carp;
use Tivoli::AccessManager::Admin::Response;
use Data::Dumper;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id$
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::SSO::Web::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::SSO::Web',
	   );

sub new {
    my $class = shift;
    my $cont = shift;
    my $self = {};
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($name,$desc);

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    bless $self, $class;

    if ( @_ == 1 ) {
	$name = shift;
    }
    elsif ( @_ % 2 ) {
	warn "Invalid parameter list -- please use a hash\n";
	return undef;
    }
    else {
	my %opts = @_;
	$name = $opts{name} || '';
	$desc = $opts{desc} || '';
    }

    $self->{name} = $name;
    $self->{context} = $cont;
    $self->{desc} = $desc;
    $self->_ssoweb_stash();

    if ( $name ) {
	$self->{exist} = $self->ssoweb_get( $resp );
    }
    else {
	$self->{exist} = 0;
    }

    return $self;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($name,$desc);

    unless ( ref( $self ) ) {
	my $pd = shift;
	$self = $self->new( $pd, @_ );
	unless ( defined $self ) {
	    $resp->set_message("Couldn't instatiate the resource");
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    if ( @_ == 1 ) {
	$self->{name} = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid parameter list -- please use a hash");
	$resp->set_isok(0);
	return $resp;
    }
    else {
	my %opts = @_;
	$self->{name} = $opts{name} || $self->{name} || '';
	$self->{desc} = $opts{desc} || $self->{desc} || '';
    }

    unless ( $self->{name} ) {
	$resp->set_message("I cannot create an unnamed SSO resource");
	$resp->set_isok(0);
	return $resp;
    }

    if ( $self->exist ) {
	$resp->set_message("The SSO resource " . $self->name . " already exists");
	$resp->set_value($self);
	$resp->set_iswarning(1);
	return $resp;
    }

    my $rc = $self->ssoweb_create($resp);
    $self->{exist} = $rc;

    if ( $rc ) {
	$resp->set_value($self);
    }

    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->exist ) {
	$resp->set_message("SSO resource " . $self->name . " doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->ssoweb_delete($resp);
    if ($rc) {
	$self->{exist} = 0;
    }
    $resp->set_value($rc);
    return $resp;
}

sub list {
    my $class = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $pd;

    # I want this to be called as either Tivoli::AccessManager::Admin::User->list or
    # $self->list
    if ( ref($class) ) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
    }

    unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	$resp->set_message("Incorrect syntax -- did you forget the context?");
	$resp->set_isok(0);
	return $resp;
    }

    my @rc = ssoweb_list($pd,$resp);
    $resp->isok() && $resp->set_value( $rc[0],\@rc );
    return $resp;
}

sub name { 
    my $self = shift;
    my $name = $self->{name} || '';

    return $name;
}

sub description { 
    my $self = shift;
    my $desc = $self->{desc} || '';

    return $desc;
}

sub exist { return $_[0]->{exist} || 0; }

1;

=head1 NAME

Tivoli::AccessManager::Admin::SSO::Web

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;

    my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
    my $sso = Tivoli::AccessManager::Admin::SSO::Web->new( $pd, name => 'twiki' );
    my $resp;

    # See what web GSO resources exist
    $resp = Tivoli::AccessManager::Admin::SSO::Web->list($pd);
    print join("\n", $resp->value);
    
    # Create the web SSO resource if it doesn't exist
    $sso = Tivoli::AccessManager::Admin::SSO::Web->new($pd) unless $sso->exist;

    my $name = $sso->name;
    my $desc = $sso->description

    $resp = $sso->delete;


=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::SSO::Web> provides the interface to create and manage web GSO
resources.

=head1 CONSTRUCTOR

=head2 new(PDADMIN[, name => STRING, desc => STRING])

Creates a blessed L<Tivoli::AccessManager::Admin::SSO::Web> object and returns it.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  As with every other class, the
only way to change the context is to destroy the L<Tivoli::AccessManager::Admin::SSO::Web>
object and recreate it with the new context.  This parameter is required.

=item name =E<gt> STRING

The name of the SSO web resource.  If this is the only other parameter
provided, you do not need to use a named parameter.  I.e., new($pd,"name")
will assume "name" is the name of the resource.  This parameter is optional.

=item desc =E<gt> STRING

A description of the resource.  This is an optional parameter.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::SSO::Web> object if things worked.  undef will be
returned otherwise, along with a nasty warning to STDERR.

=head2 create(PDADMIN, <NAME|name =E<gt>  name, desc =E<gt>  STRING>)

Creates a new web GSO resource.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  As with every other class, the
only way to change the context is to destroy the L<Tivoli::AccessManager::Admin::SSO::Web>
object and recreate it with the new context.  This parameter is required.

=item NAME

If only one parameter provided other than PDADMIN is provided, it will be
interpreted as the name of the GSO web resource.  You must provide the name of
the resource to create -- either this way or the next way.

=item name =E<gt> NAME

An alternate way to provide the reource's name.

=item desc =E<gt> STRING

Provide a description for the GSO resource.  The only way to provide this to
create is to use the full named parameter call.  It is an optional parameter.

I should also note that this is the only way to set the description -- the API
provides no way to change the description after the resource is created.

=back

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object, containing the L<Tivoli::AccessManager::Admin::SSO::Web>
object if the create was successful.  Otherwise you will get an error message.

=head1 CLASS METHODS

The standard disclaimer.  All the class methods will return a
L<Tivoli::AccessManager::Admin::Response> object unless specifically stated otherwise.  See the
documentation for that module on how to coax the values out.

=head2 list

Lists all the defined web resources.

=head3 Parameters

None.

=head3 Returns

A list of the defined web GSO resources.

=head1 METHODS

The standard disclaimer.  All the methods will return a
L<Tivoli::AccessManager::Admin::Response> object unless specifically stated otherwise.  See the
documentation for that module on how to coax the values out.

The methods also follow the same basic pattern.  If an optional parameter is
provided, it will have the affect of setting the attribute.  All method calls
will embed the results of a 'get' in the L<Tivoli::AccessManager::Admin::Response> object.

=head2 create( [NAME|name =E<gt> NAME[, desc =E<gt> STRING]] )

As you might expect, create can also be used as a method call.

=head3 Parameters

=over 4

=item NAME

The name of the resource.  This is only required if you did not provide the
name of the resource when you created the object and if you are not using the
named parameter call.

If you provide the name to both L</"new"> and L</"create">, the name given to
L</"create"> will be the one used.

=item name =E<gt> NAME

An alternate way to provide the name of the resource.  If you want to provide
a description of the resource, you must use this form.

=item desc =E<gt> STRING

A description of the resource.  This is optional.  If you provide a
description to both L</"new"> and L</"create">, the description given to
L</"create"> will be the one used.

I should also note that this is the only way to set the description -- the API
provides no way to change the description after the resource is created.

=back

=head3 Returns

The success or failure of the operation.

=head2 delete

Deletes the web resource.

=head3 Parameters

None.

=head3 Returns

The success of failure of the operation.

=head2 list

As should be no surprise, L</"list"> can be used as an instance method as
well.  I don't think it makes any sense, but you can do it.

=head3 Parameters

None

=head3 Returns

A list of the defined web GSO resources.

=head2 name

Gets the name of the web resource.

=head3 Parameters

None.

=head3 Returns

The name of the resource.  This is returned as a string -- it is not embedded
in an L<Tivoli::AccessManager::Admin::Response> object.

=head2 description

Gets the web resource's description, if set.

=head3 Parameters

None.

=head3 Returns

The resource's description, if set.  This is returned as a string -- it is not
embedded in an L<Tivoli::AccessManager::Admin::Response> object.  You will get
an empty string if the description is not set.

=head2 exist

Determines if the web resource object exists.

=head3 Parameters

None.

=head3 Returns

True if the resource exists, false otherwise.  Again, this is not embedded in an L<Tivoli::AccessManager::Admin::Response> object.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than I.

=head1 BUGS

None known.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

=cut

__DATA__
__C__

#include "ivadminapi.h"
#include "ogauthzn.h"
#include "aznutils.h"

static ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL ) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return rsp;
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return (ivadmin_context*)SvIV(SvRV(*fetched));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched  = hv_fetch( self_hash, key, strlen(key), 0 );

    return( fetched ? SvPV_nolen( *fetched ) : NULL );
}

void _ssoweb_stash( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_ssoweb",7,1);
    ivadmin_ssoweb* sso;

    Newz( 5, sso, 1, ivadmin_ssoweb );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _ssocred slot");
    }

    sv_setiv(*fetched, (IV) sso );
    SvREADONLY_on(*fetched);
}

static ivadmin_ssoweb* _get_ssoweb( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_ssoweb", 7, 0 );

    return( fetched ? (ivadmin_ssoweb*) SvIV(*fetched) : NULL );
}

int ssoweb_create(SV* self, SV* resp) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);
    const char* desc = _fetch(self,"desc");

    unsigned long rc = 0;

    if ( name == NULL )
	croak("ssoweb_create: invalid name");

    if ( desc == NULL ) 
	desc = "";

    rc = ivadmin_ssoweb_create( *ctx,
				 name,
				 desc,
				 rsp );
    return( rc == IVADMIN_TRUE );
}

int ssoweb_delete(SV* self, SV* resp) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char *name    = _getname(self);

    unsigned long rc = 0;

    if ( name == NULL )
	croak("ssoweb_delete: invalid name");

    rc = ivadmin_ssoweb_delete( *ctx,
				 name,
				 rsp );
    return( rc == IVADMIN_TRUE );
}

int ssoweb_get( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    ivadmin_ssoweb*  sso  = _get_ssoweb(self);
    const char *name      = _getname(self);

    unsigned long rc;

    if ( sso == NULL ) {
	_ssoweb_stash(self);
	sso = _get_ssoweb(self);
    }

    if ( name == NULL )  {
	croak("ssoweb_get: could not retrieve name");
    }

    if ( sso == NULL ) {
	croak("ssoweb_get: Couldn't retrieve the ivadmin_ssoweb object");
    }

    rc = ivadmin_ssoweb_get( *ctx,
    			  name,
			  sso,
			  rsp );

    return( rc == IVADMIN_TRUE );
}

SV* ssoweb_getdescription(SV* self) {
    ivadmin_ssoweb* sso = _get_ssoweb(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssoweb_getdescription: Couldn't retrieve the ivadmin_ssoweb object");
    }

    answer = ivadmin_ssoweb_getdescription(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

SV* ssoweb_getid(SV* self) {
    ivadmin_ssoweb* sso = _get_ssoweb(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssoweb_getid: Couldn't retrieve the ivadmin_ssoweb object");
    }

    answer = ivadmin_ssoweb_getid(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

void ssoweb_list(SV* pd,SV* resp) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char** list;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_ssoweb_list( *ctx,
    			       &count,
			       &list,
			       rsp
			     );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(list[i],0)));
	    ivadmin_free(list[i]);
	}
    }
    Inline_Stack_Done;
}

void _ssowebfree( SV* self ) {
    ivadmin_ssoweb* web = _get_ssoweb(self);
    
    if ( web != NULL )
	Safefree(web);

    hv_delete((HV*)SvRV(self),"_ssoweb", 7, 0);
}
