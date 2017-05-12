package Tivoli::AccessManager::Admin::SSO::Cred;
use strict;
use warnings;
use Carp;
use Tivoli::AccessManager::Admin::Response;
use Tivoli::AccessManager::Admin::SSO::Web;
use Tivoli::AccessManager::Admin::SSO::Group;
use Data::Dumper;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id$
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::SSO::Cred::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::SSO::Cred',
	   );

sub _get_credtype {
    my ($tam,$cred) = @_;
    my $resp;

    my $test = Tivoli::AccessManager::Admin::SSO::Web->new( $tam, name => $cred );
    if ($test->exist) {
	return 'web';
    }
    else {
	$test = Tivoli::AccessManager::Admin::SSO::Group->new( $tam, name => $cred );
	if ($test->exist) {
	    return 'group';
	}
    }

    return '';
}

sub new {
    my $class = shift;
    my $cont = shift;
    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    my $self  = bless {}, $class;
    if ( @_ % 2 ) {
	warn "Incorrent syntax -- I really need a hash\n";
	return undef;
    }
    my %opts  = @_;

    $self->{context} = $cont;
    $self->{resource} = $opts{resource} || '';
    $self->{uid}      = $opts{uid}      || '';
    $self->{ssouid}   = $opts{ssouid}   || '';
    $self->{ssopwd}   = $opts{ssopwd}   || '';
    $self->{type}     = $opts{type}     || '';


    if ( $self->{resource} and not $self->{type} ) {
	$self->{type} = _get_credtype($cont,$self->{resource}) || 'web';
    }

    $self->_ssocred_stash();

    if ( $self->{resource} && $self->{uid} ) {
	my $resp = Tivoli::AccessManager::Admin::Response->new();
	my $rc = $self->ssocred_get($resp);
	$self->{exist} = $rc;
    }
    else {
	$self->{exist} = 0;
    }
    return $self;
}

sub create {
    my $self = shift;

    unless ( ref $self ) {
	my $pd = shift;
	$self = new( $self, $pd, @_ );
    }

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( @_ % 2 ) {
	$resp->set_message("Incorrent syntax -- I really need a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts  = @_;

    $self->{resource}   = $opts{resource}   || $self->{resource}   || '';
    $self->{uid}    = $opts{uid}    || $self->{uid}    || '';
    $self->{type}   = $opts{type}   || $self->{type}   || '';
    $self->{ssouid} = $opts{ssouid} || $self->{ssouid} || '';
    $self->{ssopwd} = $opts{ssopwd} || $self->{ssopwd} || '';

    unless ( $self->{uid} and $self->{ssouid} ) {
	$resp->set_message("You must define both the UID and the SSO UID");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{ssopwd} ) {
	$resp->set_message("You must define the SSO password");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{resource} ) {
	$resp->set_message("You must define the SSO resource");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->ssocred_create($resp);
    if ( $resp->isok ) {
	$rc = $self->ssocred_get($resp);
	$self->{exist} = $rc;
    }
    $resp->set_value($self);

    return $resp;
}
   
# This must be a read only call.  The documentation implies you can change the
# resource id via the ssocred_set call.  I do not think you really can.
sub resource {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $rc = $self->ssocred_getid;
    $self->{resource} = $rc;
    $resp->set_value( $rc );
    return $resp;
}

sub ssopwd {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($ssopwd,$rc);

    if ( @_ == 1 ) {
	$ssopwd = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$ssopwd = $opts{ssopwd} || '';
    }

    if ( defined( $ssopwd ) ) {
	$self->{ssopwd} = $ssopwd;
	$self->ssocred_set($resp);
	$rc = $self->ssocred_get($resp);
    }

    if ( $resp->isok ) {
	$rc = $self->ssocred_getssopassword;
	$self->{ssopwd} = $rc;
	$resp->set_value( $rc );
    }
    return $resp;
}

sub ssouid {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($ssouid,$rc);

    if ( @_ == 1 ) {
	$ssouid = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$ssouid = $opts{ssouid} || '';
    }

    if ( $ssouid ) {
	$self->{ssouid} = $ssouid;
	$self->ssocred_set($resp);
	$rc = $self->ssocred_get($resp);
    }

    if ( $resp->isok ) {
	$rc = $self->ssocred_getssouser;
	$self->{ssopwd} = $rc;
	$resp->set_value( $rc );
    }
    return $resp;
}

# This too must be a read only method.
sub type {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($type,$rc);

    $rc = $self->ssocred_getssotype;
    $self->{type} = $rc;
    $resp->set_value( $rc );

    return $resp;
}

sub user {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($uid,$rc);

    $rc = $self->ssocred_getuser;
    $self->{uid} = $rc;
    $resp->set_value( $rc );
    
    return $resp;
}

sub list {
    my $class = shift;
    my $pd = ref($class) ? $class->{context} : shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($uid,@rc);

    if ( @_ == 1 ) {
	$uid = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$uid = $opts{uid} || '';
    }
    elsif ( ref($class) ) {
	$resp = $class->user;
	$uid = $resp->value;
    }

    unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	$resp->set_message("Incorrect syntax -- did you forget the context?");
	$resp->set_isok(0);
	return $resp;
    }
    unless ( defined($uid) and $uid ) {
	$resp->set_message("Invalid syntax -- please provide the userid");
	$resp->set_isok(0);
	return $resp;
    }

    my @hrefs = ssocred_list($pd,$resp,$uid);
    if ( $resp->isok ) {
	for ( @hrefs ) {
	    push @rc,Tivoli::AccessManager::Admin::SSO::Cred->new($pd, %{$_}); 
	}
	$resp->set_value(\@rc);
    }
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->exist ) {
	$resp->set_message("The SSO Cred " . $self->resource . " does not exist");
	$resp->set_iswarning(1);
	return $resp;
    }

    my $rc = $self->ssocred_delete($resp);
    $resp->set_value($rc);
    $self->{exist} = 0 if $resp->isok;
    return $resp;
}

sub exist { return $_[0]->{exist}; }

sub DESTROY {
    my $self = shift;

    $self->_ssocredfree;
}

1;

=head1 NAME

Tivoli::AccessManager::Admin::SSO::Cred

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;

    my $pd = Tivoli::AccessManager::Admin->new( password => 'N3ew0nk' );
    my $sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd,
					resource => 'fred',
					uid  => 'mik',
					ssouid => 'mikfire',
					ssopwd => 'pa$$w0rd',
				      ); 
    unless ( $sso->exist ) {
	$resp = $sso->create;
    }

    $resp = $sso->resource();

    $resp = $sso->ssopwd('derf');

    $resp = $sso->ssopwd();

    # SSOUID
    $resp = $sso->ssouid('derf');

    $resp = $sso->ssouid();

    # TYPE
    $resp = $sso->type();

    # USER
    $resp = $sso->user();

    $resp = $sso->list();
    for ( $resp->value ) {
	isa_ok($_, "Tivoli::AccessManager::Admin::SSO::Cred");
    }

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::SSO::Cred> provides the interface to create and modify GSO
credentials.

=head1 CONSTRUCTOR

=head2 new(PDADMIN[,resource =E<gt> NAME, uid =E<gt> UID, ssouid =E<gt> GSO User ID, ssopwd =E<gt> GSO password, type =E<gt> E<lt>web|groupE<gt>])

Creates a blessed L<Tivoli::AccessManager::Admin::SSO::Cred> object.  

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  As with every other class, the
only way to change the context is to destroy the L<Tivoli::AccessManager::Admin::SSO::Cred>
object and recreate it with the new context.  This parameter is required.

=item resource =E<gt> NAME

The name of the GSO resource.  This resource must already exist or an error
will be generated.  This parameter is optional but can only be provided to
L</"new"> or L</"create">.  Most other methods will not work without the
resource name.

=item uid =E<gt> UID

The user's ID in TAM.  As with resource, this parameter is optional, but can
only be given to L</"new"> or L</"create">.  Most of the methods will not work
without it.

=item ssouid =E<gt> GSO User ID

The user ID to presented to the back end.  This parameter is optional and can
be provided/changed at any time.

=item ssopwd =E<gt> GSO password

The password to be presented to the back end.  This parameter is optional and
can be changed/provided when ever.  I should make the observation that this
password is stored in plain text in the L<Tivoli::AccessManager::Admin::SSO::Cred> object.  This
means it may be readable in a core dump or something similar.  Caveat emptor.

=item type =E<gt> E<lt>web|groupE<gt>

Defines the resource as a web or group resource.  This is optional.  If not
provided, I will try to figure it out.  If I cannot figure out, it defaults to
"web".

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::SSO::Cred> object under normal circumstances,
undef otherwise.  Since no TAM API calls are made by this method, "other" can
loosely be defined as "syntax error".

=head2 create(PDADMIN,resource =E<gt> NAME, uid =E<gt> UID, ssouid =E<gt> GSO User ID, ssopwd =E<gt> GSO password[, type =E<gt> E<lt>web|groupE<gt>])

Initializes the L<Tivoli::AccessManager::Admin::SSO::Cred> and creates it in TAM as well.

=head3 Parameters

See the parameter list for L</"new">.  The only difference is that all of the
parameters except type are now required.

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object indicating the success or failure of the
create operation.  If it could be created, the new L<Tivoli::AccessManager::Admin::SSO::Cred>
object will be embedded in the response object as well.

=head1 CLASS METHODS

=head2 list(PDADMIN, 'uid')

Lists all GSO credentials for the provided uid.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  

=item uid =E<gt> UID

The user's ID in TAM.  

=back

=head3 Returns

A list of initialized L<Tivoli::AccessManager::Admin::SSO::Cred> objects, one for each GSO
credential the user has.  This list may be empty.  Please do note that this is
different from every other list method in Tivoli::AccessManager::Admin.

This list is, of course, embedded in a L<Tivoli::AccessManager::Admin::Response> object.

=head1 METHODS

The standard disclaimer.  All the methods will return a
L<Tivoli::AccessManager::Admin::Response> object unless specifically stated otherwise.  See the
documentation for that module on how to coax the values out.

The methods also follow the same basic pattern.  If an optional parameter is
provided, it will have the affect of setting the attribute.  All method calls
will embed the results of a 'get' in the L<Tivoli::AccessManager::Admin::Response> object.

=head2 create( [resource =E<gt> NAME, uid =E<gt> UID, ssouid =E<gt> GSO User ID, ssopwd =E<gt> GSO password, type =E<gt> E<lt>web|groupE<gt>])

As you might expect, create can also be used as a method call.

=head3 Parameters

See L</"new"> for a full description.  Only those parameters not provided to
L</"new"> need to be sent to L</"create">.  However, all of them need to be
provided to one method or the other (except type) for the create call to work.

=head3 Returns

The success or failure of the operation.

=head2 delete

Deletes the user's GSO cred.

=head3 Parameters

None.

=head3 Returns

The success or failure of the operation.

=head2 ssopwd('password')

Gets/sets the GSO password for this resource.

=head3 Parameters

=over 4

=item 'password'

The new GSO password.

=back

=head3 Returns

The GSO password.  Need I repeat the warnings about plain text passwords in
memory?

=head2 ssouid('UID')

Gets/sets teh GSO user ID.

=head3 Parameters

=over 4

=item 'UID'

The new GSO user ID.

=back

=head3 Returns

The GSO user ID.  

The following methods are all read only.  The documentation for the underlying
API calls implies otherwise, but I was not able to make it work.  Rather than
cause problems, I thought it better to make them read only.

=head2 resource

Returns the name of the GSO resource to which the cred belongs.  

=head3 Parameters

None.

=head3 Returns

The name of the GSO resource.

=head2 type

Returns the type of the GSO resource 

=head3 Parameters

None.

=head3 Returns

'web' or 'group'

=head2 user

Returns the TAM user ID associated with the resource

=head3 Parameters

None.

=head3 Returns

The TAM user ID

=head2 exist

Determines of the GSO cred exists or not.

=head3 Parameters

None.

=head3 Returns

1 if the object exists, 0 otherwise.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than I.

=head1 BUGS

None known.

=head1 TODO

I need to figure out if the three read only methods can be made read/write.

I need to make the create and new methods smarter.  I would really like them
to be able to figure out if the resource is a web or group resource.  I would
also like a force option that will create the GSO resource if:
   o it does not already exist and
   o the type was provided in the method call

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

static char* _getresource( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "resource", 8, 0 );

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

static unsigned long _gettype( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "type", 4, 0 );
    unsigned long type;

    if ( fetched ) {
	type = strcmp( SvPV_nolen(*fetched), "web" ) ? 
		    IVADMIN_SSOCRED_SSOGROUP : IVADMIN_SSOCRED_SSOWEB;
    }
    else {
	type = IVADMIN_SSOCRED_SSOWEB;
    }

    return type;
}

static char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched = hv_fetch( self_hash, key, strlen(key), 0 );

    return( fetched ? SvPV_nolen(*fetched) : NULL );
}

void _ssocred_stash( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_ssocred",8,1);
    ivadmin_ssocred* sso;

    Newz( 5, sso, 1, ivadmin_ssocred );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _ssocred slot");
    }

    sv_setiv(*fetched, (IV) sso );
    SvREADONLY_on(*fetched);
}

static ivadmin_ssocred* _get_ssocred( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_ssocred", 8, 0 );

    return( fetched ? (ivadmin_ssocred*) SvIV(*fetched) : NULL );
}

int ssocred_create( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *resource         = _getresource(self);
    unsigned long type = _gettype(self);

    char *uid     = _fetch(self,"uid");
    char *ssouid  = _fetch(self,"ssouid");
    char *ssopwd  = _fetch(self,"ssopwd");

    unsigned long rc = 0;

    if ( resource == NULL )
	croak("ssocred_create: invalid resource name");

    if ( uid == NULL )
	croak("ssocred_create: invalid uid");

    if ( ssouid == NULL )
	croak("ssocred_create: invalid GSO id");

    if ( ssopwd == NULL )
	croak("ssocred_create: invalid GSO password");

    rc = ivadmin_ssocred_create( *ctx,
				 resource,
				 type,
				 uid,
				 ssouid,
				 ssopwd,
				 rsp );
    return( rc == IVADMIN_TRUE );
}

int ssocred_delete(SV* self,SV* resp) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *resource    = _getresource(self);
    unsigned long type = _gettype(self);

    char *uid     = _fetch(self,"uid");

    unsigned long rc = 0;

    if ( resource == NULL )
	croak("ssocred_delete: invalid resource name");

    if ( uid == NULL )
	croak("ssocred_delete: invalid uid");

    rc = ivadmin_ssocred_delete( *ctx,
				 resource,
				 type,
				 uid,
				 rsp );
    return( rc == IVADMIN_TRUE );
}

int ssocred_get( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    ivadmin_ssocred*  sso = _get_ssocred(self);
    char *ssoid           = _getresource(self);
    unsigned long type    = _gettype(self);

    char* uid             = _fetch(self,"uid");
    unsigned long rc;

    if ( sso == NULL ) {
	_ssocred_stash(self);
	sso = _get_ssocred(self);
    }

    if ( ssoid == NULL )  {
	croak("ssocred_get: could not retrieve resource");
    }

    if ( sso == NULL ) {
	croak("ssocred_get: Couldn't retrieve the ivadmin_ssocred object");
    }

    if ( uid == NULL )
	croak("ssocred_get: invalid uid");

    rc = ivadmin_ssocred_get( *ctx,
    			  ssoid,
			  type,
			  uid,
			  sso,
			  rsp );

    return( rc == IVADMIN_TRUE );
}

SV* ssocred_getid(SV* self) {
    ivadmin_ssocred* sso = _get_ssocred(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssocred_getid: Couldn't retrieve the ivadmin_ssocred object");
    }

    answer = ivadmin_ssocred_getid(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

SV* ssocred_getssopassword( SV* self ) {
    ivadmin_ssocred* sso = _get_ssocred(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssocred_getssopassword: Couldn't retrieve the ivadmin_ssocred object");
    }

    answer = ivadmin_ssocred_getssopassword(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

SV* ssocred_getssouser( SV* self ) {
    ivadmin_ssocred* sso = _get_ssocred(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssocred_getssouser: Couldn't retrieve the ivadmin_ssocred object");
    }

    answer = ivadmin_ssocred_getssouser(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

SV* ssocred_getssotype( SV* self ) {
    ivadmin_ssocred* sso = _get_ssocred(self);

    if ( sso == NULL ) {
	croak("ssocred_getssotype: Couldn't retrieve the ivadmin_ssocred object");
    }

    return(ivadmin_ssocred_gettype(*sso) == IVADMIN_SSOCRED_SSOWEB ? newSVpv("web",0) : newSVpv("group",0));
}

SV* ssocred_getuser( SV* self ) {
    ivadmin_ssocred* sso = _get_ssocred(self);
    const char *answer;

    if ( sso == NULL ) {
	croak("ssocred_getuser: Couldn't retrieve the ivadmin_ssocred object");
    }

    answer = ivadmin_ssocred_getuser(*sso);
    return( answer ? newSVpv(answer,0) : NULL );
}

/* This one is a bit tricky.  The list function actually returns a list of
* ivadmin_ssocred structs.  I am pushing those into an array of hashes -- the
* calling code will have to make them into objects and embed the context
*/
void ssocred_list( SV* pd, SV* resp, char* uid ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    ivadmin_ssocred* credlist;
    HV* hash;
    SV** fetched;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_ssocred_list( *ctx,
			       uid,
    			       &count,
			       &credlist,
			       rsp
			     );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    hash = newHV();
	    hv_store(hash,"_ssocred",8,
		     newSViv((IV)&credlist[i]),
		     0 );
	    hv_store(hash, "resource", 8,
		     newSVpv(ivadmin_ssocred_getid(credlist[i]),0),
		     0 );
	    hv_store(hash, "type", 4,
		     newSVpv(ivadmin_ssocred_gettype(credlist[i]) == IVADMIN_SSOCRED_SSOWEB ? "web" : "group", 0),
		     0 );
	    hv_store(hash, "uid", 3,
		     newSVpv(ivadmin_ssocred_getuser(credlist[i]),0),
		     0 );
	    hv_store(hash,"ssouid", 6,
		     newSVpv(ivadmin_ssocred_getssouser(credlist[i]),0),
		     0 );
	    hv_store(hash,"ssopwd", 6,
		     newSVpv(ivadmin_ssocred_getssopassword(credlist[i]),0),
		     0 );
	    Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*)hash)));
	}
    }
    Inline_Stack_Done;
}

int ssocred_set( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    char* ssoid           = _getresource(self);
    unsigned long type    = _gettype(self);
    char* uid             = _fetch(self,"uid");
    char* ssouid          = _fetch(self,"ssouid");
    char* ssopwd          = _fetch(self,"ssopwd");

    unsigned long rc = 0;

    if ( ssoid == NULL )
	croak("ssocred_set: invalid resource");

    if ( uid == NULL )
	croak("ssocred_set: invalid uid");

    if ( ssouid == NULL )
	croak("ssocred_set: invalid GSO uid");

    if ( ssopwd == NULL )
	croak("ssocred_set: invalid GSO password");

    rc = ivadmin_ssocred_set( *ctx,
			      ssoid,
			      type,
			      uid,
			      ssouid,
			      ssopwd,
			      rsp );
    return( rc == IVADMIN_TRUE );
}

void _ssocredfree( SV* self ) {
    ivadmin_ssocred* cred = _get_ssocred(self);
    
    if ( cred != NULL )
	Safefree(cred);

    hv_delete((HV*)SvRV(self),"_ssocred", 8, 0);
}
