package Tivoli::AccessManager::Admin::SSO::Group;
use strict;
use warnings;
use Carp;
use Tivoli::AccessManager::Admin::Response;
use Data::Dumper;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id$
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::SSO::Group::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::SSO::Group',
	   );

sub new {
    my $class = shift;
    my $cont = shift;
    my ($name,$desc,$resources);
    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if ( @_ == 1 ) {
	$name = shift;
	$desc = '';
	$resources = [];
    }
    elsif ( @_ % 2 ) {
	warn "Invalid parameter list -- please use a hash\n";
	return undef;
    }
    else {
	my %opts = @_;
	$name = $opts{name} || '';
	$desc = $opts{description} || '';
	$resources = $opts{resources} || [];
    }

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $self = bless {}, $class;
    $self->{name}        = $name;
    $self->{description} = $desc;
    for ( @{$resources} ) {
	push @{$self->{resources}}, ref($_) ? $_->name : $_;
    }
    $self->{context}	 = $cont;
    $self->{exist} = 0;

    if ($self->{name}) {
	$self->{exist} = $self->ssogroup_get($resp);
	if ( $resp->isok ) {
	    $self->{description}  = $self->ssogroup_getdescription();
	    @{$self->{resources}} = $self->ssogroup_getresources();
	}
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
	unless (defined $self) {
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
	$self->{description} = $opts{description} || $self->{description} || '';
	$self->{resources} = $opts{resources} || $self->{resources} || [];
    }

    unless ( $self->{name} ) {
	$resp->set_message("I cannot create an unnamed GSO group");
	$resp->set_isok(0);
	return $resp;
    }

    if ( $self->exist ) {
	$resp->set_message("The GSO group " . $self->name . " already exists");
	$resp->set_value($self);
	$resp->set_iswarning(1);
	return $resp;
    }

    my $rc = $self->ssogroup_create($resp);
    return $resp unless $resp->isok;
    $self->{exist} = $rc;

    # If we have been provided resources on the create call, add them here
    if ( $self->{resources} ) {
	$resp = $self->resources( add => $self->{resources} );
	$resp = $self->get;
    }

    $resp->set_value($self);
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->exist ) {
	$resp->set_message("The GSO group " . $self->name . " doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->ssogroup_delete($resp);
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

    my @rc = ssogroup_list($pd,$resp);
    $resp->isok() && $resp->set_value( $rc[0],\@rc );
    return $resp;
}

sub resources {
    my $self = shift;
    my (@resources,$rc);
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my %dispatch = ( add => \&ssogroup_addresource,
		     remove => \&ssogroup_removeresource
		 );

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    for my $op ( qw/remove add/ ) {
	next unless defined $opts{$op};
	for my $rsc ( ref($opts{$op}) ? @{$opts{$op}} : $opts{$op} ) {
	    for my $resource ( ref($rsc) ? $rsc->name : $rsc ) {
		$rc = $dispatch{$op}->($self,$resp,$resource);
		return $resp unless $resp->isok;
	    }
	}
	$resp = $self->get;
    }

    @resources = $self->ssogroup_getresources();
    $resp->isok and $resp->set_value($resources[0], \@resources);

    return $resp;
}

sub get {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rc;

    unless ( $self->exist ) {
	$resp->set_message( "The GSO groups doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    $rc = $self->ssogroup_get($resp);
    return $resp;
}

sub description { return $_[0]->{description} }
sub name	{ return $_[0]->{name} }
sub exist	{ return $_[0]->{exist} }

sub DESTROY {
    my $self = shift;
    $self->_ssogroupfree();
}

1;

=head1 NAME

Tivoli::AccessManager::Admin::SSO::Group

=head1 SYNOPSIS

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::SSO::Group> provides the interface to modify, create and delete
GSO cred groups.

=head1 CONSTRUCTORS

=head2 new(PDADMIN[,name =E<gt> STRING, description =E<gt> STRING, resources =E<gt> RESOURCES])

Initializes a blessed L<Tivoli::AccessManager::Admin::SSO::Group> object.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  As with every other class, the
only way to change the context is to destroy the L<Tivoli::AccessManager::Admin::SSO::Cred>
object and recreate it with the new context.  This parameter is required.

=item name =E<gt> STRING

The name of the GSO resource group.  This is optional.  If provided, the
module will attempt to determine if a resource group of the same name already
exists.

=item description =E<gt> STRING

A description for the resource group.  This is completely optional.

=item resources =E<gt> RESOURCES

Some GSO resources to be added to the group.  This can be just about anything
you want.  It can consist of a scalar or a list.  The scalar can be a simple
string -- the name of the resource -- or it can be either a
L<Tivoli::AccessManager::Admin::SSO::Cred> or L<Tivoli::AccessManager::Admin::SSO::Web> object.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::SSO::Cred> object under normal circumstances,
undef otherwise.  Since no TAM API calls are made by this method, "otherwise" can
loosely be defined as "syntax error".

=head2 create(PDADMIN,name =E<gt> STRING[,description =E<gt> STRING,resources =E<gt> RESOURCES])

Does the same thing as L</"new">, and creates the GSO group as well.

=head3 Parameters

See the parameter list for L</"new">.  The only difference is that the name of
the resource group is now required.

=head3 Returns


A L<Tivoli::AccessManager::Admin::Response> object indicating the success or failure of the
create operation.  If it could be created, the new L<Tivoli::AccessManager::Admin::SSO::Group>
object will be embedded in the response object as well.

If you are adding resources at create time, do be aware that this is not an
atomic operation -- the resource group can be created by adding the resources
can fail.

=head1 CLASS METHODS

=head2 list(PDADMIN)

Lists all GSO resource groups.

=head2 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  

=back

=head3 Returns

A list of all the resource groups defined in TAM.  This list may be empty.  

This list is, of course, embedded in a L<Tivoli::AccessManager::Admin::Response> object.

=head1 METHODS

The standard disclaimer.  All the methods will return a
L<Tivoli::AccessManager::Admin::Response> object unless specifically stated otherwise.  See the
documentation for that module on how to coax the values out.

The methods also follow the same basic pattern.  If an optional parameter is
provided, it will have the affect of setting the attribute.  All method calls
will embed the results of a 'get' in the L<Tivoli::AccessManager::Admin::Response> object.

=head2 create([name =E<gt> STRING, description =E<gt> STRING, resources =E<gt> RESOURCES])

As you might expect, create can also be used as a method call.

=head3 Parameters

See L</"new"> for a full description.  The name parameter is required only if
it was not provided to L</"new">

=head3 Returns

The success or failure of the operation.

=head2 delete

Deletes the GSO resource group.

=head3 Parameters

None.

=head3 Returns

The success or failure of the operation.

=head2 resources( [add =E<gt> RESOURCES, remove =E<gt> RESOURCES] );

Adds or removes resources from the resource group.

=head3 Parameters

=over 4

=item add =E<gt> RESOURCES

Adds the named resources to the group.  As with L</"create"> and L</"new">,
the RESOURCES can be a single value or a list, a list of names or objects or
some combination there of.

=item remove =E<gt> RESOURCES

Removes the named resources from the group.  As with L</"create"> and L</"new">,
the RESOURCES can be a single value or a list, a list of names or objects or
some combination there of.

If both add and remove are provided, the removes will be processed before the
adds.

=back

=head3 Returns

The success or failure of the operations and the current list (ie, the list of
resource after all the operations) of resources in the group.

=head2 get

Updates the underlying API structure.  You should almost never, ever need to
call this directly.

=head3 Parameters

None.

=head2 Returns

The failure or success of the operation.

The following methods are read only.  They do NOT return their data in 
L<Tivoli::AccessManager::Admin::Response> object.

=head2 name

Returns the name of the resource group.

=head2 exist

Returns 1 if the resource group exists, 0 otherwise.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than I.

=head1 BUGS

None known.

=head1 TODO

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

ivadmin_response* _getresponse( SV* self ) {
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

void _ssogroup_stash( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_ssogroup",9,1);
    ivadmin_ssogroup* group;

    Newz( 5, group, 1, ivadmin_ssogroup );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _ssogroup slot");
    }

    sv_setiv(*fetched, (IV) group );
    SvREADONLY_on(*fetched);
}

static ivadmin_ssogroup* _get_ssogroup( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_ssogroup", 9, 0 );

    return( fetched ? (ivadmin_ssogroup*) SvIV(*fetched) : NULL );
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

static char* _fetch( SV* self, char* field ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, field, strlen(field), 0 );

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

int ssogroup_create(SV* self, SV* resp) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* groupid = _getname(self);
    const char* descrp  = _fetch(self,"description");

    unsigned long rc;

    if ( groupid == NULL )
	croak("ssogroup_create: invalid group id");

    rc = ivadmin_ssogroup_create( *ctx,
				  groupid,
				  descrp,
				  rsp );
    return(rc == IVADMIN_TRUE);
}

int ssogroup_delete(SV* self, SV* resp) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* groupid = _getname(self);

    unsigned long rc;

    if ( groupid == NULL )
	croak("ssogroup_delete: invalid group id");

    rc = ivadmin_ssogroup_delete( *ctx,
				  groupid,
				  rsp );
    return(rc == IVADMIN_TRUE);
}

int ssogroup_get( SV* self, SV* resp ) {
    ivadmin_context* ctx    = _getcontext(self);
    ivadmin_response* rsp   = _getresponse(resp);
    ivadmin_ssogroup* group = _get_ssogroup(self);
    char *groupid           = _getname(self);
    unsigned long rc;

    if ( group == NULL ) {
	_ssogroup_stash(self);
	group = _get_ssogroup(self);
    }

    if ( groupid == NULL )  {
	croak("ssogroup_get: could not retrieve name");
    }

    if ( group == NULL ) {
	croak("ssogroup_get: Couldn't retrieve the ivadmin_ssogroup object");
    }

    rc = ivadmin_ssogroup_get( *ctx,
    			  groupid,
			  group,
			  rsp );

    return( rc == IVADMIN_TRUE );
}

SV* ssogroup_getdescription( SV* self ) {
    ivadmin_ssogroup* group = _get_ssogroup(self);
    const char *answer;

    if ( group == NULL ) {
	croak("ssogroup_getdescription: Couldn't retrieve the ivadmin_ssogroup object");
    }

    answer = ivadmin_ssogroup_getdescription(*group);
    return( answer ? newSVpv(answer,0) : NULL );
}

SV* ssogroup_getid(SV* self) {
    ivadmin_ssogroup* group = _get_ssogroup(self);
    const char *answer;

    if ( group == NULL ) {
	croak("ssogroup_getid: Couldn't retrieve the ivadmin_ssogroup object");
    }

    answer = ivadmin_ssogroup_getid(*group);
    return( answer ? newSVpv(answer,0) : NULL );
}

void ssogroup_getresources(SV* self) {
    ivadmin_ssogroup* group = _get_ssogroup(self);
    char **answer;
    unsigned long count;
    unsigned long rc;
    unsigned long i;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( group == NULL ) {
	croak("ssogroup_getuser: Couldn't retrieve the ivadmin_ssogroup object");
    }

    rc = ivadmin_ssogroup_getresources( *group, &count, &answer );
    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(answer[i],0)));
	    ivadmin_free(answer[i]);
	}
    }
    Inline_Stack_Done;
}

void ssogroup_list(SV* pd, SV* resp) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    char **answer;
    unsigned long count;
    unsigned long rc;
    unsigned long i;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_ssogroup_list( *ctx, &count, &answer, rsp );
    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(answer[i],0)));
	    ivadmin_free(answer[i]);
	}
    }
    Inline_Stack_Done;
}

int ssogroup_addresource(SV* self, SV* resp, const char* ssoid) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* group = _getname(self);
    unsigned long rc = 0;

    if ( group == NULL )
	croak("ssogroup_addresource: Couldn't retrieve the GSO group name");

    rc = ivadmin_ssogroup_addres( *ctx,
				 group,
				 ssoid,
				 rsp );
    return(rc == IVADMIN_TRUE);
}

int ssogroup_removeresource(SV* self, SV* resp, const char* ssoid) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* group = _getname(self);
    unsigned long rc = 0;

    if ( group == NULL )
	croak("ssogroup_removeresource: Couldn't retrieve the GSO group name");

    rc = ivadmin_ssogroup_removeres( *ctx,
				 group,
				 ssoid,
				 rsp );
    return(rc == IVADMIN_TRUE);
}

void _ssogroupfree(SV* self) {
    ivadmin_ssogroup* group = _get_ssogroup(self);

    if (group)
	Safefree(group);
    hv_delete( (HV*)SvRV(self), "_ssogroup", 9, 0 );
}


