package Tivoli::AccessManager::Admin::Domain;
use Carp;
use strict;
use warnings;
use Data::Dumper;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Domain.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Tivoli::AccessManager::Admin::Action::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::Domain',
	  );
use Tivoli::AccessManager::Admin::Response;

sub new {
    my $class = shift;
    my $cont    = shift;
    my $resp  = Tivoli::AccessManager::Admin::Response->new();

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if ( @_ % 2 ) {
	warn "Invalid syntax -- you did not send a hash\n";
	return undef;
    }

    my %opts  = @_;
    my $self = bless {}, $class;

    $self->{name}        = $opts{name} || '';
    $self->{admin}       = $opts{admin} || '';
    $self->{description} = $opts{description} || '';
    $self->{context}     = $cont;
    $self->{exist}       = 0;

    if ( $self->{name} ) {
	$self->domain_get($resp);
	$self->{exist} = $resp->isok;
    }

    return $self;
}

sub create { 
    my $self = shift;
    my $resp  = Tivoli::AccessManager::Admin::Response->new();
    my $rc;

    unless ( ref $self ) {
	my $pd = shift;

	unless ( UNIVERSAL::isa($pd, 'Tivoli::AccessManager::Admin::Context') ) {
	    $resp->set_message( 'syntax error -- no context' );
	    $resp->set_isok(0);
	    return $resp;
	}

	$self = $self->new( $pd, @_ );
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax -- you did not send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ( $self->{exist} ) {
	$resp->set_message("Cannot create a Domain that already exists");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{name} ) {
	$self->{name} = $opts{name} || '';
    }

    unless ( $self->{admin} ) {
	$self->{admin} = $opts{admin} || '';
    }

    unless ( $self->{description} ) {
	$self->{description} = $opts{description} || '';
    }

    unless ( defined( $opts{password} ) ) {
	$resp->set_message("syntax error: you must provide the domain admin's password" );
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{name} and $self->{admin} and $self->{description} ) {
	$resp->set_message("syntax error: you must provide the domain's name, admin and description" );
	$resp->set_isok(0);
	return $resp;
    }

    $rc = $self->domain_create( $resp, $opts{password} );
    if ( $resp->isok ) {
	$resp->set_value($self);
	$self->{exist} = 1;
    }
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$reg);

    if ( @_ == 1 ) {
	$reg = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$reg = $opts{registry} || 0;
    }
    else {
	$reg = 0;
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot delete a Domain that does not exist");
	$resp->set_iswarning(1);
	return $resp;
    }

    $rc = domain_delete( $self, $resp, $reg);
    $self->{exist} = ! $rc;

    return $resp;
}

sub description { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$desc);

    if ( @_ == 1 ) {
	$desc = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$desc = $opts{description} || '';
    }
    else {
	$desc = '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot describe a Domain that does not exist");
	$resp->set_isok(0);
	return $resp;
    }
    if ( $desc ) {
	$rc = $self->domain_setdescription($resp, $desc);
    }

    if ( $resp->isok ) {
	$self->domain_get($resp);
	$resp->isok and $resp->set_value( $self->domain_getdescription );
    }

    return $resp;
}

sub list {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my (@rc,$pd);


    if ( ref $self ) {
	$pd = $self->{context};
    }
    else {
	$pd = shift;
	unless ( UNIVERSAL::isa($pd, 'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message( 'syntax error -- no context object' );
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    @rc = domain_list( $pd, $resp );
    $resp->isok and $resp->set_value(\@rc);

    return $resp;
}

sub DESTROY {
    my $self = shift;
    $self->_domainfree;
}

sub name { return $_[0]->domain_getid };

1;

=head1 NAME

Tivoli::AccessManager::Admin::Domain

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin;

  my $pd = Tivoli::AccessManager::Admin->new( password => 'N3ew0nk' );
  # Create a domain object
  my $dom = Tivoli::AccessManager::Admin::Domain->new( $pd,
				     name => 'Test',
				     admin => 'chimchim',
				     description => 'test domain' );
  # Create it in TAM
  my $resp = $dom->create(password => 'n33w0nk');

  # Create another domain in a different way
  $resp = Tivoli::AccessManager::Admin::Domain->create( $pd,
				      name => 'Test1',
				      admin => 'chimchim',
				      description => 'another test domain',
				      password => 'n33w0nk');
  my $dom1 = $resp->value;
  # Delete them both
  $resp = $dom->delete;  # All the info stays in registry
  $resp = $dom1->delete( 1 ); # Kill everything

  # Recreate my example :)
  $resp = $dom->create(password => 'n33w0nk');
  # Set the description
  $resp = $dom->description( 'Speed Racer' );

  # Get a list of all the domains
  $resp = $dom->list;
  # Or
  $resp = Tivoli::AccessManager::Admin::Domain->list($pd);

  print "Domains:\n\t" . join("\n\t", @{$resp->value});



=head1 DESCRIPTION

Allows for the creation, deletion and some manipulations of TAM domains.

=head1 CONSTRUCTORS

=head2 new( PDADMIN[, name =E<gt> NAME, admin =E<gt>  ADMINID, description =E<gt> DESC] );

Creates a blessed L<Tivoli::AccessManager::Admin::Domain> object.  You will need to destroy this
object if you wish to change the context.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
parameter.

=item name =E<gt>  NAME

The name of the domain.  

=item admin =E<gt>  ADMINID

The domain administrator's ID. 

=item description =E<gt> DESC

A description of the domain.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::Domain> object. 

=head2 create( PDADMIN, name =E<gt> NAME, admin =E<gt>  ADMINID, description =E<gt> DESC, password =E<gt> PASSWORD )

Instantiates a L<Tivoli::AccessManager::Admin::Domain> object and creates the domain in 
TAM if used as a class method.

=head3 Parameters

=over 4

=item name =E<gt>  NAME

=item admin =E<gt>  ADMINID

=item description =E<gt> DESC

The parameters are identical to those for L</"new">.  Unlike L</"new">, they
are all required.

=item password =E<gt>  PASSWORD

The domain administrator's password.  This too is required.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::Domain> object, buried in a L<Tivoli::AccessManager::Admin::Response>
object.

=head1 CLASS METHODS

=head2 list(PDADMIN)

Generates a list of the names of all the security domains.

=head3 Parameters

=over 4

=item PDADMIN

A fully initialized L<Tivoli::AccessManager::Admin::Context> object.

=back

=head3 Returns

The list of the security domains currently defined.

=head1 METHODS

=head2 create( name =E<gt> NAME, admin =E<gt>  ADMINID, description =E<gt> DESC, password =E<gt> PASSWORD )

Yes, this can called as an instance method if you want.  Notice the different
signature -- the context object is no longer required.

=head3 Parameters

=over 4

=item name =E<gt>  NAME

=item admin =E<gt>  ADMINID

=item description =E<gt> DESC

See L</"new">.  Any parameter you did not provide to L</"new"> must be
provided to L</"create">.  They all must be defined to actually create the
domain in TAM

=item password =E<gt>  PASSWORD

The domain administrator's password.  This too is required.

=back

=head3 Returns

The results if the create operation

=head2 delete([1])

Deletes the domain from TAM.

=head3 Parameters

=over 4

=item 1

If provided, all of the domain's entries will be deleted from the registry.

=back

=head3 Returns

The results of the delete call.

=head2 description([STR])

If the optional parameter is provided, the domain's description will be
changed.  Either way, the description for the domain is returned.

=head3 Parameters

=over 4

=item STR

Causes the domain's description to be changed to STR

=back

=head3 Returns

The domain's current description.

=head2 list()

L</"list"> can be called as an instance method as well.  Note the diffference
in the method's signature -- the L<Tivoli::AccessManager::Admin::Context> object is no longer
required.

=head3 Parameters

None.

=head3 Returns

The names of all the currently defined TAM domains.

=head2 name

Returns the domain's name.  This is a read-only method.

=head3 Parameters

None

=head3 Returns

The domain's name.  This is NOT buried in a L<Tivoli::AccessManager::Admin::Response> object.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than me.

=head1 BUGS

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

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

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return(rsp);
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return((ivadmin_context*)SvIV(SvRV(*fetched)));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return(fetched ? SvPV_nolen(*fetched) : NULL);
}

char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched  = hv_fetch( self_hash, key, strlen(key), 0 );

    return( fetched ? SvPV_nolen( *fetched ) : NULL );
}

void _domainstore( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_domain",7,1);
    ivadmin_domain* domain;

    Newz( 5, domain, 1, ivadmin_domain );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _domain slot");
    }

    sv_setiv(*fetched, (IV) domain );
    SvREADONLY_on(*fetched);
}

ivadmin_domain* _domainget( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_domain", 7, 0 );

    if ( fetched ) {
	return (ivadmin_domain*) SvIV(*fetched);
    }
    else {
	return NULL;
    }
}

unsigned long domain_create( SV* self, SV* resp, const char* passwd ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    const char* name = _getname(self);

    const char* admin    = _fetch(self,"admin");
    const char* descr    = _fetch(self,"description");

    unsigned long rc = 0;

    if ( name == NULL )
	croak("domain_create: could not retrieve domain name");

    if ( admin == NULL )
	croak("domain_create: could not retrieve admin id");

    if ( descr == NULL )
	croak("domain_create: could not retrieve description");

    rc = ivadmin_domain_create( *ctx,
				name,
				admin,
				passwd,
				descr,
				rsp );
    return( rc == IVADMIN_TRUE );
}

unsigned long domain_delete( SV* self, SV* resp, unsigned  long registry ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    const char* name = _getname(self);

    unsigned long rc = 0;

    if ( name == NULL )
	croak("domain_delete: could not retrieve domain name");

    rc = ivadmin_domain_delete( *ctx,
				name,
				registry,
				rsp );
    return( rc == IVADMIN_TRUE );
}


int domain_get( SV* self, SV* resp ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    ivadmin_domain* domain = _domainget(self);
    char *name = _getname(self);

    unsigned long rc;
   
    if ( domain == NULL ) {
	_domainstore(self);
	domain = _domainget(self);
    }

    if ( name == NULL )
	croak("domain_get: could not retrieve domain name");

    if ( domain == NULL )
	croak("domain_get: could not retrieve ivadmin_domain");

    rc = ivadmin_domain_get( *ctx, name, domain, rsp );
    return( rc == IVADMIN_TRUE );
}

SV* domain_getdescription( SV* self ) {
    ivadmin_domain* domain = _domainget(self);
    char *desc;

    if ( domain == NULL )
	croak("domain_getdescription: could not retrieve ivadmin_domain");

    desc = (char*)ivadmin_domain_getdescription(*domain);
    return( desc ? newSVpv(desc,0) : NULL );
}

SV* domain_getid( SV* self ) {
    ivadmin_domain* domain = _domainget(self);
    char *id;

    if ( domain == NULL )
	croak("domain_getid: could not retrieve ivadmin_domain");
    
    id = (char*)ivadmin_domain_getid(*domain);
    return( id ? newSVpv(id,0) : NULL );
}

void domain_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **domains;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_domain_list( *ctx,
			     &count,
			     &domains,
			     rsp 
			    );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(domains[i],0)));
	    ivadmin_free( domains[i] );
	}
    }
    Inline_Stack_Done;
}

int domain_setdescription( SV* self, SV* resp, const char* descr ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    const char* name = _getname(self);

    unsigned long rc = 0;

    if ( name == NULL )
	croak("domain_setdescription: could not retrieve domain name");

    rc = ivadmin_domain_setdescription( *ctx, 
					name,
					descr,
					rsp );
    return(rc == IVADMIN_TRUE);
}

void _domainfree( SV* self ) {
    ivadmin_domain* domain = _domainget(self);

    if (domain)
	Safefree(domain);
    hv_delete((HV*)SvRV(self), "_domain",7,0);
}

