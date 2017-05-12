package Tivoli::AccessManager::Admin::Objectspace;
use Carp;
use strict;
use warnings;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Objectspace.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Tivoli::AccessManager::Admin::Objectspace::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::Objectspace',
	  );
use Tivoli::AccessManager::Admin::Response;
use Tivoli::AccessManager::Admin::ProtObject;

my %obj_types = ( unknown       => 0,
		  domain        => 1,
		  file          => 2,
		  program       => 3,
		  dir           => 4,
		  junction      => 5,
		  webseal       => 6,
		  nonexist      => 10,
		  container     => 11,
		  leaf          => 12,
		  port	        => 13,
		  app_container => 14,
		  app_leaf      => 15,
		  mgmt_object   => 16,
	  );

my %rev_obj_types = map { $obj_types{$_} => $_ } keys %obj_types;

sub new {
    my $class = shift;
    my $cont  = shift;

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    my $self  = bless {}, $class;
    if ( @_ % 2 ) {
	warn "Invalid syntax\n";
	return undef;
    }
    my %opts  = @_;

    $self->{name}    = $opts{name} || '';
    $self->{desc}    = $opts{desc} || '';
    $self->{exist}   = 0;
    $self->{context} = $cont;

    if ( defined $opts{type} ) {
	if ( $opts{type} =~ /^\d+$/ ) {
	    if (defined $rev_obj_types{$opts{type}}) {
		$self->{type} = $opts{type};
	    }
	    else {
		warn( "Unknown object type $opts{type}\n" );
		return undef;
	    }
	}
	else {
	    if (defined $obj_types{$opts{type}}) {
		$self->{type} = $obj_types{$opts{type}};
	    }
	    else {
		warn( "Unknown object type $opts{type}\n" );
		return undef;
	    }
	}
    }

    return $self;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless (ref $self) {
	my $pd = shift;
	unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}

	$self = new( $self, $pd, @_ );
	unless ( defined($self) ) {
	    $resp->set_isok(0);
	    $resp->set_message("Could not create self");
	    return $resp;
	}
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ($self->exist) {
	$resp->set_message( $self->{name} . " already exists" );
	$resp->set_iswarning(1);

	return $resp;
    }
	
    unless ( $self->{name} ) {
	$self->{name} = $opts{name} || '';
    }

    unless ( $self->{type} ) {
	$self->{type} = 0;
    }

    if ( $self->{name} ) {
	my $rc = $self->objectspace_create( $resp, $self->{type} );
	$resp->isok and $resp->set_value($self);
	$self->{exist} = $resp->isok;
    }
    else {
	$resp->set_message("create syntax error");
	$resp->set_isok(0);
    }
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rc;

    unless ( $self->{name} ) {
	$resp->set_message("Cannot delete a nameless objectspace");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot delete a non-existent objectspace");
	$resp->set_isok(0);
	return $resp;
    }

    $rc = $self->objectspace_delete( $resp );
    if ($resp->isok) {
	$resp->set_value($rc);
	$self->{exist} = 0;
    }

    return $resp;
}

sub list {
    my $self = shift;
    my $pd;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my @rc;


    if ( ref($self) ) {
	$pd = $self->{context};
    }
    else {
	$pd = shift;
    }

    @rc = objectspace_list($pd, $resp);
    $resp->isok and $resp->set_value(\@rc);

    return $resp;
}

sub exist { return $_[0]->{exist}; }

1;

=head1 NAME

Tivoli::AccessManager::Admin::Objectspace

=head1 SYNOPSIS
   use Tivoli::AccessManager::Admin

   my $resp;
   my $pd = Tivoli::AccessManager::Admin->new( password => 'N3ew0nk!' );
   my $ospace = Tivoli::AccessManager::Admin::Objectspace->new( $pd, name => '/test',
					      type => 'container',
					      desc => 'Test objectspace',
					    );
   # Create the objectspace if it doesn't exist
   unless ( $ospace->exist ) {
       $resp = $ospace->create()
   }

   # Delete the objectspace
   $ospace->delete;

   # List all the objectspaces
   $resp = $ospace->list;
   print @{$resp->value}, "\n";

=head1 DESCRIPTION

B<Tivoli::AccessManager::Admin::Objectspace> provides the interface to the objectspace portion
of the TAM APIs.

=head1 CONSTRUCTOR

=head2 new( PDADMIN[, name =E<gt> NAME, type =E<gt> TYPE, desc => STRING] )

Creates a blessed B<Tivoli::AccessManager::Admin::Objectspace> object and returns it.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  Please note that, after the
L<Tivoli::AccessManager::Admin::Objectspace> object is created, you cannot change the context
w/o destroying the object and recreating it.

=item name =E<gt> NAME

The name of the objectspace to be created.  I believe it needs to start with a
/, but I don't know for certain.

=item type =E<gt> TYPE

The type of the objectspace.  This can either be a numeric value as defined in
the TAM Admin guide, or it may be a word.  I have not defined the unused
object types.  The mapping between names and values looks like this:
    unknown       => 0
    domain        => 1
    file          => 2
    program       => 3
    dir           => 4
    junction      => 5
    webseal       => 6
    nonexist      => 10
    container     => 11
    leaf          => 12
    port	  => 13
    app_container => 14
    app_leaf      => 15
    mgmt_object   => 16

=item desc =E<gt>  STRING

A description.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::Objectspace> object.

=head1 METHODS

You should know this by now, but all of the methods return a
L<Tivoli::AccessManager::Admin::Response> object.  See the documentation for that module to
learn how to coax the values out.

=head2 create([ PDADMIN, name =E<gt> NAME, desc =E<gt> STRING, type =E<gt> TYPE ])

B<create> creates a new objectspace.  It can be used as a constructor.  The
parameters are only required in that instance.

=head3 Parameters

See L<Tivoli::AccessManager::Admin::Objectspace::new> for the discussion and description.

=head3 Returns

If used as a contructor, a fully blessed L<Tivoli::AccessManager::Admin::Objectspace> object.
Otherwise, the success or failure of the create operation.

=head2 delete

Deletes an objectspace.

=head3 Parameters

None

=head3 Returns

The success or failure of the operation.

=head2 list([PDADMIN])

Lists all of the objectspaces in the domain.  This can be used as either an
instance method ( $self=E<gt>list ) or a class method (
Tivoli::AccessManager::Admin::Objectspace=E<gt>list ).

=head3 Parameters

=over 4

=item PDADMIN

A fully blessed L<Tivoli::AccessManager::Admin::Context> object.  This is required only when B<list>
is being used as a class method.

=back

=head3 Returns

A list of all the objectspaces defined in the domain.

=head2 exist

Returns true if the objectspace exists.  This is a read only method and DOES
NOT use a L<Tivoli::AccessManager::Admin::Response>.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the complete list of credits.

=head1 BUGS

None known 

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
    return( rsp );
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return( (ivadmin_context*)SvIV(SvRV(*fetched)) );
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return( fetched ? SvPV_nolen(*fetched) : NULL );
}

char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched  = hv_fetch( self_hash, key, strlen(key), 0 );

    return( fetched ? SvPV_nolen( *fetched ) : NULL );
}

int objectspace_create( SV* self, SV* resp, int code ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char *name = _getname(self);
    char *descr = _fetch( self, "description" );

    unsigned long rc;

    if ( name == NULL )
	croak("objectspace_create: could not retrieve objectspace name");

    if ( descr == NULL )
	descr = "";

    rc = ivadmin_objectspace_create( *ctx, name, code, descr, rsp );
    return( rc == IVADMIN_TRUE );
}

int objectspace_delete( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char *name = _getname(self);

    unsigned long rc;

    if ( name == NULL )
	croak("objectspace_delete: could not retrieve objectspace name");

    rc = ivadmin_objectspace_delete( *ctx, name, rsp );
    return( rc == IVADMIN_TRUE );
}

void objectspace_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **objspace;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_objectspace_list( *ctx,
				   &count,
				   &objspace,
				   rsp );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(objspace[i],0)));
	    ivadmin_free( objspace[i] );
	}
    }
    Inline_Stack_Done;
}
